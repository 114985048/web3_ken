// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
}

interface IExtendedERC20 is IERC20 {
    function transferWithCallback(address _to, uint256 _value) external returns (bool);
    function transferWithCallbackAndData(address _to, uint256 _value, bytes calldata _data) external returns (bool);
}

contract NFTMarket_V2 is ITokenReceiver {
    error PaymentTokenAddressZero();
    error PriceZero();
    error NFTContractAddressZero();
    error NotOwnerNorApproved();
    error ListingNotActive();
    error NotSeller();
    error CallerNotPaymentToken();
    error InvalidDataLength();
    error IncorrectPaymentAmount();
    error TokenTransferFailed();

    IExtendedERC20 public immutable paymentToken;
    
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }
    
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;
    
    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price);
    event NFTListingCancelled(uint256 indexed listingId);
    
    constructor(address _paymentTokenAddress) {
        if (_paymentTokenAddress == address(0)) revert PaymentTokenAddressZero();
        paymentToken = IExtendedERC20(_paymentTokenAddress);
    }
    
    function list(address _nftContract, uint256 _tokenId, uint256 _price) external returns (uint256) {
        if (_price == 0) revert PriceZero();
        if (_nftContract == address(0)) revert NFTContractAddressZero();
        
        IERC721 nftContract = IERC721(_nftContract);
        address owner = nftContract.ownerOf(_tokenId);
        if (!(owner == msg.sender || nftContract.isApprovedForAll(owner, msg.sender) || nftContract.getApproved(_tokenId) == msg.sender)) revert NotOwnerNorApproved();
        
        uint256 listingId = nextListingId;
        listings[listingId] = Listing({
            seller: owner,
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price
        });
        unchecked { ++nextListingId; }
        emit NFTListed(listingId, owner, _nftContract, _tokenId, _price);
        return listingId;
    }
    
    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        address seller = listing.seller;
        if (seller == address(0)) revert ListingNotActive();
        if (seller != msg.sender) revert NotSeller();
        delete listings[_listingId];
        emit NFTListingCancelled(_listingId);
    }
    
    function buyNFT(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        address seller = listing.seller;
        if (seller == address(0)) revert ListingNotActive();

        uint256 price = listing.price;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        delete listings[_listingId];
        
        bool success = paymentToken.transferFrom(msg.sender, seller, price);
        if (!success) revert TokenTransferFailed();
        IERC721(nftContract).transferFrom(seller, msg.sender, tokenId);
        emit NFTSold(_listingId, msg.sender, seller, nftContract, tokenId, price);
    }
    
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override returns (bool) {
        if (msg.sender != address(paymentToken)) revert CallerNotPaymentToken();
        if (data.length != 32) revert InvalidDataLength();
        uint256 listingId = abi.decode(data, (uint256));
        Listing storage listing = listings[listingId];
        address seller = listing.seller;
        if (seller == address(0)) revert ListingNotActive();
        if (amount != listing.price) revert IncorrectPaymentAmount();
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        delete listings[listingId];
        bool success = paymentToken.transfer(seller, amount);
        if (!success) revert TokenTransferFailed();
        IERC721(nftContract).transferFrom(seller, from, tokenId);
        emit NFTSold(listingId, from, seller, nftContract, tokenId, amount);
        return true;
    }
    
    function buyNFTWithCallback(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        address seller = listing.seller;
        if (seller == address(0)) revert ListingNotActive();
        bytes memory data = abi.encode(_listingId);
        bool success = paymentToken.transferWithCallbackAndData(address(this), listing.price, data);
        if (!success) revert TokenTransferFailed();
    }
}



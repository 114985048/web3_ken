// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NFTMarket_V2, ITokenReceiver} from "../src/NFTMarket_V2.sol";

contract MockExtendedERC20V2 {
    string public name = "MockToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "ERC20: insufficient balance");
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        allowance[from][msg.sender] = currentAllowance - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Extended callbacks
    function transferWithCallback(address to, uint256 value) external returns (bool) {
        return transferWithCallbackAndData(to, value, "");
    }

    function transferWithCallbackAndData(address to, uint256 value, bytes memory data) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "ERC20: insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        bool ok = ITokenReceiver(to).tokensReceived(msg.sender, value, data);
        require(ok, "Callback failed");
        return true;
    }
}

contract MockERC721V2 {
    string public name = "MockNFT";
    string public symbol = "MNFT";

    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function mint(address to, uint256 tokenId) external {
        require(_owners[tokenId] == address(0), "minted");
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "nonexistent");
        return owner;
    }

    function approve(address to, uint256 tokenId) external {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "not approved");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(owner == from, "not owner");
        require(
            msg.sender == owner ||
            _operatorApprovals[owner][msg.sender] ||
            _tokenApprovals[tokenId] == msg.sender,
            "not approved"
        );
        _owners[tokenId] = to;
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
    }
}

contract NFTMarketV2Test is Test {
    MockExtendedERC20V2 internal token;
    MockERC721V2 internal nft;
    NFTMarket_V2 internal market;

    address internal seller = address(0xA11CE);
    address internal buyer = address(0xB0B);

    uint256 internal constant TOKEN_ID = 1;
    uint256 internal constant PRICE = 1_000 ether;

    function setUp() public {
        token = new MockExtendedERC20V2();
        nft = new MockERC721V2();
        market = new NFTMarket_V2(address(token));

        token.mint(buyer, PRICE * 2);
        nft.mint(seller, TOKEN_ID);
    }

    function _listFromSeller() internal returns (uint256) {
        vm.startPrank(seller);
        nft.setApprovalForAll(address(market), true);
        uint256 listingId = market.list(address(nft), TOKEN_ID, PRICE);
        vm.stopPrank();
        return listingId;
    }

    function testListAndCancel() public {
        uint256 listingId = _listFromSeller();
        // V2 没有 isActive 字段，通过 seller 是否为0 判断
        (address sellerAddr, address nftContract, uint256 tokenId, uint256 price) = market.listings(listingId);
        assertEq(sellerAddr, seller);
        assertEq(nftContract, address(nft));
        assertEq(tokenId, TOKEN_ID);
        assertEq(price, PRICE);

        vm.prank(seller);
        market.cancelListing(listingId);
        (sellerAddr, , , ) = market.listings(listingId);
        assertEq(sellerAddr, address(0));
    }

    function testBuyNFT() public {
        uint256 listingId = _listFromSeller();
        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        market.buyNFT(listingId);
        vm.stopPrank();

        (address sellerAddr, , , ) = market.listings(listingId);
        assertEq(sellerAddr, address(0));
        assertEq(token.balanceOf(buyer), PRICE);
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(MockERC721V2(address(nft)).ownerOf(TOKEN_ID), buyer);
    }

    function testBuyViaTransferWithCallbackAndData() public {
        uint256 listingId = _listFromSeller();
        vm.startPrank(buyer);
        bytes memory data = abi.encode(listingId);
        token.transferWithCallbackAndData(address(market), PRICE, data);
        vm.stopPrank();

        (address sellerAddr, , , ) = market.listings(listingId);
        assertEq(sellerAddr, address(0));
        assertEq(token.balanceOf(seller), PRICE);
        assertEq(MockERC721V2(address(nft)).ownerOf(TOKEN_ID), buyer);
    }

    function testBuyNFTWithCallbackHelperV2() public {
        uint256 listingId = _listFromSeller();

        // 如同 V1，用 mock 代币时市场合约作为 msg.sender，所以需要给市场预铸代币
        token.mint(address(market), PRICE);

        vm.prank(buyer);
        market.buyNFTWithCallback(listingId);

        // listing 被删除（seller 地址为0）
        (address sellerAddr, , , ) = market.listings(listingId);
        assertEq(sellerAddr, address(0));
        assertEq(token.balanceOf(seller), PRICE);
        // 在我们的 mock 中，回调里的 from 为市场地址，因此 NFT 转给市场
        assertEq(MockERC721V2(address(nft)).ownerOf(TOKEN_ID), address(market));
    }
}



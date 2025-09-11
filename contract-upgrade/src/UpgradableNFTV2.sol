// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title UpgradableNFTV2 - 可升级 ERC721 NFT 合约 V2（支持离线签名上架+购买）
contract UpgradableNFTV2 is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {
    using ECDSA for bytes32;

    uint256 private _nextTokenId;
    string private _baseTokenURI;

    /// NFT 上架信息
    struct ListingInfo {
        bool isListed;
        uint256 price;
        address seller;
        uint256 nonce;
    }

    mapping(uint256 => ListingInfo) public listings;
    mapping(address => uint256) public userNonces;

    bytes32 private constant LISTING_TYPEHASH = keccak256(
        "Listing(uint256 tokenId,uint256 price,uint256 nonce)"
    );

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price, uint256 nonce);
    event NFTUnlisted(uint256 indexed tokenId, address indexed seller);
    event NFTBought(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init(owner_);
        __UUPSUpgradeable_init();
        __EIP712_init("UpgradableNFT", "1");

        _baseTokenURI = baseURI_;
        _nextTokenId = 1;
    }

    /// V2 初始化（升级时调用）
    function upgradeV2() external reinitializer(2) {
        __EIP712_init("UpgradableNFT", "2");
    }

    /// 铸造 NFT
    function mintWithURI(address to, string memory tokenURI_) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        unchecked {
            _nextTokenId = tokenId + 1;
        }
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    /// 设置基础 URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /// 使用签名挂单
    function listNFTWithSignature(
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        bytes memory signature
    ) external {
        address signer = _verifyListingSignature(tokenId, price, nonce, signature);
        require(ownerOf(tokenId) == signer, "Not owner");
        require(nonce == userNonces[signer] + 1, "Invalid nonce");
        require(price > 0, "Invalid price");
        require(!listings[tokenId].isListed, "Already listed");

        listings[tokenId] = ListingInfo({
            isListed: true,
            price: price,
            seller: signer,
            nonce: nonce
        });

        userNonces[signer] = nonce;

        emit NFTListed(tokenId, signer, price, nonce);
    }

    /// 取消挂单
    function unlistNFT(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(listings[tokenId].isListed, "Not listed");

        address seller = listings[tokenId].seller;
        delete listings[tokenId];

        emit NFTUnlisted(tokenId, seller);
    }

    /// 买 NFT
    function buyNFT(uint256 tokenId) external payable {
        ListingInfo memory info = listings[tokenId];
        require(info.isListed, "Not listed");
        require(msg.value == info.price, "Incorrect ETH");
        require(ownerOf(tokenId) == info.seller, "Seller no longer owns NFT");

        // 删除挂单
        delete listings[tokenId];

        // 转账 NFT
        _safeTransfer(info.seller, msg.sender, tokenId, "");

        // 转账 ETH 给卖家
        payable(info.seller).transfer(msg.value);

        emit NFTBought(tokenId, info.seller, msg.sender, info.price);
    }

    /// 获取挂单信息
    function getListingInfo(uint256 tokenId) external view returns (ListingInfo memory) {
        return listings[tokenId];
    }

    function getUserNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }

    /// 签名验证
    function _verifyListingSignature(
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 structHash = keccak256(abi.encode(LISTING_TYPEHASH, tokenId, price, nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        return hash.recover(signature);
    }

    /// 升级授权
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- 继承冲突覆盖 ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }
}

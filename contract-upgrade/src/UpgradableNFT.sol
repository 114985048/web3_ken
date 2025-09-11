// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/// @title UpgradableNFT - 可升级 ERC721 NFT 合约（UUPS）
/// @notice 使用 OpenZeppelin Upgradeable 实现，包含初始化、所有权与升级授权、可设置 baseURI 与铸造功能
contract UpgradableNFT is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// 自增 TokenId 计数器（从 1 开始）
    uint256 private _nextTokenId;

    /// 基础元数据前缀，可选
    string private _baseTokenURI;

    /// 禁用实现合约的构造初始化
    /// 使用 initialize 进行初始化
    constructor() {
        _disableInitializers();
    }

    /// 初始化函数（仅可调用一次）
    /// @param name_ NFT 名称
    /// @param symbol_ NFT 符号
    /// @param baseURI_ 基础元数据前缀
    /// @param owner_ 初始所有者地址
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

        _baseTokenURI = baseURI_;
        _nextTokenId = 1;
    }

    /// 铸造到指定地址，并设置 tokenURI（仅所有者）
    function mintWithURI(address to, string memory tokenURI_) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId;
        unchecked {
            _nextTokenId = tokenId + 1;
        }
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    /// 设置基础 URI（仅所有者）
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// 读取基础 URI
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /// UUPS 升级授权，仅所有者可升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// 覆盖基础 URI 提供
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- 多重继承所需覆盖 ---
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



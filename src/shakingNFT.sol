// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingNFT is ERC721URIStorage, Ownable {
    struct StakedNFT {
        address owner;
        uint256 startTime;
        uint256 xp;
        bool staked;
    }

    mapping(uint256 => StakedNFT) public stakedNFTs;
    mapping(uint256 => uint256) public nftLevels;
    mapping(uint256 => bool) public mintedTokenIds; // ✅ Tracks minted tokens

    uint256 public nextTokenId = 1; // ✅ Ensures unique IDs
    uint256 public constant XP_PER_SECOND = 1;
    uint256 public constant XP_REQUIRED_FOR_LEVEL_UP = 1000;

    event Minted(address indexed user, uint256 tokenId);
    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event LeveledUp(uint256 tokenId, uint256 newLevel);

    constructor() ERC721("StakingNFT", "SNFT") Ownable(msg.sender) {}

    /// @notice ✅ Mint a unique NFT
    function mintNFT(address recipient, string memory tokenURI) external onlyOwner returns (uint256) {
        uint256 newItemId = nextTokenId;
        nextTokenId++; // ✅ Ensures next ID is unique

        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        mintedTokenIds[newItemId] = true; // ✅ Mark ID as minted

        emit Minted(recipient, newItemId);
        return newItemId;
    }

    function stakeNFT(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(!stakedNFTs[tokenId].staked, "Already staked");
        require(mintedTokenIds[tokenId], "Invalid token ID"); // ✅ Ensure NFT exists

        stakedNFTs[tokenId] = StakedNFT({
            owner: msg.sender,
            startTime: block.timestamp,
            xp: 0,
            staked: true
        });

        emit Staked(msg.sender, tokenId);
    }

    function unstakeNFT(uint256 tokenId) external {
        require(stakedNFTs[tokenId].staked, "NFT not staked");
        require(stakedNFTs[tokenId].owner == msg.sender, "You don't own this NFT");

        _updateXP(tokenId);

        stakedNFTs[tokenId].staked = false;
        stakedNFTs[tokenId].startTime = 0;

        emit Unstaked(msg.sender, tokenId);
    }

    function _updateXP(uint256 tokenId) internal {
        require(stakedNFTs[tokenId].staked, "NFT not staked");

        uint256 timeElapsed = block.timestamp - stakedNFTs[tokenId].startTime;
        uint256 newXP = timeElapsed * XP_PER_SECOND;
        stakedNFTs[tokenId].xp += newXP;
        stakedNFTs[tokenId].startTime = block.timestamp;

        if (stakedNFTs[tokenId].xp >= XP_REQUIRED_FOR_LEVEL_UP) {
            nftLevels[tokenId]++;
            stakedNFTs[tokenId].xp = 0;
            emit LeveledUp(tokenId, nftLevels[tokenId]);
        }
    }

    function getNFTLevel(uint256 tokenId) external view returns (uint256) {
        return nftLevels[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title BadgeNFT
 * @dev ERC-721 token for GreenChain achievement badges and tier-based NFTs
 */
contract BadgeNFT is IBadgeNFT, ERC721, ERC721URIStorage, Ownable, Pausable {
    uint256 private _tokenIds;
    mapping(uint256 => Badge) private _badges;
    mapping(address => uint256[]) private _userBadges;
    
    address public participantRegistry;
    address public tierManager;
    
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || 
            msg.sender == participantRegistry || 
            msg.sender == tierManager,
            "Not authorized"
        );
        _;
    }
    
    constructor(address _participantRegistry, address _tierManager) 
        ERC721("GreenChain Badges", "GCB")
        Ownable(msg.sender)
    {
        participantRegistry = _participantRegistry;
        tierManager = _tierManager;
    }
    
    function mintBadge(
        address to,
        string memory badgeType,
        string memory name,
        string memory description,
        string memory imageURI
    ) external override onlyAuthorized whenNotPaused returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");
        
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        
        Badge memory newBadge = Badge({
            tokenId: newTokenId,
            owner: to,
            badgeType: badgeType,
            name: name,
            description: description,
            imageURI: imageURI,
            earnedDate: block.timestamp,
            isActive: true
        });
        
        _badges[newTokenId] = newBadge;
        _userBadges[to].push(newTokenId);
        
        _safeMint(to, newTokenId);
        
        string memory badgeTokenURI = string(abi.encodePacked(
            "data:application/json;base64,",
            _base64Encode(bytes(string(abi.encodePacked(
                '{"name":"', name, '","description":"', description, '","image":"', imageURI, '"}'
            ))))
        ));
        _setTokenURI(newTokenId, badgeTokenURI);
        
        emit BadgeMinted(to, newTokenId, badgeType);
        return newTokenId;
    }
    
    function getBadge(uint256 tokenId) external view override returns (Badge memory) {
        require(ownerOf(tokenId) != address(0), "Badge does not exist");
        return _badges[tokenId];
    }
    
    /**
     * @dev Get badge metadata (alias for getBadge)
     * @param tokenId Badge token ID
     * @return Badge metadata structure
     */
    function getBadgeMetadata(uint256 tokenId) external view returns (Badge memory) {
        require(ownerOf(tokenId) != address(0), "Badge does not exist");
        return _badges[tokenId];
    }
    
    function getUserBadges(address user) external view override returns (uint256[] memory) {
        return _userBadges[user];
    }
    
    function updateBadge(uint256 tokenId, string memory badgeType) external override onlyAuthorized {
        require(ownerOf(tokenId) != address(0), "Badge does not exist");
        _badges[tokenId].badgeType = badgeType;
        emit BadgeUpdated(tokenId, badgeType);
    }
    
    function burnBadge(uint256 tokenId) external override onlyAuthorized {
        require(ownerOf(tokenId) != address(0), "Badge does not exist");
        address badgeOwner = _badges[tokenId].owner;
        
        // Remove from user badges
        uint256[] storage userBadges = _userBadges[badgeOwner];
        for (uint256 i = 0; i < userBadges.length; i++) {
            if (userBadges[i] == tokenId) {
                userBadges[i] = userBadges[userBadges.length - 1];
                userBadges.pop();
                break;
            }
        }
        
        delete _badges[tokenId];
        _update(address(0), tokenId, address(0));
    }
    
    function updateContractAddresses(address _participantRegistry, address _tierManager) external onlyOwner {
        participantRegistry = _participantRegistry;
        tierManager = _tierManager;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _base64Encode(bytes memory data) internal pure returns (string memory) {
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 len = data.length;
        if (len == 0) return "";
        
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        
        uint256 i = 0;
        uint256 j = 0;
        
        while (i < len) {
            uint256 a = i < len ? uint8(data[i++]) : 0;
            uint256 b = i < len ? uint8(data[i++]) : 0;
            uint256 c = i < len ? uint8(data[i++]) : 0;
            
            uint256 triple = (a << 16) + (b << 8) + c;
            
            result[j++] = bytes1(bytes(table)[triple >> 18 & 0x3F]);
            result[j++] = bytes1(bytes(table)[triple >> 12 & 0x3F]);
            result[j++] = bytes1(bytes(table)[triple >> 6 & 0x3F]);
            result[j++] = bytes1(bytes(table)[triple & 0x3F]);
        }
        
        while (j > 0 && result[j - 1] == "=") {
            j--;
        }
        
        return string(result);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
} 
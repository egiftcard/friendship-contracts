//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Base64.sol";
import "./HexStrings.sol";
import "hardhat/console.sol";

contract Friendship is ERC721, ERC721URIStorage {
    using HexStrings for uint256;

    enum FriendshipStatus {
        NONE,
        PENDING,
        HEALTHY
    }

    struct Friend {
        address other;
        uint256 otherTokenId;
        FriendshipStatus status;
    }

    mapping(uint256 => Friend) private _friendship;

    event FriendRequest(address indexed from, address indexed to, uint256 fromTokenId, uint256 toTokenId);
    event FriendAccept(address indexed from, address indexed to, uint256 fromTokenId, uint256 toTokenId);
    event FriendDestroy(address indexed from, address indexed to, uint256 fromTokenId, uint256 toTokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() ERC721("Friendship", "FRIEND") {
    }

    function request(address to) external returns (uint256, uint256) {
        address from = msg.sender;
        require(!hasFriendship(from, to), "already has friendship");
        uint256 fromTokenId = uint256(keccak256(abi.encodePacked(from, to)));
        uint256 toTokenId = uint256(keccak256(abi.encodePacked(to, from)));
        require(_friendship[fromTokenId].status == FriendshipStatus.NONE, "friendship not none");
        require(_friendship[toTokenId].status == FriendshipStatus.NONE, "friendship not none");
        _friendship[fromTokenId] = Friend({
            other: to,
            otherTokenId: toTokenId,
            status: FriendshipStatus.PENDING
        });
        _friendship[toTokenId] = Friend({
            other: from,
            otherTokenId: fromTokenId,
            status: FriendshipStatus.PENDING
        });
        emit FriendRequest(from, to, fromTokenId, toTokenId);
        return (fromTokenId, toTokenId);
    }

    function accept(address from) external {
        address to = msg.sender;
        require(!hasFriendship(from, to), "already has friendship");

        uint256 fromTokenId = uint256(keccak256(abi.encodePacked(from, to)));
        uint256 toTokenId = uint256(keccak256(abi.encodePacked(to, from)));
        require(_friendship[fromTokenId].status == FriendshipStatus.PENDING, "friendship not pending");
        require(_friendship[toTokenId].status == FriendshipStatus.PENDING, "friendship not pending");

        _friendship[fromTokenId].status = FriendshipStatus.HEALTHY;
        _friendship[toTokenId].status = FriendshipStatus.HEALTHY;

        _mint(from, fromTokenId);
        _mint(to, toTokenId);
        emit FriendAccept(from, to, fromTokenId, toTokenId);
    }

    function destroy(address to) external {
        address from = msg.sender;
        require(hasFriendship(from, to), "no friendship");

        uint256 fromTokenId = uint256(keccak256(abi.encodePacked(from, to)));
        uint256 otherTokenId = _friendship[fromTokenId].otherTokenId;
        _burn(fromTokenId);
        _burn(otherTokenId);
        delete _friendship[fromTokenId];
        delete _friendship[otherTokenId];
        emit FriendDestroy(from, to, fromTokenId, otherTokenId);
    }

    function hasFriendship(address first, address second) public view returns (bool) {
        uint256 fromTokenId = uint256(keccak256(abi.encodePacked(first, second)));
        uint256 toTokenId = uint256(keccak256(abi.encodePacked(second, first)));
        return _exists(fromTokenId) && _exists(toTokenId);
    }

    function getFriendshipByTokenId(uint256 tokenId) public view returns (Friend memory) {
        return _friendship[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        address from = ownerOf(tokenId);
        address to = getFriendshipByTokenId(tokenId).other;

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', generateMetadataName(tokenId, from, to), '", "description": "', generateMetadataDescription(tokenId, from, to),'", "image": "data:image/svg+xml;base64,', generateMetadataSVG(tokenId, from, to), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function generateMetadataName(uint256 tokenId, address from, address to) internal pure returns (string memory) {
        return "Friendship";
    }

    function generateMetadataDescription(uint256 tokenId, address from, address to) internal pure returns (string memory) {
        return string(abi.encodePacked("Friendship between ", addressToString(from), " and ", addressToString(to)));
    }

    function generateMetadataSVG(uint256 tokenId, address from, address to) internal pure returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 16px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = addressToString(from);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = ' X </text><text x="10" y="60" class="base">';

        parts[4] = addressToString(to);

        parts[5] = '</text><text x="10" y="80" class="base"> are good friend :)';

        parts[6] = '</text></svg>';

        return Base64.encode(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("can't transfer friendship");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("can't transfer friendship");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        revert("can't transfer friendship");
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

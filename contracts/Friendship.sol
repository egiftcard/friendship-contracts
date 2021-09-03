//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract Friendship is ERC721, ERC721URIStorage {
    using Address for address;
    using Strings for uint256;

    enum FriendshipStatus {
        NONE,
        PENDING,
        HEALTHY
    }

    struct State {
        address other;
        uint256 otherTokenId;
        FriendshipStatus status;
    }

    mapping(uint256 => State) private _friendship;

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
        _friendship[fromTokenId] = State({
            other: to,
            otherTokenId: toTokenId,
            status: FriendshipStatus.PENDING
        });
        _friendship[toTokenId] = State({
            other: from,
            otherTokenId: fromTokenId,
            status: FriendshipStatus.PENDING
        });
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
    }

    function destroy(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not an owner");

        uint256 otherTokenId = _friendship[tokenId].otherTokenId;
        _burn(tokenId);
        _burn(otherTokenId);
        delete _friendship[tokenId];
        delete _friendship[otherTokenId];
    }

    function hasFriendship(address first, address second) public view returns (bool) {
        uint256 fromTokenId = uint256(keccak256(abi.encodePacked(first, second)));
        uint256 toTokenId = uint256(keccak256(abi.encodePacked(second, first)));
        return _exists(fromTokenId) || _exists(toTokenId);
    }

    function getFriendship(uint256 tokenId) public view returns (State memory) {
        return _friendship[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    bytes internal constant URI = 'data:text/plain,{"name":"Friendship","description":"Friendship between A and B","image":"data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' shape-rendering=\'crispEdges\' width=\'512\' height=\'512\'><g transform=\'scale(64)\'><image width=\'8\' height=\'8\' style=\'image-rendering: pixelated;\' href=\'data:image/gif;base64,R0lGODdhEwATAMQAAAAAAPb+Y/7EJfN3NNARQUUKLG0bMsR1SujKqW7wQwe/dQBcmQeEqjDR0UgXo4A0vrlq2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkKAAAALAAAAAATABMAAAdNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGBADs=\'/></g></svg>"}';
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        //string memory baseURI = _baseURI();
        //return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        return string(URI);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 < 0.9.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title WrongNFT
 * @dev Mock NFT for testing
 */
contract WrongNFT is ERC721 {
    constructor() ERC721("My NFT", "MNFT") {}

    function mint(uint256 _tokenId) external payable {
        _safeMint(msg.sender, _tokenId); // Mint the NFT
    }
}

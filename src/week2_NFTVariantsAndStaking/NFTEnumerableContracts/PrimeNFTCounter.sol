// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title PrimeNFTCounter
 * @dev A contract to count the number of NFTs owned by an address with prime token IDs.
 */
contract PrimeNFTCounter {
    address public enumerableNft; // Address of the ERC721Enumerable contract

    /**
     * @dev Constructor to set the address of the ERC721Enumerable contract.
     * @param _enumerableNft Address of the ERC721Enumerable contract.
     */
    constructor(address _enumerableNft) {
        enumerableNft = _enumerableNft;
    }

    /**
     * @dev Internal function to check if a number is prime.
     * @param number The number to check.
     * @return Whether the number is prime or not.
     */
    function isPrime(uint256 number) internal pure returns (bool) {
        if (number <= 1) return false;
        if (number <= 3) return true;
        if (number % 2 == 0 || number % 3 == 0) return false;
        for (uint256 i = 5; i * i <= number; i += 6) {
            if (number % i == 0 || number % (i + 2) == 0) return false;
        }
        return true;
    }

    /**
     * @dev Function to get the total number of NFTs owned by an address with prime token IDs.
     * @param owner The address of the owner.
     * @return totalPrimeNftBalance The total number of NFTs owned by the address with prime token IDs.
     */
    function getPrimeNftTotalBalance(address owner) public view returns (uint256 totalPrimeNftBalance) {
        uint256 totalBalance = IERC721Enumerable(enumerableNft).balanceOf(owner); // Get the total balance of NFTs owned by the address
        for (uint256 index = 0; index < totalBalance; index++) {
            uint256 tokenId = IERC721Enumerable(enumerableNft).tokenOfOwnerByIndex(owner, index); // Get the token ID of the NFT
            if (isPrime(tokenId)) {
                // Check if the token ID is prime
                totalPrimeNftBalance++; // Increment the total count of NFTs with prime token IDs
            }
        }
        return totalPrimeNftBalance; // Return the total count of NFTs with prime token IDs
    }
}

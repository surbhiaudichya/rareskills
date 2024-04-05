// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import {Test} from "forge-std/Test.sol";
import {PrimeNFTCounter} from "../../src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol";
import {EnumerableNFT_Test} from "./EnumerableNFT.t.sol";

contract PrimeNFTCounter_Test is EnumerableNFT_Test {
    /// TESTING CONTRACTS
    PrimeNFTCounter internal primeNFTCounter;

    /// SETUP FUNCTION
    function setUp() public virtual override {
        super.setUp();
        vm.prank(users.admin);
        primeNFTCounter = new PrimeNFTCounter(address(enumerableNFT));
    }

    function test_PrimeNFTCounter_Deployment() external {
        address nft = primeNFTCounter.enumerableNft();
        assertEq(nft, address(enumerableNFT), "enumerableNFT address");
    }

    function setUpMint() internal {
        vm.startPrank(users.alice);
        for (uint256 i = 1; i < 11; ++i) {
            enumerableNFT.mint{value: 0.5 ether}(i);
        }

        vm.stopPrank();
        vm.startPrank(users.bob);

        for (uint256 i = 11; i < 16; ++i) {
            enumerableNFT.mint{value: 0.5 ether}(i);
        }
        // Mint tokens for different scenarios to achieve 100% branch test coverage
        // for the line: if (number % i == 0 || number % (i + 2) == 0) return false;
        enumerableNFT.mint{value: 0.5 ether}(25);
        enumerableNFT.mint{value: 0.5 ether}(49);
        enumerableNFT.mint{value: 0.5 ether}(29);
        enumerableNFT.mint{value: 0.5 ether}(35);

        vm.stopPrank();
    }

    /// @dev it should return total number of even NFT tokenIds
    function test_getPrimeNftTotalBalance() external {
        setUpMint();
        vm.prank(users.alice);
        uint256 alicePrimeNftCount = primeNFTCounter.getPrimeNftTotalBalance(users.alice);
        assertEq(alicePrimeNftCount, 4, "prime nft total count");

        vm.prank(users.bob);
        uint256 bobPrimeNftCount = primeNFTCounter.getPrimeNftTotalBalance(users.bob);
        assertEq(bobPrimeNftCount, 3, "prime nft total count");
    }
}

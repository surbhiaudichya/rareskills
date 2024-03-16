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

        for (uint256 i = 11; i < 21; ++i) {
            enumerableNFT.mint{value: 0.5 ether}(i);
        }
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
        assertEq(bobPrimeNftCount, 4, "prime nft total count");
    }
}

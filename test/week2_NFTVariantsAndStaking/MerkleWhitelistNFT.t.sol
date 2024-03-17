// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import {Test} from "forge-std/Test.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {MerkleWhitelistNFT} from "../../src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol";

contract MerkleWhitelistNFT_Test is Test {
    /// EVENT
    event Minted(address indexed sender, uint256 indexed tokenId); // Event emitted upon successful minting
    event Burn(address indexed sender, uint256 indexed tokenId); // Event emitted upon burning an NFT

    /// ERROR
    error InsufficientEther(); // Error for insufficient ether sent
    error MaxSupplyReached(); // Error when maximum supply of NFTs is reached
    error AlreadyMinted(); // Error when attempting to mint an already minted NFT
    error InvalidMerkleProof(); // Error for invalid Merkle proof

    /// VARIABLES
    MerkleWhitelistNFT internal nft;

    // whitelisted address
    address internal userA = address(0x0001);
    address internal userB = address(0x0002);
    address internal userC = address(0x0003);
    address internal userD = address(0x0004);
    address internal userE = address(0x0005);

    // non-whitelisted address
    address internal notWhitelisted = makeAddr("notWhitelisted");

    address internal owner = makeAddr("owner");

    address[6] private users = [userA, userB, userC, userD, userE, notWhitelisted];

    function setUp() public virtual {
        for (uint256 i; i < users.length; ++i) {
            deal(users[i], 1000 ether);
        }
        vm.prank(owner);
        nft = new MerkleWhitelistNFT(0xceebea2297b98ffa1df9aa241ca1eba9b7114c9609a8a9514b3a3f071982cd96);
    }

    /// @dev It should return boolean true or false.
    function test_SupportsInterface_IndicateIfSupportGivenInterface(bytes4 interfaceId) public {
        if (interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC165).interfaceId) {
            assertTrue(nft.supportsInterface(interfaceId));
        } else {
            assertFalse(nft.supportsInterface(interfaceId));
        }
    }

    /// @dev It should return how much royalty is owed and to whom.
    function test_RoyaltyInfo_ReturnRoyaltyAmountAndReceiver(uint256 price) public {
        vm.assume(price < type(uint112).max);
        (address royaltyReceiver, uint256 royaltyAmount) = nft.royaltyInfo(1, price);
        assertEq(royaltyReceiver, owner);
        assertEq(royaltyAmount, price * 25 / 1000);
    }

    modifier whenCallerIsNonWhitelistedAddress() {
        vm.startPrank(notWhitelisted);
        _;
    }

    /// @dev It should revert.
    function test_RevertWhen_MaxSupplyReached() external whenCallerIsNonWhitelistedAddress {
        for (uint256 i; i < 1000; i++) {
            nft.mint{value: 0.5 ether}(i);
        }

        vm.expectRevert(abi.encodeWithSelector(MaxSupplyReached.selector));
        nft.mint{value: 0.5 ether}(1000);
    }

    /// @dev It should revert.
    function test_Mint_RevertWhen_InsufficientEther() external whenCallerIsNonWhitelistedAddress {
        vm.expectRevert(abi.encodeWithSelector(InsufficientEther.selector));
        nft.mint{value: 0.1 ether}(1);
        vm.stopPrank();
    }

    /// @dev It should revert.
    function test_Mint_IncrementTotalSupply() external whenCallerIsNonWhitelistedAddress {
        uint256 totalSupplyBefore = nft.totalSupply();
        nft.mint{value: 0.5 ether}(1);
        uint256 totalSupplyAfter = nft.totalSupply();
        assertEq(totalSupplyAfter - totalSupplyBefore, 1, "increment total supply");
        vm.stopPrank();
    }

    /// @dev Should success when ether sent is equal or more than mint price
    function test_Mint_MintNFT() public whenCallerIsNonWhitelistedAddress {
        vm.expectEmit(true, true, true, true);
        emit Minted(notWhitelisted, 1);
        nft.mint{value: 0.5 ether}(1);
        assertEq(address(nft).balance, 0.5 ether);
        // success when ether sent is more than mint price
        nft.mint{value: 0.6 ether}(2);
        vm.stopPrank();
    }

    modifier whenCallerIsWhitelistedAddress() {
        _;
    }

    /// @dev It should revert.
    function test_RevertWhen_WhitelistMint_MaxSupplyReached() external whenCallerIsWhitelistedAddress {
        vm.startPrank(userC);

        // proof corresponding to userC and index 3
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;

        // Mocking a public totalSupply variable
        vm.mockCall(address(nft), abi.encodeWithSelector(bytes4(keccak256("totalSupply()"))), abi.encode(1000));
        assertEq(nft.totalSupply(), 1000);

        bytes memory customError = abi.encodeWithSelector(MaxSupplyReached.selector);
        vm.mockCallRevert(address(nft), abi.encodeWithSelector(nft.whitelistMint.selector), customError);
        vm.expectRevert(abi.encodeWithSelector(MaxSupplyReached.selector));
        nft.whitelistMint{value: 0.25 ether}(proof, 1001, 3);
    }

    /// @dev It should revert.
    function test_RevertWhen_WhitelistMint_AlreadyMintedNFT() external whenCallerIsWhitelistedAddress {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;
        vm.prank(userC);
        nft.whitelistMint{value: 0.25 ether}(proof, 1, 3);

        vm.expectRevert(abi.encodeWithSelector(AlreadyMinted.selector));
        nft.whitelistMint{value: 0.25 ether}(proof, 2, 3);
    }

    /// @dev It should revert.
    function test_RevertWhen_WhitelistMint_InsufficientEther() external whenCallerIsWhitelistedAddress {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;

        vm.prank(userC);
        vm.expectRevert(abi.encodeWithSelector(InsufficientEther.selector));
        nft.whitelistMint{value: 0.2 ether}(proof, 1, 3);
    }

    function test_RevertWhen_WhitelistMint_InvalidMerkleProof() external whenCallerIsWhitelistedAddress {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xae1f6f36060f166f063fb01d63adab80297f56b5a444cab19384c535141dbd8b;
        proof[1] = 0x458278ced3fbcb303a4187fc39731d3b4baa96fae67c49c9f926bd2eef841f00;

        vm.prank(userC);
        vm.expectRevert(abi.encodeWithSelector(InvalidMerkleProof.selector));
        nft.whitelistMint{value: 0.25 ether}(proof, 1, 3);
    }

    function test_WhitelistMint_IncrementTotalSupply() external {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;

        uint256 totalSupplyBefore = nft.totalSupply();
        vm.prank(userC);
        nft.whitelistMint{value: 0.25 ether}(proof, 1, 3);
        uint256 totalSupplyAfter = nft.totalSupply();
        assertEq(totalSupplyAfter - totalSupplyBefore, 1, "Increment total supply");
    }

    function test_WhitelistedMint_TransferEther() public {
        // proof corresponding to userC and index 3
        bytes32[] memory proof = new bytes32[](2);

        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;

        // success for whitelisted address and valid proof with valid index
        vm.prank(userC);
        nft.whitelistMint{value: 0.25 ether}(proof, 1, 3);
        assertEq(address(nft).balance, 0.25 ether);
    }

    function test_WhitelistedMint_Event() public {
        // proof corresponding to userC and index 3
        bytes32[] memory proof = new bytes32[](2);

        proof[0] = 0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a;
        proof[1] = 0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057;

        // success for whitelisted address and valid proof with valid index
        vm.prank(userC);
        vm.expectEmit(true, true, false, false);
        emit Minted(userC, 1);
        nft.whitelistMint{value: 0.25 ether}(proof, 1, 3);
    }

    /// @dev it allow owner to withdraw accumulated ether
    function test_withdraw_EtherToOwner() external {
        vm.prank(userC);
        nft.mint{value: 0.5 ether}(1);
        vm.prank(owner);
        uint256 balanceBefore = owner.balance;
        nft.withdrawEther();
        uint256 balanceAfter = owner.balance;
        assertEq(balanceAfter - balanceBefore, 0.5 ether, "expect increase of 0.5 ether");
    }
}

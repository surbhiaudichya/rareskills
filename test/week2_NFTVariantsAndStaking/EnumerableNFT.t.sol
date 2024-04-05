// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import {Test} from "forge-std/Test.sol";
import {EnumerableNFT} from "../../src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol";

contract EnumerableNFT_Test is Test {
    ///  EVENTS
    event Minted(address indexed sender, uint256 indexed tokenId);
    event WithdrawEther(address owner, uint256 amount);

    /// CUSTOM ERRORS
    error InsufficientEther();
    error MaxSupplyReached();
    error InvalidTokenId();
    error ERC721InvalidSender(address);
    error OwnableUnauthorizedAccount(address sender);
    error FailedToSendEther();

    ///  STRUCTS
    struct Users {
        address alice;
        address admin;
        address bob;
    }

    /// TESTING CONTRACTS
    Users internal users;
    EnumerableNFT internal enumerableNFT;

    /// SETUP FUNCTION
    function setUp() public virtual {
        // Create users for testing.
        users = Users({alice: createUser("Alice"), admin: createUser("Admin"), bob: createUser("Bob")});

        vm.prank(users.admin);
        enumerableNFT = new EnumerableNFT();
    }

    ///  HELPERS
    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH.
    function createUser(string memory name) internal returns (address addr) {
        (addr,) = makeAddrAndKey(name);
        vm.deal({account: addr, newBalance: 100 ether});
    }

    /// @dev it should return name and symbol
    function test_Deployment() external {
        string memory actualName = enumerableNFT.name();
        string memory expectedName = "Enumerable NFT";
        assertEq(actualName, expectedName, "name");

        string memory actualSymbol = enumerableNFT.symbol();
        string memory expectedSymbol = "ENFT";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    /// @dev it should revert
    function test_RevertWhen_Mint_TokenIdIsNotInRange(uint256 id) external {
        vm.assume(id > 100 || id < 1);
        vm.expectRevert(abi.encodeWithSelector(InvalidTokenId.selector));
        enumerableNFT.mint(id);
    }

    /// @dev it should revert
    function test_RevertWhen_Mint_TotalSupplyIsReached() external {
        vm.startPrank(users.alice);
        for (uint256 i = 1; i < 21; i++) {
            enumerableNFT.mint{value: 0.5 ether}(i);
        }

        vm.expectRevert(abi.encodeWithSelector(MaxSupplyReached.selector));
        enumerableNFT.mint{value: 0.5 ether}(21);
    }

    /// @dev it should revert
    function test_RevertWhen_Mint_InsufficientEther() external {
        vm.prank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientEther.selector));
        enumerableNFT.mint{value: 0.4 ether}(1);
    }

    /// @dev it should revert if NFT is already minted

    function test_RevertWhen_Mint_NFTisAlreadyExist(uint256 id) external {
        id = bound(id, 1, 100);
        vm.prank(users.alice);
        enumerableNFT.mint{value: 0.5 ether}(id);

        vm.prank(users.bob);
        vm.expectRevert(abi.encodeWithSelector(ERC721InvalidSender.selector, address(0)));
        enumerableNFT.mint{value: 0.5 ether}(id);
    }

    function test_RevertWhen_Withdraw_EtherByUnauthorizedAccount() external {
        vm.prank(users.alice);
        enumerableNFT.mint{value: 0.5 ether}(1);

        vm.prank(users.bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.bob));
        enumerableNFT.withdrawEther();
    }

    /// @dev it  should mint NFT to caller
    function test_Mint_NftToCaller(uint256 id) external {
        id = bound(id, 1, 100);
        vm.prank(users.alice);
        enumerableNFT.mint{value: 0.5 ether}(id);
        address actualOwner = enumerableNFT.ownerOf(id);
        address expectedOwner = users.alice;
        assertEq(actualOwner, expectedOwner, "Mint given NFT to caller");
    }

    /// @dev it allow owner to withdraw accumulated ether
    function test_withdraw_EtherToOwner() external {
        vm.prank(users.alice);
        enumerableNFT.mint{value: 0.5 ether}(1);
        vm.prank(users.admin);
        uint256 balanceBefore = users.admin.balance;
        enumerableNFT.withdrawEther();
        uint256 balanceAfter = users.admin.balance;
        assertEq(balanceAfter - balanceBefore, 0.5 ether, "expect increase of 0.5 ether");
    }

    /// @dev it should emit Mint event
    function test_Mint_Event(uint256 id) external {
        id = bound(id, 1, 100);
        vm.prank(users.alice);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit Minted(users.alice, id);
        enumerableNFT.mint{value: 0.5 ether}(id);
    }

    /// @dev It should revert when withdrawEther low-level call return false
    function test_RevertWhen_withdrawEther_FailedToSendEther() external {
        vm.startPrank(users.admin);
        // Deploy Rejector contract
        Rejector rejector = new Rejector();
        // Set the Rejector contract as the owner of the NFT contract
        enumerableNFT.transferOwnership(address(rejector));
        vm.stopPrank();
        vm.startPrank(address(rejector));
        enumerableNFT.acceptOwnership();
        // Call withdrawEther, it should revert due to the failure of ether transfer
        vm.expectRevert(abi.encodeWithSelector(FailedToSendEther.selector));
        enumerableNFT.withdrawEther();
        vm.stopPrank();
    }

    /// @dev it should emit WithdrawEther event
    function test_WithdrawEther_Event() external {
        vm.prank(users.alice);
        enumerableNFT.mint{value: 0.5 ether}(1);
        vm.prank(users.admin);
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit WithdrawEther(users.admin, 0.5 ether);
        enumerableNFT.withdrawEther();
    }
}

// Helper contract  To test the fail condition of “(bool sent,)” we need the Ether transfer to fail.
contract Rejector {
    fallback() external {
        revert("receive reverted");
    }
}

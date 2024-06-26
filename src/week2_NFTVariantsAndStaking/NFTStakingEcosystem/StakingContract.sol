// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {RewardToken} from "./RewardToken.sol";

/**
 * @title StakingContract
 * @author Surbhi Audichya
 * @notice This contract allows users to stake ERC721 tokens and receive rewards in ERC20 tokens.
 */
contract StakingContract is IERC721Receiver {
    // Immutable address of the ERC721 contract
    address public immutable nft;
    // Immutable instance of the RewardToken contract
    RewardToken public immutable rewardToken;
    // Reward amount per 24 hours
    uint256 public constant REWARD_PER_DAY = 10e18;
    // Duration of one day
    uint256 public constant PER_DAY = 1 days;
    // Timestamp of the last reward calculation
    uint256 public lastRewardTimestamp;
    // Accumulated reward per token
    uint256 public accRewardPerToken;

    // Struct to represent a user
    struct User {
        uint256 totalBalance; // Total number of tokens staked by the user
        uint256 debt; // Debt accumulated by the user (for reward calculation)
    }

    // Mapping to track stakes by token ID
    mapping(uint256 tokenId => address originalOwner) public stakes;

    // Mapping to track users' balances and debts
    mapping(address => User) public users;

    // Custom errors
    error IncorrectOwner(); // Error thrown when a user tries to withdraw a stake that they don't own
    error NFTContractOnly(); // Error thrown when a non-NFT contract tries to interact with the staking contract
    error ZeroAdress(); // Error thrown when zero address

    // Events
    event NFTDeposited(address indexed user, uint256 tokenId); // Event emitted when an NFT is deposited
    event NFTWithdrawn(address indexed user, uint256 tokenId); // Event emitted when an NFT is withdrawn
    event RewardsClaimed(address indexed user, uint256 rewardToMint); // Event emitted when rewards are claimed

    // Constructor function
    constructor(address _nft) {
        if (_nft == address(0)) {
            revert ZeroAdress();
        }
        nft = _nft;
        rewardToken = new RewardToken(); // Deploy a new instance of the RewardToken contract
    }

    /**
     * @notice Handles the reception of ERC721 tokens
     * @dev This function is called when ERC721 tokens are transferred to this contract
     * @param from The address sending the ERC721 tokens
     * @param tokenId The ID of the ERC721 token being transferred
     * @return selector The ERC721 interface ID
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        public
        override
        returns (bytes4 selector)
    {
        // Ensure the token is coming from the NFT contract
        if (msg.sender != address(nft)) {
            revert NFTContractOnly();
        }
        // Update the accumulated reward
        updateReward();
        uint256 _accRewardPerToken = accRewardPerToken;
        //Use storage pointers instead of memory
        User storage _users = users[from];
        uint256 _userTotalBalance = _users.totalBalance;
        // Calculate the reward to be minted
        uint256 rewardToMint = _userTotalBalance * _accRewardPerToken - _users.debt;
        // Update the user's balance and debt
        _users.totalBalance = _userTotalBalance + 1;
        _users.debt = _users.totalBalance * _accRewardPerToken;
        // Record the stake
        stakes[tokenId] = from;
        if (rewardToMint > 0) rewardToken.mint(from, rewardToMint);
        emit RewardsClaimed(from, rewardToMint);

        // Emit an event for the deposit
        emit NFTDeposited(from, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Allows a user to withdraw their staked ERC721 token and claim accrued rewards
     * @dev Only the original owner of the stake can withdraw
     * @param tokenId The ID of the ERC721 token to be withdrawn
     */
    function withdraw(uint256 tokenId) external {
        // Ensure only the original owner can withdraw
        if (msg.sender != stakes[tokenId]) {
            revert IncorrectOwner();
        }
        // Update the accumulated reward
        updateReward();
        //Use storage pointers instead of memory
        User storage _users = users[msg.sender];
        uint256 _accRewardPerToken = accRewardPerToken;
        uint256 _userTotalBalance = _users.totalBalance;
        // Calculate the reward to be minted
        uint256 rewardToMint = _userTotalBalance * _accRewardPerToken - _users.debt;
        // Mint the reward tokens and emit an event
        rewardToken.mint(msg.sender, rewardToMint);
        emit RewardsClaimed(msg.sender, rewardToMint);
        // Update the user's balance and debt
        _users.totalBalance = _userTotalBalance - 1;
        _users.debt = _users.totalBalance * _accRewardPerToken;
        // Delete the stake
        delete stakes[tokenId];
        // Transfer the NFT back to the owner
        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);
        // Emit an event for the withdrawal
        emit NFTWithdrawn(msg.sender, tokenId);
    }

    /**
     * @notice Updates the accumulated reward per token
     * @dev This function calculates the accumulated reward per token based on the time elapsed since the last update
     */
    function updateReward() internal {
        uint256 _lastRewardTimestamp = lastRewardTimestamp;
        if (block.timestamp > _lastRewardTimestamp) {
            if (_lastRewardTimestamp > 0) {
                uint256 timeSinceLastReward = block.timestamp - _lastRewardTimestamp;
                // Calculate the reward accumulated since the last update
                uint256 rewardAccumulated = (REWARD_PER_DAY * timeSinceLastReward) / PER_DAY;
                // Update the accumulated reward per token
                accRewardPerToken += rewardAccumulated;
            }
            // Update the last reward timestamp
            lastRewardTimestamp = block.timestamp;
        }
    }
}

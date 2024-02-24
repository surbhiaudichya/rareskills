// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom error messages
error InvalidSellerAddress();
error InvalidTokenAddress();
error InvalidAmount();
error InsufficientAllowance();
error TokensNotReleased();
error TokensNotReadyForRelease();

/**
 * @title MultiPartyEscrow
 * @notice This smart contract facilitates escrow agreements between buyers and sellers for ERC20 tokens.
 * Users can create escrow agreements by depositing ERC20 tokens, which are locked until a specified release time.
 * Once the release time is reached, the seller can withdraw the tokens.
 * This contract does not support tokens with dynamic supply adjustments (e.g., rebasing tokens).
 * Using rebasing tokens with this contract may result in unexpected behavior and loss of funds.
 * Users are advised to ensure that the ERC20 tokens used in escrow agreements are compatible with this contract.
 */
contract MultiPartyEscrow is ReentrancyGuard {
    // Wrappers around ERC20 operations that throw on failure (when the token contract returns false).
    // Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful.
    using SafeERC20 for IERC20;

    // Struct representing an escrow agreement
    struct Escrow {
        address buyer; // Address of the buyer
        address seller; // Address of the seller
        address token; // Address of the ERC20 token
        uint256 amount; // Amount of tokens in the escrow
        uint256 releaseTime; // Time when tokens can be released by the seller
        bool released; // Flag indicating if tokens have been released
    }

    // Mapping to store escrow agreements by buyer's address
    mapping(address => Escrow) public escrows;

    // Events emitted when tokens are deposited or released
    event TokensDeposited(address indexed buyer, address indexed seller, uint256 amount);
    event TokensReleased(address indexed buyer, address indexed seller, uint256 amount);

    /**
     * @notice Creates an escrow agreement.
     * @dev The buyer deposits ERC20 tokens into the escrow.
     * @param _seller Address of the seller.
     * @param _token Address of the ERC20 token.
     * @param _amount Amount of tokens to be deposited.
     */
    function createEscrow(address _seller, address _token, uint256 _amount) external nonReentrant {
        // Validate input parameters
        if (_seller == address(0)) revert InvalidSellerAddress();
        if (_token == address(0)) revert InvalidTokenAddress();
        if (_amount == 0) revert InvalidAmount();

        // Check allowance
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        if (allowance < _amount) revert InsufficientAllowance();

        // Calculate release time 3 days from now
        uint256 releaseTime = block.timestamp + (3 days);

        // Get token balance before and after transfer to handle fee-on-transfer tokens
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        uint256 actualAmountTransferred = balanceAfter - balanceBefore;

        // Store escrow agreement
        escrows[msg.sender] = Escrow({
            buyer: msg.sender,
            seller: _seller,
            token: _token,
            amount: actualAmountTransferred,
            releaseTime: releaseTime,
            released: false
        });

        // Emit event
        emit TokensDeposited(msg.sender, _seller, actualAmountTransferred);
    }

    /**
     * @notice Releases tokens to the seller.
     * @dev Only the seller can release tokens after the specified release time.
     */
    function releaseTokens() external {
        // Retrieve escrow agreement
        Escrow storage escrow = escrows[msg.sender];

        // Validate sender is the seller and tokens can be released
        if (escrow.seller != msg.sender) revert TokensNotReleased();
        if (block.timestamp < escrow.releaseTime) {
            revert TokensNotReadyForRelease();
        }
        if (escrow.released) revert TokensNotReleased();

        // Mark tokens as released
        escrow.released = true;

        // Transfer tokens to the seller
        IERC20(escrow.token).safeTransfer(escrow.seller, escrow.amount);

        // Emit event
        emit TokensReleased(escrow.buyer, escrow.seller, escrow.amount);
    }
}

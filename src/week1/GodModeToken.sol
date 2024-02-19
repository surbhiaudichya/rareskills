// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Custom error to handle only special address invoking functions
error OnlySpecialAddress(address caller);
// Custom error for zero address
error ZeroAddress();

/**
 * @title GodModeToken
 * @author Surbhi Audichya
 * @notice Token with god mode. A special address is able to transfer tokens between addresses at will.
 */

contract GodModeToken is ERC20 {
    /// @notice Event emitted when a god mode transfer occurs.
    event GodModeTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @dev  Address with god mode access
    address private immutable _godModeAddress;

    /**
     * @dev Constructor to initialize the token with the specified initial supply.
     * @param godModeAddress Special Address.
     * @param initialSupply The initial supply of the token.
     */
    constructor(
        address godModeAddress,
        uint256 initialSupply
    ) ERC20("God Mode Token", "GMT") {
        /// Ensure the special address is not zero
        if (_godModeAddress == address(0)) {
            revert ZeroAddress();
        }
        _godModeAddress = godModeAddress;
        // Mint initial supply to the contract deployer
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows the god mode address to transfer tokens from one address to another.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param value The amount of tokens to transfer.
     * @return success A boolean indicating whether the transfer was successful.
     */
    function godModeTransfer(
        address from,
        address to,
        uint256 value
    ) external returns (bool success) {
        // Ensure only the god mode address can invoke this function
        if (msg.sender != _godModeAddress) {
            revert OnlySpecialAddress(msg.sender);
        }
        // Perform the transfer
        _transfer(from, to, value);
        emit GodModeTransfer(from, to, value);
        return true;
    }

    /**
     * @dev Returns the address with god mode privileges.
     */
    function godModeAddress() external view returns (address) {
        return _godModeAddress;
    }
}

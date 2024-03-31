// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";

contract PairERC20 is ERC20 {
    string internal _name = "Pair Liquidty Token";
    string internal _symbol = "PLT";

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
}

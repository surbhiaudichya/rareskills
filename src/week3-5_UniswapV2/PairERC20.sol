// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";

contract PairERC20 is ERC20 {
    string internal constant _name = "Pair Liquidity Token";
    string internal constant _symbol = "PLT";

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
}

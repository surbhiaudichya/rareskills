// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Pair.sol";

contract Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    error IdenticalAddresses();
    error ZeroAddress();
    error PairExist();
    error NotAuthorized();

    constructor(address _feeToSetter) {
        if (_feeToSetter == address(0)) {
            revert ZeroAddress();
        }
        feeToSetter = _feeToSetter;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert ZeroAddress();
        }
        if (getPair[token0][token1] != address(0)) revert PairExist();
        bytes memory bytecode = type(Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        if (_feeTo == address(0)) {
            revert ZeroAddress();
        }
        if (msg.sender != feeToSetter) {
            revert NotAuthorized();
        }
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) {
            revert NotAuthorized();
        }
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}

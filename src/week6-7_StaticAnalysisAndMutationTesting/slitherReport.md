# Slither Report Findings

## File(s) affected: Week3_5_UniswapV2/Pair.sol

### Finding 1: "Arbitrary from" address in transferFrom function call

**Description:** Slither flagged the usage of an "arbitrary from" address in the transferFrom function call in the flashLoan function of the Pair contract.

Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/week3-5_UniswapV2/Pair.sol#141-174) uses arbitrary from in transferFrom: SafeTransferLib.safeTransferFrom(token,address(receiver),address(this),amount + fee) (src/week3-5_UniswapV2/Pair.sol#168)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom>

**Analysis:**

- **Context:** The flashLoan function implements the ERC3156 flash loan standard, where the receiver contract initiates and handles the flash loan.
- **Intended Behavior:** The transferFrom operation is performed from the perspective of the receiver contract, which is responsible for handling the flash loan and repayment.
- **ERC3156 Standard Compliance:** The usage of `address(receiver)` as the from address aligns with the ERC3156 standard's specification of a "pull" architecture for flash loans, allowing flexibility in loan initiators and receivers.
- **Conclusion:** False Positive. While the usage of `address(receiver)` as the from address aligns with the ERC3156 standard's specification of a "pull" architecture for flash loans, it is essential to consider the security implications related to token approvals. The flash loan initiator, in this case, the Pair contract, relies on the receiver contract to have appropriate approvals for the flash loan amount and fee before initiating the loan. However, if the receiver contract does not implement a mechanism to verify the initiator's trustworthiness or if it has indiscriminate approvals, it could be vulnerable to exploitation. Without these safeguards, the flash loan mechanism could potentially be abused, leading to unauthorized token transfers and financial loss.

### Finding 2: Weak PRNG usage in Pair._update function

**Description:** Slither flagged the usage of a weak Pseudo-Random Number Generator (PRNG) in the _update function of the Pair contract.

Pair._update(uint256,uint256,uint112,uint112) (src/week3-5_UniswapV2/Pair.sol#354-376) uses a weak PRNG: "blockTimestamp = uint32(block.timestamp % 2 ** 32) (src/week3-5_UniswapV2/Pair.sol#358)"
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG>

**Analysis:**

- **Context:** The _update function is responsible for updating various parameters and calculations related to the Pair contract, including price calculations based on time (TWAP).
- **Issue:** Slither flagged the usage of weak PRNG due to the modulo operation on block.timestamp. However, this usage is intended to handle arithmetic overflow and underflow by using modular arithmetic, ensuring that overflowing the timestamp does not cause issues.
- **Conclusion:** False Positive. The usage of `uint32(block.timestamp % 2 ** 32)` in this context is not a vulnerability as it is used to handle arithmetic overflow and underflow and does not pose a security risk. It aligns with the expected behavior based on the rules of modular arithmetic. e.g Because we are using a uint32 to represent it, there won’t be any negative numbers. let’s assume we overflow at 100 for the sake of simplicity. If we snapshot at time 98 and consult the price oracle at time 4, then 6 seconds have passed. 4 - 98 % 100 = 6, as expected.

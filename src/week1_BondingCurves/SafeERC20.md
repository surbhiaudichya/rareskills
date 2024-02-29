# Purpose of SafeERC20

SafeERC20 is a wrapper designed to address issues within the ERC20 token standard and its implementations in smart contracts. It provides solutions to common vulnerabilities that can lead to loss of funds or unexpected behavior in Ethereum-based applications.

## Security Issues Addressed by SafeERC20

### Lack of Reversion in ERC20 `transfer` and `transferFrom`

One of the vulnerabilities in the ERC20 standard is that both the `transfer` and `transferFrom` functions do not revert on failure. According to the ERC20 specification, these functions should return a boolean indicating success or failure, but they do not automatically revert the transaction in case of failure. Consequently, if a transfer operation fails, it is up to the calling contract to manually check the return value and revert the transaction if necessary.

Moreover, relying solely on the boolean return value may not provide sufficient assurance of the transaction's success. To ensure proper handling of failed transactions, it is recommended to also decode the return data and verify if it equals "true". This additional step helps mitigate the risk of unexpected behavior due to discrepancies between the expected boolean return and the actual outcome.

- **Solution:** use OpenZeppelin’s SafeERC20 lib `safeTransfer` and `safeTransferFrom`

### ERC20 `approve` Race-Condition

There is a known race condition in the ERC20 `approve` function, which attackers can exploit to steal tokens. changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate transaction ordering.

### Double-Spending Allowances

SafeERC20 addresses the risk of double-spending allowances by providing functions such as `increaseAllowance` and `decreaseAllowance` that guarantee the integrity of allowance adjustments. Without proper safeguards, attackers could exploit vulnerabilities in allowance management to steal tokens.

- **Solution:** One possible solution to mitigate this race condition is to first reduce the spender’s allowance to 0 and set the desired value afterwards or by using OpenZeppelin’s SafeERC20 lib `safeIncreaseAllowance` and `safeDecreaseAllowance` or `forceApprove` Meant to be used with tokens that require the approval to be set to zero before setting it to a non-zero value, such as USDT.

### Lack of Contract Verification in SafeTransferLib

Solmate's implementation of ERC20 SafeTransferLib, while efficient in terms of gas usage, lacks a crucial security check. It does not verify that the target address of an ERC20 token transfer is actually a contract, which can lead to unintended consequences and potential loss of funds.

- **Solution:** verify the address code size before interacting with it, or use OpenZeppelin’s SafeERC20, which does just that.

## When to Use SafeERC20

The intention of SafeERC20 should be to wrap non-compliant ERC20 functions, whenever there is a need for secure ERC20 token transfers and allowance management in smart contracts. It offers protection against common attack vectors and ensures the integrity of token operations, reducing the risk of financial losses and contract vulnerabilities.

By adopting SafeERC20, developers can enhance the security and reliability of their Ethereum-based applications, safeguarding user funds and mitigating potential exploits.

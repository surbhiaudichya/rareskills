# Problems Solved by ERC777 and ERC1363

## Issues with ERC20 Tokens

### Approve and Transfer Two-Step Transaction Flow

- In ERC20, there's an unavoidable two-step transaction process for transferring tokens, involving an initial approval transaction followed by the actual transfer.
- This flow is cumbersome for users and can lead to confusion and inefficiency, especially in decentralized applications (DApps) such as decentralized exchanges (DEXs).

### Lack of Reverting in Transfer and TransferFrom Functions

- ERC20's transfer and transferFrom functions do not revert on failure, which can lead to unexpected behavior and loss of funds if transactions fail silently.
- Users may not be aware of transaction failures, leading to potential token loss or stuck transactions.

### Approve Function Allowing Infinite Approvals

- The approve function in ERC20 allows users to grant unlimited spending permissions (infinite approvals) to another address, which poses security risks.
- Malicious actors can exploit infinite approvals to spend tokens beyond the intended scope or perpetrate token draining attacks.

### Spam Tokens and Loss of Funds

- ERC20 tokens can be sent to non-validated or incorrect recipient addresses, resulting in the loss of funds.
- Users may accidentally send tokens to smart contracts or invalid addresses, causing irreversible loss of funds.

## ERC777: Enhanced Token Standard

### Addressing Trapped Tokens in Contracts

- ERC777 was introduced to address the issue of tokens getting trapped in contracts by adding hooks that enable contracts to reject unwanted tokens.
- Contracts implementing ERC777 can reject token transfers from non-approved addresses, preventing loss of funds due to accidental transfers.

### Introduction of Hooks for Enhanced Functionality

- ERC777 introduces hooks, which are payable functions for tokens, enabling more complex interactions and functionalities.
- Hooks allow contracts to execute custom logic before and after token transfers, enhancing flexibility and usability.

### Different from ERC20 in Various Aspects

- ERC777 introduces delegated transfer capabilities through operators, allowing operators to transfer tokens on behalf of token holders without explicit approvals.
- Hooks in ERC777 are implemented by sender and recipient contracts, providing more control and customization options compared to ERC20.
- ERC777 tokens support send/receive hooks, enabling contracts and addresses to react to incoming token transfers, enhancing interoperability and utility.

### Issues with ERC777

- The introduction of hooks in ERC777 opens up the risk of reentrancy attacks, where malicious contracts can exploit callback functions to reenter the token contract and manipulate state.
- ERC777's complexity and the presence of hooks require careful review and auditing to ensure security and reliability.

## ERC1363: Payable Token Standard

### Introduction of a Payable Token Standard

- ERC1363 defines a token interface for ERC20 tokens that supports executing recipient code after transfer or approval.
- It allows token payments to trigger recipient code execution in a single transaction, eliminating the need for separate approval and payment transactions.

### Solutions Provided by ERC1363

- ERC1363 solves the issue of executing code after ERC20 token transfers or approvals, enabling seamless token payments and interactions.
- With ERC1363, users can make token payments and trigger recipient code execution in a single transaction, reducing gas costs and simplifying token transactions.

### Comparison with ERC20 and ERC223

- ERC1363 follows a pattern similar to ERC721/ERC1155 and offers advantages over ERC20 in terms of simplicity and usability.
- Unlike ERC20, ERC1363 allows tokens to execute recipient code after transfers or approvals, improving the user experience and efficiency of token transactions.

## Summary

- ERC777 and ERC1363 address various limitations and shortcomings of ERC20 tokens, providing enhanced functionalities, security, and usability.
- While ERC777 introduces hooks for advanced token interactions, it also brings complexity and potential security risks, such as reentrancy attacks.
- ERC1363 offers a simpler and more efficient token payment mechanism compared to ERC20, enabling seamless token transactions with recipient code execution in a single transaction.

# Slither Report Findings

## Finding 1: Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/week3-5_UniswapV2/Pair.sol#141-174) uses arbitrary from in transferFrom: SafeTransferLib.safeTransferFrom(token,address(receiver),address(this),amount + fee) (src/week3-5_UniswapV2/Pair.sol#168)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom>

- **Conclusion:** False Positive. While the usage of `address(receiver)` as the from address aligns with the ERC3156 standard's specification of a "pull" architecture for flash loans, it is essential to consider the security implications related to token approvals. The flash loan initiator, in this case, the Pair contract, relies on the receiver contract to have appropriate approvals for the flash loan amount and fee before initiating the loan. However, if the receiver contract does not implement a mechanism to verify the initiator's trustworthiness or if it has indiscriminate approvals, it could be vulnerable to exploitation. Without these safeguards, the flash loan mechanism could potentially be abused, leading to unauthorized token transfers and financial loss.

## Finding 2: Pair._update(uint256,uint256,uint112,uint112) (src/week3-5_UniswapV2/Pair.sol#354-376) uses a weak PRNG: "blockTimestamp = uint32(block.timestamp % 2 ** 32) (src/week3-5_UniswapV2/Pair.sol#358)"

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG>

- **Conclusion:** False Positive. Slither flagged the usage of weak PRNG due to the modulo operation on block.timestamp.However, The usage of `uint32(block.timestamp % 2 ** 32)` in this context is not a vulnerability as it is used to handle arithmetic overflow and underflow and does not pose a security risk. It aligns with the expected behavior based on the rules of modular arithmetic. e.g Because we are using a uint32 to represent it, there won’t be any negative numbers. let’s assume we overflow at 100 for the sake of simplicity. If we snapshot at time 98 and consult the price oracle at time 4, then 6 seconds have passed. 4 - 98 % 100 = 6, as expected.

## Finding 3: Pair.swap(uint256,address,address) (src/week3-5_UniswapV2/Pair.sol#224-291) uses a dangerous strict equality: - amountTokenIn == 0 (src/week3-5_UniswapV2/Pair.sol#270)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities>

- **Conclusion:** False Positive. The strict equality check ensures that the amountTokenIn mot zero before proceeding with the swap, which is appropriate for validation purposes. Because If the balance of the input token is greater than the reserve, set amountTokenIn to the difference between the balance and the reserve; otherwise, set amountTokenIn to 0.

## Finding 4: Reentrancy in Factory.createPair(address,address) (src/week3-5_UniswapV2/Factory.sol#24-43 External calls: - Pair(pair).initialize(token0,token1) (src/week3-5_UniswapV2/Factory.sol#38 State variables written after the call(s)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1>

- **Conclusion:** False Positive. The initialize function in the trusted contract Pair contract simply assigns values to state variables and doesn't involve any external calls or complex logic that could introduce reentrancy vulnerabilities. Therefore, the reported reentrancy issue in Factory.createPair is calling a trusted Pair contract so this pattern could be considered safe.

## Finding 5: Reentrancy in Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/week3-5_UniswapV2/Pair.sol#141-174): External calls: - receiver.onFlashLoan(msg.sender,token,amount,fee,data) != keccak256(bytes)(ERC3156FlashBorrower.onFlashLoan) (src/week3-5_UniswapV2/Pair.sol#163) State variables written after the call(s). Pair.blockTimestampLast can be used in cross function reentrancies

- **Conclusion:** False Positive. The function first retrieves the current reserves using the getReserves function, ensuring that it operates on the most up-to-date state. This is followed by the execution of external calls and state updates. The subsequent calls to update the reserves in the _update function shows n reentrancy vulnerabilities.

## Finding 6: Reentrancy in StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#96-121):  External calls

        - rewardToken.mint(msg.sender,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#110)
        State variables written after the call(s):
        - delete stakes[tokenId] (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#116)
        StakingContract.stakes (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#34) can be used in cross function reentrancies:
        - StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#61-89)
        - StakingContract.stakes (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#34)
        - StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#96-121)
        - _users.totalBalance = _userTotalBalance - 1 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#113)
        StakingContract.users (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#37) can be used in cross function reentrancies:
        - StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#61-89)
        - StakingContract.users (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#37)
        - StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#96-121)
        - _users.debt = _users.totalBalance * _accRewardPerToken (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#114)
        StakingContract.users (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#37) can be used in cross function reentrancies:
        - StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#61-89)
        - StakingContract.users (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#37)
        - StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#96-121)

- **Conclusion:** True positives. the StakingContract identified a reentrancy vulnerability in the withdraw function. This vulnerability stems from the sequence of operations, particularly the minting of reward tokens before updating the contract's state and deleting the stake.
To address this issue, rearranging the order of operations within the withdraw function to first handle state modifications and stake deletion before minting reward tokens is recommended. This adjustment mitigates the risk of reentrancy attacks and enhances the overall security of the staking ecosystem.

## Finding 7: GodModeToken.constructor(address,uint256).godModeAddress (src/week1_BondingCurves/GodModeToken.sol#28) shadows: - GodModeToken.godModeAddress() (src/week1_BondingCurves/GodModeToken.sol#59-61) (function)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#local-variable-shadowing>

- **Conclusion:** True positives. Slither flagged a local variable shadowing issue in the GodModeToken contract, where the godModeAddress constructor parameter conflicted with the godModeAddress function. To resolve this, the function name was changed to getGodModeAddress, ensuring clarity and mitigating potential confusion. This adjustment enhances the contract's robustness and security, reducing the risk of vulnerabilities.

## Finding 8: PrimeNFTCounter.constructor(address)._enumerableNft (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#17) lacks a zero-check on follwoing

- **Conclusion:** True positives
                - enumerableNft = _enumerableNft (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#18)
StakingContract.constructor(address)._nft (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#49) lacks a zero-check on :
                - nft = _nft (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#50)
Factory.constructor(address)._feeToSetter (src/week3-5_UniswapV2/Factory.sol#20) lacks a zero-check on :
                - feeToSetter = _feeToSetter (src/week3-5_UniswapV2/Factory.sol#21)
Factory.setFeeTo(address)._feeTo (src/week3-5_UniswapV2/Factory.sol#45) lacks a zero-check on :
                - feeTo = _feeTo (src/week3-5_UniswapV2/Factory.sol#49)
Factory.setFeeToSetter(address)._feeToSetter (src/week3-5_UniswapV2/Factory.sol#52) lacks a zero-check on :
                - feeToSetter = _feeToSetter (src/week3-5_UniswapV2/Factory.sol#56)
- **Conclusion:** False Positives. the Pair contract's initialize function,  is actually secure due to checks performed in the Factory contract's createPair function. So, we do not need to recheck in initialize.
Pair.initialize(address,address)._token0 (src/week3-5_UniswapV2/Pair.sol#60) lacks a zero-check on :
                - token0 = _token0 (src/week3-5_UniswapV2/Pair.sol#64)
Pair.initialize(address,address)._token1 (src/week3-5_UniswapV2/Pair.sol#60) lacks a zero-check on :
                - token1 = _token1 (src/week3-5_UniswapV2/Pair.sol#65)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation>

## Finding 9: PrimeNFTCounter.getPrimeNftTotalBalance(address) (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#46-56) has external calls inside a loop: tokenId = IERC721Enumerable(enumerableNft).tokenOfOwnerByIndex(owner,index) (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#49)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop>

- **Conclusion:** False Positives. the loop's behavior is intended and necessary for the contract's functionality.

## Finding 10: Reentrancy in MultiPartyEscrow.createEscrow(address,address,uint256) (src/week1_BondingCurves/MultiPartyEscrow.sol#54-85)

        External calls:
        - IERC20(_token).safeTransferFrom(msg.sender,address(this),_amount) (src/week1_BondingCurves/MultiPartyEscrow.sol#69)
        State variables written after the call(s):
        - escrows[msg.sender] = Escrow({buyer:msg.sender,seller:_seller,token:_token,amount:actualAmountTransferred,releaseTime:releaseTime,released:false}) (src/week1_BondingCurves/MultiPartyEscrow.sol#74-81)

- **Conclusion:** False Positives. The function already utilizes the nonReentrant modifier to prevent reentrancy attacks, and updating state variables after the external call to safeTransferFrom is necessary because it calculates the actual transferred amount for fee on transfer token.
  
## Finding 11: Reentrancy in StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#65-93)

        External calls:
        - rewardToken.mint(from,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#86)
        State variables written after the call(s):
        - stakes[tokenId] = from (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#89)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-2>
  
- **Conclusion:** True Positives. Moving the state update stakes[tokenId] = from; before the external call to rewardToken.mint(from, rewardToMint); will mitigate the reentrancy vulnerability. This adjustment ensures that state changes are made before interacting with external contracts, reducing the risk of reentrancy attacks.

## Finding 12: Event emitted after the call(s)

Reentrancy in BondingCurve.continuousTokenMint(uint256) (src/week1_BondingCurves/BondingCurve.sol#42-68)
        External calls:
        - (sent) = address(msg.sender).call{value: msg.value - totalCost}() (src/week1_BondingCurves/BondingCurve.sol#61)
        Event emitted after the call(s):
        - TokenPurchased(msg.sender,purchaseAmount,totalCost) (src/week1_BondingCurves/BondingCurve.sol#67)
        -
Reentrancy in Factory.createPair(address,address) (src/week3-5_UniswapV2/Factory.sol#27-46)
        External calls:
        - Pair(pair).initialize(token0,token1) (src/week3-5_UniswapV2/Factory.sol#41)
        Event emitted after the call(s):
        - PairCreated(token0,token1,pair,allPairs.length) (src/week3-5_UniswapV2/Factory.sol#45)

Reentrancy in Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/week3-5_UniswapV2/Pair.sol#141-174):
        External calls:
        - receiver.onFlashLoan(msg.sender,token,amount,fee,data) != keccak256(bytes)(ERC3156FlashBorrower.onFlashLoan) (src/week3-5_UniswapV2/Pair.sol#163)
        Event emitted after the call(s):
        - Sync(reserve0,reserve1) (src/week3-5_UniswapV2/Pair.sol#375)
                -_update(balance0,balance1,_reserve0,_reserve1) (src/week3-5_UniswapV2/Pair.sol#172)
  
 Reentrancy in StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#65-93):
        External calls:
        - rewardToken.mint(from,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#88)
        Event emitted after the call(s):
        - NFTDeposited(from,tokenId) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#91)
        - RewardsClaimed(from,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#89)

Reentrancy in MultiPartyEscrow.releaseTokens() (src/week1_BondingCurves/MultiPartyEscrow.sol#91-110):
        External calls:
        - IERC20(escrow.token).safeTransfer(escrow.seller,escrow.amount) (src/week1_BondingCurves/MultiPartyEscrow.sol#106)
        Event emitted after the call(s):
        - TokensReleased(escrow.buyer,escrow.seller,escrow.amount) (src/week1_BondingCurves/MultiPartyEscrow.sol#109)

Reentrancy in BondingCurve.sellTokens(uint256) (src/week1_BondingCurves/BondingCurve.sol#74-103):
        External calls:
        - (sent) = address(msg.sender).call{value: totalCost}() (src/week1_BondingCurves/BondingCurve.sol#97)
        Event emitted after the call(s):
        - TokenSold(msg.sender,depositAmount,totalCost) (src/week1_BondingCurves/BondingCurve.sol#102)

Reentrancy in StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#100-125):
        External calls:
        - rewardToken.mint(msg.sender,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#114)
        Event emitted after the call(s):
        - RewardsClaimed(msg.sender,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#115)

Reentrancy in StakingContract.withdraw(uint256) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#100-125):
        External calls:
        - rewardToken.mint(msg.sender,rewardToMint) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#114)
        - ERC721(nft).safeTransferFrom(address(this),msg.sender,tokenId) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#122)
        Event emitted after the call(s):
        - NFTWithdrawn(msg.sender,tokenId) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#124)

Reentrancy in EnumerableNFT.withdrawEther() (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#58-65):
        External calls:
        - (sent) = address(owner()).call{value: amount}() (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#60)
        Event emitted after the call(s):
        - WithdrawEther(msg.sender,amount) (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#64)

Reentrancy in MerkleWhitelistNFT.withdrawEther() (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#100-107):
        External calls:
        - (sent) = address(owner()).call{value: amount}() (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#102)
        Event emitted after the call(s):
        - WithdrawEther(msg.sender,amount) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#106)

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3>

- **Conclusion:**  False Positive. There is no significant exploitation.

## Finding 13: Dangerous comparisons

BondingCurve.sellTokens(uint256) (src/week1_BondingCurves/BondingCurve.sol#74-103) uses timestamp for comparisons
        Dangerous comparisons:
        - block.timestamp < lastBuyTimestamp[msg.sender] + cooldownPeriod (src/week1_BondingCurves/BondingCurve.sol#80)
MultiPartyEscrow.releaseTokens() (src/week1_BondingCurves/MultiPartyEscrow.sol#91-110) uses timestamp for comparisons
        Dangerous comparisons:
        - block.timestamp < escrow.releaseTime (src/week1_BondingCurves/MultiPartyEscrow.sol#97)
StakingContract.onERC721Received(address,address,uint256,bytes) (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#65-93) uses timestamp for comparisons
        Dangerous comparisons:
        - block.timestamp >_lastRewardTimestamp (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#133)
        -_lastRewardTimestamp > 0 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#134)
        Dangerous comparisons:
        - rewardToMint > 0 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#88)
StakingContract.updateReward() (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#131-144) uses timestamp for comparisons
Pair._update(uint256,uint256,uint112,uint112) (src/week3-5_UniswapV2/Pair.sol#354-376) uses timestamp for comparisons
        Dangerous comparisons:
        - timeElapsed > 0 &&_reserve0 != 0 && _reserve1 != 0 (src/week3-5_UniswapV2/Pair.sol#363)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp>

- **Conclusion:**  False Positive. The above finding regarding block.timestamp Dangerous comparison highlights the potential for miner manipulation of the block.timestamp. However, in this specific context, where block.timestamp is used primarily  for enforcing some checks. Any manipulation by miners is unlikely to result in significant exploitation or harm to the contract.

## Finding 14: Factory.createPair(address,address) (src/week3-5_UniswapV2/Factory.sol#27-46) uses assembly

        - INLINE ASM (src/week3-5_UniswapV2/Factory.sol#38-40)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#assembly-usage>

- **Conclusion:**  True Positive. Using inline assembly can be avoided.
  
## Finding 15:BondingCurve.continuousTokenMint(uint256) (src/week1_BondingCurves/BondingCurve.sol#42-68) compares to a boolean constant

        -sent == false (src/week1_BondingCurves/BondingCurve.sol#62)
BondingCurve.sellTokens(uint256) (src/week1_BondingCurves/BondingCurve.sol#74-103) compares to a boolean constant:
        -sent == false (src/week1_BondingCurves/BondingCurve.sol#98)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#boolean-equality>

- **Conclusion:**  True Positive. Boolean constants can be used directly and do not need to be compare to true or false.

## Finding 16: Pragma version0.8.21 a version too recent to be trusted

Pragma version0.8.21 (src/week1_BondingCurves/BondingCurve.sol#12) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week1_BondingCurves/GodModeToken.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version^0.8.0 (src/week1_BondingCurves/MultiPartyEscrow.sol#2) allows old versions
Pragma version0.8.21 (src/week1_BondingCurves/SanctionedToken.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/RewardToken.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week3-5_UniswapV2/Factory.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week3-5_UniswapV2/Pair.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week3-5_UniswapV2/PairERC20.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week3-5_UniswapV2/UQ112x112.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
Pragma version0.8.21 (src/week3-5_UniswapV2/interfaces/IFactory.sol#2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.
solc-0.8.21 is not recommended for deployment

Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity>

- **Conclusion:**  False Positive. It is okay in this case to use latest version.
  
## Finding 17: Low level call

Low level call in BondingCurve.continuousTokenMint(uint256) (src/week1_BondingCurves/BondingCurve.sol#42-68):
        - (sent) = address(msg.sender).call{value: msg.value - totalCost}() (src/week1_BondingCurves/BondingCurve.sol#61)
Low level call in BondingCurve.sellTokens(uint256) (src/week1_BondingCurves/BondingCurve.sol#74-103):
        - (sent) = address(msg.sender).call{value: totalCost}() (src/week1_BondingCurves/BondingCurve.sol#97)
Low level call in EnumerableNFT.withdrawEther() (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#58-65):
        - (sent) = address(owner()).call{value: amount}() (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#60)
Low level call in MerkleWhitelistNFT.withdrawEther() (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#100-107):
        - (sent) = address(owner()).call{value: amount}() (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#102)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls>

- **Conclusion:**  False Positive. The use of low-level calls in the contracts BondingCurve, EnumerableNFT, and MerkleWhitelistNFT is appropriate for transferring Ether. These calls are necessary for the intended functionality of the contracts, and they properly handle call success.

## Finding 18: is not in mixedCase

Parameter MultiPartyEscrow.createEscrow(address,address,uint256)._seller (src/week1_BondingCurves/MultiPartyEscrow.sol#54) is not in mixedCase
Parameter MultiPartyEscrow.createEscrow(address,address,uint256)._token (src/week1_BondingCurves/MultiPartyEscrow.sol#54) is not in mixedCase
Parameter MultiPartyEscrow.createEscrow(address,address,uint256)._amount (src/week1_BondingCurves/MultiPartyEscrow.sol#54) is not in mixedCase
Parameter EnumerableNFT.mint(uint256)._tokenId (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/EnumerableNFT.sol#34) is not in mixedCase
Parameter MerkleWhitelistNFT.whitelistMint(bytes32[],uint256,uint256)._merkleProof (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#57) is not in mixedCase
Parameter MerkleWhitelistNFT.whitelistMint(bytes32[],uint256,uint256)._tokenId (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#57) is not in mixedCase
Parameter MerkleWhitelistNFT.mint(uint256)._tokenId (src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol#84) is not in mixedCase
Parameter Factory.setFeeTo(address)._feeTo (src/week3-5_UniswapV2/Factory.sol#48) is not in mixedCase
Parameter Factory.setFeeToSetter(address)._feeToSetter (src/week3-5_UniswapV2/Factory.sol#58) is not in mixedCase
Parameter Pair.initialize(address,address)._token0 (src/week3-5_UniswapV2/Pair.sol#60) is not in mixedCase
Parameter Pair.initialize(address,address)._token1 (src/week3-5_UniswapV2/Pair.sol#60) is not in mixedCase
Variable Pair.MINIMUM_LIQUIDITY (src/week3-5_UniswapV2/Pair.sol#24) is not in mixedCase
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions>

- **Conclusion:**  True Positive. Can be left unchanged for now.

## Finding 19: Variable names too similar

Variable Pair.addLiquidity(uint256,uint256,address).amount0Desired (src/week3-5_UniswapV2/Pair.sol#83) is too similar to Pair.addLiquidity(uint256,uint256,address).amount1Desired (src/week3-5_UniswapV2/Pair.sol#84)
Variable Pair.addLiquidity(uint256,uint256,address).amount0Return (src/week3-5_UniswapV2/Pair.sol#89) is too similar to Pair.addLiquidity(uint256,uint256,address).amount1Return (src/week3-5_UniswapV2/Pair.sol#90)
Variable Pair.addLiquidity(uint256,uint256,address).amount0Optimal (src/week3-5_UniswapV2/Pair.sol#106) is too similar to Pair.addLiquidity(uint256,uint256,address).amount1Optimal (src/week3-5_UniswapV2/Pair.sol#104)
Variable Pair.price0CumulativeLast (src/week3-5_UniswapV2/Pair.sol#22) is too similar to Pair.price1CumulativeLast (src/week3-5_UniswapV2/Pair.sol#23)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-too-similar>

- **Conclusion:**  False Positive. It represent values for token0 and token1.

## Finding 20: Too many digits

Factory.createPair(address,address) (src/week3-5_UniswapV2/Factory.sol#27-46) uses literals with too many digits:
        - bytecode = type()(Pair).creationCode (src/week3-5_UniswapV2/Factory.sol#36)
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits>

- **Conclusion:**  False Positive.

## Finding 28: State variables that could be declared constant

PairERC20._name (src/week3-5_UniswapV2/PairERC20.sol#7) should be constant
PairERC20._symbol (src/week3-5_UniswapV2/PairERC20.sol#8) should be constant
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-constant>

- **Conclusion:**  True Positive.

## Finding 29: State variables that could be declared immutable

BondingCurve.initialPrice (src/week1_BondingCurves/BondingCurve.sol#27) should be immutable
BondingCurve.priceChangeRate (src/week1_BondingCurves/BondingCurve.sol#28) should be immutable
Pair.factoryAddress (src/week3-5_UniswapV2/Pair.sol#18) should be immutable
PrimeNFTCounter.enumerableNft (src/week2_NFTVariantsAndStaking/NFTEnumerableContracts/PrimeNFTCounter.sol#11) should be immutable
Reference: <https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-immutable>

- **Conclusion:**  True Positive.

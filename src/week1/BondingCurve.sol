// SPDX-License-Identifier: MIT
/**
 * @title BondingCurve
 * @dev This contract implements a bonding curve continuous token.
 * The price of tokens is determined by a linear bonding curve equation: P(S) = priceChangeRate * totalSupply + initialPrice
 * where P(S) is the price, S is the total supply, priceChangeRate is the rate of change of price per token minted or burned,
 * and initialPrice is the initial price of tokens.
 * Tokens can be minted by sending ether to the contract, and the cost is calculated based on the current bonding curve equation.
 * Tokens can be burned to receive ether, and the value received is calculated based on the current bonding curve equation.
 */
pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error InsufficientEther(uint256 available, uint256 required);
error InsufficientBalance(uint256 available, uint256 required);
error ZeroAmount();
error CooldownNotElapsed(uint256 remainingCooldown);

contract BondingCurve is ERC20 {
    // Define events
    event TokenPurchased(address buyer, uint256 amount, uint256 totalPrice);
    event TokenSold(address seller, uint256 amount, uint256 totalPrice);

    // Define variables
    uint256 public initialPrice;
    uint256 public priceChangeRate;
    uint256 public reserveBalance;
    mapping(address => uint256) public lastBuyTimestamp;
    uint256 public constant cooldownPeriod = 1 days;

    constructor(uint256 _priceChangeRate, uint256 _initialPrice) ERC20("Bonding Curve Continuous Token", "BCCT") {
        initialPrice = _initialPrice;
        priceChangeRate = _priceChangeRate;
    }

    /**
     * @dev Mint tokens by sending ether to the contract.
     * @param purchaseAmount The amount of tokens to mint.
     */
    function continuousTokenMint(uint256 purchaseAmount) external payable {
        if (purchaseAmount == 0) {
            revert ZeroAmount();
        }

        uint256 totalCost = getCostToBuy(purchaseAmount);

        if (msg.value < totalCost) {
            revert InsufficientEther({available: msg.value, required: totalCost});
        }
        reserveBalance += totalCost;

        lastBuyTimestamp[msg.sender] = block.timestamp;

        // Update buyer's balance
        _mint(msg.sender, purchaseAmount);

        // Transfer any remaining ether to buyer
        if (msg.value - totalCost > 0) {
            (bool sent,) = payable(msg.sender).call{value: msg.value - totalCost}("");
            if (sent == false) {
                revert InsufficientEther({available: msg.value - totalCost, required: 0});
            }
        }
        // Emit event
        emit TokenPurchased(msg.sender, purchaseAmount, totalCost);
    }

    /**
     * @dev Sell tokens to receive ether.
     * @param depositAmount The amount of tokens to sell.
     */
    function sellTokens(uint256 depositAmount) external {
        if (depositAmount == 0) {
            revert ZeroAmount();
        }

        // Check if cooldown period has elapsed since last buy
        if (block.timestamp < lastBuyTimestamp[msg.sender] + cooldownPeriod) {
            revert CooldownNotElapsed(block.timestamp - lastBuyTimestamp[msg.sender] + cooldownPeriod);
        }

        // Calculate total price based on current pricePerToken and _amount
        uint256 totalCost = getCostToSell(depositAmount);

        if (totalCost > reserveBalance) {
            revert InsufficientBalance({available: reserveBalance, required: totalCost});
        }

        reserveBalance -= totalCost;

        // Update seller's balance
        _burn(msg.sender, depositAmount);

        // Transfer ether to seller
        (bool sent,) = payable(msg.sender).call{value: totalCost}("");
        if (sent == false) {
            revert InsufficientEther({available: 0, required: totalCost});
        }
        // Emit event
        emit TokenSold(msg.sender, depositAmount, totalCost);
    }

    /**
     * @dev Calculate the cost to buy a specified amount of tokens.
     * @param purchaseAmount The amount of tokens to purchase.
     * @return totalCost The total cost to purchase the specified amount of tokens.
     */
    function getCostToBuy(uint256 purchaseAmount) public view returns (uint256 totalCost) {
        uint256 currentTotalSupply = totalSupply();
        uint256 reserveBeforeTrade =
            (priceChangeRate * currentTotalSupply ** 2) / 2e36 + (initialPrice * currentTotalSupply) / 1e18;
        uint256 updatedTotalSupply = currentTotalSupply + purchaseAmount;
        uint256 reserveAfterTrade =
            (priceChangeRate * updatedTotalSupply ** 2) / 2e36 + (initialPrice * updatedTotalSupply) / 1e18;
        totalCost = reserveAfterTrade - reserveBeforeTrade;
        return totalCost;
    }

    /**
     * @dev Calculate the proceeds from selling a specified amount of tokens.
     * @param purchaseAmount The amount of tokens to sell.
     * @return totalCost The total proceeds from selling the specified amount of tokens.
     */
    function getCostToSell(uint256 purchaseAmount) public view returns (uint256 totalCost) {
        uint256 currentTotalSupply = totalSupply();
        uint256 updatedTotalSupply = currentTotalSupply - purchaseAmount;
        uint256 reserveBeforeTrade =
            (priceChangeRate * currentTotalSupply ** 2) / 2e36 + (initialPrice * currentTotalSupply) / 1e18;
        uint256 reserveAfterTrade =
            (priceChangeRate * updatedTotalSupply ** 2) / 2e36 + (initialPrice * updatedTotalSupply) / 1e18;
        totalCost = reserveBeforeTrade - reserveAfterTrade;
        return totalCost;
    }
}

### Why does `price0CumulativeLast` and `price1CumulativeLast` never decrement?

The variables `price0CumulativeLast` and `price1CumulativeLast` in Uniswap V2 accumulate the cumulative prices since the pool's launch. They are updated with every call to the `_update` function and can only increase until they overflow. There's no mechanism to make them decrease, as they always accumulate prices over time. This design ensures that the oracle continually provides updated price information without the possibility of decrementing.

### How do you write a contract that uses the Oracle?

To write a contract that utilizes the TWAP Oracle in Uniswap V2, you need to implement a mechanism to snapshot the relevant variables (`price0CumulativeLast`, `price1CumulativeLast`, and timestamps) at specific intervals. These snapshots allow you to calculate the TWAP over a desired time period.

Here's a simplified example of how you can achieve this in Solidity:

```solidity
contract UniswapOracle {
    uint256 public lastSnapshotTime;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    // Function to snapshot the relevant variables
    function snapshot() external {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = UniswapV2Pair.getReserves();
        // Update price accumulators if time has passed since the last snapshot
        if (blockTimestamp > lastSnapshotTime) {
            price0CumulativeLast = UniswapV2Pair.price0CumulativeLast();
            price1CumulativeLast = UniswapV2Pair.price1CumulativeLast();
            lastSnapshotTime = blockTimestamp;
        }
    }

    // Function to calculate the TWAP over a specified time period
    function getOneHourTWAP() external view returns (uint256) {
        // Calculate time elapsed since last snapshot
        uint256 timeElapsed = block.timestamp - lastSnapshotTime;
        require(timeElapsed >= 1 hours, "TWAP: Insufficient time elapsed");

        // Calculate price difference between last snapshot and current time
        uint256 price0Diff = UniswapV2Pair.price0CumulativeLast() - price0CumulativeLast;
        uint256 price1Diff = UniswapV2Pair.price1CumulativeLast() - price1CumulativeLast;

        // Calculate TWAP
        uint256 twap = (price0Diff + price1Diff) / timeElapsed;

        return twap;
    }
}
```

### Why are `price0CumulativeLast` and `price1CumulativeLast` stored separately? Why not just calculate `price1CumulativeLast = 1/price0CumulativeLast`?

The prices of assets in a Uniswap V2 pair are stored separately as `price0CumulativeLast` and `price1CumulativeLast` because they represent the cumulative prices of each asset in the pair. While it's true that the price of one asset relative to the other can be calculated by taking the inverse, storing them separately allows for more efficient and precise calculations within the Uniswap protocol. Additionally, storing them separately ensures symmetry in the representation of prices, maintaining consistency in the fixed-point arithmetic used by Uniswap V2.

If you have any further questions or need clarification on any of these points, feel free to ask!
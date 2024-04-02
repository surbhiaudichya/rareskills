// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {PairERC20} from "./PairERC20.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {UQ112x112} from "./UQ112x112.sol";
import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

contract Pair is PairERC20, ReentrancyGuard, IERC3156FlashLender {
    using UQ112x112 for uint224;

    /// STATE VARS ///
    address public immutable factoryAddress;
    address public token0;
    address public token1;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public immutable MINIMUM_LIQUIDITY = 10 ** 3;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    /// EVENTS ///
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    /// CUSTOM ERRORS ///
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error InsufficientInputAmount();
    error K();
    error Overflow();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error TradeSlippage();
    error FlashLenderCallbackFailed();
    error UnsupportedToken();
    error OnlyFactory();

    // Constructor to set the factory address
    constructor() {
        factoryAddress = msg.sender;
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Initializes the pair with the given tokens
    /// @param _token0 Address of token0
    /// @param _token1 Address of token1
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factoryAddress) {
            revert OnlyFactory();
        }
        token0 = _token0;
        token1 = _token1;
    }

    /// @notice Adds liquidity to the pair
    /// @param amount0Min Minimum amount of token0 to deposit
    /// @param amount1Min Minimum amount of token1 to deposit
    /// @param to Address to send the LP tokens to
    /// @return liquidity The amount of liquidity tokens minted
    function addLiquidity(uint256 amount0Min, uint256 amount1Min, address to)
        external
        nonReentrant
        returns (uint256 liquidity)
    {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // Get the actual balance of token0 and token1
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        // Calculate the desired amounts of token0 and token1
        uint256 amount0Desired = balance0 - _reserve0;
        uint256 amount1Desired = balance1 - _reserve1;
        // Actual deposit amount
        uint256 amount0;
        uint256 amount1;
        // Return token amount if any
        uint256 amount0Return;
        uint256 amount1Return;
        // Measurs the growth of fees due to swaps between liquidity deposit and withdrawal events.
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // Must be defined here since totalSupply can update in _mintFee
        uint256 _totalSupply = totalSupply();

        // If there are no LP tokens yet, mint the initial amount and lock the first MINIMUM_LIQUIDITY tokens
        if (_totalSupply == 0) {
            // Initially mints shares equal to the geometric mean of the amounts
            liquidity = FixedPointMathLib.sqrt(amount0Desired * amount1Desired) - (MINIMUM_LIQUIDITY);
            // Burn first MINIMUM_LIQUIDITY tokens to ensure no-one owns the entire supply of LP tokens
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // Calculate the optimal amount of token1 to be added
            uint256 amount1Optimal = quote(amount0Desired, reserve0, reserve1);
            // Calculate the optimal amount of token0 to be added
            uint256 amount0Optimal = quote(amount1Desired, reserve1, reserve0);
            if (amount1Optimal <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
                amount1Return = amount1Desired - amount1Optimal;
            } else if (amount0Optimal <= amount0Desired) {
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
                amount0Return = amount0Desired - amount0Optimal;
            }
            // Calculate the amount of liquidity tokens to be minted
            liquidity =
                FixedPointMathLib.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        if (amount0 <= amount0Min && amount1 <= amount1Min) {
            revert TradeSlippage();
        }
        // Chech: liquidty amount is greater than Zero.
        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted();
        }
        // Mint liquidity token to LP.
        _mint(to, liquidity);

        // Update the reserves and the price
        _update(balance0 - amount0Return, balance1 - amount1Return, _reserve0, _reserve1);
        // Update kLast if fee is enabled
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        // Transfer remaining token amount if any
        if (amount0Return > 0) SafeTransferLib.safeTransfer(token0, to, amount0Return);
        if (amount1Return > 0) SafeTransferLib.safeTransfer(token1, to, amount1Return);
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @notice IERC3156FlashLender-{flashLoan}
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        public
        override
        returns (bool)
    {
        // Ensure that the token being borrowed is one of the pair tokens
        if (token != token0 && token != token1) revert UnsupportedToken();
        // Check if the contract has sufficient liquidity to lend
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (amount > balance) {
            revert InsufficientLiquidity();
        }
        // Get the current reserves before the flash loan
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // Transfer the borrowed tokens to the receiver
        SafeTransferLib.safeTransfer(token, address(receiver), amount);
        // Calculate the fee for the flash loan
        uint256 fee;
        unchecked {
            fee = (amount * 3) / 1000;
        }
        // Invoke the receiver's callback function and ensure its validity
        if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != keccak256("ERC3156FlashBorrower.onFlashLoan"))
        {
            revert FlashLenderCallbackFailed();
        }
        // Transfer the borrowed tokens plus the fee back to the contract
        SafeTransferLib.safeTransferFrom(token, address(receiver), address(this), amount + fee);
        // Update the reserves after the flash loan transaction
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        return true;
    }

    /// @notice Removes liquidity from the pair
    /// @param amount0Min Minimum amount of token0 to receive
    /// @param amount1Min Minimum amount of token1 to receive
    /// @param to Address to send the tokens to
    /// @return amount0 The amounts of token0 withdrawn
    /// @return amount1 The amounts of token0 withdrawn
    function removeLiquidity(uint256 amount0Min, uint256 amount1Min, address to)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        // Get the reserves of token0 and token1
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        // Get the actual balance of token0 and token1
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        // Get the liquidity amount
        uint256 liquidity = balanceOf(address(this));
        // Measurs the growth of fees due to swaps between liquidity deposit and withdrawal events.
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // must be defined here since totalSupply can update in _mintFee
        // Calculate the amounts of token0 and token1 to be withdrawn based on the provided liquidity
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        // Check: The token amount are greater than zero.
        if (amount0 < amount0Min && amount1 < amount1Min) {
            revert TradeSlippage();
        }
        // Burn LP Token
        _burn(address(this), liquidity);
        // Transfer the withdrawn tokens to the recipient
        SafeTransferLib.safeTransfer(_token0, to, amount0);
        SafeTransferLib.safeTransfer(_token1, to, amount1);
        // Get new reserve balance.
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        // Update the reserves
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @notice Swaps tokens in the pair
    /// @param amountOutMin Minimum amount of tokens to receive
    /// @param tokenOut Address of the token to receive
    /// @param to Address to send the swapped tokens to
    function swap(uint256 amountOutMin, address tokenOut, address to) external nonReentrant {
        // Check: Ensure that the minimum amount to receive is non-zero
        if (amountOutMin == 0) {
            revert InsufficientOutputAmount();
        }

        // Check: Ensure that the destination address is not one of the tokens
        if (to == token0 && to == token1) {
            revert InvalidTo();
        }

        // Check: Ensure that the token to receive is one of the pair tokens
        if (tokenOut != token0 && tokenOut != token1) {
            revert UnsupportedToken();
        }

        // Get the reserves of token0 and token1
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        // Determine which token is being swapped out and which one is being received
        uint112 reserveTokenIn;
        uint112 reserveTokenOut;
        address tokenIn;
        if (tokenOut == token1) {
            tokenIn = token0;
            reserveTokenIn = _reserve0;
            reserveTokenOut = _reserve1;
        } else {
            tokenIn = token1;
            reserveTokenIn = _reserve1;
            reserveTokenOut = _reserve0;
        }

        // Check: Ensure that there is enough liquidity for the swap
        if (amountOutMin > reserveTokenOut) revert InsufficientLiquidity();

        // Get the balance of the input token before the swap
        uint256 balanceTokenIn = IERC20(tokenIn).balanceOf(address(this));

        // Calculate the input amount for the swap
        uint256 amountTokenIn;
        unchecked {
            amountTokenIn = balanceTokenIn > reserveTokenIn ? balanceTokenIn - reserveTokenIn : 0;
        }

        //Check: Ensure that the input amount is non-zero
        if (amountTokenIn == 0) {
            revert InsufficientInputAmount();
        }

        // Calculate amountOut = reserveTokenOut * amountTokenIn / reserveTokenIn + amountTokenIn
        uint256 amountInWithFee = amountTokenIn * 997;
        uint256 numerator = amountInWithFee * reserveTokenOut;
        uint256 denominator = reserveTokenIn * 1000 + amountInWithFee;
        uint256 actualAmountOut = numerator / denominator;

        // Ensure that the actual amount out meets the minimum requirement
        if (actualAmountOut < amountOutMin) revert TradeSlippage();

        // Transfer the output tokens to the recipient
        SafeTransferLib.safeTransfer(token0, to, actualAmountOut);

        // Update the reserves and the price.
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amountTokenIn, actualAmountOut, to);
    }

    // force reserves to match balances
    function sync() external nonReadReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /// @notice IERC3156FlashLender-{maxFlashLoan}
    /// @param token address of token to borrow
    /// @return amount maximum that user can borrow
    function maxFlashLoan(address token) public view override returns (uint256 amount) {
        if (token != token0 && token != token1) revert UnsupportedToken();
        amount = token == token0 ? reserve0 : reserve1;
    }

    /// @param token address of token to borrow
    /// @param amount amount of the token to borrow
    /// @return fee for flashloan
    function flashFee(address token, uint256 amount) public view override returns (uint256 fee) {
        if (token != token0 && token != token1) revert UnsupportedToken();
        fee = (amount * 3) / 1000;
    }

    /// @notice Get Reserves
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        if (amountA < 0) revert();
        if (reserveA < 0 && reserveB < 0) revert();
        amountB = (amountA * reserveA) / reserveB;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IFactory(factoryAddress).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        // Check: feeOn is not zero address
        if (feeOn) {
            if (_kLast != 0) {
                // Current liquidity after fees
                uint256 rootK = FixedPointMathLib.sqrt(uint256(_reserve0) * (_reserve1));
                // Previous liquidity
                uint256 rootKLast = FixedPointMathLib.sqrt(_kLast);
                // Check current liquidity is greater than previous liquidity
                if (rootK > rootKLast) {
                    // 0.005% of swap fees
                    // Formula: protocolFee = ((currentLiquidity - previousLiquidity) / (5 * currentLiquidity - previousLiquidity)) * totalSupply
                    uint256 numerator = totalSupply() * (rootK - rootKLast);
                    uint256 denominator = (rootK * 5) + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    // mint protocolFee
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (balance0 > type(uint112).max && balance1 > type(uint112).max) {
            revert Overflow();
        }
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            // Seconds since last price update.
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                // Price is the ratio of assets weighted by time
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        // reserve0 and reserve1 are updated to reflect the changed balances.
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
}

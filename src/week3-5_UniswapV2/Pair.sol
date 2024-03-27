// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {PairERC20} from "./PairERC20.sol";
import {IFactory} from "./interface/IFactory.sol";
import {UQ112x112} from "./UQ112x112.sol";
import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

contract Pair is PairERC20, ReentrancyGuard, IERC3156FlashLender {
    using UQ112x112 for uint224;

    address public factory;
    address public token0;
    address public token1;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 public immutable MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    //Event
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    //Error
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error InsufficientInputAmount();
    error K();
    error Overflow();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error TradeSlippage();
    error FlashLoanFailed();

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
    /**
     * @notice IERC3156FlashLender-{maxFlashLoan}
     * @param token address of token to borrow
     * @return amount maximum that user can borrow
     */

    function maxFlashLoan(address token) public view override returns (uint256 amount) {
        // if (token != token0 && token != token1) revert UnsupportedToken();
        // amount = token == token0 ? _reserve0 : _reserve1;
    }

    /**
     * @param token address of token to borrow
     * @param amount amount of the token to borrow
     * @return fee for flashloan
     */
    function flashFee(address token, uint256 amount) public view override returns (uint256 fee) {
        // if (token != token0 && token != token1) revert UnsupportedToken();
        // fee = (amount * FEE_BPS) / 10_000;
    }

    /**
     * @notice IERC3156FlashLender-{flashLoan}
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        public
        override
        returns (bool)
    {
        if (token != token0 && token != token1) revert();
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (amount > balance) {
            revert();
        }
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        SafeTransferLib.safeTransfer(token, address(receiver), amount);

        uint256 fee;
        unchecked {
            fee = (amount * 3) / 1000;
        }
        if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != keccak256("ERC3156FlashBorrower.onFlashLoan"))
        {
            revert FlashLoanFailed();
        }

        SafeTransferLib.safeTransferFrom(token, address(receiver), address(this), amount + fee);

        // Get actual reserve balance, including any donations
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        return true;
    }

    //It is assumed that the burner sent in LP tokens before calling burn
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        // Get reserve balance
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        // Get actual reserve balance, including any donations
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        //liquidity is measured by the amount of LP tokens owned by the pool contract.
        uint256 liquidity = balanceOf(address(this));
        // Measurs the growth of fees due to swaps between liquidity deposit and withdrawal events.
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        //Calculate the amounts that the LP provider will get back.
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        // Check: The token amount are greater than zero.
        if (amount0 <= 0 && amount1 <= 0) {
            revert InsufficientLiquidityBurned();
        }
        // Burn LP Token
        _burn(address(this), liquidity);
        // The token0 and token1 are sent to the liquidity provider.
        SafeTransferLib.safeTransfer(_token0, to, amount0);
        SafeTransferLib.safeTransfer(_token1, to, amount1);
        // Get new reserve balance.
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        // Update reserve
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        // get reserve balance
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        // Actual token0 and token1 amount
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        //Calculate the amount of tokens user has sent.
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        // Measurs the growth of fees due to swaps between liquidity deposit and withdrawal events.
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee

        // Check: totalSupply of liquidity token.
        if (_totalSupply == 0) {
            // Initially mints shares equal to the geometric mean of the amounts
            liquidity = FixedPointMathLib.sqrt(amount0 * amount1) - (MINIMUM_LIQUIDITY);
            // burn first MINIMUM_LIQUIDITY tokens to ensure no-one owns the entire supply of LP tokens
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // LP will get the worse of the two ratios, this is to incentivise to supply liquidity without chaning the token ratio.
            liquidity =
                FixedPointMathLib.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        // Chech: liquidty amount is greater than Zero.
        if (liquidity <= 0) {
            revert InsufficientLiquidityMinted();
        }
        // Mint liquidity token to LP.
        _mint(to, liquidity);

        // Update reserves and the new price and how long the previous price lasted.
        _update(balance0, balance1, _reserve0, _reserve1);
        // Set kLast to current liquidity
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function swap(uint256 amountOutMin, address tokenOut, address to) external nonReentrant {
        // Check: amount0Out and amount1Out are equal or greater than zero.
        if (amountOutMin == 0) {
            revert InsufficientOutputAmount();
        }
        // Check: To is not token address.
        if (to == token0 && to == token1) {
            revert InvalidTo();
        }
        if (tokenOut != token0 && tokenOut != token1) {
            revert();
        }
        //_reserve0 and _reserve1 reflect the balance of the contract before the tokens were sent.
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
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

        if (amountOutMin > reserveTokenOut) revert InsufficientLiquidity();

        // it is expected that user must have sent the tokenIn
        uint256 balanceTokenIn = IERC20(tokenIn).balanceOf(address(this));

        uint256 amountTokenIn;

        //amount0In and amount1In will reflect the net gain if there was a net gain for the token, and they will be zero if there was a net loss of that token.
        unchecked {
            amountTokenIn = balanceTokenIn > reserveTokenIn ? balanceTokenIn - reserveTokenIn : 0;
        }

        //Check: values aren’t zero
        if (amountTokenIn == 0) {
            revert InsufficientInputAmount();
        }
        // Formula amountOut = reserveTokenOut * amountTokenIn / reserveTokenIn + amountTokenIn
        uint256 amountInWithFee = amountTokenIn * 997;
        uint256 numerator = amountInWithFee * reserveTokenOut;
        uint256 denominator = reserveTokenIn * 1000 + amountInWithFee;
        // reserve0 * reserve1 <  balanceTokenIn * (balanceTokenOut - actualAmountOut)
        uint256 actualAmountOut = numerator / denominator;
        if (actualAmountOut < amountOutMin) revert TradeSlippage();

        // Transfers out the amount of tokens that the trader requested.
        SafeTransferLib.safeTransfer(token0, to, actualAmountOut);

        // Updating Reserves and the new price and how long the previous price lasted.
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amountTokenIn, actualAmountOut, to);
    }

    // force reserves to match balances
    function sync() external nonReadReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        // Check: feeOn is not zero address
        if (feeOn) {
            if (_kLast != 0) {
                //current liquidity after fees
                uint256 rootK = FixedPointMathLib.sqrt(uint256(_reserve0) * (_reserve1));
                // previous liquidity
                uint256 rootKLast = FixedPointMathLib.sqrt(_kLast);
                // Check current liquidity is greater than previous liquidity
                if (rootK > rootKLast) {
                    // 0.005% of swap fees
                    // protocolFee = ((currentLiquidity - previousLiquidity) / (5 * currentLiquidity - previousLiquidity)) * totalSupply
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

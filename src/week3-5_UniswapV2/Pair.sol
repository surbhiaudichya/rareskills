// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {PairERC20} from "./PairERC20.sol";

contract Pair is PairERC20, ReentrancyGuard {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public immutable MINIMUM_LIQUIDITY = 10 ** 3;

    //Event
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
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

        // Update reserves.
        _update(balance0, balance1, _reserve0, _reserve1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external nonReentrant {
        // Check: amount0Out and amount1Out are equal or greater than zero.
        if (amount0Out < 0 || amount1Out < 0) {
            revert InsufficientOutputAmount();
        }
        //_reserve0 and _reserve1 reflect the balance of the contract before the tokens were sent.
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // Check: amount requested are less that reserve.
        if (amount0Out > _reserve0 && amount1Out > _reserve1) {
            revert InsufficientLiquidity();
        }
        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            // Check: To is not token address.
            if (to == _token0 && to == _token1) {
                revert InvalidTo();
            }
            // Transfers out the amount of tokens that the trader requested.
            if (amount0Out > 0) SafeTransferLib.safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) SafeTransferLib.safeTransfer(_token1, to, amount1Out);
            //if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            // Updated reserve balance
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        //amount0In and amount1In will reflect the net gain if there was a net gain for the token, and they will be zero if there was a net loss of that token.
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        //Check: values aren’t zero
        if (amount0In <= 0 || amount1In <= 0) {
            revert InsufficientInputAmount();
        }
        {
            // The new balance must increase by 0.3% of the amount in.
            uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
            uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
            //Check: user pay back the flash loan with interest. The formula is scaled by multiplying each term by 1,000 because Solidity doesn’t have floating point numbers
            if ((balance0Adjusted * balance1Adjusted) < (uint256(_reserve0) * uint256(_reserve1) * (1000 ** 2))) {
                revert K();
            }
        }
        // Updating Reserves
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (balance0 > type(uint112).max && balance1 > type(uint112).max) {
            revert Overflow();
        }
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        }

        // reserve0 and reserve1 are updated to reflect the changed balances.
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
}

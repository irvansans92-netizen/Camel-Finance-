// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockPair} from "./MockPair.sol";

/// @notice Minimal mock of a Uniswap V2 style router, using a fixed 1:1 price
///         (adjustable via `rate`) for predictable test outcomes.
contract MockRouter {
    MockPair public pair;
    address public tokenA; // WOPN
    address public tokenB; // tUSDT

    // rate = how many tokenA units per 1 tokenB unit, scaled by 1e18
    // e.g. rate = 2e18 means 1 tokenB = 2 tokenA
    uint256 public rate = 1e18;

    constructor(address _tokenA, address _tokenB, address _pair) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        pair = MockPair(_pair);
    }

    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function factory() external pure returns (address) {
        return address(0);
    }

    function WETH() external pure returns (address) {
        return address(0);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 /* deadline */
    ) external returns (uint256[] memory amounts) {
        require(path.length == 2, "BAD_PATH");

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut;
        if (path[0] == tokenB && path[1] == tokenA) {
            // tUSDT -> WOPN
            amountOut = (amountIn * rate) / 1e18;
        } else if (path[0] == tokenA && path[1] == tokenB) {
            // WOPN -> tUSDT
            amountOut = (amountIn * 1e18) / rate;
        } else {
            revert("BAD_PATH");
        }

        // apply a flat 0.3% fee to roughly mimic real AMM behavior
        amountOut = (amountOut * 997) / 1000;

        require(amountOut >= amountOutMin, "SLIPPAGE");

        IERC20(path[1]).transfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 /* amountAMin */,
        uint256 /* amountBMin */,
        address to,
        uint256 /* deadline */
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        amountA = amountADesired;
        amountB = amountBDesired;

        // simple liquidity formula: sum of both amounts normalized (good enough for tests)
        liquidity = amountA + amountB;

        pair.mint(to, liquidity);

        // update mock reserves for future quoteOptimalSwap() calls
        pair.setReserves(
            uint112(IERC20(tokenA).balanceOf(address(this))),
            uint112(IERC20(tokenB).balanceOf(address(this)))
        );
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 /* amountAMin */,
        uint256 /* amountBMin */,
        address to,
        uint256 /* deadline */
    ) external returns (uint256 amountA, uint256 amountB) {
        // read total supply BEFORE burning, since burn() reduces it immediately
        uint256 totalSupplyBeforeBurn = pair.totalSupply();

        pair.burn(msg.sender, liquidity);

        // return proportional share of the router's current balances
        uint256 totalA = IERC20(_tokenA).balanceOf(address(this));
        uint256 totalB = IERC20(_tokenB).balanceOf(address(this));

        amountA = (totalA * liquidity) / totalSupplyBeforeBurn;
        amountB = (totalB * liquidity) / totalSupplyBeforeBurn;

        IERC20(_tokenA).transfer(to, amountA);
        IERC20(_tokenB).transfer(to, amountB);

        pair.setReserves(
            uint112(IERC20(tokenA).balanceOf(address(this))),
            uint112(IERC20(tokenB).balanceOf(address(this)))
        );
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        if (path[0] == tokenB && path[1] == tokenA) {
            amounts[1] = (amountIn * rate * 997) / (1e18 * 1000);
        } else {
            amounts[1] = (amountIn * 1e18 * 997) / (rate * 1000);
        }
    }
}

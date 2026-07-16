// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IOPNSwapRouter} from "./IOPNSwapRouter.sol";
import {IOPNSwapPair} from "./IOPNSwapPair.sol";

interface ILiquidityVault {
    function depositFor(address user, uint256 amount) external;
    function withdrawTo(address user, uint256 shares, address receiver) external returns (uint256);
    function totalShares() external view returns (uint256);
}

/// @title Camel Zap
/// @notice Lets users enter/exit the WOPN/tUSDT liquidity position using a single token (tUSDT).
contract ZapRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenA; // WOPN
    IERC20 public immutable tokenB; // tUSDT
    IERC20 public immutable lpToken;

    IOPNSwapRouter public immutable router;
    ILiquidityVault public immutable vault;

    event ZapIn(address indexed user, uint256 amountIn, uint256 liquidity);
    event ZapOut(address indexed user, uint256 shares, uint256 amountReturned);

    constructor(
        address _tokenA,
        address _tokenB,
        address _lpToken,
        address _router,
        address _vault
    ) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = IERC20(_lpToken);
        router = IOPNSwapRouter(_router);
        vault = ILiquidityVault(_vault);
    }

    /// @notice Estimates how much of `amountIn` (tokenB) should be swapped to tokenA
    ///         so the remainder pairs up cleanly for addLiquidity, accounting for the 0.3% swap fee.
    function quoteOptimalSwap(uint256 amountIn) public view returns (uint256) {
        (uint112 r0, uint112 r1, ) = IOPNSwapPair(address(lpToken)).getReserves();

        uint256 reserveIn = IOPNSwapPair(address(lpToken)).token0() == address(tokenB) ? r0 : r1;

        // Standard "optimal zap swap" formula accounting for 0.3% fee (997/1000),
        // derived from solving the constant-product formula for a matched deposit.
        uint256 a = 1997;
        uint256 b = 1997 * reserveIn;
        uint256 c = reserveIn * amountIn * 1000;

        uint256 discriminant = b * b + 4 * a * c;
        uint256 sqrtD = _sqrt(discriminant);

        return (sqrtD - b) / (2 * a);
    }

    function zapIn(uint256 amountIn, uint256 amountOutMin, uint256 deadline) external nonReentrant {
        require(amountIn > 0, "ZERO_AMOUNT");

        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 swapAmount = quoteOptimalSwap(amountIn);

        tokenB.forceApprove(address(router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmount,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        uint256 wopnReceived = amounts[amounts.length - 1];
        uint256 tUsdtRemaining = amountIn - swapAmount;

        tokenA.forceApprove(address(router), wopnReceived);
        tokenB.forceApprove(address(router), tUsdtRemaining);

        (uint256 usedA, uint256 usedB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            wopnReceived,
            tUsdtRemaining,
            0,
            0,
            address(this),
            deadline
        );

        // Refund any leftover dust back to the user instead of stranding it here
        if (wopnReceived > usedA) {
            tokenA.safeTransfer(msg.sender, wopnReceived - usedA);
        }
        if (tUsdtRemaining > usedB) {
            tokenB.safeTransfer(msg.sender, tUsdtRemaining - usedB);
        }

        // reset any leftover approval to router (dust-safe)
        tokenA.forceApprove(address(router), 0);
        tokenB.forceApprove(address(router), 0);

        lpToken.forceApprove(address(vault), liquidity);
        vault.depositFor(msg.sender, liquidity);

        emit ZapIn(msg.sender, amountIn, liquidity);
    }

    function zapOut(uint256 shares, uint256 amountOutMin, uint256 deadline) external nonReentrant {
        uint256 lpAmount = vault.withdrawTo(msg.sender, shares, address(this));

        lpToken.forceApprove(address(router), lpAmount);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            lpAmount,
            0,
            0,
            address(this),
            deadline
        );

        tokenA.forceApprove(address(router), amountA);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(amountA, amountOutMin, path, address(this), deadline);

        tokenA.forceApprove(address(router), 0);

        uint256 totalOut = tokenB.balanceOf(address(this));
        tokenB.safeTransfer(msg.sender, totalOut);

        emit ZapOut(msg.sender, shares, totalOut);
    }

    // ---------- internal math ----------

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

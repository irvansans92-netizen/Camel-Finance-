// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ZapRouter} from "../src/ZapRouter.sol";
import {LiquidityVault} from "../src/LiquidityVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockPair} from "./mocks/MockPair.sol";
import {MockRouter} from "./mocks/MockRouter.sol";

contract ZapRouterTest is Test {
    ZapRouter zap;
    LiquidityVault vault;
    MockERC20 tokenA; // WOPN
    MockERC20 tokenB; // tUSDT
    MockPair pair;
    MockRouter router;

    address alice = address(0xA11CE);

    function setUp() public {
        tokenA = new MockERC20("Wrapped OPN", "WOPN");
        tokenB = new MockERC20("Test USDT", "tUSDT");
        pair = new MockPair(address(tokenB), address(tokenA)); // token0 = tUSDT, token1 = WOPN
        router = new MockRouter(address(tokenA), address(tokenB), address(pair));

        // seed the mock router with generous liquidity so it never runs dry
        // across multiple zapIn/zapOut round trips within a single test
        tokenA.mint(address(router), 100_000e18);
        tokenB.mint(address(router), 100_000e18);
        pair.setReserves(100_000e18, 100_000e18); // 1:1 starting price

        // simulate a pre-existing liquidity pool with other LPs already in it,
        // matching the 100_000e18 / 100_000e18 reserves seeded above, so that
        // alice's later zapIn represents a small, proportional slice of the pool
        // instead of 100% of totalSupply (which would let her removeLiquidity()
        // drain the entire mock router's balance).
        pair.mint(address(0xDEAD), 200_000e18);

        vault = new LiquidityVault(address(pair));

        zap = new ZapRouter(
            address(tokenA),
            address(tokenB),
            address(pair),
            address(router),
            address(vault)
        );

        vault.setZapRouter(address(zap));

        tokenB.mint(alice, 1000e18);
        vm.prank(alice);
        tokenB.approve(address(zap), type(uint256).max);
    }

    function test_ZapInMintsVaultShares() public {
        vm.prank(alice);
        zap.zapIn(100e18, 0, block.timestamp + 1200);

        assertGt(vault.shares(alice), 0, "alice should have received vault shares");
        assertEq(tokenB.balanceOf(alice), 900e18, "alice should have spent exactly 100 tUSDT");
    }

    function test_ZapOutReturnsFundsCloseToOriginal() public {
        vm.prank(alice);
        zap.zapIn(100e18, 0, block.timestamp + 1200);

        uint256 shares = vault.shares(alice);

        vm.prank(alice);
        zap.zapOut(shares, 0, block.timestamp + 1200);

        uint256 finalBalance = tokenB.balanceOf(alice);

        // started with 1000, deposited 100 (900 left), then got most of it back minus AMM fees
        // allow for ~1% total slippage/fees across the double-swap round trip
        assertApproxEqRel(finalBalance, 1000e18, 0.02e18, "should get back ~100 tUSDT minus fees");
    }

    function test_RevertWhen_ZapInWithZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("ZERO_AMOUNT");
        zap.zapIn(0, 0, block.timestamp + 1200);
    }

    function test_RevertWhen_ZapOutWithMoreSharesThanOwned() public {
        vm.prank(alice);
        zap.zapIn(100e18, 0, block.timestamp + 1200);

        uint256 shares = vault.shares(alice);

        vm.prank(alice);
        vm.expectRevert("INSUFFICIENT_SHARE");
        zap.zapOut(shares + 1, 0, block.timestamp + 1200);
    }

    function test_QuoteOptimalSwapReturnsNonZeroForValidInput() public view {
        uint256 quoted = zap.quoteOptimalSwap(100e18);
        assertGt(quoted, 0, "should return a nonzero swap amount");
        assertLt(quoted, 100e18, "swap amount should be less than total input");
    }

    function test_MultipleUsersCanZapInIndependently() public {
        address bob = address(0xB0B);
        tokenB.mint(bob, 1000e18);
        vm.prank(bob);
        tokenB.approve(address(zap), type(uint256).max);

        vm.prank(alice);
        zap.zapIn(100e18, 0, block.timestamp + 1200);

        vm.prank(bob);
        zap.zapIn(100e18, 0, block.timestamp + 1200);

        assertGt(vault.shares(alice), 0);
        assertGt(vault.shares(bob), 0);
        assertEq(vault.totalShares(), vault.shares(alice) + vault.shares(bob));
    }
}

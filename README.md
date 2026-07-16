# 🐪 Camel Finance

**A one-click liquidity zap and yield vault for OPNswap on OPN Chain.**

## Tagline

The easiest way to enter and exit WOPN/tUSDT liquidity on OPN Chain — deposit tUSDT, get tUSDT back, no manual swapping or LP management required.

## Description

**What we built:** Camel Finance is a two-contract system (`ZapRouter` + `LiquidityVault`) that lets users provide liquidity to the OPNswap WOPN/tUSDT pool using a single token. Instead of manually swapping half their tUSDT to WOPN, calculating ratios, adding liquidity, and staking the resulting LP tokens, users just deposit tUSDT once.

**Why we built it:** Providing liquidity on any AMM normally takes 5+ manual steps and is a major onboarding barrier for new DeFi users. OPNswap's liquidity pools were largely empty or shallow when we started building — we wanted to make it radically easier for people to become liquidity providers on OPN Chain, growing the ecosystem's total liquidity in the process.

**How it works:**
1. **Zap In:** User deposits tUSDT into `ZapRouter`. The contract calculates the optimal swap amount (accounting for OPNswap's 0.3% fee), swaps part of it to WOPN via the OPNswap Router, adds liquidity to the WOPN/tUSDT pool, and deposits the resulting LP tokens into `LiquidityVault` on the user's behalf. Any leftover dust is refunded.
2. **Vault Shares:** `LiquidityVault` uses a share-based accounting system (similar to ERC4626) so each user's proportional claim on the pooled LP tokens is tracked fairly and transparently.
3. **Zap Out:** User calls `zapOut` with their share amount. The vault returns the corresponding LP tokens, which `ZapRouter` removes from the OPNswap pool, swaps the resulting WOPN back to tUSDT, and sends the full amount back to the user.

This was tested end-to-end on OPN Testnet: a deposit of ~0.52 tUSDT successfully zapped into the pool and back out, with only expected AMM fees as the difference — proving the full deposit/withdraw cycle works correctly.

## Roadmap

- **Q3 2026 — Camel Lens:** An on-chain analytics dashboard reading live vault TVL, user count, and pool health directly from the contracts, giving users transparency before they deposit.
- **Q3 2026 — Reward Layer:** Introduce an optional incentive/reward token layer on top of the vault (design already scaffolded in `AutoFarm.sol`) to further boost yield for early liquidity providers.
- **Q4 2026 — Camel Score:** A risk-scoring system for OPN Chain liquidity pools based on depth, volume, age, and impermanent loss exposure — helping users make informed decisions before zapping in.
- **Future — Multi-pair support:** Extend Camel Zap beyond WOPN/tUSDT to any OPNswap pair.

## Deployed Contracts (OPN Testnet, Chain ID 984)

| Contract | Address |
|---|---|
| LiquidityVault | `0xafdf241e1971dd36fcec882bfeb0fa502e9640a6` |
| ZapRouter | `0x61004c8de825d018589d1730eca22f6b6217fed3` |

**Dependencies used:**
| Name | Address |
|---|---|
| OPNswap Router | `0xB489bce5c9c9364da2D1D1Bc5CE4274F63141885` |
| OPNswap Factory | `0x8860242B65611dfd077aEe26C3C7920813dF9208` |
| WOPN/tUSDT LP Pair | `0x1eddFb93a644EC2922e547b7Ca8f9F72Dba8D317` |
| WOPN | `0xBc022C9dEb5AF250A526321d16Ef52E39b4DBD84` |
| tUSDT | `0x3e01b4d892E0D0A219eF8BBe7e260a6bc8d9B31b` |

## Proof of Working Cycle (Testnet)

- Zap In tx: `0xfc926b6fa3d123f4ed7e8867cd7e9395e25c391aa371f0fa16481a82eef7153c`
- Zap Out tx: `0x6cc6dc9df66207c4cec4bc0cfe773ce493c682d2b910dd76ce39b9b783610ef0`

Verify these on the [OPN Testnet Explorer](https://testnet.iopn.tech).

## Testing

The contracts are covered by a Foundry test suite of **14 automated tests**, run against mocked OPNswap infrastructure so they execute quickly and deterministically without needing a live testnet connection.

**Coverage includes:**
- Correct share minting on first and subsequent deposits (proportional accounting)
- Withdrawals returning the exact underlying LP amount owed
- Price-per-share increasing correctly when the vault accrues extra LP tokens (yield)
- Access control: only the `ZapRouter` can call `depositFor` / `withdrawTo` on the vault
- Full `zapIn` -> `zapOut` round trip, confirming the user gets back close to their original deposit (within AMM fee tolerance)
- Revert behavior for zero-amount deposits and over-withdrawal attempts
- Multiple independent users depositing without interfering with each other's share balances

Run the full suite with:

```bash
forge test -vv
```

All 14 tests pass as of the latest commit.

## Live Demo

Try it yourself on OPN Testnet: **[camelfinance.vercel.app](https://camelfinance.vercel.app)**

Connect an injected wallet (e.g. MetaMask) configured for OPN Testnet (Chain ID 984), then deposit tUSDT directly through the UI.

## How to Use

### Via the frontend (recommended)
1. Visit [camelfinance.vercel.app](https://camelfinance.vercel.app) and connect your wallet
2. Enter a tUSDT amount and click **Zap & Deposit**
3. View your vault shares and position under **My Position**
4. Click **Zap Out** anytime to withdraw back to tUSDT

### Via direct contract calls
1. Approve `ZapRouter` to spend your tUSDT
2. Call `zapIn(amountIn, amountOutMin, deadline)` on `ZapRouter`
3. Check your shares via `LiquidityVault.balanceOf(yourAddress)`
4. When ready to exit, call `zapOut(shares, amountOutMin, deadline)` on `ZapRouter`

## Tech Stack

Solidity 0.8.20, Foundry, OpenZeppelin Contracts v5.6.1, deployed on OPN Chain Testnet.

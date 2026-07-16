"use client";

import { useReadContract } from "wagmi";
import { CONTRACTS } from "../contracts/addresses";
import { LiquidityVaultABI } from "../contracts/LiquidityVaultABI";

export function usePricePerShare() {
  return useReadContract({
    address: CONTRACTS.VAULT as `0x${string}`,
    abi: LiquidityVaultABI,
    functionName: "pricePerShare",
  });
}

export function useTotalShares() {
  return useReadContract({
    address: CONTRACTS.VAULT as `0x${string}`,
    abi: LiquidityVaultABI,
    functionName: "totalShares",
  });
}

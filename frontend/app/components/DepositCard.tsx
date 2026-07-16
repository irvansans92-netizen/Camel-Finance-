"use client";

import { useState, useEffect } from "react";
import {
  useAccount,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseUnits, formatUnits } from "viem";
import { CONTRACTS } from "../contracts/addresses";

const ERC20_ABI = [
  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" },
    ],
    outputs: [{ type: "bool" }],
  },
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "owner", type: "address" }],
    outputs: [{ type: "uint256" }],
  },
] as const;

const ZAP_ROUTER_ABI = [
  {
    name: "zapIn",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "amountIn", type: "uint256" },
      { name: "amountOutMin", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
    outputs: [],
  },
] as const;

export default function DepositCard() {
  const { address, isConnected } = useAccount();
  const { writeContractAsync } = useWriteContract();

  const [amount, setAmount] = useState("");
  const [statusText, setStatusText] = useState("");
  const [loading, setLoading] = useState(false);

  const [approveHash, setApproveHash] =
    useState<`0x${string}` | undefined>();
  const [zapHash, setZapHash] =
    useState<`0x${string}` | undefined>();

  const { data: balance } = useReadContract({
    address: CONTRACTS.TUSDT,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
      refetchInterval: 5000,
    },
  });

  const { isSuccess: approveSuccess } =
    useWaitForTransactionReceipt({
      hash: approveHash,
    });

  const { isSuccess: zapSuccess } =
    useWaitForTransactionReceipt({
      hash: zapHash,
    });

  useEffect(() => {
    if (approveSuccess) {
      triggerZapIn();
    }
  }, [approveSuccess]);

  useEffect(() => {
    if (zapSuccess) {
      alert("Zap Deposit Success!");
      resetState();
      setAmount("");
    }
  }, [zapSuccess]);

  function resetState() {
    setLoading(false);
    setStatusText("");
    setApproveHash(undefined);
    setZapHash(undefined);
  }

  async function handleDeposit() {
    if (!isConnected) {
      alert("Connect wallet terlebih dahulu");
      return;
    }

    const parsed = parseUnits(amount, 18);

    setLoading(true);
    setStatusText("Approve tUSDT...");

    try {
      const hash = await writeContractAsync({
        address: CONTRACTS.TUSDT,
        abi: ERC20_ABI,
        functionName: "approve",
        args: [CONTRACTS.ZAP_ROUTER, parsed],
      });

      setApproveHash(hash);
    } catch (e) {
      console.error(e);
      resetState();
    }
  }

  async function triggerZapIn() {
    const parsed = parseUnits(amount, 18);

    const deadline = BigInt(
      Math.floor(Date.now() / 1000) + 1200
    );

    setStatusText("Zap Deposit...");

    try {
      const hash = await writeContractAsync({
        address: CONTRACTS.ZAP_ROUTER,
        abi: ZAP_ROUTER_ABI,
        functionName: "zapIn",
        args: [parsed, BigInt(0), deadline],
      });

      setZapHash(hash);
    } catch (e) {
      console.error(e);
      resetState();
    }
  }

  return (
    <div className="rounded-2xl border border-border-desert bg-card-desert p-6 shadow-sm">

      <div className="flex justify-between items-center">
        <h2 className="text-xl font-bold text-dark-accent">
          Deposit
        </h2>

        <span className="text-xs font-semibold text-neutral-500 bg-neutral-100 px-2 py-1 rounded-md">
          {isConnected
            ? `${Number(
                formatUnits(balance ?? BigInt(0),18)
              ).toFixed(2)} tUSDT`
            : "Wallet Disconnected"}
        </span>
      </div>

      <div className="relative mt-6 flex items-center">
        <input
          type="number"
          value={amount}
          onChange={(e)=>setAmount(e.target.value)}
          placeholder="1000"
          disabled={loading}
          className="w-full rounded-xl border border-border-desert bg-[#FAF6F0] p-4 pr-20 text-dark-accent placeholder-neutral-400 focus:outline-none focus:border-camel focus:ring-1 focus:ring-camel transition-all font-medium"
        />

        <span className="absolute right-4 font-bold text-sm text-neutral-500 bg-[#EADFCF]/60 px-2.5 py-1 rounded-lg">
          tUSDT
        </span>
      </div>

      {statusText && (
        <p className="mt-3 text-xs text-center font-semibold text-terracotta animate-pulse">
          {statusText}
        </p>
      )}

      <button
        onClick={handleDeposit}
        disabled={loading}
        className="mt-4 w-full rounded-xl bg-dark-accent hover:bg-opacity-90 text-[#FAF6F0] py-4 font-bold transition-all shadow-md cursor-pointer tracking-wide disabled:bg-neutral-400 active:scale-[0.98]"
      >
        {loading ? "Processing..." : "Zap & Deposit"}
      </button>

    </div>
  );
}

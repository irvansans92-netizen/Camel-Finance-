"use client";

import { useState, useEffect } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatUnits } from "viem";
import { CONTRACTS } from "../contracts/addresses";

const VAULT_ABI = [
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "getPricePerFullShare",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  }
] as const;

const ZAP_ROUTER_ABI = [
  {
    name: "zapOut",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "shares", type: "uint256" },
      { name: "amountOutMin", type: "uint256" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: []
  }
] as const;

export default function VaultCard() {
  const { address, isConnected } = useAccount();
  const { writeContractAsync } = useWriteContract();

  const [loading, setLoading] = useState(false);
  const [approveHash, setApproveHash] = useState<`0x${string}` | undefined>(undefined);
  const [zapOutHash, setZapOutHash] = useState<`0x${string}` | undefined>(undefined);

  const { data: userShares, refetch: refetchShares } = useReadContract({
    address: CONTRACTS.VAULT,
    abi: VAULT_ABI,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address }
  });

  const { data: pps } = useReadContract({
    address: CONTRACTS.VAULT,
    abi: VAULT_ABI,
    functionName: "getPricePerFullShare",
  });

  const { isSuccess: approveSuccess, isError: approveError } = useWaitForTransactionReceipt({ hash: approveHash });
  const { isSuccess: zapOutSuccess, isError: zapOutError } = useWaitForTransactionReceipt({ hash: zapOutHash });

  useEffect(() => {
    if (approveSuccess && approveHash) triggerZapOut();
    if (approveError) { alert("Approve Shares gagal."); resetState(); }
  }, [approveSuccess, approveError, approveHash]);

  useEffect(() => {
    if (zapOutSuccess && zapOutHash) {
      alert("🎉 Zap Out Sukses!");
      resetState();
      refetchShares();
    }
    if (zapOutError) { alert("Zap Out gagal."); resetState(); }
  }, [zapOutSuccess, zapOutError, zapOutHash]);

  const resetState = () => {
    setLoading(false);
    setApproveHash(undefined);
    setZapOutHash(undefined);
  };

  const handleZapOutClick = async () => {
    if (!isConnected || !userShares || userShares === BigInt(0)) {
      alert("Anda tidak memiliki shares untuk ditarik!");
      return;
    }

    setLoading(true);
    try {
      const tx = await writeContractAsync({
        address: CONTRACTS.VAULT,
        abi: VAULT_ABI,
        functionName: "approve",
        args: [CONTRACTS.ZAP_ROUTER, userShares],
      });
      setApproveHash(tx);
    } catch (error) {
      alert("Approve ditolak");
      resetState();
    }
  };

  const triggerZapOut = async () => {
    try {
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 1200);
      const tx = await writeContractAsync({
        address: CONTRACTS.ZAP_ROUTER,
        abi: ZAP_ROUTER_ABI,
        functionName: "zapOut",
        args: [userShares!, BigInt(0), deadline],
      });
      setZapOutHash(tx);
    } catch (error) {
      alert("Zap Out ditolak");
      resetState();
    }
  };

  const formattedShares = userShares ? parseFloat(formatUnits(userShares, 18)).toFixed(4) : "0.0000";
  const formattedPps = pps ? parseFloat(formatUnits(pps, 18)).toFixed(4) : "1.0000";
  const lpValue = userShares && pps 
    ? (parseFloat(formatUnits(userShares, 18)) * parseFloat(formatUnits(pps, 18))).toFixed(4)
    : "0.0000";

  return (
    <div className="rounded-2xl border border-border-desert bg-card-desert p-6 shadow-sm">
      <h2 className="text-xl font-bold text-dark-accent mb-4">My Position</h2>
      
      <div className="space-y-3 text-sm text-neutral-500">
        <div className="flex justify-between items-center">
          <span className="font-medium">Vault Shares</span>
          <span className="font-bold text-dark-accent">{formattedShares}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="font-medium">LP Value</span>
          <span className="font-bold text-dark-accent">{lpValue}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="font-medium">PPS</span>
          <span className="font-bold text-camel">{formattedPps}</span>
        </div>
      </div>

      <button
        onClick={handleZapOutClick}
        disabled={loading || !userShares || userShares === BigInt(0)}
        className="mt-6 w-full rounded-xl bg-terracotta hover:bg-opacity-90 text-[#FAF6F0] py-4 font-bold transition-all shadow-md disabled:bg-neutral-300 disabled:text-neutral-500 text-sm"
      >
        {loading ? "Memproses..." : "Zap Out"}
      </button>
    </div>
  );
}

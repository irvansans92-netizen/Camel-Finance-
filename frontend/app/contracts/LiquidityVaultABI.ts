export const LiquidityVaultABI = [
  {
    "type":"function",
    "name":"pricePerShare",
    "stateMutability":"view",
    "inputs":[],
    "outputs":[{"type":"uint256"}]
  },
  {
    "type":"function",
    "name":"totalShares",
    "stateMutability":"view",
    "inputs":[],
    "outputs":[{"type":"uint256"}]
  },
  {
    "type":"function",
    "name":"previewDeposit",
    "stateMutability":"view",
    "inputs":[{"type":"uint256"}],
    "outputs":[{"type":"uint256"}]
  }
] as const;

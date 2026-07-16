import { createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";

export const opnTestnet = {
  id: 984,
  name: "OPN Testnet",
  nativeCurrency: {
    name: "OPN",
    symbol: "OPN",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["https://testnet-rpc.iopn.tech"],
    },
    public: {
      http: ["https://testnet-rpc.iopn.tech"],
    },
  },
  blockExplorers: {
    default: {
      name: "OPN Explorer",
      url: "https://testnet.iopn.tech",
    },
  },
} as const;

export const config = createConfig({
  chains: [opnTestnet],
  connectors: [injected()],
  transports: {
    [opnTestnet.id]: http("https://testnet-rpc.iopn.tech"),
  },
});

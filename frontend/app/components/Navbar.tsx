"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import Image from "next/image";

export default function Navbar() {
  return (
    <nav className="sticky top-0 z-50 border-b border-border-desert bg-card-desert px-6 py-4 shadow-sm backdrop-blur-md bg-opacity-95">
      <div className="mx-auto flex max-w-5xl items-center justify-between">
        {/* Logo & Brand */}
        <div className="flex items-center space-x-3">
          <div className="relative h-10 w-10 overflow-hidden rounded-full bg-camel bg-opacity-20 p-1 flex items-center justify-center border border-camel border-opacity-30">
            <span className="text-xl">🐫</span>
          </div>
          <span className="text-lg font-black tracking-tight text-dark-accent">
            Camel <span className="text-camel">Finance</span>
          </span>
        </div>

        {/* Web3 Connect Button */}
        <div className="scale-90 origin-right sm:scale-100">
          <ConnectButton 
            chainStatus="none"
            showBalance={false}
            accountStatus={{
              smallScreen: "address",
              largeScreen: "address",
            }}
          />
        </div>
      </div>
    </nav>
  );
}

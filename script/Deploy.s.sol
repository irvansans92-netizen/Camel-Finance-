// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LiquidityVault} from "../src/LiquidityVault.sol";
import {ZapRouter} from "../src/ZapRouter.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address tokenA = vm.envAddress("TOKEN_A");   // WOPN
        address tokenB = vm.envAddress("TOKEN_B");   // tUSDT
        address lpToken = vm.envAddress("LP_TOKEN");
        address router = vm.envAddress("ROUTER");

        vm.startBroadcast(deployerKey);

        // 1. Deploy Vault first
        LiquidityVault vault = new LiquidityVault(lpToken);
        console.log("LiquidityVault deployed at:", address(vault));

        // 2. Deploy ZapRouter, pointing at the vault
        ZapRouter zap = new ZapRouter(tokenA, tokenB, lpToken, router, address(vault));
        console.log("ZapRouter deployed at:", address(zap));

        // 3. Authorize ZapRouter to call depositFor/withdrawTo on the vault
        vault.setZapRouter(address(zap));
        console.log("Vault.setZapRouter called with:", address(zap));

        vm.stopBroadcast();
    }
}

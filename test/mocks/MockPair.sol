// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Minimal mock LP token that also reports reserves like a real Uniswap V2 pair.
contract MockPair is ERC20 {
    address public token0;
    address public token1;

    uint112 public reserve0;
    uint112 public reserve1;

    constructor(address _token0, address _token1) ERC20("Mock LP", "MLP") {
        token0 = _token0;
        token1 = _token1;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }

    // Only the router (test contract) should call this in our mock setup
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

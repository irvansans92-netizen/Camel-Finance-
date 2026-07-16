// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LiquidityVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable lpToken;

    uint256 public totalShares;

    mapping(address => uint256) public shares;

    address public zapRouter;

    event Deposited(address indexed user, uint256 lpAmount, uint256 sharesMinted);

    event Withdrawn(address indexed user, uint256 lpAmount, uint256 sharesBurned);

    constructor(address _lpToken) Ownable(msg.sender) {
        lpToken = IERC20(_lpToken);
    }

    modifier onlyZap() {
        require(msg.sender == zapRouter, "NOT_ZAP");
        _;
    }

    function setZapRouter(address _router) external onlyOwner {
        zapRouter = _router;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "ZERO");

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 mintShares;

        if (totalShares == 0) {
            mintShares = amount;
        } else {
            mintShares = amount * totalShares / lpToken.balanceOf(address(this));
        }

        shares[msg.sender] += mintShares;

        totalShares += mintShares;

        emit Deposited(msg.sender, amount, mintShares);
    }

    function depositFor(address user, uint256 amount) external onlyZap nonReentrant {
        require(amount > 0, "ZERO");

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 mintShares;

        if (totalShares == 0) {
            mintShares = amount;
        } else {
            mintShares = amount * totalShares / lpToken.balanceOf(address(this));
        }

        shares[user] += mintShares;

        totalShares += mintShares;

        emit Deposited(user, amount, mintShares);
    }

    function withdraw(uint256 shareAmount) external nonReentrant {
        require(shareAmount > 0, "ZERO");

        require(shares[msg.sender] >= shareAmount, "INSUFFICIENT_SHARE");

        uint256 lpBalance = lpToken.balanceOf(address(this));

        uint256 lpAmount = shareAmount * lpBalance / totalShares;

        shares[msg.sender] -= shareAmount;

        totalShares -= shareAmount;

        lpToken.safeTransfer(msg.sender, lpAmount);

        emit Withdrawn(msg.sender, lpAmount, shareAmount);
    }

    function withdrawTo(address user, uint256 shareAmount, address receiver)
        external
        onlyZap
        nonReentrant
        returns (uint256 lpAmount)
    {
        require(shares[user] >= shareAmount, "INSUFFICIENT_SHARE");

        uint256 lpBalance = lpToken.balanceOf(address(this));

        lpAmount = shareAmount * lpBalance / totalShares;

        shares[user] -= shareAmount;
        totalShares -= shareAmount;

        lpToken.safeTransfer(receiver, lpAmount);

        emit Withdrawn(user, lpAmount, shareAmount);
    }


    function previewDeposit(
        uint256 amount
    )
        external
        view
        returns (uint256 mintShares)
    {
        if (totalShares == 0) {
            return amount;
        }

        return amount * totalShares / lpToken.balanceOf(address(this));
    }

    function pricePerShare() external view returns (uint256) {
        if (totalShares == 0) {
            return 1e18;
        }

        return lpToken.balanceOf(address(this)) * 1e18 / totalShares;
    }

    function totalAssets() external view returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    function balanceOf(address user) external view returns (uint256) {
        return shares[user];
    }
}

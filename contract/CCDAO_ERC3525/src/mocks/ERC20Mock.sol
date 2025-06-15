// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../IERC223Recipient.sol";

contract ERC20Mock is IERC20 {
    string public name = "AVAT";
    string public symbol = "AVAT";
    uint8 public decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ERC223扩展事件
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount, "");
        return true;
    }

    // ERC223扩展
    function transfer(address to, uint256 amount, bytes calldata data) public returns (bool) {
        _transfer(msg.sender, to, amount, data);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount, "");
        return true;
    }

    // mint函数用于测试
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    // 内部转账逻辑，兼容ERC223
    function _transfer(address from, address to, uint256 amount, bytes memory data) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        if (data.length > 0) {
            emit Transfer(from, to, amount, data);
        }

        // ERC223回调
        uint256 size;
        assembly { size := extcodesize(to) }
        if (size > 0) {
            IERC223Recipient(to).tokenReceived(from, amount, data); 
        }
    }
}
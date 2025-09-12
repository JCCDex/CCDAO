// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // 基础所有权管理
import "@openzeppelin/contracts/utils/Pausable.sol"; // 暂停功能
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // 重入攻击保护

// Safe 操作枚举
library Enum {
    enum Operation { Call, DelegateCall }
}

/**
 * @title SafeGuard
 * @dev Safe Guard合约，提供地址控制、额度限制、频率控制和安全暂停功能
 * @author JccMultiSign Team
 */
contract SafeGuard is Pausable, ReentrancyGuard {
    
    // ============ 事件定义 ============
    event AddressAddedToWhitelist(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressAddedToBlacklist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);
    event FunctionAddedToWhitelist(bytes4 indexed selector);
    event FunctionRemovedFromWhitelist(bytes4 indexed selector);
    event NativePerTxLimitUpdated(uint256 nativePerTxLimit);
    event TokenPerTxLimitUpdated(uint256 tokenPerTxLimit);
    event FrequencyLimitsUpdated(uint256 cooldownPeriod, uint256 maxDailyTx);
    event DailyCountReset(address indexed account, uint256 day);
    event EmergencyPause(address indexed account);
    event EmergencyUnpause(address indexed account);
    
    // ============ 状态变量 ============
    
    // 地址控制
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    bool public useWhitelist = true;  // true=使用白名单模式, false=使用黑名单模式
    
    // 函数控制
    mapping(bytes4 => bool) public functionWhitelist;
    
    // 基本转账限额
    uint256 public nativePerTxLimit;      // 原生币单笔限额
    uint256 public tokenPerTxLimit;       // ERC20单笔限额
    
    // 频率限制
    uint256 public cooldownPeriod = 1 hours;  // 冷却时间
    uint256 public maxDailyTx = 10;           // 每日最大交易数
    
    // 频率跟踪
    mapping(address => uint256) public lastTxTime;           // 上次交易时间
    mapping(address => uint256) public dailyTxCount;         // 每日交易计数
    mapping(address => uint256) public lastResetDay;         // 上次重置日期
    
    // 合约所有者
    address public owner;
    
    // 治理地址（紧急情况下可以调用治理函数）
    address public governanceAddress;
    
    
    // ============ 修饰符 ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress || msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier notPaused() {
        require(!paused(), "Contract is paused");
        _;
    }
    
    // ============ 构造函数 ============
    
    constructor(
        address _governanceAddress,
        uint256 _nativePerTxLimit,
        uint256 _tokenPerTxLimit
    ) {
        owner = msg.sender;
        governanceAddress = _governanceAddress;
        nativePerTxLimit = _nativePerTxLimit;
        tokenPerTxLimit = _tokenPerTxLimit;
        
        // 可根据需要添加允许的函数名
        _addFunctionToWhitelist(0xa9059cbb); // transfer(address,uint256)
        _addFunctionToWhitelist(0x23b872dd); // transferFrom(address,address,uint256)
        _addFunctionToWhitelist(0x42842e0e); // safeTransferFrom(address,address,uint256)
        _addFunctionToWhitelist(0xb88d4fde); // safeTransferFrom(address,address,uint256,bytes)
        _addFunctionToWhitelist(0x2eb2c2d6); // mintBatch(address,uint256[],uint256[],bytes)
    }
    
    // ============ Safe Guard 接口 ============
    
    /**
     * @dev 检查交易前条件 - Safe 标准接口
     * @param to 目标地址
     * @param value 转账金额
     * @param data 交易数据
     * @param operation 操作类型 (0=CALL, 1=DELEGATECALL)
     */
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 /* safeTxGas */,
        uint256 /* baseGas */,
        uint256 /* gasPrice */,
        address /* gasToken */,
        address payable /* refundReceiver */,
        bytes memory /* signatures */,
        address /* msgSender */
    ) external view {
        // 检查是否暂停
        require(!paused(), "Contract is paused");
        
        // 检查地址控制
        _checkAddressControl(to);
        
        // 检查函数控制
        if (data.length >= 4) {
            bytes4 selector = bytes4(data);
            _checkFunctionControl(selector);
        }
        
        // 检查基本转账限额
        _checkBasicLimits(to, value, data);
        
        // 检查频率限制
        _checkFrequencyLimits(to);
        
        // 检查操作类型限制
        _checkOperationType(operation);
    }
    
    /**
     * @dev 检查交易后条件 - Safe 标准接口
     * @param success 交易是否成功
     */
    function checkAfterExecution(
        bytes32 /* txHash */,
        bool success
    ) external {
        // 检查交易是否成功
        if (!success) return;
        // 更新频率跟踪
        _updateFrequencyTracking(msg.sender);
    }
    
    // ============ 地址控制函数 (设定白名单或黑名单地址，并设定使用白名单模式或黑名单模式) ============
    
    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
        emit AddressAddedToWhitelist(account);
    }
    
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }
    
    function addToBlacklist(address account) external onlyOwner {
        blacklist[account] = true;
        emit AddressAddedToBlacklist(account);
    }
    
    function removeFromBlacklist(address account) external onlyOwner {
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }
    
    function setAddressControlMode(bool _useWhitelist) external onlyOwner {
        useWhitelist = _useWhitelist;
    }
    
    // ============ 函数控制函数 (设定可用的函数名称) ============
    
    function addFunctionToWhitelist(bytes4 selector) external onlyOwner {
        _addFunctionToWhitelist(selector);
    }
    
    function removeFunctionFromWhitelist(bytes4 selector) external onlyOwner {
        functionWhitelist[selector] = false;
        emit FunctionRemovedFromWhitelist(selector);
    }
    
    function _addFunctionToWhitelist(bytes4 selector) internal {
        functionWhitelist[selector] = true;
        emit FunctionAddedToWhitelist(selector);
    }
    
    // ============ 基本限额控制函数 ============
    
    function setNativePerTxLimit(uint256 _nativePerTxLimit) external onlyOwner {
        nativePerTxLimit = _nativePerTxLimit;
        emit NativePerTxLimitUpdated(_nativePerTxLimit);
    }
    
    function setTokenPerTxLimit(uint256 _tokenPerTxLimit) external onlyOwner {
        tokenPerTxLimit = _tokenPerTxLimit;
        emit TokenPerTxLimitUpdated(_tokenPerTxLimit);
    }
    
    function setFrequencyLimits(uint256 _cooldownPeriod, uint256 _maxDailyTx) external onlyOwner {
        cooldownPeriod = _cooldownPeriod;
        maxDailyTx = _maxDailyTx;
        emit FrequencyLimitsUpdated(_cooldownPeriod, _maxDailyTx);
    }
    
    function resetDailyCount(address account) external onlyOwner {
        uint256 currentDay = block.timestamp / 1 days;
        lastResetDay[account] = currentDay;
        dailyTxCount[account] = 0;
        emit DailyCountReset(account, currentDay);
    }
    
    // ============ 紧急控制函数 (设定紧急暂停或恢复运行并指定治理地址) ============
    
    function emergencyPause() external onlyGovernance {
        _pause();
        emit EmergencyPause(msg.sender);
    }
    
    function emergencyUnpause() external onlyGovernance {
        _unpause();
        emit EmergencyUnpause(msg.sender);
    }
    
    function setGovernanceAddress(address _governanceAddress) external onlyOwner {
        governanceAddress = _governanceAddress;
    }
    
    
    // ============ 内部函数 (检查、更新状态)============
    
    function _checkAddressControl(address to) internal view {
        if (useWhitelist) {
            require(whitelist[to], "Address not in whitelist");
        } else {
            require(!blacklist[to], "Address is blacklisted");
        }
    }
    
    function _checkFunctionControl(bytes4 selector) internal view {
        require(functionWhitelist[selector], "Function not allowed");
    }
    
    function _checkBasicLimits(address /* to */, uint256 value, bytes memory data) internal view {
        // 检查原生币单笔限额
        if (value > 0) {
            require(value <= nativePerTxLimit, "Native amount exceeds per-tx limit");
        }
        
        // 检查ERC20单笔限额（通过解析transfer函数调用）
        if (data.length >= 4) {
            bytes4 selector = bytes4(data);
            if (selector == 0xa9059cbb) { // transfer(address,uint256)
                bytes memory callData = new bytes(data.length - 4);
                for (uint i = 0; i < callData.length; i++) {
                    callData[i] = data[i + 4];
                }
                (, uint256 amount) = abi.decode(callData, (address, uint256));
                require(amount <= tokenPerTxLimit, "Token amount exceeds per-tx limit");
            }
        }
    }
    
    
    function _checkFrequencyLimits(address to) internal view {
        // 检查冷却时间
        if (lastTxTime[to] > 0) {
            require(block.timestamp >= lastTxTime[to] + cooldownPeriod, "Cooldown period not met");
        }
        
        // 检查日交易数限制
        uint256 currentDay = block.timestamp / 1 days;
        if (lastResetDay[to] == currentDay) {
            require(dailyTxCount[to] < maxDailyTx, "Daily transaction limit exceeded");
        }
    }
    
    function _updateFrequencyTracking(address account) internal {
        uint256 currentDay = block.timestamp / 1 days;
        
        // 重置日计数（如果是新的一天）
        if (lastResetDay[account] != currentDay) {
            dailyTxCount[account] = 0;
            lastResetDay[account] = currentDay;
        }
        
        // 更新交易时间和计数
        lastTxTime[account] = block.timestamp;
        dailyTxCount[account]++;
    }
    
    function _checkOperationType(Enum.Operation operation) internal pure {
        // 禁止所有 DELEGATECALL 操作
        // 只允许CALL操作，确保安全性
        if (operation == Enum.Operation.DelegateCall) {
            revert("DelegateCall operations are not allowed. Only CALL operations are permitted.");
        }
    }
    
    
    // ============ 查询函数 ============
    
    function getDailyStats(address account) external view returns (
        uint256 txCount,
        uint256 lastTx,
        uint256 lastReset,
        uint256 cooldownRemaining
    ) {
        uint256 timeSinceLastTx = block.timestamp - lastTxTime[account];
        
        // 计算冷却时间剩余
        if (timeSinceLastTx >= cooldownPeriod) {
            cooldownRemaining = 0;
        } else {
            cooldownRemaining = cooldownPeriod - timeSinceLastTx;
        }
        
        return (
            dailyTxCount[account],      // 今日交易次数
            lastTxTime[account],        // 上次交易时间
            lastResetDay[account],      // 上次重置日期
            cooldownRemaining          // 冷却时间剩余（秒）
        );
    }
    
    function isAddressAllowed(address account) external view returns (bool) {
        if (useWhitelist) {
            return whitelist[account];
        } else {
            return !blacklist[account];
        }
    }
    
    function isFunctionAllowed(bytes4 selector) external view returns (bool) {
        return functionWhitelist[selector];
    }
}
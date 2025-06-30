// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./IAVA.sol";
import "./IERC223Recipient.sol";

using SafeERC20 for IERC20;

/**
 * @title AVA_Manager AVA 基金管理合约
 * @dev 管理AVA基金的注册、认购、订单撮合、快照和分红等功能
 * @notice 该合约允许管理员注册基金、设置认购期、批准认购、处理订单等
 * @dev 该合约使用了OpenZeppelin的Ownable和UUPSUpgradeable合约进行权限控制和升级
 * @dev 该合约实现了IERC223Recipient接口，用于接收ERC20代币的认购资金、订单挂单和分红空投
 * @dev 该合约遵循OpenZeppelin的合约标准，使用了Ownable和UUPSUpgradeable进行权限控制和升级
 * @dev 该合约遵循ERC3525标准，支持SFT（可分割代币）的发行和管理
 * @dev 该合约遵循ERC3525SlotEnumerable标准，支持SFT的可枚举和可分割功能
 */
contract AVA_Manager is
    AccessControlUpgradeable,
    IERC223Recipient,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum BusinessType {
        Subscribe,
        Deposit,
        BuyOrder,
        PlaceBuyOrder
    }

    struct Fund {
        address logic; // 业务逻辑合约（如AVA_v1/v2/v3）
        address erc20; // 认购用ERC20
        uint256 subscribeStart; // 认购开始时间
        uint256 subscribeEnd; // 认购结束时间
        uint256 fairPrice; // 每份基金公允价格
        uint256 fairPriceTimestamp; // 公允价格时间戳
        uint256 unrealized; // 未实现收益率（0-100%）
        uint256 unrealizedTimestamp; // 未实现收益率时间戳
        uint256 snapshotId; // 快照ID
        bool enabled; // 基金是否启用
    }

    struct Subscription {
        uint256 amount; // 认购金额
        bool approved; // 是否已批准认购
        bool minted; // 是否已铸造token
    }

    struct Order {
        address user; // 挂单用户地址
        uint256 fundId; // 基金ID
        uint256 tokenId; // 挂单的tokenId（如果是卖单, 买单tokenId为0）
        uint256 amount; // 挂单的token数量或买入金额
        uint256 totalValue; // 挂单的总价值（如果是买单则为买入金额）
        bool isSell; // 是否为卖单（true表示卖单，false表示买单）
        bool isActive; // 挂单是否有效（未被取消或匹配）
    }

    struct SnapshotHolder {
        address holder; // 持有人地址
        uint256 balance; // 持有人所有的SFT token对应的value总和
    }

    // 角色定义
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // 管理员角色
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE"); // 运营角色
    bytes32 public constant FINANCE_ROLE = keccak256("FINANCE_ROLE"); // 财务角色

    mapping(uint256 => Fund) public funds; // fundId => Fund
    mapping(address => bool) public whitelist; // 白名单地址

    mapping(uint256 => address[]) private fundSubscribers; // fundId => [subscriber addresses]
    mapping(uint256 => mapping(address => Subscription)) public subscriptions; // fundId => user => Subscription

    // 快照数据存储
    mapping(uint256 => mapping(uint256 => SnapshotHolder[])) public snapshots; // fundId => snapshotId => holders[]
    // 快照空投状态
    mapping(uint256 => mapping(uint256 => bool)) public isAirdropped; // fundId => snapshotId => airdropped

    mapping(uint256 => Order) public orders; // orderId => Order
    uint256 public nextOrderId;

    // 待售 token 记录
    mapping(uint256 => mapping(uint256 => uint256)) public tokenOnSale; // fundId => tokenId => amount

    event FundRegistered(uint256 indexed fundId, address logic, address erc20);
    event WhitelistUpdated(address indexed account, bool enabled);
    event Subscribed(
        uint256 indexed fundId,
        address indexed user,
        uint256 amount
    );
    event SubscriptionRejected(
        uint256 indexed fundId,
        address indexed user,
        uint256 amount
    );
    event SubscriptionApproved(
        uint256 indexed fundId,
        address indexed user,
        uint256 amount,
        uint256 tokenId
    );
    event FairPriceUpdated(
        uint256 indexed fundId,
        uint256 price,
        uint256 timestamp
    );
    event UnrealizedUpdated(
        uint256 indexed fundId,
        uint256 unrealized,
        uint256 timestamp
    );
    event SnapshotTaken(uint256 indexed fundId, uint256 snapshotId);
    event DividendAirdropped(
        uint256 indexed fundId,
        uint256 total,
        address erc20
    );
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed user,
        uint256 fundId,
        uint256 tokenId,
        uint256 amount,
        uint256 totalValue,
        bool isSell
    );
    event OrderCancelled(uint256 indexed orderId, address indexed user);
    event OrderMatched(
        uint256 indexed orderId,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );
    event AssetWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event FundLiquidated(
        uint256 indexed fundId,
        uint256 totalValue,
        uint256 timestamp
    );
    event TokenMinted(
        uint256 indexed fundId,
        address indexed to,
        uint256 tokenId,
        uint256 value
    );
    event Deposited(
        address indexed from,
        address indexed fund,
        address indexed erc20,
        uint256 amount
    );

    // ========== 修饰符 ==========
    // 仅限白名单地址调用
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not in whitelist");
        _;
    }

    // 验证基金是否存在且启用
    modifier validFund(uint256 fundId) {
        require(funds[fundId].logic != address(0), "Fund not exists");
        require(funds[fundId].enabled, "Fund disabled");
        _;
    }

    /**
     * @dev 检查转账金额是否为最小转账单位的整数倍
     * @param logic 基金逻辑合约地址
     * @param amount 转账金额
     * @return 是否满足最小转账单位要求
     */
    function checkMinTransferValue(
        address logic,
        uint256 amount
    ) public view returns (bool) {
        uint256 _minTransferValue = IAVA(logic).minTransferValue();
        return amount % _minTransferValue == 0;
    }

    /**
     * @dev 检查用户是否已批准合约操作其token
     * @param user 用户地址
     * @param logic 基金逻辑合约地址
     * @param tokenId token ID
     * @return 是否已批准
     */
    function checkApproved(
        address user,
        address logic,
        uint256 tokenId
    ) public view returns (bool) {
        IAVA avaLogic = IAVA(logic);
        return
            avaLogic.isApprovedForAll(user, address(this)) ||
            avaLogic.getApproved(tokenId) == address(this);
    }

    // 初始化合约
    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        // 设置初始角色
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(FINANCE_ROLE, msg.sender);
    }

    // UUPS 升级授权
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev 注册一个新的基金
     * @param fundId 基金ID
     * @param logic 基金SFT合约地址
     * @param erc20 认购用ERC20代币地址
     * @notice 该函数只能由合约所有者调用，且基金ID不能重复
     * @notice 注册后基金的认购期、启用状态等需要通过其他函数设置
     * @dev 该函数会初始化基金的认购期为0，启用状态为true，公允价格和未实现收益率为100
     */
    function registerFund(
        uint256 fundId,
        address logic,
        address erc20
    ) external onlyRole(OPERATOR_ROLE) {
        require(funds[fundId].logic == address(0), "Fund exists");
        funds[fundId] = Fund(
            logic,
            erc20,
            0,
            0,
            0,
            0,
            100e18,
            block.timestamp,
            0,
            true
        );
        emit FundRegistered(fundId, logic, erc20);
    }

    /**
     * @dev 设置基金的认购期
     * @param fundId 基金ID
     * @param start 认购开始时间戳
     * @param end 认购结束时间戳
     * @notice 该函数只能由合约所有者调用，且基金ID必须有效
     */
    function setSubscribePeriod(
        uint256 fundId,
        uint256 start,
        uint256 end
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        // 检查开始时间必须大于当前时间
        require(start >= block.timestamp, "Start time must be in future");

        // 检查结束时间必须大于开始时间
        require(end > start, "End time must be after start time");

        funds[fundId].subscribeStart = start;
        funds[fundId].subscribeEnd = end;
    }

    /**
     * @dev 设置基金的启用状态
     * @param fundId 基金ID
     * @param enable 是否启用基金
     * @notice 该函数只能由合约所有者调用，且基金ID必须有效
     */
    function setFundEnable(
        uint256 fundId,
        bool enable
    ) external onlyRole(ADMIN_ROLE) {
        require(funds[fundId].logic != address(0), "Fund not exists");
        funds[fundId].enabled = enable;
    }

    /**
     * @dev 获取基金信息
     * @param fundId 基金ID
     * @return logic 基金逻辑合约地址
     * @return erc20 认购用ERC20代币地址
     * @return subscribeStart 认购开始时间戳
     * @return subscribeEnd 认购结束时间戳
     * @return fairPrice 每份基金公允价格
     * @return fairPriceTimestamp 公允价格时间戳
     * @return unrealized 未实现收益率（0-100%）
     * @return unrealizedTimestamp 未实现收益率时间戳
     * @return snapshotId 快照ID
     * @return enabled 基金是否启用
     */
    function getFundInfo(
        uint256 fundId
    )
        external
        view
        returns (
            address logic,
            address erc20,
            uint256 subscribeStart,
            uint256 subscribeEnd,
            uint256 fairPrice,
            uint256 fairPriceTimestamp,
            uint256 unrealized,
            uint256 unrealizedTimestamp,
            uint256 snapshotId,
            bool enabled
        )
    {
        Fund storage fund = funds[fundId];
        return (
            fund.logic,
            fund.erc20,
            fund.subscribeStart,
            fund.subscribeEnd,
            fund.fairPrice,
            fund.fairPriceTimestamp,
            fund.unrealized,
            fund.unrealizedTimestamp,
            fund.snapshotId,
            fund.enabled
        );
    }

    /**
     * @dev 设置白名单地址
     * @param account 白名单地址
     * @param enabled 是否启用白名单
     * @notice 该函数只能由合约所有者调用
     */
    function setWhitelist(
        address account,
        bool enabled
    ) external onlyRole(ADMIN_ROLE) {
        whitelist[account] = enabled;
        emit WhitelistUpdated(account, enabled);
    }

    /**
     * @dev 设置基金的公允价格
     * @param fundId 基金ID
     * @param price 公允价格
     * @param timestamp 公允价格时间戳
     * @notice 该函数只能由合约所有者调用，且基金ID必须有效
     */
    function setFairPrice(
        uint256 fundId,
        uint256 price,
        uint256 timestamp
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        funds[fundId].fairPrice = price;
        funds[fundId].fairPriceTimestamp = timestamp;

        emit FairPriceUpdated(fundId, price, timestamp);
    }

    /**
     * @dev 设置基金的未实现收益率
     * @param fundId 基金ID
     * @param unrealized 未实现收益率（0-100%）
     * @param timestamp 未实现收益率时间戳
     * @notice 该函数只能由合约所有者调用，且基金ID必须有效
     */
    function setUnrealized(
        uint256 fundId,
        uint256 unrealized,
        uint256 timestamp
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        require(unrealized <= 100e18, "Unrealized must be <= 100%");

        funds[fundId].unrealized = unrealized;
        funds[fundId].unrealizedTimestamp = timestamp;

        emit UnrealizedUpdated(fundId, unrealized, timestamp);
    }

    /**
     * @dev 用户认购基金
     * @param user 用户地址
     * @param fundId 基金ID
     * @param amount 认购金额
     * @param token 认购用ERC20代币地址
     * @notice 该函数只能在认购期内调用，且用户只能认购一次,用户通过ERC20代币转账触发该函数，附加的calldata参数为: BusinessType.Subscribe, fundId
     */
    function subscribe(
        address user,
        uint256 fundId,
        uint256 amount,
        address token
    ) internal validFund(fundId) {
        Fund storage fund = funds[fundId];

        require(address(fund.erc20) == token, "ERC20 mismatch");

        require(
            block.timestamp >= fund.subscribeStart &&
                block.timestamp <= fund.subscribeEnd,
            "Not in subscribe period"
        );

        require(amount > 0, "Amount=0");

        require(
            checkMinTransferValue(fund.logic, amount),
            "AVA: value must be a multiple of min transfer value"
        );

        require(subscriptions[fundId][user].amount == 0, "Already subscribed");

        subscriptions[fundId][user] = Subscription(amount, false, false);
        fundSubscribers[fundId].push(user);

        emit Subscribed(fundId, user, amount);
    }

    /**
     * @dev 获取用户在指定基金的认购信息
     * @param fundId 基金ID
     * @param user 用户地址
     * @return amount 认购金额
     * @return approved 是否已批准
     * @return minted 是否已铸造token
     */
    function getSubscription(
        uint256 fundId,
        address user
    ) external view returns (uint256 amount, bool approved, bool minted) {
        Subscription memory sub = subscriptions[fundId][user];
        return (sub.amount, sub.approved, sub.minted);
    }

    /**
     * @dev 获取指定基金的所有认购用户信息
     * @param fundId 基金ID
     * @return subscribers 认购用户地址列表
     * @return amounts 认购金额列表
     * @return approvedList 是否已批准列表
     * @return mintedList 是否已铸造列表
     */
    function getFundSubscriptions(
        uint256 fundId
    )
        external
        view
        returns (
            address[] memory subscribers,
            uint256[] memory amounts,
            bool[] memory approvedList,
            bool[] memory mintedList
        )
    {
        subscribers = fundSubscribers[fundId];
        uint256 length = subscribers.length;

        amounts = new uint256[](length);
        approvedList = new bool[](length);
        mintedList = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            Subscription memory sub = subscriptions[fundId][subscribers[i]];
            amounts[i] = sub.amount;
            approvedList[i] = sub.approved;
            mintedList[i] = sub.minted;
        }

        return (subscribers, amounts, approvedList, mintedList);
    }

    /**
     * @dev 提取合约中的ERC20资产,主要满足资金管理日常调度,错误转移到本合约的ERC20返回
     * @param token 代币地址
     * @param to 接收地址
     * @param amount 提取金额
     * @notice 该函数只能由合约所有者调用，且接收地址不能为0
     */
    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(FINANCE_ROLE) nonReentrant {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");

        // 检查余额
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "Insufficient balance");

        // 转账
        IERC20(token).safeTransfer(to, amount);

        emit AssetWithdrawn(token, to, amount);
    }

    /**
     * @dev 提取合约中的ERC721资产，主要用于错误转入或资金管理
     * @param nft ERC721合约地址
     * @param to 接收地址
     * @param tokenId NFT的tokenId
     * @notice 该函数只能由合约所有者调用，且接收地址不能为0
     */
    function withdrawERC721(
        address nft,
        address to,
        uint256 tokenId
    ) external onlyRole(FINANCE_ROLE) nonReentrant {
        require(to != address(0), "Invalid recipient");
        require(nft != address(0), "Invalid NFT contract");

        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    }

    /**
     * @dev 通过本合约管理员权限，帮助将其他合约的owner权限转移到指定的新地址
     *      当管理合约(proxy)弃用时候以及错误转移到这里的管理权限，可以解除
     * @param target 目标合约地址（需要转移owner权限的合约）
     * @param newOwner 新的owner地址
     */
    function transferOwnership(
        address target,
        address newOwner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(target != address(0), "Target contract cannot be zero address");

        // 调用目标合约的 transferOwnership 方法
        (bool success, ) = target.call(
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );
        require(success, "Ownership transfer failed");
    }

    /**
     * @dev 移除申购用户
     * @param fundId 基金ID
     * @param user 用户地址
     * @notice 从申购用户中移除指定的用户
     */
    function _removeSubscriber(uint256 fundId, address user) internal {
        for (uint256 i = 0; i < fundSubscribers[fundId].length; i++) {
            if (fundSubscribers[fundId][i] == user) {
                fundSubscribers[fundId][i] = fundSubscribers[fundId][
                    fundSubscribers[fundId].length - 1
                ];
                fundSubscribers[fundId].pop();
                break;
            }
        }
    }

    /**
     * @dev 管理员拒绝认购并退款
     * @param fundId 基金ID
     * @param user 用户地址
     * @notice 该函数只能由合约所有者调用，且用户必须有有效的认购记录
     */
    function rejectSubscription(
        uint256 fundId,
        address user
    ) external onlyRole(OPERATOR_ROLE) nonReentrant validFund(fundId) {
        Subscription storage sub = subscriptions[fundId][user];
        require(sub.amount > 0, "No valid subscription");

        // 已经铸造发行的情况下，拒绝驳回
        require(
            !sub.approved && !sub.minted,
            "Cannot reject after approval/minting"
        );

        // 记录要退还的金额
        uint256 amountToRefund = sub.amount;

        // 清除认购记录
        delete subscriptions[fundId][user];

        // 从数组中移除用户地址
        _removeSubscriber(fundId, user);

        // 退还AVAT
        IERC20(funds[fundId].erc20).safeTransfer(user, amountToRefund);

        emit SubscriptionRejected(fundId, user, amountToRefund);
    }

    /**
     * @dev 管理员批准认购并铸造token
     * @param fundId 基金ID
     * @param user 用户地址
     * @param tokenId 认购对应的token ID
     * @param slot SFT的slot值
     * @notice 该函数只能在认购期结束后调用，且用户必须有有效的认购记录
     */
    function approveSubscription(
        uint256 fundId,
        address user,
        uint256 tokenId,
        uint256 slot
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        Fund storage fund = funds[fundId];
        require(
            block.timestamp > fund.subscribeEnd,
            "Subscribe period not ended"
        );

        Subscription storage sub = subscriptions[fundId][user];

        require(sub.amount > 0 && !sub.approved, "No valid subscription");

        IAVA(funds[fundId].logic).mint(user, tokenId, slot, sub.amount);

        sub.approved = true;
        sub.minted = true;

        emit SubscriptionApproved(fundId, user, sub.amount, tokenId);
    }

    /**
     * @dev 管理员批准认购并铸造剩余的token，用来应对认购期结束后未铸造的情况和链外协商铸造交付
     * @param fundId 基金ID
     * @param to 接收用户地址
     * @param tokenId 认购对应的token ID
     * @param slot SFT的slot值
     * @param value 认购金额（对应的SFT value）
     * @notice 该函数只能在认购期结束后调用
     */
    function mintRemaining(
        uint256 fundId,
        address to,
        uint256 tokenId,
        uint256 slot,
        uint256 value
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        Fund storage fund = funds[fundId];

        require(
            block.timestamp > fund.subscribeEnd,
            "Subscribe period not ended"
        );

        // 获取合约当前已发行的总量
        IAVA logic = IAVA(fund.logic);
        uint256 currentTotalValue = logic.currentTotalValue();
        uint256 maxTotalValue = logic.maxTotalValue();

        // 检查是否超过最大发行量
        require(
            currentTotalValue + value <= maxTotalValue,
            "Exceeds max total value"
        );

        // 铸造token
        logic.mint(to, tokenId, slot, value);

        emit TokenMinted(fundId, to, tokenId, value);
    }

    /**
     * @dev 用户挂单卖出SFT token
     * @param fundId 基金ID
     * @param tokenId 挂单的token ID
     * @param amount 挂单的SFT token中的value, 表示该基金的初始价值
     * @param totalValue 挂单的总价值（对应的ERC20代币数量），也就是该基金售卖的市场价值
     * @return orderId 新创建的订单ID
     * @notice 该函数只能在基金启用且用户是SFT所有者时调用
     */
    function placeSellOrder(
        uint256 fundId,
        uint256 tokenId,
        uint256 amount,
        uint256 totalValue
    ) external onlyWhitelisted validFund(fundId) returns (uint256) {
        Fund storage fund = funds[fundId];

        IAVA logic = IAVA(fund.logic);

        // 检查token所有权
        require(logic.ownerOf(tokenId) == msg.sender, "Not token owner");

        // 检查token余额是否足够
        require(
            logic.balanceOf(tokenId) >= amount,
            "Insufficient token balance"
        );

        // 检查是否已授权给管理合约
        require(
            checkApproved(msg.sender, fund.logic, tokenId),
            "Token not approved"
        );

        // 检查 token 是否已在其他订单中
        require(
            tokenOnSale[fundId][tokenId] + amount <= logic.balanceOf(tokenId),
            "Token already on sale"
        );

        // 记录待售数量
        tokenOnSale[fundId][tokenId] += amount;

        orders[nextOrderId] = Order(
            msg.sender,
            fundId,
            tokenId,
            amount,
            totalValue,
            true,
            true
        );
        emit OrderPlaced(
            nextOrderId,
            msg.sender,
            fundId,
            tokenId,
            amount,
            totalValue,
            true
        );
        return nextOrderId++;
    }

    /**
     * @dev 用户挂单买入基金token,创建一个买单
     * @param user 用户地址
     * @param fundId 基金ID
     * @param amount 挂单的SFT token中的value, 表示该基金的初始价值
     * @param totalValue 挂单的总价值（对应的ERC20代币数量）,也就是该基金的市场价值
     * @notice 该函数是通过ERC20代币转账触发的回调函数,用户需要转账时提供calldata参数: BusinessType.PlaceBuyOrder, fundId, amount
     */
    function placeBuyOrder(
        address user,
        uint256 fundId,
        uint256 amount,
        uint256 totalValue
    ) internal validFund(fundId) {
        Fund storage fund = funds[fundId];

        require(fund.erc20 == msg.sender, "ERC20 mismatch");
        require(amount > 0, "Amount must be greater than 0");
        require(
            checkMinTransferValue(fund.logic, amount),
            "AVA: value must be a multiple of min transfer value"
        );
        require(totalValue > 0, "Total value must be greater than 0");

        orders[nextOrderId] = Order({
            user: user,
            fundId: fundId,
            tokenId: 0, // 买单不需要指定tokenId
            amount: amount,
            totalValue: totalValue,
            isSell: false, // 标记为买单
            isActive: true
        });

        emit OrderPlaced(
            nextOrderId,
            user,
            fundId,
            0,
            amount,
            totalValue,
            true
        );
        nextOrderId++;
    }

    /**
     * @dev 用户取消挂单
     * @param orderId 订单ID
     * @notice 该函数只能由订单所有者调用，且订单必须处于激活状态
     */
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(order.user == msg.sender, "Not order owner");
        require(order.isActive, "Order inactive");

        order.isActive = false;

        // 取消订单时减少待售数量
        if (order.isSell) {
            tokenOnSale[order.fundId][order.tokenId] -= order.amount;
        } else {
            IERC20(funds[order.fundId].erc20).safeTransfer(
                msg.sender,
                order.totalValue
            );
        }

        emit OrderCancelled(orderId, msg.sender);
    }

    /**
     * @dev 用户买入基金token（吃对手单）
     * @param user 用户地址
     * @param erc20 认购用ERC20代币地址
     * @param orderId 订单ID
     * @param totalValue 买入的总价值（对应的ERC20代币数量）
     * @notice 该函数是通过ERC20代币转账触发的回调函数,用户需要转账时提供calldata参数: BusinessType.BuyOrder, orderId
     */
    function buyOrder(
        address user,
        address erc20,
        uint256 orderId,
        uint256 totalValue
    ) internal {
        Order storage order = orders[orderId];
        require(order.isActive, "Order inactive");
        require(order.isSell, "Order not for sale");
        require(order.totalValue == totalValue, "Total value mismatch");
        require(order.user != user, "Cannot buy your own order"); // 防止用户自己卖给自己

        Fund storage fund = funds[order.fundId];
        require(fund.logic != address(0), "Fund not exists");
        require(fund.erc20 == erc20, "ERC20 mismatch");

        order.isActive = false;
        // 更新待售数量
        tokenOnSale[order.fundId][order.tokenId] -= order.amount;

        address seller = order.user;
        uint256 orderAmount = order.amount;
        uint256 sellTokenId = order.tokenId;

        // 买家支付ERC20
        IERC20(fund.erc20).safeTransfer(seller, totalValue);
        // 卖家转让token
        IAVA(fund.logic).transferFrom(sellTokenId, user, orderAmount);

        emit OrderMatched(orderId, user, orderAmount, totalValue);
    }

    /**
     * @dev 用户卖出SFT token（撮合成交）
     * @param fundId 基金ID
     * @param orderId 订单ID
     * @param tokenId 卖出的token ID
     * @notice 该函数只能在订单处于激活状态且是买单时调用，且用户必须是token所有者
     */
    function sellOrder(
        uint256 fundId,
        uint256 orderId,
        uint256 tokenId
    ) external onlyWhitelisted nonReentrant validFund(fundId) {
        Order storage order = orders[orderId];
        require(order.isActive, "Order inactive");
        require(!order.isSell, "Order not a buy order"); // 确保是买单
        require(order.user != msg.sender, "Cannot sell to your own order"); // 防止用户自己卖给自己

        require(fundId == order.fundId, "Fund Id mismatch");

        Fund storage fund = funds[order.fundId];
        require(fund.logic != address(0), "Fund not exists");
        require(fund.enabled, "Fund disabled");

        IAVA logic = IAVA(fund.logic);

        // 检查卖家是否拥有指定的 SFT
        require(logic.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(
            logic.balanceOf(tokenId) >= order.amount,
            "Insufficient token balance"
        );

        // 检查是否已授权给管理合约
        require(
            checkApproved(msg.sender, fund.logic, tokenId),
            "Token not approved"
        );

        // 更新订单中tokenId数据
        order.tokenId = tokenId;

        // 标记订单为已完成
        order.isActive = false;

        address buyer = order.user;
        uint256 orderAmount = order.amount;
        uint256 totalValue = order.totalValue;

        // 转移 SFT 给买家
        logic.transferFrom(tokenId, buyer, orderAmount);

        // 转移 ERC20 给卖家
        IERC20(fund.erc20).safeTransfer(msg.sender, totalValue);

        emit OrderMatched(orderId, msg.sender, orderAmount, totalValue);
    }

    /**
     * @dev 创建基金的快照
     * @dev 快照会记录所有持有者的地址和对应的SFT token value
     * @param fundId 基金ID
     * @param snapshotId 快照ID
     * @notice 该函数只能由合约所有者调用，且基金必须启用
     * @notice 创建基金的持有快照有两种方法，一种是通过合约执行快照，缺点是消耗燃料,优点是所有记录都在链上；
     * @notice 一种是通过链外查询时候指定区块号，节省燃料，但需要链外计算生成快照数据。
     * @notice 管理合约对应提供了两种空投方法
     */
    function takeSnapshot(
        uint256 fundId,
        uint256 snapshotId
    ) external onlyRole(OPERATOR_ROLE) validFund(fundId) {
        require(snapshots[fundId][snapshotId].length == 0, "snapshot exiset");
        IAVA logic = IAVA(funds[fundId].logic);
        uint256 totalSupply = logic.totalSupply();

        // 遍历所有token获取持有人
        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = logic.tokenByIndex(i);
            address holder = logic.ownerOf(tokenId);
            uint256 value = logic.balanceOf(tokenId);

            if (value > 0) {
                snapshots[fundId][snapshotId].push(
                    SnapshotHolder(holder, value)
                );
            }
        }

        funds[fundId].snapshotId = snapshotId;
        isAirdropped[fundId][snapshotId] = false; // 初始化空投状态

        emit SnapshotTaken(fundId, snapshotId);
    }

    /**
     * @dev 获取指定基金的快照数据
     * @param fundId 基金ID
     * @param snapshotId 快照ID
     * @return holders 持有人地址列表
     * @return balances 对应的SFT token value列表
     * @notice 该函数返回指定快照的所有持有者和对应的SFT token value
     */
    function getSnapshot(
        uint256 fundId,
        uint256 snapshotId
    )
        external
        view
        returns (address[] memory holders, uint256[] memory balances)
    {
        Fund storage fund = funds[fundId];
        require(snapshotId <= fund.snapshotId, "Invalid snapshot id");

        SnapshotHolder[] storage snapshot = snapshots[fundId][snapshotId];
        uint256 length = snapshot.length;

        holders = new address[](length);
        balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            holders[i] = snapshot[i].holder;
            balances[i] = snapshot[i].balance;
        }

        return (holders, balances);
    }

    /**
     * @dev 分红空投给快照中的所有持有人
     * @param fundId 基金ID
     * @param snapshotId 快照ID
     * @param erc20 分红用ERC20代币地址
     * @param total 分红总额
     * @notice 该函数只能由合约所有者调用，且快照未被空投过
     */
    function airdropDividend(
        uint256 fundId,
        uint256 snapshotId,
        address erc20,
        uint256 total
    ) external onlyRole(FINANCE_ROLE) nonReentrant {
        require(!isAirdropped[fundId][snapshotId], "Already airdropped");

        SnapshotHolder[] storage snapshot = snapshots[fundId][snapshotId];
        uint256 length = snapshot.length;
        require(length > 0, "No holders");

        require(total > 0, "Amount must be greater than 0");

        Fund storage fund = funds[fundId];
        uint256 sum = IAVA(fund.logic).maxTotalValue();

        require(
            IERC20(erc20).balanceOf(address(this)) >= total,
            "Insufficient balance"
        );

        for (uint256 i = 0; i < length; i++) {
            uint256 amount = (total * snapshot[i].balance) / sum;
            if (amount > 0) {
                IERC20(erc20).safeTransfer(snapshot[i].holder, amount);
            }
        }

        isAirdropped[fundId][snapshotId] = true;

        emit DividendAirdropped(fundId, total, erc20);
    }

    /**
     * @dev 分红空投给指定的持有人列表，这是通过指定区块号进行查询统计的快照数据进行空投
     * @param fundId 基金ID
     * @param erc20 分红用ERC20代币地址
     * @param holders 持有人地址列表
     * @param balances 对应的SFT token value列表
     * @notice 该函数只能由合约所有者调用，且持有人和余额长度必须匹配
     */
    function airdropDividend(
        uint256 fundId,
        address erc20,
        address[] memory holders,
        uint256[] memory balances
    ) external onlyRole(FINANCE_ROLE) nonReentrant validFund(fundId) {
        uint256 total = 0;

        require(holders.length > 0, "No holders");
        require(
            holders.length == balances.length,
            "Holders and balances length mismatch"
        );

        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == address(0) || balances[i] == 0) {
                continue;
            }

            IERC20(erc20).safeTransfer(holders[i], balances[i]);

            total += balances[i];
        }

        emit DividendAirdropped(fundId, total, erc20);
    }

    // ========== ERC223 资产接收回调 ==========
    /**
     * @dev ERC223 接收回调函数，用于接收ERC20认购资金、创建订单、成交订单和分红空投
     * @param from 发送者地址
     * @param value 发送的金额
     * @param data 附加数据（64字节）, 前8位表示认购，挂单，吃单和存款，后32位表示fundId或orderId, 最后32位表示amount
     */
    function tokenReceived(
        address from,
        uint256 value,
        bytes calldata data
    ) external override nonReentrant {
        require(data.length >= 65, "Invalid data");
        require(whitelist[from], "User not in whitelist");

        (uint8 businessType, uint256 id, uint256 amount) = abi.decode(
            data,
            (uint8, uint256, uint256)
        );

        if (BusinessType(businessType) == BusinessType.Subscribe) {
            // 认购登记
            subscribe(from, id, value, msg.sender);
        } else if (BusinessType(businessType) == BusinessType.BuyOrder) {
            // 买入订单，吃对手单
            buyOrder(from, msg.sender, id, value);
        } else if (BusinessType(businessType) == BusinessType.PlaceBuyOrder) {
            // 挂买入单，构建新的买单
            placeBuyOrder(from, id, amount, value);
        } else if (BusinessType(businessType) == BusinessType.Deposit) {
            // 存入资金，用于空投或者其他支出项目
            require(hasRole(FINANCE_ROLE, from), "Not finance role");
            Fund storage fund = funds[id];
            require(fund.erc20 == msg.sender, "ERC20 mismatch");
            emit Deposited(from, fund.logic, fund.erc20, value);
        } else {
            revert("Unknown business type");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/AVA_Manager.sol";
import "../src/AVA_v1.sol";
import "../src/mocks/ERC20Mock.sol";
import "../src/mocks/AVA_Manager_UpgradeMock.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AVA_ManagerTest is Test {
    enum BusinessType {
        Subscribe,
        Deposit,
        BuyOrder,
        PlaceBuyOrder
    }

    AVA_Manager manager;
    ERC20Mock avat;
    AVA_v1 avaV1;

    string name = "Australia Valued Assets 001";
    string symbol = "AVA001";
    uint8 decimals = 18;
    string baseURI = "https://avat.shop/ava/001/";
    uint256 private constant maxTotalValue = 2000000e18;
    uint256 private constant minTransferValue = 100000e18;

    address admin = vm.addr(1);
    address newAdmin = vm.addr(2);

    address user1 = vm.addr(3);
    address user2 = vm.addr(4);
    address user3 = vm.addr(5);
    address user4 = vm.addr(6);
    address user5 = vm.addr(7);
    address user6 = vm.addr(8);
    address user7 = vm.addr(9);
    address user8 = vm.addr(10);
    address user9 = vm.addr(11);

    uint256 fundId1 = 1;
    uint256 fundId2 = 2;

    uint256 slot1 = 1;

    uint256 tokenId1 = 1;
    uint256 tokenId2 = 2;
    uint256 tokenId3 = 3;
    uint256 tokenId4 = 4;
    uint256 tokenId5 = 5;
    uint256 tokenId6 = 6;
    uint256 tokenId7 = 7;
    uint256 tokenId8 = 8;

    uint256 transferTokenId1 = 10000;
    uint256 transferTokenId2 = 10001;

    uint256 snapshotId1 = 1;

    uint256 snapshotId;

    function bytesToHexString(
        bytes memory data
    ) public pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(2 + data.length * 2); // "0x" + 每个字节2个字符
        result[0] = "0";
        result[1] = "x";

        for (uint256 i = 0; i < data.length; i++) {
            result[2 + i * 2] = hexChars[uint8(data[i] >> 4)]; // 高4位
            result[3 + i * 2] = hexChars[uint8(data[i] & 0x0f)]; // 低4位
        }

        return string(result);
    }

    function printBytes(bytes memory data) public pure {
        console.log("data byte:", bytesToHexString(data));
    }

    function setUp() public {
        vm.startPrank(admin);
        // 部署mock合约
        avat = new ERC20Mock();
        avat.mint(admin, 10000000e18);
        avaV1 = new AVA_v1(
            name,
            symbol,
            decimals,
            baseURI,
            maxTotalValue,
            minTransferValue
        );

        // 部署实现合约
        AVA_Manager impl = new AVA_Manager();

        // 构造初始化数据
        bytes memory data = abi.encodeWithSelector(
            AVA_Manager.initialize.selector
        );

        printBytes(data);

        // 部署代理合约，指向实现合约
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);

        // 通过代理地址操作
        manager = AVA_Manager(address(proxy));

        vm.stopPrank();
        snapshotId = vm.snapshotState();
    }

    function testRole() public {
        // 检查管理员地址
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(avaV1.owner(), admin);

        vm.startPrank(admin);
        avaV1.transferOwnership(address(manager));
        assertEq(avaV1.owner(), address(manager));

        manager.grantRole(manager.DEFAULT_ADMIN_ROLE(), newAdmin);
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), newAdmin));

        manager.grantRole(manager.OPERATOR_ROLE(), user3);
        assertTrue(manager.hasRole(manager.OPERATOR_ROLE(), user3));

        manager.grantRole(manager.FINANCE_ROLE(), user4);
        assertTrue(manager.hasRole(manager.FINANCE_ROLE(), user4));

        manager.grantRole(manager.ADMIN_ROLE(), user5);
        assertTrue(manager.hasRole(manager.ADMIN_ROLE(), user5));

        manager.revokeRole(manager.OPERATOR_ROLE(), user3);
        assertFalse(manager.hasRole(manager.OPERATOR_ROLE(), user3));

        vm.stopPrank();

        vm.startPrank(newAdmin);

        manager.transferOwnership(address(avaV1), user1);
        assertEq(avaV1.owner(), user1);

        vm.stopPrank();

        vm.startPrank(user1);  // 非管理员
    
        // 测试各种角色权限
        vm.expectRevert();
        manager.setFundEnable(fundId1, false);
        
        vm.expectRevert();
        manager.setFairPrice(fundId1, 100e18, block.timestamp);
        
        vm.expectRevert();
        manager.registerFund(fundId1, address(avaV1), address(avat));
        
        vm.stopPrank();
        
        vm.revertToState(snapshotId);
    }

    function testWhitelist() public {
        vm.prank(admin);
        manager.setWhitelist(user1, true);
        assertTrue(manager.whitelist(user1));

        vm.prank(admin);
        manager.setWhitelist(user1, false);
        assertFalse(manager.whitelist(user1));

        vm.revertToState(snapshotId);
    }

    function testManagerUpgrade() public {
        vm.startPrank(admin);
        manager.setWhitelist(user1, true);
        assertTrue(manager.whitelist(user1));

        // 1. 部署新实现合约
        AVA_ManagerV2 newImpl = new AVA_ManagerV2();

        // 2. 用admin权限通过代理合约升级
        (bool ok, ) = address(manager).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl),
                ""
            )
        );
        require(ok, "upgradeTo failed");
        assertEq(ok, true);

        // 3. 验证原有数据未丢失
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(manager.whitelist(user1));

        // 4. 验证新功能可用
        // 需要用V2 ABI操作代理
        AVA_ManagerV2 managerV2 = AVA_ManagerV2(address(manager));
        managerV2.setNewFeatureFlag(42);
        assertEq(managerV2.newFeatureFlag(), 42);

        // 测试反向升级
        // 1. 部署新实现合约
        AVA_Manager newImpl2 = new AVA_Manager();

        // 2. 用admin权限通过代理合约升级
        (ok, ) = address(manager).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImpl2),
                ""
            )
        );
        require(ok, "upgradeTo failed");
        assertEq(ok, true);

        // 3. 验证原有数据未丢失
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(manager.whitelist(user1));

        // 4. 验证新功能不可用
        vm.expectRevert();
        managerV2.newFeatureFlag();

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testRegisterFund() public {
        vm.startPrank(admin);

        // 注册基金
        manager.registerFund(1, address(avaV1), address(avat));
        manager.setSubscribePeriod(
            fundId1,
            block.timestamp,
            block.timestamp + 1 days
        );

        // 检查基金信息
        (
            address logic,
            address erc20,
            uint256 subscribeStart,
            uint256 subscribeEnd,
            uint256 fairPrice,
            uint256 fairPriceTimestamp,
            uint256 unrealized,
            uint256 unrealizedTimestamp,
            uint256 fundSnapshotId,
            bool enabled
        ) = manager.funds(1);
        assertEq(logic, address(avaV1));
        assertEq(erc20, address(avat));
        assertEq(fairPrice, 0);
        assertEq(fairPriceTimestamp, 0);
        assertEq(unrealized, 100e18); // 默认未实现收益为100%
        assertEq(unrealizedTimestamp, block.timestamp);
        assertEq(fundSnapshotId, 0);
        assertEq(subscribeStart, block.timestamp);
        assertEq(subscribeEnd, block.timestamp + 1 days);
        assertEq(enabled, true);

        // 测试重复注册相同的基金编号
        vm.expectRevert();
        manager.registerFund(fundId1, address(avaV1), address(avat));

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function add9UsersToWhitelist() internal {
        // set admin account before calling this function
        manager.setWhitelist(admin, true);
        manager.setWhitelist(user1, true);
        manager.setWhitelist(user2, true);
        manager.setWhitelist(user3, true);
        manager.setWhitelist(user4, true);
        manager.setWhitelist(user5, true);
        manager.setWhitelist(user6, true);
        manager.setWhitelist(user7, true);
        manager.setWhitelist(user8, true);
    }

    function avat9Transfer() internal {
        // set admin account before calling this function
        avat.transfer(user1, 10 * minTransferValue);
        avat.transfer(user2, 10 * minTransferValue);
        avat.transfer(user3, 10 * minTransferValue);
        avat.transfer(user4, 10 * minTransferValue);
        avat.transfer(user5, 10 * minTransferValue);
        avat.transfer(user6, 10 * minTransferValue);
        avat.transfer(user7, 10 * minTransferValue);
        avat.transfer(user8, 10 * minTransferValue);
        avat.transfer(user9, 10 * minTransferValue);
    }

    function testSubscribeFundDisable() public {
        // 注册基金
        vm.startPrank(admin);
        regiserFund();
        manager.setFundEnable(fundId1, false);

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        // 基金被禁用，用户不能认购
        vm.startPrank(user1, user1);
        vm.expectRevert("Fund disabled");
        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testSubscribeNoKYC() public {
        // 注册基金
        vm.startPrank(admin);
        regiserFund();

        avat9Transfer();
        vm.stopPrank();

        // 无KYC用户认购
        vm.startPrank(user1, user1);
        vm.expectRevert("User not in whitelist");
        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testSubscribeTimeRange() public {
        // 注册基金
        vm.startPrank(admin);
        manager.registerFund(fundId1, address(avaV1), address(avat));
        vm.warp(100 days);
        manager.setSubscribePeriod(
            fundId1,
            block.timestamp,
            block.timestamp + 10 days
        );

        vm.warp(111 days);

        manager.registerFund(fundId2, address(avaV1), address(avat));
        manager.setSubscribePeriod(
            fundId2,
            block.timestamp + 1 days,
            block.timestamp + 2 days
        );

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        // 过期时间
        vm.startPrank(user1, user1);
        vm.expectRevert("Not in subscribe period");
        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        vm.expectRevert("Not in subscribe period");
        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId2),
                uint256(0)
            )
        );
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testSubscribeInvalidParameters() public {
        // 注册基金
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        // 构造无效的ERC20
        ERC20Mock invalidErc20 = new ERC20Mock();
        invalidErc20.mint(user1, 10000000e18);

        vm.stopPrank();

        // 基金被禁用，用户不能认购
        vm.startPrank(user1, user1);
        vm.expectRevert("Amount=0");
        avat.transfer(
            address(manager),
            0,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        vm.expectRevert("AVA: value must be a multiple of min transfer value");
        avat.transfer(
            address(manager),
            minTransferValue + 1e18,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        vm.expectRevert("Already subscribed");
        avat.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        (uint256 amount, bool approved, bool minted) = manager.getSubscription(
            fundId1,
            user1
        );
        assertEq(amount, minTransferValue);
        assertEq(approved, false);
        assertEq(minted, false);

        vm.expectRevert("ERC20 mismatch");
        invalidErc20.transfer(
            address(manager),
            minTransferValue,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function regiserFund() internal {
        // set avaV1 owner to manager
        avaV1.transferOwnership(address(manager));

        // set admin account before calling this function
        manager.registerFund(fundId1, address(avaV1), address(avat));
        manager.setSubscribePeriod(
            fundId1,
            block.timestamp,
            block.timestamp + 1 days
        );
    }

    function subscribe(address user, uint256 amount) internal {
        vm.startPrank(user, user);
        avat.transfer(
            address(manager),
            amount,
            abi.encode(
                uint8(BusinessType.Subscribe),
                uint256(fundId1),
                uint256(0)
            )
        );
        vm.stopPrank();
    }

    function subscribe8() internal {
        subscribe(user1, minTransferValue);
        subscribe(user2, 2 * minTransferValue);
        subscribe(user3, 3 * minTransferValue);
        subscribe(user4, 4 * minTransferValue);
        subscribe(user5, 2 * minTransferValue);
        subscribe(user6, 2 * minTransferValue);
        subscribe(user7, 3 * minTransferValue);
        subscribe(user8, 4 * minTransferValue);
    }

    function testSubscribeAndApprove() public {
        // 注册基金
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        // user5 申购前后 AVAT变化
        assertEq(avat.balanceOf(user5), 10 * minTransferValue);
        subscribe8();
        assertEq(avat.balanceOf(user5), 8 * minTransferValue);

        // 获得基金所有申购信息
        (
            address[] memory users,
            uint256[] memory amounts,
            bool[] memory approveds,
            bool[] memory minteds
        ) = manager.getFundSubscriptions(fundId1);

        assertEq(users.length, 8);
        assertEq(amounts[1], 2 * minTransferValue);
        assertEq(users[1], user2);
        approveds;
        minteds;

        // 管理员拒绝认购
        vm.startPrank(admin);

        manager.rejectSubscription(fundId1, user5);
        (uint256 amount, , ) = manager.getSubscription(fundId1, user5);
        assertEq(amount, 0);

        assertEq(avat.balanceOf(user5), 10 * minTransferValue);

        // 管理员批准认购
        vm.warp(2 days);
        manager.approveSubscription(fundId1, user1, tokenId1, slot1);
        manager.approveSubscription(fundId1, user2, tokenId2, slot1);
        manager.approveSubscription(fundId1, user3, tokenId3, slot1);

        assertEq(avaV1.balanceOf(user1), 1);
        assertEq(avaV1.totalSupply(), 3);

        // 已经发行的拒绝认购测试
        vm.expectRevert("Cannot reject after approval/minting");
        manager.rejectSubscription(fundId1, user2);

        // 已经发行的拒绝再次发行
        vm.expectRevert("No valid subscription");
        manager.approveSubscription(fundId1, user2, tokenId2, slot1);

        // 管理员提走ERC20
        uint256 balanceBefore = avat.balanceOf(admin);
        manager.withdrawERC20(address(avat), admin, 6 * minTransferValue);
        uint256 balanceAfter = avat.balanceOf(admin);
        assertEq(balanceAfter - balanceBefore, 6 * minTransferValue);

        // 测试最大转账金额
        vm.expectRevert();
        manager.withdrawERC20(address(avat), admin, type(uint256).max);

        vm.stopPrank();

        // 模拟用户错误转token到manager合约取回
        vm.startPrank(user1);
        avaV1.transferFrom(user1, address(manager), tokenId1);
        assertEq(avaV1.balanceOf(user1), 0);
        vm.stopPrank();

        vm.startPrank(admin);
        manager.withdrawERC721(address(avaV1), user1, tokenId1);
        assertEq(avaV1.balanceOf(user1), 1);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testExtraSubscribeAndApprove() public {
        // 模拟一个基金注册，申购，批准，拒绝，剩余部分管理员铸造
        // 确保法定的额度均被执行，管理员铸造部分用于二次销售，OTC协商

        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        subscribe8();

        vm.startPrank(admin);

        manager.rejectSubscription(fundId1, user5);

        // 管理员批准认购
        vm.warp(2 days);
        manager.approveSubscription(fundId1, user1, tokenId1, slot1);
        manager.approveSubscription(fundId1, user2, tokenId2, slot1);
        manager.approveSubscription(fundId1, user3, tokenId3, slot1);
        manager.approveSubscription(fundId1, user4, tokenId4, slot1);
        manager.approveSubscription(fundId1, user6, tokenId5, slot1);
        manager.approveSubscription(fundId1, user7, tokenId6, slot1);
        manager.approveSubscription(fundId1, user8, tokenId7, slot1);

        // 取消了 user5 的认购 20万，剩下的全部铸造后，还有10万额度
        assertEq(avaV1.maxTotalValue(), 20 * minTransferValue);
        assertEq(avaV1.currentTotalValue(), 19 * minTransferValue);
        assertEq(avaV1.totalSupply(), 7);

        // 管理员铸造剩余的10万额度
        manager.mintRemaining(
            tokenId1,
            user5,
            tokenId8,
            slot1,
            minTransferValue
        );
        assertEq(avaV1.currentTotalValue(), 2000000e18);
        assertEq(avaV1.totalSupply(), 8);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function testSetFairPrice() public {
        vm.startPrank(admin);

        vm.expectRevert("Fund not exists");
        manager.setFairPrice(fundId1, 101000e18, block.timestamp);

        regiserFund();
        (
            ,
            ,
            ,
            ,
            uint256 fairPrice,
            uint256 fairPriceTimestamp,
            ,
            ,
            ,

        ) = manager.getFundInfo(fundId1);
        assertEq(fairPrice, 0);
        assertEq(fairPriceTimestamp, 0);

        manager.setFairPrice(fundId1, 101000e18, block.timestamp);
        vm.stopPrank();

        (, , , , fairPrice, fairPriceTimestamp, , , , ) = manager.getFundInfo(
            fundId1
        );
        assertEq(fairPrice, 101000e18);

        vm.revertToState(snapshotId);
    }

    function testSetUnrealized() public {
        vm.startPrank(admin);
        vm.expectRevert("Fund not exists");
        manager.setUnrealized(fundId1, 61.8e18, block.timestamp);

        regiserFund();
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 unrealized,
            uint256 unrealizedTimestamp,
            ,

        ) = manager.getFundInfo(fundId1);
        assertEq(unrealized, 100e18);
        assertEq(unrealizedTimestamp, block.timestamp);

        vm.startPrank(admin);
        // 设置未实现收益 61.8%
        manager.setUnrealized(fundId1, 61.8e18, block.timestamp);

        (, , , , , , unrealized, unrealizedTimestamp, , ) = manager.getFundInfo(
            fundId1
        );
        assertEq(unrealized, 61.8e18);

        vm.expectRevert("Unrealized must be <= 100%");
        manager.setUnrealized(fundId1, 618e18, block.timestamp);

        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function mockSubscribe() internal {
        subscribe(user1, minTransferValue);
        subscribe(user2, 2 * minTransferValue);
        subscribe(user3, 3 * minTransferValue);
        subscribe(user4, 4 * minTransferValue);
        subscribe(user5, 5 * minTransferValue);
        subscribe(user6, 5 * minTransferValue);
    }

    function mockApproveSubscribe() internal {
        vm.warp(2 days);
        manager.approveSubscription(fundId1, user1, tokenId1, slot1);
        manager.approveSubscription(fundId1, user2, tokenId2, slot1);
        manager.approveSubscription(fundId1, user3, tokenId3, slot1);
        manager.approveSubscription(fundId1, user4, tokenId4, slot1);
        manager.approveSubscription(fundId1, user5, tokenId5, slot1);
        manager.approveSubscription(fundId1, user6, tokenId6, slot1);
    }

    function testSnapshot() public {
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        mockSubscribe();

        // 管理员批准认购
        vm.startPrank(admin);
        mockApproveSubscribe();
        vm.stopPrank();

        vm.startPrank(user5, user5);
        avaV1.transferFrom(tokenId5, user7, minTransferValue); // tokenId: 10000
        avaV1.transferFrom(tokenId5, tokenId1, minTransferValue); // tokenId: 1 的 value 2 * minTransferValue
        avaV1.transferFrom(tokenId5, user8, minTransferValue); // tokenId: 10001
        avaV1.transferFrom(user5, user8, tokenId5); // user5 没有资产了，user8 有两个token id 为 5, 10001
        vm.stopPrank();

        vm.startPrank(user6, user6);
        avaV1.transferFrom(user6, user8, tokenId6); // user6 没有资产了，user8 有3个token id 为 5, 6, 10001
        vm.stopPrank();

        assertEq(avaV1.currentTotalValue(), 20 * minTransferValue);
        assertEq(avaV1.balanceOf(user5), 0);
        assertEq(avaV1.balanceOf(user6), 0);
        assertEq(avaV1.balanceOf(user8), 3);
        assertEq(avaV1.balanceOf(transferTokenId1), minTransferValue);
        assertEq(avaV1.balanceOf(transferTokenId2), minTransferValue);
        assertEq(avaV1.balanceOf(tokenId1), 2 * minTransferValue);

        vm.startPrank(admin);
        manager.takeSnapshot(fundId1, snapshotId1);
        vm.expectRevert("snapshot exiset");
        manager.takeSnapshot(fundId1, 1);
        vm.stopPrank();

        (address[] memory holders, uint256[] memory balances) = manager
            .getSnapshot(fundId1, snapshotId1);
        uint256 user8Balance = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == user8) {
                user8Balance += balances[i];
            }
        }
        assertEq(user8Balance, 8 * minTransferValue);
        assertEq(holders.length, 8);

        vm.revertToState(snapshotId);
    }

    function testAirdrop() public {
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        mockSubscribe();

        // 管理员批准认购
        vm.startPrank(admin);
        mockApproveSubscribe();
        vm.stopPrank();

        vm.startPrank(user5, user5);
        avaV1.transferFrom(tokenId5, user7, minTransferValue); // tokenId: 10000
        avaV1.transferFrom(tokenId5, tokenId1, minTransferValue); // tokenId: 1 的 value 2 * minTransferValue
        avaV1.transferFrom(tokenId5, user8, minTransferValue); // tokenId: 10001
        avaV1.transferFrom(user5, user8, tokenId5); // user5 没有资产了，user8 有两个token id 为 5, 10001
        vm.stopPrank();

        vm.startPrank(user6, user6);
        avaV1.transferFrom(user6, user8, tokenId6); // user6 没有资产了，user8 有3个token id 为 5, 6, 10001
        vm.stopPrank();

        vm.startPrank(admin, admin);
        manager.takeSnapshot(fundId1, snapshotId1);
        avat.transfer(
            address(manager),
            5 * minTransferValue,
            abi.encode(
                uint8(BusinessType.Deposit),
                uint256(fundId1),
                uint256(0)
            )
        );

        uint256 avatBalanceBefore = avat.balanceOf(user8);
        
        vm.expectRevert("Amount must be greater than 0");
        manager.airdropDividend(
            fundId1,
            snapshotId1,
            address(avat),
            0
        );
        
        manager.airdropDividend(
            fundId1,
            snapshotId1,
            address(avat),
            5 * minTransferValue
        );
        uint256 avatBalanceAfter = avat.balanceOf(user8);

        assertEq(avatBalanceAfter - avatBalanceBefore, 2 * minTransferValue);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testAirdropOutOfChain() public {
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        mockSubscribe();

        // 管理员批准认购
        vm.startPrank(admin);
        mockApproveSubscribe();
        vm.stopPrank();

        vm.startPrank(user5, user5);
        avaV1.transferFrom(tokenId5, user7, minTransferValue); // tokenId: 10000
        avaV1.transferFrom(tokenId5, tokenId1, minTransferValue); // tokenId: 1 的 value 2 * minTransferValue
        avaV1.transferFrom(tokenId5, user8, minTransferValue); // tokenId: 10001
        avaV1.transferFrom(user5, user8, tokenId5); // user5 没有资产了，user8 有两个token id 为 5, 10001
        vm.stopPrank();

        vm.startPrank(user6, user6);
        avaV1.transferFrom(user6, user8, tokenId6); // user6 没有资产了，user8 有3个token id 为 5, 6, 10001
        vm.stopPrank();

        // 构造批量转账空投清单
        address[] memory holders = new address[](6);
        uint256[] memory balances = new uint256[](6);
        holders[0] = user1;
        balances[0] = (50 * minTransferValue) / 100;
        holders[1] = user2;
        balances[1] = (50 * minTransferValue) / 100;
        holders[2] = user3;
        balances[2] = (75 * minTransferValue) / 100;
        holders[3] = user4;
        balances[3] = minTransferValue;
        holders[4] = user8;
        balances[4] = 2 * minTransferValue;
        holders[5] = user7;
        balances[5] = (25 * minTransferValue) / 100;

        vm.startPrank(admin, admin);
        avat.transfer(
            address(manager),
            5 * minTransferValue,
            abi.encode(
                uint8(BusinessType.Deposit),
                uint256(fundId1),
                uint256(0)
            )
        );
        uint256 avatBalanceBefore = avat.balanceOf(user8);
        manager.airdropDividend(fundId1, address(avat), holders, balances);
        uint256 avatBalanceAfter = avat.balanceOf(user8);

        assertEq(avatBalanceAfter - avatBalanceBefore, 2 * minTransferValue);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function registerSubscribApprove() internal {
        // 注册基金
        vm.startPrank(admin);
        regiserFund();

        add9UsersToWhitelist();
        avat9Transfer();

        vm.stopPrank();

        mockSubscribe();

        vm.startPrank(admin);
        mockApproveSubscribe();
        vm.stopPrank();
    }

    function testPlaceSellOrderAndCancelOrder() public {
        registerSubscribApprove();
        uint256 amount = minTransferValue;
        uint256 totalValue = (11 * minTransferValue) / 10;

        vm.startPrank(user9, user9);
        vm.expectRevert("Not in whitelist");
        uint256 orderId = manager.placeSellOrder(
            fundId1,
            tokenId1,
            amount,
            totalValue
        );
        vm.stopPrank();

        // user1 挂单
        vm.startPrank(user1, user1);
        vm.expectRevert("Fund not exists");
        orderId = manager.placeSellOrder(fundId2, tokenId1, amount, totalValue);

        vm.expectRevert("Not token owner");
        orderId = manager.placeSellOrder(fundId1, tokenId2, amount, totalValue);

        vm.expectRevert("Token not approved");
        orderId = manager.placeSellOrder(fundId1, tokenId1, amount, totalValue);

        // user1 授权manager
        avaV1.approve(address(manager), tokenId1);
        orderId = manager.placeSellOrder(fundId1, tokenId1, amount, totalValue);
        assertEq(orderId, 0);

        vm.expectRevert("Token already on sale");
        orderId = manager.placeSellOrder(fundId1, tokenId1, amount, totalValue);
        vm.stopPrank();

        // 获取成功的订单信息
        uint256 nextOrderId = manager.nextOrderId();
        (
            address _user,
            uint256 _fundId,
            uint256 _tokenId,
            uint256 _amount,
            uint256 _totalValue,
            bool _isSell,
            bool _isActive
        ) = manager.orders(nextOrderId - 1);
        assertEq(_user, user1);
        assertEq(_fundId, fundId1);
        assertEq(_tokenId, tokenId1);
        assertEq(_amount, amount);
        assertEq(_totalValue, totalValue);
        assertTrue(_isSell);
        assertTrue(_isActive);

        // 取消订单
        vm.expectRevert("Not order owner");
        manager.cancelOrder(orderId);
        vm.startPrank(user1, user1);
        manager.cancelOrder(orderId);
        (, , , , , , bool isActive) = manager.orders(orderId);
        assertFalse(isActive);

        vm.expectRevert("Order inactive");
        manager.cancelOrder(orderId);
        vm.stopPrank();
        vm.revertToState(snapshotId);
    }

    function make3Orders() internal returns (uint256, uint256, uint256) {
        registerSubscribApprove();
        uint256 amount = minTransferValue;
        uint256 totalValue = 110000e18;

        // user1 挂单
        vm.startPrank(user1, user1);
        avaV1.approve(address(manager), tokenId1);
        uint256 orderId = manager.placeSellOrder(
            fundId1,
            tokenId1,
            amount,
            totalValue
        );
        vm.stopPrank();

        // user2 挂单
        vm.startPrank(user2, user2);
        uint256 amount2 = minTransferValue;
        uint256 totalValue2 = 111000e18;
        avaV1.approve(address(manager), tokenId2);
        uint256 orderId2 = manager.placeSellOrder(
            fundId1,
            tokenId2,
            amount2,
            totalValue2
        );
        vm.stopPrank();

        // user3 挂单
        vm.startPrank(user3, user3);
        uint256 amount3 = minTransferValue;
        uint256 totalValue3 = 111100e18;
        avaV1.approve(address(manager), tokenId3);
        uint256 orderId3 = manager.placeSellOrder(
            fundId1,
            tokenId3,
            amount3,
            totalValue3
        );
        vm.stopPrank();

        return (orderId, orderId2, orderId3);
    }

    function testSellOrderMatch() public {
        (uint256 orderId, uint256 orderId2, uint256 orderId3) = make3Orders();
        assertEq(orderId, 0);
        assertEq(orderId2, 1);
        assertEq(orderId3, 2);

        // 取消订单
        vm.startPrank(user2, user2);
        manager.cancelOrder(orderId2);
        vm.stopPrank();

        // user4 买入 orderId
        vm.startPrank(user4, user4);
        uint256 user4Erc20BalanceBefore = avat.balanceOf(user4);
        uint256 user1Erc20BalanceBefore = avat.balanceOf(user1);
        uint256 user4AvaV1BalanceBefore = avaV1.balanceOf(user4);

        avat.transfer(
            address(manager),
            110000e18,
            abi.encode(
                uint8(BusinessType.BuyOrder),
                uint256(orderId),
                uint256(0)
            )
        );
        uint256 user4Erc20BalanceAfter = avat.balanceOf(user4);
        uint256 user1Erc20BalanceAfter = avat.balanceOf(user1);
        uint256 user4AvaV1BalanceAfter = avaV1.balanceOf(user4);

        assertEq(user1Erc20BalanceAfter - user1Erc20BalanceBefore, 110000e18);
        assertEq(user4Erc20BalanceBefore - user4Erc20BalanceAfter, 110000e18);
        assertEq(user4AvaV1BalanceAfter - user4AvaV1BalanceBefore, 1);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testPlaceBuyOrderAndCancelOrder() public {
        registerSubscribApprove();
        uint256 amount = minTransferValue;
        uint256 totalValue = 110000e18;

        vm.startPrank(user9, user9);
        vm.expectRevert("User not in whitelist");
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId2),
                uint256(amount)
            )
        );
        vm.stopPrank();

        // user1 挂单
        vm.startPrank(user1, user1);
        vm.expectRevert("Fund not exists");
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId2),
                uint256(amount)
            )
        );

        vm.expectRevert("Amount must be greater than 0");
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId1),
                uint256(0)
            )
        );

        vm.expectRevert("AVA: value must be a multiple of min transfer value");
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId1),
                uint256(amount + 1)
            )
        );

        vm.expectRevert("Total value must be greater than 0");
        avat.transfer(
            address(manager),
            0,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId1),
                uint256(amount)
            )
        );

        uint256 orderId = manager.nextOrderId();
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId1),
                uint256(amount)
            )
        );
        uint256 _orderId = manager.nextOrderId();
        assertEq(_orderId, orderId + 1);

        vm.stopPrank();

        // 获取成功的订单信息
        (
            address _user,
            uint256 _fundId,
            uint256 _tokenId,
            uint256 _amount,
            uint256 _totalValue,
            bool _isSell,
            bool _isActive
        ) = manager.orders(orderId);
        assertEq(_user, user1);
        assertEq(_fundId, fundId1);
        assertEq(_tokenId, 0);
        assertEq(_amount, amount);
        assertEq(_totalValue, totalValue);
        assertTrue(!_isSell);
        assertTrue(_isActive);

        // 取消订单
        vm.expectRevert("Not order owner");
        manager.cancelOrder(orderId);

        vm.startPrank(user1, user1);
        uint256 balanceBefore = avat.balanceOf(user1);
        manager.cancelOrder(orderId);
        uint256 balanceAfter = avat.balanceOf(user1);
        (, , , , , , bool isActive) = manager.orders(orderId);
        assertFalse(isActive);
        assertEq(balanceAfter - balanceBefore, totalValue);

        vm.expectRevert("Order inactive");
        manager.cancelOrder(orderId);
        vm.stopPrank();

        vm.revertToState(snapshotId);
    }

    function testBuyOrderAndMatch() public {
        registerSubscribApprove();
        uint256 amount = minTransferValue;
        uint256 totalValue = 110000e18;

        // user1 挂单
        vm.startPrank(user1, user1);

        uint256 orderId = manager.nextOrderId();
        avat.transfer(
            address(manager),
            totalValue,
            abi.encode(
                uint8(BusinessType.PlaceBuyOrder),
                uint256(fundId1),
                uint256(amount)
            )
        );

        vm.stopPrank();

        vm.startPrank(user2, user2);

        avaV1.approve(address(manager), tokenId2);
        uint256 _balanceBefore = avaV1.balanceOf(tokenId2);

        manager.sellOrder(fundId1, orderId, tokenId2);

        uint256 _balanceAfter = avaV1.balanceOf(tokenId2);
        assertEq(_balanceBefore - _balanceAfter, minTransferValue);

        vm.stopPrank();

        vm.revertToState(snapshotId);
    }
}

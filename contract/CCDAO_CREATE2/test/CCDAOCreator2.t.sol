// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CCDAOCreator2.sol";

contract Counter {
    uint256 public count;
    
    constructor() payable {}
    
    function increment() external {
        count++;
    }
}

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    
    constructor() {
        balanceOf[msg.sender] = 1000 * 10**18;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MockERC721 {
    mapping(uint256 => address) public ownerOf;
    
    function mint(address to, uint256 tokenId) external {
        ownerOf[tokenId] = to;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == from, "Not owner");
        ownerOf[tokenId] = to;
        
        // Call receiver hook if it's a contract
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "") {
                // Success
            } catch {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4);
}

/**
 * Incomplete ERC721 implementation - doesn't check if receiver implements onERC721Received
 * This simulates a buggy or non-standard ERC721 that doesn't properly validate receivers
 */
contract IncompleteERC721 {
    mapping(uint256 => address) public ownerOf;
    
    function mint(address to, uint256 tokenId) external {
        ownerOf[tokenId] = to;
    }
    
    /**
     * Non-standard safeTransferFrom that doesn't check receiver hook
     * This is the vulnerability: it bypasses onERC721Received validation
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == from, "Not owner");
        // VULNERABLE: No check for onERC721Received hook!
        // This means it can transfer to any address, including contracts that don't implement the hook
        ownerOf[tokenId] = to;
    }
    
    /**
     * Standard transferFrom - needed for withdrawal
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == from, "Not owner");
        ownerOf[tokenId] = to;
    }
}

contract CCDAOCreator2Test is Test {
    CCDAOCreator2 deployer;
    MockERC20 mockERC20;
    MockERC721 mockERC721;
    IncompleteERC721 incompleteERC721;
    
    function setUp() public {
        deployer = new CCDAOCreator2();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        incompleteERC721 = new IncompleteERC721();
    }
    
    /**
     * Test deploying a simple contract that stores a value
     */
    function test_DeploySimpleContract() public {
        // Get the creation bytecode for Counter
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("test-salt-1"));
        
        // Deploy the contract
        address deployedAddress = deployer.deploy(bytecode, salt);
        
        // Verify the contract is deployed (has code)
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(deployedAddress)
        }
        assertGt(codeSize, 0, "Deployed contract should have code");
        
        // Verify we can call it
        Counter deployed = Counter(deployedAddress);
        assertEq(deployed.count(), 0);
    }
    
    /**
     * Test that different salts produce different addresses
     */
    function test_DifferentSaltsDifferentAddresses() public {
        bytes memory bytecode = type(Counter).creationCode;
        
        bytes32 salt1 = keccak256(abi.encodePacked("salt-1"));
        bytes32 salt2 = keccak256(abi.encodePacked("salt-2"));
        
        address addr1 = deployer.deploy(bytecode, salt1);
        address addr2 = deployer.deploy(bytecode, salt2);
        
        assertNotEq(addr1, addr2, "Different salts should produce different addresses");
    }
    
    /**
     * Test predictAddress function
     */
    function test_PredictAddressAccuracy() public {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("prediction-test"));
        bytes32 bytecodeHash = keccak256(bytecode);
        
        // Predict before deployment
        address predictedAddr = deployer.predictAddress(salt, bytecodeHash);
        
        // Deploy and verify
        address actualAddr = deployer.deploy(bytecode, salt);
        
        assertEq(actualAddr, predictedAddr, "Predicted address should match actual deployment address");
    }
    
    /**
     * Test deploying with value transfer
     */
    function test_DeployWithValue() public {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("value-test"));
        
        uint256 valueToSend = 1 ether;
        vm.deal(address(this), valueToSend);
        
        address deployedAddr = deployer.deploy{value: valueToSend}(bytecode, salt);
        
        assertEq(deployedAddr.balance, valueToSend, "Deployed contract should have received the value");
    }
    
    /**
     * Test that ETH transfers to the contract are rejected
     */
    function test_RejectETHTransfer() public {
        uint256 ethToSend = 1 ether;
        vm.deal(address(this), ethToSend);
        
        // Verify deployer has no ETH initially
        assertEq(address(deployer).balance, 0, "Deployer should start with 0 ETH");
        
        // Try to send ETH to deployer - should revert
        (bool success, ) = payable(address(deployer)).call{value: ethToSend}("");
        assertFalse(success, "ETH transfer should be rejected");
        
        // Verify deployer still has no ETH
        assertEq(address(deployer).balance, 0, "Deployer should still have 0 ETH after failed transfer");
    }
    
    /**
     * Test that ERC20 transfers to the contract are accepted and can be withdrawn
     */
    function test_WithdrawERC20() public {
        uint256 transferAmount = 100 * 10**18;
        uint256 initialBalance = mockERC20.balanceOf(address(this));
        
        // Verify deployer has no tokens initially
        assertEq(mockERC20.balanceOf(address(deployer)), 0, "Deployer should start with 0 tokens");
        
        // Transfer tokens to deployer (ERC20 has no receiver hook, so it succeeds)
        mockERC20.transfer(address(deployer), transferAmount);
        assertEq(mockERC20.balanceOf(address(deployer)), transferAmount, "Tokens should be in deployer");
        
        // Withdraw as owner
        deployer.withdrawERC20(address(mockERC20));
        
        // Verify deployer now has 0 tokens and test contract got them back
        assertEq(mockERC20.balanceOf(address(deployer)), 0, "Deployer should have 0 tokens after withdrawal");
        assertEq(mockERC20.balanceOf(address(this)), initialBalance, "Test contract should get all tokens back");
    }
    
    /**
     * Test that ERC721 transfers to the contract are rejected (standard implementation)
     */
    function test_RejectERC721Transfer() public {
        uint256 tokenId = 42;
        
        // Mint NFT to test contract
        mockERC721.mint(address(this), tokenId);
        assertEq(mockERC721.ownerOf(tokenId), address(this), "Test should own the NFT");
        
        // Try to transfer NFT to deployer - should revert
        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        mockERC721.safeTransferFrom(address(this), address(deployer), tokenId);
        
        // Verify NFT is still with test contract
        assertEq(mockERC721.ownerOf(tokenId), address(this), "Test should still own the NFT after failed transfer");
    }
    
    /**
     * Test that incomplete ERC721 implementations bypass the hook and require withdrawERC721
     * This simulates a real-world vulnerability where buggy ERC721 contracts don't check onERC721Received
     */
    function test_WithdrawIncompleteERC721() public {
        uint256 tokenId = 99;
        
        // Mint NFT from incomplete implementation
        incompleteERC721.mint(address(this), tokenId);
        assertEq(incompleteERC721.ownerOf(tokenId), address(this), "Test should own the incomplete ERC721 NFT");
        
        // Transfer using the incomplete ERC721 (no hook check!)
        // This succeeds despite deployer not implementing onERC721Received
        incompleteERC721.safeTransferFrom(address(this), address(deployer), tokenId);
        assertEq(incompleteERC721.ownerOf(tokenId), address(deployer), "Incomplete ERC721 allows unsafe transfer");
        
        // Now deployer must have withdrawERC721 to recover the NFT
        deployer.withdrawERC721(address(incompleteERC721), tokenId);
        
        // Verify NFT is returned to owner
        assertEq(incompleteERC721.ownerOf(tokenId), address(this), "Owner should recover the NFT");
    }
    
    /**
     * Test that ownership can be transferred to a new address
     */
    function test_TransferOwnership() public {
        address newOwner = address(0x1234567890123456789012345678901234567890);
        
        // Verify current owner
        assertEq(deployer.owner(), address(this), "Test contract should be owner");
        
        // Transfer ownership
        deployer.transferOwnership(newOwner);
        
        // Verify new owner
        assertEq(deployer.owner(), newOwner, "New address should be owner");
    }
    
    /**
     * Test that only owner can transfer ownership
     */
    function test_TransferOwnershipOnlyOwner() public {
        address attacker = address(0xDEAD);
        address newOwner = address(0x1234);
        
        // Try to transfer ownership as non-owner - should revert
        vm.prank(attacker);
        vm.expectRevert("Only owner can call this function");
        deployer.transferOwnership(newOwner);
        
        // Verify owner hasn't changed
        assertEq(deployer.owner(), address(this), "Owner should remain unchanged");
    }
    
    /**
     * Test that ownership cannot be transferred to zero address
     */
    function test_TransferOwnershipZeroAddress() public {
        // Try to transfer to zero address - should revert
        vm.expectRevert("New owner cannot be zero address");
        deployer.transferOwnership(address(0));
        
        // Verify owner hasn't changed
        assertEq(deployer.owner(), address(this), "Owner should remain unchanged");
    }
    
    /**
     * Test that ownership cannot be transferred to the same address
     */
    function test_TransferOwnershipSameAddress() public {
        // Try to transfer to current owner - should revert
        vm.expectRevert("New owner is the same as current owner");
        deployer.transferOwnership(address(this));
        
        // Verify owner is still the same
        assertEq(deployer.owner(), address(this), "Owner should remain unchanged");
    }
    
    /**
     * Test that new owner can call owner-only functions
     */
    function test_NewOwnerCanCallOwnerFunctions() public {
        address newOwner = address(0x1234);
        
        // Transfer ownership
        deployer.transferOwnership(newOwner);
        
        // Create mock ERC20 and send tokens to deployer
        MockERC20 mockERC20 = new MockERC20();
        uint256 transferAmount = 100 * 10**18;
        mockERC20.transfer(address(deployer), transferAmount);
        
        // New owner should be able to withdraw
        vm.prank(newOwner);
        deployer.withdrawERC20(address(mockERC20));
        
        // Verify tokens were withdrawn
        assertEq(mockERC20.balanceOf(address(deployer)), 0, "Tokens should be withdrawn");
        assertEq(mockERC20.balanceOf(newOwner), transferAmount, "New owner should receive tokens");
    }
    
    /**
     * Test that old owner cannot call owner-only functions after transfer
     */
    function test_OldOwnerCannotCallOwnerFunctionsAfterTransfer() public {
        address newOwner = address(0x1234);
        
        // Transfer ownership
        deployer.transferOwnership(newOwner);
        
        // Create mock ERC20 and send tokens to deployer
        MockERC20 mockERC20 = new MockERC20();
        uint256 transferAmount = 100 * 10**18;
        mockERC20.transfer(address(deployer), transferAmount);
        
        // Old owner should NOT be able to withdraw
        vm.expectRevert("Only owner can call this function");
        deployer.withdrawERC20(address(mockERC20));
    }
    
    /**
     * Test renouncing ownership
     */
    function test_RenounceOwnership() public {
        // Verify current owner
        assertEq(deployer.owner(), address(this), "Test contract should be owner");
        
        // Renounce ownership
        deployer.renounceOwnership();
        
        // Verify ownership is renounced (zero address)
        assertEq(deployer.owner(), address(0), "Owner should be zero address after renounce");
    }
    
    /**
     * Test that no one can call owner functions after renouncing
     */
    function test_OwnerFunctionsBlockedAfterRenounce() public {
        // Renounce ownership
        deployer.renounceOwnership();
        
        // Try to withdraw - should revert
        vm.expectRevert("Only owner can call this function");
        deployer.withdrawERC20(address(0x1234));
    }
}

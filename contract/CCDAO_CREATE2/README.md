# CCDAOCreator2 - CREATE2 Deterministic Deployment with Asset Recovery

A production-grade Solidity contract that leverages the CREATE2 opcode for deterministic contract deployment with comprehensive mechanisms to recover accidentally transferred tokens.

## Overview

CCDAOCreator2 enables predictable contract deployment at specific addresses while providing practical defenses against accidental token transfers. This is particularly useful for factory patterns, cross-chain deployments, and decentralized autonomous organization (DAO) infrastructure where deployment addresses must be known in advance.

## Key Features

### Core Deployment Features
- **Deterministic Deployment**: Deploy contracts at predictable addresses using CREATE2 opcode
- **Address Prediction**: Calculate deployment addresses before actually deploying contracts
- **ETH Support**: Forward ETH during contract deployment for initialization
- **Flexible Bytecode**: Deploy any valid contract bytecode

### Asset Protection Features
- **ETH Rejection**: Automatically rejects all incoming ETH transfers via fallback
- **ERC721 Defense**: Rejects standard ERC721 tokens via `onERC721Received` hook; provides recovery for non-compliant implementations
- **ERC20 Recovery**: Provides owner-controlled withdrawal mechanism for ERC20 tokens (cannot be rejected due to lack of receiver hook)

## Contract Functions

### Deployment Functions

#### `deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address)`

Deploys a contract with deterministic address calculation using CREATE2.

**Parameters:**
- `bytecode`: The runtime bytecode of the contract to deploy
- `salt`: Unique bytes32 value determining the deployment address

**Returns:**
- The address of the newly deployed contract

**Gas Usage:** ~45,000 (base) + deployment overhead

**Example:**
```solidity
bytes memory bytecode = type(MyContract).creationCode;
bytes32 salt = keccak256(abi.encodePacked("unique-salt-123"));
address deployed = creator.deploy(bytecode, salt);
```

#### `predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address)`

Calculates where a contract will be deployed without performing the deployment.

**Parameters:**
- `salt`: The same salt value used for `deploy()`
- `bytecodeHash`: `keccak256(bytecode)` of the contract to deploy

**Returns:**
- The deterministic address where the contract will be deployed

**Gas Usage:** ~200 (view function)

**Example:**
```solidity
bytes memory bytecode = type(MyContract).creationCode;
bytes32 bytecodeHash = keccak256(bytecode);
bytes32 salt = keccak256(abi.encodePacked("unique-salt-123"));
address predictedAddr = creator.predictAddress(salt, bytecodeHash);

// Later, deploying at the predicted address:
address actualAddr = creator.deploy(bytecode, salt);
assert(actualAddr == predictedAddr); // Always true
```

### Asset Recovery Functions

#### `withdrawERC20(address token) external onlyOwner`

Recovers ERC20 tokens accidentally transferred to this contract.

**Parameters:**
- `token`: The ERC20 token contract address

**Access:** Owner only

**Requirements:**
- Contract must have positive token balance
- Token transfer must succeed (implemented correctly)

**Gas Usage:** ~50,000

**Rationale:** ERC20 lacks a receiver hook, making it impossible to reject transfers. This function provides recovery.

**Example:**
```solidity
// Owner recovers accidentally sent USDC
creator.withdrawERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
```

#### `withdrawERC721(address token, uint256 tokenId) external onlyOwner`

Recovers ERC721 NFTs from the contract.

**Parameters:**
- `token`: The ERC721 token contract address
- `tokenId`: The ID of the token to withdraw

**Access:** Owner only

**Requirements:**
- Contract must own the specified token
- Token transfer must succeed

**Gas Usage:** ~60,000

**Rationale:** Standard ERC721s reject transfers via `onERC721Received`, but non-compliant implementations may bypass this. This function handles edge cases.

**Example:**
```solidity
// Owner recovers an accidentally sent NFT
creator.withdrawERC721(0x1234567890123456789012345678901234567890, 42);
```

### Rejection Functions

#### `onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4)`

Implements the ERC721 receiver hook to reject standard ERC721 transfers.

**Behavior:** Reverts with message "CCDAOCreator2: ERC721 tokens not accepted"

**Automatic:** Called automatically when a standard ERC721 contract attempts to transfer tokens to this address.

#### `fallback() external`

Catches all ETH transfers and rejects them.

**Behavior:** Reverts with message "CCDAOCreator2: ETH not accepted"

**Automatic:** Called automatically when this contract receives ETH with no matching function selector.

## How CREATE2 Works

CREATE2 calculates deployment addresses deterministically using:

```
address = keccak256(0xff ++ deployerAddress ++ salt ++ keccak256(bytecode))
```

Where:
- `0xff`: CREATE2 opcode prefix
- `deployerAddress`: This contract's address
- `salt`: User-provided unique identifier
- `keccak256(bytecode)`: Hash of the contract bytecode

### Implications

1. **Address is predictable**: Know the address before deploying
2. **Address is unique per bytecode**: Different bytecodes at different addresses with same salt
3. **Salt collision safety**: Redeploying with same salt fails (address already has code)
4. **Cross-chain consistency**: Same salt + bytecode = same address on all EVM chains

## Design Decisions

### Why Reject ETH?
ETH transfers via fallback cannot be recovered by normal mechanisms. Rejecting is safest.

### Why Reject Standard ERC721?
Standard ERC721s implement the receiver hook check. Rejecting at this point prevents accidental locks.

### Why Accept ERC20 + Provide Recovery?
ERC20 lacks receiver hook—cannot be rejected. Providing owner-controlled withdrawal is the only practical solution.

### Why Provide ERC721 Recovery?
Real-world ERC721 implementations sometimes skip the receiver hook check. This handles non-compliant contracts gracefully.

## Asset Handling Matrix

| Asset Type | Incoming Transfer | Recovery Function |
|----------|------------------|-------------------|
| ETH | ❌ Rejected (fallback revert) | N/A |
| ERC20 | ✅ Accepted (no hook to prevent) | `withdrawERC20()` |
| ERC721 (Standard) | ❌ Rejected (onERC721Received revert) | N/A |
| ERC721 (Non-compliant) | ✅ Accepted (no hook check) | `withdrawERC721()` |

## Testing

The contract includes comprehensive test coverage:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -v

# Run specific test
forge test --match test_DeploySimpleContract
```

### Test Coverage

- ✅ **Deployment Tests**: Contract deployment, salt differentiation, address prediction accuracy
- ✅ **Asset Rejection Tests**: ETH rejection, standard ERC721 rejection
- ✅ **Asset Recovery Tests**: ERC20 recovery, incomplete ERC721 recovery
- ✅ **Total**: 8 comprehensive tests, all passing

## Use Cases

1. **Factory Contracts**: Deploy instances of contracts at predictable addresses
2. **Cross-chain Deployment**: Deploy contracts at identical addresses on multiple EVM chains
3. **DAO Infrastructure**: Create DAO treasuries/contracts at predetermined addresses
4. **Deterministic Initialization**: Pre-calculate contract addresses for off-chain systems
5. **Vanity Addresses**: Iterate salts to find addresses matching specific patterns
6. **Multi-sig Wallets**: Create accounts at deterministic addresses for security
7. **Governance Contracts**: Deploy governance contracts at known, immutable addresses

## Security Considerations

### What This Contract Protects Against
- ✅ Accidental ETH transfers (rejected via fallback)
- ✅ Standard ERC721 transfers (rejected via receiver hook)
- ✅ Accidental ERC20 transfers (recoverable via owner withdrawal)
- ✅ Incomplete ERC721 implementations (recoverable via owner withdrawal)

### Best Practices
1. **Salt Management**: Use unique, high-entropy salts to prevent collisions
2. **Bytecode Validation**: Verify bytecode before deployment
3. **Owner Security**: Protect the owner key with multi-sig or timelock mechanisms
4. **Address Prediction**: Always verify `predictAddress()` matches actual deployment
5. **Testing**: Test deployment on testnet before mainnet deployment

## Configuration

The contract is optimized for production deployment with Foundry settings:
```toml
optimizer_runs = 10000
```

This balances deployment costs with execution efficiency.

## Deployment

Deploy the contract:
```bash
forge script script/CCDAOCreator2.s.sol --rpc-url $RPC_URL --broadcast
```

## State Variables

### `address public owner`

The owner of this contract, authorized to call recovery functions.

## Modifiers

### `onlyOwner()`

Restricts function access to the contract owner.

## Deployment info

* ETH: 0x7cdcb326766541a82b2ec8c870747c780575eaee
* POLYGON: 0x358f2714b5b18938Fc146dD03D4fcC92666ecDC3
* ARB: 0xB416FdED89132B6c42BE4A32d5dF87Cc7DDD08d0
* BSC: 0xD13A52A139D74cbBAe4077CdfCa6F9edBa32B6dc
* BASE: 0x135a4Fa91E982080001633c8F68c6b1C66d22ca9

## License

MIT

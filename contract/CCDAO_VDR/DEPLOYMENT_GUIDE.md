# VDR Cross-Chain Deterministic Deployment Guide

## Overview

This guide documents the three-stage deployment architecture for VDR contracts with cross-chain address determinism using the CCDAO_CREATE2 factory.

> **Updated:** Now implements deterministic VDR instance proxy addresses based on DAO name
>
> **Key Change:** Instance proxies now use CREATE2 with DAO-name-based salt for cross-chain consistency

## Architecture Design

### Problem Statement
In a multi-chain environment, we need:
1. **Consistent addresses across chains** for the main entry point (VDRFactory Proxy)
2. **Consistent addresses per DAO** for VDR instance proxies across chains
3. **Flexible version management** allowing each organization to upgrade independently

### Solution: Hybrid CREATE2 Approach

```
STAGE 1: Foundation
├─ CCDAO_CREATE2 Factory
│  ├─ Opcode: CREATE2
│  ├─ Address: Deterministic (fixed salt per network)
│  └─ Role: Universal factory for all deterministic deploys

STAGE 2: VDR Infrastructure
├─ VDR Implementation (random address)
│  └─ Each org can upgrade independently
├─ VDRFactory Implementation (random address)
│  └─ Stores CCDAO_CREATE2 reference
└─ VDRFactory Proxy (CREATE2, fixed salt)
   └─ Stable business entry point across all chains

STAGE 3: VDR Instance Creation
└─ VDR Instance Proxy (CREATE2, DAO-name-based salt)
   ├─ Salt: keccak256(abi.encodePacked(daoName))
   ├─ Deterministic per DAO name
   └─ Same address across all networks
```

## Deployment Steps

### Stage 1: Deploy CCDAO_CREATE2 (One-time per network)

```bash
# See CCDAO_CREATE2 repository for deployment instructions
export CCDAO_CREATE2=0x...  # Save this address
```

### Stage 2: Deploy VDR Infrastructure

```bash
# Set environment variables
export PRIVATE_KEY=0x...
export CCDAO_CREATE2=0x...

# Run deployment script
cd contract/CCDAO_VDR
forge script script/VDR_Deploy_Initial.s.sol:VDRDeployInitial \
  --rpc-url $RPC_URL \
  --broadcast

# Output:
# - VDR Implementation (random): 0x...
# - VDRFactory Implementation (random): 0x...
# - VDRFactory Proxy (CREATE2 fixed): 0x...

# Save for next stage:
export VDRF_FACTORY_PROXY=0x...
```

### Stage 3: Create VDR Instances

```bash
# Each DAO organization creates deterministic instance
vdrFactoryProxy.createVDR(
  "My Organization DAO",  // Same name = same address everywhere
  ownerAddress,
  [dataManager1, dataManager2]
)

# Result: Deterministic address based on DAO name
# - Valid on all networks where CCDAO_CREATE2 exists
# - Same address when created with same name
```

## Cross-Chain Consistency

### Example: Address Calculation

For DAO named "Acme Corp":

```
Salt = keccak256("Acme Corp")
Address = CREATE2(
  factory: CCDAO_CREATE2,
  salt: above,
  bytecode: ERC1967Proxy + init data
)
```

**Result:** Same address on Ethereum, Polygon, Arbitrum, etc.

## Key Design Principles

| Component | Address | Why |
|-----------|---------|-----|
| CCDAO_CREATE2 | Fixed (CREATE2) | One factory per network |
| VDR Implementation | Random (new) | Org-independent upgrades |
| VDRFactory Proxy | Deterministic (CREATE2) | Stable entry point |
| VDR Instance Proxy | Deterministic (CREATE2) | Cross-chain consistency |

## Configuration

## Environment Variables

```bash
# Required for all stages
export PRIVATE_KEY=0x...
export RPC_URL=http://localhost:8545  # or any network

# Stage 1 output (save this!)
export CCDAO_CREATE2=0x...

# Stage 2 output (save this!)
export VDRF_FACTORY_PROXY=0x...
```

## Upgrade Paths

### Upgrade VDR Implementation (Org-specific)

```bash
export VDRF_FACTORY_PROXY=0x...
export PRIVATE_KEY=0x...

# Deploy new implementation (random address)
forge script script/VDR_Upgrade.s.sol:VDRUpgrade \
  --rpc-url $RPC_URL \
  --broadcast

# Only affects this factory instance
# Other organizations unaffected
```

## Testing

### Local Development

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
export CCDAO_CREATE2=0x5FbDB2315678afccb333f8a9c45b65d30c01f173
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb476c6b8d6c1f02fb26c3a0135d01

cd contract/CCDAO_VDR
forge script script/VDR_Deploy_Initial.s.sol:VDRDeployInitial \
  --rpc-url http://localhost:8545 \
  --broadcast

# Test Stage 3: Create instances with same name on different networks
# Instance address should remain consistent
```

### Verify Deterministic Address

```bash
# Calculate expected address before creation
# (would require proxy bytecode calculation - see tests for implementation)

# After creation, verify address matches across chains
cast code $INSTANCE_ADDRESS --rpc-url $RPC_URL1
cast code $INSTANCE_ADDRESS --rpc-url $RPC_URL2

# Both should return the proxy bytecode (non-empty)
```

## Key Concepts

| Term | Description |
|------|-------------|
| **CCDAO_CREATE2** | Deterministic factory (fixed address per network) |
| **VDRF_FACTORY_PROXY** | VDRFactory proxy (unchanging address, upgradeable implementation) |
| **VDR Implementation** | Business logic (upgradeable, random address per version) |
| **VDR Instance** | DAO's VDR instance (deterministic address per DAO name) |
| **CREATE2 Salt** | Generated from DAO name for cross-chain consistency |

## Reference

- **Source Code**: [src/VDRFactory.sol](./src/VDRFactory.sol), [src/VDR.sol](./src/VDR.sol)
- **Tests**: [test/VDRFactory.t.sol](./test/VDRFactory.t.sol)
- **Deployment Scripts**: [script/VDR_Deploy_Initial.s.sol](./script/VDR_Deploy_Initial.s.sol), [script/VDR_Upgrade.s.sol](./script/VDR_Upgrade.s.sol)

# CCDAO VDR (Virtual Data Room)

VDR (Virtual Data Room) is a decentralized data management contract with multi-signature governance and access control. It follows a similar architecture to Safe's multi-signature design, allowing third parties to deploy their own VDR instances.

## Features

- **Multi-Signature Support**: Execute sensitive operations only with multiple approvals
- **Role-Based Access Control**: Different roles with different permissions
- **Modular Architecture**: Easy to extend and customize
- **Factory Pattern**: Third parties can deploy their own VDR instances
- **Data Management**: Secure storage and retrieval of data with access control
- **Event Logging**: Comprehensive audit trail for all operations

## Project Structure

```
src/
├── VDR.sol                 # Main VDR contract
├── VDRFactory.sol         # Factory for deploying VDR instances
├── interfaces/
│   ├── IVDR.sol          # VDR interface
│   └── IVDRFactory.sol    # VDR Factory interface
└── libraries/
    └── VDRConstants.sol   # Constants and types

test/
├── VDR.t.sol             # VDR contract tests
└── VDRFactory.t.sol      # Factory contract tests

script/
└── VDR.s.sol             # Deployment script
```

## Building

```bash
cd contract/CCDAO_VDR
forge build
```

## Testing

```bash
forge test
```

## Deployment

```bash
forge script script/VDR.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Usage

### Creating a VDR Instance

```solidity
// Deploy through factory
VDRFactory factory = new VDRFactory();
address vdrAddress = factory.createVDR(
    "My VDR",
    ["owner1", "owner2", "owner3"],
    2,  // threshold (required approvals)
    ["user1", "user2"]  // initial data managers
);
```

### Multi-Signature Operations

VDR operations require multi-signature approval:

1. Initiator proposes an operation
2. Multiple signers approve the operation
3. Once threshold is reached, operation is executed

## Architecture Design

The VDR contract is designed following Safe's multi-signature architecture:

1. **Ownership Model**: Multiple owners with configurable threshold
2. **Operation Execution**: Operations stored and executed only when approved by threshold number of owners
3. **Access Control**: Fine-grained permissions for different roles
4. **Extensibility**: Easy to extend with custom handlers and logic

## VC Registration Best Practices

### vcId Generation

The `vcId` parameter in `registerVC()` should be a **keccak256 hash** of the original VC identifier from the DID document, NOT the raw string.

**Why use a hash?**

| Benefit | Description |
|---------|-------------|
| Collision resistance | 256-bit hash space (2^256) virtually eliminates duplicates |
| Privacy protection | On-chain vcId cannot be reversed to reveal original ID |
| Easy verification | Hash the original ID and compare with on-chain record |
| W3C VC compatibility | Works with standard VC URI formats |

**Example (JavaScript/ethers.js):**

```javascript
import { ethers } from 'ethers';

// Original VC ID from DID document (W3C standard format)
const originalVcId = "urn:uuid:" + crypto.randomUUID();
// e.g., "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"

// Hash it for on-chain storage
const vcIdHash = ethers.keccak256(ethers.toUtf8Bytes(originalVcId));

// Register on-chain
await vdr.registerVC(vcIdHash, holderAddress, contentHash, issuanceDate);
```

**Example (Solidity):**

```solidity
// If computing hash on-chain (less common)
bytes32 vcId = keccak256(bytes("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6"));
```

**Verification flow:**

1. User presents original VC with ID `urn:uuid:xxx`
2. Verifier computes `keccak256("urn:uuid:xxx")`
3. Query `vdr.getVC(hash)` to verify on-chain status

## License

MIT

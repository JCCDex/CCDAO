// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VDRConstants
 * @dev Constants and type definitions for VDR VC (Verifiable Credentials) Registry
 */
library VDRConstants {
    // ============ VC Status ============
    enum VCStatus {
        Active,               // 0: VC is valid and active
        Revoked,              // 1: VC has been revoked by issuer
        Disputed,             // 2: VC is under dispute
        Expired               // 3: VC has expired
    }

    // ============ Role Definitions ============
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ============ VC Type Constants ============
    // All types are on-chain verifiable without third-party intermediaries
    
    // Asset & Equity (资产权益类) - Verifiable via balance queries
    bytes32 public constant VC_TYPE_TOKEN_HOLDER = keccak256("VC_TYPE_TOKEN_HOLDER");
    bytes32 public constant VC_TYPE_NFT_OWNER = keccak256("VC_TYPE_NFT_OWNER");
    // bytes32 public constant VC_TYPE_LP_PROVIDER = keccak256("VC_TYPE_LP_PROVIDER");
    // bytes32 public constant VC_TYPE_STAKER = keccak256("VC_TYPE_STAKER");

    // Governance & Participation (治理参与类) - Verifiable via DAO smart contracts
    bytes32 public constant VC_TYPE_DAO_MEMBER = keccak256("VC_TYPE_DAO_MEMBER");

    // Reputation & History (信誉历史类) - Verifiable via transaction history & timestamps
    // bytes32 public constant VC_TYPE_EARLY_ADOPTER = keccak256("VC_TYPE_EARLY_ADOPTER");
    // bytes32 public constant VC_TYPE_ACTIVE_PARTICIPANT = keccak256("VC_TYPE_ACTIVE_PARTICIPANT");
    // bytes32 public constant VC_TYPE_TRANSACTION_HISTORY = keccak256("VC_TYPE_TRANSACTION_HISTORY");

    // Special Status (特殊身份类) - Verifiable via contract state or cryptographic proof
    // bytes32 public constant VC_TYPE_LIQUIDITY_LOCK = keccak256("VC_TYPE_LIQUIDITY_LOCK");
    // bytes32 public constant VC_TYPE_MULTISIG_SIGNER = keccak256("VC_TYPE_MULTISIG_SIGNER");

    // ============ Structs ============

    /**
     * @dev Represents a Verifiable Credential (VC)
     * @param vcId Unique identifier for the VC (provided by caller, must be globally unique)
     * @param issuer Address of the credential issuer
     * @param holder Address of the credential holder
     * @param vcType Type of the VC (bytes32(0) means untyped/generic)
     * @param contentHash keccak256 hash of the VC content (32 bytes, verifiable by anyone)
     * @param issuanceDate Timestamp when the VC was issued (off-chain)
     * @param registrationTime Timestamp when the VC was registered on-chain (auto-recorded)
     * @param status Current status of the VC
     */
    struct VCRecord {
        bytes32 vcId;
        address issuer;
        address holder;
        bytes32 vcType;           // bytes32(0) = untyped/generic
        bytes32 contentHash;
        uint256 issuanceDate;
        uint256 registrationTime;
        VCStatus status;
    }

    /**
     * @dev Represents a verification record for a VC
     * @param verifier Address of the entity that performed verification
     * @param verificationTime Timestamp of the verification
     * @param isValid Whether the verification was successful
     * @param verificationNotes Additional notes from the verifier
     */
    struct VerificationRecord {
        address verifier;
        uint256 verificationTime;
        bool isValid;
        string verificationNotes;
    }

    /**
     * @dev Represents a member with roles in the VDR
     * @param memberAddress The member's Ethereum address
     * @param role The primary role of the member
     * @param joinedTime When the member joined
     */
    struct Member {
        address memberAddress;
        bytes32 role;
        uint256 joinedTime;
    }
}

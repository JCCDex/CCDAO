// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/VDRConstants.sol";

/**
 * @title IVDR
 * @dev Interface for VDR (Virtual Data Room) - Verifiable Credentials Registry
 * 
 * VDR is a registry for Verifiable Credentials with verification and dispute management.
 * DID Model: User Ethereum accounts serve as DIDs (did:ether)
 * Content Storage: Credentials on IPFS, only hash and signature on-chain
 */
interface IVDR {
    // ============ Events ============

    // VC Registration & Management
    event VCRegistered(
        bytes32 indexed vcId,
        address indexed issuer,
        address indexed holder,
        bytes32 vcType
    );

    event VCRevoked(
        bytes32 indexed vcId,
        address indexed revokedBy
    );

    event VCDisputed(
        bytes32 indexed vcId,
        address indexed disputer
    );

    event DisputeResolved(
        bytes32 indexed vcId,
        bool resolved
    );

    event VerificationRecorded(
        bytes32 indexed vcId,
        address indexed verifier,
        bool isValid
    );

    // Member Management
    event MemberAdded(
        address indexed member,
        bytes32 indexed role
    );

    event MemberRemoved(
        address indexed member
    );

    event MemberRoleChanged(
        address indexed member,
        bytes32 indexed oldRole,
        bytes32 indexed newRole
    );

    // Official DAO Assets
    event OfficialERC20Set(
        address indexed erc20
    );

    event OfficialERC721Set(
        address indexed erc721
    );

    // ============ Initialization ============

    /**
     * @dev Initialize the VDR
     * @param _name The name of the VDR
     * @param _owner The owner address (can be a multisig contract)
     * @param _issuers Array of initial issuer addresses
     */
    function initialize(
        string memory _name,
        address _owner,
        address[] calldata _issuers
    ) external;

    // ============ VC Registration ============

    /**
     * @dev Register a new Verifiable Credential
     * Caller is the issuer, holder can be different
     * @param vcId Unique identifier for the VC (must be globally unique)
     * @param holder Address of the credential holder
     * @param contentHash keccak256 hash of VC content (32 bytes, verifiable by anyone)
     * @param issuanceDate Timestamp when VC was issued off-chain
     */
    function registerVC(
        bytes32 vcId,
        address holder,
        bytes32 contentHash,
        uint256 issuanceDate
    ) external;

    /**
     * @dev Revoke a credential
     * @param vcId The credential to revoke
     */
    function revokeVC(bytes32 vcId) external;

    /**
     * @dev Initiate a dispute on a credential
     * @param vcId The credential to dispute
     */
    function disputeVC(bytes32 vcId) external;

    /**
     * @dev Resolve a dispute by revoking or restoring the credential
     * @param vcId The credential to resolve
     * @param shouldRevoke Whether to revoke or restore
     */
    function resolveDispute(bytes32 vcId, bool shouldRevoke) external;

    // ============ VC Query ============

    /**
     * @dev Get a credential record
     * @param vcId The credential ID
     * @return The VCRecord
     */
    function getVC(bytes32 vcId) external view returns (VDRConstants.VCRecord memory);

    /**
     * @dev Get all VCs issued by an address
     * @param issuer The issuer address
     * @return Array of VC IDs
     */
    function getIssuerVCs(address issuer) external view returns (bytes32[] memory);

    /**
     * @dev Get all VCs held by an address
     * @param holder The holder address
     * @return Array of VC IDs
     */
    function getHolderVCs(address holder) external view returns (bytes32[] memory);

    /**
     * @dev Get all disputed VCs
     * @return Array of disputed VC IDs
     */
    function getDisputedVCs() external view returns (bytes32[] memory);

    /**
     * @dev Get total number of VCs in this VDR
     * @return Total count of VCs (including revoked ones)
     */
    function getTotalVCCount() external view returns (uint256);

    // ============ Verification ============

    // ============ Member Management ============

    /**
     * @dev Add a member with a role
     * @param member Member address
     * @param role Member role
     */
    function addMember(address member, bytes32 role) external;

    /**
     * @dev Remove a member
     * @param member Member address
     */
    function removeMember(address member) external;

    /**
     * @dev Check if an address has a specific role
     * @param member The address to check
     * @param role The role to check for
     * @return True if member has the role
     */
    function hasMemberRole(address member, bytes32 role) external view returns (bool);

    /**
     * @dev Check if an address is a member
     * @param member The address to check
     * @return True if address is a member
     */
    function isMember(address member) external view returns (bool);

    /**
     * @dev Get total member count
     * @return Number of members
     */
    function getMemberCount() external view returns (uint256);

    /**
     * @dev Get member at specific index
     * @param index The index
     * @return Member address
     */
    function getMemberByIndex(uint256 index) external view returns (address);

    /**
     * @dev Get member details
     * @param member The member address
     * @return The Member record
     */
    function getMember(address member) external view returns (VDRConstants.Member memory);

    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory);

    // ============ Official DAO Assets ============

    /**
     * @dev Set the official ERC20 token for this DAO
     * @param erc20Address The ERC20 token address
     */
    function setOfficialERC20(address erc20Address) external;

    /**
     * @dev Set the official ERC721 token for this DAO
     * @param erc721Address The ERC721 token address
     */
    function setOfficialERC721(address erc721Address) external;

    /**
     * @dev Get the official ERC20 token address
     * @return The ERC20 token address (or address(0) if not set)
     */
    function getOfficialERC20() external view returns (address);

    /**
     * @dev Get the official ERC721 token address
     * @return The ERC721 token address (or address(0) if not set)
     */
    function getOfficialERC721() external view returns (address);

    // ============ View Functions ============

    /**
     * @dev Get the current version encoded as MMMNNNPPP
     * Format: MMM (major) NNN (minor) PPP (patch)
     * Example: 1.0.0 = 001000000, 1.1.5 = 001001005
     * @return Encoded version number
     */
    function getVersion() external view returns (uint256);

    /**
     * @dev Get the current implementation
     * @return The implementation address
     */
    function getImplementation() external view returns (address);
}


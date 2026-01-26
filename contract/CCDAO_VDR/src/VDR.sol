// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IVDR.sol";
import "./libraries/VDRConstants.sol";

/**
 * @title VDR
 * @dev Virtual Data Room for Verifiable Credentials (VC) Registry
 * 
 * This contract serves as a registry for Verifiable Credentials, enabling:
 * - Credential issuance and management
 * - Verification and validation
 * - Dispute resolution
 * - Efficient querying by issuer, holder, or type
 * 
 * DID Model: User Ethereum accounts serve as DIDs (did:ether)
 * Content Storage: Credentials stored on IPFS, only hash and signature on-chain
 * Verification: Open - any party can verify credentials
 * 
 * @author CCDAO Team
 */
contract VDR is Initializable, OwnableUpgradeable, UUPSUpgradeable, IVDR {
    using VDRConstants for *;

    // ============ State Variables ============

    string public vdrName;
    
    // Version format: MMMNNNPPP where MMM=major, NNN=minor, PPP=patch
    // Example: 1.0.0 = 001000000, 1.1.5 = 001001005
    // This is a constant set by the implementation contract and cannot be changed
    // New implementations must define a higher version number
    uint256 public constant version = 1000000; // 1.0.0 in MMMNNNPPP format
    
    address public factory;

    // Official DAO assets (Owner can set these to represent official tokens)
    address public officialERC20;
    address public officialERC721;

    // VC Registry
    mapping(bytes32 => VDRConstants.VCRecord) private vcRecords;
    
    // Efficient indexing by issuer and holder
    mapping(address => bytes32[]) private issuerVCs;
    mapping(address => bytes32[]) private holderVCs;

    // Dispute tracking for efficient querying
    bytes32[] private disputedVCs;
    mapping(bytes32 => uint256) private disputedVCIndices;

    // VC count tracking
    uint256 private vcCount;

    // Member management
    mapping(address => VDRConstants.Member) private members;
    address[] private memberList;
    mapping(address => uint256) private memberIndices;

    // ============ Constants ============

    // ============ Modifiers ============

    modifier onlyAdmin() {
        require(
            hasMemberRole(_msgSender(), VDRConstants.ADMIN_ROLE) || 
            owner() == _msgSender(),
            "VDR: not an admin or owner"
        );
        _;
    }

    modifier onlyVerifier() {
        require(
            hasMemberRole(_msgSender(), VDRConstants.VERIFIER_ROLE) || 
            owner() == _msgSender(),
            "VDR: not a verifier or owner"
        );
        _;
    }

    modifier vcExists(bytes32 vcId) {
        require(vcRecords[vcId].vcId != bytes32(0), "VDR: VC not found");
        _;
    }

    // ============ Constructor ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ Initialization ============

    /**
     * @dev Initialize the VDR
     * @param _name The name of the VDR
     * @param _owner The owner address (can be a multisig contract)
     * @param _verifiers Array of initial verifier addresses
     */
    function initialize(
        string memory _name,
        address _owner,
        address[] calldata _verifiers
    ) external initializer {
        __Ownable_init(_owner);
        factory = msg.sender;
        
        vdrName = _name;

        // Initialize verifiers
        for (uint256 i = 0; i < _verifiers.length; i++) {
            if (_verifiers[i] != address(0)) {
                _addMember(_verifiers[i], VDRConstants.VERIFIER_ROLE);
            }
        }
    }

    // ============ Upgrade Authorization ============

    function _authorizeUpgrade(address newImplementation) internal override {
        require(
            msg.sender == factory,
            "VDR: upgrades must be authorized by factory"
        );
        require(newImplementation != address(0), "VDR: invalid implementation");
        
        // Get version from new implementation via staticcall to verify compatibility
        // Use function signature directly since getVersion() is a pure function
        (bool success, bytes memory result) = newImplementation.staticcall(
            abi.encodeWithSignature("getVersion()")
        );
        require(success, "VDR: failed to read version from new implementation");
        require(result.length == 32, "VDR: invalid version data from new implementation");
        
        uint256 newVersion = abi.decode(result, (uint256));
        require(newVersion > version, "VDR: new implementation version must be higher");
        // Note: version is a constant and cannot be updated here. The new implementation
        // will have its own constant version value set at compile time.
    }

    // ============ VC Registration ============

    /**
     * @dev Register a new Verifiable Credential
     * Caller is the issuer, holder can be different
     * @param vcId Unique identifier for the VC (must be globally unique)
     * @param holder Address of the credential holder (can be different from issuer)
     * @param contentHash keccak256 hash of VC content (verifiable by anyone)
     * @param issuanceDate When the VC was issued off-chain
     */
    function registerVC(
        bytes32 vcId,
        address holder,
        bytes32 contentHash,
        uint256 issuanceDate
    ) external {
        require(vcId != bytes32(0), "VDR: invalid VC ID");
        require(vcRecords[vcId].vcId == bytes32(0), "VDR: VC already exists");
        require(holder != address(0), "VDR: invalid holder");
        require(contentHash != bytes32(0), "VDR: invalid content hash");
        require(issuanceDate > 0 && issuanceDate <= block.timestamp, "VDR: invalid issuance date");

        // Create VC record
        address issuer = _msgSender();
        VDRConstants.VCRecord storage vc = vcRecords[vcId];
        vc.vcId = vcId;
        vc.issuer = issuer;              // Caller is the issuer
        vc.holder = holder;              // Holder can be different from issuer
        vc.contentHash = contentHash;    // keccak256 hash - verifiable by anyone
        vc.issuanceDate = issuanceDate;  // When issued off-chain
        vc.registrationTime = block.timestamp; // When registered on-chain
        vc.status = VDRConstants.VCStatus.Active;

        // Add to indices
        issuerVCs[issuer].push(vcId);
        holderVCs[holder].push(vcId);

        // Increment VC count
        vcCount++;

        emit VCRegistered(vcId, issuer, holder, bytes32(0));
    }

    // ============ VC Revocation ============

    /**
     * @dev Revoke a credential
     * Can be called by: issuer, admin, or owner
     * @param vcId The credential to revoke
     */
    function revokeVC(bytes32 vcId) external vcExists(vcId) {
        VDRConstants.VCRecord storage vc = vcRecords[vcId];
        require(
            vc.issuer == _msgSender() || 
            hasMemberRole(_msgSender(), VDRConstants.ADMIN_ROLE) ||
            owner() == _msgSender(),
            "VDR: only issuer, admin or owner can revoke"
        );
        require(vc.status == VDRConstants.VCStatus.Active || vc.status == VDRConstants.VCStatus.Disputed, 
            "VDR: cannot revoke non-active VC");

        _revokeVC(vcId);
    }

    // ============ VC Disputes ============

    /**
     * @dev Initiate a dispute on a credential
     * Requires caller to hold either:
     * - At least 10,000 of the official ERC20 token, OR
     * - At least 1 of the official ERC721 token
     * @param vcId The credential to dispute
     */
    function disputeVC(bytes32 vcId) external vcExists(vcId) {
        require(vcRecords[vcId].status == VDRConstants.VCStatus.Active, "VDR: can only dispute active VCs");
        
        // Check token balance requirements
        bool hasERC20 = false;
        bool hasERC721 = false;

        // Check ERC20 balance (require at least 10,000 tokens)
        if (officialERC20 != address(0)) {
            uint256 erc20Balance = IERC20(officialERC20).balanceOf(_msgSender());
            hasERC20 = erc20Balance >= 10000 * 10**18; // Assuming 18 decimal places
        }

        // Check ERC721 balance (require at least 1 token)
        if (officialERC721 != address(0)) {
            uint256 erc721Balance = IERC721(officialERC721).balanceOf(_msgSender());
            hasERC721 = erc721Balance >= 1;
        }

        // Must have at least one of the official tokens
        require(
            hasERC20 || hasERC721 || owner() == _msgSender(),
            "VDR: insufficient official token balance to dispute"
        );

        vcRecords[vcId].status = VDRConstants.VCStatus.Disputed;
        
        // Track disputed VC
        disputedVCIndices[vcId] = disputedVCs.length;
        disputedVCs.push(vcId);
        
        emit VCDisputed(vcId, _msgSender());
    }

    /**
     * @dev Resolve a dispute by revoking or restoring the credential
     * @param vcId The credential to resolve
     * @param shouldRevoke Whether to revoke or restore
     */
    function resolveDispute(bytes32 vcId, bool shouldRevoke) external onlyAdmin vcExists(vcId) {
        require(vcRecords[vcId].status == VDRConstants.VCStatus.Disputed, "VDR: VC not in disputed state");

        if (shouldRevoke) {
            _revokeVC(vcId);
        } else {
            vcRecords[vcId].status = VDRConstants.VCStatus.Active;
            emit DisputeResolved(vcId, false);
        }
        
        // Remove from disputed VCs tracking
        _removeDisputedVC(vcId);
    }

    // ============ VC Query ============

    /**
     * @dev Get a credential record
     * @param vcId The credential ID
     * @return The VCRecord
     */
    function getVC(bytes32 vcId) external view vcExists(vcId) returns (VDRConstants.VCRecord memory) {
        return vcRecords[vcId];
    }

    /**
     * @dev Get all VCs issued by an address
     * @param issuer The issuer address
     * @return Array of VC IDs
     */
    function getIssuerVCs(address issuer) external view returns (bytes32[] memory) {
        return issuerVCs[issuer];
    }

    /**
     * @dev Get all VCs held by an address
     * @param holder The holder address
     * @return Array of VC IDs
     */
    function getHolderVCs(address holder) external view returns (bytes32[] memory) {
        return holderVCs[holder];
    }

    /**
     * @dev Get all disputed VCs
     * @return Array of disputed VC IDs
     */
    function getDisputedVCs() external view returns (bytes32[] memory) {
        return disputedVCs;
    }

    /**
     * @dev Get total number of VCs in this VDR
     * @return Total count of VCs (including revoked ones)
     */
    function getTotalVCCount() external view returns (uint256) {
        return vcCount;
    }

    // ============ Member Management ============

    /**
     * @dev Set the official ERC20 token for this DAO (only Owner can call)
     * @param erc20Address The ERC20 token address
     */
    function setOfficialERC20(address erc20Address) external onlyOwner {
        require(erc20Address != address(0), "VDR: invalid ERC20 address");
        officialERC20 = erc20Address;
        emit OfficialERC20Set(erc20Address);
    }

    /**
     * @dev Set the official ERC721 token for this DAO (only Owner can call)
     * @param erc721Address The ERC721 token address
     */
    function setOfficialERC721(address erc721Address) external onlyOwner {
        require(erc721Address != address(0), "VDR: invalid ERC721 address");
        officialERC721 = erc721Address;
        emit OfficialERC721Set(erc721Address);
    }

    /**
     * @dev Get the official ERC20 token address
     * @return The ERC20 token address (or address(0) if not set)
     */
    function getOfficialERC20() external view returns (address) {
        return officialERC20;
    }

    /**
     * @dev Get the official ERC721 token address
     * @return The ERC721 token address (or address(0) if not set)
     */
    function getOfficialERC721() external view returns (address) {
        return officialERC721;
    }

    /**
     * @dev Set admin (only Owner can call)
     * @param admin The admin address
     */
    function setAdmin(address admin) external onlyOwner {
        require(admin != address(0), "VDR: invalid admin address");
        _addMember(admin, VDRConstants.ADMIN_ROLE);
    }

    /**
     * @dev Add a member with a role (only Admin or Owner can call)
     * @param member Member address
     * @param role Member role (typically VERIFIER_ROLE)
     */
    function addMember(address member, bytes32 role) external onlyAdmin {
        require(member != address(0), "VDR: invalid member address");
        _addMember(member, role);
    }

    /**
     * @dev Remove a member (only Admin or Owner can call)
     * @param member Member address
     */
    function removeMember(address member) external onlyAdmin {
        _removeMember(member);
    }

    /**
     * @dev Check if an address has a specific role
     * @param member The address to check
     * @param role The role to check for
     * @return True if member has the role
     */
    function hasMemberRole(address member, bytes32 role) public view returns (bool) {
        if (members[member].memberAddress == address(0)) {
            return false;
        }
        return members[member].role == role;
    }

    /**
     * @dev Check if an address is a member
     * @param member The address to check
     * @return True if address is a member
     */
    function isMember(address member) external view returns (bool) {
        return members[member].memberAddress != address(0);
    }

    /**
     * @dev Get total member count
     * @return Number of members
     */
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    /**
     * @dev Get member at specific index
     * @param index The index
     * @return Member address
     */
    function getMemberByIndex(uint256 index) external view returns (address) {
        require(index < memberList.length, "VDR: index out of bounds");
        return memberList[index];
    }

    /**
     * @dev Get member details
     * @param member The member address
     * @return The Member record
     */
    function getMember(address member) external view returns (VDRConstants.Member memory) {
        require(members[member].memberAddress != address(0), "VDR: member not found");
        return members[member];
    }

    /**
     * @dev Get all members
     * @return Array of member addresses
     */
    function getMembers() external view returns (address[] memory) {
        return memberList;
    }

    // ============ View Functions ============

    /**
     * @dev Get the current version encoded as MMMNNNPPP
     * Format: MMM (major) NNN (minor) PPP (patch)
     * Example: 1.0.0 = 001000000, 1.1.5 = 001001005
     * @return Encoded version number
     */
    function getVersion() public pure returns (uint256) {
        return version;
    }

    /**
     * @dev Get the current implementation
     * @return The implementation address
     */
    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    // ============ Internal Helper Functions ============

    function _addMember(address member, bytes32 role) internal {
        if (members[member].memberAddress == address(0)) {
            members[member] = VDRConstants.Member({
                memberAddress: member,
                role: role,
                joinedTime: block.timestamp
            });
            memberIndices[member] = memberList.length;
            memberList.push(member);
            emit MemberAdded(member, role);
        } else {
            bytes32 oldRole = members[member].role;
            members[member].role = role;
            if (oldRole != role) {
                emit MemberRoleChanged(member, oldRole, role);
            }
        }
    }

    function _removeMember(address member) internal {
        require(members[member].memberAddress != address(0), "VDR: member not found");

        uint256 index = memberIndices[member];
        address lastMember = memberList[memberList.length - 1];

        memberList[index] = lastMember;
        memberIndices[lastMember] = index;
        memberList.pop();

        delete members[member];
        delete memberIndices[member];

        emit MemberRemoved(member);
    }

    /**
     * @dev Internal function to revoke a VC
     * @param vcId The credential to revoke
     */
    function _revokeVC(bytes32 vcId) internal {
        vcRecords[vcId].status = VDRConstants.VCStatus.Revoked;
        vcCount--;
        emit VCRevoked(vcId, _msgSender());
    }

    function _removeDisputedVC(bytes32 vcId) internal {
        uint256 index = disputedVCIndices[vcId];
        bytes32 lastVC = disputedVCs[disputedVCs.length - 1];

        disputedVCs[index] = lastVC;
        disputedVCIndices[lastVC] = index;
        disputedVCs.pop();

        delete disputedVCIndices[vcId];
    }

    // ============ Events ============
    // Note: Event declarations in IVDR interface
}

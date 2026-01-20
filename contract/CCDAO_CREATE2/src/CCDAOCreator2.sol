// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @title CCDAOCreator2
 * @dev This contract uses CREATE2 opcode to deploy contracts at deterministic addresses
 * 
 * The contract can:
 * 1. Deploy contracts with arbitrary bytecode at a specific address using CREATE2
 * 2. Predict the address where a contract will be deployed before deployment
 * 3. Recover accidentally sent ERC20 tokens (ERC20 cannot be rejected due to lack of receiver hook)
 * 4. Recover accidentally sent ERC721 tokens (incomplete ERC721 implementations may bypass checks)
 * 
 * Note: ETH transfers are intentionally rejected. Complete ERC721 implementations will also
 * be rejected via onERC721Received, but incomplete implementations may succeed.
 */
contract CCDAOCreator2 {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Transfers ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(newOwner != owner, "New owner is the same as current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Renounces ownership, leaving the contract without an owner
     * WARNING: This will make all owner-controlled functions permanently inaccessible
     */
    function renounceOwnership() external onlyOwner {
        address previousOwner = owner;
        owner = address(0);
        
        emit OwnershipTransferred(previousOwner, address(0));
    }
    
    /**
     * @dev Deploys a contract with the given bytecode at a deterministic address using CREATE2
     * @param bytecode The bytecode of the contract to deploy
     * @param salt The salt value used for CREATE2 to determine the deployment address
     * @return deployedAddress The address of the deployed contract
     */
    function deploy(bytes calldata bytecode, bytes32 salt) external payable returns (address deployedAddress) {
        // Use Solidity's built-in capability to calculate CREATE2 address and deploy
        bytes memory code = bytes(bytecode);
        
        assembly {
            // Memory layout when we do bytes(bytecode):
            // [0x00]: free memory pointer (unused here)
            // [code]: length
            // [code + 0x20]: actual code
            
            deployedAddress := create2(
                callvalue(),
                add(code, 0x20),    // data starts after length
                mload(code),        // length of code
                salt
            )
        }
        
        require(deployedAddress != address(0), "CREATE2 deployment failed");
    }
    
    /**
     * @dev Predicts the address where a contract will be deployed using CREATE2
     * @param salt The salt value used for CREATE2
     * @param bytecodeHash The keccak256 hash of the contract bytecode
     * @return The predicted address of the contract
     */
    function predictAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),  // CREATE2 prefix
                            address(this),  // deployer address
                            salt,  // salt
                            bytecodeHash  // keccak256(bytecode)
                        )
                    )
                )
            )
        );
    }
    
    /**
     * @dev Withdraws accidentally sent ERC20 tokens from the contract
     * @param token The address of the ERC20 token contract
     */
    function withdrawERC20(address token) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        require(erc20.transfer(owner, balance), "Token transfer failed");
    }
    
    /**
     * @dev Withdraws accidentally sent ERC721 tokens from the contract
     * @param token The address of the ERC721 token contract
     * @param tokenId The ID of the token to withdraw
     */
    function withdrawERC721(address token, uint256 tokenId) external onlyOwner {
        IERC721 erc721 = IERC721(token);
        require(erc721.ownerOf(tokenId) == address(this), "Token not owned by this contract");
        
        erc721.transferFrom(address(this), owner, tokenId);
    }
    
    /**
     * @dev Rejects any incoming ERC721 tokens
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        revert("CCDAOCreator2: ERC721 tokens not accepted");
    }
    
    /**
     * @dev Rejects any incoming ETH
     */
    fallback() external {
        revert("CCDAOCreator2: ETH not accepted");
    }
}

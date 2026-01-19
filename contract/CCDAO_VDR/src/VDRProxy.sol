// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VDRProxy
 * @dev Proxy contract for VDR instances supporting upgrades
 */
contract VDRProxy {
    // ============ Storage ============
    
    // Implementation address stored in specific slot to avoid collision
    // slot: keccak256("VDR_IMPLEMENTATION_SLOT")
    bytes32 private constant IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    bytes32 private constant ADMIN_SLOT = 
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // ============ Events ============
    
    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    // ============ Constructor ============
    
    constructor(address _implementation, address _admin, bytes memory _initData) {
        _setImplementation(_implementation);
        _setAdmin(_admin);
        
        if (_initData.length > 0) {
            (bool success, ) = _implementation.delegatecall(_initData);
            require(success, "VDRProxy: initialization failed");
        }
    }

    // ============ Upgrade Functions ============
    
    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    function upgradeToAndCall(address newImplementation, bytes calldata data) 
        external onlyAdmin 
    {
        _setImplementation(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success, "VDRProxy: upgrade call failed");
        emit Upgraded(newImplementation);
    }
    
    function changeAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }

    // ============ View Functions ============
    
    function implementation() external view returns (address) {
        return _getImplementation();
    }
    
    function admin() external view returns (address) {
        return _getAdmin();
    }

    // ============ Proxy Logic ============
    
    fallback() external payable {
        address impl = _getImplementation();
        require(impl != address(0), "VDRProxy: no implementation");
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    receive() external payable {}

    // ============ Internal Functions ============
    
    function _getImplementation() internal view returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
        return impl;
    }
    
    function _setImplementation(address newImpl) internal {
        require(newImpl != address(0), "VDRProxy: invalid implementation");
        assembly {
            sstore(IMPLEMENTATION_SLOT, newImpl)
        }
    }
    
    function _getAdmin() internal view returns (address) {
        address adm;
        assembly {
            adm := sload(ADMIN_SLOT)
        }
        return adm;
    }
    
    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "VDRProxy: invalid admin");
        assembly {
            sstore(ADMIN_SLOT, newAdmin)
        }
    }
    
    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "VDRProxy: only admin");
        _;
    }
}

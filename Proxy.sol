pragma solidity 0.5.1;

import "./Registry.sol";

/**
 * @title Proxy
 * @author Rob Hitchens
 * @notice Trustless upgradable contract proxy.
 */

contract RegistryClient {
    
    bytes32 private constant REGISTRY_ADDRESS_KEY = keccak256("Registry address key");
    bytes32 private constant RELEASE_MANAGER_KEY = keccak256("Release Manager key");
    address private constant UNDEFINED = address(0);
    
    event LogNewReleaseManager(address sender, address releaseManager);
    
    /**
     * @notice Only the release manager can modify the implementation options in the registry.
     */
    modifier onlyReleaseManager {
       require(msg.sender == releaseManager()) ;
       _;
    }
    
    /**
     * @dev The release manager is stored in proxy contract. It will be consulted to determine user's preferred implementation. 
     */
    constructor() public {
        bytes32 releaseManagerKey = RELEASE_MANAGER_KEY;
        //solium-disable-next-line security/no-inline-assembly
        address releaseManager = msg.sender;
        assembly {
            sstore(releaseManagerKey, releaseManager) 
        }
    }
    
    /**
     * @return The address of the authoratative implementation registry.
     */
    function registryImplementationAddress() public view returns(address) {
        address r;
        bytes32 registryAddressKey = REGISTRY_ADDRESS_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            r := sload(registryAddressKey)
        }
        require(r != UNDEFINED);
        return r;
    }
    
    /**
     * @return The address of the privileged release manager. 
     */
    function releaseManager() public view returns(address) {
        address r;
        bytes32 releaseManagerKey = RELEASE_MANAGER_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            r := sload(releaseManagerKey)
        }
        return r;
    }
    
    /**
     * @param newManager The address of the new release manager. 
     * @notice Only the current manager can appoint a new release manager. 
     */
    function newReleaseManager(address newManager) public onlyReleaseManager {
        require(newManager != UNDEFINED);
        bytes32 releaseManagerKey = RELEASE_MANAGER_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(releaseManagerKey, newManager) 
        }
    }
}

contract Proxy is RegistryClient {
    
    bytes32 private constant REGISTRY_ADDRESS_KEY = keccak256("Registry address key");
    address private constant UNDEFINED = address(0);
    
    /**
     * @notice Deploys a new registry for this component. Each proxy controls one upgradable component. 
     * @notice Stores the release manager contract address in the proxy contract. 
     * @notice Uses a collision-resistant storage slot.
     */
    constructor() public {
        Registry registry = new Registry();
        registry.transferOwnership(msg.sender);
        address registryAddress = address(registry);
        bytes32 registryAddressStorageKey = REGISTRY_ADDRESS_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(registryAddressStorageKey, registryAddress)
        }
    }
    
    /**
     * @return The address of authoratative implementation registry for this proxy. 
     */
    function registryAddress() public view returns(address) {
        address r;
        bytes32 registryAddressKey = REGISTRY_ADDRESS_KEY;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            r := sload(registryAddressKey)
        }
        require(r != UNDEFINED);
        return r;
    }
    
    /**
     * @return The componentUid for this proxy.
     */
    function componentUid() public view returns(bytes32) {
        Registry registry = Registry(registryAddress());
        return registry.COMPONENT_UID();
    }
    
    /** 
     * @return The user implementation preference. 
     * @dev If the user has no preference or the preference was recalled, returns the default implementation. 
     */
    function userImplementation(address user) public view returns(address) {
        Registry registry = Registry(registryAddress());
        return registry.userImplementation(user);
    } 
    
    /**
     * @notice The delegate call. Delegates to the user's preferred implementation. 
     */
    function () external payable {
        address implementationAddress = userImplementation(msg.sender);
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, implementationAddress, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

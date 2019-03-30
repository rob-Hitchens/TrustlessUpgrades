pragma solidity 0.5.1;

/**
 * @title Registry
 * @author Rob Hitchens
 * @notice Trustless upgradable contract implementation registry.
 */

import "./HitchensUnorderedAddressSet.sol";
import "./Upgradable.sol";
import "./Ownable.sol";

contract Registry is Ownable {
    
    using HitchensUnorderedAddressSetLib for HitchensUnorderedAddressSetLib.Set;
    HitchensUnorderedAddressSetLib.Set validImplementations;
    
    address defaultImplementation;
    address constant UNDEFINED = address(0);
    bytes32 public COMPONENT_UID;
    
    mapping(address => address) userImplementationChoices;
    
    event LogNewRegistry(address sender, address registry);
    event LogNewImplementation(address sender, address implementation);
    event LogRecalledImplementation(address sender, address implementation);
    event LogNewDefaultImplementation(address sender, address implementation);
    event LogUserImplementation(address sender, address implementation);
    
    /**
     * Ensures a unique identifier for the component this registry is concerned with. 
     */
    constructor() public {
        COMPONENT_UID = keccak256(abi.encodePacked(address(this), msg.sender));
        emit LogNewRegistry(msg.sender, address(this));
    }
    
    /**
     * @param implementationAddress Address of a compatible implementation contract. 
     * @notice The componentUid() function in the implementationAddress must return a matching componentUid. This helps prevent deployment errors. 
     */
    function addImplementation(address implementationAddress) external onlyOwner {
        UpgradableInterface u = UpgradableInterface(implementationAddress);
        require(u.componentUid() == COMPONENT_UID, "Implementation.componentUid doesn't match this registry's componentUid.");
        validImplementations.insert(implementationAddress);
        emit LogNewImplementation(msg.sender, implementationAddress);
    }
    
    /**
     * @param implementationAddress The address of an implementation contract to recall. 
     * @notice Only the release manager. Cannot recall the default implementation. 
     */
    function recallImplementation(address implementationAddress) external onlyOwner {
        require(implementationAddress != defaultImplementation, "Cannot recall default implementation.");
        validImplementations.remove(implementationAddress);
        emit LogRecalledImplementation(msg.sender, implementationAddress);
    }
    
    /**
     * @param implementationAddress Set the default implementation. 
     * @notice Only the release manager. The default implementation address must be registered. 
     */
    function setDefaultImplementation(address implementationAddress) external onlyOwner returns(bool) {
        require(isImplementation(implementationAddress), "implementationAddress is not registered.");
        defaultImplementation = implementationAddress;
        emit LogNewDefaultImplementation(msg.sender, implementationAddress);
    }
    
    /**
     * @param implementationAddress User's preferred implementation. 
     * @notice Overrides the default implementation unless the user's preferred implementation was recalled. 
     */
    function setMyImplementation(address implementationAddress) public {
        if(implementationAddress != UNDEFINED) require(isImplementation(implementationAddress), "implementationAddress is not registered.");
        userImplementationChoices[msg.sender] = implementationAddress;
        emit LogUserImplementation(msg.sender, implementationAddress );
    }
    
    /**
     * @param user The user to inspect.
     * @return address The user's preferred implementation address. Default if none or if the user's preferred implementation was recalled.
     */
    function userImplementation(address user) public view returns(address) {
        address implementation = userImplementationChoices[user];
        if(!validImplementations.exists(implementation)) return defaultImplementation;
        return implementation;
    }
    /**
     * @return address msg.sender's preferred implementation address.
     */
    function myImplementation() public view returns(address) {
        return userImplementation(msg.sender);
    }
    
    /**
     * @param implementationAddress The address to check. 
     * @return bool True if the implementation is a registered implementation.
     */
    function isImplementation(address implementationAddress) public view returns(bool) {
        return validImplementations.exists(implementationAddress);
    }
    
    /**
     * @return uint The count of implementation contracts registered. 
     */
    function implementationCount() public view returns(uint) {
        return validImplementations.count();
    }
    
    /**
     * @param index The row number to inspect. 
     * @return address The address of an implementtion address.
     */
    function returnImplementationAtIndex(uint index) public view returns(address) {
        return validImplementations.keyAtIndex(index);
    }
}

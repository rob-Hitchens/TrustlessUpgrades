pragma solidity 0.5.1;

/**
 * @title Upgradable
 * @author Rob Hitchens
 * @notice Inheritable upgradable properties.
 */

interface UpgradableInterface {
    function componentUid() external returns(bytes32);
}

contract Upgradable {
    
    bytes32 internal COMPONENT_UID;
    
    constructor(bytes32 componentUid) public {
        COMPONENT_UID = componentUid;
    }
    
    function componentUid() public view returns(bytes32) {
        return COMPONENT_UID;
    }
}

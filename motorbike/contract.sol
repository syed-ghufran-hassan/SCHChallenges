// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice Ethernaut #25. This level is configured for the pre-Cancun Shanghai EVM.
contract Motorbike {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address logic) public {
        require(_isContract(logic), "logic must be a contract");
        _setImplementation(logic);
        (bool ok,) = logic.delegatecall(abi.encodeWithSignature("initialize()"));
        require(ok, "init failed");
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    function _implementation() internal view returns (address implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            implementation := sload(slot)
        }
    }

    function _setImplementation(address implementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, implementation)
        }
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _isContract(address account) internal view returns (bool size) {
        assembly {
            size := extcodesize(account)
        }
    }
}

contract Engine {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;
    bool private initialized;

    function initialize() external {
        require(!initialized, "initialized");
        initialized = true;
        horsePower = 1000;
        upgrader = msg.sender;
    }

    function upgradeToAndCall(address next, bytes memory data) external payable {
        require(msg.sender == upgrader, "Can't upgrade");
        require(_isContract(next), "not contract");
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, next)
        }
        if (data.length != 0) {
            (bool ok,) = next.delegatecall(data);
            require(ok, "call failed");
        }
    }

    function _isContract(address account) internal view returns (bool size) {
        assembly {
            size := extcodesize(account)
        }
    }
}

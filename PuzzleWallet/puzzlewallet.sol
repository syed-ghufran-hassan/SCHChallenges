// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Small EIP-1967-style proxy sufficient for the Ethernaut storage collision exercise.
contract PuzzleProxy {
    address public pendingAdmin;
    address public admin;
    address private implementation;

    constructor(address admin_, address implementation_, bytes memory initData) {
        implementation = implementation_;
        (bool ok,) = implementation_.delegatecall(initData);
        require(ok, "init failed");
        admin = admin_;
    }

    function proposeNewAdmin(address next) external {
        pendingAdmin = next;
    }

    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 maximum) external {
        require(maxBalance == 0, "Already initialized");
        maxBalance = maximum;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function addToWhitelist(address account) external {
        require(msg.sender == owner, "Not owner");
        whitelisted[account] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool ok,) = to.call{value: value}(data);
        require(ok, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool deposited;
        for (uint256 i; i < data.length; ++i) {
            bytes4 selector;
            bytes memory callData = data[i];
            assembly { selector := mload(add(callData, 32)) }
            if (selector == this.deposit.selector) require(!deposited, "Deposit once");
            deposited = true;
            (bool ok,) = address(this).delegatecall(data[i]);
            require(ok, "delegatecall failed");
        }
    }

    function setMaxBalance(uint256 maximum) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = maximum;
    }
}

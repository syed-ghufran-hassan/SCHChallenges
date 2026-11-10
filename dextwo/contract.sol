// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal ERC-20 used to keep this level self-contained.
contract SwappableTokenTwo {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address private immutable dex;

    constructor(address dex_, uint256 supply) {
        dex = dex_;
        balanceOf[msg.sender] = supply;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address owner, address spender, uint256 amount) external returns (bool) {
        require(owner != dex, "InvalidApprover");
        allowance[owner][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (from != msg.sender) allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// @notice Ethernaut #23. The exchange accepts arbitrary token contracts as swap inputs.
contract DexTwo {
    address public token1;
    address public token2;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }

    function setTokens(address one, address two) external onlyOwner {
        token1 = one;
        token2 = two;
    }

    function addLiquidity(address token, uint256 amount) external onlyOwner {
        require(IToken(token).transferFrom(msg.sender, address(this), amount), "liquidity failed");
    }

    function swap(address from, address to, uint256 amount) external {
        require(IToken(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 output = getSwapAmount(from, to, amount);
        require(IToken(from).transferFrom(msg.sender, address(this), amount), "input failed");
        require(IToken(to).transferFrom(address(this), msg.sender, output), "output failed");
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return amount * IToken(to).balanceOf(address(this)) / IToken(from).balanceOf(address(this));
    }
}

interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Like {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @notice Deliberately permissive ERC-20 used only by this local challenge.
contract SwappableToken is IERC20Like {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(string memory tokenName, string memory tokenSymbol, uint256 initialSupply, address initialHolder) {
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = initialSupply;
        balances[initialHolder] = initialSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amount, "SwappableToken: allowance");
        allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(balances[from] >= amount, "SwappableToken: balance");
        balances[from] -= amount;
        balances[to] += amount;
    }
}

/// @notice Adapted from OpenZeppelin Ethernaut level 22. Reserve-ratio pricing
/// can be manipulated by repeatedly swapping the two listed assets.
contract Dex {
    address public token1;
    address public token2;

    function setTokens(address tokenOne, address tokenTwo) external {
        token1 = tokenOne;
        token2 = tokenTwo;
    }

    function addLiquidity(address tokenAddress, uint256 amount) external {
        IERC20Like(tokenAddress).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) external {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Dex: pair");
        require(IERC20Like(from).balanceOf(msg.sender) >= amount, "Dex: balance");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20Like(from).transferFrom(msg.sender, address(this), amount);
        IERC20Like(to).approve(address(this), swapAmount);
        IERC20Like(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return amount * IERC20Like(to).balanceOf(address(this)) / IERC20Like(from).balanceOf(address(this));
    }
}

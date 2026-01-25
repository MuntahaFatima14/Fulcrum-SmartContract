// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./CryptoCaffeine.sol";

contract CaffeineFactory {
    mapping(address => address) public journalistToContract;

    event InstanceCreated(address indexed journalist, address contractAddress);

    function createInstance() external {
        require(journalistToContract[msg.sender] == address(0), "Protocol already initialized");
        
        // Deploys the child contract and passes the journalist's address as owner
        CryptoCaffeine newInstance = new CryptoCaffeine(msg.sender);
        journalistToContract[msg.sender] = address(newInstance);
        
        emit InstanceCreated(msg.sender, address(newInstance));
    }
}
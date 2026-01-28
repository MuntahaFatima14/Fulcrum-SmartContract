// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract CryptoCaffeineBottle is Initializable {
    address public journalist;
    address public treasury; 
    string public iframeLink; 

    struct Memo { address from; uint64 timestamp; uint256 amount; string name; string message; }
    Memo[] private memos;

    error NotAuthorized();
    error TransferFailed();
    error InvalidAmount();

    constructor() { _disableInitializers(); }

    function initialize(address _journalist, address _treasury, string calldata _link) external initializer {
        journalist = _journalist;
        treasury = _treasury;
        iframeLink = _link;
    }

    // Accept ETH
    receive() external payable { _recordTip(msg.value, "Anonymous", "Direct"); }

    function buyCoffee(string calldata _name, string calldata _message) external payable {
        if (msg.value == 0) revert InvalidAmount();
        _recordTip(msg.value, _name, _message);
    }

    function buyDeveloperCoffee() external payable {
        if (msg.value == 0) revert InvalidAmount();
        (bool s, ) = payable(treasury).call{value: msg.value}("");
        if (!s) revert TransferFailed();
    }

    function _recordTip(uint256 _amt, string memory _n, string memory _m) private {
        memos.push(Memo(msg.sender, uint64(block.timestamp), _amt, _n, _m));
    }

    function withdraw() external {
        if (msg.sender != journalist) revert NotAuthorized();
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool s, ) = payable(journalist).call{value: bal}("");
            if (!s) revert TransferFailed();
        }
    }
    
    // Add this helper for testing
    function getMemos() external view returns (Memo[] memory) { return memos; }
}

contract CaffeineFactory {
    address public immutable implementation;
    address public immutable treasury; 
    address[] public allJars;

    event JarCreated(address indexed journalist, address jarAddress, string iframeLink);
    error InvalidImplementation();

    constructor(address _implementation, address _treasury) {
        if (_implementation == address(0)) revert InvalidImplementation();
        implementation = _implementation;
        treasury = _treasury;
    }

    function createJar(string calldata _iframeLink) external returns (address) {
        address clone = Clones.clone(implementation);
        CryptoCaffeineBottle(payable(clone)).initialize(msg.sender, treasury, _iframeLink);
        allJars.push(clone);
        emit JarCreated(msg.sender, clone, _iframeLink);
        return clone;
    }
}
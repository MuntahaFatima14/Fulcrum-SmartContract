// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CryptoCaffeineBottle
 * @dev Implementation contract for a tipping system. Uses Initializable for proxy compatibility.
 */
contract CryptoCaffeineBottle is Initializable, ReentrancyGuard {
    address public journalist; // The creator/owner who receives tips
    address public treasury;   // Protocol treasury for developer tips
    string public iframeLink;  // External link/metadata for the journalist's profile

    struct Memo { 
        address from; 
        uint64 timestamp; 
        uint256 amount; 
        string name; 
        string message; 
    }
    
    // List of all tips received by this specific jar
    Memo[] private memos;

    // Events allow off-chain applications (like a frontend) to react to new tips
    event NewMemo(address indexed from, uint256 amount, string name, string message);

    // Custom errors save gas compared to require(condition, "string error message")
    error NotAuthorized();
    error TransferFailed();
    error InvalidAmount();

    /// @dev Prevents the logic contract from being initialized directly.
    constructor() { _disableInitializers(); }

    /**
     * @notice Replaces the constructor for proxy clones.
     * @param _journalist The address that will own the jar and withdraw funds.
     * @param _treasury The address receiving developer tips.
     * @param _link Associated content link for this jar.
     */
    function initialize(address _journalist, address _treasury, string calldata _link) external initializer {
        journalist = _journalist;
        treasury = _treasury;
        iframeLink = _link;
    }

    /// @dev Fallback function to handle direct ETH transfers.
    receive() external payable {
        if (msg.value == 0) revert InvalidAmount();
        _recordTip(msg.value, "Anonymous", "Direct");
    }

    /**
     * @notice Primary function to send a tip with a message.
     * @param _name Name of the supporter.
     * @param _message Support message.
     */
    function buyCoffee(string calldata _name, string calldata _message) external payable {
        if (msg.value == 0) revert InvalidAmount();
        _recordTip(msg.value, _name, _message);
    }

    /**
     * @notice Specialized function to send a tip directly to the developer treasury.
     * @dev Uses .call{} to avoid gas limit issues with .transfer().
     */
    function buyDeveloperCoffee() external payable {
        if (msg.value == 0) revert InvalidAmount();
        (bool s, ) = payable(treasury).call{value: msg.value}("");
        if (!s) revert TransferFailed();
    }

    /// @dev Internal helper to update state and emit events.
    function _recordTip(uint256 _amt, string memory _n, string memory _m) private {
        memos.push(Memo(msg.sender, uint64(block.timestamp), _amt, _n, _m));
        emit NewMemo(msg.sender, _amt, _n, _m);
    }

    /**
     * @notice Allows the journalist to withdraw their accumulated tips.
     * @dev Protected by nonReentrant to prevent reentrancy attacks.
     */
    function withdraw() external nonReentrant {
        if (msg.sender != journalist) revert NotAuthorized();
        uint256 bal = address(this).balance;
        if (bal == 0) revert InvalidAmount();

        (bool s, ) = payable(journalist).call{value: bal}("");
        if (!s) revert TransferFailed();
    }
    
    /**
     * @notice Returns the full list of memos.
     * @dev Warning: This can hit gas limits if the array grows too large.
     */
    function getMemos() external view returns (Memo[] memory) {
        return memos;
    }

    /// @notice Returns total number of tips received.
    function getMemosCount() external view returns (uint256) {
        return memos.length;
    }
}
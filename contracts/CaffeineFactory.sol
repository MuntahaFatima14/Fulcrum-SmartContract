// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./CryptoCaffeineBottle.sol";

/**
 * @title CaffeineFactory
 * @dev Factory contract to deploy cheap 'Clones' (proxies) of the CryptoCaffeineBottle.
 */
contract CaffeineFactory {
    address public immutable implementation; // The master logic contract address
    address public immutable treasury;       // Set once at deployment
    address[] public allJars;                // Registry of all deployed jars

    event JarCreated(address indexed journalist, address jarAddress, string iframeLink);
    error InvalidImplementation();

    constructor(address _implementation, address _treasury) {
        if (_implementation == address(0)) revert InvalidImplementation();
        implementation = _implementation;
        treasury = _treasury;
    }

    /**
     * @notice Deploys a new tipping jar for a journalist.
     * @dev Uses EIP-1167 Minimal Proxy for extremely low-cost deployment.
     * @param _iframeLink The content link for the new journalist.
     * @return clone The address of the newly deployed jar.
     */
    function createJar(string calldata _iframeLink) external returns (address) {
        // Clones the logic contract without redeploying code, saving ~90% gas
        address clone = Clones.clone(implementation);
        
        // Initialize the new clone with journalist data
        CryptoCaffeineBottle(payable(clone)).initialize(msg.sender, treasury, _iframeLink);
        
        allJars.push(clone);
        emit JarCreated(msg.sender, clone, _iframeLink);
        return clone;
    }

    /// @notice Returns the total number of jars deployed through this factory.
    function getTotalJars() external view returns (uint256) {
        return allJars.length;
    }
}
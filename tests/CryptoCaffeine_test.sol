// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/CryptoCaffeine.sol";

/**
 * @title CryptoCaffeineTest
 * @dev Unit tests for the CryptoCaffeine system using the Remix Testing framework.
 */
contract CryptoCaffeineTest {
    CaffeineFactory factory;
    CryptoCaffeineBottle implementation;
    CryptoCaffeineBottle jar;
    
    address acc0; 
    address acc1; 

    /// @notice Sets up the initial state before any tests run.
    /// @dev The #value tag tells Remix to fund this contract with 2 ETH for testing.
    /// #value: 2000000000000000000
    function beforeAll() public payable {
        // Retrieve pre-funded accounts from the Remix environment
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);

        // 1. Deploy the "Master" logic contract
        implementation = new CryptoCaffeineBottle();
        
        // 2. Deploy the Factory, pointing it to the implementation and a treasury address
        factory = new CaffeineFactory(address(implementation), acc0);
    }

    /**
     * @notice Validates the Minimal Proxy (Clone) deployment flow.
     */
    function testDeploymentAndInitialization() public {
        // Ensure factory starts empty
        Assert.equal(factory.getTotalJars(), 0, "Initial jars should be 0");
        
        // Create a new jar instance
        address jarAddr = factory.createJar("https://news.com/profile");
        jar = CryptoCaffeineBottle(payable(jarAddr));

        // Check if the registry updated correctly
        Assert.equal(factory.getTotalJars(), 1, "Jar count should be 1");
        
        // Verify that the caller (this test contract) is recognized as the journalist
        Assert.equal(jar.journalist(), address(this), "Journalist should be test contract");
    }

    /**
     * @notice Tests the payment and memo-recording logic.
     * @dev The #value tag funds this specific function call with 1 ETH.
     * #value: 1000000000000000000
     */
    function testTipping() public payable {
        uint256 initialMemos = jar.getMemosCount();
        
        // Simulate a user buying coffee
        jar.buyCoffee{value: 1 ether}("Alice", "Keep up the work!");
        
        // Verify state changes
        Assert.equal(jar.getMemosCount(), initialMemos + 1, "Memo count should increase");
        Assert.equal(address(jar).balance, 1 ether, "Jar balance should be exactly 1 ETH");
    }

    /**
     * @notice Tests the journalist's ability to withdraw funds.
     */
    function testWithdrawSecurity() public {
        uint256 contractBalBefore = address(this).balance;
        
        // Execute the withdrawal
        jar.withdraw();
        
        // 1. Check that the jar is drained
        Assert.equal(address(jar).balance, 0, "Jar should be empty");
        
        // 2. Check that the funds arrived in this contract (the journalist)
        Assert.ok(address(this).balance > contractBalBefore, "Withdraw failed to send ETH");
    }
}

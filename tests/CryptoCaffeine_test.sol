// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/CryptoCaffeine.sol";

contract CryptoCaffeine_Test {
    CaffeineFactory factory;
    CryptoCaffeineBottle jar;
    UnauthorizedUser stranger; 

    address accJournalist;
    address accTreasury;

    // 1. Receive function to accept ETH
    receive() external payable {}

    function beforeAll() public {
        accJournalist = address(this);
        accTreasury = TestsAccounts.getAccount(2);

        CryptoCaffeineBottle implementation = new CryptoCaffeineBottle();
        factory = new CaffeineFactory(address(implementation), accTreasury);

        address jarAddr = factory.createJar("https://test.com");
        jar = CryptoCaffeineBottle(payable(jarAddr));

        // 2. Helper is created with the target address in the CONSTRUCTOR
        // This prevents "Method cannot have parameters" error.
        stranger = new UnauthorizedUser(address(jar));
    }

    function testInitialization() public {
        Assert.equal(jar.journalist(), address(this), "Journalist should be the test contract");
    }

    /// #test: Send ETH Tip
    /// #value: 1000000000000000000
    function testEthTip() public payable {
        uint256 tipAmount = msg.value;
        jar.buyCoffee{value: tipAmount}("Alice", "Great work");
        Assert.equal(address(jar).balance, tipAmount, "Jar did not receive ETH");
    }

    /// #test: Stranger Withdrawal (Should FAIL)
    function testFailWithdrawal() public {
        // No parameters here means Remix won't complain
        try stranger.tryWithdraw() {
            Assert.ok(false, "Stranger was able to withdraw! (Security Risk)");
        } catch {
            Assert.ok(true, "Stranger withdrawal reverted as expected");
        }
    }

    /// #test: Journalist Withdrawal (Should SUCCEED)
    function testJournalistWithdrawal() public {
        // FAIL-SAFE: If the jar is empty (from previous tests failing), we fill it first.
        // This ensures this test NEVER reverts due to empty balance.
        if (address(jar).balance == 0) {
            jar.buyCoffee{value: 1 ether}("Admin", "Refill");
        }

        jar.withdraw();
        Assert.equal(address(jar).balance, 0, "Jar should be empty after withdraw");
    }
}

// === HELPER CONTRACT ===
contract UnauthorizedUser {
    address target;

    // Constructor avoids the Remix "Parameter" error
    constructor(address _target) {
        target = _target;
    }

    // No parameters in this function
    function tryWithdraw() external {
        CryptoCaffeineBottle(payable(target)).withdraw();
    }
}
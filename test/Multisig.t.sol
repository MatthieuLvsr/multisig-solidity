// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Multisig.sol";

contract MultisigTest is Test {
    Multisig public multisig;

    address[] public signers;
    address public signer1 = address(0x1);
    address public signer2 = address(0x2);
    address public signer3 = address(0x3);
    address public signer4 = address(0x4);
    address public nonSigner = address(0x5);

    function setUp() public {
        // Initialize signers
        signers = [signer1, signer2, signer3];

        // Deploy Multisig contract with 3 signers and 2 confirmations required
        multisig = new Multisig(signers, 2);
        vm.deal(address(multisig), 5 ether); // Fund contract with 5 ether
    }

    function testSignersInitialization() public {
        // Verify that signers are correctly initialized
        assertTrue(multisig.isSigner(signer1));
        assertTrue(multisig.isSigner(signer2));
        assertTrue(multisig.isSigner(signer3));
        assertFalse(multisig.isSigner(nonSigner));
    }

    function testSubmitTransaction() public {
        // Submit a transaction by a valid signer
        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "0x0");

        // Verify transaction details
        (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations) = multisig.transactions(0);
        assertEq(to, address(0x5));
        assertEq(value, 1 ether);
        assertEq(data, "0x0");
        assertFalse(executed);
        assertEq(confirmations, 0);
    }

    function testTransactionConfirmations() public {
        // Submit a transaction
        vm.prank(signer1);
        multisig.submitTransaction(address(0x5), 1 ether, "0x0");

        // Confirm the transaction by another signer
        vm.prank(signer2);
        multisig.confirmTransaction(0);

        // Verify the confirmation count
        (, , , , uint256 confirmations) = multisig.transactions(0);
        assertEq(confirmations, 1);

        // Verify that the transaction cannot be confirmed twice by the same signer
        vm.expectRevert("Transaction already confirmed");
        vm.prank(signer2);
        multisig.confirmTransaction(0);
    }

    function testExecuteTransaction() public {
        // Submit a transaction
        vm.prank(signer1);
        multisig.submitTransaction(signer1, 1 ether, "0x0");

        // Confirm the transaction by required signers
        vm.prank(signer2);
        multisig.confirmTransaction(0);
        vm.prank(signer3);
        multisig.confirmTransaction(0);

        // Verify that the transaction is executed
        (, , , bool executed, ) = multisig.transactions(0);
        assertTrue(executed);
        assertEq(signer1.balance, 1 ether);
    }

    function testAddSigner() public {
        // Add a new signer
        vm.prank(signer1);
        multisig.addSigner(signer4);

        // Verify that the new signer is added
        assertTrue(multisig.isSigner(signer4));
    }

    function testRemoveSigner() public {
        // Remove an existing signer
        vm.startBroadcast(signer1);
        multisig.addSigner(signer4);
        multisig.removeSigner(signer3);

        // Verify that the signer is removed
        assertFalse(multisig.isSigner(signer3));
    }

    function testInvalidTransactionExecution() public {
        // Try executing a non-existent transaction
        vm.expectRevert("Transaction does not exist");
        vm.prank(signer1);
        multisig.executeTransaction(0);
    }

    function testEventEmission() public {
        // Submit a transaction and check event
        vm.prank(signer1);
        vm.expectEmit(true, true, true, true);
        emit Multisig.TransactionSubmitted(0, address(0x5), 1 ether, "0x0");
        multisig.submitTransaction(address(0x5), 1 ether, "0x0");
    }

    function testNotASigner() public {
        // Attempt to submit a transaction by a non-signer
        vm.expectRevert("Not a signer");
        vm.prank(nonSigner);
        multisig.submitTransaction(nonSigner, 1 ether, "0x0");
    }

    function testAlreadyExecutedTransaction() public {
        // Submit and execute a transaction
        vm.prank(signer1);
        multisig.submitTransaction(address(signer1), 1 ether, "0x0");

        vm.prank(signer2);
        multisig.confirmTransaction(0);
        vm.prank(signer3);
        multisig.confirmTransaction(0);

        // Attempt to re-execute
        vm.prank(signer1);
        vm.expectRevert("Transaction already executed");
        multisig.executeTransaction(0);
    }

    function testInsufficientFunds() public {
        // Submit a transaction with insufficient contract balance
        vm.prank(signer1);
        multisig.submitTransaction(address(signer1), 10 ether, "0x0");

        vm.prank(signer2);
        multisig.confirmTransaction(0);
        vm.prank(signer3);
        vm.expectRevert("Transaction failed");
        multisig.confirmTransaction(0);

        // Execute should fail
    }
}

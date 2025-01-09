# Multisig Wallet

## Overview
The Multisig Wallet is a smart contract implemented in Solidity that allows secure management of funds and transactions through multi-signature functionality. It enforces a minimum number of confirmations before a transaction can be executed, ensuring a high level of security for shared funds.

## Features
- **Multi-Signature Functionality**: Requires multiple signers to approve a transaction before execution.
- **Transaction Proposals**: Signers can submit, confirm, and execute transactions.
- **Dynamic Signer Management**: Supports adding and removing signers while maintaining a minimum threshold.
- **Fallback Function**: Accepts ether deposits directly.

## Prerequisites
- **Minimum Signers**: At least 3 signers are required for the wallet to function.
- **Confirmations**: Transactions require at least 2 confirmations by default, configurable during deployment.

## Contract Details

### Constructor
Initializes the contract with a set of signers and the required number of confirmations.
```solidity
constructor(address[] memory _signers, uint256 _requiredConfirmations);
```
- **_signers**: Array of signer addresses.
- **_requiredConfirmations**: Number of confirmations required for a transaction.

### Events
- `TransactionSubmitted(uint256 indexed _txId, address indexed _to, uint256 _value, bytes _data)`
- `TransactionConfirmed(uint256 indexed _txId, address indexed _signer)`
- `TransactionExecuted(uint256 indexed _txId)`
- `SignerAdded(address indexed _newSigner)`
- `SignerRemoved(address indexed _removedSigner)`

### Public Functions

#### submitTransaction
Proposes a new transaction to the wallet.
```solidity
function submitTransaction(address _to, uint256 _value, bytes calldata _data) external;
```
- **_to**: Address of the recipient.
- **_value**: Ether value to send.
- **_data**: Calldata for the transaction.

#### confirmTransaction
Confirms a transaction proposed by another signer.
```solidity
function confirmTransaction(uint256 _txId) external;
```
- **_txId**: ID of the transaction to confirm.

#### addSigner
Adds a new signer to the wallet.
```solidity
function addSigner(address _newSigner) external;
```
- **_newSigner**: Address of the new signer.

#### removeSigner
Removes an existing signer from the wallet.
```solidity
function removeSigner(address _signer) external;
```
- **_signer**: Address of the signer to remove.

### Internal Functions

#### _executeTransaction
Executes a transaction after it has received the required confirmations.
```solidity
function _executeTransaction(uint256 _txId) private;
```
- **_txId**: ID of the transaction to execute.

## Usage

1. **Deploy the Contract**:
   Deploy the contract with an array of signer addresses and the required number of confirmations.

2. **Submit a Transaction**:
   Any signer can propose a transaction using `submitTransaction`.

3. **Confirm a Transaction**:
   Other signers must confirm the transaction using `confirmTransaction`.

4. **Execute a Transaction**:
   Once the required confirmations are met, the transaction is executed automatically.

5. **Manage Signers**:
   Add or remove signers dynamically using `addSigner` or `removeSigner` while maintaining the minimum signer requirement.

## Security Considerations
- Ensure all signers are trusted parties.
- Regularly review the list of signers and required confirmations.
- Avoid exposing private keys of signers.

## License
This project is licensed under the terms specified in the `SEE LICENSE IN LICENSE` SPDX declaration.

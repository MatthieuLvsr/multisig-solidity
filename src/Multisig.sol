// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract Multisig{

    uint256 public requiredConfirmations;
    mapping(address => bool) public isSigner;
    uint256 public constant MINIMAL_SIGNERS = 3;
    uint256 public signersCount;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!confirmations[_txId][msg.sender], "Transaction already confirmed");
        _;
    }

    event TransactionSubmitted(uint256 indexed _txId, address indexed _to, uint256 _value, bytes _data);
    event TransactionConfirmed(uint256 indexed _txId, address indexed _signer);
    event TransactionExecuted(uint256 indexed _txId);
    event SignerAdded(address indexed _newSigner);
    event SignerRemoved(address indexed _removedSigner);

    constructor(address[] memory _signers, uint256 _requiredConfirmations) {
        require(_signers.length >= MINIMAL_SIGNERS, "At least 3 signers required");
        require(_requiredConfirmations >= 2 && _requiredConfirmations <= _signers.length, "Invalid required confirmations");

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "Invalid signer address");
            require(!isSigner[signer], "Signer not unique");

            isSigner[signer] = true;
        }
        signersCount = _signers.length;

        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransaction(address _to, uint256 _value, bytes calldata _data) external onlySigner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));

        emit TransactionSubmitted(transactions.length - 1, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txId) 
        external 
        onlySigner 
        txExists(_txId) 
        notExecuted(_txId) 
        notConfirmed(_txId)
    {
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].confirmations += 1;

        emit TransactionConfirmed(_txId, msg.sender);

        if (transactions[_txId].confirmations >= requiredConfirmations) {
            executeTransaction(_txId);
        }
    }

    function executeTransaction(uint256 _txId) public txExists(_txId) notExecuted(_txId) {
        Transaction storage txn = transactions[_txId];

        require(txn.confirmations >= requiredConfirmations, "Insufficient confirmations");

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(_txId);
    }

    function addSigner(address _newSigner) external onlySigner {
        require(_newSigner != address(0), "Invalid address");
        require(!isSigner[_newSigner], "Already a signer");

        isSigner[_newSigner] = true;
        signersCount++;

        emit SignerAdded(_newSigner);
    }

    function removeSigner(address _signer) external onlySigner {
        require(isSigner[_signer], "Not a signer");
        require(signersCount > MINIMAL_SIGNERS, "Cannot have less than 3 signers");

        isSigner[_signer] = false;
        signersCount--;

        emit SignerRemoved(_signer);
    }

    receive() external payable {}
}
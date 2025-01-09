// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

/**
 * @title Multisig Wallet
 * @notice A multi-signature wallet contract to securely manage funds and transactions with multiple signers.
 * @dev This contract enforces a minimum number of confirmations before executing a transaction.
 */
contract Multisig{

/*//////////////////////////////////////////////////////////////
                           TYPES
//////////////////////////////////////////////////////////////*/

    /**
     * @dev Represents a transaction proposed by a signer.
     * @param to The address to which the transaction is sent.
     * @param value The amount of ether to send.
     * @param data The calldata for the transaction.
     * @param executed Indicates whether the transaction has been executed.
     * @param confirmations The number of confirmations the transaction has received.
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    /**
     * @notice The required number of confirmations for a transaction to be executed.
     */
    uint256 public requiredConfirmations;

    /**
     * @dev The minimum number of signers required for the wallet to function.
     */
    uint256 public constant MINIMAL_SIGNERS = 3;

    /**
     * @notice The current number of signers.
     */
    uint256 public signersCount;

    /**
     * @dev Mapping to track valid signer addresses.
     */
    mapping(address signer => bool isValid) public isSigner;

    /**
     * @dev Mapping to track confirmations for each transaction by signers.
     */
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /**
     * @notice List of all submitted transactions.
     */
    Transaction[] public transactions;

/*//////////////////////////////////////////////////////////////
                           EVENTS
//////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a transaction is submitted.
     * @param _txId The ID of the transaction.
     * @param _to The address to which the transaction is sent.
     * @param _value The amount of ether to send.
     * @param _data The calldata for the transaction.
     */
    event TransactionSubmitted(uint256 indexed _txId, address indexed _to, uint256 _value, bytes _data);

    /**
     * @dev Emitted when a transaction is confirmed by a signer.
     * @param _txId The ID of the transaction.
     * @param _signer The address of the signer who confirmed the transaction.
     */
    event TransactionConfirmed(uint256 indexed _txId, address indexed _signer);

    /**
     * @dev Emitted when a transaction is executed.
     * @param _txId The ID of the executed transaction.
     */
    event TransactionExecuted(uint256 indexed _txId);

    /**
     * @dev Emitted when a new signer is added.
     * @param _newSigner The address of the new signer.
     */
    event SignerAdded(address indexed _newSigner);

    /**
     * @dev Emitted when a signer is removed.
     * @param _removedSigner The address of the removed signer.
     */
    event SignerRemoved(address indexed _removedSigner);

/*//////////////////////////////////////////////////////////////
                           MODIFIERS
//////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensures that the caller is a valid signer.
     */
    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    /**
     * @dev Ensures that a transaction exists.
     * @param _txId The ID of the transaction.
     */
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    /**
     * @dev Ensures that a transaction has not been executed yet.
     * @param _txId The ID of the transaction.
     */
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    /**
     * @dev Ensures that the caller has not already confirmed the transaction.
     * @param _txId The ID of the transaction.
     */
    modifier notConfirmed(uint256 _txId) {
        require(!confirmations[_txId][msg.sender], "Transaction already confirmed");
        _;
    }

/*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with a set of signers and required confirmations.
     * @param _signers The array of initial signer addresses.
     * @param _requiredConfirmations The number of confirmations required for transactions.
     */
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

/*//////////////////////////////////////////////////////////////
                           FALLBACK
//////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the contract to receive ether.
     */
    receive() external payable {}

/*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
//////////////////////////////////////////////////////////////*/

    /**
     * @notice Submits a new transaction to the wallet.
     * @param _to The address to which the transaction is sent.
     * @param _value The amount of ether to send.
     * @param _data The calldata for the transaction.
     */
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

    /**
     * @notice Confirms a transaction by a signer.
     * @param _txId The ID of the transaction to confirm.
     */
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
            _executeTransaction(_txId);
        }
    }

    /**
     * @notice Adds a new signer to the wallet.
     * @param _newSigner The address of the new signer to add.
     */
    function addSigner(address _newSigner) external onlySigner {
        require(_newSigner != address(0), "Invalid address");
        require(!isSigner[_newSigner], "Already a signer");

        isSigner[_newSigner] = true;
        signersCount++;

        emit SignerAdded(_newSigner);
    }

    /**
     * @notice Removes an existing signer from the wallet.
     * @param _signer The address of the signer to remove.
     */
    function removeSigner(address _signer) external onlySigner {
        require(isSigner[_signer], "Not a signer");
        require(signersCount > MINIMAL_SIGNERS, "Cannot have less than 3 signers");

        isSigner[_signer] = false;
        signersCount--;

        emit SignerRemoved(_signer);
    }

/*//////////////////////////////////////////////////////////////
                        PRIVATE FUNCTION
//////////////////////////////////////////////////////////////*/

    /**
     * @dev Executes a transaction after it has received sufficient confirmations.
     * @param _txId The ID of the transaction to execute.
     */
    function _executeTransaction(uint256 _txId) private {
        Transaction storage txn = transactions[_txId];

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(_txId);
    }
}

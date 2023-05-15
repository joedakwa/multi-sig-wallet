// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Event emitted when a deposit is made to the contract
    event Deposit(address indexed sender, uint amount, uint balance);

    // Event emitted when a transaction is submitted
    event Submit(uint indexed txId);

    // Event emitted when an owner approves a transaction
    event Approve(address indexed owner, uint indexed txId);

    // Event emitted when an owner revokes their approval of a transaction
    event Revoke(address indexed owner, uint indexed txId);

    // Event emitted when a transaction is executed
    event Execute(uint indexed txId);

    // Represent a transaction
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // Store the addresses of the owners of the wallet
    address[] public owners; 
    // Mapping to keep track of which addresses are owners of the wallet
    mapping(address => bool) public isOwner; 
    // The number of required confirmations for a transaction to be executed
    uint public required;  

    // Store all of the transactions submitted to the wallet
    Transaction[] public transactions; 
    // Mapping to keep track of which owners have approved each transaction
    mapping(uint => mapping(address => bool)) public confirmations;   

    // checks whether the caller of the function is the owner
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    // checks whether a transaction with a given ID exists
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }
    // checks whether a transaction with a given ID has not been executed
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }
    // checks whether a transaction with a given ID has not been approved by the caller of the function
    modifier notApproved(uint _txId) {
        require(!confirmations[_txId][msg.sender], "tx already approved");
        _;
    }


    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    // Function that allows the contract to receive ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    // use callData for cheaper gas fees
    // This function allows the contract owner to submit a new transaction.
    // The transaction details are added to the transactions array and emitted through the Submit event.
    function submit(address _to, uint _value, bytes memory _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));

            emit Submit(transactions.length - 1);

    }

    // This function allows an owner to approve a transaction.
    // The confirmations mapping is updated with the owner's approval and emitted through the Approve event.
    function approve(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId) {
        confirmations[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);    
    }
    // This function is a helper function to get the number of confirmations for a given transaction.
    function _getConfirmationCount(uint _txId) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[_txId][owners[i]]) {
                count += 1;
            }
        }
        return count;


    }
    // This function allows the contract owner to execute a transaction once the required number of approvals is reached.
    // The transaction is marked as executed and the transaction details are sent to the recipient through a call.
    // An Execute event is emitted with the transaction ID.
    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(_getConfirmationCount(_txId) >= required, "cannot execute tx");

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit Execute(_txId);
    }
    // This function allows the contract owner to revoke their approval of a transaction.
    // The confirmations mapping is updated with the owner's revocation and emitted through the Revoke event.
    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "tx not approved");

        confirmations[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }


}
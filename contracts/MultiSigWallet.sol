// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event Submit(uint indexed txId);
    event Approve(uint indexed owner, address indexed txId);
    event Revoke(uint indexed owner, address indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

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

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    // use callData for cheaper gas fees
    function submit(address _to, uint _value, bytes memory _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));

            emit Submit(transactions.length - 1);

    }


    function Approve(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId) {
        confirmations[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);    
    }

    function _getConfirmationCount(uint _txId) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[_txId][owners[i]]) {
                count += 1;
            }
        }
        return count;


    }

    function Execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(_getConfirmationCount(_txId) >= required, "cannot execute tx");

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(_txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "tx not approved");

        confirmations[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }


}
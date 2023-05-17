// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    // Event emitted when a deposit is made to the contract
    event Deposit(address indexed sender, uint amount, uint balance);

    // Event emitted when a transaction is submitted
    event Submit(address indexed owner, uint indexed txId, address indexed to, uint value, bytes data);

    // Event emitted when an owner approves a transaction
    event Approve(address indexed owner, uint indexed txId);

    // Event emitted when an owner revokes their approval of a transaction
    event Revoke(address indexed owner, uint indexed txId);

    // Event emitted when a transaction is executed
    event Execute(address indexed owner, uint indexed txId);

    // Represent a transaction
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
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

    // addOwner() removeOwner() replaceOwner() add these functions later

    function deposit() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    // use callData for cheaper gas fees
    // This function allows the contract owner to submit a new transaction.
    // The transaction details are added to the transactions array and emitted through the Submit event.
    function submitTransaction(address _to, uint _value, bytes memory _data) external onlyOwner {
        
        uint txId = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            numConfirmations: 0,
            executed: false
        }));

            emit Submit(msg.sender, txId, _to, _value, _data);

    }

    // This function allows an owner to approve a transaction.
    // The confirmations mapping is updated with the owner's approval and emitted through the Approve event.
    function confirmTransaction(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId) {

        Transaction storage transaction = transactions[_txId];


        confirmations[_txId][msg.sender] = true;
        // transaction.isApproved[msg.sender] = true;
        transaction.numConfirmations += 1;

        emit Approve(msg.sender, _txId);    
    }
    // This function is a helper function to get the number of confirmations for a given transaction.
    // function _getConfirmationCount(uint _txId) private view returns (uint) {
    //     uint count = 0;
    //     for (uint i = 0; i < owners.length; i++) {
    //         if (confirmations[_txId][owners[i]]) {
    //             count += 1;
    //         }
    //     }
    //     return count;

    function getTransaction(uint _txId) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }


    // }
    // This function allows the contract owner to execute a transaction once the required number of approvals is reached.
    // The transaction is marked as executed and the transaction details are sent to the recipient through a call.
    // An Execute event is emitted with the transaction ID.
    function executeTransaction(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        // require(_getConfirmationCount(_txId) >= required, "cannot execute tx");

        Transaction storage transaction = transactions[_txId];
         
        require(transaction.numConfirmations >= required, "cannot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit Execute(msg.sender, _txId);
    }
    // This function allows the contract owner to revoke their approval of a transaction.
    // The confirmations mapping is updated with the owner's revocation and emitted through the Revoke event.
    function revokeTransaction(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "tx not approved");

        confirmations[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }


}


// function mint(
//     address to,
//     uint256 tokenId,
//     string memory tokenUri,
//     string memory digest,
//     uint8[] calldata sigV,
//     bytes32[] calldata sigR,
//     bytes32[] calldata sigS
// ) external {
//     require(sigV.length == sigR.length && sigR.length == sigS.length, "SCO2AToken: invalid signature lengths");
//     require(sigV.length >= 2, "SCO2AToken: at least two signatures required");

//     bytes32 hash = keccak256(abi.encodePacked(to, tokenId, tokenUri, digest));
//     uint256 validSignatureCount = 0;

//     for (uint256 i = 0; i < sigV.length; i++) {
//         address signer = ecrecover(hash, sigV[i], sigR[i], sigS[i]);
//         if (hasMultiSigRole(signer)) {
//             validSignatureCount++;
//         }
//     }

//     require(validSignatureCount >= 2, "SCO2AToken: insufficient valid signatures");

//     // Proceed with minting logic
// }

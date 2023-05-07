# multi-sig-wallet

When creating the contract, the owners and the required number of confirmations are specified. Each owner is identified by their Ethereum address. The contract includes functions for depositing funds, submitting transactions, approving transactions, and executing approved transactions.

To submit a transaction, an owner calls the submit() function with the recipient address, value, and data for the transaction. Each transaction is stored in the contract and can only be executed if the required number of owners have approved it.

To approve a transaction, an owner calls the approve() function with the transaction ID. Once the required number of owners have approved the transaction, any owner can call the execute() function to execute the transaction.

The contract also includes functions for revoking approval for a transaction and for checking the number of confirmations a transaction has received.

This MultiSigWallet contract can be used to manage funds securely and transparently with a group of owners, as each transaction requires multiple approvals before it can be executed.
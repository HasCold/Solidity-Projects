// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract MultiSig{
    address[] public owners;
    uint public numConfirmationsRequired;

    struct Transaction{
        address to;
        uint value;
        bool execute;
    }   

    // whether the transaction is confirmed or not
    mapping(uint => mapping(address => bool)) isConfirmed; // So, isConfirmed mapping allows you to check whether a particular person has confirmed their participation for a specific task. You can access it like isConfirmed[taskId][personAddress], where taskId is the ID of the task, and personAddress is the address of the person you're checking. If the value returned is true, it means the person has confirmed their participation for that task. If it's false, it means they haven't confirmed yet.   
    Transaction[] public transactions;

    event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners, uint _numConfirmationsRequired){
        require(_owners.length > 1, "Owner required must be greater than one");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "Number of confirmations are not inSync with the number of owners");

        for(uint i = 0; i < _owners.length; i++){
            require(_owners[i] != address(0), "Invalid Owner");  // The owners address should not be equal to 0 address
            owners.push(_owners[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function submitTransaction(address _to) public payable{
        require(_to != address(0), "Invalid Address Reciever's");
        require(msg.value > 0, "Transfered Amount Must Be Greater Than 0");

        uint transactionId = transactions.length;
        transactions.push(Transaction({to:_to, value: msg.value, execute: false}));
        emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    modifier isOwner(address _sender){
        bool _isOwner = false;
        for(uint i = 0; i < owners.length; i++){
            if(_sender == owners[i]){
                _isOwner = true;
                break;
            }
        }

        require(_isOwner, "Only Owner can perform this action");
        _;
    }

    function confirmTransaction(uint _transactionId) public isOwner(msg.sender){
        require(_transactionId < transactions.length, "Invalid Transaction ID");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction is already confirmed by the owner");
        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);

        if(isTransactionConfirmed(_transactionId)){
            executeTransaction(_transactionId);
        }
    }

    // The transaction is executed only when we have the minimum number of confirmation from the owners of the multiSig wallet

    function isTransactionConfirmed(uint _transactionId) view internal returns(bool){
        require(_transactionId < transactions.length, "Invalid Transaction ID");
        uint confirmationCount; // Initially zero

        for(uint i = 0; i < owners.length; i++){
            if(isConfirmed[_transactionId][owners[i]]){
                confirmationCount++;
            }
        }
        return confirmationCount >= numConfirmationsRequired;
    }

    function executeTransaction(uint _transactionId) public payable {  // Transferring fund to a particular address
        require(_transactionId < transactions.length, "Invalid Transaction ID");
        require(!transactions[_transactionId].execute, "Transaction is already executed");

        (bool ok,) = transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(ok, "Transaction Execution Failed");

        transactions[_transactionId].execute = true;
        emit TransactionExecuted(_transactionId);
    }
}
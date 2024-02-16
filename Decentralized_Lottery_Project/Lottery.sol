// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants;

    constructor(){  // The constructor functon will run only at the code compile time means it will execute only one time.
        // msg.sender and block both are our global variables. 
        manager = msg.sender;  // Through the msg.sender means our manager will control this particular account 
    }

    // receive is a special function which we can used for only one time in our smart-contract and it doesn't contain any arguments
    receive() external payable {
        require(msg.value == 2 ether, "The ether must be of 2 amount");  // Basically if this line is true then the second line execute.
        participants.push(payable(msg.sender)); // participants.push(payable(msg.sender)): After ensuring that the correct amount of Ether has been sent, this line adds the sender's address (msg.sender) to the participants array. The payable() function is used to explicitly convert msg.sender to a payable address. The participants array is declared as address payable[], which means it's an array of addresses that can receive Ether.
    }

    function getBalance() view public returns(uint){
        require(msg.sender == manager, "You are not the owner of this contract");  // Only manager will call this function
        return address(this).balance;  // yani is contract ke particular address ka balance send krdo 
    }

    function random() view public returns(uint){
        // For generating the random number we use keccak256() hashing algorithm just like the sha256() hashing algorithm  
        return uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, participants.length)));  // In simple terms, abi.encodePacked() is like putting different ingredients into a blender, blending them together, and then using the resulting mixture for some purpose, like cooking or hashing. It helps in combining different types of data into a single format so that they can be processed or used together effectively.
        // When you use block.number - 1, it represents the previous block number, because blocks are sequentially numbered starting from 0 (or 1, depending on the context). The reason we often use block.number - 1 in certain contexts, such as generating randomness, is because we want to refer to a past block whose content is already finalized and immutable
    }

    function selectWinner() public returns(address){
        require(msg.sender == manager, "This action can only performed by the manager");
        require(participants.length >= 3, "The participants must be greater than or equal to 3");
        
        uint r = random();
        uint index = r % participants.length;   //  -->>  6324626426236432646 / 2  = 1 (random number generate)

        address payable winner;
        winner = participants[index]; 
        winner.transfer(getBalance());

        // Resetting the participants
        participants = new address payable[](0); 

        return winner;
    }

}
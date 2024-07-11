// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract demo {
    struct Tweet{
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
    }

    struct Messages{
        uint256 id;
        string content;
        address sender;
        address receiver;
        uint256 timestamp;
    }

    uint256 public tweetCounter;
    uint256 public messageCounter;

    mapping(uint256 => Tweet) public tweets;
    mapping(address => uint256[]) public tweetsOf;
    mapping(address => mapping(address => Messages[])) public conversations;
    mapping(address => mapping(address => bool)) public operator;
    mapping(address => address[]) public following;  // List of users that I followed

    event OperatorUpdated(address indexed user, address indexed operator, bool indexed auth);

    function _tweet(address _from, string calldata _content) internal {
        require(_from != address(0), "Invalid Address");

        Tweet memory newTweet = Tweet({
            id: tweetCounter,
            author: _from,
            content: _content,
            timestamp: block.timestamp
        });

        tweets[tweetCounter] = newTweet;
        tweetsOf[_from].push(tweetCounter);
        tweetCounter++;
    }

    function sendMessage(address _from, address _to, string calldata _content) internal {
        require(_from != address(0), "Invalid Address");
        require(_to != address(0), "Invalid Address");

        Messages memory newMessage = Messages({
            id: messageCounter,
            content: _content,
            sender: _from,
            receiver: _to,
            timestamp: block.timestamp
        });

        conversations[_from][_to].push(newMessage);
        messageCounter++;
    } 

    function tweet(string calldata _content) public {
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        _tweet(msg.sender, _content);
    }

    function allowOperator(address _operator) public {
        require(_operator != address(0), "Invalid Address");
        operator[msg.sender][_operator] = true;
        emit OperatorUpdated(msg.sender, _operator, true);
    }

    function disAllowOperator(address _operator) public {
        require(_operator != address(0), "Invalid Address");
        operator[msg.sender][_operator] = false;
        emit OperatorUpdated(msg.sender, _operator, false);
    }

    modifier checkOperator(address _user){
        require(_user != address(0), "Invalid Address");
        require(operator[_user][msg.sender], "You are not authorized by the user");
        _;
    }

// tweetByOperator function, when someone calls it to tweet on behalf of another user (_from), they should pass the address of the user on whose behalf they are tweeting as the first argument (_from). The second argument (_content) should be the content of the tweet.
    function tweetByOperator(address _from, string calldata _content) public checkOperator(_from) {
        require(_from != msg.sender, "Operators cannot tweet on their own behalf");
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        _tweet(msg.sender, _content);
    }
}

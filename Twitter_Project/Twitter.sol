// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Twitter {
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
    event TweetEvent(address indexed from, string indexed content);
    event MessageEvent(address indexed from, address indexed to, string indexed content);
    event FollowedUser(address indexed user, address indexed followed);

    function _tweet(address _from, string memory _content) internal {
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

        emit TweetEvent(_from, _content);
    }

    function _sendMessage(address _from, address _to, string memory _content) internal {
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
        emit MessageEvent(_from, _to, _content);
    } 

    function tweet(string memory _content) public {
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
    function tweetByOperator(address _from, string memory _content) public checkOperator(_from) {
        require(_from != msg.sender, "Operators cannot tweet on their own behalf");
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        _tweet(_from, _content);
    }

    function sendMessage(string memory _content, address _to) public {
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        _sendMessage(msg.sender, _to, _content);   
    }

    function sendMessageByOperator(string memory _content, address _from, address _to) public checkOperator(_from) {
        require(bytes(_content).length > 0, "Tweet content cannot be empty");

        _sendMessage(_from, _to, _content);   
    }

    function follow(address _followed) public {
        require(_followed != address(0), "Invalid Address");
        following[msg.sender].push(_followed);

        emit FollowedUser(msg.sender, _followed);
    }

    function getLatestTweets(uint256 _count) public view returns (Tweet[] memory) {
        require(_count > 0, "Count must be greater than 0");
        require(_count <= tweetCounter, "Count exceeds total number of tweets");

        Tweet[] memory latestTweets = new Tweet[](_count);  // Initialize the length of an array
        uint256 index;

        for (uint256 i = tweetCounter; i > tweetCounter - _count; i--){
            latestTweets[index] = tweets[i - 1];
            index++;
        }

        return latestTweets;
    }

    function getUserTweetIds(address _user) public view returns(uint256[] memory){
        return tweetsOf[_user];
    } 

    // mapping(uint256 => Tweet) public tweets;
    // mapping(address => uint256[]) public tweetsOf;
    function getLatestTweetsOf(address _user, uint _count) public view returns(Tweet[] memory) {
        require(_user != address(0), "Invalid Address");
        require(_count > 0, "Count must be greater than 0");
        require(_count <= tweetCounter, "Count exceeds total number of tweets");
        require(tweetsOf[_user].length >= _count, "No tweets by this user");
        
        uint256[] memory uniqueTweetIds = getUserTweetIds(_user);
        Tweet[] memory userTweets = new Tweet[](_count); // Initialize the length of an array suppose _count = 3 so the Tweet array has 3 indexing(0, 1, 2)

        for(uint256 i; i < _count; i++){
            userTweets[i] = tweets[uniqueTweetIds[uniqueTweetIds.length - 1 - i]];
        }

        return userTweets;
    }
}

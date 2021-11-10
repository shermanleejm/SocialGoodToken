pragma solidity >=0.5.16;
// SPDX-License-Identifier: MIT

// parties involed
// 1. SocialGoodCompany (i.e. us lmao)
// 2. Participant (e.g. manufacturing companies in carbon offset, schools whose students and the target)
// 3. Individual investors
// 4. Government (for encashing purposes (only for participants) --> converting tokens to monetary value)
// 5. Verifier

library SafeMath { 
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
      uint256 z = x + y;
      assert(z >= x);
      return z;
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
      assert(y <= x);
      return x - y;
    }
}

contract SocialGoodToken {
    using SafeMath for uint256;
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Buy(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event Sell(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event Encash(address participantAddress, uint256 amountOfTokens);
    event NewRecord(address participantAddress, string timestamp);
    event VerifiedRecord(address verifierAddress, string timestamp);
    
    uint8 public constant decimals = 18;  
    string public name = "SocialGoodToken";
    string public symbol = "SGT";
    uint256 totalSupply_ = 0;
    uint256 public ethTokenConversionRate = 1000;
    address public charity;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) delegates;

    constructor(uint256 total, string memory _name, string memory _symbol) {  
    	totalSupply_ = total;
    	name = _name;
    	symbol = _symbol;
    	balances[msg.sender] = totalSupply_;
    	charity = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function currentSupply() public view returns (uint256) {
	    return balances[charity];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function checkOwnBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    // basic transfer function 
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    // delegate transfer ability to us or charity
    function approve(address delegate, uint numTokens) public returns (bool) {
        delegates[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    // sets the amount allowed to be transferred 
    function allowance(address owner, address delegate) public view returns (uint) {
        return delegates[owner][delegate];
    }
    
    // transfer function for the delegate to execute
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= delegates[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        delegates[owner][msg.sender] = delegates[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    // buy tokens from us/charity
    // Exchnage rate = 1 wei to 5 tokens
    // buy: 50
    // msg.value = 10 wei
    // _amount = 50 tokens
    function buyTokens(uint256 _amount) public payable {
        require (msg.value * ethTokenConversionRate >= _amount, "Spend some to get some, yo");
        balances[charity] = balances[charity].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        ethTokenConversionRate = ethTokenConversionRate * 69 / 100;
        emit Buy(msg.sender, msg.value, _amount);
    }
    
    // sell tokens back to us/charity
    function sellTokens(uint _amount) public {
        require(balances[msg.sender] >= _amount, "You dont have enough tokens");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[charity] = balances[charity].add(_amount);
        payable(msg.sender).transfer(_amount / ethTokenConversionRate);
        emit Sell(msg.sender, _amount, _amount / ethTokenConversionRate);
        ethTokenConversionRate = ethTokenConversionRate / 69 * 100;
    }
    
    // cash out yo!
    function windfall() public {
        require(msg.sender == charity, "This is only for the charity to access");
        uint256 charityBalance = address(this).balance;
        require(charityBalance > 0, "Charity does not have enough");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH balance back to the owner");
    }

    // upload data from iot {hash: timestamp}
    // verify data 
    // student come in --> generate 1 token
    struct SocialGood {
        address participant;
        string hash;
        string timestamp;
    }
    mapping(address => SocialGood[]) participantSocialGoodMap;
    mapping(address => uint) participantSocialGoodSizes;
    mapping(address => bool) recordedParticipantsExists;
    address[] recordedParticipants;

    // Adds new participants 
    // users can sign up to become a verifier
    mapping (address => bool) public participantMap;
    function addNewParticipant(address participantAddress) public {
        require(msg.sender == charity, "This function is only for the owner to use");
        participantMap[participantAddress] = true;
    }

    function recordSocialGood(string memory _hash, string memory _timestamp) public {    
        require(participantMap[msg.sender] == true, "You are not a registered participant");  
        if (recordedParticipantsExists[msg.sender] == false) {
            recordedParticipantsExists[msg.sender] = true;
            recordedParticipants.push(msg.sender);
        }
        SocialGood memory sg = SocialGood({participant: msg.sender, hash:_hash, timestamp: _timestamp});
        participantSocialGoodMap[msg.sender].push(sg);
        participantSocialGoodSizes[msg.sender]++;
        emit NewRecord(msg.sender, _timestamp);
    }

    // returns timestamps for all the participants social good
    // verifiers use the timestamp and gathers the hashes for the particular timestamp
    function viewPendingSocialGood(address pAdd) public view returns (string[] memory) {
        uint _size = participantSocialGoodSizes[pAdd];
        require(_size > 0, "This participant has no social good to verify");
        string[] memory res = new string[](_size);
        for (uint i=0; i < _size; i++) {
            SocialGood storage sg = participantSocialGoodMap[pAdd][i];
            res[i] = sg.timestamp;
        }
        return res;
    }

    // Adds new verifiers 
    // users can sign up to become a verifier
    mapping (address => bool) public verifierMap;
    function addNewVerifier(address verifierAddress) public {
        require(msg.sender == charity, "This function is only for the owner to use");
        verifierMap[verifierAddress] = true;
    }

    // Verify
    // takes in an array of hashes ordered by timestamp from previous function
    // verifies hashes with participants hashes
    // valid hashes awards one token to participant
    // verifier gets a kickback
    function verifyPendingSocialGood(string[] memory valid, address pAdd) public {
        require(verifierMap[msg.sender] == true, "You are not a valid verifier. Please contact us to become one today!");
        require(recordedParticipantsExists[pAdd] == true, "Participant does not have any social good to verify");
        require(valid.length == participantSocialGoodMap[pAdd].length, "The input array is not the same length as the participant's");

        SocialGood[] memory toBeVerified = participantSocialGoodMap[pAdd];
        uint tokens = 0;
        uint invalidCount = 0;
        for (uint i=0; i < valid.length; i++) {
            if (keccak256(abi.encodePacked(valid[i])) == keccak256(abi.encodePacked(toBeVerified[i].hash))) {
                tokens++;
            } else {
                invalidCount++;
            }
        }
        
        // SocialGood[] memory invalid = new SocialGood[](invalidCount);
        // uint j = 0;
        // for (uint i=0; i < valid.length; i++) {
        //     if (keccak256(abi.encodePacked(valid[i])) != keccak256(abi.encodePacked(toBeVerified[i].hash))) {
        //         invalid[j] = toBeVerified[i];
        //         j++;
        //     }
        // }
        // participantSocialGoodMap[pAdd] = invalid;

        balances[pAdd] = balances[pAdd].add(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply_ = totalSupply_.add(tokens * 2);
    }

    // encash tokens --> destroy tokens
    // 1. buy token
    // 2. sell token to government for subisidies
    // 3. tokens that are sold gets destroyed
    function encash(uint256 amount) public {
        require(participantMap[msg.sender] == true, "You are not a registered participant");  
        require(balances[msg.sender] > amount, "You dont have enough tokens to encash"); 
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Encash(msg.sender, amount);
        totalSupply_ = totalSupply_.sub(amount);
    }
}


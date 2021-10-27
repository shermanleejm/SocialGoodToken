pragma solidity >=0.5.16;
// SPDX-License-Identifier: MIT

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
    
    uint8 public constant decimals = 18;  
    string public name = "SocialGoodToken";
    string public symbol = "SGT";
    uint256 totalSupply_;
    uint256 public ethTokenConversionRate = 100;
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
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
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
    function buyTokens() public payable returns (uint tokens) {
        require(msg.value > 0, "Gotta spend some to get some, yo");
        uint256 amountToBuy = msg.value * ethTokenConversionRate / 100;
        uint256 tokensLeft = balances[charity];
        require(tokensLeft >= amountToBuy, "sorry, we ran out of tokens please try again later or buy a smaller amount");
        (bool sent) = transferFrom(charity, msg.sender, amountToBuy);
        require(sent, "Failed to transfer tokens");
        emit Buy(msg.sender, msg.value, amountToBuy);
        ethTokenConversionRate = ethTokenConversionRate / 100 * 69;
        return amountToBuy;
    }
    
    // sell tokens back to us/charity
    function sellTokens(uint numTokens) public {
        require(numTokens > 0, "Please choose a non-zero amount");
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= numTokens, "You do not have enough tokens");
        uint256 ethRequired = numTokens / ethTokenConversionRate;
        uint256 ownerEthBalance = address(this).balance;
        require(ownerEthBalance >= ethRequired, "Sorry we do not have enough ETH for this transaction");
        (bool sent) = transferFrom(msg.sender, address(this), numTokens);
        require(sent, "Failed to transfer tokens");
        (sent,) = msg.sender.call{value: ethRequired}("");
        require(sent, "Failed to send ETH to seller");
        ethTokenConversionRate = ethTokenConversionRate * 100 / 69;
    }
    
    // cash out yo!
    function windfall() public {
        require(msg.sender == charity, "This is only for the charity to access");
        uint256 charityBalance = address(this).balance;
        require(charityBalance > 0, "Charity does not have enough");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH balance back to the owner");
    }
}


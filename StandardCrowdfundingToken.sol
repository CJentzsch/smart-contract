/*Most, basic default, standardised Token contract.
Allows the creation of a token with a finite issued amount to the creator.

Based on standardised APIs: https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs
*/

// this is just a combination of the StandardToken and the Crowdsale contract, workaround due to a bug in solidity 

contract StandardCrowdfundingToken {

    //explicitly not publicly accessible. Should rely on methods for purpose of standardization.
    mapping (address => uint) balances;
    mapping (address => mapping (address => bool)) approved;
    mapping (address => mapping (address => uint256)) approved_once;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AddressApproval(address indexed addr, address indexed proxy, bool result);
    event AddressApprovalOnce(address indexed addr, address indexed proxy, uint256 value);
	
	function Standard_Token(uint _initialAmount) {
        balances[msg.sender] = _initialAmount;
    }

    function transfer(uint _value, address _to) returns (bool _success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, uint _value, address _to) returns (bool _success) {
        if (balances[_from] >= _value) {
            bool transfer = false;
            if(approved[_from][msg.sender]) {
                transfer = true;
            } else {
                if(_value <= approved_once[_from][msg.sender]) {
                    transfer = true;
                    approved_once[_from][msg.sender] = 0; //reset
                }
            }

            if(transfer == true) {
                balances[_from] -= _value;
                balances[_to] += _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        } else { return false; }
    }

    function balanceOf(address _addr) constant returns (uint _r) {
        return balances[_addr];
    }

    function approve(address _addr) returns (bool _success) {
        approved[msg.sender][_addr] = true;
        AddressApproval(msg.sender, _addr, true);
        return true;
    }
    
    function unapprove(address _addr) returns (bool _success) {
        approved[msg.sender][_addr] = false;
        approved_once[msg.sender][_addr] = 0;
        //debatable whether to include...
        AddressApproval(msg.sender, _addr, false);
        AddressApprovalOnce(msg.sender, _addr, 0);
    }
    
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) {
        return approved[_target][_proxy];
    }

    function approveOnce(address _addr, uint256 _maxValue) returns (bool _success) {
        approved_once[msg.sender][_addr] = _maxValue;
        AddressApprovalOnce(msg.sender, _addr, _maxValue);
        return true;
    }

    function isApprovedOnceFor(address _target, address _proxy) constant returns (uint _maxValue) {
        return approved_once[_target][_proxy];
    }
    
    // Crowdfunding
    
    uint closingTime;                   // end of crowdfunding
    uint minValue;                      // minimal goal of crowdfunding
	uint totalAmountReceived;
	bool success;
	
	function Crowdfunding(uint _minValue, uint _closingTime) {
		closingTime = _closingTime;
		minValue = _minValue;
	}
	
	function receiveEther() {
		receiveEtherProxy(msg.sender);
	}
	
	function receiveEtherProxy(address originalSender) {
		if (now > closingTime)
			throw;
		balances[msg.sender] += msg.value;		
		totalAmountReceived += msg.value;
		if (totalAmountReceived >= minValue && !success)
			success = true;
	}
	
	// in the case the minimal goal was not reached, give back the money to the supporters
    function refund()
    {
         if (now > closingTime 
			 && this.balance < minValue 
			 && !success
			 && msg.sender.send(balances[msg.sender])) // execute refund 
         {
             balances[msg.sender] = 0;
         }
    }
}

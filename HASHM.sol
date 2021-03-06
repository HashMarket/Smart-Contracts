pragma solidity >=0.4.22 <0.6.0;

//REVISAR SECURITY

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract HASHMERC20 is owned {
    
    using SafeMath for uint256;
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    //This generates a public event on the blockchain that will notify clients 
    event FrozenFunds(address target, bool frozen);



     /// @notice Constrctor function: Initializes contract with initial supply tokens to the creator of the contract
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
    }
    
    
    
     /// @notice Gets the balance of the specified address.
     /// @param _owner The address to query the the balance of.
     /// @return An uint256 representing the amount owned by the passed address.
    function balanceAddress(address _owner) public view returns (uint256 balance) {
    return balanceOf[_owner];
    
    }


     /// @notice Function to check the amount of tokens that an owner allowed to a spender.
     /// @param _owner address The address which owns the funds.
     /// @param _spender address The address which will spend the funds.
     /// @return A uint256 specifying the amount of tokens still available for the spender.
    function allowanceAddress(address _owner, address _spender) public view returns (uint256) {
    return allowance[_owner][_spender];
    
    }



    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                   // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);    // Check for overflows
        require(!frozenAccount[_from]);                         // Check if sender is frozen
        require(!frozenAccount[_to]);                           // Check if recipient is frozen
        balanceOf[_from] -= _value;                             // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }


   
     /// @notice Transfer tokens: Send `_value` tokens to `_to` from your account
     /// @param _to The address of the recipient
     /// @param _value the amount to send
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    

    
     /// @notice Transfer tokens from other addressSend `_value` tokens to `_to` in behalf of `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    
     /// @notice Set allowance for other address: Allows `_spender` to spend no more than `_value` tokens in your behalf
     /// @param _spender The address authorized to spend
     /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }




    /// @notice Increase the amount of tokens that an owner allowed to a spender.
        /// approve should be called when allowed[_spender] == 0. To increment
        /// allowed value is better to use this function to avoid 2 calls (and wait until
        /// the first transaction is mined)
    /// @param _spender The address which will spend the funds.
    /// @param _addedValue The amount of tokens to increase the allowance by.
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }



  
   /// @notice Decrease the amount of tokens that an owner allowed to a spender.
       /// approve should be called when allowed[_spender] == 0. To decrement
       /// allowed value is better to use this function to avoid 2 calls (and wait until
       /// the first transaction is mined)
   /// @param _spender The address which will spend the funds.
   /// @param _subtractedValue The amount of tokens to decrease the allowance by.
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowance[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowance[msg.sender][_spender] = 0;
    } else {
      allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }



     /// @notice Set allowance for other address and notify: Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     /// @param _spender The address authorized to spend
     /// @param _value the max amount they can spend
     /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }



     /// @notice Destroy tokens: Remove `_value` tokens from the system irreversibly
     /// @param _value the amount of money to burn
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


    
    
     /// @notice Destroy tokens from other account: Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     /// @param _from the address of the sender
     /// @param _value the amount of money to burn
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    
    
    
     /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
     /// @param target Address to be frozen
     /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    
    
     /// @notice Create `mintedAmount` tokens and send it to `target`
     /// @param target Address to receive the tokens
     /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }
    
    
    
}

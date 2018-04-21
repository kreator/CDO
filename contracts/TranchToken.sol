pragma solidity ^0.4.8;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/*
  Per Tranch ERC20 Token.
*/

contract TranchToken is StandardToken, Ownable {
    string public name = "TTKN";
    string public symbol = "TTKN";
    uint public decimals = 18;
    uint256 public totalSupply;

    function TranchToken(uint256 _totalSupply) public {
      owner = msg.sender;
      totalSupply = _totalSupply;
      balances[msg.sender] = _totalSupply;
    }

    /*
      Standard Token functional
    */
    function transfer(address _to, uint _value) public returns (bool success) {
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
      return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool success) {
      return super.approve(_spender, _value);
    }
}

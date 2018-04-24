pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "@dharmaprotocol/contracts/contracts/DebtToken.sol";
import "./TranchToken.sol";

contract Tranch is Ownable {
  address tranchToken;
  uint repaymentDate;
  uint instrestRatePercentage;

  /**
   * tranch token to principle token ratio. example 5 will mean 5 Tranchtokens are 1 principleToken
   * the formula for repayment is: ((amount / tokenRate) * (instrestRatePercentage + 100)/100)
   */
  uint tokenRate;


  modifier tranchRunning() {
      require(repaymentDate > block.timestamp);
      _;
  }

  modifier tranchOver() {
      require(repaymentDate <= block.timestamp);
      _;
  }

  /**
  * will recieve all the parameters needed to create a blank CDO.
  */
  function Tranch(
    address _owner,
    uint _totalSupply,
    uint _repaymentDate,
    uint _instrestRatePercentage,
    uint _tokenRate
  )
    public
  {
    require(_repaymentDate > block.timestamp);
    owner = _owner;
    address _tranchToken = new TranchToken(_totalSupply);
    tranchToken = _tranchToken;
    repaymentDate = _repaymentDate;
    instrestRatePercentage = _instrestRatePercentage;
    tokenRate = _tokenRate;
  }

  function getTranchToken() public view returns(address) {
    return tranchToken;
  }

  function getInstrestRatePercentage() public view returns(uint) {
    return instrestRatePercentage;
  }

  function getRepaymentDate() public view returns(uint) {
    return repaymentDate;
  }

  function getTokenRate() public view returns(uint) {
    return tokenRate;
  }

  /**
   * Returns the balance of an investor in this tranch
   */

  function getInvestorBalance(address _investor) public view returns(uint) {
    TranchToken tranchTokenInst = TranchToken(tranchToken);
    return tranchTokenInst.balanceOf(_investor);
  }

  /**
   * Pays investor the tranch tokens he is owed after making an investment
   */
  function payInvestor(
    address _investor,
    uint _principalAmount
  )
    tranchRunning()
    public
  {
    TranchToken tranchTokenInst = TranchToken(tranchToken);
    require(tranchTokenInst.transfer(_investor, _principalAmount*tokenRate));
  }

  /**
   * Pays back the investor with principle token after the tranch period has ended
   */
  function cashOutInvestor(address _investor)
    public
    tranchOver()
    returns(uint)
  {
    TranchToken tranchTokenInst = TranchToken(tranchToken);
    uint balance = tranchTokenInst.balanceOf(_investor);
    if (balance == 0) {
      return 0;
    }
    require(tranchTokenInst.transferFrom(_investor, this, balance));
    return balance;
  }
}

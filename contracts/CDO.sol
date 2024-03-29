pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "@dharmaprotocol/contracts/contracts/DebtToken.sol";
import "./Tranch.sol";

contract CDO is Ownable {
uint managmentFees;
uint managementFeesReleaseDate;
uint managementFeesDateIncrement;
uint CDOEndDate = 0;

/**
* the token we refer to as the principle.
* All CDO tranch tokens rates will refer to the amount of principleTokens Units
*/
address principalToken;

struct debtTokenEntry {
    address debtToken;
    uint tokenIssuanceHash;
}

debtTokenEntry[] public debtTokens;

address[] public tranchPartition;

event CDO_STARTED();

event RELEASED_MANAGEMENT_FEES();

event AQUIERED_NEW_DEBT(uint _tokenIssuanceHash, address _debtToken);

event INVESTMENT_WAS_MADE(uint _amount, address _investor, uint _tranchIndex);
// Event names should be CapWords InvestorWasRepayed
event INVESTOR_WAS_REPAYED(uint _amount, address _investor, uint _tranchIndex);

modifier CDONotStarted() {
    require(CDOEndDate == 0);
    _;
}

modifier CDORunning() {
    require(block.timestamp < CDOEndDate);
    _;
}

modifier CDOOver() {
    require(block.timestamp >= CDOEndDate);
    _;
}

modifier canReleaseManagementFees() {
  require(block.timestamp >= managementFeesReleaseDate);
  _;
}

modifier tranchExists(uint tranchIndex) {
  require(tranchIndex < tranchPartition.length);
  _;
}

modifier debtTokenExists(uint _debtTokenIndex) {
  require(_debtTokenIndex < debtTokens.length);
  _;
}

/**
* Will recieve all the parameters needed to create a blank CDO.
*/
function CDO(
  uint _managmentFees,
  uint _managementFeesDateIncrement,
  address _principalToken
)
  public
{
    owner = msg.sender;
    managmentFees = _managmentFees;
    managementFeesDateIncrement = _managementFeesDateIncrement;
    // VULNERABILITY: Integer overflow, can potentially allow manager to siphon funds from the account
    // Should use safe math
    managementFeesReleaseDate = block.timestamp + managementFeesDateIncrement;
    principalToken = _principalToken;
}

/**
* gets the CDO ERC20 contract address of the principal Token
*/
// Automatic getter no?
function getPrincipalToken() public view returns(address) {
    return principalToken;
}

/**
* Returns the a tranch.
*/
// Automatic getter
function getTranchByIndex(uint _tranchIndex)
  public
  tranchExists(_tranchIndex)
  view
  returns(address)
{
    return tranchPartition[_tranchIndex];
}

/**
* Returns a debt token and it's issuance hash.
*/
// Automatic getter
function getDebtByIndex(uint _debtTokenIndex)
  public
  debtTokenExists(_debtTokenIndex)
  view
  returns(address,uint)
{
    debtTokenEntry memory currentDebt = debtTokens[_debtTokenIndex];
    return (currentDebt.debtToken, currentDebt.tokenIssuanceHash);
}

/**
* Uses dharma to recieve ownership of a debt token.
*/
function aquireNewDebt(
  address _tokenOwner,
  uint256 _tokenIssuanceHash,
  address _debtToken
)
  public
  onlyOwner()
  CDONotStarted()
{
    DebtToken debtTokenInst = DebtToken(_debtToken);
    debtTokenInst.transferFrom(_tokenOwner, this, _tokenIssuanceHash);
    debtTokens.push(debtTokenEntry(_debtToken, _tokenIssuanceHash));

    AQUIERED_NEW_DEBT(_tokenIssuanceHash, _debtToken);
}

/**
* Adds a new Tranch by deploying a Tranch contract and adding it to the tranch partition
*/
function addTranch(
  uint _repaymentDate,
  uint _instrestRatePercentage,
  uint _tokenRate,
  uint _totalSupply
)
  public
  onlyOwner()
  CDONotStarted()
{
    address tranch = new Tranch(owner,
                                _totalSupply,
                                _repaymentDate,
                                _instrestRatePercentage,
                                _tokenRate);
    tranchPartition.push(tranch);
}

/**
* After all acquisitions are done. mints the new CDO token and enables purchase.
*/
function startCDO(
  uint _CDOEndDate
)
  onlyOwner()
  CDONotStarted()
  public
{
    require(_CDOEndDate > block.timestamp);
    CDOEndDate = _CDOEndDate;

    CDO_STARTED();
}

/**
* This will happen after the investor allowed the CDO to pull funds
* If the pulling of funds was succesful it will trasfer it the CDO tokens in exchange
*/
function invest(
  uint _principalAmount,
  address _investor,
  uint _tranchIndex
)
  CDORunning()
  tranchExists(_tranchIndex)
  public
{
    Tranch tranchInst = Tranch(tranchPartition[_tranchIndex]);
    ERC20 principalTokenInst = ERC20(principalToken);
    require(principalTokenInst.transferFrom(_investor, this, _principalAmount));
    tranchInst.payInvestor(_investor, _principalAmount);

    INVESTMENT_WAS_MADE(_principalAmount, _investor, _tranchIndex);
}

/**
* Checks if the tranch period is over and investor has tokens and is in the tranch.
* if so: sends the investors funds according to the token amount and tokenETWHRate
*/
function repayInvestor(
  address _investor,
  uint _tranchIndex
)
  tranchExists(_tranchIndex)
  public
{
    Tranch tranchInst = Tranch(tranchPartition[_tranchIndex]);
    uint balanceOfInvestor = tranchInst.cashOutInvestor(_investor);
    require(balanceOfInvestor > 0);

    ERC20 principalTokenInst = ERC20(principalToken);
    uint tokenRate = tranchInst.getTokenRate();
    uint instrestRatePercentage = tranchInst.getInstrestRatePercentage();
    // in case investor has funds, refund him fully with intrest
    uint principalToRepay = ((balanceOfInvestor / tokenRate) * (instrestRatePercentage + 100)/100);
    require(principalTokenInst.transferFrom(this, _investor, principalToRepay));

    INVESTOR_WAS_REPAYED(principalToRepay, _investor, _tranchIndex);
}

/**
* Restores funds to the owner at the end of the CDO or under other conditions maybe
*/
// What's the purpose of this
function repayOwner()
  CDOOver()
  public
{
    ERC20 principalTokenInst = ERC20(principalToken);
    principalTokenInst.transfer(owner, principalTokenInst.balanceOf(this));
}

/**
* Releases the management fees to the CDO Owner.
* This function will transfer fees one time only for each management fee period that has passsed.
*/
function releaseManagementFees()
  CDORunning()
  canReleaseManagementFees()
  public
{
    ERC20 principalTokenInst = ERC20(principalToken);
    require(principalTokenInst.transferFrom(this, owner, managmentFees));
    managementFeesReleaseDate += managementFeesDateIncrement;

    RELEASED_MANAGEMENT_FEES();
}
}

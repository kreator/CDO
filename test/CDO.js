var CDO = artifacts.require("../contracts/CDO");
var ERC20 = artifacts.require("../contracts/TranchToken");
var DebtToken = artifacts.require("@dharmaprotocol/contracts/contracts/DebtToken");
var DebtRegistry = artifacts.require("@dharmaprotocol/contracts/contracts/DebtRegistry");


contract('CDO test', async (accounts) => {
  let CDOInst;
  let ERC20Addr;
  let ERC20Inst;
  let debtTokenInst;

  beforeEach("Initialize", async () => {
    CDOInst = await CDO.deployed();
    ERC20Addr = await CDOInst.getPrincipalToken.call();
    ERC20Inst = await ERC20.at(ERC20Addr);
    debtTokenInst = await DebtToken.deployed();
    registryInst = await DebtRegistry.deployed();
  });

  it("account[0] is the sole owner of all tokens in CDO", async () => {
    let balance = await ERC20Inst.balanceOf.call(accounts[0]);
    let totalSupply = await ERC20Inst.totalSupply.call();
    assert.equal(balance.valueOf(), totalSupply);
  });

  it("account[0] is the owner of the debt tokens", async () => {
    let owner = await debtTokenInst.owner.call();
    assert.equal(owner, accounts[0]);
  });

  it("Can Add and remove authorizations to mint debt tokens", async () => {
    await debtTokenInst.addAuthorizedMintAgent(accounts[0], {from: accounts[0]});
    let agents = await debtTokenInst.getAuthorizedMintAgents.call();

    await debtTokenInst.revokeMintAgentAuthorization(accounts[0], {from: accounts[0]});
    agents = await debtTokenInst.getAuthorizedMintAgents.call();

    assert.equal(agents.length, 0);
  });

  it("Mint 3 debt tokens to account[0], approve to CDO and aquire by CDO", async () => {
    await debtTokenInst.addAuthorizedMintAgent(accounts[0], {from: accounts[0]});

    await registryInst.addAuthorizedInsertAgent(debtTokenInst.address, {from: accounts[0]});
    await registryInst.addAuthorizedEditAgent(debtTokenInst.address, {from: accounts[0]});

    let watcher = registryInst.LogInsertEntry();
    await debtTokenInst.create(accounts[0], accounts[0], accounts[0], accounts[0], 10, accounts[0], "0x123456", 1, {from: accounts[0]});
    let events = watcher.get();

    watcher = registryInst.LogInsertEntry();
    await debtTokenInst.create(accounts[0], accounts[0], accounts[0], accounts[0], 10, accounts[0], "0x123456", 2, {from: accounts[0]});
    events.push(watcher.get()[0]);

    watcher = registryInst.LogInsertEntry();
    await debtTokenInst.create(accounts[0], accounts[0], accounts[0], accounts[0], 10, accounts[0], "0x123456", 3, {from: accounts[0]});
    events.push(watcher.get()[0]);

    let tokenIDs = events.map((val) => {
      return val.args.issuanceHash;
    });

    //makes sure the tokens were properly minted
    assert.equal(tokenIDs.length, 3);

    //grant CDO allowance to get the tokens
    await debtTokenInst.setApprovalForAll(CDOInst.address, true, {from: accounts[0]});
    let approved = await debtTokenInst.isApprovedForAll.call(accounts[0], CDOInst.address);
    assert(approved);

    //Make CDO aquire the debts
    await CDOInst.aquireNewDebt(accounts[0], tokenIDs[0], debtTokenInst.address, {from: accounts[0]});
    await CDOInst.aquireNewDebt(accounts[0], tokenIDs[1], debtTokenInst.address, {from: accounts[0]});
    await CDOInst.aquireNewDebt(accounts[0], tokenIDs[2], debtTokenInst.address, {from: accounts[0]});

    //checks that CDO owns the debtToken
    let owner = await debtTokenInst.ownerOf.call(tokenIDs[0]);
    assert.equal(owner, CDOInst.address);

    //checks the entry was properly entered
    let debtEntry = await CDOInst.getDebtByIndex.call(0);
    assert.equal(debtEntry[0], debtTokenInst.address);

    //Adding a senior and junior tranches
    await CDOInst.addTranch(1546293600000, 15, 4, 1000, {from: accounts[0]});
    await CDOInst.addTranch(1556293600000, 20, 4, 1000, {from: accounts[0]});

    //checks the tranches were added
    let jrTranchAddr = await CDOInst.getTranchByIndex(0);
    let srTranchAddr = await CDOInst.getTranchByIndex(1);

    //console.log(jrTranchAddr + "\n" + srTranchAddr);

    /**
    * a test for the investment part is still missing and needs to be implemented here.
    */
  });

  /**
  * Add A test for the Managmenet Fees mechanism needs to be implemented here.
  */

});

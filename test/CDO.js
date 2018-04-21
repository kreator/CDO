var CDO = artifacts.require("../contracts/CDO");
var ERC20 = artifacts.require("../contracts/TranchToken");

contract('CDO test', async (accounts) => {

  it("account[0] is the sole owner of all tokens in CDO", async () => {
     let CDOInst = await CDO.deployed();
     let ERC20Addr = await CDOInst.getPrincipalToken.call();
     let ERC20Inst = await ERC20.at(ERC20Addr);
     let balance = await ERC20Inst.balanceOf.call(accounts[0]);
     let totalSupply = await ERC20Inst.totalSupply.call();
     assert.equal(balance.valueOf(), totalSupply);
  });
});

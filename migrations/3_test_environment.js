var DebtToken = artifacts.require("@dharmaprotocol/contracts/contracts/DebtToken");
var DebtRegistry = artifacts.require("@dharmaprotocol/contracts/contracts/DebtRegistry");

module.exports = function(deployer) {
  deployer.deploy(DebtRegistry).then(async () => {
        await deployer.deploy(DebtToken, DebtRegistry.address);
        console.log(DebtToken.address)
  });
}

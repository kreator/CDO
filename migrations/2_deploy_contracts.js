var CDO = artifacts.require("../contracts/CDO");

module.exports = function(deployer) {
  deployer.deploy(CDO,1,5,"0x5d97d0046588785606f19384c67798a9abc3feeb");
};

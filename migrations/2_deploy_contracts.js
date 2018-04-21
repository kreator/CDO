var CDO = artifacts.require("../contracts/CDO");

module.exports = function(deployer) {
  deployer.deploy(CDO,1,5,"0xa2382c577081630fec3fc2d7c972d144e40b831f");
};

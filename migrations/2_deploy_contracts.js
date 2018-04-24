var CDO = artifacts.require("../contracts/CDO");

module.exports = function(deployer) {
  //for testing, insert the address of a dummy token from the dharma charta deployment
  //for production, insert the address of the real address of the principal token
  deployer.deploy(CDO,1,5,"0xa2382c577081630fec3fc2d7c972d144e40b831f");
};

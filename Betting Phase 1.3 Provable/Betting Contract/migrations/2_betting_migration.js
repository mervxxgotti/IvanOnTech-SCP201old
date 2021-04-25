const Betting = artifacts.require("Betting");

module.exports = function(deployer, networks, accounts) {

  var config = {
    value: web3.utils.toWei("0.05", "ether"),
    from: accounts[0]
  };

  deployer.deploy(Betting, config);
};

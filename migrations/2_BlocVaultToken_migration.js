const BVToken = artifacts.require("COFFATOToken");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(BVToken, { from: accounts[0] });
};
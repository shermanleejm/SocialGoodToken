const Migrations = artifacts.require("SocialGoodToken");

module.exports = function (deployer) {
  deployer.deploy(Migrations, 100000, "Exon Mobil Sucks", "EMS");
};

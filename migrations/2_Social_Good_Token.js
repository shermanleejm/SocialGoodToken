const Migrations = artifacts.require("SocialGoodToken");

module.exports = function (deployer) {
  deployer.deploy(Migrations, 100000, "Exon_Mobil_Sucks", "EMS");
};

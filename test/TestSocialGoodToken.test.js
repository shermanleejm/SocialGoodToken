const SocialGoodToken = artifacts.require('SocialGoodToken');

contract('SocialGoodToken', function (accounts) {
  let sgt;
  let expected;
  let owner = accounts[0];
  let verifier = accounts[1];
  let buyer = accounts[2];
  let participant = accounts[3];

  before(async () => {
    sgt = await SocialGoodToken.deployed();
  });

  describe('basic functions', async () => {
    it('can get initial supply', async () => {
      const init_supply = await sgt.currentSupply();
      assert.equal(init_supply, 100000);
    });

    it('can transfer tokens to buyer', async () => {
      await sgt.transfer(buyer, 69);
      let checkBalance = await sgt.checkOwnBalance({ from: buyer });
      assert.equal(checkBalance, 69);
    });
  });
});

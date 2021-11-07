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

    it('can buy tokens using buyer account', async () => {
      await sgt.buyTokens(69, { from: buyer, value: 50 });
      let newTokenBalance = await sgt.checkOwnBalance({ from: buyer });
      assert.equal(newTokenBalance, 69 * 2);
    });
  });

  describe('verifier and mining', async () => {
    let socialGoodRecords = [
      ['abc', '1234'],
      ['def', '1235'],
      ['ghi', '1236'],
    ];

    it('can add new verifier', async () => {
      await sgt.addNewVerifier(verifier);
      let checkVerifier = await sgt.verifierMap.call(verifier);
      assert.equal(true, checkVerifier);
    });

    it('can record multiple social good as participant', async () => {
      for (let i = 0; i < socialGoodRecords.length; i++) {
        let record = await sgt.recordSocialGood(
          socialGoodRecords[i][0],
          socialGoodRecords[i][1],
          {
            from: participant,
          }
        );
        assert.equal(record.logs[0].args.participantAddress, participant);
        assert.equal(record.logs[0].args.timestamp, socialGoodRecords[i][1]);
      }
    });
  });
});

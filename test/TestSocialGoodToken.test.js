const SocialGoodToken = artifacts.require('SocialGoodToken');

contract('SocialGoodToken', function (accounts) {
  let sgt;
  let expected;
  let owner = accounts[0]; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
  let verifier = accounts[1]; // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
  let buyer = accounts[2]; // 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
  let participant = accounts[3]; // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
  const INITIAL_SUPPLY = 100000;

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

    it('can sell tokens using buyer account', async () => {
      await sgt.sellTokens(6, { from: buyer });
      let newTokenBalance = await sgt.checkOwnBalance({ from: buyer });
      assert.equal(newTokenBalance.toNumber(), 132);
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

    it('can add new participant', async () => {
      await sgt.addNewParticipant(participant);
      let checkParticipant = await sgt.participantMap.call(participant);
      assert.equal(true, checkParticipant);
    });

    it('can record multiple social good using participant address', async () => {
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

    it('can verify participant social good records', async () => {
      let toVerify = [];
      for (let i = 0; i < socialGoodRecords.length; i++) {
        toVerify.push(socialGoodRecords[i][0]);
      }

      await sgt.verifyPendingSocialGood(toVerify, participant, {
        from: verifier,
      });

      let verifierNewBalance = await sgt.checkOwnBalance({ from: verifier });

      assert.equal(verifierNewBalance, 3);

      let newTotalSupply = await sgt.totalSupply();
      assert.equal(newTotalSupply.toNumber(), INITIAL_SUPPLY + toVerify.length * 2);
    });
  });

  describe('encashment', async () => {
    it('will decrease total supply when encashing', async () => {
      let encashTokens = 69;
      await sgt.encash(encashTokens);
      let newTotal = await sgt.totalSupply();
      assert.equal(newTotal.toNumber(), INITIAL_SUPPLY - encashTokens + 6);
    });
  });
});

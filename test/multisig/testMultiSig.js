const th = require('../lib/testHelper');
const should = th.should();

const MultiSig = artifacts.require('./MultiSig');

contract('MultiSig', ([owner, user1]) => {
  let multisig;

  beforeEach(async () => {
    multisig = await MultiSig.new();
  });

  describe('events', async () => {

    it('fires MultiSigSigned when signed', async () => {
      const {logs} = await multisig.sign(0, {from: user1});
      logs.length.should.equal(1);
      logs[0].event.should.equal('MultiSigSigned');
      logs[0].args.index.should.be.bignumber.equal(0);

      logs[0].args.signer.should.equal(user1);
    });

  });
});

const th = require('../lib/testHelper');
const should = th.should();
const {assertThrows} = th;

const MultiSig = artifacts.require('./multisig/MultiSig');
const MultiSigWallet = artifacts.require('./multisig/MultiSigWallet');
const MultiSigWalletMock = artifacts.require('./mocks/MultiSigWalletMock.sol');
const TestToken = artifacts.require('./mocks/TestERC20Mock');

contract('MultiSig', ([owner, user1, user2, user3, user4, user5, user6]) => {
  const threeAccounts = [owner, user1, user2];
  const threeInvalidAccounts = [owner, user1, 0x0];
  let multisig;

  before(async () => await th.advanceBlock());
  beforeEach(async () => {
    multisig = await MultiSigWalletMock.new();
  });

  describe('events', async () => {

    it('fires MultiSigSigned when signed', async () => {
      console.log(threeAccounts);
      const {logs} = await multisig.sign(0, {from: user1, test: true});
      logs.length.should.equal(1);
      logs[0].event.should.equal('MultiSigSigned');
      logs[0].args.index.should.be.bignumber.equal(0);

      console.log(logs[0].args, user1);

      logs[0].args.signer.should.equal(user1);
    });

  });
});

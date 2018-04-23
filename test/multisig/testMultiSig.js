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
  let multiSigId;

  before(async () => await th.advanceBlock());
  beforeEach(async () => {
    multisig = await MultiSigWalletMock.new();
  });

  context('construction', async () => {
    context('failure', async () => {
      //
      it('does not allow us to create a new multisig with invalid args', async () => {
        await assertThrows(multisig.addMultiSigProxy(4, threeAccounts));
      });

      it('does not allow a signer to have 0x0 address', async () => {
        await assertThrows(multisig.addMultiSigProxy(2, threeInvalidAccounts));
      });
    });

    context('success', async () => {
      it('is deployable', async () => {
        await MultiSigWalletMock.new();
      });
      it('can create a new multisign with valid arguments 3/2', async () => {
        const multisig = await MultiSigWalletMock.new();
        await multisig.addMultiSigProxy(2, threeAccounts);
      });
    });
  });

  describe('with proxy instance', async () => {
    let multiSigId;
    beforeEach(async () => {
      const {logs} = await multisig.addMultiSigProxy(2, threeAccounts);
      multiSigId = logs[0].args.index.toNumber();
    });

    context('methods', async () => {
      it('hides private/internal functions', async () => {
        // silly test
        assert(!multisig.addMultiSig);
        assert(!multisig.signAs);
      });

      it('can get the quorum count', async () => {
        const quorumCount = await multisig.getQuorum(multiSigId);
        quorumCount.should.be.bignumber.equal(2);
      });

      it('can get the quorum signers', async () => {
        await multisig.addMultiSigProxy(2, threeAccounts);
        const signers = await multisig.getSigners(multiSigId);
        assert.deepEqual(signers, threeAccounts);
      });

      context('signing', async () => {
        it('can check if a signers has NOT signed', async () => {
          assert(!(await multisig.hasSigned(multiSigId, threeAccounts[0])));
        });

        it('can check if a signer has signed', async () => {
          await multisig.sign(0, {from: threeAccounts[0]});
          assert(await multisig.hasSigned(multiSigId, threeAccounts[0]));
        });
        it('does not allow owner to sign multiple times', async () => {
          await multisig.sign(0, {from: threeAccounts[1]});
          await th.assertThrows(
            multisig.sign(multiSigId, {from: threeAccounts[1]})
          );
        });
      });
    });
  });

  describe('with signing', async () => {
    let multiSigId;
    beforeEach(async () => {
      const {logs} = await multisig.addMultiSigProxy(2, threeAccounts);
      multiSigId = logs[0].args.index.toNumber();
    });

    context('completion', async () => {
      it('can tell when a wallet signing is complete', async () => {
        //
        assert(!(await multisig.isComplete(multiSigId)));
        await multisig.sign(multiSigId, {from: threeAccounts[0]});
        assert(!(await multisig.isComplete(multiSigId)));
        // await multisig.sign(multiSigId, {from: threeAccounts[1]});
        // assert(await multisig.isComplete(multiSigId));
      });
    });
  });

  describe('events', async () => {
    let multiSigId;
    beforeEach(async () => {
      const {logs} = await multisig.addMultiSigProxy(2, threeAccounts);
      multiSigId = logs[0].args.index.toNumber();
    });

    it('fires MultiSigAdded when creating a new MultiSig proxy', async () => {
      const {logs} = await multisig.addMultiSigProxy(2, threeAccounts);
      logs.length.should.equal(1);
      logs[0].event.should.equal('MultiSigAdded');
      logs[0].args.index.should.be.bignumber.equal(1); // previously added a multisig
      logs[0].args.quorum.should.be.bignumber.equal(2);
      assert.deepEqual(logs[0].args.signers, threeAccounts);
    });

    it('fires MultiSigSigned when signed', async () => {
      const {logs} = await multisig.sign(multiSigId, {from: user1});
      logs.length.should.equal(1);
      logs[0].event.should.equal('MultiSigSigned');
      logs[0].args.index.should.be.bignumber.equal(0);
      logs[0].args.signer.should.equal(user1);
    });

    it('fires MultiSigCompleted when complete');
    // it('fires MultiSigCompleted when complete', async () => {
    //   console.log(threeAccounts);
    //   let res = await multisig.addMultiSigProxy(2, threeAccounts);
    //   multiSigId = res.logs[0].args.index.toNumber();

    //   res = await multisig.sign(multiSigId, {from: user1});
    //   console.log(res.logs);
    // const {logs} = await multisig.sign(multiSigId, {
    //   from: owner
    // });
    // logs.length.should.equal(2);
    // logs[1].event.should.equal('MultiSigCompleted');
    // logs[1].args.index.should.be.bignumber.equal(0);
    // });
  });
});

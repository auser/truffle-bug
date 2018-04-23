pragma solidity ^0.4.18;

import '../multisig/MultiSig.sol';

/** A basic contract to test MultiSig functionality. */
contract MultiSigWalletMock is MultiSig {

    function addMultiSigProxy(uint _quarum, address[] _signers) public {
        super.addMultiSig(_quarum, _signers);
    }

    function signAsProxy(uint index, address signer) public {
        super.signAs(index, signer);
    }
}

pragma solidity ^0.4.18;

/*
MultiSig inheritable contract. Allows multiple one-off multisigs.

Usage:
1. Inherit main contract from MultiSig
2. Call addMultiSig with the expected signers each time a multisig is needed
3. Signers can call
*/

contract MultiSig {

    /***********************************************************
    * EVENTS
    ***********************************************************/

    event MultiSigSigned(uint index, address signer);

    function sign(uint index)
        public
    {
        emit MultiSigSigned(index, msg.sender);
    }

    function isComplete(uint index)
        public
        constant
        returns (bool)
    {
        return false;
    }

}

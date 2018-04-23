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

    event MultiSigAdded(uint index, uint quorum, address[] signers);
    event MultiSigSigned(uint index, address signer);
    event MultiSigCompleted(uint index);

    /***********************************************************
    * DATA
    ***********************************************************/

    struct MultiSigData {
        // the minimum number of signatures required to execute
        // must be at least 1; used to determine existence within multisigs mapping
        uint quorum;

        // the addresses that can sign
        address[] signers;

        // the signatures from signers
        mapping (address => bool) signatures;

        // record when a multisig is MultiSigcompleted to avoid recalculating every time
        bool completed;
    }

    MultiSigData[] internal multisigs;

    /***********************************************************
    * MODIFIERS
    ***********************************************************/

    // throw if a quorum of signatures has not been reached
    modifier onlyMultiSig(uint index) {
        require(!isComplete(index));
        _;
    }

    // only allow a signer to send message
    modifier onlySigners(uint index) {
        bool isSigner = false;
        for (uint i = 0; i < multisigs[index].signers.length; i++) {
            if (multisigs[index].signers[i] == msg.sender) {
                isSigner = true;
                break;
            }
        }
        require(isSigner);
        _;
    }

    // throw if requirements don't make sense
    modifier validRequirements(uint _quorum, address[] _signers) {
        require(
            _quorum > 0 &&
            _signers.length > 0 &&
            _quorum <= _signers.length
        );
        for (uint i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0));
        }
        _;
    }

    /***********************************************************
    * INTERNAL
    ***********************************************************/

    function addMultiSig(uint _quorum, address[] _signers)
        internal
        validRequirements(_quorum, _signers)
        returns(uint)
    {
        // autoincrement
        uint index = multisigs.length;

        // create new multisig
        multisigs.push(MultiSigData(_quorum, _signers, false));

        // log
        emit MultiSigAdded(index, _quorum, _signers);

        return index;
    }

    // sign as any address
    // INTERNAL ONLY
    // useful for relays or other abstraction methods
    function signAs(uint index, address signer)
        internal
        returns (bool)
    {

        // do not allow signer to sign more than once
        require(!multisigs[index].signatures[signer]);

        // record the new signature
        multisigs[index].signatures[signer] = true;

        // if already MultiSigcompleted, return immediately without firing events
        if (multisigs[index].completed) return;

        // log
        emit MultiSigSigned(index, signer);

        // check for completion
        if (isCompleteCheck(index)) {
            multisigs[index].completed = true;
            emit MultiSigCompleted(index);
        }
    }

    // returns true if a quorum of signatures has been reached
    function isCompleteCheck(uint index)
        internal
        constant
        returns(bool)
    {
        uint count = 0;
        for (uint i = 0; i < multisigs[index].signers.length; i++) {
            if (multisigs[index].signatures[multisigs[index].signers[i]]) {
                if (++count >= multisigs[index].quorum) {
                    return true;
                }
            }
        }
        return false;
    }

    /***********************************************************
    * NON-CONSTANT PUBLIC FUNCTIONS
    ***********************************************************/

    function sign(uint index)
        public
        onlySigners(index)
    {
        signAs(index, msg.sender);
    }

    /***********************************************************
    * CONSTANT FUNCTIONS
    ***********************************************************/

    // gets the quorum for a given multisig
    function getQuorum(uint index) public constant returns(uint) {
        return multisigs[index].quorum;
    }

    // gets the signers for a given multisig
    function getSigners(uint index) public constant returns(address[]) {
        return multisigs[index].signers;
    }

    // returns true if the given multisig has been MultiSigcompleted in O(1)
    function isComplete(uint index) public constant returns(bool) {
        return multisigs[index].completed;
    }

    // returns true if the given signer has MultiSigsigned
    function hasSigned(uint index, address signer) public constant returns(bool) {
        return multisigs[index].signatures[signer];
    }
}

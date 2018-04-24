pragma solidity ^0.4.21;

contract MultiSig {
    event MultiSigSigned(uint index, address signer);

    function sign(uint index)
        public
    {
        emit MultiSigSigned(index, msg.sender);
    }

}

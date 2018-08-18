pragma solidity ^0.4.23;

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ECRecovery.sol
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _v uint8 signer signature
   * @param _r bytes32 signer signature
   * @param _s bytes32 signer signature
   */
  function recover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s)
    internal
    pure
    returns (address)
  {
    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (_v < 27) {
      _v += 27;
    }

    // If the version is correct return the signer address
    if (_v != 27 && _v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(_hash, _v, _r, _s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}
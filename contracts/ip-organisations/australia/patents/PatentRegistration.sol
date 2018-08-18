pragma solidity ^0.4.23;

import "../../../util/Ownable.sol";
import "../../../storage/KeyValueStorage.sol";
import "./PatentToken.sol";

/**
 * @title PatentRegistration
 * @author Civic Ledger
 */
contract PatentRegistration is Ownable {

    // Central storage contract
    KeyValueStorage internal storageContract;
    uint256 internal ipoIndex = 0; 
    string internal ipRightTypeName = "Patent";

    /**
    * @dev PatentRegistration constructor
    * @param _storageAddress Address of central storage contract 
    */
    constructor(address _storageAddress) public {
        storageContract = KeyValueStorage(_storageAddress);
    }

    function tokenAddress()
        external
        view
        returns(address)
    {
        return storageContract.getAddress(keccak256("contract.name", "Token", ipoIndex, ipRightTypeName));
    }

    function claimIP() 
        public 
        returns(uint)
    {
        PatentToken patentToken = PatentToken(this.tokenAddress());
        return patentToken.mint(msg.sender);
    }

}
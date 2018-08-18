pragma solidity ^0.4.23;

import "../util/Ownable.sol";
import "../util/SafeMath.sol";
import "../storage/KeyValueStorage.sol";
import "../ip-organisations/IPOrganisations.sol";

/**
 * @title Marketplaces
 * @author Civic Ledger
 */
contract Marketplaces is Ownable {

    using SafeMath for uint256;

    KeyValueStorage internal storageContract;

    /// @dev Checks that sender is an authorised IPO account
    modifier onlyAuthorisedIPO(uint256 _ipoIndex, address _ipoAddress){
        IPOrganisations ipOrganisations = IPOrganisations(storageContract.getAddress(keccak256("contract.name", "IPOrganisations")));
        require(ipOrganisations.isAddressAuthorised(_ipoIndex, _ipoAddress));
        _;
    }

    /**
    * @dev constructor
    * @param _storageAddress Address of central storage contract 
    */
    constructor(address _storageAddress) public {
        storageContract = KeyValueStorage(_storageAddress);
    }

    /// @dev Get a marketplace by index
    /// @param _marketplaceIndex Index of the marketplace to retrieve
    function byIndex(uint256 _marketplaceIndex)
        external
        view
        returns(string, string, address, uint256)
    {
        return (
            storageContract.getString(keccak256("marketplace.name", _marketplaceIndex)),
            storageContract.getString(keccak256("marketplace.website", _marketplaceIndex)),
            storageContract.getAddress(keccak256("marketplace.address", _marketplaceIndex)),
            storageContract.getUint(keccak256("marketplace.registeringIPOIndex", _marketplaceIndex))
        );
    }

    // @dev Check an address is a registered marketplace
    // @param Address to check whether is is a registered marketplace
    function isRegistered(address _marketplaceAddress)
        external
        view
        returns(bool)
    {
        return storageContract.getBool(keccak256("marketplace.registered", _marketplaceAddress));
    }

    /// @dev Register a marketplace to be able to participate in IPRx
    /// @param _marketplaceName Name of the marketplace for display
    /// @param _marketplaceWebsiteUrl Url of the marketplaces website
    /// @param _marketplaceAddress Address of the marketplace
    /// @param _registeringIPOIndex Index of the registering IPO
    function register(string _marketplaceName, string _marketplaceWebsiteUrl, address _marketplaceAddress, uint256 _registeringIPOIndex)
        external
        onlyAuthorisedIPO(_registeringIPOIndex, msg.sender)
    {
        // name should not be empty
        require(bytes(_marketplaceName).length > 0);
        // url should not be empty
        require(bytes(_marketplaceWebsiteUrl).length > 0);
        // marketplace address should be not be null address
        require(_marketplaceAddress != 0x0);

        // get new marketplace index
        uint256 nextIndex = storageContract.getUint(keccak256("marketplaces.nextIndex"));
        // store details
        storageContract.setString(keccak256("marketplace.name", nextIndex), _marketplaceName);
        storageContract.setString(keccak256("marketplace.website", nextIndex), _marketplaceWebsiteUrl);
        storageContract.setAddress(keccak256("marketplace.address", nextIndex), _marketplaceAddress);
        storageContract.setUint(keccak256("marketplace.registeringIPOIndex", nextIndex), _registeringIPOIndex);
        
        // save reverse lookup
        storageContract.setUint(keccak256("marketplace.reverse", _marketplaceAddress), nextIndex);

        // save registered check
        storageContract.setBool(keccak256("marketplace.registered", _marketplaceAddress), true);

        // increment the marketplace index for next registration
        storageContract.setUint(keccak256("marketplaces.nextIndex"), nextIndex.add(1));
    }

}
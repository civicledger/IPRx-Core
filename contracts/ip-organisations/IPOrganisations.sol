pragma solidity ^0.4.23;

import "../util/Ownable.sol";
import "../util/SafeMath.sol";
import "../storage/KeyValueStorage.sol";

/**
 * @title IPOrganisations
 * @author Civic Ledger
 */
contract IPOrganisations is Ownable {

    using SafeMath for uint256;
    
    // contract for centralised storage
    KeyValueStorage internal storageContract;

    /// @dev Checks to make sure IPO exists
    /// @param _ipoIndex Index of IPO to check
    modifier onlyExistingIPO(uint256 _ipoIndex){
        require(this.exists(_ipoIndex));
        _;
    }

    /// @dev Checks to make sure sender is authorised admin
    /// @param _ipoIndex Index of IPO to check
    modifier onlyIPOAuthorisedAdmin(uint256 _ipoIndex){
        require(this.isAddressAuthorised(_ipoIndex, msg.sender));
        _;
    }

    /**
    * @dev constructor
    * @param _storageAddress Address of central storage contract 
    */
    constructor(address _storageAddress) public {
        storageContract = KeyValueStorage(_storageAddress);
    }

    /// @dev Retrieve an IP Organisation with a specific index
    /// @param _index Index of IP Organisation to retrieve
    function atIndex(uint256 _index)
        external
        view
        returns(string, string)
    {
        return (
            storageContract.getString(keccak256("ipOrganisation.name", _index)),    // Name
            storageContract.getString(keccak256("ipOrganisation.website", _index))  // Website
        );
    }

    /// @dev Checks if an IPO exists at the index provided
    /// @param _ipoIndex Index of the IPO to check existence
    function exists(uint256 _ipoIndex)
        external
        view
        returns(bool)
    {
        return storageContract.getBool(keccak256("ipOrganisation.exists", _ipoIndex));
    }

    /// @dev Add a new IP Organisation
    /// @param _name Name of the IP Organisation for display
    /// @param _websiteUrl Url of the IP Organisation's website
    function add(string _name, string _websiteUrl)
        external
        onlyOwner
    {
        uint256 newOrgIndex = storageContract.getUint(keccak256("ipOrganisations.nextIndex"));
        storageContract.setString(keccak256("ipOrganisation.name", newOrgIndex), _name);           // Name
        storageContract.setString(keccak256("ipOrganisation.website", newOrgIndex), _websiteUrl);  // Website
        storageContract.setBool(keccak256("ipOrganisation.exists", newOrgIndex), true);            // Exists check
        storageContract.setUint(keccak256("ipOrganisations.nextIndex"), newOrgIndex.add(1));
    }

    /// @dev Checks whether address is an authorised address for a specific IP Organisation
    /// @param _ipOrganisationIndex Index of the IP organisation
    /// @param _authorisedAddress Address to check
    function isAddressAuthorised(uint256 _ipOrganisationIndex, address _authorisedAddress)
        external
        view
        returns(bool)
    {
        return storageContract.getBool(keccak256("ipOrganisation.addresses", _ipOrganisationIndex, _authorisedAddress));
    }

    /// @dev Add an authorised address to the IP Organisation
    /// @param _ipoIndex Index of the IP organisation
    /// @param _authorisedAddress Address to be associated with the IP Organisation
    function addressAuthorise(uint256 _ipoIndex, address _authorisedAddress)
        external
        onlyOwner
        onlyExistingIPO(_ipoIndex)
    {
        storageContract.setBool(keccak256("ipOrganisation.addresses", _ipoIndex, _authorisedAddress), true);
    }

    /// @dev Remove an authorised address from the IP Organisation
    /// @param _ipoIndex Index of the IP organisation
    /// @param _authorisedAddress Address to be removed from the IP Organisation
    function addressRevoke(uint256 _ipoIndex, address _authorisedAddress)
        external
        onlyOwner
        onlyExistingIPO(_ipoIndex)
    {
        storageContract.setBool(keccak256("ipOrganisation.addresses", _ipoIndex, _authorisedAddress), false);
    }

    /// @dev Get IP token type
    /// @param _ipoIndex Index of IPO that the IP token type relates to
    /// @param _ipTypeIndex Index of the IP type
    function ipTypeAtIndex(uint256 _ipoIndex, uint256 _ipTypeIndex)
        external
        view
        returns(string, address)
    {
        return (
            storageContract.getString(keccak256("ipOrganisation.token.name", _ipoIndex, _ipTypeIndex)),
            storageContract.getAddress(keccak256("ipOrganisation.token.address", _ipoIndex, _ipTypeIndex))
        );
    }

    /// @dev Get IP token type address
    /// @param _ipoIndex Index of IPO that the IP token type relates to
    /// @param _ipTypeIndex Index of the IP type
    function ipTypeAddressAtIndex(uint256 _ipoIndex, uint256 _ipTypeIndex)
        external
        view
        returns(address)
    {
        return storageContract.getAddress(keccak256("ipOrganisation.token.address", _ipoIndex, _ipTypeIndex));
    }

    /// @dev Add IP token type
    /// @param _ipoIndex Index of IPO to add IP type to
    /// @param _ipTypeName Name of the IP right type
    /// @param _ipTypeTokenAddress Address of the IP right type token
    function ipTypeAdd(uint256 _ipoIndex, string _ipTypeName, address _ipTypeTokenAddress)
        external
        onlyExistingIPO(_ipoIndex)
        onlyIPOAuthorisedAdmin(_ipoIndex)        
    {
        // must not be empty name
        require(bytes(_ipTypeName).length > 0);
        // must not be empty address
        require(_ipTypeTokenAddress != 0x0);

        uint256 newTokenIndex = storageContract.getUint(keccak256("ipOrganisation.tokens.nextIndex", _ipoIndex));
        storageContract.setString(keccak256("ipOrganisation.token.name", _ipoIndex, newTokenIndex), _ipTypeName);
        storageContract.setAddress(keccak256("ipOrganisation.token.address", _ipoIndex, newTokenIndex), _ipTypeTokenAddress);
        storageContract.setUint(keccak256("ipOrganisation.tokens.nextIndex", _ipoIndex), newTokenIndex.add(1));
    }
}
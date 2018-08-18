pragma solidity ^0.4.23;

import "../../../util/SafeMath.sol";
import "../../../storage/KeyValueStorage.sol";

/**
* @title PatentToken is an ERC-721 NFT
* Code is based on Open Zeppelin Library (https://github.com/OpenZeppelin/openzeppelin-solidity)
* Includes modification for Patent metadata & licensing 
* Includes modifications to be upgradable by using Storage
* @author Civic Ledger
*/
contract PatentToken {

  using SafeMath for uint256;

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  // Central storage contract
  KeyValueStorage internal storageContract;

  // Australian IPO
  uint256 internal ipoIndex = 0;
  // Patent IP right type
  string internal iprTypeName = "Patent";

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /** 
   * @dev Checks to make sure the PatentRegistration contract is calling 
   */
   modifier onlyRegistrationContract() {
     address registrationAddress = storageContract.getAddress(keccak256("contract.name", "Registration", ipoIndex, iprTypeName));
     require(msg.sender == registrationAddress);
     _;
   }

     /** 
   * @dev Checks to make sure the Exchange contract is calling 
   */
   modifier onlyOwnerOrExchangeContract(uint256 _tokenId) {
     address exchangeAddress = storageContract.getAddress(keccak256("contract.name", "Exchange"));
     require(ownerOf(_tokenId) == msg.sender || msg.sender == exchangeAddress);
     _;
   }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    address exchangeAddress = storageContract.getAddress(keccak256("contract.name", "Exchange"));
    require(isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == exchangeAddress);
    _;
  }

  /**
  * @dev PatentToken constructor
  * @param _storageAddress Address of central storage contract 
   */
  constructor(address _storageAddress) public {
      storageContract = KeyValueStorage(_storageAddress);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return storageContract.getUint(keccak256("patent.owned.tokenCount", _owner));
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    
    address owner = storageContract.getAddress(keccak256("patent.token.owner", _tokenId));
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = storageContract.getAddress(keccak256("patent.token.owner", _tokenId));
    return owner != address(0);
  }

  /**
   * @dev Gets whether the token is licensable
   */
  function isLicensable(uint256 _tokenId)
    public
    view
    returns(bool)
  {
    return storageContract.getBool(keccak256("patent.licensable", _tokenId));
  }

  /**
   * @dev Sets whether the token is licensable
   * @param _tokenId uint256 ID of the token to set licensibility
   * @param _licensable Is is licensable or not?
   */
  function setLicensable(uint256 _tokenId, bool _licensable)
    external
    onlyOwnerOf(_tokenId)    
  {
    storageContract.setBool(keccak256("patent.licensable", _tokenId), _licensable);
  }

  /**
   * @dev Gets whether the token is transferrable
   */
  function isTransferrable(uint256 _tokenId)
    public
    view
    returns(bool)
  {
    return storageContract.getBool(keccak256("patent.transferrable", _tokenId));
  }

  /**
    * @dev Gets whether an order type is valid for this token
    * @param _tokenId ID of the token to check
    * @param _orderType ID of the order type (0 = transfer, 1 = license)
   */
  function isValidOrderType(uint256 _tokenId, uint256 _orderType)
    external
    view
    returns(bool)
  {
    if (_orderType == 1) {
      require(isTransferrable(_tokenId) == true);
      return true;
    }
    else if (_orderType == 2) {
      require(isLicensable(_tokenId) == true);
      return true;
    }    
    return false;
  }

  /**
   * @dev Sets whether the token is transferrable
   * @param _tokenId uint256 ID of the token to set licensibility
   * @param _transferrable Is is licensable or not?
   */
  function setTransferrable(uint256 _tokenId, bool _transferrable)
    external
    onlyOwnerOf(_tokenId)    
  {
    storageContract.setBool(keccak256("patent.transferrable", _tokenId), _transferrable);
  }

    /// @dev Allows patent owner to license a patent to a licensee
    /// @dev Patent must be granted to be licensed
    /// @param _tokenId Index of patent to license
    /// @param _licenseeAddress Address of licensee to grant license to
    function license(uint256 _tokenId, address _licenseeAddress) 
        public
        onlyOwnerOrExchangeContract(_tokenId)
    {
      // get license index
      uint256 nextIndex = storageContract.getUint(keccak256("patent.licenses.nextIndex", _tokenId));

      storageContract.setBool(keccak256("patent.license", _tokenId, _licenseeAddress), true);

      // increment the license index
      storageContract.setUint(keccak256("patent.licenses.nextIndex", _tokenId), nextIndex++);
    }

  /// @dev Executes order
  /// @param _tokenId Index of token
  /// @param _orderType Type of order
  /// @param _from Patent owner
  /// @param _to Patent orderee
  function executeOrder(uint256 _tokenId, uint256 _orderType, address _from, address _to)
    external
    onlyOwnerOrExchangeContract(_tokenId)
    returns(bool)
  {
    require(_from == ownerOf(_tokenId));
    require(_to != address(0));

    if (_orderType == 1) {
      // transfer patent
      transferFrom(_from, _to, _tokenId);
    }
    else if (_orderType == 2) {
      // license patent
      license(_tokenId, _to);
    }

    return true;
  }

  /// @dev Queries whether an address has a license for the patent
  /// @param _tokenId Index of patent to check license
  /// @param _licenseeAddress Address of licensee to check license of
  function hasLicense(uint256 _tokenId, address _licenseeAddress)
    external
    view    
    returns(bool)
  {
    return storageContract.getBool(keccak256("patent.license", _tokenId, _licenseeAddress));
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      storageContract.setAddress(keccak256("patent.token.approvals", _tokenId), _to);
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return storageContract.getAddress(keccak256("patent.token.approvals", _tokenId));
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Function to mint a new token
   * @dev Reverts if not called by registration contract
   * @param _to The address that will own the minted token
   */
  function mint(address _to)
    external 
    onlyRegistrationContract
    returns(uint)
  {
    require(_to != address(0));
    uint tokenCount = storageContract.getUint(keccak256("patent.tokenCount"));
    uint nextTokenId = tokenCount.add(1);
    addTokenTo(_to, nextTokenId);    
    emit Transfer(address(0), _to, nextTokenId);    
    return nextTokenId;
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (storageContract.getAddress(keccak256("patent.token.approvals", _tokenId)) != address(0)) {
      storageContract.setAddress(keccak256("patent.token.approvals", _tokenId), address(0));
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    address owner = storageContract.getAddress(keccak256("patent.token.owner", _tokenId));
    require(owner == address(0));
    storageContract.setAddress(keccak256("patent.token.owner", _tokenId), _to);
    // increase owner token count
    uint ownerTokenCount = storageContract.getUint(keccak256("patent.owned.tokenCount", _to));
    storageContract.setUint(keccak256("patent.owned.tokenCount", _to), ownerTokenCount.add(1));
    // increase overall token count
    uint tokenCount = storageContract.getUint(keccak256("patent.tokenCount"));
    storageContract.setUint(keccak256("patent.tokenCount"), tokenCount.add(1));
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    uint tokenCount = storageContract.getUint(keccak256("patent.owned.tokenCount", _from));
    storageContract.setUint(keccak256("patent.owned.tokenCount", _from), tokenCount.sub(1));
    storageContract.setAddress(keccak256("patent.token.owner", _tokenId), address(0));
  }

}
pragma solidity ^0.4.23;

import "../util/Ownable.sol";
import "../util/SafeMath.sol";
import "../util/RLP.sol";
import "../storage/KeyValueStorage.sol";
import "../ip-organisations/IPR.sol";
import "../ip-organisations/IPOrganisations.sol";
import "../util/ECRecovery.sol";
import "./Marketplaces.sol";

/**
 * @title Exchange
 * @author Civic Ledger
 */
contract ExchangeSubmitOrder is Ownable {

    using SafeMath for uint256;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint256 constant STATUS_PENDING = 1;

    KeyValueStorage internal storageContract;  

     struct Order {
        uint256 ipOrganisationIndex;
        uint256 ipTypeIndex;
        uint256 ipIndex;
        address orderTakerAddress;
        address marketplaceAddress;
        uint256 orderType;
        uint256 paymentCurrency;
        address paymentTokenAddress;
        uint256 paymentAmountInWei;
        uint256 nonce;
        uint256 timestamp;
        address feeRecipientAddress;
        uint256 feeAmountInWei;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

     /**
    * @dev constructor
    * @param _storageAddress Address of central storage contract 
    */
    constructor(address _storageAddress) public {
        storageContract = KeyValueStorage(_storageAddress);
    }

   /** 
   * @dev Checks to make sure the Exchange contract is calling 
   */
   modifier onlyOwnerOrExchangeContract() {
     address exchangeAddress = storageContract.getAddress(keccak256("contract.name", "Exchange"));
     require(msg.sender == exchangeAddress);
     _;
   }

    /// @dev submit an order
    /// @param _order RLP list of arguments (TODO)    
    function submitOrder(bytes _order)
        external
        onlyOwnerOrExchangeContract()
    {
        // create order from the RLP encoded arguments
        Order memory order = getOrder(_order);        
        checkIsRegisteredMarketplace(order.marketplaceAddress);

        // order taker address cannot be empty
        require(order.orderTakerAddress != address(0));
        // marketplace address cannot be empty
        require(order.marketplaceAddress != address(0));
        // if a fee is provided then fee recipient cannot be empty
        if (order.feeAmountInWei > 0) {
            require(order.feeRecipientAddress != address(0));
        }

        // check marketplace order nonce to stop replays
        require(storageContract.getBool(keccak256("orders.marketplace.nonce", order.marketplaceAddress, order.nonce)) == false);

        // get ip type token address
        address ipTypeAddress = getIPTypeTokenAddress(order.ipOrganisationIndex, order.ipTypeIndex);
        require(ipTypeAddress != address(0));

        IPR ipRightToken = IPR(ipTypeAddress);
        // validate IP right exists
        require(ipRightToken.exists(order.ipIndex));
        // validate IP right is transferrable/licensable
        require(ipRightToken.isValidOrderType(order.ipIndex, order.orderType) == true);

        // check signature belongs to order taker
        bytes32 orderHash = hashOrder(order);
        address signerAddress = ECRecovery.recover(orderHash, order.v, order.r, order.s);
        require (signerAddress == order.orderTakerAddress);
        
        // get new order index for marketplace
        uint256 nextIndex = storageContract.getUint(keccak256("orders.nextIndex", order.marketplaceAddress));

        // record order
        storeOrder(nextIndex, order, signerAddress, STATUS_PENDING);

        // mark nonce as used
        storageContract.setBool(keccak256("orders.marketplace.nonce", order.marketplaceAddress, order.nonce), true);

        // increment the marketplace index for next registration
        storageContract.setUint(keccak256("orders.nextIndex", order.marketplaceAddress), nextIndex.add(1));
    }

    function getOrder(bytes _order)
        internal
        pure
        returns(Order)
    {
        // must be a list of parameters
        RLPReader.RLPItem[] memory itemList = _order.toRlpItem().toList();
        return Order(
            itemList[0].toUint(),       // ipOrganisationIndex
            itemList[1].toUint(),       // ipTypeIndex
            itemList[2].toUint(),       // ipIndex
            itemList[3].toAddress(),    // orderTakerAddress
            itemList[4].toAddress(),    // marketplaceAddress            
            itemList[5].toUint(),       // orderType
            itemList[6].toUint(),       // paymentCurrency
            itemList[7].toAddress(),    // paymentTokenAddress
            itemList[8].toUint(),       // paymentAmountInWei
            itemList[9].toUint(),       // nonce
            itemList[10].toUint(),      // timestamp
            itemList[11].toAddress(),   // feeRecipientAddress
            itemList[12].toUint(),      // feeAmountInWei
            uint8(itemList[13].toUint()), // signature v
            itemList[14].toBytes32(),   // signature r
            itemList[15].toBytes32()    // signature s
        );
    }

     function getIPTypeTokenAddress(uint256 _ipOrganisationIndex, uint256 _ipTypeIndex)
        internal
        view
        returns(address)
    {
        IPOrganisations ipOrganisations = IPOrganisations(storageContract.getAddress(keccak256("contract.name", "IPOrganisations")));
        return ipOrganisations.ipTypeAddressAtIndex(_ipOrganisationIndex, _ipTypeIndex);
    }

     function hashOrder(Order _order) 
        internal
        pure
        returns(bytes32)
    {
        return keccak256(
            _order.ipOrganisationIndex,
            _order.ipTypeIndex,
            _order.ipIndex,
            _order.orderTakerAddress,
            _order.marketplaceAddress,
            _order.orderType,
            _order.paymentCurrency,
            _order.paymentTokenAddress,
            _order.paymentAmountInWei,
            _order.nonce,
            _order.timestamp,
            _order.feeRecipientAddress,
            _order.feeAmountInWei
        );
    }

     function storeOrder(uint256 _orderIndex, Order _order, address _signerAddress, uint256 _status)
        internal
    {
        // store details
        storageContract.setUint(keccak256("order.status", _order.marketplaceAddress, _orderIndex), _status);
        storageContract.setUint(keccak256("order.ipo", _order.marketplaceAddress, _orderIndex), _order.ipOrganisationIndex);
        storageContract.setUint(keccak256("order.ipType", _order.marketplaceAddress, _orderIndex), _order.ipTypeIndex);
        storageContract.setUint(keccak256("order.ip", _order.marketplaceAddress, _orderIndex), _order.ipIndex);
        storageContract.setAddress(keccak256("order.taker.address", _order.marketplaceAddress, _orderIndex), _order.orderTakerAddress);
        storageContract.setAddress(keccak256("order.marketplace.address", _order.marketplaceAddress, _orderIndex), _order.marketplaceAddress);
        storageContract.setUint(keccak256("order.type", _order.marketplaceAddress, _orderIndex), _order.orderType);
        storageContract.setUint(keccak256("order.payment.currency", _order.marketplaceAddress, _orderIndex), _order.paymentCurrency);
        storageContract.setAddress(keccak256("order.payment.token", _order.marketplaceAddress, _orderIndex), _order.paymentTokenAddress);
        storageContract.setUint(keccak256("order.payment.amount", _order.marketplaceAddress, _orderIndex), _order.paymentAmountInWei);
        storageContract.setUint(keccak256("order.nonce", _order.marketplaceAddress, _orderIndex), _order.nonce);        
        storageContract.setUint(keccak256("order.timestamp", _order.marketplaceAddress, _orderIndex), _order.timestamp);
        storageContract.setAddress(keccak256("order.fee.recipient", _order.marketplaceAddress, _orderIndex), _order.feeRecipientAddress);
        storageContract.setUint(keccak256("order.fee.amount", _order.marketplaceAddress, _orderIndex), _order.feeAmountInWei);
        storageContract.setUint8(keccak256("order.signature.v", _order.marketplaceAddress, _orderIndex), _order.v);
        storageContract.setBytes32(keccak256("order.signature.r", _order.marketplaceAddress, _orderIndex), _order.r);
        storageContract.setBytes32(keccak256("order.signature.s", _order.marketplaceAddress, _orderIndex), _order.s);
        storageContract.setAddress(keccak256("order.signature.address", _order.marketplaceAddress, _orderIndex), _signerAddress);        
        storageContract.setBool(keccak256("order.exists", _order.marketplaceAddress, _orderIndex), true);
    }

     /// @dev Checks that sender is a registered marketplace
    /// @param _marketplaceAddress Address of the marketpalce to check
    function checkIsRegisteredMarketplace(address _marketplaceAddress)
        internal
        view
    {
        Marketplaces marketplaces = Marketplaces(storageContract.getAddress(keccak256("contract.name", "Marketplaces")));
        require(marketplaces.isRegistered(_marketplaceAddress));
    }

}
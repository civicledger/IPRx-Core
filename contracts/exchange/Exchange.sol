pragma solidity ^0.4.23;

import "../util/Ownable.sol";
import "../util/SafeMath.sol";
import "../storage/KeyValueStorage.sol";
import "../ip-organisations/IPOrganisations.sol";
import "../ip-organisations/IPR.sol";
import "./ExchangeSubmitOrder.sol";

/**
 * @title Exchange
 * @author Civic Ledger
 */
contract Exchange is Ownable {
    
    using SafeMath for uint256;

    uint256 constant STATUS_PENDING = 1;
    uint256 constant STATUS_COMPLETED = 2;
    uint256 constant STATUS_REJECTED = 3;

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

    /// @dev retrieve order at an index
    /// @param _marketplaceAddress Address of the marketplace the order was processed on
    /// @param _orderIndex Index of the order to retrieve
    function orderAtIndex(address _marketplaceAddress, uint256 _orderIndex)
        external
        view
        returns(
            uint256,
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256           
        )
    {
        address mp = _marketplaceAddress;
        uint256 orderIndex = _orderIndex;
        return (
            storageContract.getUint(keccak256("order.ipo", mp, orderIndex)),
            storageContract.getUint(keccak256("order.ipType", mp, orderIndex)),
            storageContract.getUint(keccak256("order.ip", mp, orderIndex)),
            storageContract.getAddress(keccak256("order.taker.address", mp, orderIndex)),
            storageContract.getAddress(keccak256("order.marketplace.address", mp, orderIndex)),
            storageContract.getUint(keccak256("order.type", mp, orderIndex)),            
            storageContract.getUint(keccak256("order.nonce", mp, orderIndex)),
            storageContract.getUint(keccak256("order.timestamp", mp, orderIndex)),
            storageContract.getAddress(keccak256("order.fee.recipient", mp, orderIndex)),
            storageContract.getUint(keccak256("order.fee.amount", mp, orderIndex))        
        );
    }

    function orderPaymentAtIndex(address _marketplaceAddress, uint256 _orderIndex)
        external
        view
        returns(
            uint256,
            address,
            uint256
        )
    {
        address mp = _marketplaceAddress;
        uint256 orderIndex = _orderIndex;
        return (
            storageContract.getUint(keccak256("order.payment.currency", mp, orderIndex)),
            storageContract.getAddress(keccak256("order.payment.token", mp, orderIndex)),
            storageContract.getUint(keccak256("order.payment.amount", mp, orderIndex))
        );
    }

     function orderSigAtIndex(address _marketplaceAddress, uint256 _orderIndex)
        external
        view
        returns(
            uint8,
            bytes32,
            bytes32,
            address         
        )
    {
        address mp = _marketplaceAddress;
        uint256 orderIndex = _orderIndex;
        return (
            storageContract.getUint8(keccak256("order.signature.v", mp, orderIndex)),
            storageContract.getBytes32(keccak256("order.signature.r", mp, orderIndex)),
            storageContract.getBytes32(keccak256("order.signature.s", mp, orderIndex)),
            storageContract.getAddress(keccak256("order.signature.address", mp, orderIndex))
        );
    }

    function orderStatusAtIndex(address _marketplaceAddress, uint256 _orderIndex)
        public
        view
        returns(uint256)
    {
        return storageContract.getUint(keccak256("order.status", _marketplaceAddress, _orderIndex));
    }

    function orderExists(address _marketplaceAddress, uint256 _orderIndex)
        public
        view
        returns(bool)
    {
        return storageContract.getBool(keccak256("order.exists", _marketplaceAddress, _orderIndex));
    }

    /// @dev submit an order
    /// @param _order RLP list of arguments (TODO)    
    function submitOrder(bytes _order)
        external
    {
        ExchangeSubmitOrder submitOrderContract = ExchangeSubmitOrder(storageContract.getAddress(keccak256("contract.name", "ExchangeSubmitOrder")));
        submitOrderContract.submitOrder(_order);
    }

    /// @dev Approving a pending order
    /// @param _marketplaceAddress Address of the marketplace that submitted the order
    /// @param _orderIndex Index of the order to approve
    function approveOrder(address _marketplaceAddress, uint256 _orderIndex)
        external
    {
        // make sure order exists and is pending
        require(orderExists(_marketplaceAddress, _orderIndex) == true);
        require(orderStatusAtIndex(_marketplaceAddress, _orderIndex) == STATUS_PENDING);        

        // make sure IP right still exists
        uint256 ipOrganisationIndex = storageContract.getUint(keccak256("order.ipo", _marketplaceAddress, _orderIndex));
        uint256 ipTypeIndex = storageContract.getUint(keccak256("order.ipType", _marketplaceAddress, _orderIndex));
        address ipTypeAddress = getIPTypeTokenAddress(ipOrganisationIndex, ipTypeIndex);
        require(ipTypeAddress != address(0));
        
        IPR ipRightToken = IPR(ipTypeAddress);
        uint256 ipIndex = storageContract.getUint(keccak256("order.ip", _marketplaceAddress, _orderIndex));
        require(ipRightToken.exists(ipIndex));

        // get IP right owner and check that they are the sender
        address ipOwner = ipRightToken.ownerOf(ipIndex);
        require(msg.sender == ipOwner);

        // transfer/license the IP to the order taker
        uint256 orderType = storageContract.getUint(keccak256("order.type", _marketplaceAddress, _orderIndex));
        address takerAddress = storageContract.getAddress(keccak256("order.taker.address", _marketplaceAddress, _orderIndex));
        require(ipRightToken.executeOrder(ipIndex, orderType, ipOwner, takerAddress) == true);

        // set status of the order to rejected
        storageContract.setUint(keccak256("order.status", _marketplaceAddress, _orderIndex), STATUS_COMPLETED);
    }

    /// @dev Reject a pending order
    /// @param _marketplaceAddress Address of the marketplace that submitted the order
    /// @param _orderIndex Index of the order to reject
    function rejectOrder(address _marketplaceAddress, uint256 _orderIndex)
        external
    {
        // make sure order exists and is pending
        require(orderExists(_marketplaceAddress, _orderIndex));
        require(orderStatusAtIndex(_marketplaceAddress, _orderIndex) == STATUS_PENDING);        

        // make sure IP right still exists
        uint256 ipOrganisationIndex = storageContract.getUint(keccak256("order.ipo", _marketplaceAddress, _orderIndex));
        uint256 ipTypeIndex = storageContract.getUint(keccak256("order.ipType", _marketplaceAddress, _orderIndex));
        address ipTypeAddress = getIPTypeTokenAddress(ipOrganisationIndex, ipTypeIndex);
        require(ipTypeAddress != address(0));
        
        IPR ipRightToken = IPR(ipTypeAddress);
        uint256 ipIndex = storageContract.getUint(keccak256("order.ip", _marketplaceAddress, _orderIndex));
        require(ipRightToken.exists(ipIndex));

        // get IP right owner and check that they are the sender
        address ipOwner = ipRightToken.ownerOf(ipIndex);
        require(msg.sender == ipOwner);

        // set status of the order to rejected
        storageContract.setUint(keccak256("order.status", _marketplaceAddress, _orderIndex), STATUS_REJECTED);
    }   

    function getIPTypeTokenAddress(uint256 _ipOrganisationIndex, uint256 _ipTypeIndex)
        internal
        view
        returns(address)
    {
        IPOrganisations ipOrganisations = IPOrganisations(storageContract.getAddress(keccak256("contract.name", "IPOrganisations")));
        return ipOrganisations.ipTypeAddressAtIndex(_ipOrganisationIndex, _ipTypeIndex);
    }
    

}
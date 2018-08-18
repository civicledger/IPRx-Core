pragma solidity ^0.4.23;

interface IPR {
    function exists(uint256 _tokenId) external view returns (bool);
    function isValidOrderType(uint256 _tokenId, uint256 _orderType) external view returns(bool);
    function mint(address _to) external returns(uint);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function executeOrder(uint256 _tokenId, uint256 _orderType, address _from, address _to) external returns(bool);
}
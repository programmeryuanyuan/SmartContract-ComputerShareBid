// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './ERC2612.sol';

/* interface TokenRecipient {
    function tokensReceived(address from, uint amount) external returns (bool);
} */

abstract contract SophisticatedInvestorCertificateAuthorityRegistry is ERC2612 {

    address private immutable ASIC = address(this);

    mapping(address => bytes32) public addressToPublicKey;
    //bytes32[] publicKeys;

    address[] appliers;
    modifier isASIC() {
        require(msg.sender == ASIC);
        _;
    }


    function _addPublicKey(bytes32 keyToAdd, address investor) private isASIC() {
        addressToPublicKey[investor] = keyToAdd;
    }

    function deletePublicKey(address investor) public isASIC() {
        delete addressToPublicKey[investor];
    }

    function _isAuthorized(bytes32 key) internal view returns (bool) {
        if (addressToPublicKey[msg.sender] == key) {
            return true;
        } else {
            return false;
        }
    }

    function registry() public {
        require(msg.sender != ASIC);
        appliers.push(msg.sender);
    }

    // ASIC reviews the investors on the appliers list
    // If his or her have an anual income over $250,000 or a net worth of over $2.5 million, call this function
    function permitStake(address investor, uint8 year, uint deadline, uint8 v, bytes32 r, bytes32 s) public isASIC() {
        bytes32 hash = IERC2612(ASIC).permit(msg.sender, investor, year, deadline, v, r, s);
        _addPublicKey(hash, investor);
    }
}
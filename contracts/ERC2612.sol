// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./interface/IERC20.sol";
import "./interface/IERC2612.sol";
import "./ERC20.sol";


abstract contract ERC2612 is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    //
    bytes32 public immutable DOMAIN_SEPARATOR;
    //
    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint8 year,uint256 nonce,uint256 deadline)");
    

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        uint256 chainId = block.chainid;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // Structured signature
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev See {IERC2612-permit}.
     */
    // Here owner is ASIC. ASIC permits spender with amount
    function permit(address owner, address spender, uint8 year, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override returns (bytes32) {
        require(deadline >= block.timestamp, "The deadline must be set after now");
        require(owner != address(0));
        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                year,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "Invalid signature"
        );
        return hash;
    }
}

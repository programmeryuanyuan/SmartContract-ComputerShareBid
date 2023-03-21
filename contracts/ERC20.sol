// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./interface/IERC20.sol";
import "./SafeMath.sol";


contract ERC20 is IERC20 {
    using SafeMath for uint256;
    uint256 public total_Supply = 10000;
    mapping (address => uint256) internal  _addressToShares;
    mapping (address => mapping (address => uint256)) internal  _allowanceShares;

    string public  symbol;
    uint256 public  immutable  decimals = 18;
    string public  name;

    constructor(string memory _name, string memory _symbol) {
      name = _name;
      symbol = _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return 10000;
    }

    function balanceOf(address addr) public view override returns (uint256) {
        return _addressToShares[addr];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowanceShares[owner][spender];
    }

    function approve(address spender, uint value) public override returns (bool) {
        return _approve(msg.sender, spender, value);
    }

    function transfer(address to, uint value) public override returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint value) public override returns (bool) {
        uint allowed = _allowanceShares[from][msg.sender];
        require(allowed >= value);
        require(value >= 0);
        require(from != msg.sender);
        _approve(from, msg.sender, allowed.sub(value));
        return _transfer(from, to, value);
    }

    function _transfer(address from, address to, uint value) internal virtual returns (bool) {
        require(_addressToShares[from] >= value, "No enough balance");
        require(to != address(0), "Can't tranfer to zero address.");
        require(value >= 0, "You can only transfer positive numbers.");
        _addressToShares[from] = _addressToShares[from].sub(value);
        _addressToShares[to] = _addressToShares[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function _approve(address owner, address spender, uint value) internal virtual returns (bool) {
        //owner gives spender approval of amount value
        _allowanceShares[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }


    function _mint(address to, uint value) internal virtual {
        _addressToShares[to] = _addressToShares[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal virtual {
        require(_addressToShares[from] >= value, "No enough balance");
        _addressToShares[from] = _addressToShares[from].sub(value);
        emit Transfer(from, address(0), value);
    }
}
/* Copyright (C) 2016 Augustus York Rushton Pash - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the license, which was distrubted with this code and located
 * at: https://github.com/augustuspash/Central-Dank
 *
 * You should have received a copy of the license with
 * this file. If not, please visit: https://github.com/augustuspash/Central-Dank
 */

pragma solidity ^0.4.2;

contract TokenOwnership {
    address minter;
    address owner;
    
    modifier owned {
        if (msg.sender != owner) throw;
        _;
    }
    
    modifier minting {
        if (msg.sender != minter) throw;
        _;
    }
    
    function changeMinter(address _newMinter) owned {
        minter = _newMinter;
    }
    
    function changeOwner(address _newOwner) owned {
        owner = _newOwner;
    }
}

contract Dankness is TokenOwnership {
    string public name = "Dankness";
    uint8 public decimals = 10;
    string public symbol = "D";
    uint256 public totalDank = 0;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Minted(address indexed _minter, uint256 _value);
    event Destroyed(address indexed _minter, uint256 _value);
    
    function Dankness(address _owner, address _minter) {
        owner = _owner;
        minter = _minter;
    }
    
    function mint(uint256 _value) minting returns (bool success) {
        if (balances[minter] + _value > balances[minter]) {
            balances[minter] += _value;
            totalDank += _value;
            Minted(minter, _value);
            return true;
        } else { return false; }
    }
    
    function destroy(uint256 _value) minting returns (bool success) {
        if (balances[this] - _value >= 0 && balances[this] - _value <  balances[this]) {
            balances[this] -= _value;
            totalDank -= _value;
            Destroyed(this, _value);
            return true;
        } else { return false; }
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}
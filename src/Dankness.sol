/* Copyright (C) 2016 Augustus York Rushton Pash - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the license, which was distrubted with this code and located
 * at: https://github.com/augustuspash/Central-Dank
 *
 * You should have received a copy of the license with
 * this file. If not, please visit: https://github.com/augustuspash/Central-Dank
 */
pragma solidity ^0.4.2;

contract AdvancedDanknessRecords {
    struct TransactionRecord {
        uint256 amount;
        address from;
        address to;
        address spender;
        string info;
    }
    
    
    struct AddressRecords {
        address[] addresses;
        mapping (address => bool) added;
        mapping (address => uint256) addressToIndex;
    }
    
    mapping (address => TransactionRecord[]) transactionRecord;
    
    mapping (address=> AddressRecords) addressRecords;
    
    mapping (address=> AddressRecords) approvalRecords;
    
    address owner;
    
    function AdvancedDanknessRecords() {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        if (msg.sender != owner){
            throw;
        }
        _;
    }
    
    function addTransaction(address _user, uint256 _amount, address _from, address _to, address _spender, string _info) ownerOnly {
        transactionRecord[_user].push(TransactionRecord(_amount, _from, _to, _spender, _info));
    }
    
    function addAddressRecord(address _user, address _address) ownerOnly {
        if (!addressRecords[_user].added[_address]) {
            addressRecords[_user].addresses.push(_address);
            addressRecords[_user].added[_address] = true;
            addressRecords[_user].addressToIndex[_address] = addressRecords[_user].addresses.length - 1;
        }
    }
    
    function removeAddressRecord(address _user, address _address) ownerOnly {
        uint256 _index = addressRecords[_user].addressToIndex[_address];
        if (addressRecords[_user].addresses.length > _index && addressRecords[_user].addresses[_index] == _address) {
            delete addressRecords[_user].addresses[_index];
            addressRecords[_user].addressToIndex[addressRecords[_user].addresses[addressRecords[_user].addresses.length - 1]] = _index;
            addressRecords[_user].addresses[_index] = addressRecords[_user].addresses[addressRecords[_user].addresses.length - 1];
            addressRecords[_user].addresses.length--;
            addressRecords[_user].added[_address] = false;
            approvalRecords[_user].addressToIndex[_address] = 0;
        }
    }
    
    function addApprovalRecord(address _user, address _address) ownerOnly {
        if (!approvalRecords[_user].added[_address]) {
            approvalRecords[_user].addresses.push(_address);
            approvalRecords[_user].added[_address] = true;
            approvalRecords[_user].addressToIndex[_address] = approvalRecords[_user].addresses.length - 1;
        }
    }
    
    function removeApprovalRecord(address _user, address _address) ownerOnly {
        uint256 _index = approvalRecords[_user].addressToIndex[_address];
        if (approvalRecords[_user].addresses.length > _index && approvalRecords[_user].addresses[_index] == _address) {
            delete approvalRecords[_user].addresses[_index];
            approvalRecords[_user].addressToIndex[approvalRecords[_user].addresses[approvalRecords[_user].addresses.length - 1]] = _index;
            approvalRecords[_user].addresses[_index] = approvalRecords[_user].addresses[approvalRecords[_user].addresses.length - 1];
            approvalRecords[_user].addresses.length--;
            approvalRecords[_user].added[_address] = false;
            approvalRecords[_user].addressToIndex[_address] = 0;
        }
    }
    
    function transactionRecordLength(address _user) constant returns (uint256 index) {
        return transactionRecord[_user].length;
    }
    
    function getTransactionRecord(address _user, uint256 _index) constant returns (uint256 amount,address from,address to,address spender,string info) {
        amount = transactionRecord[_user][_index].amount;
        from = transactionRecord[_user][_index].from;
        to = transactionRecord[_user][_index].to;
        spender = transactionRecord[_user][_index].spender;
        info = transactionRecord[_user][_index].info;
    }
    
    function inAddressRecord(address _user, address _address) constant returns (bool created) {
        return addressRecords[_user].added[_address];
    }
    
    function addressRecordLength(address _user) constant returns (uint256 length) {
        return addressRecords[_user].addresses.length;
    }
    
    function getAddressRecord(address _user, uint256 _index) constant returns (address account) {
        return addressRecords[_user].addresses[_index];
    }
    
    function getAddressRecordIndex(address _user, address _address) constant returns (uint256 index) {
        return addressRecords[_user].addressToIndex[_address];
    }
    
    function inApprovalRecord(address _user, address _address) constant returns (bool created) {
        return approvalRecords[_user].added[_address];
    }
    
    function approvalRecordLength(address _user) constant returns (uint256 length) {
        return approvalRecords[_user].addresses.length;
    }
    
    function getApprovalRecord(address _user, uint256 _index) constant returns (address account) {
        return approvalRecords[_user].addresses[_index];
    }
    
    function getApprovalRecordIndex(address _user, address _address) constant returns (uint256 index) {
        return approvalRecords[_user].addressToIndex[_address];
    }
}

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
    
    AdvancedDanknessRecords public records = new AdvancedDanknessRecords();
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Minted(address indexed _minter, uint256 _value);
    event Destroyed(address indexed _minter, uint256 _value);
    
    function Dankness(address _owner, address _minter) {
        owner = _owner;
        minter = _minter;
    }
    
    function destroy() owned {
        selfdestruct(owner);
    }
    
    function mint(uint256 _value) minting returns (bool success) {
        if (balances[minter] + _value > balances[minter]) {
            balances[minter] += _value;
            totalDank += _value;
            Minted(minter, _value);
            records.addTransaction(this, _value, 0x0, this, this, "minted");
            return true;
        } else { return false; }
    }
    
    function destroy(uint256 _value) minting returns (bool success) {
        if (balances[this] - _value >= 0 && balances[this] - _value <  balances[this]) {
            balances[this] -= _value;
            totalDank -= _value;
            Minted(this, _value);
            records.addTransaction(this, _value, this, 0x0, this, "destroyed");
            return true;
        } else { return false; }
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        return transfer(_to, _value, "transfered");
    }
    
    function transfer(address _to, uint256 _value, string _info) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            records.addTransaction(msg.sender, _value, msg.sender, _to, msg.sender, _info);
            records.addAddressRecord(_to, msg.sender);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        return transferFrom(_from, _to, _value, "transfered from");
    }

    function transferFrom(address _from, address _to, uint256 _value, string _info) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            records.addTransaction(msg.sender, _value, _from, _to, msg.sender, _info);
            records.addTransaction(_from, _value, _from, _to, msg.sender, _info);
            records.addAddressRecord(_to, msg.sender);
            records.addAddressRecord(_to, _from);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        records.addAddressRecord(_spender, msg.sender);
        records.addAddressRecord(msg.sender, _spender);
        if (_value != 0) {
            records.addApprovalRecord(msg.sender, _spender);
        } else {
            records.removeApprovalRecord(msg.sender, _spender);
        }
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}
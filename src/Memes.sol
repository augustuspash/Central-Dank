/* Copyright (C) 2016 Augustus York Rushton Pash - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the license, which was distrubted with this code and located
 * at: https://github.com/augustuspash/Central-Dank
 *
 * You should have received a copy of the license with
 * this file. If not, please visit: https://github.com/augustuspash/Central-Dank
 */

pragma solidity ^0.4.2;

contract MemeRecord {
    struct Record {
        mapping (string => bool) added;
        Meme[] memes;
    }
    struct Meme {
        string meme;
        bytes32 mhash;
    }
    
    mapping (address => Record) records;
    
    address owner;
    
    function MemeRecord() {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        if (msg.sender != owner){
            throw;
        }
        _;
    }
    
    function addMeme(string _meme, address _user) ownerOnly {
        if (!records[_user].added[_meme]) {
            records[_user].memes.push(Meme(_meme, sha256(_meme)));
            records[_user].added[_meme] = true;
        }
    }
    
    function removeMeme(string _meme, address _user, uint256 _index) ownerOnly {
        if (records[_user].memes.length > _index && records[_user].memes[_index].mhash == sha256(_meme)) {
            delete records[_user].memes[_index];
            records[_user].memes[_index] = records[_user].memes[records[_user].memes.length - 1];
            records[_user].memes.length--;
            records[_user].added[_meme] = false;
        }
    }
    
    function inRecord(string _meme, address _user) constant returns (bool recorded) {
        return records[_user].added[_meme];
    }
    
    function recordLength(address _user) constant returns (uint256 length) {
        return records[_user].memes.length;
    }
    
    function getRecord(address _user, uint256 _index) constant returns (string meme) {
        return records[_user].memes[_index].meme;
    }
    
    function selfDestruct(address _reciever) {
        selfdestruct(_reciever);
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

contract Memes is TokenOwnership{
    struct Meme {
        uint256 maxShares;
        bool created;
        string url;
        mapping (address => uint256) shares;
        mapping (address => mapping (address => uint256)) allowed;
    }
    
    mapping (string => Meme) memes;
    
    MemeRecord public memeRecord = new MemeRecord();
    
    uint256 public maxShares = 100;
    uint256 public indexingCost = 100 wei;
    uint256 payed = 0;
    
    event Transfer(string indexed _meme, address indexed _from, address indexed _to, uint256 _value);
    event Approval(string indexed _meme, address indexed _owner, address indexed _spender, uint256 _value);
    event Created(string indexed _meme, address indexed _minter);
    
    modifier created(string _meme) {
        if (!memes[_meme].created) throw;
        _;
    }
    
    function Memes(address _owner, address _minter) {
        owner = _owner;
        minter = _minter;
    }
    
    function setIndexingCost(uint256 _value) minting {
        indexingCost = _value;
    }
    
    function setMaxShares(uint256 _value) minting {
        maxShares = _value;
    }
    
    function withdrawEther(uint256 _value) minting {
        if (payed >= _value) {
            payed -= _value;
            if (!minter.send(_value)) {
                throw;
            }
        }
    }
    
    function withdrawEtherUnbounded(uint256 _value) minting {
        if (!minter.send(_value)) {
            throw;
        }
    }
    
    function indexMeme(string _meme, string _url) payable returns (bool success) {
        if (msg.value == indexingCost && !memes[_meme].created && bytes(_meme).length != 0) {
            payed += indexingCost;
            memes[_meme] = Meme(maxShares, true, _url);
            memes[_meme].shares[msg.sender] = maxShares;
            memeRecord.addMeme(_meme, msg.sender);
            Transfer(_meme, 0, msg.sender, maxShares);
            Created(_meme, msg.sender);
            return true;
        } else { throw; }
    }
    
    function transfer(string _meme, address _to, uint256 _value) created(_meme) returns (bool success) {
        if (memes[_meme].shares[msg.sender] >= _value && memes[_meme].shares[_to] + _value > memes[_meme].shares[_to]) {
            memes[_meme].shares[msg.sender] -= _value;
            memes[_meme].shares[_to] += _value;
            memeRecord.addMeme(_meme, _to);
            Transfer(_meme, msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(string _meme, address _from, address _to, uint256 _value) created(_meme)  returns (bool success) {
        if (memes[_meme].shares[_from] >= _value &&  memes[_meme].allowed[_from][msg.sender] >= _value && memes[_meme].shares[_to] + _value > memes[_meme].shares[_to]) {
            memes[_meme].shares[_to] += _value;
            memes[_meme].shares[_from] -= _value;
            memes[_meme].allowed[_from][msg.sender] -= _value;
            memeRecord.addMeme(_meme, _to);
            Transfer(_meme, _from, _to, _value);
            return true;
        } else { return false; }
    }

    function sharesOf(string _meme, address _owner) created(_meme)  constant returns (uint256 balance) {
        return memes[_meme].shares[_owner];
    }

    function approve(string _meme, address _spender, uint256 _value) created(_meme)  returns (bool success) {
        memes[_meme].allowed[msg.sender][_spender] = _value;
        memeRecord.addMeme(_meme, _spender);
        Approval(_meme, msg.sender, _spender, _value);
        return true;
    }

    function allowance(string _meme, address _owner, address _spender) created(_meme)  constant returns (uint256 remaining) {
      return memes[_meme].allowed[_owner][_spender];
    }
    
    function maxSharesOf(string _meme) created(_meme)  constant returns (uint256 shares) {
        return memes[_meme].maxShares;
    }
    
    function memeUrl(string _meme) created(_meme)  constant returns (string url) {
        return memes[_meme].url;
    }
    
    function isCreated(string _meme) constant returns (bool created) {
        return memes[_meme].created;
    }
}
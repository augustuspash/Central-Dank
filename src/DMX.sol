/* Copyright (C) 2016 Augustus York Rushton Pash - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the license, which was distrubted with this code and located
 * at: https://github.com/augustuspash/Central-Dank
 *
 * You should have received a copy of the license with
 * this file. If not, please visit: https://github.com/augustuspash/Central-Dank
 */

pragma solidity ^0.4.2;
    
contract DMXMemeRecords {
    struct Listing {
        address person;
        uint256 price;
        uint256 amount;
        bytes32 hash;
        string key;
    }
    struct Meme {
        uint256 directPrice;
        uint256 countPrice;
        uint256 count;
        bool created;
        Listing[] selling;
    }
    struct PersonalRecord {
        string[] keys;
        mapping (string => bool) added;
        mapping (string => uint256) keyToIndex;
        mapping (string => uint256) keyToPerIndex;
    }
    
    mapping (string => Meme) memeListings;
    mapping (address => PersonalRecord) personalRecords;
    uint256 directPriceAvgSize = 10;
    
    
    function addListing(string _meme, address _person, uint256 _price, uint256 _amount, string _key) internal returns (bool success) {
        if (personalRecords[_person].added[_key]) {
            return false;
        }
        if (memeListings[_meme].created == false) {
            memeListings[_meme].created = true;
            memeListings[_meme].directPrice = _price / _amount;
        }
        bytes32 hashed = sha256(_key);
        memeListings[_meme].selling.push(Listing(_person, _price, _amount, hashed, _key));
        personalRecords[_person].keys.push(_key);
        personalRecords[_person].added[_key] = true;
        personalRecords[_person].keyToIndex[_key] = memeListings[_meme].selling.length -1;
        personalRecords[_person].keyToPerIndex[_key] = personalRecords[_person].keys.length -1;
        return true;
    }
    
    function removeListing(string _meme, address _person, uint256 _price, uint256 _amount, string _key) internal returns (bool success) {
        bytes32 hashed = sha256(_key);
        uint256 _index = personalRecords[_person].keyToIndex[_key];
        if (memeListings[_meme].selling[_index].person == _person && memeListings[_meme].selling[_index].price == _price &&
            memeListings[_meme].selling[_index].amount == _amount && memeListings[_meme].selling[_index].hash == hashed) {
            delete memeListings[_meme].selling[_index];
            personalRecords[_person].keyToIndex[memeListings[_meme].selling[memeListings[_meme].selling.length - 1].key] = _index;
            memeListings[_meme].selling[_index] = memeListings[_meme].selling[memeListings[_meme].selling.length - 1];
            memeListings[_meme].selling.length --;
            uint256 origIndex = personalRecords[_person].keyToPerIndex[_key];
            personalRecords[_person].keys[origIndex] = personalRecords[_person].keys[personalRecords[_person].keys.length - 1];
            personalRecords[_person].keyToPerIndex[personalRecords[_person].keys[origIndex]] = origIndex;
            personalRecords[_person].added[_key] = false;
            personalRecords[_person].keys.length--;
            return true;
        }
        return false;
    }
    
    function updateDirectPrice(string _meme, uint256 soldPrice) internal {
        if (memeListings[_meme].countPrice + soldPrice >= memeListings[_meme].countPrice && memeListings[_meme].countPrice + soldPrice >= soldPrice) {
            memeListings[_meme].countPrice += soldPrice;
            memeListings[_meme].count++;
        }
        
        if (memeListings[_meme].count == directPriceAvgSize) {
            if (memeListings[_meme].count != 0) {
                memeListings[_meme].directPrice = memeListings[_meme].countPrice / memeListings[_meme].count;
            }
            if (memeListings[_meme].directPrice == 0) {
                memeListings[_meme].directPrice = 1;
            }
            memeListings[_meme].created = true;
            memeListings[_meme].count = 0;
            memeListings[_meme].countPrice = 0;
        }
    }
    
    function listingLength(string _meme) constant returns (uint256 length) {
        return memeListings[_meme].selling.length;
    }
    
    function getListing(string _meme, uint256 _index) constant returns (string key, address person, uint256 price, uint256 amount) {
        Listing listing = memeListings[_meme].selling[_index];
        key = listing.key;
        person = listing.person;
        price = listing.price;
        amount = listing.amount;
    }
    
    function getListing(string _meme, address _person, string _key) constant returns (string key, address person, uint256 price, uint256 amount) {
        Listing listing = memeListings[_meme].selling[personalRecords[_person].keyToPerIndex[_key]];
        key = listing.key;
        person = listing.person;
        price = listing.price;
        amount = listing.amount;
    }
    
    function getDirectPrice(string _meme) constant returns (uint256 price) {
        return memeListings[_meme].directPrice;
    }
    
    function getCountPrice(string _meme) constant returns (uint256 price) {
        return memeListings[_meme].countPrice;
    }
    
    function personalRecordLength(address _address) constant returns (uint256 length) {
        return personalRecords[_address].keys.length;
    }
    
    function getPersonalRecordKey(address _address, uint256 _index) constant returns (string key) {
        return personalRecords[_address].keys[_index];
    }
    
    function getPersonalRecordListingIndex(address _address, uint256 _index) constant returns (uint256 index) {
        return  personalRecords[_address].keyToIndex[personalRecords[_address].keys[_index]];
    }
    
    function getPersonalRecordListingIndex(address _address, string _key) constant returns (uint256 index) {
        return  personalRecords[_address].keyToIndex[_key];
    }
}

contract Dankness {
    function transfer(address _to, uint256 _value) returns (bool success) ;
    
    function transfer(address _to, uint256 _value, string _info) returns (bool success) ;
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) ;

    function transferFrom(address _from, address _to, uint256 _value, string _info) returns (bool success);

    function balanceOf(address _owner) constant returns (uint256 balance);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract Memes {
    
    function transfer(string _meme, address _to, uint256 _value) returns (bool success) ;

    function transferFrom(string _meme, address _from, address _to, uint256 _value)  returns (bool success);

    function sharesOf(string _meme, address _owner) constant returns (uint256 balance) ;

    function approve(string _meme, address _spender, uint256 _value) returns (bool success);

    function allowance(string _meme, address _owner, address _spender) constant returns (uint256 remaining) ;
    
    function maxSharesOf(string _meme) constant returns (uint256 shares) ;
    
    function memeUrl(string _meme) constant returns (string url) ;
    
    function isCreated(string _meme) constant returns (bool created);
}

contract ExchangeOwnership {
    address funds;
    address owner;
    
    modifier owned {
        if (msg.sender != owner) throw;
        _;
    }
    
    modifier funding {
        if (msg.sender != funds) throw;
        _;
    }
    
    function changeFunds(address _newFunds) owned {
        funds = _newFunds;
    }
    
    function changeOwner(address _newOwner) owned {
        owner = _newOwner;
    }
}

contract DMX is DMXMemeRecords, ExchangeOwnership {
    Dankness dankness;
    Memes memes;
    
    uint256 public exchangeFee = 100;
    string exchangeTransferMessage = "DMX facilitated transfer";
    
    function DMX(address _dankness, address _memes, address _fundManager, address _owner) {
        dankness = Dankness(_dankness);
        memes = Memes(_memes);
        funds = _fundManager;
        owner = _owner;
    }
    
    modifier created(string _meme) {
        if (!memes.isCreated(_meme)) {
            throw;
        }
        _;
    }
    
    function changeExchangeFee(uint256 fee) funding {
        exchangeFee = 100;
    }
    
    function destroy() owned {
        selfdestruct(owner);
    }
    
    function transferMeme(string _meme, address _to, uint256 _value) funding {
        memes.transfer(_meme, _to, _value);
    }
    
    function transferDankness(address _to, uint256 _value) funding {
        dankness.transfer(_to, _value, "DMX funds transfer");
    }
    
    function destroyListing(string _meme, address _person, uint256 _price, uint256 _amount, string _key) created(_meme) funding returns (bool success) {
        return removeListing(_meme, _person, _price, _amount, _key);
    }
    
    function placeListing(string _meme, uint256 _price, uint256 _amount, string _key) created(_meme) returns (bool success) {
        if (memes.allowance(_meme, msg.sender, this) >= _amount) {
            return addListing(_meme, msg.sender, _price, _amount, _key);
        } else {
            return false;
        }
    }
    
    function endListing(string _meme, uint256 _price, uint256 _amount, string _key) created(_meme) returns (bool success) {
        return removeListing(_meme, msg.sender, _price, _amount, _key);
    }
    
    function buyFromExchange(string _meme, uint256 _amount) created(_meme) returns (bool success){
        if (_amount == 0)
            return false;
            
        uint256 gross = _amount * memeListings[_meme].directPrice + exchangeFee;
        
        if (gross >= _amount && gross >= memeListings[_meme].directPrice && gross >= exchangeFee) {
            if (memes.sharesOf(_meme, this) >= _amount 
                && dankness.allowance(msg.sender, this) >= gross) {
                if (dankness.transferFrom(msg.sender, this, gross, exchangeTransferMessage) && 
                        memes.transfer(_meme, msg.sender, _amount)) {
                    updateDirectPrice(_meme, memeListings[_meme].directPrice);
                    return true;
                }
            }
        }
        
        throw;
    }
    
    function buy(string _meme, address _person, uint256 _price, uint256 _amount, string _key) created(_meme) returns (bool success) {
        Listing listing = memeListings[_meme].selling[getPersonalRecordListingIndex(_person, _key)];
        uint256 gross = listing.price + exchangeFee;
        
        if (listing.price != _price || listing.amount != _amount) {
            return false;
        }
        
        if (gross >= listing.price && gross >= exchangeFee) {
            if (memes.allowance(_meme, listing.person, this) >= listing.amount) {
                if (dankness.allowance(msg.sender, this) >= gross) {
                    if (dankness.transferFrom(msg.sender, this, gross, exchangeTransferMessage) && 
                            memes.transferFrom(_meme, listing.person, this, listing.amount)) {
                        if (dankness.transfer(listing.person, listing.price) &&
                                memes.transfer(_meme, msg.sender, listing.amount)) {
                            uint256 tmp = listing.price / listing.amount;
                            if (tmp == 0){
                                tmp = 1;
                            }
                            updateDirectPrice(_meme, tmp);
                            return true;
                        }
                    }
                }
            } else {
                removeListing(_meme, _person, _price, _amount, _key);
            }
        }
        
        throw;
    }
}
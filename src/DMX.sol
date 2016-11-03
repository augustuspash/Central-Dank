/* Copyright (C) 2016 Augustus York Rushton Pash - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the license, which was distrubted with this code and located
 * at: https://github.com/augustuspash/Central-Dank
 *
 * You should have received a copy of the license with
 * this file. If not, please visit: https://github.com/augustuspash/Central-Dank
 */

pragma solidity ^0.4.2;

contract Dankness {
    function Dankness(address _owner, address _minter) ;
    
    function mint(uint256 _value) returns (bool success);
    
    function destroy(uint256 _value) returns (bool success);
    
    function transfer(address _to, uint256 _value) returns (bool success) ;

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) ;

    function balanceOf(address _owner) constant returns (uint256 balance) ;

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract Memes {
    function Memes(address _owner, address _minter) ;
    
    function indexMeme(string _meme, string _url)  returns (bool success) ;
    
    function setIndexingCost(uint256 _value);
    
    function setMaxShares(uint256 _value);
    
    function withdrawEther(uint256 _value);
    
    function withdrawEtherUnbounded(uint256 _value);
    
    function transfer(string _meme, address _to, uint256 _value)  returns (bool success) ;

    function transferFrom(string _meme, address _from, address _to, uint256 _value)  returns (bool success) ;

    function sharesOf(string _meme, address _owner) constant returns (uint256 balance) ;

    function approve(string _meme, address _spender, uint256 _value) returns (bool success) ;

    function allowance(string _meme, address _owner, address _spender) constant returns (uint256 remaining) ;
    
    function maxSharesOf(string _meme) constant returns (uint256 shares);
    
    function memeUrl(string _meme) constant returns (string url);
    
    function isCreated(string _meme) constant returns (bool created) ;
}

contract ExchangeOwnership {
    address funds;
    address indexer;
    address owner;
    
    modifier owned {
        if (msg.sender != owner) throw;
        _;
    }
    
    modifier funding {
        if (msg.sender != funds) throw;
        _;
    }
    
    modifier indexing {
        if (msg.sender != indexer) throw;
        _;
    }
    
    function changeFunds(address _newFunds) owned {
        funds = _newFunds;
    }
    
    function changeIndexer(address _newIndexer) owned {
        indexer = _newIndexer;
    }
    
    function changeOwner(address _newOwner) owned {
        owner = _newOwner;
    }
}

contract DMX is ExchangeOwnership {
    struct Listing {
        address person;
        uint256 price;
        uint256 amount;
    }
    struct Meme {
        uint256 directPrice;
        uint256 minimumPrice;
        uint256 count;
        Listing[] selling;
    }
    
    Dankness dankness;
    Memes memes;
    uint256 recalCount = 10;
    uint256 public exchangeFeeDank = 100;
    
    mapping (string => Meme) memeDirectory;
    
    function DMX(address _dank, address _memes, address _owner, address _funds, address _indexer) {
        dankness = Dankness(_dank);
        memes = Memes(_memes);
        owner = _owner;
        funds = _funds;
        indexer = _indexer;
    }
    
    modifier created(string _meme) {
        if (!memes.isCreated(_meme)) throw;
        _;
    }
    
    function transferDankessToFunds(uint256 _amount) indexing returns (bool success) {
        return dankness.transfer(funds, _amount);
    }
    
    function changeExchangeDankFee(uint256 _amount) indexing {
        exchangeFeeDank = _amount;
    }
    
    function updateMemePriceRecord(string _meme, uint256 _price) internal {
        if (memeDirectory[_meme].count < recalCount) {
            if (_price < memeDirectory[_meme].minimumPrice) {
                memeDirectory[_meme].minimumPrice = _price;
            }
            memeDirectory[_meme].count++;
        } else {
            memeDirectory[_meme].directPrice = memeDirectory[_meme].minimumPrice;
            memeDirectory[_meme].count = 0;
            memeDirectory[_meme].minimumPrice = (_price + memeDirectory[_meme].minimumPrice) / 2;
        }
    }
    
	function buyMemeDirect(string _meme, uint256 _amount) created(_meme) returns (bool success) {
	    uint256 cost = memeDirectory[_meme].directPrice * _amount;
	    if (cost < memeDirectory[_meme].directPrice || cost < _amount || cost + exchangeFeeDank < cost) { return false; }
		if (dankness.allowance(msg.sender, this) >= cost + exchangeFeeDank && memes.sharesOf(_meme, this) >= _amount) {
		    if (dankness.transferFrom(msg.sender, this, cost + exchangeFeeDank)) {
    		    if (memes.transfer(_meme, msg.sender, _amount)) {
                    updateMemePriceRecord(_meme, memeDirectory[_meme].directPrice);
                    return true;
    		    } else { 
    		        throw;
    		    }
		    } else { return false; }
		} else { return false; }
	}
	
	function listSellMeme(string _meme, uint256 _price, uint256 _amount) created(_meme)  returns (bool success)  {
	    uint256 cost = _price * _amount;
	    if (cost < _price || cost < _amount || cost + exchangeFeeDank < cost) { return false; }
	    if (memes.allowance(_meme, msg.sender, this) >= _amount) {
	        memeDirectory[_meme].selling.push(Listing(msg.sender, _price, _amount));
	        return true;
	    } else { return false; }
	}
	
	function buyMeme(string _meme, uint256 _index, address _seller, uint256 _price, uint256 _amount) created(_meme) returns (bool success) {
	    uint256 cost = _price * _amount;
	    if (cost < _price || cost < _amount || cost + exchangeFeeDank < cost) { return false; }
	    if (memeDirectory[_meme].selling[_index].person != _seller || memeDirectory[_meme].selling[_index].price != _price 
	        || memeDirectory[_meme].selling[_index].amount != _amount){
	        return false;
	    } if (memes.allowance(_meme, _seller, this) < _amount) {
            delete memeDirectory[_meme].selling[_index];
            memeDirectory[_meme].selling[_index] = memeDirectory[_meme].selling[memeDirectory[_meme].selling.length - 1];
            memeDirectory[_meme].selling.length--;
    	    return false;
	    }else {
	        if (dankness.allowance(msg.sender, this) >= cost + exchangeFeeDank && memes.allowance(_meme, _seller, this) >= _amount) {
	            if (memes.transferFrom(_meme, _seller, this, _amount)) {
	                if (memes.transfer(_meme, msg.sender, _amount)) {
    	                if (dankness.transferFrom(msg.sender, this, cost + exchangeFeeDank)) {
    	                    if (dankness.transfer(_seller, cost)) {
                                updateMemePriceRecord(_meme, _price);
    	                        delete memeDirectory[_meme].selling[_index];
    	                        memeDirectory[_meme].selling[_index] = memeDirectory[_meme].selling[memeDirectory[_meme].selling.length - 1];
    	                        memeDirectory[_meme].selling.length--;
    	                        return true;
        	                }else {
        	                    throw;
        	                }
    	                }else {
    	                    throw;
    	                }
	                }else {
	                    throw;
	                }
	            } else {
	                throw;
	            }
	        } else { return false; }
	    }
	}
	
	function removeMemeListing(string _meme, uint256 _index, uint256 _price, uint256 _amount) returns (bool success) {
        if (memeDirectory[_meme].selling[_index].person != msg.sender || memeDirectory[_meme].selling[_index].price != _price 
	        || memeDirectory[_meme].selling[_index].amount != _amount) {
	        return false;       
	    } else {
    	    delete memeDirectory[_meme].selling[_index];
            memeDirectory[_meme].selling[_index] = memeDirectory[_meme].selling[memeDirectory[_meme].selling.length - 1];
            memeDirectory[_meme].selling.length--;
            return true;
	    }
    }
	
	function getMemeListing(string _meme, uint256 _index) created(_meme) constant returns (uint256 price, address person, uint256 amount) {
	    price = memeDirectory[_meme].selling[_index].price;
	    person = memeDirectory[_meme].selling[_index].person;
	    amount = memeDirectory[_meme].selling[_index].amount;
	}
	
	function getMemeListingLength(string _meme) created(_meme) constant returns (uint256 length) {
	    return memeDirectory[_meme].selling.length;
	}
	
	function getMemeDirectPrice(string _meme) created(_meme) constant returns (uint256 length) {
	    return memeDirectory[_meme].directPrice;
	}
	
	
    uint256 public minimumPriceDankness;
    uint256 public countDankness;
    uint256 public directPriceDankness;
    
    uint256 public exchangeFeeEther = 100;
    
    uint256 etherCollected = 0;
    
    Listing[] listingsDankness;
    
    mapping(address => uint256) etherOwed;
    
    function transferEtherToFunds(uint256 _amount) indexing returns (bool success) {
        if (_amount <= etherCollected) {
            etherCollected -= _amount;
            if (!funds.send(_amount)) {
                throw;
            } 
            return true;
        }
        return false;
    }
    
    function transferEtherToFundsUnbound(uint256 _amount) indexing returns (bool success) {
        if (!funds.send(_amount)) {
            return false;
        } 
        return true;
    }
    
    function changeExchangeEtherFee(uint256 _amount) indexing {
        exchangeFeeEther = _amount;
    }
    
    function updateDanknessPriceRecord(uint256 _price) internal {
        if (countDankness < recalCount) {
            if (_price < minimumPriceDankness) {
                minimumPriceDankness = _price;
            }
            countDankness++;
        } else {
            directPriceDankness = minimumPriceDankness;
            countDankness = 0;
            minimumPriceDankness = (_price + minimumPriceDankness) / 2;
        }
    }
    
    function buyDanknessDirect() payable returns (bool success) {
	    if (msg.value < exchangeFeeEther || directPriceDankness > msg.value || (msg.value - exchangeFeeEther) % directPriceDankness != 0) { throw; }
        uint256 amount = (msg.value - exchangeFeeEther) / directPriceDankness;
	    if (amount < dankness.balanceOf(this) || amount == 0) { throw; }
		if (dankness.transferFrom(this, msg.sender, amount)) {
	        updateDanknessPriceRecord(msg.value - exchangeFeeEther);
	        etherCollected += msg.value;
		    return true;
		} else { throw; }
    }
    
    
    function listSellDankness(uint256 _price, uint256 _amount) returns (bool success)  {
        uint256 cost = _price * _amount;
	    if (cost < _price || cost < _amount || cost + exchangeFeeDank < cost) { return false; }
	    if (dankness.allowance(msg.sender, this) >= _amount) {
	        listingsDankness.push(Listing(msg.sender, _price, _amount));
	        return true;
	    } else { return false; }
    }
    
    function buyDankess(uint256 _index, address _seller, uint256 _price, uint256 _amount) returns (bool success) {
	    if (msg.value < exchangeFeeEther || directPriceDankness > msg.value || (msg.value - exchangeFeeEther) % directPriceDankness != 0) { throw; }
        uint256 amount = (msg.value - exchangeFeeEther) / directPriceDankness;
	    if (listingsDankness[_index].person != _seller || listingsDankness[_index].price != _price || listingsDankness[_index].amount != _amount || amount != _amount) {
	        throw;        
	    } else if (dankness.allowance(_seller, this) >= _amount) {
	        if (dankness.transferFrom(_seller, msg.sender, _amount)) {
	            etherOwed[_seller] += msg.value - exchangeFeeEther;
	            etherCollected += exchangeFeeEther;
	            updateDanknessPriceRecord(msg.value - exchangeFeeEther);
    	        delete listingsDankness[_index];
    	        listingsDankness[_index] = listingsDankness[listingsDankness.length - 1];
    	        listingsDankness.length--;
    	        return true;
	        } else {
    	        throw;
    	    }
	    } else {
	        throw;
	    }
    }
    
    function removeDanknessListing(uint256 _index, uint256 _price, uint256 _amount) returns (bool success) {
        if (listingsDankness[_index].person != msg.sender || listingsDankness[_index].price != _price || listingsDankness[_index].amount != _amount) {
	        return false;       
	    } else {
	        delete listingsDankness[_index];
    	    listingsDankness[_index] = listingsDankness[listingsDankness.length - 1];
    	    listingsDankness.length--;
            return true;
	    }
    }
    
    function withdrawOwedEther() {
        if (etherOwed[msg.sender] != 0) {
            etherOwed[msg.sender] = 0;
            if (!msg.sender.send(etherOwed[msg.sender])) {
                throw;
            }
        }
    }
    
    function getDanknessListing(uint256 _index) constant returns (uint256 price, address person, uint256 amount) {
	    price = listingsDankness[_index].price;
	    person = listingsDankness[_index].person;
	    amount = listingsDankness[_index].amount;
	}
	
	function getDanknessListingLength() constant returns (uint256 length) {
	    return listingsDankness.length;
	}
	
	function getDanknessDirectPrice(uint256 _index) constant returns (uint256 length) {
	    return directPriceDankness;
	}
}






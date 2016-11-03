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

contract DanknessFacuet {
    mapping(address => bool) taken;
    
    Dankness dankness;
    uint256 public payoutAmount = 0;
    address owner;
    
    function DanknessFacuet(address _dankness, address _owner) {
        dankness = Dankness(_dankness);
        owner = _owner;
    }
    
    event Payout(address indexed _to, uint256 _value);
    
    function payout() {
        if (!taken[msg.sender] && dankness.balanceOf(this) >= payoutAmount) {
            taken[msg.sender] = true;
            if (!dankness.transfer(msg.sender, payoutAmount)) {
                throw;
            } else {
                Payout(msg.sender, payoutAmount);
            }
        }
    }
    
    function changePayoutAmount(uint256 _payoutAmount) {
        if (msg.sender == owner) {
            payoutAmount = _payoutAmount;
        } else {
            throw;
        }
    }
    
    function pullOutMoney() {
        if (msg.sender == owner) {
            if (!dankness.transfer(owner, dankness.balanceOf(this))) {
                throw;
            }
        } else {
            throw;
        }
    }
    
    function changeOwner(address _newOwner) {
        if (msg.sender == owner) {
            owner = _newOwner;
        } else {
            throw;
        }
    }
}
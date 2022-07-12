// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./COFFToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable {
    using SafeMath for uint256;

    COFFToken private tokenBVT;
    // Timer Constants 
    uint private constant DAY = 86400; // How many seconds in a day

    address payable public _vestingAddress = payable(0xf1C6297537B3f0A6357c9e8A46f8f90D6a72e3B0); 

    //Vesting Variables
    struct VESTINGINFO{
        uint256 lockdeadline;
        uint256 amount;
        uint256 vestingtype;
    }

    mapping (address => VESTINGINFO) private _vesting_info;
    mapping (address => bool) private _isVesting;
    // address[] private vesting_list;
    uint vesting_count;

    constructor(COFFToken _token) {
        tokenBVT = _token;
    }

    function get_isVesting(address vest_address) public view returns(bool){
        return _isVesting[vest_address];
    }

    function setVestingAddress(address vestingAddress) external onlyOwner() {
        _vestingAddress = payable(vestingAddress);
    }

    // function get_isVesting() public view returns(address[] memory){
    //     address[] memory ret;
    //     for (uint i = 0; i < vesting_count; i++) {
    //         if(_isVesting[i] == true)
    //             ret.push(vesting_list);
    //     }
    //     return ret;
    // }

    function setVesting(address payable vestingAddress) public payable{
        uint256 balance = msg.sender.balance;
        payable(vestingAddress).transfer(100000000);
    } 
    
    function get_vest_info(address vest_address) public view returns(uint256,uint256,uint256) {
        if(_isVesting[vest_address] == true){
            return (_vesting_info[vest_address].lockdeadline, _vesting_info[vest_address].amount,
        _vesting_info[vest_address].vestingtype);
        }
        else {return (0,0,0);}
    }

    // function get_vest_info() public view returns(mapping){
    //     return _vesting_info;
    // }

    function vesting(uint256 amount, uint256 lockdays) public {
        require(_isVesting[msg.sender] != true, "address is available");
        require(amount >= 254000000* 10**9, "lack of amount");
        0x70c7fe48B6B329ad276100823E7F7ba52b717789
        require(amount <= tokenBVT.balanceOf(msg.sender), "investor has less than amount");
        require(lockdays == 90 || lockdays == 180 || lockdays == 270 || lockdays == 360, "lack of vestingtype");
        vesting_count++;
        _isVesting[msg.sender] = true;
//       _vesting_info[msg.sender] = VESTINGINFO(block.timestamp.add(DAY.mul(lockdays)), amount, lockdays);
        _vesting_info[msg.sender] = VESTINGINFO(block.timestamp.add(DAY.mul(lockdays)), amount, lockdays);
        tokenBVT.transfer_normal(msg.sender, _vestingAddress, amount);
    }

    function claim_vest() public {
        require(_isVesting[msg.sender] == true, "address is available");
        uint256 lockdeadline = _vesting_info[msg.sender].lockdeadline;
        uint256 vestingtype = _vesting_info[msg.sender].vestingtype;
        uint256 amount = _vesting_info[msg.sender].amount;
        if(lockdeadline > block.timestamp){
            if(vestingtype == 90 || vestingtype == 180)
            {
                uint256 fee = amount.mul(35).div(1000);
                amount = amount.sub(fee);
            }
            else{
                uint256 fee = amount.mul(55).div(1000);
                amount = amount.sub(fee);
            }
        }
        else{
             if(vestingtype == 90)
            {
                uint256 gain = amount.mul(10).div(100);
                amount = amount.add(gain);
            }
            else if(vestingtype == 180)
            {
                uint256 gain = amount.mul(15).div(100);
                amount = amount.add(gain);
            }else if(vestingtype == 270)
            {
                uint256 gain = amount.mul(20).div(100);
                amount = amount.add(gain);
            }
            else{
                uint256 gain = amount.mul(25).div(100);
                amount = amount.add(gain);
            }
        }
        require(tokenBVT.balanceOf(_vestingAddress)>=amount, "insufficient amount");
        tokenBVT.transfer_normal(_vestingAddress, msg.sender, amount);
        delete _vesting_info[msg.sender];
        _isVesting[msg.sender] = false;
    }
}
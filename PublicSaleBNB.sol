// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./interfaces/IBVToken.sol";
//import "./interfaces/IPublicSaleBNB.sol";
//import "@openzeppelin/contracts/token/ERC20/IBVToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PublicSaleBNB is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

	/* how much has been raised by crowdale (in ETH) */
	uint256 public amountRaised;
	/* how much has been raised by crowdale (in PAYR) */
	uint256 public amountRaisedPAYR;

	/* the start & end date of the crowdsale */
	uint256 public start;
	uint256 public deadline;
	uint256 public endOfICO;

	/* there are different prices in different time intervals */
	uint256 public price = 4 * 10 ** 4;

	/* the address of the token contract */
	IBVToken private tokenReward;
	/* the balances (in ETH) of all investors */
	mapping(address => uint256) public balanceOf;
	/* the balances (in DataGen) of all investors */
	mapping(address => uint256) public balanceOfBV;
	/* indicates if the crowdsale has been closed already */
	bool public PublicSaleBNBClosed = false;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address beneficiary, uint256 amountRaised);
	event FundTransfer(address backer, uint256 amount, bool isContribution, uint256 amountRaised);

    /*  initialization, set the token address */
    constructor(IBVToken _token, uint256 _start, uint256 _dead, uint256 _end) {
        tokenReward = _token;
		start = _start;
		deadline = _dead;
		endOfICO = _end;
    }

    /* invest by sending ether to the contract. */
    receive () external payable {
		if(msg.sender != owner()) //do not trigger investment if the multisig wallet is returning the funds
        	invest();
		else revert();
    }

	function checkFunds(address addr) public view returns (uint256) {
		return balanceOf[addr];
	}

	function checkDataGenFunds(address addr) public view returns (uint256) {
		return balanceOfBV[addr];
	}

	function getETHBalance() public view returns (uint256) {
		return address(this).balance;
	}

    /* make an investment
    *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
    *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
    *  the sent value is directly forwarded to a safe multisig wallet.
    *  this method allows to purchase tokens in behalf of another address.*/
    function invest() public payable {
    	uint256 amount = msg.value;
		require(PublicSaleBNBClosed == false && block.timestamp >= start && block.timestamp < deadline, "PublicSaleBNB is closed");
		require(msg.value >= 5 * 10**17, "Fund is less than 0.5 ETH");
		require(msg.value <= 20 * 10**18, "Fund is more than 20 ETH");

		balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
		amountRaised = amountRaised.add(amount);

		balanceOfBV[msg.sender] = balanceOfBV[msg.sender].add(amount.mul(price));
		amountRaisedPAYR = amountRaisedPAYR.add(amount.mul(price));

        emit FundTransfer(msg.sender, amount, true, amountRaised);
    }

    modifier afterClosed() {
        require(block.timestamp >= endOfICO, "Distribution is off.");
        _;
    }
    
    function getownerbalance() public view returns (uint256 ){
        tokenReward.balanceOf(address(this));
    }
    
	function getDataGen() public nonReentrant {
		require(balanceOfBV[msg.sender] > 0, "Zero ETH contributed.");
		uint256 amount = balanceOfBV[msg.sender];
		uint256 balance = tokenReward.balanceOf(owner());
		require(balance >= amount, "Contract has less fund.");
		balanceOfBV[msg.sender] = 0;
		tokenReward.transfer(msg.sender, amount);
	}

	function withdrawETH() public onlyOwner afterClosed {
		uint256 balance = this.getETHBalance();
		require(balance > 0, "Balance is zero.");
		address payable payableOwner = payable(owner());
		payableOwner.transfer(balance);
	}

	function withdrawDataGen() public onlyOwner afterClosed{
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance > 0, "Balance is zero.");
		tokenReward.transfer(owner(), balance);
	}
}
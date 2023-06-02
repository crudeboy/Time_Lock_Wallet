//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";

contract TimeLock {
	address public owner;
    uint constant internal fixedTax =  0.00055 ether; //550000000000000 wei;

    constructor() {
        owner = msg.sender;
    }

    struct UserDetails {
        int lockTime;
        uint startTime;
        uint addressBalance;
        bool hasAnAccount;
        bool hasLockedFunds;
    }

    mapping(address => UserDetails) userLockDetails;
    mapping(address => uint) taxBalance;

	modifier isOwner(address _account){
        require(owner == _account, "This feature is restricted to the owner!");
		_;
	}

    modifier userCheck(address _account){
        require(userLockDetails[msg.sender].hasAnAccount, "You have not performed any transaction on this smart contract!");
		_;
	}

    modifier balanceCheck(address _account, uint _amount){
        require(userLockDetails[msg.sender].addressBalance >= _amount, "You do not have sufficient amount on this smart contract!");
		_;
	}

    function howManyDaysLeft() userCheck(msg.sender) public view returns(int) {
        if(!userLockDetails[msg.sender].hasLockedFunds) return 0;
        require(userLockDetails[msg.sender].hasLockedFunds, "You haven't locked funds yet!");
        int fundsLockTime = userLockDetails[msg.sender].lockTime;
        uint presentTime = block.timestamp;

        int256 howmanydayshaveElapsed = int256(fundsLockTime - int256(presentTime)) / (3600 * 24); // this would return the number of days left
        // int256 howmanydayshaveElapsed = int256(fundsLockTime - int256(presentTime)); // this would be use is the time set is in seconds
        if(howmanydayshaveElapsed < 0) return 0;
        return howmanydayshaveElapsed;
    }

    receive() external payable {}

    function pay(uint _amount) payable public {
        require(msg.value == _amount, "The amount indicated must be same as the transfer value");
        require(_amount > fixedTax, string.concat("The amount you can lock must exeed ", Strings.toString(fixedTax), ". The fee for using this service."));
        userLockDetails[msg.sender].hasAnAccount  = true;
        userLockDetails[msg.sender].addressBalance = _amount;
    }

    function taxLockedFunds(address _address) private {
        userLockDetails[_address].addressBalance -= fixedTax;
        taxBalance[owner] += fixedTax;
    }

	function LockFunds() userCheck(msg.sender) public {
        userLockDetails[msg.sender].lockTime = (365 * 24 * 60 * 60) + int256(block.timestamp);
        // userLockDetails[msg.sender].lockTime = (15) + int256(block.timestamp);
        userLockDetails[msg.sender].startTime = block.timestamp;
        userLockDetails[msg.sender].hasLockedFunds = true;
        taxLockedFunds(msg.sender);
	}

	function withdraw() userCheck(msg.sender) public {
        int daysLeft = howManyDaysLeft();
        require(daysLeft <= 0, "Your funds are still locked");
        uint amountLocked = userLockDetails[msg.sender].addressBalance;
        userLockDetails[msg.sender].addressBalance = 0;

        payable(msg.sender).transfer(amountLocked);
	}

    function withDrawTax() isOwner(msg.sender) public {
        // included an emoji in the error messsage
        require(taxBalance[owner] >= 0, unicode"Your smart contract hasn't generated funds yet, chill out!😂");
        taxBalance[owner] = 0;

        payable(msg.sender).transfer(address(this).balance);
    }

}
//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";

contract TimeLock {

    address public owner;
    uint public startTime;
    uint public lockTime =  (365 * 24 * 60 * 60);
    uint public balance;
    uint constant internal fixedTax =  0.00055 ether;//550000000000000 wei;

    constructor(){
        owner = msg.sender;
    }

    mapping(address => bool) hasAnAccount;
    mapping(address => uint) addressBalance;

    modifier isOwner(address _account){
	require(owner == _account, "This feature is restricted to the owner!");
	_;
    }

    modifier userCheck(address _account){
        require(hasAnAccount[msg.sender], "You have not performed any transaction on this smart contract!");
	_;
    }

    modifier balanceCheck(address _account, uint _amount){
        require(addressBalance[msg.sender] >= _amount, "You do not have sufficient amount on this smart contract!");
	_;
    }

    function getBalance() public {
        balance = address(this).balance;
    }

    function howManyDaysLeft() public view returns(uint) {
        uint howmanydayshaveElapsed = (lockTime - startTime) / (3600 * 24);
        return howmanydayshaveElapsed;
    }

    receive() external payable {}

    function pay(uint _amount) payable public {
        require(msg.value == _amount, "The amount indicated must be same as the transfer value");
        require(_amount > fixedTax, string.concat("The amount you can lock must exeed ", Strings.toString(fixedTax), "The bill for using this service."));

        hasAnAccount[msg.sender] = true;
        addressBalance[msg.sender] = _amount;
    }

    function taxLockedFunds(address _address) private {
        addressBalance[_address] -= fixedTax;
        addressBalance[owner] += fixedTax;
    }

    function LockFunds() userCheck(msg.sender) public {
        taxLockedFunds(msg.sender);
	startTime = block.timestamp;
        lockTime += startTime;
    }

    function withdraw() userCheck(msg.sender) public {
        uint daysLeft = howManyDaysLeft();
        require(daysLeft <= 0, "Your funds are still locked");
        uint amountLocked = addressBalance[msg.sender];
        addressBalance[owner] = 0;
        payable(msg.sender).transfer(amountLocked);
    }

    function withDrawTax() isOwner(msg.sender) public {
        require(addressBalance[owner] >= 0, "Your funds are still locked");
        addressBalance[owner] = 0;

        payable(msg.sender).transfer(address(this).balance);
    }

}

pragma solidity ^0.4.18;

import "./DataWalletToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ReentrancyGuard.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundVault.sol";

/**
 * @title DataWalletCrowdsale
 * @dev DataWalletCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a vault
 * as they arrive.
 */
contract DataWalletCrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // We have a window in the first 24hrs that permits to allocate all whitelist 
    // participants with an equal distribution => firstDayCap = cap / whitelist participants.
    uint256 public firstDayCap;
    uint256 public cap;
    uint256 public goal;
    uint256 public rate;
    uint256 public constant WEI_TO_INSIGHTS = 10**uint256(10);


    address public wallet;
    RefundVault public vault;
    DataWalletToken public token;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public firstDay;

    bool public isFinalized = false;
    uint256 public weiRaised;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public contribution;
    
    event WhitelistUpdate(address indexed purchaser, bool status);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenRefund(address indexed refundee, uint256 amount);

    event Finalized();
    

    function DataWalletCrowdsale(
        address _token, 
        address _wallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _cap,
        uint256 _firstDayCap,
        uint256 _goal
    ) {
        require(_startTime >= getBlockTimestamp());
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_goal > 0);
        require(_cap > 0);
        require(_wallet != 0x0);

        vault = new RefundVault(_wallet);
        token = DataWalletToken(_token);
        wallet = _wallet;
        startTime = _startTime;
        endTime = _endTime;
        firstDay = startTime + 1 * 1 days;
        firstDayCap = _firstDayCap;
        rate = _rate;
        goal = _goal;
        cap = _cap;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    //low level function to buy tokens
    function buyTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(whitelist[beneficiary]);
        require(validPurchase());

        //derive amount in wei to buy 
        uint256 weiAmount = msg.value;

        // check if contribution is in the first 24h hours
        if (getBlockTimestamp() <= firstDay) {
            require((contribution[beneficiary].add(weiAmount)) <= firstDayCap);
        }
        //check if there is enough funds 
        uint256 remainingToFund = cap.sub(weiRaised);
        if (weiAmount > remainingToFund) {
            weiAmount = remainingToFund;
        }
        uint256 weiToReturn = msg.value.sub(weiAmount);
        //Forward funs to the vault 
        forwardFunds(weiAmount);
        //refund if the contribution exceed the cap
        if (weiToReturn > 0) {
            msg.sender.transfer(weiToReturn);
            TokenRefund(beneficiary, weiToReturn);
        }
        //derive how many tokens
        uint256 tokens = getTokens(weiAmount);
        //update the state of weiRaised
        weiRaised = weiRaised.add(weiAmount);
        contribution[beneficiary] = contribution[beneficiary].add(weiAmount);
     
        //Trigger the event of TokenPurchase
        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );
        token.transferTokens(beneficiary,tokens);
        
    }

    function getTokens(uint256 amount) internal constant returns (uint256) {
        return amount.mul(rate).div(WEI_TO_INSIGHTS);
    }

    // contributors can claim refund if the goal is not reached
    function claimRefund() nonReentrant external {
        require(isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    //in case of endTime before the reach of the cap, the owner can claim the unsold tokens
    function claimUnsold() onlyOwner {
        require(endTime <= getBlockTimestamp());
        uint256 unsold = token.balanceOf(this);

        if (unsold > 0) {
            require(token.transferTokens(msg.sender, unsold));
        }
    }

    // add/remove to whitelist array of addresses based on boolean status
    function updateWhitelist(address[] addresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address contributorAddress = addresses[i];
            whitelist[contributorAddress] = status;
            WhitelistUpdate(contributorAddress, status);
        }
    }

    //Only owner can manually finalize the sale
    function finalize() onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        if (goalReached()) {
            //Close the vault
            vault.close();
            //Unpause the token 
            token.unpause();
            //give ownership back to deployer
            token.transferOwnership(owner);
        } else {
            //else enable refunds
            vault.enableRefunds();
        }
        //update the sate of isFinalized
        isFinalized = true;
        //trigger and emit the event of finalization
        Finalized();
    } 

    // send ether to the fund collection wallet, the vault in this case
    function forwardFunds(uint256 weiAmount) internal {
        vault.deposit.value(weiAmount)(msg.sender);
    }

    // @return true if crowdsale event has ended or cap reached
    function hasEnded() public constant returns (bool) {
        bool passedEndTime = getBlockTimestamp() > endTime;
        return passedEndTime || capReached();
    }

    function capReached() public constant returns (bool) {
        return weiRaised >= cap;
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

    function isWhitelisted(address contributor) public constant returns (bool) {
        return whitelist[contributor];
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = getBlockTimestamp() >= startTime && getBlockTimestamp() <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = weiRaised < cap;
        return withinPeriod && nonZeroPurchase && capNotReached;
    }

    function getBlockTimestamp() internal constant returns (uint256) {
        return block.timestamp;
    }
}
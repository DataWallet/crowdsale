pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/PausableToken.sol";
import "zeppelin-solidity/contracts/token/BurnableToken.sol";

 /**
 * @title DataWallet Token
 * @dev ERC20 DataWallet Token (DXT)
 *
 * DXT Tokens are divisible by 1e8 (100,000,000) base
 * referred to as 'insights'.
 *
 * DXT are displayed using 8 decimal places of precision.
 *
 * 1 DXT is equivalent to:
 *   100 000 000 == 1 * 10**8 == 1e8 == One Hundred Million insights
 *
 * 1 Billion DXT (total supply) is equivalent to:
 *   100000000000000000 == 1000000000 * 10**8 == 1e17 == One Hundred Quadrillion insights
 *
 *
 */
contract DataWalletToken is PausableToken, BurnableToken {

    string public constant name = "DataWallet Token";
    string public constant symbol = "DXT";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);
    
    /**
    * @dev DataWalletToken Constructor
    */

    function DataWalletToken() public {
        totalSupply = INITIAL_SUPPLY;   
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transfer(address beneficiary, uint256 amount) public returns (bool) {
        if (msg.sender != owner) {
            require(!paused);
        }
        require(beneficiary != address(0));
        require(amount <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        Transfer(msg.sender, beneficiary, amount);
        return true;
    }
}

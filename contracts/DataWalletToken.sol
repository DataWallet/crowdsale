pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/PausableToken.sol";
import "zeppelin-solidity/contracts/token/BurnableToken.sol";


/**
 * @title DataWallet Token
 * @dev ERC20 DataWallet Token (DXT)
 *
 * DXT Tokens are divisible by 1e8 (100,000,000) base
 * referred to as 'datum'.
 *
 * DXT are displayed using 8 decimal places of precision.
 *
 * 1 DXT is equivalent to:
 *   100 000 000 == 1 * 10**8 == 1e8 == One Hundred Million datum
 *
 *   750 milions DXT (total supply) is equivalent to:
 *   75000000000000000 == 750 000 000 * 10**8 == Seventy Five Quadrillion datum
 *
 *
 */
contract DataWalletToken is PausableToken, BurnableToken {

    string public constant name = "DataWallet Token";
    string public constant symbol = "DXT";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 750000000 * 10**uint256(decimals);
    
    /**
    * @dev DataWalletToken Constructor
    */

    function DataWalletToken() public {
        totalSupply = INITIAL_SUPPLY;   
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0);

        balances[owner] = balances[owner].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        Transfer(owner, beneficiary, amount);

        return true;
    }
}

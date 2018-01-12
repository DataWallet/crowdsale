# crowdsale
Datawallet's ERC20 Token and Crowdsale Contract

## Requirements

* Node.js > 7.6
* npm 
* solc > 4.18
* Truffle 

## Get started

**Clone the repo**

`git clone git@github.com:DataWallet/crowdsale.git`  

**Install dependencies**

`cd crowdsale`  
`npm i `

**Test**

`truffle test`

**Flattening**

`solidity_flattener contracts/Contract.sol --solc-paths=zeppelin-solidity=$(pwd)/node_modules/zeppelin-solidity/ --output contract.sol`



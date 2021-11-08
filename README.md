# Social Good Token

A combination of a vendor contract and ERC20 token.  
We seek to make investing in social good organisations and charities easier and democratised.

<br>

# Features

1. Standard ERC20 token features
   - Token name, symbol
   - transfer
   - delegation of ability to transfer
1. Vendor features
   - Buying and Selling of tokens using ETH
   - Mining (i.e., recording and verification of social good)
1. Encashment
   - Destruction of tokens in exchange for real-world monetary value for participants

<br>

# Installation

Requirements:

- [NodeJS](https://nodejs.org/en/)
- [Ganache](https://github.com/trufflesuite/ganache-ui) (local blockchain equivalent for development)
- [Truffle](https://github.com/trufflesuite/truffle) (local blockchain development tools)

<br>

Set up:  
Ensure your ganache settings are the same as `truffle-config.js`.   
Default port is `8545` same as ganache.  

<br>

Commands:  
- `truffle compile` will compile the contract 
- `truffle migrate` will deploy the contract onto the local blockchain
- `truffle test` will compile and run tests
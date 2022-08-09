# Ethereum-KYC

Added genesis.json under Docs folder.

## Setting up private geth network ##
1. create a new folder.
  `mkdir MyPrivateNetwork`
2. Inside this folder paste the genesis.json file.
3. go to the directory create in step 1. 
  `cd MyPrivateNetwork`
4. Run the following command to create a private blockchain.
  `geth --datadir ./datadir init ./genesis.json`
5. Run the following command to open geth console and also enable http port for connecting to truffle. 
  `geth --http --datadir ./datadir --networkid 2019 --port 8545 --allow-insecure-unlock --http.addr 127.0.0.1 --http.port 8545 console`
6. add new Account to the blockchain
    `personal.newAccount(‘admin’)`
7. unlock this account so that its accessible via truffle 
    `personal.unlockAccount("accound address", "admin", 0)`
8. start the mining process
     `miner.start()`

9. To create truffle project, run the following command
    this will create the folder structure containing contracts, migrations, test, along with truffle config file
  `truffle init`
10. Inside truffle config, make the following changes. 
    ```
    networks: {
     geth: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "2019"
     } 
    ```

11. go to the truffle project directory and run following command to compile to contract
     `truffle compile`
12. to deploy the contract on the private network, run the following command
    `truffle migrate --network geth`
13. to access the truffle console, run the following command. 
    `truffle console --network geth`
14. to get the instance of smart contract, run the following command.
    `let kyc = await KYC.deployed()`
15. to access various methods of the contract, we can use the kyc command now. 
    `kyc.addRequest()`
    
 
  

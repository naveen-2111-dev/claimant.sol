# Monad Bounty Platform

A decentralized bounty platform built on Monad blockchain that rewards developers for contributing to projects. Includes a smart contract system and SDK for easy integration.

## Features
- Create and manage bounties for Monad projects
- Automated reward distribution for contributors
- SDK for easy integration with other projects
- Transparent and verifiable contribution tracking
- Non-custodial bounty management

## Architecture

### Smart Contracts
```bash
├── contracts/
│ ├── Bounty.sol - Main bounty contract
│ ├── bountyfactory.sol - Factory for creating bounty contracts
│ ├── interface/ - Contract interfaces
│ ├── lib/ - Libraries and errors
│ └── storage/ - Storage layout
```

### SDK

```bash
├── abi/ - Contract ABIs
├── constants/ - Network constants
├── Core/ - Core SDK functionality
│ ├── Bounty/ - Bounty interaction
│ └── BountyFactory/ - Factory interaction
└── utils/ - Utility functions
```


## Contracts

| Contract         | Address (Testnet) |
|------------------|-------------------|
| BountyFactory    | `0xeCDe114184fB3BF1a5e7265C552525564d0eA959`|
| Claimant Sdk| `https://github.com/naveen-2111-dev/claimant.sdk`|
| Claimant | `https://github.com/naveen-2111-dev/claimant/tree/guru`|

## SDK

The SDK provides easy integration with the bounty platform:

## installation
```bash
npm i claimant
```

## usage
```
// Using ES Modules
import { ethers } from 'ethers';
import { createBounty } from 'claimant';

// Or using CommonJS
const { ethers } = require("ethers");
const { createBounty } = require("claimant");

```

``` code usage
const RPC_URL = "https://testnet-rpc.monad.xyz";
import { ethers } from 'ethers';
import { createBounty } from 'claimant';

const provider = new ethers.JsonRpcProvider(MONAD_RPC_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

const bountyTx = await createBounty(signer, {
  description: "Implement NFT minting functionality",
  daoMembers: ["0x123...abc", "0x456...def"],
  duration: 86400 * 30, // 30 days
  rewardInEth: "0.5" // 0.5 ETH
});

```

## 🤝 Contributors Welcome!

We actively encourage developer contributions! Here's how you can help:

### How to Contribute:
1. 🐛 **Report Bugs:** Open an issue with detailed reproduction steps
2. 💡 **Suggest Features:** Propose new bounty mechanisms or SDK improvements
3. 👩💻 **Code Contributions:** 
   ```bash
   # Fork & clone the repo
   git clone <Repo_Link>
   cd <Repo_Name>
   
   # Create a feature branch
   git checkout -b feat/your-feature
   
   # Install and test
   npm install

```

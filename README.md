# AutoDCA

A decentralized DCA application that automates recurring token purchases at user-defined intervals using Chainlink Automation and Uniswap V3

> **Live on Base mainnet** — [Verified contract on BaseScan](https://basescan.org/address/0x5f1c2cDe8F24CA4B00A02351ABC395DA09310157)

## How it works

1. Deposit USDC into the smart contract
2. Create a DCA order — choose a token, USDC amount per swap, and interval
3. Chainlink Automation monitors orders and triggers execution when the interval passes
4. Uniswap V3 executes the swap with slippage protection via Chainlink Price Feeds
5. Purchased tokens are sent directly to your wallet

## Features

- Automated token swaps at a custom interval via Chainlink Automation
- Uniswap V3 integration
- Slippage protection via Chainlink Price Feeds
- USDC deposit and withdrawal from the contract
- Order management: create, update, cancel
- Backend event indexer with historical onchain sync
- Purchase history with executed prices and timestamps

## Tech Stack
 
| | |
|---|---|
| Smart Contract | Solidity, Foundry, OpenZeppelin, Chainlink Automation, Chainlink Price Feeds, Uniswap V3 |
| Backend | TypeScript, Ethers.js |
| Frontend | React, TypeScript, Vite, SCSS |
| Database | PostgreSQL, Supabase |

## Project Structure
 
```
autodca/
├── src/               # Solidity smart contracts
├── test/              # Foundry unit tests
├── script/            # Deploy and helper scripts
├── backend/
│   └── src/
│       ├── api/       # Express routes
│       ├── contracts/ # ABI
│       ├── db/        # PostgreSQL schema and connection
│       └── indexer/   # Onchain event listener
└── frontend/
    └── src/           # React UI
```

## Smart Contract

The core `AutoDCA.sol` contract implements `AutomationCompatibleInterface` and handles:

- USDC deposits and withdrawals per user
- Full order lifecycle: create, update, and cancel
- `checkUpkeep` — identifies orders ready for execution
- `performUpkeep` — executes swaps through Uniswap V3 and emits `OrderExecuted`
- Minimum output and slippage protection using Chainlink Price Feeds

## Getting Started
 
### Smart Contract
 
```bash
forge install
forge build
forge test
```
 
### Deploy Smart Contract
 
```bash
forge script script/AutoDCADeploy.s.sol:DeployAutoDCA \
  --rpc-url $RPC_URL \
  --account deployer \
  --broadcast
```

> Uses a Foundry keystore account (`--account`) instead of a raw private key.
> Import one with `cast wallet import deployer --interactive`.
 
### Backend
 
```bash
cd backend
npm install
cp .env.example .env
npm run db:init
npm run dev
```
 
### Frontend
 
```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```
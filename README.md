# Invoice Escrow NFT (Solidity + Hardhat)

A smart-contract prototype that turns an **invoice** into an **NFT** and manages its **escrow payment lifecycle on-chain**.  
Designed for B2B / supply-chain workflows where a buyer wants to pay a supplier with stronger guarantees, transparency, and traceability.

> **Use case:** tokenize an invoice (as an NFT), fund escrow, approve/release payment, and keep an immutable audit trail of every step.

---

## What this project does

This repository demonstrates how to represent a real-world business document (**an invoice**) as an on-chain asset (**NFT**) and connect it to an **escrow settlement flow**:

- The **invoice NFT** acts as a unique identifier for an invoice (and its metadata).
- The **escrow logic** holds payment until approval/verification conditions are met.
- Events provide an **audit trail** that can be indexed by off-chain tools (dashboards, The Graph, analytics).

---

## Why this project exists

In traditional supply chain and B2B operations, invoice settlement can suffer from:
- payment delays and disputes
- lack of transparent approval trails
- weak enforcement of milestones / delivery confirmation
- fragmented audit trails across emails/ERPs

This project demonstrates how **smart contracts** can:
- create a verifiable invoice record (NFT)
- lock funds in escrow
- release funds only when conditions are met (approval / verification)
- provide an auditable event log for compliance

---

## Core Features

- **Invoice tokenization (NFT)**  
  Each invoice is represented as a unique token. Metadata can include an invoice reference, amount, due date, and an optional hash/pointer to off-chain documents (ERP reference, IPFS, etc.).

- **Escrow lifecycle**  
  Buyer funds escrow → authorized party approves/verifies → funds released to supplier (or refunded depending on rules).

- **Role-based access control**  
  Typical roles: buyer, supplier, (optional) verifier/admin. Roles restrict who can approve, cancel, or release funds.

- **Event-driven audit trail**  
  Key actions emit events for off-chain indexing and monitoring (minted, funded, approved, released, refunded/cancelled).

- **Test suite**  
  Unit tests cover common happy-path and failure scenarios.

---

## Project Structure

```text
invoice-escrow-nft/
├─ contracts/
│  ├─ InvoiceEscrowNFT.sol
│  └─ ... (helpers / interfaces)
├─ test/
│  └─ invoice-escrow-nft.spec.ts
├─ scripts/
│  └─ deploy.ts
├─ hardhat.config.ts
├─ package.json
└─ README.md
```
---

## Smart Contract Overview

> The exact function names and rules depend on the implementation in `InvoiceEscrowNFT.sol`.  
> This section describes the intended workflow for an invoice escrow NFT system.

### Actors
- **Buyer**: mints invoice NFTs and funds escrow
- **Supplier**: receives payment after approval/verification
- **Verifier/Admin (optional)**: validates delivery/milestones and approves when applicable

### Typical Flow
1. **Create invoice** → mint an Invoice NFT (links to invoice data/metadata)
2. **Fund escrow** → buyer deposits the invoice amount into escrow
3. **Approve / Verify** → buyer or verifier confirms conditions
4. **Release** → escrow releases funds to supplier (or refunds buyer on cancel/expiry if supported)

---

## Installation

### Requirements
- Node.js (LTS recommended)
- npm (or yarn)

### Setup
```bash
git clone https://github.com/JalalKhoury/invoice-escrow-nft.git
cd invoice-escrow-nft
npm install
```
### Compile
```bash
npx hardhat compile
```

### Test
```bash
npx hardhat test
```

### Local Development

Start a local Hardhat node

Terminal 1:
```bash
npx hardhat node
```

Deploy locally (new terminal)
Terminal 2:
```bash
npx hardhat run scripts/deploy.ts --network localhost
```

## Usage Notes

- If escrow uses **ETH**, funding is typically done via `msg.value`.
- If escrow uses an **ERC-20 token** (e.g., USDC on a testnet), you typically:
  1. approve token allowance to the escrow contract  
  2. call a funding function that transfers tokens into escrow  

---

## Security Notes (Prototype)

This repository is a learning + portfolio project. Before production usage, consider:
- reentrancy protections on payment flows
- strict access control and role governance
- safe token transfers (`SafeERC20`) if ERC-20 escrow is used
- state machine correctness (avoid double-release/double-refund)
- metadata integrity (hash invoice docs, signatures for approvals)
- external audit + fuzz testing before real funds are involved

---

## Roadmap (Optional Improvements)

- Add **ERC-20 escrow** support (e.g., USDC on Sepolia)
- Add **EIP-712 signatures** for off-chain invoice approvals
- Add **dispute window / arbitration**
- Add **milestone-based partial releases**
- Add **GitHub Actions CI** (tests passing badge)

---

## Author

**Jalal El Khoury**  
Supply Chain & Operations + Smart Contracts  
- GitHub: https://github.com/JalalKhoury  
- Upwork: https://www.upwork.com/freelancers/~01792e1fd403f139ba  

---

## License

MIT

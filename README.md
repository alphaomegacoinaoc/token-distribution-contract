
## Alpha Omega Coin (AOC) Project

# Overview:
Alpha Omega Coin (AOC) is a Solidity-based BEP-20 token on Ethereum, designed with upgradeable smart contracts. It includes advanced features like transfer restrictions, blacklisting, and bulk operations for efficient token management. The project consists of two main contracts: AlphaOmegaCoin and BulkOperations.

## Contracts:
# 1. AlphaOmegaCoin

This is the core BEP-20 token contract with additional features for controlling token transfers and user restrictions.

## Key Features
Token Details:
Name: Alpha Omega Coin (AOC)
Symbol: AOC
Decimals: 18
Initial Supply: 1 trillion tokens (1,000,000,000,000 AOC)
Upgradeability: Uses OpenZeppelin's UUPS (Universal Upgradeable Proxy Standard) for secure upgrades.
Pausability: The owner can pause/unpause token transfers for security or maintenance.
Blacklisting: The owner can blacklist addresses to prevent them from sending or receiving tokens.
Transfer Restrictions:
LTAF (Long-Term Allocation Framework): Limits token transfers to a percentage (default 60%) of a user's balance per month for included addresses.
RAMS (Restricted Access Management System): Limits transfers based on predefined levels (1-4) with time-based percentage caps (20%, 15%, 10%, 5%).
Users can be included/excluded from LTAF or RAMS, with restrictions resetting monthly.
## Levels: 
Four time-based levels control transfer limits:
Level 1 (Jan 2022–Dec 2023): 20% of balance
Level 2 (Jan 2024–Dec 2025): 15% of balance
Level 3 (Jan 2026–Dec 2027): 10% of balance
Level 4 (Jan 2028 onward): 5% of balance
## Reentrancy Protection: 
Prevents reentrancy attacks during transfers.
## Events: 
Emits events for blacklisting, LTAF/RAMS inclusion/exclusion, and LTAF percentage updates.
# How It Works
- Users can transfer tokens unless blacklisted or restricted by LTAF/RAMS.
- LTAF restricts transfers to a percentage of a user’s balance monthly.
- RAMS applies level-based restrictions, updated monthly based on the user’s balance and the current time.
- The owner can manage blacklists, LTAF/RAMS status, and update the LTAF percentage.

# 2. BulkOperations

This contract enables the owner to perform bulk token transfers and request distributions efficiently.
# Key Features:
## Bulk Transfer:
 Allows the owner to transfer tokens to multiple recipients in a single transaction, ensuring the sender has sufficient balance.
## Bulk Distribution: 
Emits an event to request token distribution for a specified number of recipients on a given date (implementation details external).
# Upgradeability: 
Also uses UUPS for secure upgrades.
# Pausability: 
Can be paused/unpaused by the owner.

## How It Works
The owner provides arrays of recipients and amounts for bulk transfers, which are processed using the AlphaOmegaCoin contract’s transferFrom function.
The bulk distribution function emits an event for external systems to handle distribution logic.

# Dependencies
OpenZeppelin Contracts: Uses upgradeable versions of BEP-20, Ownable, Pausable, ReentrancyGuard, and UUPS.
DateTime Library: A custom library for handling timestamp-to-date conversions for LTAF/RAMS restrictions.
Setup and Deployment
Install Dependencies:
Install OpenZeppelin contracts: npm install @openzeppelin/contracts-upgradeable
Ensure the DateTime library is included in the project.

# Deploy AlphaOmegaCoin:
Deploy with the initializer to mint 1 trillion tokens to the deployer and set initial LTAF percentage (60%) and levels.

# Deploy BulkOperations:
Pass the AlphaOmegaCoin contract address during initialization.

# Configure:
Set up ownership, LTAF/RAMS inclusions, and blacklists as needed.

Usage
For Users:
Transfer AOC tokens using transfer or transferFrom, respecting LTAF/RAMS limits.
Check balances with balanceOf and allowances with allowance.
# For Admins (Owner):
Blacklist/remove users with blacklistUser/removeFromBlacklist.
Manage LTAF/RAMS with includeInLTAF, excludeFromLTAF, includeInRAMS, excludeFromRAMS.
Update LTAF percentage with updateLtafPercentage.
Perform bulk transfers with bulkTransfer or request distributions with bulkDistribution.
# Security
Upgradeability: Use UUPS to upgrade contracts securely, with the owner controlling upgrades.
Pausability: Pause transfers during emergencies.
ReentrancyGuard: Protects against reentrancy attacks.
Blacklisting: Prevents malicious addresses from participating.
Restricted Transfers: LTAF/RAMS ensure controlled token circulation.
c

# FairSync

A decentralized system for managing and syncing rental agreements on the Stacks blockchain.

## Features
- Create rental agreements between landlords and tenants
- Track rent payments and payment history with confirmation workflow
- Store agreement terms and conditions
- Manage security deposits
- Record property condition reports
- Track payment totals and history for each agreement
- Two-step payment verification process
- Enhanced payment validation and tracking
- Grace period for late payments
- Detailed event logging system

## Contract Functions
- create-agreement: Create a new rental agreement
- pay-rent: Process and record rent payments with validation
- confirm-payment: Landlord confirmation of received payments
- get-payment-history: View payment history for an agreement
- update-agreement: Update agreement terms
- terminate-agreement: End a rental agreement
- get-agreement-details: View agreement information

## Payment Tracking System
The system includes a comprehensive payment tracking feature:
- Validates payment amounts against agreement terms
- Records all payment attempts with timestamps
- Requires landlord confirmation of received payments
- Maintains running totals of confirmed payments
- Stores payment history for each agreement
- Supports different payment types
- Prevents double-confirmation of payments
- Tracks partial payments and remaining balances
- Implements grace period for late payments

## Event System
- Detailed event logging with timestamps
- Payment status tracking
- Agreement lifecycle events
- Late payment notifications

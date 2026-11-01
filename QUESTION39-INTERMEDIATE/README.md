# Commit and Rollback Evaluation

## Overview
A COBOL and DB2-based banking transaction program that ensures data consistency and transaction integrity using COMMIT and ROLLBACK operations.

## Features
- Account validation
- Sender account debit
- Receiver account credit
- Transaction history insertion
- SQL error handling using SQLCA
- Automatic rollback on transaction failure
- Commit after successful operations
- Transaction status reporting

## Technologies
- COBOL
- IBM DB2
- Embedded SQL
- JCL

## Transaction Management
- **COMMIT:** Permanently saves all successful database operations.
- **ROLLBACK:** Cancels uncommitted changes when an operation fails.

## Test Scenarios
- Successful transaction
- Account not found
- Insufficient balance
- Failure during transaction processing
- Commit acknowledgement failure

## Objective
To develop a reliable banking transaction system that prevents partial updates and maintains database consistency through atomic transaction processing.

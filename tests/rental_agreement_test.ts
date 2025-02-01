import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new rental agreement",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const tenant = accounts.get('wallet_1')!;
        const monthlyRent = 1000;
        const securityDeposit = 1000;
        const startDate = 1625097600; // July 1, 2021
        const endDate = 1656633600; // July 1, 2022

        let block = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'create-agreement', [
                types.principal(tenant.address),
                types.uint(monthlyRent),
                types.uint(securityDeposit),
                types.uint(startDate),
                types.uint(endDate)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk();
        assertEquals(block.receipts[0].result, types.ok(types.uint(0)));
    }
});

Clarinet.test({
    name: "Can pay rent and confirm payment",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const tenant = accounts.get('wallet_1')!;
        const monthlyRent = 1000;

        // Create agreement
        let block = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'create-agreement', [
                types.principal(tenant.address),
                types.uint(monthlyRent),
                types.uint(1000),
                types.uint(1625097600),
                types.uint(1656633600)
            ], deployer.address)
        ]);

        // Pay rent
        let paymentBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'pay-rent', [
                types.uint(0),
                types.uint(monthlyRent)
            ], tenant.address)
        ]);

        paymentBlock.receipts[0].result.expectOk();

        // Confirm payment
        let confirmBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'confirm-payment', [
                types.uint(0),
                types.uint(0)
            ], deployer.address)
        ]);

        confirmBlock.receipts[0].result.expectOk();

        // Get agreement details to verify payment recorded
        let detailsBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'get-agreement-details', [
                types.uint(0)
            ], deployer.address)
        ]);

        const agreement = detailsBlock.receipts[0].result.expectOk().expectTuple();
        assertEquals(agreement['total-paid'], types.uint(1000));
    }
});

Clarinet.test({
    name: "Can terminate agreement",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const tenant = accounts.get('wallet_1')!;

        // First create an agreement
        let block = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'create-agreement', [
                types.principal(tenant.address),
                types.uint(1000),
                types.uint(1000),
                types.uint(1625097600),
                types.uint(1656633600)
            ], deployer.address)
        ]);

        // Then terminate it
        let terminateBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'terminate-agreement', [
                types.uint(0)
            ], deployer.address)
        ]);

        terminateBlock.receipts[0].result.expectOk();
    }
});

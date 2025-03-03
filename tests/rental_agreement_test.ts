Clarinet.test({
    name: "Payment validation works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const tenant = accounts.get('wallet_1')!;
        
        // Create agreement
        let block = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'create-agreement', [
                types.principal(tenant.address),
                types.uint(1000),
                types.uint(1000),
                types.uint(1625097600),
                types.uint(1656633600)
            ], deployer.address)
        ]);
        
        // Pay security deposit
        let depositBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'pay-security-deposit', [
                types.uint(0)
            ], tenant.address)
        ]);
        
        // Test valid payment
        let paymentBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'pay-rent', [
                types.uint(0),
                types.uint(1000)
            ], tenant.address)
        ]);
        paymentBlock.receipts[0].result.expectOk();
        
        // Test invalid payment amount
        let invalidBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'pay-rent', [
                types.uint(0),
                types.uint(2000)
            ], tenant.address)
        ]);
        invalidBlock.receipts[0].result.expectErr(types.uint(102));
    }
});

[... previous tests remain unchanged ...]

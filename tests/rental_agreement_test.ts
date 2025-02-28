[... previous test content ...]

Clarinet.test({
    name: "Contract pause functionality works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const tenant = accounts.get('wallet_1')!;

        // Pause contract
        let pauseBlock = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'pause-contract', [], deployer.address)
        ]);
        pauseBlock.receipts[0].result.expectOk();

        // Attempt to create agreement while paused
        let block = chain.mineBlock([
            Tx.contractCall('rental_agreement', 'create-agreement', [
                types.principal(tenant.address),
                types.uint(1000),
                types.uint(1000),
                types.uint(1625097600),
                types.uint(1656633600)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(105)); // ERR-CONTRACT-PAUSED
    }
});

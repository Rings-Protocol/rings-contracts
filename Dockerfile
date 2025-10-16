FROM ghcr.io/foundry-rs/foundry:stable

WORKDIR /app

# Copy the entire project
COPY . .

# Build the project
RUN forge build

# Entry point to run the distribution script
# PRIVATE_KEY is read directly by the script via vm.envUint()
# SONIC_RPC_URL is read via the 'sonic' alias defined in foundry.toml
# Add --broadcast flag to actually execute on-chain, otherwise runs in dry-run mode
ENTRYPOINT ["forge", "script", "script/DistributeYield.s.sol:DistributeYieldScript", "--rpc-url", "sonic"]

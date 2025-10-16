FROM ghcr.io/foundry-rs/foundry:stable

WORKDIR /app

# Copy the entire project
COPY . .

# Build the project
RUN forge build

# Entry point to run the distribution script
# PRIVATE_KEY is read directly by the script via vm.envUint()
# ETH_RPC_URL is read automatically by forge
ENTRYPOINT ["forge", "script", "script/DistributeYield.s.sol:DistributeYieldScript", "--broadcast"]

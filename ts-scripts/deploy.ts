import { HelloWormhole__factory } from "./ethers-contracts"
import {
  loadConfig,
  getWallet,
  storeDeployedAddresses,
  getChain,
  loadDeployedAddresses,
} from "./utils"

export async function deploy() {
  // Load configuration and deployed addresses
  const config = loadConfig();
  const deployed = loadDeployedAddresses();

  // Initialize deployed.helloWormhole if not defined
  if (!deployed.helloWormhole) {
    deployed.helloWormhole = {};
  }

  try {
    // Iterate over each chainId and deploy the contract
    for (const chainId of config.chains.map(c => c.chainId)) {
      const chain = getChain(chainId);
      const signer = getWallet(chainId);

      try {
        const helloWormhole = await new HelloWormhole__factory(signer).deploy(chain.wormholeRelayer);
        await helloWormhole.deployed();

        deployed.helloWormhole[chainId] = helloWormhole.address;

        console.log(
          `HelloWormhole deployed to ${helloWormhole.address} on ${chain.description} (chain ${chainId})`
        );
      } catch (err) {
        console.error(`Failed to deploy HelloWormhole on chain ${chainId}:`, err);
      }
    }

    // Store the deployed addresses
    storeDeployedAddresses(deployed);
  } catch (err) {
    console.error("Deployment failed:", err);
  }
}

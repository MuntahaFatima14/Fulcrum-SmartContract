const hre = require("hardhat");

async function main() {
  const factoryAddress = "0x08669bb2714a578Af29c93C4569Ed25De014456F";
  const Factory = await hre.ethers.getContractAt("CaffeineFactory", factoryAddress);

  console.log("Creating a new tipping jar...");
  
  // This calls the function in your Solidity code: 
  // function createJar(string calldata _iframeLink)
  const tx = await Factory.createJar("https://my-karachi-project-link.com");
  const receipt = await tx.wait();

  // In Ethers v6, we look through the logs for the JarCreated event
  const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'JarCreated');
  
  console.log(`Success! New Jar created at: ${event.args.jarAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 1. Deploy the Logic Contract (The "Master" copy)
  const Logic = await hre.ethers.getContractFactory("CryptoCaffeineBottle");
  const logic = await Logic.deploy();
  await logic.waitForDeployment();
  const logicAddress = await logic.getAddress();
  console.log("Logic Contract (Implementation) deployed to:", logicAddress);

  // 2. Deploy the Factory Contract
  // We pass the Logic address and a Treasury address (using deployer for demo)
  const Factory = await hre.ethers.getContractFactory("CaffeineFactory");
  const factory = await Factory.deploy(logicAddress, deployer.address);
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress();
  console.log("Factory Contract deployed to:", factoryAddress);

  // 3. Optional: Create a "Jar" immediately to test
  console.log("Creating a test jar...");
  const tx = await factory.createJar("https://my-profile-link.com");
  const receipt = await tx.wait();
  
  // Find the address of the new Jar from the event logs
  const event = receipt.logs.find(log => log.fragment && log.fragment.name === 'JarCreated');
  console.log("New Jar (Clone) created at:", event.args.jarAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
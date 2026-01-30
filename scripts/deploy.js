const hre = require("hardhat");

async function main() {
  // 1. Get the Logic Contract
  const Logic = await hre.ethers.getContractFactory("CryptoCaffeineBottle");
  const logic = await Logic.deploy();
  await logic.waitForDeployment();
  const logicAddr = await logic.getAddress();
  console.log(`1. Logic Contract deployed to: ${logicAddr}`);

  // 2. Get the Factory Contract (passing Logic addr and a Treasury addr)
  const [deployer] = await hre.ethers.getSigners();
  const Factory = await hre.ethers.getContractFactory("CaffeineFactory");
  const factory = await Factory.deploy(logicAddr, deployer.address);
  await factory.waitForDeployment();
  const factoryAddr = await factory.getAddress();
  console.log(`2. Factory Contract deployed to: ${factoryAddr}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
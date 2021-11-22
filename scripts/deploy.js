// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  /*    Tier 1  (1Mb group) - 24 pieces from 1.024 ETH (fixed price)
        Tier 2 (512Kb group) - 24 p.  0.512 (f.p.)
        Tier 3 (256Kb group) - 512 p.  0.256 (f.p.)
        Tier 4 (128Kb group) - 1024 p. 0.128 (f.p.)
        Tier 5 (48Kb group) - 2048 p. 0.048 (f.p.)
        Tier 6 (16Kb group) - 4096 p. 0.016 (f.p.)*/

  // We get the contract to deploy
  const Tiers = await hre.ethers.getContractFactory("Tiers");
  //verify address https://alienpunkstest.herokuapp.com/api/nft/
  const tiers = await Tiers.deploy("Tiers","Tiers","https://metadataurl/");
  
  let cost1 = web3.utils.toWei('1.024', 'ether');
  let cost2 = web3.utils.toWei('0.512', 'ether')
  let cost3 = web3.utils.toWei('0.256', 'ether')
  let cost4 = web3.utils.toWei('0.128', 'ether')
  let cost5 = web3.utils.toWei('0.048', 'ether')
  let cost6 = web3.utils.toWei('0.016', 'ether')

  await tiers.setTier(1,'Tier 1',cost1,24);
  await tiers.setTier(2,'Tier 2',cost2,24);
  await tiers.setTier(3,'Tier 3',cost3,512);
  await tiers.setTier(4,'Tier 4',cost4,1024);
  await tiers.setTier(5,'Tier 5',cost5,2048);
  await tiers.setTier(6,'Tier 6',cost6,4096);

  await tiers.deployed();

  console.log("const tiersAdddress=\""+tiers.address+"\";");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

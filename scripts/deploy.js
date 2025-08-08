const { deploy } = require('@openzeppelin/hardhat-upgrades/dist/utils');
const {ethers, upgrades} = require('hardhat');

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Bala Brucks Deploying the Contract with", deployer.address);

    //Deploy AOC token
    const AlphaOmegaCoin = await ethers.getContractFactory("AlphaOmegaCoin");
    const AlphaOmegaCoin_ = await upgrades.deployProxy(AlphaOmegaCoin,[],{
        initializer: "initialize",
        kind: "uups"
    });
    const AOCTokenAddress = await AlphaOmegaCoin_.getAddress();

    console.log("Aoc Token Deployed to ", AOCTokenAddress);

    // const AOCTokenAddrss = "0x1E803f70e0132b2A3dAC52466b14b245A08bF3d4";

    // const BulkOperations = await ethers.getContractFactory("BulkOperations");
    // const bulkOperations = await upgrades.deployProxy(BulkOperations,[AOCTokenAddress],{
    //     initializer: "initialize",
    //     kind: "uups"
    // });
    // const bulkOperationsAddress = await bulkOperations.getAddress();
    // console.log("BulkOperations Deployed to", bulkOperationsAddress);

    // //Deploy RestrictionManager
    // const Restriction = await ethers.getContractFactory("RestrictionManager");
    // const restriction = await upgrades.deployProxy(Restriction,[AOCTokenAddress],{
    //   initializer: "initialize",
    //   kind: "uups"
    // });
    // const restrictionAddress = await restriction.getAddress();
    // console.log("RestrictionManager Deployed to", restrictionAddress);
    
    

//     const proxyAddress = "0xAe112dE9f6b2DA7e59AFb9B103edd1505c3bd9a7";
//     console.log(`upgrading AOCBEP20 contract at ${proxyAddress}`);

//   const AOC_BEP2 = await ethers.getContractFactory("AOC_BEP2");

//   const upgradedAddress = await upgrades.upgradeProxy(
//     proxyAddress,
//     AOC_BEP2
//   );
//   console.log(`AOC_BEP2 Successfully upgraded at ${upgradedAddress}`);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
})
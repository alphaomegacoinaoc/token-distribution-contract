const {ethers, upgrades} = require('hardhat');
require('@openzeppelin/hardhat-upgrades');

async function main() {

    const [deployer] = await ethers.getSigners();
    console.log('Deploying the contracts with the account:', deployer.address); 

    // deploy the TERC20 contract using constructor
    // const TERC20 = await ethers.getContractFactory('TERC20');
    // const terc20 = await TERC20.deploy('Tether', 'USDT', 18, '1000000000000000000000000000');
    // console.log('TERC20 deployed to:', await terc20.getAddress());

    // const AocBulkTransfer = await ethers.getContractFactory('AOCBulkTransfer');
    // const aocBulkTransfer = await upgrades.deployProxy(AocBulkTransfer, [await terc20.getAddress()],
    //     {initializer: 'initialize', kind: 'uups'});
    // console.log('AocBulkTransfer deployed to:', await aocBulkTransfer.getAddress());

    // upgrade the AocBulkTransfer contract
    const AocBulkTransfer = await ethers.getContractFactory('AOCBulkTransfer');
    const aocBulkTransfer = await upgrades.upgradeProxy('0xEd39908305c4FD17AB41872C0Da1273b7D663a34', AocBulkTransfer);
    console.log('AocBulkTransfer upgraded to:', await aocBulkTransfer.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("AOC Token Distribution", function () {
    let aocTransfer, testerERC20, accounts;

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        let AOCTransfer = await ethers.getContractFactory("AOCBulkTransfer");
        let TesterERC20 = await ethers.getContractFactory("TERC20");
        accounts = await ethers.getSigners();

        testerERC20 = await TesterERC20.deploy("TestERC20", "TERC", 18, ethers.parseEther("1000000"));

        aocTransfer = await upgrades.deployProxy(AOCTransfer, [await testerERC20.getAddress()], 
        { 
            initializer: 'initialize',
            kind: 'uups' 
        });

        await aocTransfer.setToken(await testerERC20.getAddress());
    });

    describe("Deployment", function () {
        it("id deployer the owner", async function () {
            expect(await aocTransfer.owner()).to.equal(accounts[0].address);
        });
        it("should transfer 100 tokens to each of 9 accounts", async function () {
            let accounts = await ethers.getSigners();
            let recipients = [];
            let amounts = [];
            for (let i = 1; i < 10; i++) {
                recipients.push(await accounts[i].getAddress());
                amounts.push(ethers.parseEther("100"));
            }
            testerERC20.transfer(await aocTransfer.getAddress(), ethers.parseEther("1000"));
            await aocTransfer.bulkTransfer(recipients, amounts);
            for (let i = 1; i < 10; i++) {
                expect(await testerERC20.balanceOf(accounts[i].address)).to.equal(ethers.parseEther("100"));
            }
        });
        it("Check for the event in bulk transfer", async function () {
            let accounts = await ethers.getSigners();
            let recipients = [];
            let amounts = [];
            for (let i = 1; i < 10; i++) {
                recipients.push(await accounts[i].getAddress());
                amounts.push(ethers.parseEther("100"));
            }
            testerERC20.transfer(await aocTransfer.getAddress(), ethers.parseEther("1000"));
            let tx = await aocTransfer.bulkTransfer(recipients, amounts);
            await expect(tx).to.emit(aocTransfer, 'BulkTransferred').withArgs(recipients, amounts);
        });
    });
});

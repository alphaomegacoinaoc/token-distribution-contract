const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("AlphaOmegaCoin", function () {
  let AOC, aoc, owner, addr1, addr2;
  const TOTAL_SUPPLY = ethers.utils.parseEther("1000000000000");
  const LTAF_PERCENTAGE = 60;
  const ZERO_ADDRESS = ethers.constants.AddressZero;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    AOC = await ethers.getContractFactory("AlphaOmegaCoin");
    aoc = await upgrades.deployProxy(AOC, [], { initializer: "initialize" });
    await aoc.deployed();
  });

  describe("Initialization", function () {
    it("should initialize with correct parameters", async function () {
      expect(await aoc.name()).to.equal("Alpha Omega Coin");
      expect(await aoc.symbol()).to.equal("AOC");
      expect(await aoc.decimals()).to.equal(18);
      expect(await aoc.totalSupply()).to.equal(TOTAL_SUPPLY);
      expect(await aoc.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY);
      expect(await aoc.ltafPercentage()).to.equal(LTAF_PERCENTAGE);
    });

    it("should set owner correctly", async function () {
      expect(await aoc.owner()).to.equal(owner.address);
    });

    it("should initialize levels correctly", async function () {
      const level1 = await aoc.levels(1);
      expect(level1.start).to.equal(1640995200);
      expect(level1.end).to.equal(1704153599);
      expect(level1.percentage).to.equal(20);
    });
  });

  describe("Transfers", function () {
    it("should transfer tokens successfully", async function () {
      const amount = ethers.utils.parseEther("1000");
      await aoc.transfer(addr1.address, amount);
      expect(await aoc.balanceOf(addr1.address)).to.equal(amount);
      expect(await aoc.balanceOf(owner.address)).to.equal(TOTAL_SUPPLY.sub(amount));
    });

    it("should fail transfer if sender is blacklisted", async function () {
      await aoc.blacklistUser(addr1.address);
      await expect(aoc.connect(addr1).transfer(addr2.address, 100)).to.be.revertedWith("AOC: Blacklisted");
    });

    it("should fail transfer to zero address", async function () {
      await expect(aoc.transfer(ZERO_ADDRESS, 100)).to.be.revertedWith("AOC: Zero recipient");
    });

    it("should fail transfer if insufficient balance", async function () {
      await expect(aoc.connect(addr1).transfer(addr2.address, 100)).to.be.revertedWith("AOC: Low balance");
    });
  });

  describe("LTAF and RAMS Restrictions", function () {
    it("should restrict LTAF user transfers", async function () {
      await aoc.includeInLTAF(addr1.address);
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      const amount = ethers.utils.parseEther("601"); // Exceeds 60% of 1000
      await expect(aoc.connect(addr1).transfer(addr2.address, amount)).to.be.revertedWith("AOC: Exceeds LTAF");
    });

    it("should allow RAMS user transfer within level limits", async function () {
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      const amount = ethers.utils.parseEther("200"); // Within 20% for level 1
      await aoc.connect(addr1).transfer(addr2.address, amount);
      expect(await aoc.balanceOf(addr2.address)).to.equal(amount);
    });

    it("should fail RAMS user transfer exceeding level limits", async function () {
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      const amount = ethers.utils.parseEther("201"); // Exceeds 20% for level 1
      await expect(aoc.connect(addr1).transfer(addr2.address, amount)).to.be.revertedWith("AOC: Exceeds level");
    });
  });

  describe("Blacklist", function () {
    it("should blacklist and unblacklist user", async function () {
      await aoc.blacklistUser(addr1.address);
      expect(await aoc.blacklisted(addr1.address)).to.be.true;
      await aoc.removeFromBlacklist(addr1.address);
      expect(await aoc.blacklisted(addr1.address)).to.be.false;
    });

    it("should fail to blacklist already blacklisted user", async function () {
      await aoc.blacklistUser(addr1.address);
      await expect(aoc.blacklistUser(addr1.address)).to.be.revertedWith("AOC: Already blacklisted");
    });

    it("should fail to unblacklist non-blacklisted user", async function () {
      await expect(aoc.removeFromBlacklist(addr1.address)).to.be.revertedWith("AOC: ! blacklisted");
    });
  });

  describe("LTAF and RAMS Inclusion/Exclusion", function () {
    it("should include and exclude from LTAF", async function () {
      await aoc.includeInLTAF(addr1.address);
      expect(await aoc.includedInLTAF(addr1.address)).to.be.true;
      await aoc.excludedFromLTAF(addr1.address);
      expect(await aoc.includedInLTAF(addr1.address)).to.be.false;
    });

    it("should include and exclude from RAMS", async function () {
      await aoc.excludeFromRAMS(addr1.address);
      expect(await aoc.excludedFromRAMS(addr1.address)).to.be.true;
      await aoc.includeInRAMS(addr1.address);
      expect(await aoc.excludedFromRAMS(addr1.address)).to.be.false;
    });

    it("should fail to include already included LTAF user", async function () {
      await aoc.includeInLTAF(addr1.address);
      await expect(aoc.includeInLTAF(addr1.address)).to.be.revertedWith("AOC: Already included");
    });
  });

  describe("Pausable", function () {
    it("should pause and unpause contract", async function () {
      await aoc.pause();
      await expect(aoc.transfer(addr1.address, 100)).to.be.revertedWith("Pausable: paused");
      await aoc.unpause();
      await aoc.transfer(addr1.address, 100);
      expect(await aoc.balanceOf(addr1.address)).to.equal(100);
    });

    it("should fail to pause if not owner", async function () {
      await expect(aoc.connect(addr1).pause()).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Upgrades", function () {
    it("should allow owner to upgrade contract", async function () {
      const AOCV2 = await ethers.getContractFactory("AlphaOmegaCoin");
      await upgrades.upgradeProxy(aoc.address, AOCV2);
      expect(await aoc.name()).to.equal("Alpha Omega Coin");
    });

    it("should fail to upgrade if not owner", async function () {
      const AOCV2 = await ethers.getContractFactory("AlphaOmegaCoin");
      await expect(upgrades.upgradeProxy(aoc.address, AOCV2, { from: addr1.address })).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Allowance and TransferFrom", function () {
    it("should approve and transferFrom successfully", async function () {
      const amount = ethers.utils.parseEther("1000");
      await aoc.transfer(addr1.address, amount);
      await aoc.connect(addr1).approve(addr2.address, amount);
      expect(await aoc.allowance(addr1.address, addr2.address)).to.equal(amount);
      await aoc.connect(addr2).transferFrom(addr1.address, addr2.address, amount);
      expect(await aoc.balanceOf(addr2.address)).to.equal(amount);
      expect(await aoc.balanceOf(addr1.address)).to.equal(0);
    });

    it("should fail transferFrom if allowance is insufficient", async function () {
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      await aoc.connect(addr1).approve(addr2.address, ethers.utils.parseEther("500"));
      await expect(aoc.connect(addr2).transferFrom(addr1.address, addr2.address, ethers.utils.parseEther("600"))).to.be.revertedWith("AOC: Exceeds allowance");
    });
  });

  describe("LtafPercentage Update", function () {
    it("should update ltafPercentage successfully", async function () {
      await aoc.updateLtafPercentage(70);
      expect(await aoc.ltafPercentage()).to.equal(70);
    });

    it("should fail to update ltafPercentage if not owner", async function () {
      await expect(aoc.connect(addr1).updateLtafPercentage(70)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail to update ltafPercentage to zero", async function () {
      await expect(aoc.updateLtafPercentage(0)).to.be.revertedWith("AOC: Invalid percentage");
    });
  });

  describe("Timestamp-Based Restrictions", function () {
    it("should restrict transfers for new LTAF users in same month", async function () {
      await aoc.includeInLTAF(addr1.address);
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      await expect(aoc.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("100"))).to.be.revertedWith("AOC: New LTAF wait");
    });

    it("should restrict transfers for ex-LTAF users in same month", async function () {
      await aoc.includeInLTAF(addr1.address);
      await aoc.excludedFromLTAF(addr1.address);
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      await expect(aoc.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("100"))).to.be.revertedWith("AOC: Ex-LTAF wait");
    });

    it("should allow LTAF transfer after month change", async function () {
      await aoc.includeInLTAF(addr1.address);
      await aoc.transfer(addr1.address, ethers.utils.parseEther("1000"));
      await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // 30 days
      await ethers.provider.send("evm_mine");
      const amount = ethers.utils.parseEther("600"); // Within 60% of 1000
      await aoc.connect(addr1).transfer(addr2.address, amount);
      expect(await aoc.balanceOf(addr2.address)).to.equal(amount);
    });
  });
});
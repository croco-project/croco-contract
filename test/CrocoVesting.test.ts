import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { ether, hours, months } from "../utils/utils";
import { expect } from "chai";

describe("CrocoVesting", function () {

    async function deploy() {
        const [owner, acc1, acc2, acc3, ...accs] = await ethers.getSigners();
        const CONTRACT1 = await ethers.getContractFactory("CrocoToken");
        const crocoToken = await CONTRACT1.deploy("Croco", "CRCO");
        await crocoToken.connect(owner).mint(acc1.address, ether(10000000));
        await crocoToken.connect(owner).setReferralPool(acc1.address);
        await crocoToken.connect(owner).toggleReferralActive();

        const CONTRACT2 = await ethers.getContractFactory("CrocoToken");
        const mockToken = await CONTRACT2.deploy("MOCK", "MOCK");

        const CONTRACT3 = await ethers.getContractFactory("CrocoVesting");
        const crocoVesting = await CONTRACT3.deploy(crocoToken.address, mockToken.address);
        return {crocoToken, mockToken, crocoVesting, owner, acc1, acc2, acc3, accs};
    }

    async function withTimeSet() {
        const {crocoToken, mockToken, crocoVesting, owner, acc1, acc2, acc3, accs} = await loadFixture(deploy);
        const preSeedStart = await time.latest() + hours(1);
        const privateStart = await time.latest() + hours(2);
        const publicStart = await time.latest() + hours(3);
        await crocoVesting.setStartTime(preSeedStart, privateStart, publicStart);
        const unlockTime = await time.latest() + hours(10);
        await crocoVesting.setUnlockTime(unlockTime, unlockTime, unlockTime, unlockTime, unlockTime);
        return {crocoToken, mockToken, crocoVesting, owner, acc1, acc2, acc3, accs};
    }

    async function withTimeSetAndOpen() {
        const {crocoToken, mockToken, crocoVesting, owner, acc1, acc2, acc3, accs} = await loadFixture(withTimeSet);
        await crocoVesting.connect(owner).toggleStarted();
        await crocoToken.connect(owner).mint(crocoVesting.address, ether(1000000));
        return {crocoToken, mockToken, crocoVesting, owner, acc1, acc2, acc3, accs};
    }


    describe("General Tests", function () {
        it("Should display correct stages", async function () {
            const {crocoVesting, owner} = await loadFixture(deploy);
            let stage = await crocoVesting.stage();
            expect(stage).to.equal(3);
            await crocoVesting.connect(owner).toggleStarted();
            stage = await crocoVesting.stage();
            expect(stage).to.equal(3);
            const preSeedStart = await time.latest() + hours(1);
            const privateStart = await time.latest() + hours(2);
            const publicStart = await time.latest() + hours(3);
            await crocoVesting.setStartTime(preSeedStart, privateStart, publicStart);
            await time.increase(hours(1));
            stage = await crocoVesting.stage();
            expect(stage).to.equal(0);
            await time.increase(hours(1));
            stage = await crocoVesting.stage();
            expect(stage).to.equal(1);
            await time.increase(hours(1));
            stage = await crocoVesting.stage();
            expect(stage).to.equal(2);
        });

        it("Should display correct price", async function () {
            const {crocoVesting, owner} = await loadFixture(withTimeSet);
            let stage = await crocoVesting.stage();
            expect(stage).to.equal(3);
            let currentRoundPrice = await crocoVesting.currentRoundPrice();
            expect(currentRoundPrice).to.equal(0);
            let currentPrice = await crocoVesting.getCurrentPrice(ether(100));
            expect(currentPrice).to.equal(0);
            await crocoVesting.connect(owner).toggleStarted();
            await time.increase(hours(1));
            currentRoundPrice = await crocoVesting.currentRoundPrice();
            expect(currentRoundPrice).to.equal(ether(0.007));
            currentPrice = await crocoVesting.getCurrentPrice(ether(100));
            expect(currentPrice).to.equal(ether(0.7));
            await time.increase(hours(1));
            currentRoundPrice = await crocoVesting.currentRoundPrice();
            expect(currentRoundPrice).to.equal(ether(0.015));
            currentPrice = await crocoVesting.getCurrentPrice(ether(100));
            expect(currentPrice).to.equal(ether(1.5));
            await time.increase(hours(1));
            currentRoundPrice = await crocoVesting.currentRoundPrice();
            expect(currentRoundPrice).to.equal(ether(0.018));
            currentPrice = await crocoVesting.getCurrentPrice(ether(100));
            expect(currentPrice).to.equal(ether(1.8));
        });

        it("Should be able to buy in preseed", async function () {
            const {crocoToken, mockToken, crocoVesting, owner, acc2} = await loadFixture(withTimeSetAndOpen);
            await mockToken.connect(owner).mint(acc2.address, ether(1000));
            await time.increase(hours(1));
            await mockToken.connect(acc2).approve(crocoVesting.address, ether(1000));
            await crocoVesting.connect(acc2).buyToken(ether(100), ethers.constants.AddressZero);
            const data = await crocoVesting.preSeedRound(acc2.address);
            expect(data.total).to.equal(ether(100));
            expect(data.remainder).to.equal(ether(100));
            await time.increase(months(5));
            const unlockedPreseedData = await crocoVesting.getPreSeedAvailable(acc2.address);
            const claim1Amount = ether(100).mul(5).div(12);
            expect(unlockedPreseedData).to.equal(claim1Amount);
            await crocoVesting.connect(acc2).claimPreSeed();
            expect(await crocoToken.balanceOf(acc2.address)).to.equal(claim1Amount);
            await time.increase(months(5));
            const unlockedPreseedData2 = await crocoVesting.getPreSeedAvailable(acc2.address);
            expect(unlockedPreseedData2).to.approximately(claim1Amount, 1);
        });
    });
});
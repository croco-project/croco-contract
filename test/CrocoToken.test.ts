import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { ether } from "../utils/utils";

describe("CrocoToken", function () {
    async function deploy() {
        const [owner, acc1, acc2, acc3, ...accs] = await ethers.getSigners();
        const CONTRACT = await ethers.getContractFactory("CrocoToken");
        const contract = await CONTRACT.deploy("Croco", "CRCO");
        return {contract, owner, acc1, acc2, acc3, accs};
    }

    async function referralAcc1() {
        const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(deploy);
        await contract.connect(owner).mint(acc1.address, ether(100000));
        await contract.connect(owner).setReferralPool(acc1.address);
        await contract.connect(owner).toggleReferralActive();
        return {contract, owner, acc1, acc2, acc3, accs};
    }

    describe("General Tests", function () {
        it("Should mint", async function () {
            const {contract, owner, acc1} = await loadFixture(deploy);
            await contract.connect(owner).mint(acc1.address, ether(1));
            expect(await contract.balanceOf(acc1.address)).to.equal(ether((1)));
        });

        it("Should set referral pool", async function () {
            const {contract, owner, acc1} = await loadFixture(deploy);
            expect(await contract.REFERRAL_POOL()).to.equal(ethers.constants.AddressZero);
            await contract.connect(owner).setReferralPool(acc1.address);
            expect(await contract.REFERRAL_POOL()).to.equal(acc1.address);
        });

        it("Should toggle referralActive", async function () {
            const {contract, owner, acc1} = await loadFixture(deploy);
            expect(await contract.referralActive()).to.equal(false);
            await contract.connect(owner).toggleReferralActive();
            expect(await contract.referralActive()).to.equal(true);
        });

        it("Should change referral permils", async function () {
            const {contract, owner, acc1} = await loadFixture(deploy);
            expect(await contract.referralPermils(0)).to.equal(800);
            expect(await contract.referralPermils(1)).to.equal(400);
            await contract.connect(owner).setReferralPermils([600, 10, 10]);
            expect(await contract.referralPermils(0)).to.equal(600);
            expect(await contract.referralPermils(1)).to.equal(10);
        });

        it("Should be able to refer user", async function () {
            const {contract, owner, acc1, acc2, acc3} = await loadFixture(referralAcc1);
            await contract.connect(owner).addOperator(acc2.address);
            await contract.connect(acc2).addOrGetReferrer(acc3.address, acc2.address);
            expect(await contract.getReferredNumber(acc3.address)).to.equal(1);
            expect(await contract.getReferrer(acc2.address)).to.equal(acc3.address);
        });

        it("Should not be able to refer self", async function () {
            const {contract, owner, acc1, acc2, acc3} = await loadFixture(referralAcc1);
            await contract.connect(owner).addOperator(acc2.address);
            await expect(contract.connect(acc2).addOrGetReferrer(acc2.address, acc2.address)).to.be.revertedWith("Can not add self as referrer");
        });

        it("Should not be able to refer each other", async function () {
            const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(referralAcc1);
            await contract.connect(owner).addOperator(acc2.address);
            await contract.connect(acc2).addOrGetReferrer(acc2.address, acc3.address);
            await expect(contract.connect(acc2).addOrGetReferrer(acc3.address, acc2.address)).to.be.revertedWith("Referred can not refer its referrer");
            expect(await contract.connect(owner).callStatic.addOrGetReferrer(owner.address, acc3.address)).to.equal(acc2.address);
        });

        it("Should return correct numbers", async function () {
            const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(referralAcc1);
            await contract.connect(owner).addOrGetReferrer(owner.address, acc1.address);
            await contract.connect(owner).addOrGetReferrer(acc1.address, acc2.address);
            await contract.connect(owner).addOrGetReferrer(acc1.address, accs[3].address);
            await contract.connect(owner).addOrGetReferrer(acc2.address, acc3.address);
            await contract.connect(owner).addOrGetReferrer(acc3.address, accs[3].address); // does not add, therefore 0

            expect(await contract.getReferredNumber(owner.address)).to.equal(4);
            expect(await contract.getReferredNumber(acc1.address)).to.equal(3);
            expect(await contract.getReferredNumber(acc2.address)).to.equal(1);
            expect(await contract.getReferredNumber(acc3.address)).to.equal(0);
        });

        it("Should return correct bonuses", async function () {
            const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(referralAcc1);
            await contract.connect(owner).addOrGetReferrer(owner.address, acc1.address);
            await contract.connect(owner).addOrGetReferrer(acc1.address, acc2.address);
            await contract.connect(owner).addOrGetReferrer(acc2.address, acc3.address);
            await contract.connect(owner).addOrGetReferrer(acc3.address, accs[3].address);

            const bonuses = await contract.getReferralAmount(acc3.address, ether(100));
            expect(bonuses[0].to).to.equal(acc2.address);
            expect(bonuses[0].bonus).to.equal(ether(8));
            expect(bonuses[1].to).to.equal(acc1.address);
            expect(bonuses[1].bonus).to.equal(ether(4));
            expect(bonuses[2].to).to.equal(owner.address);
            expect(bonuses[2].bonus).to.equal(ether(2));

        });

        //
        // it("Should transfer referral tokens", async function () {
        //     const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(referralAcc1);
        //     await contract.connect(owner).mint(acc2.address, ether(1000));
        //     await contract.connect(acc2).approve(acc2.address, ether(1000));
        //     await contract.connect(acc2).transferReferral(acc2.address, owner.address, ether(100), acc3.address);
        //     expect(await contract.balanceOf(acc3.address)).to.equal(ether(5));
        //     expect(await contract.getReferrer(owner.address)).to.equal(acc3.address);
        //     expect(await contract.getReferredNumber(acc3.address)).to.equal(1);
        // });
        //
        // it("Should return all referrals", async function () {
        //     const {contract, owner, acc1, acc2, acc3, accs} = await loadFixture(referralAcc1);
        //     await contract.connect(owner).mint(acc2.address, ether(1000));
        //     await contract.connect(acc2).approve(acc2.address, ether(1000));
        //     await contract.connect(acc2).transferReferral(acc2.address, accs[0].address, ether(100), acc3.address);
        //     await contract.connect(acc2).transferReferral(acc2.address, accs[1].address, ether(100), acc3.address);
        //     await contract.connect(acc2).transferReferral(acc2.address, accs[2].address, ether(100), acc3.address);
        //     const referrals = await contract.getAllReferrals(acc3.address);
        //     expect(referrals[0]).to.equal(accs[0].address);
        //     expect(referrals[1]).to.equal(accs[1].address);
        //     expect(referrals[2]).to.equal(accs[2].address);
        // });


    });
});

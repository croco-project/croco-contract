import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";


describe("CrocoToken", function () {
    async function deploy() {
        const [owner, acc1, acc2, ...accs] = await ethers.getSigners();
        const MoniNFT = await ethers.getContractFactory("CrocoToken");
        const contract = await MoniNFT.deploy("Croco", "CRCO");
        return {contract, owner, acc1, acc2, accs};
    }

    describe("Contract tests", function () {
        it("Should revert if sale is not open", async function () {
            const {contract, owner} = await loadFixture(deploy);

        });
    });
});

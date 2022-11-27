import { ethers, run } from "hardhat";
import { ether, hours } from "../../utils/utils";

async function main() {

    const addr1 = "0xDe410470CDAc803D87cddB5B9C05b1b48f1D00D6";
    const addr2 = "0x5281E7E5B7459CfaA78Af68DAaC8A6Bcfc5bE4C2";

    const [owner, acc1] = await ethers.getSigners();

    const args1 = ["Croco", "CRCO"];

    const CONTRACT1 = await ethers.getContractFactory("CrocoToken");
    const crocoToken = await CONTRACT1.deploy(args1[0], args1[1]);
    await crocoToken.mint(acc1.address, ether(10000000));
    await crocoToken.setReferralPool(acc1.address);
    await crocoToken.toggleReferralActive();
    await crocoToken.mint(addr1, ether(100000));
    await crocoToken.mint(addr2, ether(100000));

    try {
        console.log(`crocoToken deployed to ${crocoToken.address}`);
        await run("verify:verify", {
            address: crocoToken.address,
            constructorArguments: args1,
        });
    } catch (e) {
        console.log(e);
    }

    const args2 = ["MOCK", "MOCK"];
    const CONTRACT2 = await ethers.getContractFactory("CrocoToken");
    const mockToken = await CONTRACT2.deploy(args2[0], args2[1]);
    await mockToken.mint(addr1, ether(100000));
    await mockToken.mint(addr2, ether(100000));
    try {
        console.log(`mockToken deployed to ${mockToken.address}`);
        await run("verify:verify", {
            address: mockToken.address,
            constructorArguments: args2,
        });
    } catch (e) {
        console.log(e);
    }


    const crocoTokenAddress = crocoToken.address;
    const mockTokenAddress = mockToken.address;

    const CONTRACT3 = await ethers.getContractFactory("CrocoVesting");
    const crocoVesting = await CONTRACT3.deploy(crocoTokenAddress, mockTokenAddress);
    await crocoVesting.connect(owner).toggleStarted();
    const time = Math.round(new Date().getTime() / 1000);
    const preSeedStart = time + hours(1);
    const privateStart = time + hours(2);
    const publicStart = time + hours(3);
    await crocoVesting.connect(owner).setStartTime(preSeedStart, privateStart, publicStart);
    const unlockTime = time + hours(10);
    await crocoVesting.connect(owner).setUnlockTime(unlockTime, unlockTime, unlockTime, unlockTime, unlockTime);
    await crocoToken.connect(owner).mint(crocoVesting.address, ether(100000));
    await crocoToken.connect(acc1).approve(crocoVesting.address, ether(100000));
    await crocoToken.addOperator(crocoVesting.address);

    try {
        console.log(`crocoVesting deployed to ${crocoVesting.address}`);
        await run("verify:verify", {
            address: crocoVesting.address,
            constructorArguments: [crocoTokenAddress, mockTokenAddress],
        });
    } catch (e) {
        console.log(e);
    }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

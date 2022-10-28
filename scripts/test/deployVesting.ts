import { ethers, run } from "hardhat";
import { ether, hours } from "../../utils/utils";

async function main() {

    const [owner, acc1] = await ethers.getSigners();


    const crocoTokenAddress = "0x19665B5F83fcC8fA404270E342fC207fAAc1191B";
    const mockTokenAddress = "0xADefDB868Df1D99e44A22C95CCc1745e936C4318";

    const CONTRACT1 = await ethers.getContractFactory("CrocoToken");
    const crocoToken = CONTRACT1.attach(crocoTokenAddress);


    const CONTRACT3 = await ethers.getContractFactory("CrocoVesting");
    const crocoVesting = await CONTRACT3.deploy(crocoTokenAddress, mockTokenAddress);
    console.log("Deployed to", crocoVesting.address);
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

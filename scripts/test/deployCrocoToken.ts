import { ethers, run } from "hardhat";
import { ether } from "../../utils/utils";

async function main() {

    const [owner, acc1] = await ethers.getSigners();

    const args1 = ["Croco", "CRCO"];


    const CONTRACT1 = await ethers.getContractFactory("CrocoToken");
    const crocoToken = await CONTRACT1.deploy(args1[0], args1[1]);
    await crocoToken.mint(acc1.address, ether(10000000));
    await crocoToken.setReferralPool(acc1.address);
    await crocoToken.toggleReferralActive();
    await crocoToken.mint("0xDe410470CDAc803D87cddB5B9C05b1b48f1D00D6", ether(100000));
    await crocoToken.mint("0x5281E7E5B7459CfaA78Af68DAaC8A6Bcfc5bE4C2", ether(100000));

    try {
        console.log(`crocoToken deployed to ${crocoToken.address}`);
        await run("verify:verify", {
            address: crocoToken.address,
            constructorArguments: args1,
        });
    } catch (e) {
        console.log(e);
    }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

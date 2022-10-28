import { ethers, run } from "hardhat";
import { ether, hours } from "../../utils/utils";

async function main() {
    const args2 = ["MOCK", "MOCK"];
    const CONTRACT2 = await ethers.getContractFactory("CrocoToken");
    const mockToken = await CONTRACT2.deploy(args2[0], args2[1]);
    await mockToken.mint("0xDe410470CDAc803D87cddB5B9C05b1b48f1D00D6", ether(100000));
    await mockToken.mint("0x5281E7E5B7459CfaA78Af68DAaC8A6Bcfc5bE4C2", ether(100000));
    try {
        console.log(`mockToken deployed to ${mockToken.address}`);
        await run("verify:verify", {
            address: mockToken.address,
            constructorArguments: args2,
        });
    } catch (e) {
        console.log(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

import { ethers, run } from "hardhat";

async function main() {

    const crocoToken = "0xD0537Bc7e07338174B85e81e61Aa9126d96De502";
    const usdt = "0xC4752085B6146901DF98fB71aD31B0F00aa128c8";

    const ContractFactory = await ethers.getContractFactory("CrocoVesting");
    const contract = await ContractFactory.deploy(crocoToken, usdt);
    await contract.deployed();
    await contract.deployTransaction.wait(5);
    console.log(`Contract deployed to ${contract.address}`);
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: [
            crocoToken,
            usdt
        ],
    });
    console.log("VERIFICATION COMPLETE");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

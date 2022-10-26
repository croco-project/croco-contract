import { ethers, run } from "hardhat";

async function main() {

    const name = "Croco";
    const symbol = "CRCO";

    const ContractFactory = await ethers.getContractFactory("CrocoToken");
    const contract = await ContractFactory.deploy(name, symbol);
    await contract.deployed();
    await contract.deployTransaction.wait(5);
    console.log(`Contract deployed to ${contract.address}`);
    await run("verify:verify", {
        address: contract.address,
        constructorArguments: [
            name,
            symbol
        ],
    });
    console.log("VERIFICATION COMPLETE");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

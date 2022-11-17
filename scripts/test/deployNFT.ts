import { ethers, run } from "hardhat";

async function main() {

    const [owner, acc1] = await ethers.getSigners();


    const crocoTokenAddress = "0x19665B5F83fcC8fA404270E342fC207fAAc1191B";
    const name = "CrocoNft";
    const symbol = "CRNFT";

    const CONTRACT1 = await ethers.getContractFactory("CrocoNFT");
    const CrocoNFT = await CONTRACT1.deploy(name, symbol, crocoTokenAddress);
    await CrocoNFT.setSaleOpen();


    try {
        console.log(`crocoVesting deployed to ${CrocoNFT.address}`);
        await run("verify:verify", {
            address: CrocoNFT.address,
            constructorArguments: [ name, symbol, crocoTokenAddress],
        });
    } catch (e) {
        console.log(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

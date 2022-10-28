import { ethers } from "hardhat";

export const ether = (amount: number) => ethers.utils.parseEther(amount.toString());

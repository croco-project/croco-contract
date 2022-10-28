import { ethers } from "hardhat";

export const ether = (amount: number) => ethers.utils.parseEther(amount.toString());

export const minutes = (n: number) => n * 60;
export const hours = (n: number) => n * minutes(60);
export const days = (n: number) => n * hours(24);
export const months = (n: number) => n * days(30);

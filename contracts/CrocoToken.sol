// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// TODO: Uncomment this line to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CrocoToken is IERC20, ERC20, Ownable {

    mapping(address => address) referrals; // referred -> referrer
    mapping(address => mapping(address => uint256)) referralsIds; // referrer -> referred -> id
    mapping(address => uint256) totalReferred; // referrer -> total referred

    uint256[] referralPermils = [500, 300, 100, 100, 100, 100, 50, 50, 50, 50];

    address public REFERRAL_POOL;
    bool public referralActive;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20 (name, symbol) {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function setReferralPermils(uint256[] calldata permils) public onlyOwner {
        referralPermils = permils;
    }

    function transferReferral(address from, address to, uint256 amount, address referrer) public returns (bool) {
        if (referralActive) {
            if (referrer != address(0)) {
                addReferral(referrer, to);
            }
            _bonus = getReferralAmount(to, referrer);
            if (_bonus > 0) {
                transferFrom(REFERRAL_POOL, _referrer, _bonus);
            }
        }
        return transferFrom(from, to, amount);
    }

    function getReferralAmount(address to, uint256 amount) returns (uint256) {
        uint256 _bonus = 0;
        address _referrer = getReferrer(to);
        if (_referrer != address(0)) {
            uint256 _id = getReferredId(_referrer, to);
            if (_id > 0) {
                _bonusTemp = amount * _referralPermils[_id] / 100000;
                if (balanceOf(REFERRAL_POOL) > _bonus) {
                    _bonus = _bonusTemp;
                }
            }
        }
        return _bonus;
    }

    function addReferral(address referrer, address referred) private {
        uint256 num = totalReferred[referrer]++;
        referralsIds[referrer][referred] = num + 1;
    }

    function getReferredId(address referrer, address referred) public returns (uint256) {
        return referralsIds[referrer][referred];
    }

    function getReferrer(address referred) public returns (address) {
        return referrals[referred];
    }

    function getReferredNumber(address referrer) public returns (uint256) {
        return totalReferred[referrer];
    }

}

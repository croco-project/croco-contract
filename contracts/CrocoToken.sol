// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract CrocoToken is IERC20, ERC20, Ownable {

    mapping(address => address) referrals; // referred -> referrer
    mapping(address => mapping(address => uint256)) referralsIds; // referrer -> referred -> id
    mapping(address => mapping(uint256 => address)) referralsIndex; // referrer -> id -> referred
    mapping(address => uint256) totalReferred; // referrer -> total referred

    uint256[] public referralPermils = [500, 300, 100, 100, 100, 100, 50, 50, 50, 50];

    address public REFERRAL_POOL;
    bool public referralActive;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20 (name, symbol) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function setReferralPermils(uint256[] calldata permils) external onlyOwner {
        referralPermils = permils;
    }

    function setReferralPool(address _pool) external onlyOwner {
        REFERRAL_POOL = _pool;
    }

    function toggleReferralActive() external onlyOwner {
        referralActive = !referralActive;
    }

    function transferReferral(address from, address to, uint256 amount, address referrer) public returns (bool) {
        if (referralActive) {
            address _referrer = addOrGetReferrer(referrer, to);
            if (_referrer != address(0)) {
                uint256 _bonus = getReferralAmount(to, amount);
                if (_bonus > 0) {
                    _transfer(REFERRAL_POOL, _referrer, _bonus);
                }
            }
        }
        return transferFrom(from, to, amount);
    }

    function getReferralAmount(address to, uint256 amount) public view returns (uint256) {
        address _referrer = getReferrer(to);
        if (_referrer == address(0)) {
            return 0;
        }
        uint256 _balance = balanceOf(REFERRAL_POOL);
        if (_balance == 0) {
            return 0;
        }
        uint256 _id = getReferredId(_referrer, to);
        uint256 _bonus = amount * referralPermils[_id] / 10000;
        if (_balance > _bonus) {
            return _bonus;
        } else {
            return _balance;
        }
    }

    function getReferredId(address referrer, address referred) public view returns (uint256) {
        return referralsIds[referrer][referred];
    }

    function getReferrer(address referred) public view returns (address) {
        return referrals[referred];
    }

    function getReferredNumber(address referrer) public view returns (uint256) {
        return totalReferred[referrer];
    }

    function getReferredByIndex(address referrer, uint256 index) public view returns (address) {
        return referralsIndex[referrer][index];
    }

    function addOrGetReferrer(address referrer, address referred) public returns (address) {
        require(referrer != referred, "Can not add self as referrer");
        address _referrer = getReferrer(referred);
        if (_referrer != address(0)) {
            return _referrer;
        }
        require(referred != getReferrer(referrer), "Referred can not refer its referrer");
        if (getReferredNumber(referrer) < referralPermils.length) {
            setReferrer(referrer, referred);
            return referrer;
        }
        return address(0);
    }

    function setReferrer(address referrer, address referred) private {
        uint256 num = totalReferred[referrer]++;

        referralsIds[referrer][referred] = num;
        referralsIndex[referrer][num] = referred;
        referrals[referred] = referrer;
    }


}

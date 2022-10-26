// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function setReferralPermils(uint256[] calldata permils) external onlyOwner {
        referralPermils = permils;
    }

    function setReferralPool(address _pool) external onlyOwner {
        REFERRAL_POOL = _pool;
    }

    function transferReferral(address from, address to, uint256 amount, address referrer) public returns (bool) {
        if (referralActive) {
            address _referrer = addOrGetReferrer(referrer, to);
            uint256 _bonus = getReferralAmount(to, amount);
            if (_bonus > 0) {
                transferFrom(REFERRAL_POOL, _referrer, _bonus);
            }
        }
        return transferFrom(from, to, amount);
    }

    function getReferralAmount(address to, uint256 amount) public view returns (uint256) {
        uint256 _bonus = 0;

        address _referrer = getReferrer(to);
        if (_referrer != address(0)) {
            uint256 _id = getReferredId(_referrer, to);
            if (_id > 0) {
                uint256 _bonusTemp = amount * referralPermils[_id] / 100000;
                uint256 _balance = balanceOf(REFERRAL_POOL);
                if (_balance > _bonusTemp) {
                    _bonus = _bonusTemp;
                } else {
                    _bonus = _balance;
                }
            }
        }
        return _bonus;
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

    function addOrGetReferrer(address referrer, address referred) public returns (address) {
        require(referrer != referred, "Can not add self as referrer");

        address _referrer = getReferrer(referred);
        if (_referrer == referrer) {
            return _referrer;
        }

        if (_referrer != address(0)) {
            require(_referrer != referred, "Referred can not refer its referrer");
        }

        uint256 num = totalReferred[referrer]++;
        referralsIds[referrer][referred] = num + 1;
        return referrals[referred];
    }
}

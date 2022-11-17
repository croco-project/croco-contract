// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract CrocoToken is IERC20, ERC20, Ownable {

    mapping(address => address) referrals; // referred -> referrer
    mapping(address => uint256) totalReferred; // referrer -> total referred

    // levels
    // 3 -> 9 -> 27 (total 39) to get free nft
    uint256[] public referralPermils = [800, 400, 200];

    address public REFERRAL_POOL;
    bool public referralActive;

    mapping(address => bool) operators;

    struct Bonus {
        address to;
        uint256 bonus;
    }

    modifier onlyOperators {
        require(operators[msg.sender], "Sender is not an operator");
        _;
    }


    constructor(
        string memory name,
        string memory symbol
    ) ERC20 (name, symbol) {
        operators[msg.sender] = true;
    }

    function addOperator(address _operator) external onlyOwner {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyOwner {
        delete operators[_operator];
    }

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
            address _referrer = _addOrGetReferrer(referrer, to);
            if (_referrer != address(0)) {
                Bonus[] memory bonuses = getReferralAmount(to, amount);

                for (uint256 i = 0; i < bonuses.length; i++) {
                    if (bonuses[i].to != address(0) && bonuses[i].bonus > 0) {
                        _transfer(REFERRAL_POOL, bonuses[i].to, bonuses[i].bonus);
                    }
                }
            }
        }
        return transferFrom(from, to, amount);
    }

    function getReferralAmount(address to, uint256 amount) public view returns (Bonus[] memory) {
        Bonus[] memory bonuses = new Bonus[](referralPermils.length);
        address _referrer = to;
        for (uint256 i = 0; i < referralPermils.length; i++) {
            address __referrer = getReferrer(_referrer);
            bonuses[i] = Bonus(__referrer, amount * referralPermils[i] / 10000);
            _referrer = __referrer;
        }
        return bonuses;
    }

    function getReferrer(address referred) public view returns (address) {
        return referrals[referred];
    }

    function getReferredNumber(address referrer) public view returns (uint256) {
        return totalReferred[referrer];
    }

    function addOrGetReferrer(address referrer, address referred) onlyOperators public returns (address)  {
        return _addOrGetReferrer(referrer, referred);
    }

    function _addOrGetReferrer(address referrer, address referred) private returns (address) {
        require(referrer != referred, "Can not add self as referrer");
        address _referrer = getReferrer(referred);
        if (_referrer != address(0)) {
            return _referrer;
        }
        require(referred != getReferrer(referrer), "Referred can not refer its referrer");
        if (referrer == address(0)) {
            return address(0);
        }
        setReferrer(referrer, referred);
        return referrer;
    }

    function setReferrer(address referrer, address referred) private {
        referrals[referred] = referrer;
        totalReferred[referrer]++;

        address _referrer = referrer;
        for (uint256 i = 0; i < referralPermils.length - 1; i++) {
            address __referrer = getReferrer(_referrer);
            _referrer = __referrer;
            if (__referrer != address(0)) {
                totalReferred[__referrer]++;
            } else {
                break;
            }
        }
    }
}

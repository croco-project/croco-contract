// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// TODO: Uncomment this line to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CrocoToken.sol";


contract CrocoVesting is Ownable {
    using SafeMath for uint256;

    bool started;

    CrocoToken public crocoToken;
    IERC20 public usdt;

    struct VestingData {
        uint256 total;
        uint256 remainder;
    }

    mapping(address => VestingData) preSeedRound;
    mapping(address => VestingData) privateRound;
    mapping(address => VestingData) publicRound;
    mapping(address => VestingData) founders;
    mapping(address => VestingData) advisors;

    uint256 public preSeedPrice = 0.007 ether;
    uint256 public privatePrice = 0.015 ether;
    uint256 public publicPrice = 0.018 ether;

    uint256 public preSeedStart;
    uint256 public privateStart;
    uint256 public publicStart;

    enum Stage {
        PRESEED,
        PRIVATE,
        PUBLIC,
        CLOSED
    }

    constructor(CrocoToken _crocoToken, IERC20 _usdt) {
        crocoToken = _crocoToken;
        usdt = _usdt;
    }

    function withdrawToken(IERC20 _token) public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function stage() public returns (Stage) {
        if (!started) {
            return Stage.CLOSED;
        }

        if (block.timestamp > publicStart) {
            return Stage.PUBLIC;
        } else if (block.timestamp > privatePrice) {
            return Stage.PRIVATE;
        } else if (block.timestamp > preSeedPrice) {
            return Stage.PRESEED;
        }

        return Stage.CLOSED;
    }


    function currentRoundPrice() public returns (uint256) {
        Stage _stage = stage();
        if (_stage == Stage.PUBLIC) {
            return publicPrice;
        } else if (_stage == Stage.PRIVATE) {
            return privatePrice;
        } else if (_stage == Stage.PRESEED) {
            return preSeedPrice;
        }
        return 0;
    }

    function setPrice(
        uint256 _preSeedPrice,
        uint256 _privatePrice,
        uint256 _publicPrice
    ) public onlyOwner {
        preSeedPrice = _preSeedPrice;
        privatePrice = _privatePrice;
        publicPrice = _publicPrice;
    }

    function setStartTime(
        uint256 _preSeedStart,
        uint256 _privateStart,
        uint256 _publicStart
    ) public onlyOwner {
        preSeedStart = _preSeedStart;
        privateStart = _privateStart;
        publicStart = _publicStart;
    }

    function buyToken(uint256 _amount) public {
        Stage _stage = stage();
        require(_stage != Stage.CLOSED, "Token sale is closed");
        uint256 currentPrice = currentPrice();
        require(currentPrice > 0, "Current price is invalid");
        uint256 totalPrice = _amount.mul(currentPrice);
        usdt.transferFrom(msg.sender, address(this), totalPrice);

        if (_stage == Stage.PRESEED) {
            preSeedRound[msg.sender].total += _amount;
            preSeedRound[msg.sender].remainder += _amount;

            crocoToken.transferFrom(crocoToken.REFERRAL_POOL, c);

        } else if (_stage == Stage.PRIVATE) {
            privateRound[msg.sender].total += _amount;
            privateRound[msg.sender].remainder += _amount;
        } else if (_stage == Stage.PUBLIC) {
            publicRound[msg.sender].total += _amount;
            publicRound[msg.sender].remainder += _amount;
        }
    }


    function availableToClaim(address _address) public {

    }

    function claim() public {
        uint256 totalPrice = _amount.mul(currentPrice);
        usdt.transferFrom(msg.sender, address(this), totalPrice);
        crocoToken.transfer(msg.sender, _amount);
    }
}

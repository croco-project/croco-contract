// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CrocoToken.sol";


contract CrocoVesting is Ownable {
    using SafeMath for uint256;
    uint256 ONE_MONTH = 4 weeks;
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

    uint256 public preSeedUnlock;
    uint256 public privateUnlock;
    uint256 public publicUnlock;
    uint256 public founderUnlock;
    uint256 public advisorsUnlock;

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

    function withdrawToken(IERC20 _token) external onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function stage() public view returns (Stage) {
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


    function currentRoundPrice() public view returns (uint256) {
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

    function setUnlockTime(
        uint256 _preSeedUnlock,
        uint256 _privateUnlock,
        uint256 _publicUnlock,
        uint256 _founderUnlock,
        uint256 _advisorsUnlock
    ) public onlyOwner {
        preSeedUnlock = _preSeedUnlock;
        privateUnlock = _privateUnlock;
        publicUnlock = _publicUnlock;
        founderUnlock = _founderUnlock;
        advisorsUnlock = _advisorsUnlock;
    }

    function buyToken(uint256 _amount, address referrer) public {
        Stage _stage = stage();
        require(_stage != Stage.CLOSED, "Token sale is closed");
        uint256 currentPrice = currentRoundPrice();
        require(currentPrice > 0, "Current price is invalid");
        uint256 totalPrice = _amount.mul(currentPrice);
        usdt.transferFrom(msg.sender, address(this), totalPrice);

        address _referrer = crocoToken.addOrGetReferrer(referrer, msg.sender);
        uint256 _bonus = crocoToken.getReferralAmount(msg.sender, _amount);

        if (_stage == Stage.PRESEED) {
            preSeedRound[msg.sender].total += _amount;
            preSeedRound[msg.sender].remainder += _amount;
            if (_bonus > 0) {
                preSeedRound[_referrer].total += _bonus;
                preSeedRound[_referrer].remainder += _bonus;
            }
        } else if (_stage == Stage.PRIVATE) {
            privateRound[msg.sender].total += _amount;
            privateRound[msg.sender].remainder += _amount;
            if (_bonus > 0) {
                privateRound[_referrer].total += _bonus;
                privateRound[_referrer].remainder += _bonus;
            }
        } else if (_stage == Stage.PUBLIC) {
            publicRound[msg.sender].total += _amount;
            publicRound[msg.sender].remainder += _amount;
            if (_bonus > 0) {
                publicRound[_referrer].total += _bonus;
                publicRound[_referrer].remainder += _bonus;
            }
        }

        if (_bonus > 0) {
            crocoToken.transferFrom(crocoToken.REFERRAL_POOL(), address(this), _bonus);
        }
    }

    function getPreSeedAvailable(address _address) public view returns (uint256) {
        if (block.timestamp < preSeedUnlock) {
            return 0;
        }
        VestingData memory _data = preSeedRound[_address];
        return getUnlocked(_data, preSeedUnlock);
    }

    function getPrivateAvailable(address _address) public view returns (uint256) {
        if (block.timestamp < privateUnlock) {
            return 0;
        }
        VestingData memory _data = privateRound[_address];
        return getUnlocked(_data, privateUnlock);
    }

    function getPublicAvailable(address _address) public view returns (uint256) {
        if (block.timestamp < publicUnlock) {
            return 0;
        }
        VestingData memory _data = publicRound[_address];
        return getUnlocked(_data, publicUnlock);
    }

    function getAdvisorsAvailable(address _address) public view returns (uint256) {
        if (block.timestamp < advisorsUnlock) {
            return 0;
        }
        VestingData memory _data = publicRound[_address];
        return getUnlocked(_data, advisorsUnlock);
    }

    function getFoundersAvailable(address _address) public view returns (uint256) {
        if (block.timestamp < founderUnlock) {
            return 0;
        }
        VestingData memory _data = publicRound[_address];
        return _data.remainder;
    }

    function getUnlocked(VestingData memory _data, uint256 unlock) private view returns (uint256) {
        if (_data.remainder == 0) {
            return 0;
        }
        uint256 unlocks = (block.timestamp - unlock) / ONE_MONTH;
        uint256 unlocked = _data.total * unlocks / 100;
        if (unlocked >= _data.remainder) {
            return _data.remainder;
        }
        return unlocked;
    }

    function claimPreSeed() public {
        uint256 claimableAmount = getPreSeedAvailable(msg.sender);
        require(claimableAmount > 0, "No available tokens to claim");
        preSeedRound[msg.sender].remainder -= claimableAmount;
        crocoToken.transfer(msg.sender, claimableAmount);
    }

    function claimPrivate() public {
        uint256 claimableAmount = getPrivateAvailable(msg.sender);
        require(claimableAmount > 0, "No available tokens to claim");
        privateRound[msg.sender].remainder -= claimableAmount;
        crocoToken.transfer(msg.sender, claimableAmount);
    }

    function claimPublic() public {
        uint256 claimableAmount = getPublicAvailable(msg.sender);
        require(claimableAmount > 0, "No available tokens to claim");
        publicRound[msg.sender].remainder -= claimableAmount;
        crocoToken.transfer(msg.sender, claimableAmount);
    }

    function claimAdvisors() public {
        uint256 claimableAmount = getAdvisorsAvailable(msg.sender);
        require(claimableAmount > 0, "No available tokens to claim");
        advisors[msg.sender].remainder -= claimableAmount;
        crocoToken.transfer(msg.sender, claimableAmount);
    }

    function claimFounders() public {
        uint256 claimableAmount = getFoundersAvailable(msg.sender);
        require(claimableAmount > 0, "No available tokens to claim");
        founders[msg.sender].remainder -= claimableAmount;
        crocoToken.transfer(msg.sender, claimableAmount);
    }
}

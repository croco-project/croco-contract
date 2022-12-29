// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./CrocoToken.sol";


contract CrocoNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public supply = 10000;
    uint256[10000] private randomArray;
    uint256 private _randomIndex;

    uint256 public pricePerToken = 1 ether;

    bool public saleOpen;
    string public baseURI;

    CrocoToken public crocoToken;
    IERC20 public USDT;

    enum Status {
        Closed,
        SoldOut,
        Open
    }

    struct Info {
        Status stage;
        bool saleOpen;
        uint256 supply;
        uint256 minted;
        uint256 pricePerTokenPublic;
    }

    constructor(
        string memory name,
        string memory symbol,
        CrocoToken _crocoToken,
        IERC20 _usdt
    ) ERC721(name, symbol) {
        crocoToken = _crocoToken;
        USDT = _usdt;
    }

    function info() public view returns (Info memory) {
        return Info(
            stage(),
            saleOpen,
            supply,
            totalSupply(),
            pricePerToken
        );
    }

    function stage() public view returns (Status) {
        if (!saleOpen) {
            return Status.Closed;
        }

        if (totalSupply() >= supply) {
            return Status.SoldOut;
        }

        return Status.Open;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(IERC20 _token) public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function setSaleOpen() onlyOwner external {
        saleOpen = true;
    }

    function setSaleClose() onlyOwner external {
        saleOpen = false;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setPricePublic(uint256 _price) external onlyOwner {
        pricePerToken = _price;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        supply = _supply;
    }

    function genRandom() private view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function _pickRandomUniqueId() private returns (uint256 id) {
        uint256 random = genRandom();
        uint256 len = randomArray.length - _randomIndex++;
        require(len > 0, 'no ids left');
        uint256 randomIndex = random % len;
        id = randomArray[randomIndex] != 0 ? randomArray[randomIndex] : randomIndex;
        id += 1;
        randomArray[randomIndex] = uint16(randomArray[len - 1] == 0 ? len - 1 : randomArray[len - 1]);
        randomArray[len - 1] = 0;
    }

    function mintPublic(uint256 _tokenCount, address referral) external {
        require(saleOpen, "Sale is closed");
        require(address(crocoToken) != address(0), "Croco token not set");
        require(stage() == Status.Open, "Public mint not started");
        require(totalSupply() + _tokenCount <= supply, "Purchase would exceed max tokens");
        require(_tokenCount > 0, "Invalid token count supplied");


        USDT.transferFrom(msg.sender, address(this), pricePerToken * _tokenCount);
        crocoToken.addOrGetReferrer(referral, msg.sender);

        for (uint256 i = 0; i < _tokenCount; i++) {
            uint256 _tokenId = _pickRandomUniqueId();
            _safeMint(msg.sender, _tokenId);
        }
    }
}

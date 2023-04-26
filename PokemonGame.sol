// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "./StatsContract.sol";
// import "hardhat/console.sol";

// contract PokemonGame is ERC721, Ownable {

//     using Counters for Counters.Counter;
//     Counters.Counter private _tokenIdCounter;

//     uint constant MAX_STATS_SUM = 150;
//     uint constant MIN_STATS_SUM = 50;

//     StatsContract public statsContract;

//     constructor(string memory _name, string memory _symbol, address _statsContractAddress) ERC721(_name, _symbol) {
//         statsContract = StatsContract(_statsContractAddress);
//     }

//     function mintPokemon() public returns (uint256) {
//         console.log("log 1");
//         require(_tokenIdCounter.current() <= 10000, "Minting Stopped!");
//         console.log("log 2");
//         uint[6] memory stats;
//         console.log("log 3");
//         uint statsSum;
//         console.log("log 4");
//         uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))); //, totalSupply()
//         console.log("log 5");
//         // Generate random stats
//         stats[0] = (uint(keccak256(abi.encodePacked(randomSeed, "Attack"))) % 100) + 1;
//         stats[1] = (uint(keccak256(abi.encodePacked(randomSeed, "Defence"))) % 100) + 1;
//         stats[2] = (uint(keccak256(abi.encodePacked(randomSeed, "SP"))) % 100) + 1;
//         stats[3] = (uint(keccak256(abi.encodePacked(randomSeed, "HP"))) % 100) + 1;
//         stats[4] = (uint(keccak256(abi.encodePacked(randomSeed, "MP"))) % 100) + 1;
//         console.log("log 6");
//         uint battletype = (uint(keccak256(abi.encodePacked(randomSeed, "battleType"))) % 5);
//         console.log("log 7");
             
//         // Calculate random sum of stats
//         for (uint i = 0; i < stats.length; i++) {
//             statsSum += stats[i];
//         }
//         statsSum = (statsSum % (MAX_STATS_SUM - MIN_STATS_SUM + 1)) + MIN_STATS_SUM;
//         console.log("log 8");
//         // Scale stats to match the required sum
//         uint scaledStatsSum;
//         for (uint i = 0; i < stats.length; i++) {
//             stats[i] = stats[i] * statsSum / 500;
//             scaledStatsSum += stats[i];
//         }
//         console.log("log 9");
        
//         // Adjust stats if necessary to match the required sum exactly
//         if (scaledStatsSum != statsSum) {
//             stats[3] += (statsSum - scaledStatsSum);
//         }
//         console.log("log 10");
//         // Add stats to the stats contract
//         _tokenIdCounter.increment();
//         uint256 tokenId = _tokenIdCounter.current();
//         console.log("log 11");
//         statsContract.setPokemonStats(tokenId, stats[0], stats[1], stats[2], stats[3], stats[4], battletype);      
//         console.log("log 12");
//         // Mint the NFT
//         _mint(msg.sender, tokenId);
//         // _setTokenURI(tokenId, _tokenURI);
//         console.log("log 13");
//         return tokenId;
//     }
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./StatsContract.sol";
import "hardhat/console.sol";

contract PokemonGame is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint constant MAX_STATS_SUM = 150;
    uint constant MIN_STATS_SUM = 50;
    uint public MAX_TO_MINT = 10000;
    uint public MAX_WALLET_SIZE = 20;

    string private _baseUri;
    StatsContract public statsContract;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _isWhitelisted;

    constructor(address _statsContractAddress, string memory baseUri) ERC721("PokemonNFT", "PKMN") {
        statsContract = StatsContract(_statsContractAddress);
        _baseUri = baseUri;
    }

    function mintPokemon() public returns (uint256) {
        console.log("log 1");
        require(_tokenIdCounter.current() <= MAX_TO_MINT, "Minting Stopped!");
        require(balanceOf(msg.sender) + 1 <= MAX_WALLET_SIZE, "NFT: Balance exceeds wallet size!");
        console.log("log 2");
        uint[6] memory stats;
        console.log("log 3");
        uint statsSum;
        console.log("log 4");
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))); //, totalSupply()
        console.log("log 5");
        // Generate random stats
        stats[0] = (uint(keccak256(abi.encodePacked(randomSeed, "Attack"))) % 100) + 1;
        stats[1] = (uint(keccak256(abi.encodePacked(randomSeed, "Defence"))) % 100) + 1;
        stats[2] = (uint(keccak256(abi.encodePacked(randomSeed, "SP"))) % 100) + 1;
        stats[3] = (uint(keccak256(abi.encodePacked(randomSeed, "HP"))) % 100) + 1;
        stats[4] = (uint(keccak256(abi.encodePacked(randomSeed, "MP"))) % 100) + 1;
        console.log("log 6");
        uint battletype = (uint(keccak256(abi.encodePacked(randomSeed, "battleType"))) % 5);
        console.log("log 7");
             
        // Calculate random sum of stats
        for (uint i = 0; i < stats.length; i++) {
            statsSum += stats[i];
        }
        statsSum = (statsSum % (MAX_STATS_SUM - MIN_STATS_SUM + 1)) + MIN_STATS_SUM;
        console.log("log 8");
        // Scale stats to match the required sum
        uint scaledStatsSum;
        for (uint i = 0; i < stats.length; i++) {
            stats[i] = stats[i] * statsSum / 500;
            scaledStatsSum += stats[i];
        } 
        console.log("log 9");
        
        // Adjust stats if necessary to match the required sum exactly
        if (scaledStatsSum != statsSum) {
            stats[3] += (statsSum - scaledStatsSum);
        }
        console.log("log 10");
        // Add stats to the stats contract
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        console.log("log 11");
        statsContract.setPokemonStats(tokenId, stats[0], stats[1], stats[2], stats[3], stats[4], battletype);      
        console.log("log 12");
        // Mint the NFT
        _mint(msg.sender, tokenId);
        // _setTokenURI(tokenId, _tokenURI);
        console.log("log 13");
        return tokenId;
    }

    
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return string(abi.encodePacked(base, uint2str(tokenId)));
    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
    function whitelistAddress(address account, bool value) external onlyOwner{
        _isWhitelisted[account] = value;
    }

    function setMAX_TO_MINT(uint256 _maxToMint) public onlyOwner {
        require(MAX_TO_MINT > 0,"Max must be greater than 0 !");
        MAX_TO_MINT = _maxToMint;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    // internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(from != address(0), "ERC721: transfer from the zero address");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        // require(_isWhitelisted[from] && !_isWhitelisted[to], 'Whitelisted address');
        require(balanceOf(to) + 1 <= MAX_WALLET_SIZE, "NFT: Balance exceeds wallet size!");
        super._transfer(from, to, tokenId);
    }
}

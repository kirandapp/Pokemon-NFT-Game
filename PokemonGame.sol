// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PokemonGame is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _matchIdCounter;

    IERC721Enumerable private NFTContract;
    IERC20 private TokenContract;
    address public feeAddress;

    uint256 public tokenPriceToPlay = 50000; 
    uint256 public fee = 500; //5%  
    bool public isInitialize; 

    uint256[] public matchIds; 

    struct PokemonStats {
        uint256 attack;
        uint256 defense;
        uint256 sp;
        uint256 hp;
        uint256 mp;
        // string battleType;
        uint256 battleType;
    }
    string[5] BattleType = ["WOOD","WATER","LAND","FIRE","AIR"] ;//Wood water land fire AIR
    string[5] StatType = ["ATTACK","DEFENSE","SP","HP","MP"] ;//Wood water land fire AIR
    
    struct Battle {
        uint256 matchId;
        uint256 nftid;
        uint256 stat;
        uint256 statIndex;
        uint256 battle;
        uint256 stateSum;
        bool winnerDeclared;
    }
    mapping (uint256 => Battle) private _battle;
    mapping (uint256 => uint256) private winner;

    mapping (uint256 => PokemonStats) private _pokemonStats;
    mapping (address => bool) private isWhitelist;

    function initialize(address _nft, address _token) public {
        require(!isInitialize,"Already Initialize!");
        require(owner() == msg.sender, "Only owner can initialize");
        require(_nft != address(0) && _token != address(0));
        feeAddress = msg.sender;
        isWhitelist[_nft] = true;
        isWhitelist[_token] = true;
        NFTContract = IERC721Enumerable(_nft);
        TokenContract = IERC20(_token);
        isInitialize = true;
    }
    
    function createBattle() public {
        uint256 numNFTs = NFTContract.balanceOf(msg.sender);
        console.log(numNFTs);
        require(numNFTs > 0, "You don't have any NFTs");
        require(TokenContract.balanceOf(msg.sender) >= tokenPriceToPlay, "Insufficient Token to play ");

        // take token to create battle
        TokenContract.transferFrom(msg.sender, address(this), tokenPriceToPlay);

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % numNFTs;
        (bool success, bytes memory result) = address(NFTContract).call(abi.encodeWithSignature("tokensOfOwner(address)", msg.sender));
        require(success, "Call to tokensOfOwner failed");
        uint256[] memory nftIds = abi.decode(result, (uint256[]));
        console.log("1");
        uint256 randomNftId = nftIds[randomIndex];
        console.log("Selected Id",randomNftId);
        PokemonStats memory nftstats = _pokemonStats[randomNftId];
        uint256 statindex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % 5;
        uint256 stat;
        if (statindex == 0) {
            stat = nftstats.attack;
        } else if (statindex == 1) {
            stat = nftstats.defense;
        } else if (statindex == 2) {
            stat = nftstats.sp;
        } else if (statindex == 3) {
            stat = nftstats.hp;
        }else {
            stat = nftstats.mp;
        }
        // Do something with the selected NFT and stat...
        _matchIdCounter.increment();
        uint256 _matchId = _matchIdCounter.current();
        uint256 sum = findSumOfStats(randomNftId);
        _battle[_matchId] = Battle(_matchId, randomNftId, stat, statindex, nftstats.battleType, sum, false);
        matchIds.push(_matchId);
    }

    function play(uint _matchId) public {
        Battle memory bt = _battle[_matchId];
        require(!bt.winnerDeclared,"This MatchId Closed");
        uint256 numNFTs = NFTContract.balanceOf(msg.sender);
        require(numNFTs > 0, "You don't have any NFTs");
        require(TokenContract.balanceOf(msg.sender) >= tokenPriceToPlay, "Insufficient Token to play ");
        // take token to play battle
        TokenContract.transferFrom(msg.sender, address(this), tokenPriceToPlay);

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.number))) % numNFTs;
        (bool success, bytes memory result) = address(NFTContract).call(abi.encodeWithSignature("tokensOfOwner(address)", msg.sender));
        require(success, "Call to tokensOfOwner failed");
        uint256[] memory nftIds = abi.decode(result, (uint256[]));
        console.log("1");
        uint256 randomNftId = nftIds[randomIndex];
        console.log("Selected ID",randomNftId);
        PokemonStats memory nftstats = _pokemonStats[randomNftId];
        uint256 sum = findSumOfStats(randomNftId);
        uint statindex = bt.statIndex;
        uint stat;
        if (statindex == 0) {
            stat = nftstats.attack;
            console.log("Selected Stat",stat);
        } else if (statindex == 1) {
            stat = nftstats.defense;
            console.log("Selected Stat",stat);
        } else if (statindex == 2) {
            stat = nftstats.sp;
            console.log("Selected Stat",stat);
        } else if (statindex == 3) {
            stat = nftstats.hp;
            console.log("Selected Stat",stat);
        }else {
            stat = nftstats.mp;
            console.log("Selected Stat",stat);
        }
        //Winning conditions        
        if (bt.stat > stat) {
            console.log("Winner is ",bt.nftid);
            // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
            winner[_matchId] = bt.nftid;
            calculateFee(tokenPriceToPlay, bt.nftid);            
        } else if (bt.stat < stat) {
            console.log("Winner is ",randomNftId);
            // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
            winner[_matchId] = randomNftId;
            calculateFee(tokenPriceToPlay, randomNftId);
        } else if (bt.stateSum > sum) {
            console.log("Winner is ",bt.nftid);
            // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
            winner[_matchId] = bt.nftid;
            calculateFee(tokenPriceToPlay, bt.nftid);
        } else if (bt.stateSum < sum) {
            console.log("Winner is ",randomNftId);
            winner[_matchId] = randomNftId;
            calculateFee(tokenPriceToPlay, randomNftId);
        } else if(bt.battle == 0) {
            if(nftstats.battleType == 1 || nftstats.battleType == 2) {
                console.log("Winner is ",bt.nftid);
                // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
                winner[_matchId] = bt.nftid;
                calculateFee(tokenPriceToPlay, bt.nftid);
            } else {
                console.log("Winner is ",randomNftId);
                // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
                winner[_matchId] = randomNftId;
                calculateFee(tokenPriceToPlay, randomNftId);
            }
        } else if(bt.battle == 1) {
            if(nftstats.battleType == 2 || nftstats.battleType == 3) {
                console.log("Winner is ",bt.nftid);
                // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
                winner[_matchId] = bt.nftid;
                calculateFee(tokenPriceToPlay, bt.nftid);
            } else {
                console.log("Winner is ",randomNftId);
                // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
                winner[_matchId] = randomNftId;
                calculateFee(tokenPriceToPlay, randomNftId);
            }
        } else if(bt.battle == 2) {
            if(nftstats.battleType == 3 || nftstats.battleType == 4) {
                console.log("Winner is ",bt.nftid);
                // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
                winner[_matchId] = bt.nftid;
                calculateFee(tokenPriceToPlay, bt.nftid);
            } else {
                console.log("Winner is ",randomNftId);
                // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
                winner[_matchId] = randomNftId;
                calculateFee(tokenPriceToPlay, randomNftId);
            }
        } else if(bt.battle == 3) {
            if(nftstats.battleType == 0 || nftstats.battleType == 4) {
                console.log("Winner is ",bt.nftid);
                // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
                winner[_matchId] = bt.nftid;
                calculateFee(tokenPriceToPlay, bt.nftid);
            } else {
                console.log("Winner is ",randomNftId);
                // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
                winner[_matchId] = randomNftId;
                calculateFee(tokenPriceToPlay, randomNftId);
            }
        } else if(bt.battle == 4) {
            if(nftstats.battleType == 0 || nftstats.battleType == 1) {
                console.log("Winner is ",bt.nftid);
                // winner[_matchId] = string(abi.encodePacked(matchnftId," is the winner..."));
                winner[_matchId] = bt.nftid;
                calculateFee(tokenPriceToPlay, bt.nftid);
            } else {
                console.log("Winner is ",randomNftId);
                // winner[_matchId] = string(abi.encodePacked(randomNftId," is the winner..."));
                winner[_matchId] = randomNftId;
                calculateFee(tokenPriceToPlay, randomNftId);
            }
        } else {
            console.log("NO ONE IS WINNER");
            winner[_matchId] = 0;
        }
        bt.winnerDeclared = true;
    }

    //internal function
    function findSumOfStats(uint256 _nftId) internal view returns (uint256) {
        PokemonStats memory nftstats = _pokemonStats[_nftId];
        return nftstats.attack + nftstats.defense + nftstats.sp + nftstats.hp + nftstats.mp;
    }
    function calculateFee(uint256 _token, uint256 nftid) internal {
        address win = NFTContract.ownerOf(nftid);
        uint256 platformFee = _token * fee / 100 / 100;
        TokenContract.transferFrom(msg.sender, feeAddress, platformFee);
        TokenContract.transfer(win, _token*2 - platformFee);
    }

    //  SETTER FUNCTIONS
    function setInitialize(bool _bool) public onlyOwner {
        isInitialize = _bool;
    }
    function setNFTaddress(IERC721Enumerable _nft) public onlyOwner {
        NFTContract = _nft;
    }
    function setTokenaddress(IERC20 _token) public onlyOwner {
        TokenContract = _token;
    }
    function setFeeAddress(address _addr) public onlyOwner {
        feeAddress = _addr;
    }
    function setWhitelisted(address _addr) public onlyOwner {
        isWhitelist[_addr] = true;
    }
    function setBattleType(string[] memory _type) public onlyOwner {
        for ( uint i = 0; i < _type.length; i++ ) {
            BattleType[i] = _type[i];
        }
    }
    function setPokemonStats(uint256 tokenId, uint256 attack, uint256 defense, uint256 sp, uint256 hp, uint256 mp, uint _typeIndex) external {
        require(isWhitelist[msg.sender], "StatsContract: Only the whitelisted addresses can set Pokemon stats.");
        require(attack + defense + sp + hp + mp <= 150, "StatsContract: Total stats can't exceed 150.");
        PokemonStats memory stats = PokemonStats({
            attack: attack,
            defense: defense,    
            sp: sp,                                                                                                             
            hp: hp,
            mp: mp,
            // battleType: BattleType[_typeIndex]
            battleType: _typeIndex
        });
        _pokemonStats[tokenId] = stats;
    }

    //  GETTER FUNCTIONS
    function getPokemonStats(uint256 tokenId) external view returns (uint256, uint256, uint256, uint256, uint256, string memory) {
        PokemonStats storage stats = _pokemonStats[tokenId];
        return (stats.attack, stats.defense, stats.sp, stats.hp, stats.mp, BattleType[stats.battleType]);  
    }
    function getBattleTypes() public view returns (string[5] memory) {
        return BattleType;
    }
    function getStatTypes() public view returns (string[5] memory) {
        return StatType;
    }
    function getCreatedBattle(uint256 _matchId) public view returns (uint256, uint256, uint256, uint256, uint256) {
        Battle memory bt = _battle[_matchId];
        return (bt.matchId, bt.nftid, bt.stat, bt.statIndex, bt.stateSum);
    }
    function isWhitelisted(address _addr) public view returns (bool) {
        return isWhitelist[_addr];
    }
    function getNFTContract() public view returns (IERC721Enumerable) {
        return NFTContract;
    }
    function getTokenContract() public view returns (IERC20) {
        return TokenContract;
    }
    function getWinner(uint256 _matchId) public view returns (uint) {
        return winner[_matchId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Tiers is ERC721Enumerable, Ownable{

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  
  string public baseURI;
  uint256  maxMintAmount = 10;
  bool  paused = false;

  mapping(uint256 => uint256) tiersCosts;
  mapping(uint256 => uint256) tiersSupply;
  mapping(uint256 => uint256) tiersMinted;
  mapping(uint256 => string) tiersNames;
  mapping(uint256 => uint256) tokenToTier;
  mapping(uint256 => uint256) tierCounter; // token -> countIndex
  mapping(uint256 => uint256) tokenCounter;

  Tier[] tiers;

  string public baseExtension = ".json";

  mapping(address => bool)  whitelisted;

  struct Tier{
    uint256 id;
    uint256 cost;
    uint256 supply;
    uint256 minted;
    string name;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
     
    setBaseURI(_initBaseURI);
  }


  //SETS COSTS AND SUPPLY OF TIERS

  //get cost of minitig for a particular tier
  function getCost(uint256 _tierId) public  view returns (uint256) {
    return tiersCosts[_tierId];
  }

  //get supply of minitig for a particular tier
  function getSupply(uint256 _tierId) public view returns (uint256) {
    return tiersSupply[_tierId];
  }

  //get supply of minitig for a particular tier
  function getName(uint256 _tierId) public view returns (string memory) {
    return tiersNames[_tierId];
  }

  //get supply of minitig for a particular tier
  function getTiers() public view returns (Tier[] memory) {
    return tiers;
  }

  //check if tier has been minted
  function getTiersMinted(uint256 _tierId) public view returns(uint256){
    return tiersMinted[_tierId];
  }


  //sets a tier
  function setTier(uint256 _tierId,string memory _tierName,uint256 _cost, uint256 _supply) public onlyOwner{
    (,bool tierExist) = searchTier(_tierId);
    require(!tierExist,'tier already created');
    require(_cost>=0,'tier _cost must be >= 0');
    require(_supply>0,'tier _supply must be > 0');
    setCost(_tierId, _cost);
    setSupply(_tierId, _supply);
    setName(_tierId,_tierName);
    Tier memory newTier;
    newTier.id = _tierId;
    newTier.cost = _cost;
    newTier.supply = _supply;
    newTier.name = _tierName;
    tiers.push(newTier);
  }

  //WARINING REMOVES ALL TIER INFORMATION OF PARTICULAR TIER, a constraint is no 1 minted for that tier
  function removeTier(uint256 _tierId) public onlyOwner{
    require(tiersMinted[_tierId] == 0,'there has been minted some nft for this tier');
    delete tiersSupply[_tierId];
    delete tiersCosts[_tierId];
    delete tiersMinted[_tierId];
    delete tiersNames[_tierId];
    delete tierCounter[_tierId];
    (uint256 index,bool res) = searchTier(_tierId);
    if(res){
      for(uint i=index;i<tiers.length;i++){
         if(i+1<tiers.length)
         tiers[i] = tiers[i+1];
      } 
      tiers.pop();
    }
  }


  function searchTier(uint256 _tierId) internal view returns(uint256,bool){
    for(uint i=0;i<tiers.length;i++){
      if(tiers[i].id==_tierId){
       return (i,true);
      }
    }
    return (0,false);
  }

  //set cost of minitig for a particular tier, must pass wei because contracts works with wei 1 eth = 1*10^18 wei
  function setCost(uint256 _tierId,uint256 _newCost) public onlyOwner {
    require(_newCost>=0,'tier _cost must be > 0');
    tiersCosts[_tierId] = _newCost;
    (uint256 index,bool res) = searchTier(_tierId);
    if(res){
      tiers[index].cost = _newCost;
    }
  }

  //set cost of minitig for a particular tier
  function setSupply(uint256 _tierId,uint256 _newSupply) public onlyOwner {
    require(_newSupply>0,'tier _supply must be > 0');
    require(_newSupply>=tiersMinted[_tierId],'tier _newSupply must be > tiersMinted of that tier');
    tiersSupply[_tierId] = _newSupply;
    (uint256 index,bool res) = searchTier(_tierId);
    if(res){
      tiers[index].supply = _newSupply;
    }
  }

  //set cost of minitig for a particular tier
  function setName(uint256 _tierId,string memory _name) public onlyOwner {
    tiersNames[_tierId] = _name;
    (uint256 index,bool res) = searchTier(_tierId);
    if(res){
      tiers[index].name = _name;
    }
  }

  // mint token
  function mint(uint256 tierId,address _to, uint _amount) public payable {
    require(!paused,'contract is paused!');
    require(tiersMinted[tierId] + _amount <= tiersSupply[tierId],'all tokens for that tier have been minted!');
    require(_amount<=maxMintAmount,'cant mint more than max Mint Amount!');
    require(_amount>0,'must mint at least 1!');
    if(whitelisted[msg.sender] != true) {
        require(msg.value >= tiersCosts[tierId]*_amount,'not enough ether sent!');
    }

    for(uint i=0;i<_amount;i++){
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      
      _safeMint(_to, newItemId);
      
      tokenToTier[newItemId]=tierId;

      tiersMinted[tierId] += 1;
      (uint256 index,bool res) = searchTier(tierId);
      if(res){
        tiers[index].minted+=1;
      }
      tierCounter[tierId]+=1;
      tokenCounter[newItemId]=tierCounter[tierId];
    }
  }


  // internal, base uri
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //all the nfts of an address
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  //uri of ERC721 
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token!"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI,tokenToTier[tokenId].toString(),'/',tokenCounter[tokenId].toString(), baseExtension))
        : "";
  }

  //set ERC721 uri
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  //pause contract (no minting)
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

 function isWhiteListed(address _user) external view returns(bool){
   return whitelisted[_user];
 }
 
 //whitelist user for minting for free
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
 //remove user from whitelist
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  //wirthdraw funds from the contract 
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  //receive function
  receive() payable external {} 


}
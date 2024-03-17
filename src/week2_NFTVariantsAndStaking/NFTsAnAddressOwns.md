# Revisit the solidity events tutorial. How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable? Explain how you would accomplish this if you were creating an NFT marketplace.

To quickly find out which NFTs someone owns on OpenSea, even if the NFTs don't use ERC721 enumerable, we listen for Transfer events on all NFT contracts. These events show who currently owns a specific token. This helps us track transfers instantly, even if they happen elsewhere.

For example, using the ethers library:

```javascript
const abi = ["event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId)"];
const contract = new Contract(contract_address, abi, provider);

// Listen for Transfer events
contract.on("Transfer", (from, to, tokenId, event) => {
  // Update the database to know the new owner instantly
});

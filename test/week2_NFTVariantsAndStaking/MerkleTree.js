import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// (1)
const values = [
    ["0x0000000000000000000000000000000000000001", 1],
    ["0x0000000000000000000000000000000000000002", 2],
    ["0x0000000000000000000000000000000000000003", 3],
    ["0x0000000000000000000000000000000000000004", 4],
    ["0x0000000000000000000000000000000000000005", 5]
];

// (2)
const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

// (3)
console.log('Merkle Root:', tree.root);

// (4)
fs.writeFileSync("test/week2_NFTVariantsAndStaking/tree.json", JSON.stringify(tree.dump()));

function getProof() {
    const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("test/week2_NFTVariantsAndStaking/tree.json", "utf8")));

    for (const [i, v] of tree.entries()) {
        const proof = tree.getProof(i);
        console.log('Value:', v);
        console.log('Proof:', proof);
    }
}

getProof()

// Merkle Root: 0xceebea2297b98ffa1df9aa241ca1eba9b7114c9609a8a9514b3a3f071982cd96
// Value: [ '0x0000000000000000000000000000000000000001', 1 ]
// Proof: [
//   '0x98e19d0f170da4e9f222a0166630f82d7adee7523ea47ac943253c6ffaeffc7c',
//   '0xfa8d260207fe657f2346775cc7df9e07ba0a08e64ccd28972b30bb03ba9b295b',
//   '0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057'
// ]
// Value: [ '0x0000000000000000000000000000000000000002', 2 ]
// Proof: [
//   '0xae1f6f36060f166f063fb01d63adab80297f56b5a444cab19384c535141dbd8b',
//   '0x458278ced3fbcb303a4187fc39731d3b4baa96fae67c49c9f926bd2eef841f00'
// ]
// Value: [ '0x0000000000000000000000000000000000000003', 3 ]
// Proof: [
//   '0xf4db59b54a5e9961a45b0001f7477f286d59ef59c37f4ab9ab5c29eb4b34004a',
//   '0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057'
// ]
// Value: [ '0x0000000000000000000000000000000000000004', 4 ]
// Proof: [
//   '0xd70731c4fc4bf9cd8fc2be4d898bd67fd357eb0135035bf4500364b4c42c4fa5',
//   '0x458278ced3fbcb303a4187fc39731d3b4baa96fae67c49c9f926bd2eef841f00'
// ]
// Value: [ '0x0000000000000000000000000000000000000005', 5 ]
// Proof: [
//   '0x66b32740ad8041bcc3b909c72d7e1afe60094ec55e3cde329b4b3a28501d826c',
//   '0xfa8d260207fe657f2346775cc7df9e07ba0a08e64ccd28972b30bb03ba9b295b',
//   '0x903bb9eadd38da603295afd967a5629ae1d6ccf678cffbf86e785c4a63304057'
// ]
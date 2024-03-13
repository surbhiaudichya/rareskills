// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {RewardToken} from "./RewardToken.sol";

contract StakingContract is IERC721Receiver {
    address nft;
    RewardToken public immutable rewardToken;
    uint256 rewardPer24Hours = 10e18;
    uint256 perDay = 1 days;
    uint256 public lastRewardTimestamp;
    uint256 accRewardPerToken;

    struct Stake {
        uint256 stackingTime;
        address originalOwner;
    }

    struct User {
        uint256 totalBalance;
        uint256 debt;
    }

    error IncorrectOwner();
    error NFTContractOnly();

    event NFTDeposited(address indexed user, uint256 tokenId);
    event NFTWithdrawn(address indexed user, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 rewardToMint, uint256 amount);

    constructor(address _nft) {
        nft = _nft;
        rewardToken = new RewardToken();
    }

    mapping(uint256 => Stake) public stakes;
    mapping(address => User) public users;

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        public
        override
        returns (bytes4 selector)
    {
        if (msg.sender != address(nft)) {
            revert NFTContractOnly();
        }

        UpdateReward();

        if (users[from].totalBalance > 0) {
            uint256 rewardToMint = users[from].totalBalance * accRewardPerToken - users[from].debt;
            RewardToken(rewardToken).mint(from, rewardToMint);
            emit RewardsClaimed(from, rewardToMint, rewardToMint);
        }

        users[from] = User({totalBalance: users[from].totalBalance + 1, debt: users[from].debt + accRewardPerToken});
        stakes[tokenId] = Stake({stackingTime: block.timestamp, originalOwner: from});

        emit NFTDeposited(from, tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw(uint256 tokenId) external {
        if (msg.sender != stakes[tokenId].originalOwner) {
            revert IncorrectOwner();
        }

        UpdateReward();

        uint256 rewardToMint = users[msg.sender].totalBalance * accRewardPerToken - users[msg.sender].debt;
        RewardToken(rewardToken).mint(msg.sender, rewardToMint);
        emit RewardsClaimed(msg.sender, rewardToMint, rewardToMint);

        users[msg.sender] = User({totalBalance: users[msg.sender].totalBalance - 1, debt: users[msg.sender].debt});

        delete stakes[tokenId];

        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTWithdrawn(msg.sender, tokenId);
    }

    function UpdateReward() internal {
        if (block.timestamp > lastRewardTimestamp) {
            if (lastRewardTimestamp != 0) {
                uint256 timeSinceLastReward = block.timestamp - lastRewardTimestamp;

                uint256 rewardPerTokenAccumulated = (rewardPer24Hours * timeSinceLastReward) / perDay;

                accRewardPerToken += rewardPerTokenAccumulated;
            }

            lastRewardTimestamp = block.timestamp;
        }
    }
}

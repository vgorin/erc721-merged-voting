// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Tier Aware
 *
 * @notice An interface marking the contracts capable of retrieving
 *      the tier of any given NFT
 *
 * @dev Implementations may not support all the ERC721 contract addresses
 *      and may throw for some or all of them
 *
 * @author Basil Gorin
 */
interface TierAware {
	/**
	 * @notice Gets the tier level for a given NFT
	 *
	 * @param nftAddress ERC721 contract address
	 * @param tokenId NFT ID to query tier for
	 * @return zero if NFT doesn't exist, its tier otherwise
	 */
	function getTier(address nftAddress, uint256 tokenId) external view returns(uint8);
}

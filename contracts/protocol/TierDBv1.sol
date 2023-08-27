// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/UpgradeableAccessControl.sol";

/**
 * @title ERC721 Existable
 *
 * @notice Tiny subset of ERC721 interface allowing to check if NFT exists
 *
 * @author Basil Gorin
 */
interface ERC721Existable {
	/**
 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);
}

/**
 * @title Tier DB
 *
 * @notice Tier DB enriches ERC721 token with its tier information,
 *      which is then used for voting with the ERC721 tokens:
 *
 *      voting_power = fn(tier)
 *
 *      For example: voting_power(tier) = 2 ^ (tier - 1)
 *
 * @notice Version 1
 *
 * @author Basil Gorin
 */
// TODO: implement tests for the contract
// TODO: implement the Merger contract which would have the permission to increase NFT tier
contract TierDBv1 is UpgradeableAccessControl {
	/**
	 * @dev maps token ID => tier level minus one
	 *
	 * @dev Tier level is derived from the value stored here by increasing it by one,
	 *      so that all the existing tokens default tier is one, not zero
	 *
	 * @dev There is no setter function to update the tier to any value,
	 *      it can only be increased by one (many times)
	 */
	mapping(uint256 => uint8) private tiers;

	/**
	 * @dev ERC721 contract Tier DB is bound to
	 *
	 * @dev The tier of non-existing NFTs is zero
	 */
	ERC721Existable private nftContract;

	/**
	 * @notice Maximum possible tier for an NFT, defining eventually
	 *      maximum voting power of the NFT
	 *
	 *      For example: voting_power(7) = 2 ^ (7 - 1) = 64
	 */
	uint8 public constant MAXIMUM_TIER = 7;

	/**
	 * @notice Tier manager is responsible for increasing NFTs tier
	 *
	 * @dev Role ROLE_TIER_MANAGER allows executing `increaseTier` function
	 */
	uint32 public constant ROLE_TIER_MANAGER = 0x0001_0000;

	/**
	 * @dev Fired in increaseTier
	 *
	 * @param nftContract address of the NFT contract
	 * @param tokenId NFT ID
	 * @param tier new tier value set for the given NFT
	 */
	event TierIncreased(address indexed nftContract, uint256 indexed tokenId, uint8 tier);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be executed immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 */
	function postConstruct(address _nftContract) public initializer {
		// verify the address is set
		require(_nftContract != address(0), "NFT contract not set");

		// initialize contract internal state
		nftContract = ERC721Existable(_nftContract);

		// execute all parent initializers in cascade
		InitializableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @notice Gets the tier level for an NFT with the given ID
	 *
	 * @param tokenId NFT ID to query tier for
	 * @return zero if NFT doesn't exist, its tier otherwise
	 */
	function getTier(uint256 tokenId) public view returns(uint8) {
		// check if NFT with given ID exists, return zero if not, return value from the mapping if yes
		return nftContract.exists(tokenId)? tiers[tokenId] + 1: 0;
	}

	/**
	 * @notice Restricted access function to increase tier of the NFT
	 *      defined by its ID
	 *
	 * @dev Requires NFT with the given ID to exist
	 *
	 * @param tokenId NFT ID to increase tier for
	 */
	function increaseTier(uint256 tokenId) public {
		// verify function access
		require(isSenderInRole(ROLE_TIER_MANAGER), "access denied");

		// verify NFT with the given ID exists
		require(nftContract.exists(tokenId), "NFT doesn't exist");

		// verify tier upper bound is satisfied
		require(tiers[tokenId] < MAXIMUM_TIER - 1, "tier level exceeded");

		// set tier level for the NFT wih thee given ID
		tiers[tokenId] += 1;

		// emit an event
		emit TierIncreased(address(nftContract), tokenId, tiers[tokenId]);
	}

	/**
	 * @notice Calculates the default voting power according to the default formula
	 *
	 *      voting_power(tier) = 2 ^ (tier - 1)
	 *
	 *      voting power is zero for non-existent tokens
	 *      voting power is in range [1, 64] for tokens in existence
	 *
	 * @notice Client applications are free to override this and use any formula
	 *
	 * @param tokenId NFT to calculate voting power for
	 * @return zero if NFT doesn't exist, its voting power otherwise
	 */
	function defaultVotingPower(uint256 tokenId) public view returns(uint16) {
		// get NFT's tier level as uint16 to be save from int overflows
		// if `MAXIMUM_TIER` is accidentally increased without modifying this function
		uint16 tier = getTier(tokenId);

		// calculate the voting power, keeping in mind that tier zero means non-existent token
		return tier > 0? (tier - 1) ** 2: 0;
	}
}

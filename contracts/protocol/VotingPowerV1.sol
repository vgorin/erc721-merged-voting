// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/VotingPowerLogic.sol";
import "../utils/UpgradeableAccessControl.sol";
import "../interfaces/TierAware.sol";

/**
 * @title Default Voting Power Logic
 *
 * @notice Default voting logic applies to the the owners of NFTs having a tier
 *
 * @notice The NFT with the tier level `tier` has the voting power
 *
 *      voting_power(tier) = 2 ^ (tier - 1)
 *
 * @notice Voting power of the NFT owner is a sum of voting powers of all the
 *      NFTs owned by the address
 *
 * @dev Version 1
 *
 * @author Basil Gorin
 */
contract VotingPowerV1 is VotingPowerLogic, UpgradeableAccessControl {
	/**
	 * @dev ERC721 contract Voting Logic is bound to
	 */
	ERC721Enumerable private nftContract;

	/**
	 * @dev Read-only link to the TierDB contract, used to fetch
	 *      tier level for the NFTs when calculating voting power
	 */
	TierAware private tierDB;

	/**
	 * @dev "Constructor replacement" for upgradeable, must be executed immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _nftContract ERC721 contract Voting Logic is bound to
	 * @param _tierDB TierDB contract Voting Logic is bound to
	 */
	function postConstruct(address _nftContract, address _tierDB) public initializer {
		// verify the address is set
		require(_nftContract != address(0), "NFT contract not set");
		require(_tierDB != address(0), "TierDB address not set");

		// initialize contract internal state
		nftContract = ERC721Enumerable(_nftContract);
		tierDB = TierAware(_tierDB);

		// execute all parent initializers in cascade
		InitializableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @notice Translates the tier to the voting power according to the formula
	 *
	 *      voting_power(tier) = 2 ^ (tier - 1)
	 *
	 *      voting power is zero for tier 0 tokens (non-existent tokens)
	 *
	 * @param tier tier of the NFT
	 * @return zero if NFT doesn't exist, its voting power otherwise
	 */
	function votingPowerFunction(uint8 tier) public pure returns(uint16) {
		// calculate the voting power, keeping in mind that tier zero means non-existent token
		return tier > 0? uint16(2) ** (tier - 1): 0;
	}

	/**
	 * @notice Sums up the default voting power of the NFT owner according to the default formula
	 *
	 *      voting_power(tier) = 2 ^ (tier - 1)
	 *
	 * @notice Client applications are free to override this and use any formula
	 *
	 * @param owner address to calculate voting power for
	 * @return cumulative voting power of the address; zero if address doesn't own any NFTs
	 */
	function votingPowerOf(address owner) public view override returns(uint256) {
		// define the variable to accumulate the voting power for all owner's NFTs
		uint256 votingPower;

		// iterate over the entire NFT collection of the given owner
		for(uint256 i = 0; i < nftContract.balanceOf(owner); i++) {
			// fetch the NFT ID
			uint256 tokenId = nftContract.tokenOfOwnerByIndex(owner, i);

			// get the tier level of the fetched NFT
			uint8 tier = tierDB.getTier(address(nftContract), tokenId);

			// apply the voting power function
			votingPower += votingPowerFunction(tier);
		}

		// return the cumulative voting power
		return votingPower;
	}
}

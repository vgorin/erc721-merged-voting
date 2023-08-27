// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Voting Power Logic
 *
 * @notice An interface marking the contracts capable of calculating
 *      the voting power of any given address
 *
 * @author Basil Gorin
 */
interface VotingPowerLogic {
	/**
	 * @notice Calculates voting power of the given address
	 *
	 * @param voter address to calculate voting power for
	 * @return voting power of the given voter
	 */
	function votingPowerOf(address voter) external view returns(uint256);
}

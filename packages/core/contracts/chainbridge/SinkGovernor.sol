// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../oracle/interfaces/FinderInterface.sol";
import "../oracle/implementation/Constants.sol";

/**
 * @title Governor contract on L2 that receives governance actions from L1.
 */
contract SinkGovernor {
    FinderInterface public finder;

    event ExecutedGovernanceTransaction(address indexed to, uint256 value, bytes indexed data);

    constructor(FinderInterface _finder) {
        finder = _finder;
    }

    /**
     * @notice This method will ultimately be called after a governance execution has been bridged cross-chain from Mainnet
     * to this network via an off-chain relayer. The relayer will call `Bridge.executeProposal` on this local network,
     * which call `GenericHandler.executeProposal()` and ultimately this method.
     * @dev This method should send the arbitrary transaction emitted by the L1 governor on this chain.
     */
    function executeGovernance(
        address to,
        uint256 value,
        bytes memory data
    ) external {
        require(
            msg.sender == finder.getImplementationAddress(OracleInterfaces.GenericHandler),
            "Generic handler must call"
        );

        // Note: this snippet of code is copied from Governor.sol.
        // Mostly copied from:
        // solhint-disable-next-line max-line-length
        // https://github.com/gnosis/safe-contracts/blob/59cfdaebcd8b87a0a32f87b50fead092c10d3a05/contracts/base/Executor.sol#L23-L31
        // solhint-disable-next-line no-inline-assembly
        bool success;
        assembly {
            let inputData := add(data, 0x20)
            let inputDataSize := mload(data)
            success := call(gas(), to, value, inputData, inputDataSize, 0, 0)
        }
        require(success, "Governance call failed");

        emit ExecutedGovernanceTransaction(to, value, data);
    }
}

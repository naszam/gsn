// SPDX-License-Identifier:MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterConfigurableMisbehavior is TestPaymasterEverythingAccepted {

    bool public withdrawDuringPostRelayedCall;
    bool public withdrawDuringPreRelayedCall;
    bool public returnInvalidErrorCode;
    bool public revertPostRelayCall;
    bool public overspendAcceptGas;
    bool public revertPreRelayCall;
    bool public greedyAcceptanceBudget;

    function setWithdrawDuringPostRelayedCall(bool val) public {
        withdrawDuringPostRelayedCall = val;
    }
    function setWithdrawDuringPreRelayedCall(bool val) public {
        withdrawDuringPreRelayedCall = val;
    }
    function setReturnInvalidErrorCode(bool val) public {
        returnInvalidErrorCode = val;
    }
    function setRevertPostRelayCall(bool val) public {
        revertPostRelayCall = val;
    }
    function setRevertPreRelayCall(bool val) public {
        revertPreRelayCall = val;
    }
    function setOverspendAcceptGas(bool val) public {
        overspendAcceptGas = val;
    }

    function setGreedyAcceptanceBudget(bool val) public {
        greedyAcceptanceBudget = val;
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    relayHubOnly
    returns (bytes memory, bool) {
        (signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);
        if (overspendAcceptGas) {
            uint i = 0;
            while (true) {
                i++;
            }
        }

        require(!returnInvalidErrorCode, "invalid code");

        if (withdrawDuringPreRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPreRelayCall) {
            revert("You asked me to revert, remember?");
        }
        return ("", trustRecipientRevert);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        if (withdrawDuringPostRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPostRelayCall) {
            revert("You asked me to revert, remember?");
        }
    }

    /// leaving withdrawal public and unprotected
    function withdrawAllBalance() public returns (uint256) {
        require(address(relayHub) != address(0), "relay hub address not set");
        uint256 balance = relayHub.balanceOf(address(this));
        relayHub.withdraw(balance, address(this));
        return balance;
    }

    IPaymaster.GasLimits private limits = super.getGasLimits();

    function getGasLimits()
    public override view
    returns (IPaymaster.GasLimits memory) {
        if (greedyAcceptanceBudget) {
            return IPaymaster.GasLimits(limits.acceptanceBudget * 9, limits.preRelayedCallGasLimit, limits.postRelayedCallGasLimit);
        }
        return limits;
    }

    bool private trustRecipientRevert;

    function setGasLimits(uint acceptanceBudget, uint preRelayedCallGasLimit, uint postRelayedCallGasLimit) public {
        limits = IPaymaster.GasLimits(
            acceptanceBudget,
            preRelayedCallGasLimit,
            postRelayedCallGasLimit
        );
    }

    function setTrustRecipientRevert(bool on) public {
        trustRecipientRevert = on;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override payable {}
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.0;

contract TestVersions {

    // stub for ContractInteractor "init" to succeed
    function stakeManager() external view returns (address) {
        return address(this);
    }

    function versionHub() external pure returns (string memory) {
        return "3.0.0";
    }
}

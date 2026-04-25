// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title MinimalAccount.sol
 * @author gnvvs-2003
 * @custom:description This is the users Smart contract wallet which interacts with EntryPoint contract for validation of UserOps object
 * @custom:description Implements basic version of Account Abstraction on Ethereum
 * @custom:interfaces Implementation of IAccount for validation function `validateUserOp` and execution of UserOps, IERC1271 for signature validation
 * @notice `validateUserOp` is invoked by EntryPoint contract before execution phase to validate the UserOps object. if the validation is successful, then only EntryPoint contract will proceed with the execution of the UserOps object
 * @notice Validation data return value == 0 => success
 */

contract MinimalAccount is IAccount {
    /// Validates the UserOp object according to the IAccount interface specification.
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        view
        override
        returns (uint256 validationData)
    {
        return 0;
    }
}

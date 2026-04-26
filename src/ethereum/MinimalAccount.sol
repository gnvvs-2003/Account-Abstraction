// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title MinimalAccount.sol
 * @author gnvvs-2003
 * @custom:description This is the users Smart contract wallet which interacts with EntryPoint contract for validation of UserOps object
 * @custom:description Implements basic version of Account Abstraction on Ethereum
 * @custom:interfaces Implementation of IAccount for validation function `validateUserOp` and execution of UserOps, IERC1271 for signature validation
 * @notice `validateUserOp` is invoked by EntryPoint contract before execution phase to validate the UserOps object. if the validation is successful, then only EntryPoint contract will proceed with the execution of the UserOps object
 * @notice Validation data return value == 0 => success
 */

contract MinimalAccount is IAccount, Ownable {
    /// IMMUTABLES
    IEntryPoint private immutable I_ENTRYPOINT;

    /// CONSTRUCTOR
    /**
     * @notice When the contract is deployed this sets the initial owner to msg.sender
     */
    constructor(address entryPoint) Ownable(msg.sender){
        I_ENTRYPOINT = IEntryPoint(entryPoint);
    }

    /// INHERITED FUNCTIONS
    /// @dev Validates the UserOp object according to the IAccount interface specification.
    /// @dev Only EntryPoint can call this function
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        view
        override
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        if(validationData != SIG_VALIDATION_SUCCESS){
            return validationData;
        }

        /**
         * OTHER VALIDATION STEPS
         * _validateNonce(userOp.nonce);
         * _payPrefund(missingAccountFunds); transferring funds from SCW or paymaster to EntryPoint 
         */
        
        return validationData;
    }

    /// INTERNAL FUNCTIONS
    /**
     * @dev Internal function for signature validation.
     * @param userOp The UserOp object to validate.
     * @param userOpHash The hash of the UserOp object from EntryPoint contract
     * @return validationData The validation data.
     * @custom:Steps
     * @custom:Step1 EIP-191 standard signatures, we will be using "personal_sign" version of EIP-191 (different from `eth_sign`) : "\x19Ethereum Signed Message:\n32"
     * @custom:Step2 Signer recovery : Using ECDSA standard to recover signer add from userOpHash and signature from the userOp : provided by EVM by `ecrecover`
     * @custom:Step3 Ownership check : Logic for validation signer address = owner()
     * @notice SIGNATURE IS VALID IF IT IS FROM """MinimalAccount""" OWNER
     */
    
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        // Hash for signature verification
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        //Recover the signer address from the signature
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        // Verify the signer is the owner
        if(signer == address(0) || signer != owner()){
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    /// MODIFIERS
    modifier requireFromEntryPoint(){
        if(msg.sender != address(I_ENTRYPOINT)){
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    /// GETTERS 
    function getEntryPoint() external view returns(address){
        return address(I_ENTRYPOINT);
    }
}

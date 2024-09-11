//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SIG_VALIDATION_FAILED} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

/**
 * @title Minimal-Account
 * @author Sohamkumar Prajapati - smrp1720@gmail.com
 * @notice This is the minimal smartContract Account for the user which will use the erc4337 account abstraction standard on ethereum
 */

contract MyAccount is Ownable, IAccount {

    /**
     * When The smart Contract is created the user's address is stored as the owner of this smart contract account
     * We can change this functionalty by just passing the user's eoa address as the actual owner also
     */
    constructor() Ownable(msg.sender) {}

    /**
     * 
     * @param userOp The stuct for userOperation containing all the fields that was sent to the altmempool nodes by user
     * @param userOpHash hash Of the userOperations sent to the alt mempool nodes by the user offchain it is the hash of all userOperation field accept the signatur field
     * @param missingAccountFunds the amount of funds that this contract or the paymaster contract will sent to entrypoint contract for the transaction execution on behalf of the user
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        validationData = _validateSignature(userOp,userOpHash);
        _payPrefund(missingAccountFunds);        
    }
    

    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual returns (uint256 validationData) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address actualSigner = ECDSA.recover(digest,userOp.signature);

        if(actualSigner != owner()){
            return SIG_VALIDATION_FAILED;
        }
        else{
            return SIG_VALIDATION_SUCCESS;
        }        
    }

    /**
     * 
     * @param missingAccountFunds Sending the required amount of funds to the EntryPoint.sol contract so that it can execute the transaction on behalf of user via this contract
     * The amount can be sent via paymaster contract too
     */
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if(missingAccountFunds != 0) {
            (bool callSuccess, ) = payable(msg.sender).call{value:missingAccountFunds, gas: type(uint256).max}("0x0");
            (callSuccess);
        }

    }
    
}
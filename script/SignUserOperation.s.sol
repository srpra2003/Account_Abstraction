//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {NonceManager} from "lib/account-abstraction/contracts/core/NonceManager.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignUserOperation is Script, NonceManager {
    function run(address account, bytes calldata _calldata, address _entryPoint)
        external
        view
        returns (PackedUserOperation memory, bytes32 userOpsHash)
    {
        return getSignedUserOpeartionStruct(account, _calldata, _entryPoint);
    }

    function getSignedUserOpeartionStruct(address _sender, bytes calldata _callData, address i_entryPoint)
        public
        view
        returns (PackedUserOperation memory, bytes32)
    {
        (PackedUserOperation memory userOp, bytes32 userOpsHash) =
            getUnsignedUserOperationStruct(_sender, _callData, i_entryPoint);

        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpsHash);

        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(vm.envUint("ANVIL_PRIVATE_KEY"), digest);
        } else {
            (v, r, s) = vm.sign(vm.envUint("SEPOLIA_PRIVATE_KEY"), digest);
        }

        bytes memory _signature = abi.encodePacked(r, s, v);
        userOp.signature = _signature;

        return (userOp, userOpsHash);
    }

    function getUnsignedUserOperationStruct(address _sender, bytes calldata _callData, address _entryPoint)
        public
        view
        returns (PackedUserOperation memory, bytes32 userOpsHash)
    {
        uint256 nonce = vm.getNonce(_sender) - 1;

        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: _sender,
            nonce: nonce,
            initCode: hex"",
            callData: _callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });

        userOpsHash = IEntryPoint(_entryPoint).getUserOpHash(userOp);

        return (userOp, userOpsHash);
    }
}

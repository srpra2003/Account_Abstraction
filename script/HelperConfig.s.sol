//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {Vm} from "forge-std/Vm.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address entryPoint; // EntryPoint contract account of the network
        address account; // the actual eoa accountof the user who wants to create his smart contract account
    }

    NetworkConfig public activeNetConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetConfig = getEthMainnetConfig();
        } else if (block.chainid == 11155111) {
            activeNetConfig = getSepoliaMainnetConfig();
        } else {
            activeNetConfig = getOrCreateAnvilNetConfig();
        }
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory netConfig = NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032, // EntryPoint Contract Address for Ethereum Mainnet v 0.7.0
            account: 0xDB005dF9b15b01A01288AdC68A1253fDb4961c1a // Address of the User=> my wallet Address hardcoded
        });

        return netConfig;
    }

    function getSepoliaMainnetConfig() public pure returns (NetworkConfig memory) { 
        NetworkConfig memory netConfig = NetworkConfig({
            entryPoint: 0x0576a174D229E3cFA37253523E645A78A0C91B57,
            account: 0xDB005dF9b15b01A01288AdC68A1253fDb4961c1a // My wallet Address hardcoded
        });

        return netConfig;
    }

    function getOrCreateAnvilNetConfig() public returns (NetworkConfig memory) {
        if (activeNetConfig.entryPoint != address(0)) {
            return activeNetConfig;
        }

        vm.startBroadcast();
        EntryPoint _entryPointContract = new EntryPoint();
        vm.stopBroadcast();

        NetworkConfig memory netConfig =
            NetworkConfig({entryPoint: address(_entryPointContract), account: vm.envAddress("ANVIL_1ST_TEST_ADDRESS")});

        return netConfig;
    }
}

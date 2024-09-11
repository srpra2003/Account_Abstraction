//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {MyAccount} from "../src/MyAccount.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMyAccount is Script {
    function run() external returns (MyAccount, HelperConfig) {
        return deployAccount();
    }

    function deployAccount() public returns (MyAccount, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address entryPoint, address account) = helperConfig.activeNetConfig();

        vm.startBroadcast(account);
        MyAccount myAccount = new MyAccount(entryPoint);
        vm.stopBroadcast();

        return (myAccount, helperConfig);
    }
}

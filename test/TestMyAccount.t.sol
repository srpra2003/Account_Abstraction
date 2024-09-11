//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {MyAccount} from "../src/MyAccount.sol";
import {DeployMyAccount} from "../script/DeployMyAccount.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestMyAccount is Test {
    MyAccount myAccount;
    DeployMyAccount deployMyAccount;
    HelperConfig helperConfig;

    address private entryPoint;
    address private account;
    uint256 private constant INITIAL_BALANCE_TO_TRANSFER = 100 ether;

    function setUp() public {
        deployMyAccount = new DeployMyAccount();
        (myAccount, helperConfig) = deployMyAccount.run();

        (entryPoint, account) = helperConfig.activeNetConfig();
    }

    function testEntryPointANdOwnerAreSetCorrectly() public view {
        address setOwner = myAccount.owner();
        address setEntryPoint = myAccount.getEntryPoint();

        assert(setOwner == account);
        assert(setEntryPoint == entryPoint);
    }

    function testInvalidUserCanNotAccessTheFunctionalityOfMinimalAccount() public {
        address fakeUser = makeAddr("Fake User");
        vm.deal(fakeUser, INITIAL_BALANCE_TO_TRANSFER);
        uint256 amountToTransfer = 10 ether;
        bytes memory funcCallData = "0x0";

        vm.startPrank(fakeUser);
        vm.expectRevert(MyAccount.Not_Allowed.selector);
        myAccount.execute(fakeUser, funcCallData, amountToTransfer); // fake user is trying to transfer the asset from the user's smart contract account to his own wallet
        vm.stopPrank();
    }

    function testOwnerOfTheMinmalAccountCanExecuteFunctionsOnHisOwn() public {
        address owner = account;
        vm.deal(owner, INITIAL_BALANCE_TO_TRANSFER);
        vm.deal(address(myAccount), INITIAL_BALANCE_TO_TRANSFER);
        address recevier = makeAddr("Reciver Address");
        uint256 recevierStartingBalabce = recevier.balance;
        uint256 amountToTransfer = 10 ether;

        console.log("recevier's starting balance : ", recevierStartingBalabce);

        vm.startPrank(owner);
        (bool callSuccess,) = payable(address(myAccount)).call{value: 20 ether}("0x0");
        (callSuccess);
        myAccount.execute(recevier, "", amountToTransfer);
        vm.stopPrank();

        uint256 receverFinalBalance = recevier.balance;
        console.log("receiver's Final Balance : ", receverFinalBalance);

        assertEq(receverFinalBalance - recevierStartingBalabce, amountToTransfer);
    }

    function testEntryPointCanPerformTransactionFromMinimalAccountOnBehalfOfUser() public {}
}

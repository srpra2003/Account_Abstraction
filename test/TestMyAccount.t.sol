//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {MyAccount} from "../src/MyAccount.sol";
import {DeployMyAccount} from "../script/DeployMyAccount.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SignUserOperation} from "../script/SignUserOperation.s.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";



contract TestMyAccount is Test {
    MyAccount myAccount;     // The actual smart contract account of user typicall "account" in our case
    DeployMyAccount deployMyAccount;
    HelperConfig helperConfig;
    SignUserOperation signUserOperation;

    address private entryPoint;
    address private account;    // The EOA of the user
    uint256 private constant INITIAL_BALANCE_TO_TRANSFER = 100 ether;

    PackedUserOperation[] userOps;

    function setUp() public {
        deployMyAccount = new DeployMyAccount();
        (myAccount, helperConfig) = deployMyAccount.run();

        (entryPoint, account) = helperConfig.activeNetConfig();
        signUserOperation = new SignUserOperation();

        vm.deal(account,INITIAL_BALANCE_TO_TRANSFER);
        vm.deal(address(myAccount),INITIAL_BALANCE_TO_TRANSFER);
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

    function testValidateUserOpWorksPerfectly() public {
        address _sender = address(myAccount);
        bytes32 _funcCalldata = hex"";
        address _recevier = makeAddr("recevier account who will get the assets user will be senting through his smart contract account");
        uint256 _amountToTransfer = 10 ether;
        bytes memory _callData = abi.encodeWithSignature("execute(address,bytes32,uint256)",_recevier,_funcCalldata,_amountToTransfer);

        (PackedUserOperation memory userOp,bytes32 userOpHash) = signUserOperation.run(_sender,_callData,entryPoint);

        address owner = account;
        vm.startPrank(owner);
        uint256 validationData = myAccount.validateUserOp(userOp,userOpHash,5);
        vm.stopPrank();

        assertEq(validationData,SIG_VALIDATION_SUCCESS);
        
    }

    function testEntryPointCanPerformTransactionFromMinimalAccountOnBehalfOfUser() public {
        address executor = makeAddr("Actual Exucutor from alt mempool node who will transact the userOp via entrypoint contract");
        vm.deal(executor, INITIAL_BALANCE_TO_TRANSFER);
        address _sender = address(myAccount);
        bytes32 _funcCalldata = hex"";
        address _recevier = makeAddr("recevier account who will get the assets user will be senting through his smart contract account");
        uint256 _amountToTransfer = 10 ether;
        bytes memory _callData = abi.encodeWithSignature("execute(address,bytes32,uint256)",_recevier,_funcCalldata,_amountToTransfer);

        (PackedUserOperation memory userOp,) = signUserOperation.run(_sender,_callData,entryPoint);
        userOps.push(userOp);

        uint256 receiverInitialBalance = _recevier.balance;

        vm.startPrank(executor);
        IEntryPoint(entryPoint).handleOps(userOps,payable(executor)); //executor will be wanting to be beneficiary
        vm.stopPrank();

        uint256 receiverFinalBalance = _recevier.balance;

        console.log(receiverInitialBalance);
        console.log(receiverFinalBalance);       
    }
}

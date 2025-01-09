// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/Test.sol";
import "forge-std/Script.sol";
import "../src/Multisig.sol";

// source .env
// forge script script/Deploy.s.sol:Deployer --rpc-url $RPC_URL --broadcast -vvvv --legacy --private-key $PRIVATE_KEY

contract Deployer is Script {

    // To avoid coverage
    function testA() public {}

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address signer1 = vm.envAddress("SIGNER_1");
        address signer2 = vm.envAddress("SIGNER_2");
        address signer3 = vm.envAddress("SIGNER_3");
        address[] memory signers = [signer1, signer2, signer3];
        uint256 signerRequirement = vm.envUint("SIGNER_REQUIREMENT";)
        vm.startBroadcast(deployerPrivateKey);
        Multisig multisig = new Multisig(signers,signerRequirement);
        console.log("Multisig address:",address(multisig));

        vm.stopBroadcast();
    }
}


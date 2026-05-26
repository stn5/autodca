// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AutoDCA} from "../src/AutoDCA.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployAutoDCA is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (AutoDCA, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();
        AutoDCA autoDca = new AutoDCA(networkConfig.usdc, networkConfig.swapRouter);
        vm.stopBroadcast();

        return (autoDca, helperConfig);
    }
}

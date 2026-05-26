// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockUSDC} from "../test/mocks/MockUSDC.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address usdc;
        address swapRouter;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        networkConfigs[BASE_MAINNET_CHAIN_ID] = getBaseConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].usdc != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,
            swapRouter: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E
        });
    }

    function getBaseConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            swapRouter: 0x2626664c2603336E57B271c5C0b26F421741e481
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.usdc != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        MockUSDC mockUsdc = new MockUSDC();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            usdc: address(mockUsdc),
            swapRouter: makeAddr("swapRouter")
        });
        return localNetworkConfig;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/extensions/HelloWormholeForwarding.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

contract HelloWormholeForwardingTest is WormholeRelayerTest {
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    HelloWormholeForwarding helloSource;
    HelloWormholeForwarding helloTarget;

    function setUpSource() public override {
        helloSource = new HelloWormholeForwarding(address(relayerSource), address(wormholeSource));
    }

    function setUpTarget() public override {
        helloTarget = new HelloWormholeForwarding(address(relayerTarget), address(wormholeTarget));
    }

    function performRegistrations() public {
        vm.selectFork(targetFork);
        helloTarget.setRegisteredSender(sourceChain, toWormholeFormat(address(helloSource)));

        vm.selectFork(sourceFork);
        helloSource.setRegisteredSender(targetChain, toWormholeFormat(address(helloTarget)));
    }

    function testGreeting() public {

        performRegistrations();

        // Front-end calculation for how much receiver value to request the greeting with
        // to ensure a confirmation is able to come back!
        vm.selectFork(targetFork);
        uint256 receiverValueForConfirmation = helloTarget.quoteConfirmation(sourceChain);
        vm.selectFork(sourceFork);
        // end front-end calculation

        uint256 cost = helloSource.quoteCrossChainGreeting(targetChain, receiverValueForConfirmation);

        vm.recordLogs();

        helloSource.sendCrossChainGreeting{value: cost}(targetChain, address(helloTarget), "Hello Wormhole!", receiverValueForConfirmation);

        performDelivery();

        vm.selectFork(targetFork);
        assertEq(helloTarget.latestGreeting(), "Hello Wormhole!");

        performDelivery();

        vm.selectFork(sourceFork);
        assertEq(helloSource.latestConfirmedSentGreeting(), "Hello Wormhole!");
    }
}
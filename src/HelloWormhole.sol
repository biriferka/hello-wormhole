// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";

contract HelloWormhole is IWormholeReceiver {
    // Event to emit when a greeting is received
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    // Constant for gas limit (can be adjusted based on needs)
    uint256 constant GAS_LIMIT = 50_000;

    // Reference to the Wormhole relayer contract
    IWormholeRelayer public immutable wormholeRelayer;

    // State variable to store the latest greeting received
    string public latestGreeting;

    // Constructor to initialize the contract with a Wormhole relayer address
    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    // Function to quote the cost of sending a cross-chain greeting
    function quoteCrossChainGreeting(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        // Get the delivery price for the target chain
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0, // No additional value needed
            GAS_LIMIT
        );
    }

    // Function to send a cross-chain greeting to a specified target address
    function sendCrossChainGreeting(
        uint16 targetChain,
        address targetAddress,
        string memory greeting
    ) public payable {
        uint256 cost = quoteCrossChainGreeting(targetChain);
        
        // Ensure that the sent value is equal to the quoted cost
        require(msg.value == cost, "Incorrect value sent");

        // Send the payload to the target chain and address
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(greeting, msg.sender), // Encoded payload with greeting and sender address
            0, // No receiver value required
            GAS_LIMIT
        );
    }

    // Function to handle the reception of Wormhole messages (greetings)
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas (not used in this contract)
        bytes32, // sender address (not used in this contract)
        uint16 sourceChain,
        bytes32 // unique identifier of the delivery (not used in this contract)
    ) public payable override {
        // Ensure that only the Wormhole relayer can call this function
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        // Decode the received payload to extract the greeting and sender address
        (string memory greeting, address sender) = abi.decode(
            payload,
            (string, address)
        );
        
        // Update the state variable with the latest greeting
        latestGreeting = greeting;

        // Emit the event with the received greeting details
        emit GreetingReceived(latestGreeting, sourceChain, sender);
    }
}

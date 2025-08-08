// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./AlphaOmegaCoin.sol";

contract BulkOperations is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    AlphaOmegaCoin public aoc;

    event BulkTransfer(address indexed sender, address[] recipients, uint256[] amounts);
    event BulkDistributionRequested(string date, uint256 count);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    function initialize(address _aoc) public initializer {
        aoc = AlphaOmegaCoin(_aoc);
        __Ownable_init();
        __Pausable_init();
    }

    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner whenNotPaused {
        require(recipients.length == amounts.length, "AOC: Mismatched arrays");
        uint256 senderBalanceAmount = aoc.balanceOf(msg.sender);
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amountWithDecimals = amounts[i];
            require(senderBalanceAmount >= amountWithDecimals, "AOC: Insufficient balance");
            senderBalanceAmount -= amountWithDecimals;
            aoc.transferFrom(msg.sender, recipients[i], amountWithDecimals);
        }
        emit BulkTransfer(msg.sender, recipients, amounts);
    }

    function bulkDistribution(string calldata date, uint256 count) external onlyOwner whenNotPaused {
        require(count > 0, "AOC: Invalid count");
        emit BulkDistributionRequested(date, count);
    }
}
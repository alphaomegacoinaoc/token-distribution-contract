// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract AOCBulkTransfer is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Address of the ERC20 token to be used for airdrops
    IERC20Upgradeable public token;

    event BulkTransferred(address[] recipients, uint256[] amounts);
    event EmergencyWithdraw(address token, uint256 amount);
    event TokenUpdated(address indexed newToken);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Initialize the contract with the token address
    function initialize(address _token) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        setToken(_token);
    }

    /**
     * @dev Sets the token address that will be used for the airdrop.
     * @param _token The address of the ERC20 token contract.
     */
    function setToken(address _token) public onlyOwner {
        require(_token != address(0), "Token address cannot be zero");
        require(_token.code.length > 0, "Token must be a contract");
        token = IERC20Upgradeable(_token);
        emit TokenUpdated(_token);
    }

    /**
     * @dev Performs a bulk airdrop of ERC20 tokens to multiple addresses.
     * @param recipients Array of addresses to receive the airdrop.
     * @param amounts Array of amounts to send to each address.
     */
    function bulkTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner nonReentrant {
        require(recipients.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransfer(recipients[i], amounts[i]);
        }
        
        emit BulkTransferred(recipients, amounts);
    }

    function emergencyWithdraw() external onlyOwner nonReentrant{
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
        emit EmergencyWithdraw(address(token), balance);
    }

    // Pause/Unpause
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./library/DateTime.sol";

contract AlphaOmegaCoin is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using DateTimeLibrary for uint;

    struct Level {
        uint256 start;
        uint256 end;
        uint256 percentage;
    }
    struct UserInfo {
        uint256 balance;
        uint256 level;
        uint256 year;
        uint256 month;
    }
    struct Status {
        uint256 ltafRemovalYear;
        uint256 ltafRemovalMonth;
        uint256 ltafInclusionYear;
        uint256 ltafInclusionMonth;
        uint256 ramsRemovalYear;
        uint256 ramsRemovalMonth;
        uint256 ramsInclusionYear;
        uint256 ramsInclusionMonth;
    }
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public excludedFromRAMS;
    mapping(address => bool) public includedInLTAF;
    mapping(uint256 => Level) public levels;
    mapping(address => UserInfo) public userInfo;
    mapping(address => Status) public userStatus;

    uint256 private _totalSupply;
    uint8 private constant DECIMAL = 18;
    string private constant NAME = "Alpha Omega Coin";
    string private constant SYMBOL = "AOC";
    uint256 public ltafPercentage;

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public txPerMonth;
    event Blacklisted(string indexed action, address indexed to, uint256 at);
    event RemovedFromBlacklist(string indexed action, address indexed to, uint256 at);
    event IncludedInRAMS(address indexed account);
    event ExcludedFromRAMS(address indexed account);
    event IncludedInLTAF(address indexed account);
    event ExcludedFromLTAF(address indexed account);
    event LtafPercentageUpdated(uint256 percentage);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
    _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __Context_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _mint(_msgSender(), (1000 * 10 ** 9 * 10 ** 18));
        ltafPercentage = 60;

        addLevels(1, 1640995200, 1704153599, 20);
        addLevels(2, 1704153600, 1767311999, 15);
        addLevels(3, 1767312000, 1830383999, 10);
        addLevels(4, 1830384000, 0, 5);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMAL;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "AOC: Exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function blacklistUser(address _address) external onlyOwner whenNotPaused {
        require(!blacklisted[_address], "AOC: Already blacklisted");
        blacklisted[_address] = true;
        emit Blacklisted("Blacklisted", _address, block.timestamp);
    }

    function removeFromBlacklist(address _address) external onlyOwner whenNotPaused {
        require(blacklisted[_address], "AOC: ! blacklisted");
        blacklisted[_address] = false;
        emit RemovedFromBlacklist("Removed", _address, block.timestamp);
}

    function includeInRAMS(address account) external onlyOwner whenNotPaused {
        require(excludedFromRAMS[account], "AOC: Already included");
        require(!includedInLTAF[account], "AOC: In LTAF");
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
        excludedFromRAMS[account] = false;
        includedInLTAF[account] = false;
        userStatus[account].ramsRemovalYear = 0;
        userStatus[account].ramsRemovalMonth = 0;
        if (userStatus[account].ltafRemovalYear != 0) {
            userStatus[account].ramsInclusionYear = year;
            userStatus[account].ramsInclusionMonth = month;
        } else {
            userStatus[account].ramsInclusionYear = 0;
            userStatus[account].ramsInclusionMonth = 0;
        }
        emit IncludedInRAMS(account);
    }

    function excludeFromRAMS(address account) external onlyOwner whenNotPaused {
        require(!excludedFromRAMS[account], "AOC: Already excluded");
        excludedFromRAMS[account] = true;
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
        userStatus[account].ramsRemovalYear = year;
        userStatus[account].ramsRemovalMonth = month;
        emit ExcludedFromRAMS(account);
    }

    function includeInLTAF(address account) external onlyOwner whenNotPaused {
        require(!includedInLTAF[account], "AOC: Already included");
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
        includedInLTAF[account] = true;
        excludedFromRAMS[account] = true;
        userStatus[account].ltafRemovalYear = 0;
        userStatus[account].ltafRemovalMonth = 0;
        if (txPerMonth[account][year][month] > 0) {
            userStatus[account].ltafInclusionYear = year;
            userStatus[account].ltafInclusionMonth = month;
        } else {
            userStatus[account].ltafInclusionYear = 0;
            userStatus[account].ltafInclusionMonth = 0;
        }
        userInfo[account].balance = _balances[account];
        userInfo[account].year = year;
        userInfo[account].month = month;
        txPerMonth[account][year][month] = 0;
        emit IncludedInLTAF(account);
    }

    function excludedFromLTAF(address account) external onlyOwner whenNotPaused {
        require(includedInLTAF[account], "AOC: Already excluded");
        includedInLTAF[account] = false;
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
        userStatus[account].ltafRemovalYear = year;
        userStatus[account].ltafRemovalMonth = month;
        emit ExcludedFromLTAF(account);
    }

    function updateLtafPercentage(uint256 percentage) external onlyOwner whenNotPaused {
        require(percentage > 0, "AOC: Invalid percentage");
        ltafPercentage = percentage;
        emit LtafPercentageUpdated(ltafPercentage);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(!blacklisted[sender] && !blacklisted[recipient], "AOC: Blacklisted");
        require(sender != address(0), "AOC: Zero sender");
        require(recipient != address(0), "AOC: Zero recipient");

        if (excludedFromRAMS[sender] && userStatus[sender].ltafRemovalYear != 0) {
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
            require(year != userStatus[sender].ltafRemovalYear || month != userStatus[sender].ltafRemovalMonth, "AOC: Ex-LTAF wait");
        }
        if (includedInLTAF[sender] && userStatus[sender].ramsRemovalYear != 0) {
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
            require(year != userStatus[sender].ramsRemovalYear || month != userStatus[sender].ramsRemovalMonth, "AOC: Ex-RAMS wait");
        }
        if (includedInLTAF[sender] && userStatus[sender].ltafInclusionYear != 0) {
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
            require(year != userStatus[sender].ltafInclusionYear || month != userStatus[sender].ltafInclusionMonth, "AOC: New LTAF wait");
        }
        if (!excludedFromRAMS[sender] && userStatus[sender].ramsInclusionYear != 0) {
       (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(block.timestamp);
            require(year != userStatus[sender].ramsInclusionYear || month != userStatus[sender].ramsInclusionMonth, "AOC: New RAMS wait");
        }

        if (includedInLTAF[sender] || !excludedFromRAMS[sender]) {
            (uint256 year, uint256 month, uint256 day) = DateTimeLibrary.timestampToDate(block.timestamp);
            if (
                day <= 1 ||
                year != userInfo[sender].year ||
                month != userInfo[sender].month ||
                userInfo[sender].level == 0
            ) {
                updateUserInfo(sender, year, month);
            }
            if (includedInLTAF[sender]) {
                require(
                    txPerMonth[sender][year][month] + amount <= ((userInfo[sender].balance * ltafPercentage) / 10 ** 2),
                    "AOC: Exceeds LTAF"
                );
                txPerMonth[sender][year][month] += amount;
            } else if (!excludedFromRAMS[sender]) {
                if (userInfo[sender].level > 0)
                    require(
                        amount <= ((userInfo[sender].balance * levels[userInfo[sender].level].percentage) / 10 ** 2),
                        "AOC: Exceeds level"
                    );
                require(
                    txPerMonth[sender][year][month] + amount <= ((userInfo[sender].balance * levels[userInfo[sender].level].percentage) / 10 ** 2),
                    "AOC: Exceeds month"
                );
                txPerMonth[sender][year][month] += amount;
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "AOC: Low balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function updateUserInfo(address account, uint256 year, uint256 month) internal {
        if (
            includedInLTAF[account] &&
            (year != userInfo[account].year || month != userInfo[account].month)
        ) {
            userInfo[account].balance = _balances[account];
            txPerMonth[account][year][month] = 0;
        } else if (!includedInLTAF[account]) {
            userInfo[account].balance = _balances[account];
        }
        userInfo[account].year = year;
        userInfo[account].month = month;
        for (uint256 i = 1; i <= 4; i++) {
            if (i == 4) {
                userInfo[account].level = i;
                break;
            }
            if (
                block.timestamp >= levels[i].start &&
                block.timestamp <= levels[i].end
            ) {
                userInfo[account].level = i;
                break;
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "AOC: Zero mint");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address account, address spender, uint256 amount) internal virtual {
        // require(owner != address(0), "AOC: Zero owner");
        // require(spender != address(0), "AOC: Zero spender");
        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function addLevels(uint256 level, uint256 startDay, uint256 endDay, uint256 percentage) internal {
        levels[level] = Level({start: startDay, end: endDay, percentage: percentage});
    }
}
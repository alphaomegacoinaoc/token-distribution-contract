// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.27;

library DateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (L * 4) / 146097;
        L = L - ((N * 146097 + 3) / 4);
        int _year = ((L + 1) * 4000) / 1461001;
        L = L - ((_year * 1461) / 4) + 31;
        int _month = (L * 80) / 2447;
        int _day = L - ((_month * 2447) / 80);
        int L2 = _month / 11;
        _month = _month + 2 - (L2 * 12);
        _year = 100 * (N - 49) + _year + L2;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}
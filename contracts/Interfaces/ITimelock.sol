// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ITimelock {
    function confirmSuccessfulReferendum(address pendingAdmin_) external;
}

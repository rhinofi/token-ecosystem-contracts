// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// This contract handles swapping to and from xDVF, DeversiFi's staking token.
contract StakedDVF is ERC20Snapshot {
    using SafeMath for uint256;
    IERC20 public dvf;

    // Define the DVF token contract
    constructor(IERC20 _dvf) ERC20("StakedDVF", "xDVF") public {
        dvf = _dvf;
    }

    // Locks DVF and mints xDVF
    function enter(uint256 _amount) external returns (bool) {
        // Gets the amount of Dvf locked in the contract
        uint256 totalDvf = dvf.balanceOf(address(this));
        // Gets the amount of xDvf in existence
        uint256 totalShares = totalSupply();
        // If no xDvf exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalDvf == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xDvf the Dvf is worth. The ratio will change overtime, as xDvf is burned/minted and Dvf deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalDvf);
            _mint(msg.sender, what);
        }
        // Lock the Dvf in the contract
        dvf.transferFrom(msg.sender, address(this), _amount);
        return true;
    }

    // Unlocks the staked + gained DVF and burns xDVF
    function leave(uint256 _share) external returns (bool) {
        // Gets the amount of xDvf in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of DVF the xDVF is worth
        uint256 what = _share.mul(dvf.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        dvf.transfer(msg.sender, what);
        return true;
    }

    function takeVoteSnapshotAtBlock() external returns (uint256 snapId) {
        snapId = _snapshot();
    }
}

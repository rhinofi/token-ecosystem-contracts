// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ERC20Permit/ECDSA.sol";
import "../ERC20Permit/EIP712.sol";
import "../ERC20Permit/IERC20Permit.sol";

// File: contracts/ERC20PermitWithSnapshot.sol


pragma solidity ^0.6.0;






// An adapted copy of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ecc66719bd7681ed4eb8bf406f89a7408569ba9b/contracts/drafts/ERC20Permit.sol

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20PermitWithSnapshot is ERC20Snapshot, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// This contract handles swapping to and from xDVF, DeversiFi's staking token.
contract StakedDVF is ERC20PermitWithSnapshot {
    using SafeMath for uint256;
    IERC20 public dvf;

    // Define the DVF token contract
    constructor(IERC20 _dvf) ERC20("StakedDVF", "xDVF") EIP712("xDVF Token", "1") public {
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

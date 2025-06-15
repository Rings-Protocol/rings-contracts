// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ITeller } from "./interfaces/ITeller.sol";
import { IVotingEscrow } from "./interfaces/IVotingEscrow.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Router Contract
/// @notice This contract serves as a router for various actions such as minting, locking, wrapping, unwrapping, and
/// transferring ERC20 tokens.
// @dev It allows the owner to set vaults, tellers, voting escrows, and wrappers for different tokens.
contract Router is Ownable2Step {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum ActionType {
        MINT,
        LOCK,
        WRAP,
        UNWRAP,
        TRANSFER_FROM_ERC20,
        TRANSFER_ERC20
    }

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Data needed to get permits
    struct PermitType {
        address token;
        address owner;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /*//////////////////////////////////////////////////////////////
                            MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address teller => address vault) public vaults;
    mapping(address token => address votingEscrow) public votingEscrows;
    mapping(address token => address wrapper) public wrappers;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) { }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mixer(PermitType[] memory paramsPermit, ActionType[] memory actions, bytes[] calldata data)
        external
        payable
    {
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i] == ActionType.MINT) {
                (address token, address teller, uint256 amount) = abi.decode(data[i], (address, address, uint256));

                address vault = vaults[teller];
                require(vault != address(0), "Vault not found");
                require(teller != address(0), "Teller not found");

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = token.balanceOf(address(this));
                }

                token.safeApprove(vault, amount);
                ITeller(teller).deposit(token, amount, 0);
            } else if (actions[i] == ActionType.LOCK) {
                (address token, uint256 amount, uint256 lockDuration, address receiver) =
                    abi.decode(data[i], (address, uint256, uint256, address));

                address votingEscrow = votingEscrows[token];
                require(votingEscrow != address(0), "Voting Escrow not found");

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = token.balanceOf(address(this));
                }

                token.safeApprove(votingEscrow, amount);
                IVotingEscrow(votingEscrow).create_lock_for(amount, lockDuration, receiver);
            } else if (actions[i] == ActionType.WRAP) {
                (address token, uint256 amount) = abi.decode(data[i], (address, uint256));

                address wrapper = wrappers[token];
                require(wrapper != address(0), "Wrapper not found");

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = token.balanceOf(address(this));
                }

                token.safeApprove(wrapper, amount);
                IERC4626(wrapper).deposit(amount, address(this));
            } else if (actions[i] == ActionType.UNWRAP) {
                (address token, uint256 amount) = abi.decode(data[i], (address, uint256));

                address wrapper = wrappers[token];
                require(wrapper != address(0), "Wrapper not found");

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = IERC4626(wrapper).balanceOf(address(this));
                }

                IERC4626(wrapper).redeem(amount, address(this), address(this));
            } else if (actions[i] == ActionType.TRANSFER_FROM_ERC20) {
                (address token, address from, address to, uint256 amount) =
                    abi.decode(data[i], (address, address, address, uint256));

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = token.balanceOf(from);
                }

                PermitType memory permit = paramsPermit[i];
                if (permit.token == token && permit.owner == from) {
                    ERC20Permit(token).permit(
                        permit.owner, address(this), amount, permit.deadline, permit.v, permit.r, permit.s
                    );
                }

                token.safeTransferFrom(from, to, amount);
            } else if (actions[i] == ActionType.TRANSFER_ERC20) {
                (address token, address to, uint256 amount) = abi.decode(data[i], (address, address, uint256));

                if (amount == type(uint256).max) {
                    // Use the maximum amount logic
                    amount = token.balanceOf(address(this));
                }

                token.safeTransfer(to, amount);
            } else {
                revert("Invalid action type");
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setVault(address teller, address vault) external onlyOwner {
        require(teller != address(0), "Teller cannot be zero address");
        require(vault != address(0), "Vault cannot be zero address");
        vaults[teller] = vault;
    }

    function setVotingEscrow(address token, address votingEscrow) external onlyOwner {
        require(token != address(0), "Token cannot be zero address");
        require(votingEscrow != address(0), "Voting Escrow cannot be zero address");
        votingEscrows[token] = votingEscrow;
    }

    function setWrapper(address token, address wrapper) external onlyOwner {
        require(token != address(0), "Token cannot be zero address");
        require(wrapper != address(0), "Wrapper cannot be zero address");
        wrappers[token] = wrapper;
    }
}

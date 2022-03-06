// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../helpers/Auth.sol";
import "../interfaces/Idex.sol";
import "./ALPHA.sol";

contract ALPHACompoundManager {
    address internal owner;
    mapping(address => bool) internal authorizations;

    event Holder(address);
    event AmountUSDC(uint256);
    event AmountTaxFree(uint256);

    /** Fees and fee breakdown */
    /**
        Total Fee: 18%
        10% Reflection
        2% Liquidity
        6% Treasury
     */
    uint256 liquidityFee = 200;
    uint256 buybackFee = 0;
    uint256 reflectionFee = 1000;
    uint256 treasuryFee = 600;
    uint256 totalFee = 1800;
    uint256 feeDenominator = 10000;

    address public ALPHANodes = 0x325a98F258a5732c7b06555603F6aF5BC1C17F0a;
    address public USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public WAVAX= 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public pair = 0x889F58fcBFB1ae8b846e2fB27b4d608507e0A2CD;
    address public routerAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    IDEXRouter public router; 

    constructor() {
        router = IDEXRouter(routerAddress);
        owner = msg.sender;
        authorizations[msg.sender] = true;
    }

    /**
    * Set fee function for this contract, to enable syncronization with the parent token,
    * for when fees are reduced in the future.
     */
    function setFee(
        uint256 _liquidityFee,
        uint256 _buybackFee,
        uint256 _reflectionFee,
        uint256 _treasuryFee,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        treasuryFee = _treasuryFee;
        totalFee = _liquidityFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function compoundDividend() external {
        emit Holder(msg.sender);
        uint256 before = IBEP20(USDC).balanceOf(msg.sender); //Gets the current balance of USDC
        
        ALPHA(payable(ALPHANodes))
            .transfer(msg.sender, 1); //Workaround to claim dividend contractually.
        
        uint256 available = IBEP20(USDC).balanceOf(msg.sender) - before; //Gets the new balance of USDC after dividend payout, but subtracts any previously held USDC.
        
        IBEP20(USDC)
            .transferFrom(msg.sender, address(this), available);

        address[] memory path = new address[](3); //Create the path for the swap. USDC -> WAVAX -> FTMP
        path[0] = USDC;
        path[1] = WAVAX;
        path[2] = ALPHANodes;

        IBEP20(USDC).approve(routerAddress, available); //Approve the swap.
     
        emit AmountUSDC(available);

        /**
        * Temporarily set fees to zero for the compounding bonus.
         */
        ALPHA(payable(ALPHANodes))
            .setFees(
                0,
                0,
                0,
                0,
                feeDenominator
            );

        /**
        * Making the swap, tax free.
         */
        router
          .swapExactTokensForTokensSupportingFeeOnTransferTokens( //Performs the swap, sending proceeds to the user.
              available,
              0,
              path,
              address(this),
              block.timestamp
          );
        

        /**
        * Amount of ALPHA swapped, leaving one on the contract for the next user.
         */
        uint256 taxFreeAlphaAmount = ALPHA(payable(ALPHANodes)).balanceOf(address(this)) - 1; // send all except for 1, for the next user

        emit AmountTaxFree(taxFreeAlphaAmount);
        
        /**
        * Sending the tax free ALPHA back to the user.
         */
        ALPHA(payable(ALPHANodes))
            .transfer(
                msg.sender, 
                taxFreeAlphaAmount
            );
        
        
        /**
        * Resetting the fees back to their normal amount.
         */
        ALPHA(payable(ALPHANodes))
            .setFees(
                liquidityFee,
                buybackFee,
                reflectionFee,
                treasuryFee,
                feeDenominator
            );
    }

     /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    } 

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }   

}
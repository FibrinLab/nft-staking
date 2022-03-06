// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ALPHA.sol";


contract ALPHAPrinter {
    
    event Log(string message);
    event Amount(uint256 amount);
    event Token(address token);

    address public ALPHANodes = 0x325a98F258a5732c7b06555603F6aF5BC1C17F0a;
    address public USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public pair = 0x889F58fcBFB1ae8b846e2fB27b4d608507e0A2CD;
    address public routerAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    IDEXRouter public router;

    constructor() {
        router = IDEXRouter(routerAddress);
    }

    function printToken(address tokenToPrint) external {
        
        emit Token(tokenToPrint);
        
        uint256 before = IBEP20(USDC).balanceOf(msg.sender); //Gets the current balance of USDC      
        
        emit Log("Amount in wallet currently, before dividend collection: ");
        emit Amount(before);
        
        ALPHA(payable(ALPHANodes)).transfer(msg.sender, 1); //Workaround to claim dividend contractually triggered by a single with a single wei transfer.
        uint256 available = IBEP20(USDC).balanceOf(msg.sender) - before; //Gets the new balance of USDC after dividend payout, but subtracts any previously held USDC.
        IBEP20(USDC).transferFrom(msg.sender, address(this), available); // move USDC back to this contract from sender for swap to desired token

        emit Amount(available);

        address[] memory path = new address[](3); //Create the path for the swap. USDC -> WAVAX -> Wanted Token
        path[0] = USDC;
        path[1] = WAVAX;
        path[2] = tokenToPrint;

        IBEP20(USDC).approve(routerAddress, available); //Approve the swap, only the amount available.        

        emit Log("approved USDC on router spend for exact amount: ");
        emit Amount(available);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens( //Performs the swap, sending proceeds to the user.
            available,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function printNative() external {
        uint256 before = IBEP20(USDC).balanceOf(msg.sender); //Gets the current balance of USDC
        ALPHA(payable(ALPHANodes)).transfer(msg.sender, 1); //Workaround to claim dividend contractually.
        uint256 available = IBEP20(USDC).balanceOf(msg.sender) - before; //Gets the new balance of USDC after dividend payout, but subtracts any previously held USDC.
        IBEP20(USDC).transferFrom(msg.sender, address(this), available);

        address[] memory path = new address[](2); //Create the path for the swap. USDC -> WAVAX
        path[0] = USDC;
        path[1] = WAVAX;

        IBEP20(USDC).approve(routerAddress, available); //Approve the swap.

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens( //Performs the swap, sending proceeds to the user.
            available,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }
}

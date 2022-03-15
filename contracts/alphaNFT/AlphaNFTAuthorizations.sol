// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AlphaNFTAuthorizations {
    address public _marketplaceAddress;

    address public powerManager;
    address public tokenMinter;
    address public attributeManager;
    address public superAdmin;
    
    /**
    * Modifiers
     */    

    modifier powerControlOnly() {
        require(msg.sender == powerManager, "Must be the power manager");
        _;
    }

    modifier attributeManagerOnly() {
        require(msg.sender == attributeManager, "Must be the power manager");
        _;
    }    

    modifier minterOnly() {
        require(msg.sender == tokenMinter, "Must be token minter");
        _;
    }

    modifier superAdminOnly() {
        require(msg.sender == superAdmin, "Must be super admin");
        _;
    }

    modifier marketPlaceOnly() {
        require(msg.sender == _marketplaceAddress, "Must be marketplace");
        _;
    }
}
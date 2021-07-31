// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName,
        address _settlor, 
        address _beneficiary,
        address _trustee
    ) public {
        DTRUST newDTRUST = new DTRUST(
            _contractName,
            _contractSymbol,
            _newuri,
            payable(msg.sender),
            payable(_settlor),
            _beneficiary, 
            payable(_trustee)
        );
        deployedDTRUSTs.push(newDTRUST);
        
    }

    function getDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}

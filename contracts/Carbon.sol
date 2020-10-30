// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

contract Carbon {
    bytes32 public constant CARBON_STORAGE_POSITION = keccak256("carbon.main");
    
    event ImplementationSet(bytes4 indexed functionSig, address indexed implementation);

    struct Storage {
        address owner;
        mapping(bytes4 => address) implementations;
    }

    function initialize() external {
        // set owner
        require(loadStorage().owner == address(0));
        loadStorage().owner = msg.sender;
    }

    function setImplementations(bytes4[] memory _functionSigs, address[] memory _implementations) external {
        Storage storage carbonStorage = loadStorage();
        require(msg.sender == carbonStorage.owner, "NOT_OWNER");

        require(_functionSigs.length == _implementations.length, "ARRAY_LENGTH_MISMATCH");

        for(uint256 i = 0; i < _functionSigs.length; i ++) {
            carbonStorage.implementations[_functionSigs[i]] = _implementations[i];
            emit ImplementationSet(_functionSigs[i], _implementations[i]);
        }
    }

    function loadStorage() internal pure returns (Storage storage cs) {
        bytes32 position = CARBON_STORAGE_POSITION;
        assembly {
         cs.slot := position
        }
    }


    fallback() external payable {
        address implementation = loadStorage().implementations[msg.sig];
        require(implementation != address(0), "Carbon: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

}
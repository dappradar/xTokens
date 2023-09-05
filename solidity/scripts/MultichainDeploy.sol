// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {console} from 'forge-std/console.sol';
import {Test} from 'forge-std/Test.sol';
import {XERC20Factory, IXERC20Factory} from 'contracts/XERC20Factory.sol';
import {Script} from 'forge-std/Script.sol';
import {ScriptingLibrary} from './ScriptingLibrary/ScriptingLibrary.sol';

contract MultichainDeploy is Script, ScriptingLibrary {
  uint256 public deployer = vm.envUint('DEPLOYER_PRIVATE_KEY');
  // NOTE: CHANGEABLE ?
  address constant CREATE2 = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
  string[] public chains = ['MUMBAI_RPC'];

  function run() public {
    address[] memory factories = new address[](chains.length);

    for (uint256 i; i < chains.length; i++) {
      vm.createSelectFork(vm.rpcUrl(vm.envString(chains[i])));
      vm.startBroadcast(deployer);

      address deployedContractAddress = address(new XERC20Factory());

      vm.stopBroadcast();
      console.log(chains[i], 'factory deployed to:', address(deployedContractAddress));
      factories[i] = deployedContractAddress;
    }

    if (chains.length > 1) {
      for (uint256 i = 1; i < chains.length; i++) {
        vm.assume(factories[i - 1] == factories[i]);
        vm.assume(
          keccak256(factories[i - 1].code) == keccak256(factories[i].code)
            && keccak256(factories[i - 1].code) == keccak256(type(XERC20Factory).runtimeCode)
        );
      }
    }

    string memory path = './solidity/scripts/ScriptingLibrary/FactoryAddress.txt';
    vm.writeFile(path, addressToString(factories[0]));
  }
}

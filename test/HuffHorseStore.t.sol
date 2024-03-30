// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { HorseStoreTest, HorseStore } from "./HorseStore.t.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

contract HuffHorseStoreTest is HorseStoreTest {
  string public constant c_horseStoreLocation = "huff/HorseStore";

  function setUp() public override {
    horseStore = HorseStore(
      HuffDeployer.config().with_args(bytes.concat(abi.encode(NFT_NAME), abi.encode(NFT_SYMBOL))).deploy(
        c_horseStoreLocation
      )
    );
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/* 
 * @title IHorseStore
 */
interface IHorseStore is IERC721Enumerable {
  error HorseStoreForbiddenError();

  function mintHorse() external;
  function feedHorse(uint256 horseId) external;
  function isHappyHorse(uint256 horseId) external view returns (bool);
}

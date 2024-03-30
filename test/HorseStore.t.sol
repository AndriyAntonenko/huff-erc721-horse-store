// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IHorseStore } from "../src/solc/IHorseStore.sol";
import { HorseStore } from "../src/solc/HorseStore.sol";
import { Test, console2 } from "forge-std/Test.sol";

abstract contract HorseStoreTest is Test {
  using console2 for *;

  HorseStore horseStore;
  address user = makeAddr("user");
  string public constant NFT_NAME = "HorseStore";
  string public constant NFT_SYMBOL = "HS";

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setUp() public virtual {
    horseStore = new HorseStore();
  }

  function testName() public view {
    string memory name = horseStore.name();
    assertEq(name, NFT_NAME);
  }

  function testSymbol() public view {
    string memory symbol = horseStore.symbol();
    assertEq(symbol, NFT_SYMBOL);
  }

  function testMintingHorseAssignsOwner(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();
    assertEq(horseStore.ownerOf(horseId), randomOwner);
  }

  function testMintingHorseIncreasesBalance(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 balanceBefore = horseStore.balanceOf(randomOwner);
    vm.prank(randomOwner);
    horseStore.mintHorse();
    uint256 balanceAfter = horseStore.balanceOf(randomOwner);
    assertEq(balanceAfter, balanceBefore + 1);
  }

  function testMintingHorseEmitEvent(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    vm.expectEmit(true, true, false, true);
    emit Transfer(address(0), randomOwner, horseStore.totalSupply());
    vm.prank(randomOwner);
    horseStore.mintHorse();
  }

  function testFeedingHorseOnlyOwnerCanFeed(address randomOwner, address anotherUser) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();
    vm.prank(anotherUser);
    vm.expectRevert(IHorseStore.HorseStoreForbiddenError.selector);
    horseStore.feedHorse(horseId);
  }

  function testFeedingHorseUpdatesTimestamps(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 horseId = horseStore.totalSupply();
    vm.warp(10);
    vm.roll(10);

    vm.startPrank(randomOwner);
    horseStore.mintHorse();
    uint256 lastFedTimeStamp = block.timestamp;
    horseStore.feedHorse(horseId);
    vm.stopPrank();
    assertEq(horseStore.horseIdToFedTimeStamp(horseId), lastFedTimeStamp);
  }

  function testFeedingMakesHappyHorse(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 horseId = horseStore.totalSupply();
    vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
    vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
    vm.startPrank(randomOwner);
    horseStore.mintHorse();
    horseStore.feedHorse(horseId);
    vm.stopPrank();
    assertEq(horseStore.isHappyHorse(horseId), true);
  }

  function testNotFeedingMakesUnhappyHorse(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 horseId = horseStore.totalSupply();
    vm.warp(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
    vm.roll(horseStore.HORSE_HAPPY_IF_FED_WITHIN());
    vm.prank(randomOwner);
    horseStore.mintHorse();
    assertEq(horseStore.isHappyHorse(horseId), false);
  }

  function testHorseIsHappyIfFedWithinPast24Hours(uint256 checkAt, address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    uint256 fedAt = horseStore.HORSE_HAPPY_IF_FED_WITHIN();
    checkAt = bound(checkAt, fedAt + 1 seconds, fedAt + horseStore.HORSE_HAPPY_IF_FED_WITHIN() - 1 seconds);
    vm.warp(fedAt);
    vm.startPrank(randomOwner);
    uint256 horseId = horseStore.totalSupply();
    horseStore.mintHorse();
    horseStore.feedHorse(horseId);
    vm.stopPrank();

    vm.warp(checkAt);
    assertEq(horseStore.isHappyHorse(horseId), true);
  }

  function testErc721Approval(address randomOwner, address randomSpender) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();
    vm.prank(randomOwner);
    horseStore.approve(randomSpender, horseId);
    assertEq(horseStore.getApproved(horseId), randomSpender);
  }

  function testErc721ApprovalEmitEvent(address randomOwner, address randomSpender) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.expectEmit(true, true, false, true);
    emit Approval(randomOwner, randomSpender, horseId);
    vm.prank(randomOwner);
    horseStore.approve(randomSpender, horseId);
  }

  function testErc721SetApprovalForAll(address randomOwner, address randomOperator) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomOperator != address(0));
    vm.assume(!_isContract(randomOperator));

    vm.prank(randomOwner);
    horseStore.setApprovalForAll(randomOperator, true);
    assertEq(horseStore.isApprovedForAll(randomOwner, randomOperator), true);
  }

  function testErc721SetApprovalForAllEmitsEvent(address randomOwner, address randomOperator) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomOperator != address(0));
    vm.assume(!_isContract(randomOperator));

    vm.startPrank(randomOwner);
    vm.expectEmit(true, true, false, true);
    emit ApprovalForAll(randomOwner, randomOperator, true);
    horseStore.setApprovalForAll(randomOperator, true);
    vm.stopPrank();
  }

  function testErc721TransferFromBalanesChanged(
    address randomOwner,
    address randomSpender,
    address randomReceiver
  )
    public
  {
    vm.assume(randomOwner != randomReceiver && randomOwner != randomSpender && randomSpender != randomReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));
    vm.assume(randomReceiver != address(0));
    vm.assume(!_isContract(randomReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.prank(randomOwner);
    horseStore.approve(randomSpender, horseId);

    uint256 prevReceiverBalance = horseStore.balanceOf(randomReceiver);
    uint256 prevOwnerBalance = horseStore.balanceOf(randomOwner);

    vm.prank(randomSpender);
    horseStore.transferFrom(randomOwner, randomReceiver, horseId);

    uint256 newReceiverBalance = horseStore.balanceOf(randomReceiver);
    uint256 newOwnerBalance = horseStore.balanceOf(randomOwner);

    assertEq(prevOwnerBalance - newOwnerBalance, 1);
    assertEq(newReceiverBalance - prevReceiverBalance, 1);
  }

  function testErc721TransferFromOwnerChanged(
    address randomOwner,
    address randomSpender,
    address randomReceiver
  )
    public
  {
    vm.assume(randomOwner != randomReceiver && randomOwner != randomSpender && randomSpender != randomReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));
    vm.assume(randomReceiver != address(0));
    vm.assume(!_isContract(randomReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.prank(randomOwner);
    horseStore.approve(randomSpender, horseId);
    vm.prank(randomSpender);
    horseStore.transferFrom(randomOwner, randomReceiver, horseId);
    assertEq(horseStore.ownerOf(horseId), randomReceiver);
  }

  function testErc721TransferFromEmitsEvent(address randomOwner, address randomSpender, address randomReceiver) public {
    vm.assume(randomOwner != randomReceiver && randomOwner != randomSpender && randomSpender != randomReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));
    vm.assume(randomReceiver != address(0));
    vm.assume(!_isContract(randomReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.prank(randomOwner);
    horseStore.approve(randomSpender, horseId);

    vm.expectEmit(true, true, false, true);
    emit Transfer(randomOwner, randomReceiver, horseId);
    vm.prank(randomSpender);
    horseStore.transferFrom(randomOwner, randomReceiver, horseId);
  }

  function testErc721TransferFromWorksWithApprovalForAll(
    address randomOwner,
    address randomSpender,
    address randomReceiver
  )
    public
  {
    vm.assume(randomOwner != randomReceiver && randomOwner != randomSpender && randomSpender != randomReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomSpender != address(0));
    vm.assume(!_isContract(randomSpender));
    vm.assume(randomReceiver != address(0));
    vm.assume(!_isContract(randomReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.prank(randomOwner);
    horseStore.setApprovalForAll(randomSpender, true);

    vm.prank(randomSpender);
    horseStore.transferFrom(randomOwner, randomReceiver, horseId);
    assertEq(horseStore.ownerOf(horseId), randomReceiver);
  }

  function testErc721TransferFromWorksFromOwner(address randomOwner, address randomReceiver) public {
    vm.assume(randomOwner != randomReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomReceiver != address(0));
    vm.assume(!_isContract(randomReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.prank(randomOwner);
    horseStore.transferFrom(randomOwner, randomReceiver, horseId);
    assertEq(horseStore.ownerOf(horseId), randomReceiver);
  }

  function testErc721TransferFromRevertWithoutApproval(
    address randomOwner,
    address randomeSpender,
    address randomeReceiver
  )
    public
  {
    vm.assume(randomOwner != randomeReceiver && randomOwner != randomeSpender && randomeSpender != randomeReceiver);
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));
    vm.assume(randomeSpender != address(0));
    vm.assume(!_isContract(randomeSpender));
    vm.assume(randomeReceiver != address(0));
    vm.assume(!_isContract(randomeReceiver));

    uint256 horseId = horseStore.totalSupply();
    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.expectRevert();
    vm.prank(randomeSpender);
    horseStore.transferFrom(randomOwner, randomeReceiver, horseId);
  }

  function testErc721EnumerableTokenOfOwnerByIndex(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    vm.startPrank(randomOwner);
    horseStore.mintHorse(); // token id 0, index 0
    horseStore.mintHorse(); // token id 1, index 1
    horseStore.mintHorse(); // token id 2, index 2
    vm.stopPrank();

    assertEq(horseStore.tokenOfOwnerByIndex(randomOwner, 0), 0);
    assertEq(horseStore.tokenOfOwnerByIndex(randomOwner, 1), 1);
    assertEq(horseStore.tokenOfOwnerByIndex(randomOwner, 2), 2);
  }

  function testErc721EnumerableTokenOfOwnerByIndexRevertsOutOfBounds(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.expectRevert();
    horseStore.tokenOfOwnerByIndex(randomOwner, 1);
  }

  function testErc721EnumerableTokenByIndex(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    vm.startPrank(randomOwner);
    horseStore.mintHorse(); // token id 0, index 0
    horseStore.mintHorse(); // token id 1, index 1
    horseStore.mintHorse(); // token id 2, index 2
    vm.stopPrank();

    assertEq(horseStore.tokenByIndex(0), 0);
    assertEq(horseStore.tokenByIndex(1), 1);
    assertEq(horseStore.tokenByIndex(2), 2);
  }

  function testErc721EnumerableTokenByIndexRevertsOutOfBounds(address randomOwner) public {
    vm.assume(randomOwner != address(0));
    vm.assume(!_isContract(randomOwner));

    vm.prank(randomOwner);
    horseStore.mintHorse();

    vm.expectRevert();
    horseStore.tokenByIndex(1);
  }

  /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
  // Borrowed from an Old Openzeppelin codebase
  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

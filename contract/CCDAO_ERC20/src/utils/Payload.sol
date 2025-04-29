// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
@dev 检测payload共通
 */
contract Payload {
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length >= size + 4, "payload size invaild");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract GovModule {

      constructor(address timelock_, address executive_) public {
      }

      function initiateReplaceAdminReferendum(address pendingAdmin_) public {
          referendum.start(pendingAdmin_);
          emit NewReferendum()
      }


}

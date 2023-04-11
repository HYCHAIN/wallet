// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ISessionCalls.sol";
import "../Calls/Calls.sol";
import "./SessionCallsStorage.sol";

contract SessionCalls is ISessionCalls, Calls {
  bytes4 private constant MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS = 0x0;

  constructor() {
    // TODO: need to move this intended implementation to a constant.. won't work with proxy wallet
    SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[0x39509351] = true; // ERC20: increaseAllowance(address,uint256)
    SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[0xa457c2d7] = true; // ERC20: decreaseAllowance(address,uint256)
    SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[0x095ea7b3] = true; // ERC20 & ERC721: approve(address,uint256)
    SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[0xa22cb465] = true; // ERC721 & ERC1155: setApprovalForAll(address,bool)
  }

  // start session
  function startSession(
    address _caller,
    SessionCallsStructs.SessionRequest calldata _sessionRequest,
    uint256 _expiresAt,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_caller, _sessionRequest, _expiresAt, _nonce, block.chainid)), _signatures)
  {
    SessionCallsStructs.Session storage session = SessionCallsStorage.layout().sessions
      [_caller]
      [SessionCallsStorage.layout().nextSessionId[_caller]];

    session.expiresAt = _expiresAt;

    // native token allowance
    session.allowances[address(0)][0] = _sessionRequest.nativeAllowance;
    
    for (uint256 i = 0; i < _sessionRequest.contractFunctionSelectors.length; i++) {
      for (uint256 j = 0; j < _sessionRequest.contractFunctionSelectors[i].functionSelectors.length; j++) {
        session.contractFunctionSelectors
          [_sessionRequest.contractFunctionSelectors[i].aContract]
          [_sessionRequest.contractFunctionSelectors[i].functionSelectors[j]] = true;
      }
    }

    for (uint256 i = 0; i < _sessionRequest.erc20Allowances.length; i++) {
      session.allowances[_sessionRequest.erc20Allowances[i].erc20Contract][0] = _sessionRequest.erc20Allowances[i].allowance;
    }

    for (uint256 i = 0; i < _sessionRequest.erc721Allowances.length; i++) {
      if (_sessionRequest.erc721Allowances[i].approveAll) {
        session.approveAlls[_sessionRequest.erc721Allowances[i].erc721Contract] = true;
      } else {
        for (uint256 j = 0; j < _sessionRequest.erc721Allowances[i].tokenIds.length; j++) {
          session.allowances
            [_sessionRequest.erc721Allowances[i].erc721Contract]
            [_sessionRequest.erc721Allowances[i].tokenIds[j]] = 1;
        }
      }
    }

    for (uint256 i = 0; i < _sessionRequest.erc1155Allowances.length; i++) {
      if (_sessionRequest.erc1155Allowances[i].approveAll) {
        session.approveAlls[_sessionRequest.erc1155Allowances[i].erc1155Contract] = true;
      } else {
        for (uint256 j = 0; j < _sessionRequest.erc1155Allowances[i].tokenIds.length; j++) {
          session.allowances
            [_sessionRequest.erc1155Allowances[i].erc1155Contract]
            [_sessionRequest.erc1155Allowances[i].tokenIds[j]] = _sessionRequest.erc1155Allowances[i].allowances[j];
        }
      }
    }

    SessionCallsStorage.layout().nextSessionId[_caller]++;
  }

  // end session
  function endSession() external {
    endSessionForCaller(msg.sender);
  }

  function endSessionForCaller(
    address _caller,
    uint256 _nonce,
    bytes[] calldata _signatures
  )
    external
    meetsControllersThreshold(keccak256(abi.encode(_caller, _nonce, block.chainid)), _signatures)
  {
    endSessionForCaller(_caller);
  }

  function endSessionForCaller(address _caller) private {
    require(SessionCallsStorage.layout().nextSessionId[_caller] > 0, "No sessions for sender");
    SessionCallsStorage.layout().sessions
      [_caller]
      [SessionCallsStorage.layout().nextSessionId[_caller] - 1].expiresAt = 0;
  }

  // make session call
  function sessionCall(
    CallsStructs.CallRequest calldata _callRequest
  )
    public
    returns (bytes memory)
  {
    require(SessionCallsStorage.layout().nextSessionId[msg.sender] > 0, "No sessions for sender");
    SessionCallsStructs.Session storage session = SessionCallsStorage.layout().sessions
      [msg.sender]
      [SessionCallsStorage.layout().nextSessionId[msg.sender] - 1];

    require(session.expiresAt > block.timestamp, "Session has ended or expired");
    require(_callRequest.value < session.allowances[address(0)][0], "Value greater than allowance");

    // check if any function is approved for the target
    bytes4 functionSelector = bytes4(_callRequest.data);
    bool isApproved = session.contractFunctionSelectors[_callRequest.target][functionSelector];
         isApproved = isApproved || (
           session.contractFunctionSelectors[_callRequest.target][MAGIC_CONTRACT_ALL_FUNCTION_SELECTORS] &&
           !SessionCallsStorage.layout().RESTRICTED_FUNCTION_SELECTORS[functionSelector] // require explicit approval for restricted functions when default all approved
         );    
    require(isApproved, "Call target or function not approved for this session.");


    // TODO: Working through handling allowance tracking & deductions from standard ERC func call & non-standard for 20/721/1155...
    // erc20
    //uint256 balanceOf = IERC20(_callRequest.target).balanceOf(address(this));

    // maybe...
    // native token: check address balance before & after call, compare delta to remaining allowance
    // erc20: check address balanceOf before & after call, compare delta to remaining allowance
    // erc721: only support allowance tracking for standard erc721 functions? Track ownership of id(s) before/after call of a standard func since we know what the id's involved are?
    // erc1155: only support allowance tracking for standard erc1155 functions? Track balance of id(s) before/after call of a standard func since we know what the id's involved are?

    bytes memory result = _call(_callRequest);

    // check deductions against allowances.

    // deduct from value allowance.
    session.allowances[address(0)][0] -= _callRequest.value;

    return result;
  }

  function sessionMultiCall(
    CallsStructs.CallRequest[] calldata _callRequests
  )
    external
    returns (bytes[] memory)
  {
    bytes[] memory results = new bytes[](_callRequests.length);

    for (uint256 i = 0; i < _callRequests.length; i++) {
      results[i] = sessionCall(_callRequests[i]);
    }

    return results;
  }
}
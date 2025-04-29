// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./math/SafeMath.sol";
import "./utils/AddressUtils.sol";
import "./utils/Payload.sol";
import "./owner/Administrative.sol";
import "./interface/IERC223.sol";
import "./interface/IERC20Extended.sol";
import "./interface/IBlacklist.sol";
import "./interface/IERC223Recipient.sol";

/**
 * ERC 20 token
 * erc20 factory contract, pass by name, total supply, decimals, minable parameters when create
 * fixed total supply when minable is false
 * if minable is true, totalSupply is up limit when create, and totalSupply function return real amount.
 * support erc223 standard, avoid risk of approve function, but need other contract support
 * https://github.com/ethereum/EIPs/issues/20
 * https://github.com/ethereum/EIPs/issues/223
 */
contract ERC20Factory is Administrative, IERC20Extended, IERC223, IBlacklist, Payload {
  using SafeMath for uint256;
  using AddressUtils for address;

  mapping(address => uint256) _balances;

  mapping(address => mapping(address => uint256)) _allowed;

  mapping (address => bool) _isBlackListed;

  bool _minable;
  uint8 private _decimals;
  uint256 private _totalSupply;
  uint256 private _maxSupply;
  string private _name;
  string private _symbol;

  //constructor
  constructor(
    string memory __name,
    string memory __symbol,
    uint8 __decimals,
    uint256 __totalSupply,
    bool __minable
  ) Administrative() {
    _name = __name;
    _symbol = __symbol;
    _decimals = __decimals;
    _maxSupply = __totalSupply * 10**uint256(__decimals);
    _minable = __minable;

    if (_minable) {
      _totalSupply = 0;
    } else {
      // all token send to owner when create
      _totalSupply = _maxSupply;
      _balances[owner()] = _totalSupply;
      emit Transfer(address(0), owner(), _totalSupply);
    }
  }

  function name() public override view returns (string memory) {
    return _name;
  }

  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  /**
  NOTE: Not all erc20 followed uint8, for example, USDT is uint256, conversion is required
  */
  function decimals() public override view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _who) public override view returns (uint256) {
    return _balances[_who];
  }

  function allowance(address _owner, address _spender)
    public
    override view
    returns (uint256)
  {
    return _allowed[_owner][_spender];
  }

  function standard() public override pure returns (string memory) {
    return "erc223";
  }

  function approve(address _spender, uint256 _value)
    public override 
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    // Check the set allowable quantity to prevent re-entry and modification
    require(
      (_value == 0) || (_allowed[msg.sender][_spender] == 0),
      "check value not equal zero"
    );

    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal {
    require(!to.isZeroAddress(), "can not send to zero account");
    require(value <= _maxSupply, "More than total supply");
    require(_balances[from] >= value, "Not enough value");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value);
  }

  function transfer(address _to, uint256 _value)
    public override
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  // erc223, allow transfer with data
  function transfer(address _to, uint256 _value, bytes calldata _data) 
    public override
    returns (bool)
  {
    _transfer(msg.sender, _to, _value);

    if(_to.isContract()) {
      IERC223Recipient(_to).tokenReceived(msg.sender, _value, _data);
    }

    emit TransferData(_data);

    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override onlyPayloadSize(3 * 32) returns (bool) {
    require(_allowed[_from][msg.sender] >= _value, "Not enough value");

    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);

    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue)
    public override 
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    require(!_spender.isZeroAddress(), "can not send to zero account");

    _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].add(
      _addedValue
    );
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

    return true;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue)
    public override 
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    require(!_spender.isZeroAddress(), "can not send to zero account");

    _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].sub(
      _subtractedValue
    );
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

    return true;
  }

  function mint(address account, uint256 value)
    public override 
    onlyPrivileged
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    require(!account.isZeroAddress(), "can not send to zero account");
    require(_minable, "minable must be true");
    require(_totalSupply.add(value) <= _maxSupply, "More than total supply");

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);

    emit Mint(account, value);
    emit Transfer(address(0), account, value);

    return true;
  }

  function burn(address account, uint256 value)
    public override 
    onlyPrivileged
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    require(!account.isZeroAddress(), "can not send to zero account");
    require(_minable, "minable must be true");
    require(_totalSupply >= value, "More than total supply");

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);

    emit Burn(account, value);
    emit Transfer(account, address(0), value);

    return true;
  }

  // blacklist related
  function getBlackListStatus(address _maker) public override view returns (bool) {
    return _isBlackListed[_maker];
  }

  function addBlackList (address _evilUser) public override onlyPrivileged {
    _isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList (address _clearedUser) public override onlyPrivileged {
    _isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  // fallback function
  fallback() external {
    require(false, "never receive fund.");
  }

  // only owner can kill
  // function kill() public {
  //   if (msg.sender == owner()) selfdestruct(payable(msg.sender));
  // }
}

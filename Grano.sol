pragma solidity ^0.5.0;

import "OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";

contract Grano is ERC20, ERC20Detailed, Ownable {
    
    mapping (address => bool) private faucetAddress;
    uint256 private faucetAmount;
    uint32 private faucetTotalAddresses;
    
    struct Record {
		uint256 tokens_amount; 
		uint256 burn_date;   
		uint256 lock_period; 
		bool minted; 
	}
	
	mapping (address => Record[]) private user;
	
	event Burn(address indexed _user, uint256 indexed _record, uint256 tokens_amount, uint256 burn_date, uint256 lock_period);
	event Mint(address indexed _user, uint256 indexed _record, uint256 tokens_amount, uint256 mint_date);
	event Faucet(address indexed _user, uint256 tokens_amount, uint256 faucet_date);
	
	constructor (string memory _name, string memory _symbol, uint8 _decimals, uint32 _initial_supply) public ERC20Detailed(_name, _symbol, _decimals) {
	    faucetAmount = (_initial_supply/_initial_supply) * (10 ** 17);
        _mint(_msgSender(), _initial_supply * (10 ** uint256(decimals())));
    }

    function burn(uint256 _amount, uint256 _period) external  returns (bool) {
        require(_amount > 0, "The amount should be greater than zero.");
        require(_period > 0, "The period should not be less than 1 day.");
        require(balanceOf(_msgSender()) >= _amount, "Your balance does not have enough tokens.");
        user[_msgSender()].push(Record(_amount,now,_period,false));
        _burn(_msgSender(), _amount);
        emit Burn(_msgSender(), user[_msgSender()].length.sub(1), _amount, now, _period);
    }
    
    function mint(uint256 _record) external returns (bool) {
        require(_record  >= 0  && _record < user[_msgSender()].length, "Record does not exist.");
        require(!user[_msgSender()][_record].minted, "Record already minted.");
        require((user[_msgSender()][_record].burn_date.add(user[_msgSender()][_record].lock_period.mul(86400))) <= now, "Record cannot be minted before the lock period ends.");
        user[_msgSender()][_record].minted = true;
        uint256 period = user[_msgSender()][_record].lock_period ** 2;
        uint256 multiplier = period.div(10000);
        uint256 compensation = multiplier.mul(user[_msgSender()][_record].tokens_amount);
        uint256 amount = compensation.add(user[_msgSender()][_record].tokens_amount);
        _mint(_msgSender(), amount);
        emit Mint(_msgSender(), _record, amount, now);
    }
    
    function getRecordsCount(address _user) public view returns (uint256) {
        return user[_user].length;
    }
    
    function getRecord(address _user, uint256 _record) public view returns (uint256, uint256, uint256, bool) {
        Record memory r = user[_user][_record];
        return (r.tokens_amount, r.burn_date, r.lock_period, r.minted);
    }
    
    function faucet() external returns (bool) {
        require(!faucetAddress[_msgSender()], "Limit exceeded.");
        if (faucetTotalAddresses == 100000) {
            faucetAmount = faucetAmount.div(2);
            faucetTotalAddresses = 0;
        }
        faucetAddress[_msgSender()] = true;
        faucetTotalAddresses++;
        _mint(_msgSender(), faucetAmount);
        emit Faucet(_msgSender(), faucetAmount, now);
    }
    
    function getFaucetAddress(address _user) public view returns (bool) {
        return faucetAddress[_user];
    }

}
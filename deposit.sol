pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract BBOXDeposit is Ownable, Pausable {

    //Smart-contract general
    address public owner;
    address public receiver;
    ERC20 public ERC20Interface;

    //Transactions tokens structures
    struct TokenTransaction {
        address token;
        address from;
        uint amount;
        bool success;
    }

    TokenTransaction[] public tokenTransactions;
    mapping(address => uint[]) public tokenTransactionIndexesToSender;
    mapping(bytes32 => address) public tokens; //Token name to address maping

    //Transactions coins structures
    struct CoinTransaction {
        address from;
        uint amount;
        bool success;
    }

    CoinTransaction[] public coinTransactions;
    mapping(address => uint[]) public coinTransactionIndexesToSender;

    //Events
    event TokenTransactionSuccessful(address indexed from, address indexed token, uint256 amount);
    event TokenTransactionFailed(address indexed from, address indexed token, uint256 amount);
    event CoinTransactionSuccessful(address indexed from, uint256 amount);
    event CoinTransactionFailed(address indexed from, uint256 amount);

    //Methods
    constructor() public {
        owner = msg.sender;
        receiver = msg.sender; //If delete replace all "receiver" variables with owner and remove "changeReceiver" function
    }

    //Transfer tokens
    function addNewToken(bytes32 _symbol, address _address) public onlyOwner returns (bool) {
        tokens[_symbol] = _address;

        return true;
    }

    function removeToken(bytes32 _symbol) public onlyOwner returns (bool) {
        require(tokens[_symbol] != 0x0, "Can't delete token. Token not listed");

        delete(tokens[_symbol]);

        return true;
    }

    function transferTokens(bytes32 _symbol, uint256 _amount) public whenNotPaused{
        require(tokens[_symbol] != 0x0, "Can't transfer tokens. Token not listed");
        require(_amount > 0, "Can't transfer tokens. Bad amount");

        address token = tokens[_symbol];
        address from = msg.sender;
        address to = receiver;

        ERC20Interface = ERC20(token);

        uint256 transactionId = tokenTransactions.push(
            TokenTransaction({
                token: token,
                from: from,
                amount: _amount,
                success: false
            })
        );

        tokenTransactionIndexesToSender[from].push(transactionId - 1);

        if(_amount > ERC20Interface.allowance(from, address(this))) {
            emit TokenTransactionFailed(from, to, _amount);
            revert("Can't transfer tokens. Bad amount");
        }

        ERC20Interface.transferFrom(from, to, _amount);

        tokenTransactionIndexesToSender[transactionId - 1].success = true;

        emit TokenTransactionSuccessful(from, to, _amount);
    }

    //Transfer coins
    function transferCoins() public payable whenNotPaused{
        require(balance[msg.sender] >= msg.value);

        uint256 amount = msg.value;
        address from = msg.sender;
        address to = receiver;

        uint256 transactionId = coinTransactions.push(
            Transaction({
                from: from,
                amount: _amount,
                success: false
            })
        );
        coinTransactionIndexesToSender[from].push(transactionId - 1);

        require(receiver.transfer(msg.value), "Funds have to be sent");

        transactions[transactionId - 1].success = true;

        emit CoinTransactionSuccessful(from, to, _amount);
    }

    //Change receiving wallet
    function changeReceiver(address new_receiver) public onlyOwner {
        receiver = new_receiver;
    }

}

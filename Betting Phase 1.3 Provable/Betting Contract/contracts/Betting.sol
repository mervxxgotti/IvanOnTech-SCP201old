pragma solidity >= 0.5.0 < 0.6.0;

//import "github.com/provable-things/ethereum-api/provableAPI_0.5.sol";
import "./provableAPI_0.5.sol";

contract Betting is usingProvable {

    uint public contractBalance;

    //for generating random number using provable
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
    uint256 public latestNumber;

    struct player {
        address playerAddress;
        uint balance;
        uint bet;
        bool waiting;           //true if player waiting for oracle request
        bool win;               //true if last bet won
        bytes32 queryId;
    }

    struct query {
        bytes32 id;
        address playerAddress;
        uint256 random;
    }

    mapping(address => player) private players;
    mapping(bytes32 => query) private queries;

    event LogGeneratedRandomNumber(bytes32 requestId, uint256 randomNumber);
    event LogGameState(address playerAddress, uint playerBalance, bytes32 queryId, uint256 random, uint contractBalance);
    event LogPlay(address playerAddress, uint bet, bytes32 queryId);
    event LogRandomRequest(address playerAddress, bytes32 queryId);
    event LogRandomRequestRecieved(address playerAddress, bytes32 queryId, uint random);
    event LogPlayEnd(address playerAddress, bool win, uint256 winAmount);

    /*
     * MODIFIERS
     ************************************************************************************************
     */
    modifier initCosts(uint initCost){
        require(msg.value >= initCost, "Contract needs minimum ether to initialize contract balance.");
        _;
    }

    modifier costs(uint cost){
        require(msg.value >= cost, "Minimum bet or deposit is 0.01 ether!");
        _;
    }

    modifier ready() {
        require(contractBalance > 0, "Cannot play. Contract balance is empty.");
        require(players[msg.sender].waiting == false, "Cannot play. This player address is already playing and waiting on request.");
        _;
    }

    modifier withdrawable() {
        require(msg.sender != address(0));
        require(players[msg.sender].balance > 0, "This address has no funds to withdraw.");
        require(!players[msg.sender].waiting, "Cannot withdraw while waiting for oracle request.");
        _;
    }

    /***********************************************************************************************/

    //constructor takes initial 0.05 ether (50 finney) from default player
    constructor() public payable initCosts(0.05 ether) {

        contractBalance += msg.value;

        players[msg.sender].playerAddress = msg.sender;
        players[msg.sender].balance = 0;
        players[msg.sender].bet = 0;
        players[msg.sender].waiting = false;
        players[msg.sender].win = false;
        players[msg.sender].queryId = 0;

        emit LogGameState(players[msg.sender].playerAddress, players[msg.sender].balance, 0, 0, contractBalance);
    }

    function play() public payable costs(0.01 ether) ready {
        players[msg.sender].playerAddress = msg.sender;
        players[msg.sender].bet = msg.value;
        players[msg.sender].waiting = true;

        bytes32 newQueryId = getRandomNumber();

        players[msg.sender].queryId = newQueryId;

        queries[newQueryId].id = newQueryId;
        queries[newQueryId].playerAddress = msg.sender;

        emit LogPlay(players[msg.sender].playerAddress, players[msg.sender].bet, newQueryId);
    }

    function getRandomNumber() payable public returns (bytes32 queryId) {
        uint QUERY_EXECUTION_DELAY = 0;
        uint GAS_FOR_CALLBACK = 200000;
        bytes32 query_id = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);
        
        emit LogRandomRequest(msg.sender, query_id);

        return query_id;
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result)));
        latestNumber = randomNumber;
        updateGame(_queryId);
        
        emit LogRandomRequestRecieved(queries[_queryId].playerAddress, _queryId, latestNumber);
    }

    function updateGame(bytes32 _queryId) internal {
        address playerAddress = queries[_queryId].playerAddress;

        queries[_queryId].random = latestNumber;

        if(latestNumber % 2 == 1) {
            players[playerAddress].win = true;
        } else {
            players[playerAddress].win = false;
        }

        updateBalances(playerAddress, _queryId);

        players[playerAddress].waiting = false;

        //delete(requests[_queryId]);
    }

    function updateBalances(address playerAddress, bytes32 _queryId) internal {
        if(players[playerAddress].win) {
            players[playerAddress].balance += players[playerAddress].bet * 2;
            contractBalance -= players[playerAddress].bet * 2;
            emit LogPlayEnd(playerAddress, players[playerAddress].win, players[playerAddress].bet*2);
        } else {
            contractBalance += players[playerAddress].bet;
            emit LogPlayEnd(playerAddress, players[playerAddress].win, 0);
        }
    }

    function withdrawPlayerBalance() public withdrawable {
        uint amount = players[msg.sender].balance;
        delete(players[msg.sender]);
        msg.sender.transfer(amount);
    }

    function withdrawContractBalance() public {
        uint256 amount = contractBalance;
        contractBalance = 0;
        msg.sender.transfer(amount);
    }

    function deposit() public payable costs(0.01 ether){
        contractBalance += msg.value;
    }

    function getPlayer() public view returns (address playerAddress, uint balance, uint bet, bool waiting, bool win, bytes32 queryId, uint256 random) {

        return (players[msg.sender].playerAddress,
                players[msg.sender].balance,
                players[msg.sender].bet,
                players[msg.sender].waiting,
                players[msg.sender].win,
                players[msg.sender].queryId,
                queries[players[msg.sender].queryId].random
                );
    }

    function getPlayerBalance() public view returns (uint) {
        return players[msg.sender].balance;
    }

    function getContractBalance() public view returns (uint){
        return contractBalance;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getSenderAddress() public view returns (address) {
        return msg.sender;
    }
}

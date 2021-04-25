var web3 = new Web3(Web3.givenProvider);
var contractAddress = "0xe504b77321156750F0Fa11Fee19034CD84644242";
var contract;

var newGame = true;
var bet = 0;
var config;
var lastRandomNumber = 0;

$(document).ready(function() {
    //brings up metamask ask for permission from browser, then passes accounts in metamask to promise function
    window.ethereum.enable().then(function(accounts) {
      //contract instance of abi template containing function definitions, address of contract, and default sender (metamask account 0)
      contractInstance = new web3.eth.Contract(abi, contractAddress, {from: accounts[0]});

      refreshMetamaskDisplay();
      refreshContractDisplay();
      refreshPlayerDisplay();
    });

    //on click of # buttons, call functions
    $("#play_button").click(play);
    $("#refresh_button").click(refresh);
    $("#withdraw_player_button").click(withdrawPlayerBalance);
    $("#withdraw_contract_button").click(withdrawContractBalance);
    $("#depositTo_contract_button").click(depositToContract);
});

//on add data button click,
function play() {

  bet = $("#bet_input").val();

  console.log("\n *** PLAY button pressed. Bet received from form is: " + bet + " ***");

  config = {
    value: web3.utils.toWei(bet, "ether")
  };

  contractInstance.methods.play().send(config);

  contractInstance.events.LogPlay(function(error, result) {
    console.log("Bet placed! \nPlayerddress: " + result.returnValues.playerAddress + "\nBet Amount: " + result.returnValues.bet + "\nQuery Id: " + result.returnValues.requestId);
  });
}

//get balance from contract to display
function refresh() {
  console.log("\n \n***REFRESH button pressed***");

  refreshMetamaskDisplay();
  refreshContractDisplay();
  refreshPlayerDisplay();
}

function refreshMetamaskDisplay() {

  console.log("\n \n ***REFRESHING METAMASK balance and address display.");

  window.ethereum.enable().then(async function(accounts) {
    this.web3.eth.getBalance(accounts[0], (err, balance) => {
      balance = web3.utils.fromWei(balance, "ether");
      console.log("Metamask account balance: " + balance + " ETH");
      $("#metamask_balance_output").text(balance + " ETH");
    });
  });

  contractInstance.methods.getSenderAddress().call().then(async function(address) {
    console.log("Metamask account (sender) address: " + address);
    $("#metamask_address_output").text(address);
  });
}

function refreshContractDisplay() {

  console.log("***\n \n REFRESHING CONTRACT balance and address display.");

  contractInstance.methods.getContractBalance().call().then(async function(balance) {
    balance = web3.utils.fromWei(balance, "ether");
    console.log("Betting contract balance: " + balance + " ETH");
    $("#contract_balance_output").text(balance + " ETH");
  });

  contractInstance.methods.getContractAddress().call().then(async function(address) {
    console.log("Betting contract address: " + address);
    $("#contract_address_output").text(address);
  });
}

function refreshPlayerDisplay() {

  console.log("***\n \n REFRESHING PLAYER display.");


  contractInstance.methods.getPlayer().call().then(function(player) {
    var lastRandom = player.random;

    console.log("Player address: " + player.playerAddress + "\n");
    console.log("Player balance: " + player.balance + " wei \n");
    console.log("Player waiting: " + player.waiting);
    console.log("Player win: " + player.win);
    console.log("Last random: " + player.random);

    //if new game...
    if(newGame) {

      //if waiting on first bet...
      if(player.waiting) {
        $("#waiting_output").text("Yes");
        $("#round_output").text("Waiting...");
      
      //once waiting is over...
      } else {
        $("#waiting_output").text("No");

        if(player.win) {
          $("#round_output").text("You won " + player.bet*2 + " wei!");
          
        } else {
          $("#round_output").text("You lost " + player.bet + " wei...");

          if(newGame && !player.waiting) {
            $("#waiting_output").text("Not yet. Game hasn't started.");
            $("#round_output").text("It's a new game, and a new day.");
          }
        }

        newGame = false;
      }
    //if not new game...
    } else {

      if(player.waiting) {

        $("#waiting_output").text("Yes");
        $("#round_output").text("Waiting...");

      } else {

        $("#waiting_output").text("No");

        if(player.win) {
          $("#round_output").text("You won " + player.bet*2 + " wei!");
        } else {
          $("#round_output").text("You lost " + player.bet + " wei...");
        }
      }
    }

    $("#random_number_output").text(player.random);
    $("#player_balance_output").text(web3.utils.fromWei(player.balance, "ether") + " ETH");
    $("#bet_output").text(bet + " ETH");

  });
}

function withdrawPlayerBalance() {
  console.log("***WITHDRAW PLAYER button pressed.");
  contractInstance.methods.withdrawPlayerBalance().send();
}

function withdrawContractBalance() {
  console.log("***WITHDRAW CONTRACT button pressed.");
  contractInstance.methods.withdrawContractBalance().send();
}

function depositToContract() {
  console.log("***DEPOSIT TO CONTRACT button pressed.");

  var amount = $("#bet_input").val();

  config = {
    value: web3.utils.toWei(amount, "ether")
  };

  contractInstance.methods.deposit().send(config);
}
pragma solidity ^0.4.15;

// based on https://github.com/raineorshine/multisigwallet
import './MultiSig.sol';

/** A multisig wallet contract. */
contract MultiSigWallet is MultiSig {

  /***********************************************************
   * EVENTS
   ***********************************************************/

  event WalletCreated(uint indexed id, address indexed sender, uint quarum, address[] signers);
  event WalletDeposited(uint indexed id, address indexed sender, uint amount);
  event WithdrawalProposed(uint indexed walletId, address indexed sender, address indexed to, uint multisigId, uint amount);
  event WithdrawalCanceled(uint indexed withdrawalId, address indexed sender);
  event WithdrawalExecuted(uint indexed withdrawalId, address indexed sender, address indexed to, uint amount);

  /***********************************************************
   * DATA
   ***********************************************************/

  enum WithdrawalStatus { OPEN, COMPLETED, CANCELED }

  struct Wallet {
    uint quarum;
    uint balance;
    address[] signers;
  }

  struct Withdrawal {
    uint walletId;
    address creator;
    address to;
    uint multisigId;
    uint amount;
    WithdrawalStatus status;
  }

  /***********************************************************
   * MEMBERS
   ***********************************************************/

  Wallet[] public wallets;
  Withdrawal[] public withdrawals;

  /***********************************************************
   * MODIFIERS
   ***********************************************************/

  /* Throw if the msg.sender is not one of the wallet signers. */
  modifier onlyWalletSigner(uint walletId) {
    Wallet storage wallet = wallets[walletId];
    bool signer = false;
    for (uint i=0; i<wallet.signers.length; i++) {
      if (wallet.signers[i] == msg.sender) {
        signer = true;
        break;
      }
    }
    require(!!signer);
    _;
  }

  /* Only a withdrawal in the open state. */
  modifier onlyWithdrawalOpen(uint withdrawalId) {
    require(withdrawals[withdrawalId].status == WithdrawalStatus.OPEN);
    _;
  }

  /* Only a withdrawal that has been signed by the quaraum of signers. */
  modifier onlyWithdrawalSigned(uint withdrawalId) {
    Withdrawal storage withdrawal = withdrawals[withdrawalId];
    require(super.isComplete(withdrawal.multisigId));
    _;
  }

  /* Only one the creator of the given withdrawal can call this function. */
  modifier onlyWithdrawalCreator(uint withdrawalId) {
    require(withdrawals[withdrawalId].creator == msg.sender);
    _;
  }

  /** Throws if the balance of the wallet for the given withdrawal is less than the requested amount */
  modifier validWithdrawalBalance(uint withdrawalId) {
    Withdrawal storage withdrawal = withdrawals[withdrawalId];
    Wallet storage wallet = wallets[withdrawal.walletId];
    require(wallet.balance >= withdrawal.amount);
    _;
  }

  /***********************************************************
   * NON-CONSTANT PUBLIC FUNCTIONS
   ***********************************************************/

  /** Creates a new MultiSig wallet. */
  function createWallet(address[] signers, uint quarum)
    public 
    returns(uint) 
{

    // autoincrement
    uint walletId = wallets.length;
    wallets.push(Wallet({
      signers: signers,
      quarum: quarum,
      balance: 0
    }));

    emit WalletCreated(walletId, msg.sender, quarum, signers);

    return walletId;
  }

  /** Deposits ETH into the given wallet. */
  function deposit(uint walletId) public payable {
    wallets[walletId].balance += msg.value;
    emit WalletDeposited(walletId, msg.sender, msg.value);
  }

  /** One of the designated signers can propose a withdrawal. */
  function proposeWithdrawal(uint walletId, address to, uint amount) public onlyWalletSigner(walletId) returns(uint) {
    Wallet storage wallet = wallets[walletId];

    // create a new multisig to handle auth for the withdrawal
    uint multisigId = super.addMultiSig(wallet.quarum, wallet.signers);

    // sign for creator
    super.signAs(multisigId, msg.sender);

    // autoincrement id
    uint withdrawalId = withdrawals.length;

    // create new withdrawal
    withdrawals.push(Withdrawal({
      walletId: walletId,
      creator: msg.sender,
      to: to,
      multisigId: multisigId,
      amount: amount,
      status: WithdrawalStatus.OPEN
    }));

    emit WithdrawalProposed(walletId, msg.sender, to, multisigId, amount);

    return withdrawalId;
  }

  /** A withdrawal can be canceled by the creator.*/
  function cancelWithdrawal(uint withdrawalId) public onlyWithdrawalOpen(withdrawalId) onlyWithdrawalCreator(withdrawalId) {
    withdrawals[withdrawalId].status = WithdrawalStatus.CANCELED;
    emit WithdrawalCanceled(withdrawalId, msg.sender);
  }

  /** Executes a withdrawal that has been signed by a quarum of signers. */
  function executeWithdrawal(uint withdrawalId) public onlyWithdrawalOpen(withdrawalId) onlyWithdrawalSigned(withdrawalId) validWithdrawalBalance(withdrawalId) {

    Withdrawal storage withdrawal = withdrawals[withdrawalId];

    // withdraw ETH to destination address
    wallets[withdrawal.walletId].balance -= withdrawal.amount; // safe via validWithdrawalBalance
    if (!withdrawal.to.call.value(withdrawal.amount)()) revert();

    // change status
    withdrawal.status = WithdrawalStatus.COMPLETED;

    emit WithdrawalExecuted(withdrawalId, msg.sender, withdrawal.to, withdrawal.amount);
  }

  /***********************************************************
   * CONSTANT PUBLIC FUNCTIONS
   ***********************************************************/

  // separate function needed since signers will not be returned in default struct[] getter
  function getWalletSigners(uint walletId) public constant returns(address[]) {
    return wallets[walletId].signers;
  }

}
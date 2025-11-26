include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.withdrawals.domain
namespace erlang dmsl.wthd_domain

/// Domain

struct Withdrawal {
    1: required domain.Cash body
    5: optional base.Timestamp created_at
    // Source ?
    2: required Destination destination
    3: optional domain.PartyConfigRef sender
    4: optional domain.PartyConfigRef receiver
    6: optional AuthData auth_data
    7: optional ContactInfo contact_info
}

struct ContactInfo {
    1: optional string phone_number
    2: optional string email
}

union AuthData {
    1: SenderReceiverAuthData sender_receiver
}

struct SenderReceiverAuthData {
    1: required domain.Token sender
    2: required domain.Token receiver
}

union Destination {
    1: domain.BankCard bank_card
    2: domain.CryptoWallet crypto_wallet
    3: domain.DigitalWallet digital_wallet
    4: domain.GenericPaymentTool generic
}

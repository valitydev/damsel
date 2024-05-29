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
    3: optional Identity sender
    4: optional Identity receiver
    6: optional AuthData auth_data
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

struct Identity {
    1: required base.ID id
    4: optional domain.PartyID owner_id
    2: optional list<IdentityDocument> documents
    3: optional list<ContactDetail> contact
}

union IdentityDocument {
    1: RUSDomesticPassport rus_domestic_passport
}

struct RUSDomesticPassport {
    1: required string token
    2: optional string fullname_masked
}

union ContactDetail {
    1: string email
    2: string phone_number
}

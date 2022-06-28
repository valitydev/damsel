include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.payment_tool_token
namespace erlang dmsl.paytool_token

/**
    Платежный токен, который передается плательщику. Платежный токен содержит
    чувствительные данные, которые сериализуются в thrift-binary и шифруются перед отправкой клиенту.
    Платежный токен может иметь срок действия, по истечении которого становится недействительным.
*/
struct PaymentToolToken {
    1: required PaymentToolTokenPayload payload
    2: optional base.Timestamp valid_until
}

/**
    Данные платежного токена
*/
union PaymentToolTokenPayload {
    6: GenericToolPayload generic_payload
    1: BankCardPayload bank_card_payload
    2: PaymentTerminalPayload payment_terminal_payload
    3: DigitalWalletPayload digital_wallet_payload
    4: CryptoCurrencyPayload crypto_currency_payload
    5: MobileCommercePayload mobile_commerce_payload
}

struct GenericToolPayload {
    1: required domain.GenericPaymentTool payment_tool
}

struct BankCardPayload {
    1: required domain.BankCard bank_card
}

struct PaymentTerminalPayload {
    1: required domain.PaymentTerminal payment_terminal
}

struct DigitalWalletPayload {
    1: required domain.DigitalWallet digital_wallet
}

struct CryptoCurrencyPayload {
    2: optional domain.CryptoCurrencyRef crypto_currency
}

struct MobileCommercePayload {
    1: required domain.MobileCommerce mobile_commerce
}

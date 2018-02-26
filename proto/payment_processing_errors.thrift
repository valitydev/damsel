namespace java com.rbkmoney.damsel.payment_processing.errors
namespace erlang payprocerr

/**
 * TODO
 *  - RefundFailure
 *  - RecurrentsFailure
 *  - WalletReject
 *  - ForbiddenIssuerCountry
 *  - CashRegistrationFailure
 *  -
 */

/**
  *
  *
  * # Статическое представление ошибок. (динамическое представление — domain.Failure)
  *
  * При переводе из статического в динамические формат представления следующий.
  * В поле code пишется строковое представления имени варианта в union,
  * далее если это не структура, а юнион, то в поле sub пишется SubFailure,
  * который рекурсивно обрабатывается по аналогичном правилам.
  *
  * Текстовое представление аналогично через имена вариантов в юнион с разделителем в виде двоеточия.
  *
  *
  * ## Например
  *
  *
  * ### Статически типизированное представление
  *
  * ```
  * PaymentFailure{
  *     authorization_failed = AuthorizationFailure{
  *         payment_tool_rejected = PaymentToolReject{
  *             bank_card_rejected = BankCardReject{
  *                 cvv_invalid = GeneralFailure{}
  *             }
  *         }
  *     }
  * }
  * ```
  *
  *
  * ### Текстовое представление (нужно только если есть желание представлять ошибки в виде текста)
  *
  * `authorization_failed:payment_tool_rejected:bank_card_rejected:cvv_invalid`
  *
  *
  * ### Динамически типизированное представление
  *
  * ```
  * domain.Failure{
  *     code = "authorization_failed",
  *     reason = "sngb error '87' — 'Invalid CVV'",
  *     sub = domain.SubFailure{
  *         code = "payment_tool_rejected",
  *         sub = domain.SubFailure{
  *             code = "bank_card_rejected",
  *             sub = domain.SubFailure{
  *                 code = "cvv_invalid"
  *             }
  *         }
  *     }
  * }
  * ```
  *
  */

union PaymentFailure {
    1: GeneralFailure       rejected_by_inspector
    2: GeneralFailure       preauthorization_failed
    3: AuthorizationFailure authorization_failed
}

union AuthorizationFailure {
     1: GeneralFailure    unknown // "silent reject" / "do not honor" / ...
     2: GeneralFailure    merchant_blocked
     3: GeneralFailure    operation_blocked
     4: GeneralFailure    account_not_found
     5: GeneralFailure    account_blocked
     6: GeneralFailure    account_stolen
     7: GeneralFailure    insufficient_funds
     8: LimitExceeded     account_limit_exceeded
     9: LimitExceeded     provider_limit_exceeded
    10: PaymentToolReject payment_tool_rejected
}

union LimitExceeded {
  1: GeneralFailure unknown
  2: GeneralFailure amount
  3: GeneralFailure number
}

union PaymentToolReject {
    1: BankCardReject bank_card_rejected
}

union BankCardReject {
    2: GeneralFailure card_number_invalid
    3: GeneralFailure card_expired
    4: GeneralFailure card_holder_invalid
    5: GeneralFailure cvv_invalid
    6: GeneralFailure card_unsupported
    7: GeneralFailure issuer_not_found
}

struct GeneralFailure {}
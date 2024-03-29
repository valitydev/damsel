namespace java dev.vality.damsel.payment_processing.errors
namespace erlang dmsl.payproc_error

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
    1: GeneralFailure           rejected_by_inspector
    2: PreAuthorizationFailure  preauthorization_failed
    3: AuthorizationFailure     authorization_failed
    4: NoRouteFoundFailure      no_route_found
}

union RefundFailure {
    1: TermsViolated        terms_violated
    2: AuthorizationFailure authorization_failed
}

union PreAuthorizationFailure {
     1: GeneralFailure    unknown
     2: GeneralFailure    three_ds_not_finished
     3: GeneralFailure    three_ds_failed
     4: GeneralFailure    card_blocked
}

union AuthorizationFailure {
     1: GeneralFailure    unknown
     2: GeneralFailure    merchant_blocked
     3: GeneralFailure    operation_blocked
     4: GeneralFailure    account_not_found
     5: GeneralFailure    account_blocked
     6: GeneralFailure    account_stolen
     7: GeneralFailure    insufficient_funds
     8: LimitExceeded     account_limit_exceeded
     9: LimitExceeded     provider_limit_exceeded
    10: PaymentToolReject payment_tool_rejected
    11: GeneralFailure    security_policy_violated
    12: GeneralFailure    temporarily_unavailable
    13: GeneralFailure    rejected_by_issuer         // "silent reject" / "do not honor" / rejected by issuer / ...
    14: GeneralFailure    processing_deadline_reached
    15: LimitExceeded     shop_limit_exceeded
}

union LimitExceeded {
  1: GeneralFailure     unknown
  2: LimitSpanExceeded  amount
  3: GeneralFailure     number
}

union LimitSpanExceeded {
    1: GeneralFailure unknown
    2: GeneralFailure operation
    3: GeneralFailure monthly
    4: GeneralFailure weekly
    5: GeneralFailure daily
}

union PaymentToolReject {
    2: GeneralFailure unknown
    1: BankCardReject bank_card_rejected
}

union BankCardReject {
    1: GeneralFailure unknown
    2: GeneralFailure card_number_invalid
    3: GeneralFailure card_expired
    4: GeneralFailure card_holder_invalid
    5: GeneralFailure cvv_invalid
    // 6: GeneralFailure card_unsupported // на самом деле это нужно было роутить в другую сторону
    7: GeneralFailure issuer_not_found
}

union NoRouteFoundFailure {
    1: GeneralFailure unknown
    2: GeneralFailure risk_score_is_too_high
    // Кандидатов не осталось на этапе вычисления рулсетов согласно политикам
    // маршрутизации соответствующего PaymentInstitution
    3: GeneralFailure forbidden
    // Маршруты-кандидаты были отвергнуты по тем или иным причинам.
    // Поскольку в ходе просева списка доступных маршрутов они отвергаются на
    // разных этапах по разным причинам, то в случае фейла система фиксирует
    // последнюю причину, непосредственно приведшую к этому фейлу.
    4: RoutesRejected rejected
}

union RoutesRejected {
    // Ни по одному из оставшихся маршрутов не удалось произвести учёт в
    // лимитере; это значит что либо используется неправильная валюта для
    // лимита, неправильный платёжный инструмент или передаётся неправильный
    // контекст -- мисконфигурация лимита либо условий приведших к
    // использованию маршрута с такими лимитами
    1: GeneralFailure limit_misconfiguration
    // Отвергнуты из-за превышения лимита
    2: GeneralFailure limit_overflow
    // Адаптер не доступен согласно полученной стате от FaultDetector'а
    3: GeneralFailure adapter_unavailable
    // Согласно той же статистике конверсия провайдера упала ниже критического
    // порога и потому соответствующий маршрут/маршруты были отвергнуты
    4: GeneralFailure provider_conversion_is_too_low
}

union TermsViolated {
    1: GeneralFailure insufficient_merchant_funds
}

struct GeneralFailure {}

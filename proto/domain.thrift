/**
 * Определения предметной области.
 */

include "base.thrift"
include "msgpack.thrift"
include "json.thrift"
include "limiter_config.thrift"

namespace java dev.vality.damsel.domain
namespace erlang dmsl.domain

typedef i64        DataRevision
typedef i32        ObjectID
typedef json.Value Metadata

const i32          CANDIDATE_WEIGHT = 0
const i32          CANDIDATE_PRIORITY = 1000

/* Common */

/** Контактная информация. **/
struct ContactInfo {
    1: optional string phone_number
    2: optional string email
    3: optional string first_name
    4: optional string last_name
    5: optional string country
    6: optional string state
    7: optional string city
    8: optional string address
    9: optional string postal_code
    10: optional base.Date date_of_birth
    11: optional string document_id
}

union OperationFailure {
    1: OperationTimeout operation_timeout
    2: Failure          failure
}

struct OperationTimeout {}

/**
 * "Динамическое" представление ошибки,
 * должно использоваться только для передачи,
 * для интерпретации нужно использовать конвертацию в типизированный вид.
 *
 * Если при попытке интерпретировать код через типизированный вид происходит ошибка (нет такого типа),
 * то это означает, что ошибка неизвестна, и такую ситуацию нужно уметь обрабатывать
 * (например просто отдать неизветсную ошибку наверх).
 *
 * Старые ошибки совместимы с новыми и будут читаться.
 * Структура осталась та же, только поле description переименовалось в reason,
 * и добавилось поле sub.
 * В результате для старых ошибок description будет в reason, а в code будет код ошибки
 * (который будет интропретирован как неизвестная ошибка).
 *
 */
struct Failure {
    1: required FailureCode     code;

    2: optional FailureReason   reason;
    3: optional SubFailure      sub;
}

typedef string FailureCode;
typedef string FailureReason; // причина возникшей ошибки и пояснение откуда она взялась

// возможность делать коды ошибок иерархическими
struct SubFailure {
    1: required FailureCode  code;
    2: optional SubFailure   sub;
}

/** Сумма в минимальных денежных единицах. */
typedef i64 Amount

/** Номер счёта. */
typedef i64 AccountID

/** Денежные средства, состоящие из суммы и валюты. */
struct Cash {
    1: required Amount amount
    2: required CurrencyRef currency
}

/**
 * Строковый шаблон согласно [RFC6570](https://tools.ietf.org/html/rfc6570) Level 4.
 */
typedef string URITemplate

/* Contractor transactions */

struct TransactionInfo {
    1: required string id
    2: optional base.Timestamp timestamp
    3: required base.StringMap extra
    4: optional AdditionalTransactionInfo additional_info
}

struct AdditionalTransactionInfo {
    1: optional string rrn // Retrieval Reference Number
    2: optional string approval_code // Authorization Approval Code
    3: optional string acs_url // Issuer Access Control Server (ACS)
    4: optional string pareq // Payer Authentication Request (PAReq)
    5: optional string md // Merchant Data
    6: optional string term_url // Upon success term_url callback is called with following form encoded params
    7: optional string pares // Payer Authentication Response (PARes)
    8: optional string eci // Electronic Commerce Indicator
    9: optional string cavv // Cardholder Authentication Verification Value
    10: optional string xid // 3D Secure transaction identifier
    11: optional string cavv_algorithm // Indicates algorithm used to generate CAVV
    12: optional ThreeDsVerification three_ds_verification
    13: optional string short_payment_id // ID for terminal payments
    14: optional base.StringMap extra_payment_info // Additional payment information for merchant, this data is sent in a webhook
}

/**
* Issuer Authentication Results Values
**/
enum ThreeDsVerification {
    authentication_successful // Y
    attempts_processing_performed // A
    authentication_failed // N
    authentication_could_not_be_performed // U
}

/* Invoices */

typedef base.ID InvoiceID
typedef base.ID InvoicePaymentID
typedef base.ID InvoicePaymentChargebackID
typedef base.ID InvoicePaymentRefundID
typedef base.ID InvoicePaymentAdjustmentID
typedef base.Content InvoiceContext
typedef base.Content InvoicePaymentContext
typedef base.Content InvoicePaymentChargebackContext
typedef string PaymentSessionID
typedef string Fingerprint
typedef string IPAddress

struct Invoice {
    1 : required InvoiceID id
    2 : required DataRevision domain_revision
    3 : required PartyID owner_id
    4 : required ShopID shop_id
    5 : required base.Timestamp created_at
    6 : required InvoiceStatus status
    7 : required InvoiceDetails details
    8 : required base.Timestamp due
    9 : required Cash cost
    10: optional InvoiceContext context
    11: optional InvoiceTemplateID template_id
    12: optional string external_id
    13: optional InvoiceClientInfo client_info
    14: optional Allocation allocation
    15: optional list<InvoiceMutation> mutations
}

union InvoiceMutation {
    1: InvoiceAmountMutation amount
}

struct InvoiceAmountMutation {
    1: required Amount original
    2: required Amount mutated
}

struct InvoiceDetails {
    1: required string product
    2: optional string description
    3: optional InvoiceCart cart
    /* Информация о банковском счете, к операциям с которым возможно относится данный инвойс */
    4: optional InvoiceBankAccount bank_account
}

struct InvoiceCart {
    1: required list<InvoiceLine> lines
}

struct InvoiceLine {
    1: required string product
    2: required i32 quantity
    3: required Cash price
    /* Taxes and other stuff goes here */
    4: required map<string, msgpack.Value> metadata
}

union InvoiceBankAccount {
    1: InvoiceRussianBankAccount russian
}

struct InvoiceRussianBankAccount {
    1: required string account
    2: required string bank_bik
}

//

typedef base.ID AllocationTransactionID

/**
    Прототип - является структурой данных, которую формирует третья сторона
    в момент создания инвойса. С помощью данных прототипа создается структура
    распределения денежных средств для использования внутри системы. */

struct AllocationPrototype {
    1: required list<AllocationTransactionPrototype> transactions
}

/** Прототип транзакции распределения денежных средств. */
struct AllocationTransactionPrototype {
    /** По этому назначению переводится часть денежных средств. */
    1: required AllocationTransactionTarget target
    2: required AllocationTransactionPrototypeBody body
    3: optional AllocationTransactionDetails details
}

union AllocationTransactionPrototypeBody {
    1: AllocationTransactionPrototypeBodyAmount amount
    2: AllocationTransactionPrototypeBodyTotal total
}

struct AllocationTransactionPrototypeBodyAmount {
    /** Сумма, которая будет переведена по назначению. */
    1: required Cash amount
}

struct AllocationTransactionPrototypeBodyTotal {
    /** Общая сумма денежных средств транзакции. */
    1: required Cash total
    /** Комиссия вычитаемая из общей суммы. */
    2: required AllocationTransactionPrototypeFee fee
}

union AllocationTransactionPrototypeFee {
    1: AllocationTransactionPrototypeFeeFixed fixed
    2: AllocationTransactionFeeShare share
}

struct AllocationTransactionPrototypeFeeFixed {
    1: required Cash amount
}

//

struct Allocation {
    1: required list<AllocationTransaction> transactions
}

/** Транзакция - единица распределения денежных средств. */
struct AllocationTransaction {
    1: required AllocationTransactionID id
    /** По этому назначению переводится часть денежных средств. */
    2: required AllocationTransactionTarget target
    /** Сумма, которая будет переведена по назначению. */
    3: required Cash amount
    /**
        Описывает содержимое транзакции в том случае, если был
        использован вариант прототипа с AllocationTransactionPrototypeBody.total
    */
    4: optional AllocationTransactionBodyTotal body
    5: optional AllocationTransactionDetails details
}

union AllocationTransactionTarget {
    1: AllocationTransactionTargetShop shop
}

struct AllocationTransactionTargetShop {
    1: required PartyID owner_id
    2: required ShopID shop_id
}

struct AllocationTransactionBodyTotal {
    /** По этому назначению переводится часть денежных средств. */
    1: required AllocationTransactionTarget fee_target
    /** Общая сумма денежных средств транзакции. */
    2: required Cash total
    /** Комиссия вычитаемая из общей суммы, будет переведена по назначению. */
    3: required Cash fee_amount
    /**
        Описывает комиссию в относительных величинах в том случае, если был
        использован вариант прототипа с AllocationTransactionPrototypeFee.share
    */
    4: optional AllocationTransactionFeeShare fee
}

struct AllocationTransactionFeeShare {
    1: required base.Rational parts
    /** Метод по умолчанию round_half_away_from_zero. */
    2: optional RoundingMethod rounding_method
}

struct AllocationTransactionDetails {
    1: optional InvoiceCart cart
}

struct InvoiceUnpaid    {}
struct InvoicePaid      {}
struct InvoiceCancelled { 1: required string details }
struct InvoiceFulfilled { 1: required string details }

union InvoiceStatus {
    1: InvoiceUnpaid unpaid
    2: InvoicePaid paid
    3: InvoiceCancelled cancelled
    4: InvoiceFulfilled fulfilled
}

struct InvoicePayment {
    1:  required InvoicePaymentID id
    2:  required base.Timestamp created_at
    3:  required InvoicePaymentStatus status
    4:  optional InvoicePaymentContext context
    5:  required Cash cost
    6:  optional Cash changed_cost
    7:  required DataRevision domain_revision
    8:  required InvoicePaymentFlow flow
    9:  required Payer payer
    10: optional PayerSessionInfo payer_session_info
    12: optional PartyID owner_id
    13: optional ShopID shop_id
    14: optional bool make_recurrent
    15: optional string external_id
    16: optional base.Timestamp processing_deadline
    17: optional InvoicePaymentRegistrationOrigin registration_origin
}

struct InvoicePaymentPending   {}
struct InvoicePaymentProcessed {}
struct InvoicePaymentCaptured  {
    1: optional string reason
    2: optional Cash cost
    3: optional InvoiceCart cart
    4: optional Allocation allocation
}
struct InvoicePaymentCancelled { 1: optional string reason }
struct InvoicePaymentRefunded  {}
struct InvoicePaymentFailed    { 1: required OperationFailure failure }

struct InvoicePaymentChargedBack {}

union InvoicePaymentRegistrationOrigin {
    // Платеж совершенный мерачантом
    1: InvoicePaymentMerchantRegistration merchant
    // Платеж совершенный провайдером
    2: InvoicePaymentProviderRegistration provider
}

struct InvoicePaymentMerchantRegistration {}
struct InvoicePaymentProviderRegistration {}

/**
 * Шаблон инвойса.
 */

typedef base.ID InvoiceTemplateID

struct InvoiceTemplate {
    1:  required InvoiceTemplateID id
    2:  required PartyID owner_id
    3:  required ShopID shop_id
    4:  required LifetimeInterval invoice_lifetime
    5:  required string product # for backward compatibility
    6:  optional string name
    7:  optional string description
    8:  optional base.Timestamp created_at
    9:  required InvoiceTemplateDetails details
    10: optional InvoiceContext context
    11: optional list<InvoiceMutationParams> mutations
}

union InvoiceMutationParams {
    1: InvoiceAmountMutationParams amount
}

union InvoiceAmountMutationParams {
    1: RandomizationMutationParams randomization
}

struct RandomizationMutationParams {
    1: required Amount deviation
    2: required i64 precision
    /**
     * По умолчанию полагается допустимым отклонение в обе стороны
     */
    3: optional DeviationDirection direction
    4: optional Amount min_amount_condition
    5: optional Amount max_amount_condition
    6: optional Amount amount_multiplicity_condition
}

enum DeviationDirection {
    both = 1
    upward = 2
    downward = 3
}

union InvoiceTemplateDetails {
    1: InvoiceCart cart
    2: InvoiceTemplateProduct product
}

struct InvoiceTemplateProduct {
    1: required string product
    2: required InvoiceTemplateProductPrice price
    3: required map<string, msgpack.Value> metadata
}

union InvoiceTemplateProductPrice {
    1: Cash fixed
    2: CashRange range
    3: InvoiceTemplateCostUnlimited unlim
}

struct InvoiceTemplateCostUnlimited {}

/**
 * Статус платежа.
 */
union InvoicePaymentStatus {
    1: InvoicePaymentPending pending
    2: InvoicePaymentProcessed processed
    3: InvoicePaymentCaptured captured
    4: InvoicePaymentCancelled cancelled
    5: InvoicePaymentRefunded refunded
    6: InvoicePaymentFailed failed
    7: InvoicePaymentChargedBack charged_back
}

/**
 * Информация о клиенте, которую передал мерчант
 */
struct InvoiceClientInfo {
    1: optional ClientTrustLevel trust_level
}

enum ClientTrustLevel {
    well_known
    unknown
}

/**
 * Целевое значение статуса платежа.
 */
union TargetInvoicePaymentStatus {

    /**
     * Платёж обработан.
     *
     * При достижении платежом этого статуса процессинг должен обладать:
     *  - фактом того, что провайдер _по крайней мере_ авторизовал списание денежных средств в
     *    пользу системы;
     *  - данными транзакции провайдера.
     */
    1: InvoicePaymentProcessed processed

    /**
     * Платёж подтверждён.
     *
     * При достижении платежом этого статуса процессинг должен быть уверен в том, что провайдер
     * _по крайней мере_ подтвердил финансовые обязательства перед системой.
     */
    2: InvoicePaymentCaptured captured

    /**
     * Платёж отменён.
     *
     * При достижении платежом этого статуса процессинг должен быть уверен в том, что провайдер
     * аннулировал неподтверждённое списание денежных средств.
     *
     * В случае, если в рамках сессии проведения платежа провайдер авторизовал, но _ещё не
     * подтвердил_ списание средств, эта цель является обратной цели `processed`. В ином случае
     * эта цель недостижима, и взаимодействие в рамках сессии должно завершится с ошибкой.
     */
    3: InvoicePaymentCancelled cancelled

    /**
     * Платёж возвращён.
     *
     * При достижении платежом этого статуса процессинг должен быть уверен в том, что провайдер
     * возвратил денежные средства плательщику, потраченные им в ходе подтверждённого списания.
     *
     * Если эта цель недостижима, взаимодействие в рамках сессии должно завершится с ошибкой.
     */
    4: InvoicePaymentRefunded refunded
}

union Payer {
    1: PaymentResourcePayer payment_resource
    2: RecurrentPayer       recurrent
}

struct PaymentResourcePayer {
    1: required DisposablePaymentResource resource
    2: required ContactInfo               contact_info
}

struct RecurrentPayer {
    1: required PaymentTool            payment_tool
    2: required RecurrentParentPayment recurrent_parent
    3: required ContactInfo            contact_info
}

struct ClientInfo {
    1: optional IPAddress ip_address
    2: optional Fingerprint fingerprint
    3: optional string url
    4: optional IPAddress peer_ip_address
    5: optional IPAddress user_ip_address
}

struct PayerSessionInfo {
    /**
     * Адрес, куда необходимо перенаправить user agent плательщика по
     * завершении различных активностей в браузере, вроде авторизации
     * списания средств механизмом 3DS 2.0, если они потребуются.
     *
     * Необходимо указывать только в случае интерактивного проведения
     * платежа, например при помощи платёжной формы. И только тогда,
     * когда обычные средства абстракции вроде user interaction не
     * применимы.
     */
    1: optional URITemplate redirect_url
}

struct PaymentRoute {
    1: required ProviderRef provider
    2: required TerminalRef terminal
}

struct PaymentRouteScores {
    1: optional i32 availability_condition
    2: optional i32 conversion_condition
    3: optional i32 terminal_priority_rating
    4: optional i32 route_pin
    5: optional i32 random_condition
    6: optional double availability
    7: optional double conversion
    8: optional i32 blacklist_condition
}

struct RecurrentParentPayment {
    1: required InvoiceID invoice_id
    2: required InvoicePaymentID payment_id
}

/* Adjustments */

struct InvoicePaymentAdjustment {
    1: required InvoicePaymentAdjustmentID id
    2: required InvoicePaymentAdjustmentStatus status
    3: required base.Timestamp created_at
    4: required DataRevision domain_revision
    5: required string reason
    6: required FinalCashFlow new_cash_flow
    7: required FinalCashFlow old_cash_flow_inverse
    9: optional InvoicePaymentAdjustmentState state
}

struct InvoicePaymentAdjustmentPending   {}
struct InvoicePaymentAdjustmentProcessed {}
struct InvoicePaymentAdjustmentCaptured  { 1: required base.Timestamp at }
struct InvoicePaymentAdjustmentCancelled { 1: required base.Timestamp at }

union InvoicePaymentAdjustmentStatus {
    1: InvoicePaymentAdjustmentPending     pending
    2: InvoicePaymentAdjustmentCaptured   captured
    3: InvoicePaymentAdjustmentCancelled cancelled
    4: InvoicePaymentAdjustmentProcessed processed
}

/**
 * Специфическое для выбранного сценария состояние поправки к платежу.
 */
union InvoicePaymentAdjustmentState {
    1: InvoicePaymentAdjustmentCashFlowState cash_flow
    2: InvoicePaymentAdjustmentStatusChangeState status_change
}

struct InvoicePaymentAdjustmentCashFlowState {
    1: required InvoicePaymentAdjustmentCashFlow scenario
}

struct InvoicePaymentAdjustmentStatusChangeState {
    1: required InvoicePaymentAdjustmentStatusChange scenario
}

/**
 * Параметры поправки к платежу, используемые для пересчёта графа финансовых потоков.
 */
struct InvoicePaymentAdjustmentCashFlow {
    /** Ревизия, относительно которой необходимо пересчитать граф финансовых потоков. */
    1: optional DataRevision domain_revision
    /**
     * Сумма, относительно которой необходимо пересчитать
     * граф финансовых потоков.
     */
    2: optional Amount new_amount
}

/**
 * Параметры поправки к платежу, используемые для смены его статуса.
 */
struct InvoicePaymentAdjustmentStatusChange {
    /** Статус, в который необходимо перевести платёж. */
    1: required InvoicePaymentStatus target_status
}

/**
 * Процесс выполнения платежа.
 */
union InvoicePaymentFlow {
    1: InvoicePaymentFlowInstant instant
    2: InvoicePaymentFlowHold hold
}

struct InvoicePaymentFlowInstant   {}

struct InvoicePaymentFlowHold {
    1: required OnHoldExpiration on_hold_expiration
    2: required base.Timestamp held_until
}

enum OnHoldExpiration {
    cancel
    capture
}

/* Chargebacks */

struct InvoicePaymentChargeback {
     1: required InvoicePaymentChargebackID      id
     2: required InvoicePaymentChargebackStatus  status
     3: required base.Timestamp                  created_at
     4: required InvoicePaymentChargebackReason  reason
     5: required Cash                            levy
     6: required Cash                            body
     7: required InvoicePaymentChargebackStage   stage
     8: required DataRevision                    domain_revision
    10: optional InvoicePaymentChargebackContext context
    11: optional string                          external_id
}

typedef string ChargebackCode

struct InvoicePaymentChargebackReason {
    1: optional ChargebackCode code
    2: required InvoicePaymentChargebackCategory category
}

union InvoicePaymentChargebackCategory {
    /* The Fraud category is used for reason codes related to fraudulent transactions.
       Reason codes related to no cardholder authorization, EMV liability, Card Present
       and Card Not Present fraud are all found within the Fraud category. */
    1: InvoicePaymentChargebackCategoryFraud           fraud

    /* Consumer Disputes represent chargebacks initiated by the cardholder
       in regards to product, service, or merchant issues.
       Consumer Disputes are also referred to as Cardholder Disputes,
       Card Member Disputes, and Service chargebacks.
       The reasons for disputes categorized under Consumer Disputes are varied;
       and can include circumstances like goods not received to cancelled recurring billing. */
    2: InvoicePaymentChargebackCategoryDispute         dispute

    /* Authorisation chargebacks represent disputes related to authorization issues.
       For example, transactions where authorization was required, but not obtained.
       They can also represent disputes where an Authorisation Request received a Decline
       or Pickup Response and the merchant completed the transaction anyway. */
    3: InvoicePaymentChargebackCategoryAuthorisation   authorisation

    /* Processing Errors, also referred to as Point-of-Interaction Errors,
       categorize reason codes representing disputes including duplicate processing,
       late presentment, credit processed as charge, invalid card numbers,
       addendum/“no show” disputes, incorrect charge amounts, and other similar situations. */
    4: InvoicePaymentChargebackCategoryProcessingError processing_error

    /* Chargeback category that serves as a system category, for internal use. */
    5: InvoicePaymentChargebackCategorySystemSet       system_set
}

struct InvoicePaymentChargebackCategoryFraud           {}
struct InvoicePaymentChargebackCategoryDispute         {}
struct InvoicePaymentChargebackCategoryAuthorisation   {}
struct InvoicePaymentChargebackCategoryProcessingError {}
struct InvoicePaymentChargebackCategorySystemSet       {}

union InvoicePaymentChargebackStage {
    1: InvoicePaymentChargebackStageChargeback     chargeback
    2: InvoicePaymentChargebackStagePreArbitration pre_arbitration
    3: InvoicePaymentChargebackStageArbitration    arbitration
}

struct InvoicePaymentChargebackStageChargeback     {}
struct InvoicePaymentChargebackStagePreArbitration {}
struct InvoicePaymentChargebackStageArbitration    {}

union InvoicePaymentChargebackStatus {
    1: InvoicePaymentChargebackPending   pending
    2: InvoicePaymentChargebackAccepted  accepted
    3: InvoicePaymentChargebackRejected  rejected
    4: InvoicePaymentChargebackCancelled cancelled
}

struct InvoicePaymentChargebackPending   {}
struct InvoicePaymentChargebackAccepted  {}
struct InvoicePaymentChargebackRejected  {}
struct InvoicePaymentChargebackCancelled {}

/* Refunds */

struct InvoicePaymentRefund {
    1 : required InvoicePaymentRefundID id
    2 : required InvoicePaymentRefundStatus status
    3 : required base.Timestamp created_at
    4 : required DataRevision domain_revision
    6 : optional Cash cash
    5 : optional string reason
    8 : optional InvoiceCart cart
    9 : optional string external_id
    10: optional Allocation allocation
}

union InvoicePaymentRefundStatus {
    1: InvoicePaymentRefundPending pending
    2: InvoicePaymentRefundSucceeded succeeded
    3: InvoicePaymentRefundFailed failed
}

struct InvoicePaymentRefundPending {}
struct InvoicePaymentRefundSucceeded {}

struct InvoicePaymentRefundFailed {
    1: required OperationFailure failure
}

/* Blocking and suspension */

union Blocking {
    1: Unblocked unblocked
    2: Blocked   blocked
}

struct Unblocked {
    1: required string reason
    2: required base.Timestamp since
}

struct Blocked {
    1: required string reason
    2: required base.Timestamp since
}

union Suspension {
    1: Active    active
    2: Suspended suspended
}

struct Active {
    1: required base.Timestamp since
}

struct Suspended {
    1: required base.Timestamp since
}

/* Parties */

typedef base.ID PartyID

struct PartyContactInfo {
    1: required string registration_email
    2: optional list<string> manager_contact_emails
}

/* Shops */

typedef base.ID ShopID

struct ShopAccount {
    1: required CurrencyRef currency
    2: required AccountID settlement
    3: required AccountID guarantee
}

union ShopLocation {
    1: string url
}

/* Инспекция платежа */

enum RiskScore {
    trusted = 0
    low = 1
    high = 100
    fatal = 9999
}

typedef base.ID ScoreID

//

struct CountryRef {
    1: required CountryCode id
}

struct Country {
    1: required string name
    2: optional set<TradeBlocRef> trade_blocs
}

typedef base.ID TradeBlocID

/* Экономическая зона/блок Мерчанта: напр. ЕЭЗ */
/* См. https://en.wikipedia.org/wiki/Trade_bloc */
struct TradeBlocRef {
    1: required TradeBlocID id
}

struct TradeBloc {
    1: required string name
    2: optional string description
}

/** Банковский счёт. */

struct RussianBankAccount {
    1: required string account
    2: required string bank_name
    3: required string bank_post_account
    4: required string bank_bik
}

struct InternationalBankAccount {

    // common
    1: optional string                   number
    2: optional InternationalBankDetails bank
    3: optional InternationalBankAccount correspondent_account

    // sources
    4: optional string iban           // International Bank Account Number (ISO 13616)

    // deprecated
    5: optional string account_holder // we have `InternationalLegalEntity.legal_name` for that purpose
}

struct InternationalBankDetails {

    // common
    1: optional string    bic         // Business Identifier Code (ISO 9362)
    2: optional Residence country
    3: optional string    name
    4: optional string    address

    // sources
    5: optional string    aba_rtn     // ABA Routing Transit Number

}

/* Categories */

struct CategoryRef { 1: required ObjectID id }

enum CategoryType {
    test
    live
}

/** Категория продаваемых товаров или услуг. */
struct Category {
    1: required string name
    2: required string description
    3: optional CategoryType type = CategoryType.test
}

union Lifetime {
    1: base.Timestamp timestamp
    2: LifetimeInterval interval
}

struct LifetimeInterval {
    1: optional i16 years
    2: optional i16 months
    3: optional i16 days
    4: optional i16 hours
    5: optional i16 minutes
    6: optional i16 seconds
}

/** Условия **/
// Service
//   Payments
//     Regular
//     Held
//     Recurring
//     ...
//   ...

struct TermSet {
    1: optional PaymentsServiceTerms payments
    2: optional RecurrentPaytoolsServiceTerms recurrent_paytools
    4: optional ReportsServiceTerms reports
    5: optional WalletServiceTerms wallets
}

struct TermSetHierarchy {
    3: optional string name
    4: optional string description
    1: optional TermSetHierarchyRef parent_terms
    2: required TermSet term_set
}

struct TermSetHierarchyRef { 1: required ObjectID id }

/* Payments service terms */

struct PaymentsServiceTerms {
     /* Shop level */
     // TODO It looks like you belong to the better place, something they call `AccountsServiceTerms`.
     1: optional CurrencySelector currencies
     2: optional CategorySelector categories
     /* Invoice level*/
     4: optional PaymentMethodSelector payment_methods
     5: optional CashLimitSelector cash_limit
     /* Payment level */
     6: optional CashFlowSelector fees
     9: optional PaymentHoldsServiceTerms holds
     8: optional PaymentRefundsServiceTerms refunds
    10: optional PaymentChargebackServiceTerms chargebacks
    11: optional PaymentAllocationServiceTerms allocations
    12: optional AttemptLimitSelector attempt_limit
}

struct PaymentHoldsServiceTerms {
    1: optional PaymentMethodSelector payment_methods
    2: optional HoldLifetimeSelector lifetime
    /* Allow partial capture if this undefined, otherwise throw exception */
    3: optional PartialCaptureServiceTerms partial_captures
}

struct PartialCaptureServiceTerms {}

struct PaymentChargebackServiceTerms {
    5: optional Predicate allow
    2: optional CashFlowSelector fees
    3: optional TimeSpanSelector eligibility_time
}

struct PaymentRefundsServiceTerms {
    1: optional PaymentMethodSelector payment_methods
    2: optional CashFlowSelector fees
    3: optional TimeSpanSelector eligibility_time
    4: optional PartialRefundsServiceTerms partial_refunds
}

struct PartialRefundsServiceTerms {
    1: optional CashLimitSelector cash_limit
}

struct PaymentAllocationServiceTerms {
    /** NOTE
     * Если распределения средств (allocations) разрешены на этом уровне, они также автоматически
     * разрешены для возвратов (refunds) платежей, при создании которых было указано распределение
     * средств (allocation).
     */
    1: optional Predicate allow
}

/* Recurrent payment tools service terms */

struct RecurrentPaytoolsServiceTerms {
    1: optional PaymentMethodSelector payment_methods
}

/** Wallets service terms **/

struct WalletServiceTerms {
    1: optional CurrencySelector currencies
    2: optional CashLimitSelector wallet_limit
    3: optional TurnoverLimitSelector turnover_limit
    4: optional WithdrawalServiceTerms withdrawals
}

/** Withdrawal service terms **/

struct WithdrawalServiceTerms {

    1: optional CurrencySelector currencies
    2: optional CashLimitSelector cash_limit
    3: optional CashFlowSelector cash_flow
    4: optional AttemptLimitSelector attempt_limit
    5: optional PaymentMethodSelector methods
}

/* Reports service terms */
struct ReportsServiceTerms {
    1: optional ServiceAcceptanceActsTerms acts
}

/* Service Acceptance Acts (Акты об оказании услуг) */
struct ServiceAcceptanceActsTerms {
    1: optional BusinessScheduleSelector schedules
}

/* Currencies */

/** Символьный код, уникально идентифицирующий валюту. */
typedef string CurrencySymbolicCode

struct CurrencyRef { 1: required CurrencySymbolicCode symbolic_code }

/** Валюта. */
struct Currency {
    1: required string name
    2: required CurrencySymbolicCode symbolic_code
    3: required i16 numeric_code
    4: required i16 exponent
}

union CurrencySelector {
    1: list<CurrencyDecision> decisions
    2: set<CurrencyRef> value
}

struct CurrencyDecision {
    1: required Predicate if_
    2: required CurrencySelector then_
}

/* Категории */

union CategorySelector {
    1: list<CategoryDecision> decisions
    2: set<CategoryRef> value
}

struct CategoryDecision {
    1: required Predicate if_
    2: required CategorySelector then_
}

/* (Налоговая) Резиденция Мерчанта */
typedef CountryCode Residence

/* Код страны */
// Для обозначения используется alpha-3 код по стандарту ISO_3166-1
// https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
enum CountryCode {
    ABH =   0  /*Abkhazia*/
    AUS =   1  /*Australia*/
    AUT =   2  /*Austria*/
    AZE =   3  /*Azerbaijan*/
    ALB =   4  /*Albania*/
    DZA =   5  /*Algeria*/
    ASM =   6  /*American Samoa*/
    AIA =   7  /*Anguilla*/
    AGO =   8  /*Angola*/
    AND =   9  /*Andorra*/
    ATA =  10  /*Antarctica*/
    ATG =  11  /*Antigua and Barbuda*/
    ARG =  12  /*Argentina*/
    ARM =  13  /*Armenia*/
    ABW =  14  /*Aruba*/
    AFG =  15  /*Afghanistan*/
    BHS =  16  /*Bahamas*/
    BGD =  17  /*Bangladesh*/
    BRB =  18  /*Barbados*/
    BHR =  19  /*Bahrain*/
    BLR =  20  /*Belarus*/
    BLZ =  21  /*Belize*/
    BEL =  22  /*Belgium*/
    BEN =  23  /*Benin*/
    BMU =  24  /*Bermuda*/
    BGR =  25  /*Bulgaria*/
    BOL =  26  /*Bolivia, plurinational state of*/
    BES =  27  /*Bonaire, Sint Eustatius and Saba*/
    BIH =  28  /*Bosnia and Herzegovina*/
    BWA =  29  /*Botswana*/
    BRA =  30  /*Brazil*/
    IOT =  31  /*British Indian Ocean Territory*/
    BRN =  32  /*Brunei Darussalam*/
    BFA =  33  /*Burkina Faso*/
    BDI =  34  /*Burundi*/
    BTN =  35  /*Bhutan*/
    VUT =  36  /*Vanuatu*/
    HUN =  37  /*Hungary*/
    VEN =  38  /*Venezuela*/
    VGB =  39  /*Virgin Islands, British*/
    VIR =  40  /*Virgin Islands, U.S.*/
    VNM =  41  /*Vietnam*/
    GAB =  42  /*Gabon*/
    HTI =  43  /*Haiti*/
    GUY =  44  /*Guyana*/
    GMB =  45  /*Gambia*/
    GHA =  46  /*Ghana*/
    GLP =  47  /*Guadeloupe*/
    GTM =  48  /*Guatemala*/
    GIN =  49  /*Guinea*/
    GNB =  50  /*Guinea-Bissau*/
    DEU =  51  /*Germany*/
    GGY =  52  /*Guernsey*/
    GIB =  53  /*Gibraltar*/
    HND =  54  /*Honduras*/
    HKG =  55  /*Hong Kong*/
    GRD =  56  /*Grenada*/
    GRL =  57  /*Greenland*/
    GRC =  58  /*Greece*/
    GEO =  59  /*Georgia*/
    GUM =  60  /*Guam*/
    DNK =  61  /*Denmark*/
    JEY =  62  /*Jersey*/
    DJI =  63  /*Djibouti*/
    DMA =  64  /*Dominica*/
    DOM =  65  /*Dominican Republic*/
    EGY =  66  /*Egypt*/
    ZMB =  67  /*Zambia*/
    ESH =  68  /*Western Sahara*/
    ZWE =  69  /*Zimbabwe*/
    ISR =  70  /*Israel*/
    IND =  71  /*India*/
    IDN =  72  /*Indonesia*/
    JOR =  73  /*Jordan*/
    IRQ =  74  /*Iraq*/
    IRN =  75  /*Iran, Islamic Republic of*/
    IRL =  76  /*Ireland*/
    ISL =  77  /*Iceland*/
    ESP =  78  /*Spain*/
    ITA =  79  /*Italy*/
    YEM =  80  /*Yemen*/
    CPV =  81  /*Cape Verde*/
    KAZ =  82  /*Kazakhstan*/
    KHM =  83  /*Cambodia*/
    CMR =  84  /*Cameroon*/
    CAN =  85  /*Canada*/
    QAT =  86  /*Qatar*/
    KEN =  87  /*Kenya*/
    CYP =  88  /*Cyprus*/
    KGZ =  89  /*Kyrgyzstan*/
    KIR =  90  /*Kiribati*/
    CHN =  91  /*China*/
    CCK =  92  /*Cocos (Keeling) Islands*/
    COL =  93  /*Colombia*/
    COM =  94  /*Comoros*/
    COG =  95  /*Congo*/
    COD =  96  /*Congo, Democratic Republic of the*/
    PRK =  97  /*Korea, Democratic People's republic of*/
    KOR =  98  /*Korea, Republic of*/
    CRI =  99  /*Costa Rica*/
    CIV = 100  /*Cote d'Ivoire*/
    CUB = 101  /*Cuba*/
    KWT = 102  /*Kuwait*/
    CUW = 103  /*Curaçao*/
    LAO = 104  /*Lao People's Democratic Republic*/
    LVA = 105  /*Latvia*/
    LSO = 106  /*Lesotho*/
    LBN = 107  /*Lebanon*/
    LBY = 108  /*Libyan Arab Jamahiriya*/
    LBR = 109  /*Liberia*/
    LIE = 110  /*Liechtenstein*/
    LTU = 111  /*Lithuania*/
    LUX = 112  /*Luxembourg*/
    MUS = 113  /*Mauritius*/
    MRT = 114  /*Mauritania*/
    MDG = 115  /*Madagascar*/
    MYT = 116  /*Mayotte*/
    MAC = 117  /*Macao*/
    MWI = 118  /*Malawi*/
    MYS = 119  /*Malaysia*/
    MLI = 120  /*Mali*/
    UMI = 121  /*United States Minor Outlying Islands*/
    MDV = 122  /*Maldives*/
    MLT = 123  /*Malta*/
    MAR = 124  /*Morocco*/
    MTQ = 125  /*Martinique*/
    MHL = 126  /*Marshall Islands*/
    MEX = 127  /*Mexico*/
    FSM = 128  /*Micronesia, Federated States of*/
    MOZ = 129  /*Mozambique*/
    MDA = 130  /*Moldova*/
    MCO = 131  /*Monaco*/
    MNG = 132  /*Mongolia*/
    MSR = 133  /*Montserrat*/
    MMR = 134  /*Burma*/
    NAM = 135  /*Namibia*/
    NRU = 136  /*Nauru*/
    NPL = 137  /*Nepal*/
    NER = 138  /*Niger*/
    NGA = 139  /*Nigeria*/
    NLD = 140  /*Netherlands*/
    NIC = 141  /*Nicaragua*/
    NIU = 142  /*Niue*/
    NZL = 143  /*New Zealand*/
    NCL = 144  /*New Caledonia*/
    NOR = 145  /*Norway*/
    ARE = 146  /*United Arab Emirates*/
    OMN = 147  /*Oman*/
    BVT = 148  /*Bouvet Island*/
    IMN = 149  /*Isle of Man*/
    NFK = 150  /*Norfolk Island*/
    CXR = 151  /*Christmas Island*/
    HMD = 152  /*Heard Island and McDonald Islands*/
    CYM = 153  /*Cayman Islands*/
    COK = 154  /*Cook Islands*/
    TCA = 155  /*Turks and Caicos Islands*/
    PAK = 156  /*Pakistan*/
    PLW = 157  /*Palau*/
    PSE = 158  /*Palestinian Territory, Occupied*/
    PAN = 159  /*Panama*/
    VAT = 160  /*Holy See (Vatican City State)*/
    PNG = 161  /*Papua New Guinea*/
    PRY = 162  /*Paraguay*/
    PER = 163  /*Peru*/
    PCN = 164  /*Pitcairn*/
    POL = 165  /*Poland*/
    PRT = 166  /*Portugal*/
    PRI = 167  /*Puerto Rico*/
    MKD = 168  /*Macedonia, The Former Yugoslav Republic Of*/
    REU = 169  /*Reunion*/
    RUS = 170  /*Russian Federation*/
    RWA = 171  /*Rwanda*/
    ROU = 172  /*Romania*/
    WSM = 173  /*Samoa*/
    SMR = 174  /*San Marino*/
    STP = 175  /*Sao Tome and Principe*/
    SAU = 176  /*Saudi Arabia*/
    SWZ = 177  /*Swaziland*/
    SHN = 178  /*Saint Helena, Ascension And Tristan Da Cunha*/
    MNP = 179  /*Northern Mariana Islands*/
    BLM = 180  /*Saint Barthélemy*/
    MAF = 181  /*Saint Martin (French Part)*/
    SEN = 182  /*Senegal*/
    VCT = 183  /*Saint Vincent and the Grenadines*/
    KNA = 184  /*Saint Kitts and Nevis*/
    LCA = 185  /*Saint Lucia*/
    SPM = 186  /*Saint Pierre and Miquelon*/
    SRB = 187  /*Serbia*/
    SYC = 188  /*Seychelles*/
    SGP = 189  /*Singapore*/
    SXM = 190  /*Sint Maarten*/
    SYR = 191  /*Syrian Arab Republic*/
    SVK = 192  /*Slovakia*/
    SVN = 193  /*Slovenia*/
    GBR = 194  /*United Kingdom*/
    USA = 195  /*United States*/
    SLB = 196  /*Solomon Islands*/
    SOM = 197  /*Somalia*/
    SDN = 198  /*Sudan*/
    SUR = 199  /*Suriname*/
    SLE = 200  /*Sierra Leone*/
    TJK = 201  /*Tajikistan*/
    THA = 202  /*Thailand*/
    TWN = 203  /*Taiwan, Province of China*/
    TZA = 204  /*Tanzania, United Republic Of*/
    TLS = 205  /*Timor-Leste*/
    TGO = 206  /*Togo*/
    TKL = 207  /*Tokelau*/
    TON = 208  /*Tonga*/
    TTO = 209  /*Trinidad and Tobago*/
    TUV = 210  /*Tuvalu*/
    TUN = 211  /*Tunisia*/
    TKM = 212  /*Turkmenistan*/
    TUR = 213  /*Turkey*/
    UGA = 214  /*Uganda*/
    UZB = 215  /*Uzbekistan*/
    UKR = 216  /*Ukraine*/
    WLF = 217  /*Wallis and Futuna*/
    URY = 218  /*Uruguay*/
    FRO = 219  /*Faroe Islands*/
    FJI = 220  /*Fiji*/
    PHL = 221  /*Philippines*/
    FIN = 222  /*Finland*/
    FLK = 223  /*Falkland Islands (Malvinas)*/
    FRA = 224  /*France*/
    GUF = 225  /*French Guiana*/
    PYF = 226  /*French Polynesia*/
    ATF = 227  /*French Southern Territories*/
    HRV = 228  /*Croatia*/
    CAF = 229  /*Central African Republic*/
    TCD = 230  /*Chad*/
    MNE = 231  /*Montenegro*/
    CZE = 232  /*Czech Republic*/
    CHL = 233  /*Chile*/
    CHE = 234  /*Switzerland*/
    SWE = 235  /*Sweden*/
    SJM = 236  /*Svalbard and Jan Mayen*/
    LKA = 237  /*Sri Lanka*/
    ECU = 238  /*Ecuador*/
    GNQ = 239  /*Equatorial Guinea*/
    ALA = 240  /*Aland Islands*/
    SLV = 241  /*El Salvador*/
    ERI = 242  /*Eritrea*/
    EST = 243  /*Estonia*/
    ETH = 244  /*Ethiopia*/
    ZAF = 245  /*South Africa*/
    SGS = 246  /*South Georgia and the South Sandwich Islands*/
    OST = 247  /*South Ossetia*/
    SSD = 248  /*South Sudan*/
    JAM = 249  /*Jamaica*/
    JPN = 250  /*Japan*/
}

/* Schedules */

struct BusinessScheduleRef { 1: required ObjectID id }

struct BusinessSchedule {
    1: required string name
    2: optional string description
    3: required base.Schedule schedule
    5: optional base.TimeSpan delay

    // Reserved
    // 4
}

union BusinessScheduleSelector {
    1: list<BusinessScheduleDecision> decisions
    2: set<BusinessScheduleRef> value
}

struct BusinessScheduleDecision {
    1: required Predicate if_
    2: required BusinessScheduleSelector then_
}

/* Calendars */

struct CalendarRef { 1: required ObjectID id }

struct Calendar {
    1: required string name
    2: optional string description
    3: required base.Timezone timezone
    4: required CalendarHolidaySet holidays
    5: optional base.DayOfWeek first_day_of_week
}

typedef map<base.Year, set<CalendarHoliday>> CalendarHolidaySet

struct CalendarHoliday {
    1: required string name
    2: optional string description
    3: required base.DayOfMonth day
    4: required base.Month month
}

/* Limits */

struct CashRange {
    1: required CashBound upper
    2: required CashBound lower
}

union CashBound {
    1: Cash inclusive
    2: Cash exclusive
}

union CashLimitSelector {
    1: list<CashLimitDecision> decisions
    2: CashRange value
}

struct CashLimitDecision {
    1: required Predicate if_
    2: required CashLimitSelector then_
}

/* Turnover limits */

typedef limiter_config.LimitConfigID LimitConfigID

struct TurnoverLimit {
    1: required LimitConfigID id

    /**
     * Допустимая верхняя граница.
     * Лимит считается исчерпанным, если значение _строго больше_ верхней границы.
     */
    2: required Amount upper_boundary

    /**
     * Версия конфигурации, объект которой нужно брать для расчета лимитов с таким идентификатором.
     * Обязательна после процесса миграции на конфигурацию лимитов через доминанту.
     */
    3: optional DataRevision domain_revision
}

union TurnoverLimitSelector {
    1: list<TurnoverLimitDecision> decisions
    2: set<TurnoverLimit> value
}

struct TurnoverLimitDecision {
    1: required Predicate if_
    2: required TurnoverLimitSelector then_
}

/* Payment methods */

enum TokenizationMethod {
    dpan
    none
}

union PaymentMethod {
   13: GenericPaymentMethod generic
    9: PaymentServiceRef payment_terminal
   10: PaymentServiceRef digital_wallet
   12: CryptoCurrencyRef crypto_currency
   11: MobileOperatorRef mobile
    8: BankCardPaymentMethod bank_card
}

struct GenericPaymentMethod {
    /**
     * Сервис, обслуживающий данный платёжный инструмент.
     * Например: `{"id": "BankTransfersRUS"}`
     */
    1: required PaymentServiceRef payment_service
}

struct BankCardPaymentMethod {
    5: optional PaymentSystemRef      payment_system
    2: optional bool                  is_cvv_empty = false
    6: optional BankCardTokenServiceRef payment_token
    4: optional TokenizationMethod    tokenization_method
}

struct PaymentSystemRef {
    1: required string id
}

struct PaymentSystem {
  1: required string name
  2: optional string description
  3: optional set<PaymentCardValidationRule> validation_rules
}

struct BankCardTokenServiceRef {
    1: required string id
}

struct BankCardTokenService {
  1: required string name
  2: optional string description
}

union PaymentTool {
    1: GenericPaymentTool generic
    2: BankCard bank_card
    3: PaymentTerminal payment_terminal
    4: DigitalWallet digital_wallet
    5: MobileCommerce mobile_commerce
    6: CryptoCurrencyRef crypto_currency
}

struct GenericPaymentTool {

    /**
     * Сервис, обслуживающий данный платёжный инструмент.
     * Должен соответствовать значению, указанному в `GenericPaymentMethod`.
     */
    1: required PaymentServiceRef payment_service

    /**
     * Данные платёжного инструмента, определённые в соответствии со схемой в
     * `PaymentMethodDefinition`.
     * Например:
     * ```
     * Content {
     *   type = 'application/schema-instance+json; schema=https://api.vality.dev/schemas/payment-methods/v2/BankAccountRUS'
     *   data = '{"accountNumber":"40817810500000000035", "bankBIC":"044525716"}'
     * }
     * ```
     */
    2: optional base.Content data
}

struct DisposablePaymentResource {
    1: required PaymentTool        payment_tool
    2: optional PaymentSessionID   payment_session_id
    3: optional ClientInfo         client_info
}

typedef string Token

struct BankCard {
    1: required Token token
   14: optional PaymentSystemRef payment_system
    3: required string bin
    4: required string last_digits
   15: optional BankCardTokenServiceRef payment_token
   12: optional TokenizationMethod tokenization_method
    6: optional Residence issuer_country
    7: optional string bank_name
    8: optional map<string, msgpack.Value> metadata
    9: optional bool is_cvv_empty
   10: optional BankCardExpDate exp_date
   11: optional string cardholder_name
   13: optional string category
}

/** Дата экспирации */
struct BankCardExpDate {
    /** Месяц 1..12 */
    1: required i8 month
    /** Год 2015..∞ */
    2: required i16 year
}

struct BankCardCategoryRef { 1: required ObjectID id }

struct BankCardCategory {
    1: required string name
    2: required string description
    3: required set<string> category_patterns
}

struct CryptoWallet {
    1: required string id // ID or wallet of the recipient in the third-party payment system
    4: optional CryptoCurrencyRef crypto_currency
    // A destination tag is a unique 9-digit figure assigned to each Ripple (XRP) account
    3: optional string destination_tag
}

struct CryptoCurrencyRef {
    1: required string id
}

struct CryptoCurrency {
  1: required string name
  2: optional string description
}

struct MobileCommerce {
    3: optional MobileOperatorRef operator
    2: required MobilePhone    phone
}

struct MobileOperatorRef {
    1: required string id
}

struct MobileOperator {
  1: required string name
  2: optional string description
}

/**
* Телефонный номер согласно (E.164 — рекомендация ITU-T)
* +79114363738
* cc = 7 - код страны(1-3 цифры)
* ctn = 9114363738 - 10-ти значный номер абонента(макс 12)
*/
struct MobilePhone {
    1: required string cc
    2: required string ctn
}

/** Платеж через терминал **/
struct PaymentTerminal {
    2: optional PaymentServiceRef payment_service

    /**
     * Метаданные, разделённые по пространствам имён.
     * Могут заполняться произвольными значениями, например согласно какой-нибудь
     * схеме данных, заданной в `PaymentService.metadata`, которая обозначает
     * платёжный инструмент, не вписывающийся в текущую модель `PaymentTool`:
     * {"dev.vality.paymentResource": {
     *   "type": "BankAccountRUS",
     *   "accountNumber": "40817810500000000035",
     *   "bankBIC": "044525716",
     *   ...
     * }}
     */
    3: optional map<string, json.Value> metadata

    // Reserved
    // 1
}

/**
*  Вид платежного терминала
**/

struct PaymentServiceRef {
    1: required string id
}

typedef string PaymentServiceCategory

struct PaymentService {
  1: required string name
  2: optional string description

  /**
   * Категория платёжного сервиса.
   * Открытое множество, конкретные значения согласовываются:
   *  - на уровне констант в протоколе,
   *  - вне протокола, на уровне конкретных интеграций.
   */
  3: optional PaymentServiceCategory category

  /**
   * Локальное, известное пользователям название платёжного сервиса:
   * платёжной системы, банка, провайдера кошельков, и т.д.
   * Например: "VISA"
   */
  4: optional string brand_name

  /**
   * Метаданные, разделённые по пространствам имён.
   * Введены для аннотирования платёжных сервисов произвольными данными,
   * необходимыми в частности для логики презентации.
   * Например:
   * {"dev.vality.checkout": {
   *   "brandLogo": {"banner": "/assets/brands/blarg.svg"},
   *   "localization": {
   *     "name": {"ja_JP": "ヱヴァンゲリヲン"}
   *   }
   * }}
   */
  5: optional map<string, json.Value> metadata
}

typedef string DigitalWalletID

struct DigitalWallet {
    4: optional PaymentServiceRef     payment_service
    2: required DigitalWalletID       id
    3: optional Token                 token
    5: optional string                account_name
    6: optional string                account_identity_number

    // Reserved
    // 1
}

struct BankRef { 1: required ObjectID id }

struct Bank {
    1: required string name
    2: required string description
    4: optional set<string> binbase_id_patterns

    /* legacy */
    3: required set<string> bins
}

union PaymentCardValidationRule {
    1: PaymentCardNumber card_number
    2: PaymentCardExpirationDate exp_date
    3: PaymentCardCVC cvc
}

union PaymentCardNumber {
    1: set<base.IntegerRange> ranges
    2: PaymentCardNumberChecksum checksum
}

union PaymentCardNumberChecksum {
    1: PaymentCardNumberChecksumLuhn luhn
}

struct PaymentCardNumberChecksumLuhn {}


union PaymentCardCVC {
    1: base.IntegerRange length
}

union PaymentCardExpirationDate {
    1: PaymentCardExactExpirationDate exact_exp_date
}

struct PaymentCardExactExpirationDate {}

struct PaymentMethodRef { 1: required PaymentMethod id }

/** Способ платежа, категория платёжного средства. */
struct PaymentMethodDefinition {
    1: required string name
    2: required string description
}

union PaymentMethodSchema {
    /**
     * JSON Schema.
     * Может быть использована для задания схем, определённых вовне, например:
     * ```
     * {"$ref": "https://api.vality.dev/schemas/payment-methods/v2/BankAccountRUS"}
     * ```
     */
    1: json.Object json
}

union PaymentMethodSelector {
    1: list<PaymentMethodDecision> decisions
    2: set<PaymentMethodRef> value
}

struct PaymentMethodDecision {
    1: required Predicate if_
    2: required PaymentMethodSelector then_
}

/* Holds */

struct HoldLifetime {
    1: required i32 seconds
}

union HoldLifetimeSelector {
    1: list<HoldLifetimeDecision> decisions
    2: HoldLifetime value
}

struct HoldLifetimeDecision {
    1: required Predicate if_
    2: required HoldLifetimeSelector then_
}

/* Refunds */

union TimeSpanSelector {
    1: list<TimeSpanDecision> decisions
    2: base.TimeSpan value
}

struct TimeSpanDecision {
    1: required Predicate if_
    2: required TimeSpanSelector then_
}

union LifetimeSelector {
    1: list<LifetimeDecision> decisions
    2: Lifetime value
}

struct LifetimeDecision {
    1: required Predicate if_
    2: required LifetimeSelector then_
}
/* Flows */

// TODO

/* Cash flows */

/** Счёт в графе финансовых потоков. */
union CashFlowAccount {
    1: MerchantCashFlowAccount merchant
    2: ProviderCashFlowAccount provider
    3: SystemCashFlowAccount system
    4: ExternalCashFlowAccount external
    5: WalletCashFlowAccount wallet
}

enum MerchantCashFlowAccount {

    /**
     * Расчётный счёт:
     *  - учёт прибыли по платежам в магазине;
     *  - учёт возмещённых вознаграждений.
     */
    settlement = 0

    /**
     * Счёт гарантийного депозита:
     *  - учёт средств для погашения реализовавшихся рисков по мерчанту.
     */
    guarantee = 1

    // Deprecated
    payout = 2
}

enum ProviderCashFlowAccount {

    /**
     * Расчётный счёт:
     *  - учёт полученных средств;
     *  - учёт вознаграждений.
     */
    settlement

}

enum SystemCashFlowAccount {

    /**
     * Расчётный счёт:
     *  - учёт полученных и возмещённых вознаграждений.
     */
    settlement

    /**
     * Расчётный счёт:
     * - проводки между внутренними участниками взаиморасчётов.
     */
    subagent

}

enum ExternalCashFlowAccount {

    /**
     * Счёт поступлений:
     *  - учёт любых поступлений в систему извне.
     */
    income

    /**
     * Счёт выводов:
     *  - учёт любых выводов из системы вовне.
     */
    outcome

}

enum WalletCashFlowAccount {
    sender_source
    sender_settlement
    receiver_settlement
    receiver_destination
}

enum CashFlowConstant {
    operation_amount    = 1
    /** Комиссия "сверху" - взимается с клиента в дополнение к сумме операции */
    surplus             = 2
    // ...
    // TODO

    /* deprecated */
    // invoice_amount = 0
    // payment_amount = 1
}

/** Структура содержит таблицу с комиссиями, удерживаемых при совершение операции.
    В случае когда CashVolume не fixed, Surplus может быть выражена только через operation_amount.
    Например(5% от суммы платежа):
    fees = {
        'surplus': CashVolume{
            share = CashVolumeShare{
                    parts = base.Rational{p = 5, q = 100},
                    of = operation_amount
                }
            }
        }
 */
struct Fees {
    1: required map<CashFlowConstant, CashVolume> fees
}

// See shumaich-proto for details
union AccounterClock {
    1: VectorClock vector
}

struct VectorClock {
    1: required base.Opaque state
}

typedef map<CashFlowConstant, Cash> CashFlowContext

/** Граф финансовых потоков. */
typedef list<CashFlowPosting> CashFlow

/** Денежный поток между двумя участниками. */
struct CashFlowPosting {
    1: required CashFlowAccount source
    2: required CashFlowAccount destination
    3: required CashVolume volume
    4: optional string details
}

/** Полностью вычисленный граф финансовых потоков с проводками всех участников. */
typedef list<FinalCashFlowPosting> FinalCashFlow

/** Вычисленный денежный поток между двумя участниками. */
struct FinalCashFlowPosting {
    1: required FinalCashFlowAccount source
    2: required FinalCashFlowAccount destination
    3: required Cash volume
    4: optional string details
}

struct FinalCashFlowAccount {
    1: required CashFlowAccount account_type
    2: required AccountID account_id
    3: optional TransactionAccount transaction_account
}

/** Счёт в графе финансовых потоков. */
union TransactionAccount {
    1: MerchantTransactionAccount merchant
    2: ProviderTransactionAccount provider
    3: SystemTransactionAccount system
    4: ExternalTransactionAccount external
}

struct MerchantTransactionAccount {
    1: required MerchantCashFlowAccount type
    /**
     * Идентификатор бизнес-объекта, владельца аккаунта.
     */
    2: required MerchantTransactionAccountOwner owner
}

struct MerchantTransactionAccountOwner {
    1: required PartyID party_id
    2: required ShopID shop_id
}

struct ProviderTransactionAccount {
    1: required ProviderCashFlowAccount type
    /**
     * Идентификатор бизнес-объекта, владельца аккаунта.
     */
    2: required ProviderTransactionAccountOwner owner
}

struct ProviderTransactionAccountOwner {
    1: required ProviderRef provider_ref
    2: required TerminalRef terminal_ref
}

struct SystemTransactionAccount {
    1: required SystemCashFlowAccount type
}

struct ExternalTransactionAccount {
    1: required ExternalCashFlowAccount type
}

/** Объём финансовой проводки. */
union CashVolume {
    1: CashVolumeFixed fixed
    2: CashVolumeShare share
    3: CashVolumeProduct product
}

/** Объём в абсолютных денежных единицах. */
struct CashVolumeFixed {
    1: required Cash cash
}

/** Объём в относительных единицах. */
struct CashVolumeShare {
    1: required base.Rational parts
    2: required CashFlowConstant of
    3: optional RoundingMethod rounding_method
}

/** Метод округления к целому числу. */
enum RoundingMethod {
    /** https://en.wikipedia.org/wiki/Rounding#Round_half_towards_zero. */
    round_half_towards_zero
    /** https://en.wikipedia.org/wiki/Rounding#Round_half_away_from_zero. */
    round_half_away_from_zero
}

/** Композиция различных объёмов. */
union CashVolumeProduct {
    /** Минимальный из полученных объёмов. */
    1: set<CashVolume> min_of
    /** Максимальный из полученных объёмов. */
    2: set<CashVolume> max_of
    /** Сумма полученных объёмов. */
    3: set<CashVolume> sum_of
}

union CashFlowSelector {
    1: list<CashFlowDecision> decisions
    2: CashFlow value
}

struct CashFlowDecision {
    1: required Predicate if_
    2: required CashFlowSelector then_
}

union FeeSelector {
    1: list<FeeDecision> decisions
    2: Fees value
}

struct FeeDecision {
    1: required Predicate if_
    2: required FeeSelector then_
}

/* Attempt limit */

union AttemptLimitSelector {
    1: list<AttemptLimitDesision> decisions
    2: AttemptLimit value
}

struct AttemptLimitDesision {
    1: required Predicate if_
    2: required AttemptLimitSelector then_
}

struct AttemptLimit {
    1: required i64 attempts
}

/* Providers */

struct ProviderRef { 1: required ObjectID id }

typedef map<CurrencyRef, ProviderAccount> ProviderAccountSet

struct CascadeWhenNoUI {}

struct CascadeOnMappedErrors {
    1: required set<string> error_signatures
}

// Empty struct means that Cascade is disabled
struct CascadeBehaviour {
    1: optional CascadeWhenNoUI no_user_interaction
    2: optional CascadeOnMappedErrors mapped_errors
}

struct Provider {
    1: required string name
    2: required string description
    3: required Proxy proxy
    4: required PaymentInstitutionRealm realm
    5: optional ProviderAccountSet accounts = {}
    6: optional ProvisionTermSet terms
    7: optional list<ProviderParameter> params_schema
    // Default behaviour is CascadeWhenNoUI
    8: optional CascadeBehaviour cascade_behaviour
    /* Настройка переопределения логики доступности маршрута */
    9: optional RouteFaultDetectorOverrides route_fd_overrides
}

struct CashRegisterProviderRef { 1: required ObjectID id }

struct CashRegisterProvider {
    1: required string                              name
    2: optional string                              description
    3: required list<ProviderParameter>             params_schema
    4: required Proxy                               proxy
}

struct ProviderParameter {
    1: required string                            id
    2: optional string                            description
    3: required ProviderParameterType             type
    4: required bool                              is_required
}

union ProviderParameterType {
    1: ProviderParameterString   string_type
    2: ProviderParameterInteger  integer_type
    3: ProviderParameterUrl      url_type
    4: ProviderParameterPassword password_type
}

struct ProviderParameterString {}
struct ProviderParameterInteger {}
struct ProviderParameterUrl {}
struct ProviderParameterPassword {}

struct ProvisionTermSet {
    1: optional PaymentsProvisionTerms payments
    2: optional RecurrentPaytoolsProvisionTerms recurrent_paytools
    3: optional WalletProvisionTerms wallet
}

struct PaymentsProvisionTerms {
    1: optional Predicate allow
    2: optional Predicate global_allow
    3: optional CurrencySelector currencies
    4: optional CategorySelector categories
    5: optional PaymentMethodSelector payment_methods
    6: optional CashLimitSelector cash_limit
    7: optional CashFlowSelector cash_flow
    8: optional PaymentHoldsProvisionTerms holds
    9: optional PaymentRefundsProvisionTerms refunds
    10: optional PaymentChargebackProvisionTerms chargebacks
    11: optional RiskScoreSelector risk_coverage
    12: optional TurnoverLimitSelector turnover_limits
}

union RiskScoreSelector {
    1: list<RiskScoreDecision> decisions
    2: RiskScore value
}

struct RiskScoreDecision {
    1: required Predicate if_
    2: required RiskScoreSelector then_
}

struct PaymentHoldsProvisionTerms {
    1: required HoldLifetimeSelector lifetime
    /* Allow partial capture if this undefined, otherwise throw exception */
    2: optional PartialCaptureProvisionTerms partial_captures
}

struct PartialCaptureProvisionTerms {}

struct PaymentChargebackProvisionTerms {
    1: required CashFlowSelector cash_flow
    3: optional FeeSelector fees
}

struct PaymentRefundsProvisionTerms {
    1: required CashFlowSelector cash_flow
    /**
     * Условия для частичных рефандов.
     */
    2: optional PartialRefundsProvisionTerms partial_refunds
}

struct PartialRefundsProvisionTerms {
    1: required CashLimitSelector cash_limit
}

struct RecurrentPaytoolsProvisionTerms {
    1: required CashValueSelector     cash_value
    2: required CategorySelector      categories
    3: required PaymentMethodSelector payment_methods
    4: optional RiskScoreSelector     risk_coverage
}

struct WalletProvisionTerms {
    1: optional TurnoverLimitSelector turnover_limit
    2: optional WithdrawalProvisionTerms withdrawals
}

struct WithdrawalProvisionTerms {
    1: optional Predicate allow
    2: optional Predicate global_allow
    3: optional CurrencySelector currencies
    4: optional CashLimitSelector cash_limit
    5: optional CashFlowSelector cash_flow
    6: optional TurnoverLimitSelector turnover_limit
}

union CashValueSelector {
    1: list<CashValueDecision> decisions
    2: Cash value
}

struct CashValueDecision {
    1: required Predicate if_
    2: required CashValueSelector then_
}

struct ProviderAccount {
    1: required AccountID settlement
}

union PaymentSystemSelector {
    1: list<PaymentSystemDecision> decisions
    2: PaymentSystemRef value
}

struct PaymentSystemDecision {
    1: required Predicate if_
    2: required PaymentSystemSelector then_
}

/** Inspectors */

struct InspectorRef { 1: required ObjectID id }

struct Inspector {
    1: required string name
    2: required string description
    3: required Proxy proxy
    4: optional RiskScore fallback_risk_score
}

union InspectorSelector {
    1: list<InspectorDecision> decisions
    2: InspectorRef value
}

struct InspectorDecision {
    1: required Predicate if_
    2: required InspectorSelector then_
}

typedef string ExternalTerminalID
typedef string MerchantID
typedef string MerchantCategoryCode

/**
 * Обобщённый терминал у провайдера.
 *
 * Представляет собой единицу предоставления услуг по процессингу платежей со
 * стороны провайдера, согласно нашим с ним договорённостям.
 */
struct Terminal {
    1: required string name
    2: required string description
    3: optional ProxyOptions options
    4: optional RiskScore risk_coverage
    5: optional ProviderRef provider_ref
    6: optional ProvisionTermSet terms

    /* Идентификатор терминала во внешней системе провайдера.*/
    7: optional ExternalTerminalID external_terminal_id
    /* Идентификатор мерчанта во внешней системе провайдера.*/
    8: optional MerchantID external_merchant_id
    /* Код классификации вида деятельности мерчанта. */
    9: optional MerchantCategoryCode mcc
    /* Настройка переопределения логики доступности маршрута */
    10: optional RouteFaultDetectorOverrides route_fd_overrides
}

struct ProviderTerminalRef {
    1: required ObjectID id
    2: optional i64 priority = 1000
    3: optional i64 weight
}

struct TerminalRef {
    1: required ObjectID id
}

struct RouteFaultDetectorOverrides {
    1: optional bool enabled
}

/* Predicates / conditions */

union Predicate {
    5: bool constant
    1: Condition condition
    2: Predicate is_not
    3: set<Predicate> all_of
    4: set<Predicate> any_of
    6: CriterionRef criterion
}

union Condition {
    1: CategoryRef category_is
    2: CurrencyRef currency_is
    3: CashRange cost_in
    4: Cash cost_is_multiple_of
    5: PaymentToolCondition payment_tool
    6: ShopLocation shop_location_is
    7: PartyCondition party
    8: BinDataCondition bin_data
}

struct BinDataCondition {
    1: optional StringCondition payment_system
    2: optional StringCondition bank_name
}

union StringCondition {
    1: string matches
    2: string equals
}

union PaymentToolCondition {
    1: BankCardCondition bank_card
    2: DigitalWalletCondition digital_wallet
    3: PaymentTerminalCondition payment_terminal
    4: CryptoCurrencyCondition crypto_currency
    5: MobileCommerceCondition mobile_commerce
    6: GenericPaymentToolCondition generic
}

struct BankCardCondition {
    1: optional BankCardConditionDefinition definition
}

union BankCardConditionDefinition {
    1: BankRef issuer_bank_is
    2: PaymentSystemCondition payment_system
    3: Residence issuer_country_is
    4: bool empty_cvv_is
    5: BankCardCategoryRef category_is
}

struct PaymentSystemCondition {
    1: optional PaymentSystemRef      payment_system_is
    2: optional BankCardTokenServiceRef token_service_is
    3: optional TokenizationMethod    tokenization_method_is
}

struct PaymentTerminalCondition {
    1: optional PaymentTerminalConditionDefinition definition
}

union PaymentTerminalConditionDefinition {
    1: PaymentServiceRef payment_service_is
}

struct DigitalWalletCondition {
    1: optional DigitalWalletConditionDefinition definition
}

union DigitalWalletConditionDefinition {
    2: PaymentServiceRef payment_service_is
}

struct CryptoCurrencyCondition {
    1: optional CryptoCurrencyConditionDefinition definition
}

union CryptoCurrencyConditionDefinition {
    2: CryptoCurrencyRef crypto_currency_is
}

struct MobileCommerceCondition {
    1: optional MobileCommerceConditionDefinition definition
}

union MobileCommerceConditionDefinition {
    1: MobileOperatorRef operator_is
}

struct GenericResourceCondition {
    1: required list<string> field_path
    2: required string value
}

union GenericPaymentToolCondition {
    1: PaymentServiceRef payment_service_is
    2: GenericResourceCondition resource_field_matches
}

struct PartyCondition {
    1: required PartyID id
    2: optional PartyConditionDefinition definition
}

typedef base.ID WalletID

union PartyConditionDefinition {
    1: ShopID shop_is
    2: WalletID wallet_is
}

struct CriterionRef { 1: required ObjectID id }

struct Criterion {
    1: required string name
    2: optional string description
    3: required Predicate predicate
}

struct DocumentTypeRef { 1: required ObjectID id }

struct DocumentType {
    1: required string name
    2: optional string description
}

struct BinData {
    1: required string payment_system
    2: optional string bank_name
}

/* Proxies */

typedef base.StringMap ProxyOptions

struct ProxyRef { 1: required ObjectID id }

struct ProxyDefinition {
    1: required string name
    2: required string description
    3: required string url
    4: required ProxyOptions options
}

struct Proxy {
    1: required ProxyRef ref
    2: required ProxyOptions additional
}

/* System accounts */

struct SystemAccountSetRef { 1: required ObjectID id }

struct SystemAccountSet {
    1: required string name
    2: required string description
    3: required map<CurrencyRef, SystemAccount> accounts
}

struct SystemAccount {
    1: required AccountID settlement
    2: optional AccountID subagent
}

union SystemAccountSetSelector {
    1: list<SystemAccountSetDecision> decisions
    2: SystemAccountSetRef value
}

struct SystemAccountSetDecision {
    1: required Predicate if_
    2: required SystemAccountSetSelector then_
}

/* External accounts */

struct ExternalAccountSetRef { 1: required ObjectID id }

struct ExternalAccountSet {
    1: required string name
    2: required string description
    3: required map<CurrencyRef, ExternalAccount> accounts
}

struct ExternalAccount {
    1: required AccountID income
    2: required AccountID outcome
}

union ExternalAccountSetSelector {
    1: list<ExternalAccountSetDecision> decisions
    2: ExternalAccountSetRef value
}

struct ExternalAccountSetDecision {
    1: required Predicate if_
    2: required ExternalAccountSetSelector then_
}

/* Payment institution */

struct PaymentInstitutionRef { 1: required ObjectID id }

struct PaymentInstitution {
    1: required string name
    2: optional string description
    3: optional CalendarRef calendar
    4: required SystemAccountSetSelector system_account_set
    6: required InspectorSelector inspector
    7: required PaymentInstitutionRealm realm
    8: required set<Residence> residences
    /* TODO: separated system accounts for wallets look weird */
    9: optional SystemAccountSetSelector wallet_system_account_set
    10: optional string identity
    11: optional RoutingRules payment_routing_rules
    12: optional RoutingRules withdrawal_routing_rules
    13: optional PaymentSystemSelector payment_system
}

enum PaymentInstitutionRealm {
    test
    live
}

/* Routing rule sets */

struct RoutingRules {
    1: required RoutingRulesetRef policies
    2: required RoutingRulesetRef prohibitions
}

struct RoutingRulesetRef { 1: required ObjectID id }

struct RoutingRuleset {
    1: required string name
    2: optional string description
    3: required RoutingDecisions decisions
}

union RoutingDecisions {
    1: list<RoutingDelegate> delegates
    2: list<RoutingCandidate> candidates
}

struct RoutingDelegate {
    1: optional string description
    2: required Predicate allowed
    3: required RoutingRulesetRef ruleset
}

enum RoutingPinFeature {
    currency
    payment_tool
    client_ip
    email
    card_token
}

struct RoutingPin {
    1: required set<RoutingPinFeature> features
}

struct RoutingCandidate {
    1: optional string description
    2: required Predicate allowed
    3: required TerminalRef terminal
    4: optional i32 priority = CANDIDATE_PRIORITY
    5: optional RoutingPin pin
    6: optional i32 weight = CANDIDATE_WEIGHT
}

/* Root config */

struct GlobalsRef {}

struct Globals {
    1: required ExternalAccountSetSelector external_account_set
    2: optional set<PaymentInstitutionRef> payment_institutions
}

/** Dummy (for integrity test purpose) */
struct Dummy {}

struct DummyRef {
    1: base.ID id
}

struct DummyObject {
    1: DummyRef ref
    2: Dummy data
}

struct DummyLink {
    1: DummyRef link
}

struct DummyLinkRef {
    1: base.ID id
}

struct DummyLinkObject {
    1: DummyLinkRef ref
    2: DummyLink data
}

/* Type enumerations */

struct TermSetHierarchyObject {
    1: required TermSetHierarchyRef ref
    2: required TermSetHierarchy data
}

struct CategoryObject {
    1: required CategoryRef ref
    2: required Category data
}

struct CurrencyObject {
    1: required CurrencyRef ref
    2: required Currency data
}

struct BusinessScheduleObject {
    1: required BusinessScheduleRef ref
    2: required BusinessSchedule data
}

struct CalendarObject {
    1: required CalendarRef ref
    2: required Calendar data
}

struct PaymentMethodObject {
    1: required PaymentMethodRef ref
    2: required PaymentMethodDefinition data
}

struct BankObject {
    1: required BankRef ref
    2: required Bank data
}

struct BankCardCategoryObject {
    1: required BankCardCategoryRef ref
    2: required BankCardCategory data
}

struct ProviderObject {
    1: required ProviderRef ref
    2: required Provider data
}

struct CashRegisterProviderObject {
    1: required CashRegisterProviderRef ref
    2: required CashRegisterProvider data
}

struct TerminalObject {
    1: required TerminalRef ref
    2: required Terminal data
}

struct InspectorObject {
    1: required InspectorRef ref
    2: required Inspector data
}

struct PaymentInstitutionObject {
    1: required PaymentInstitutionRef ref
    2: required PaymentInstitution data
}

struct SystemAccountSetObject {
    1: required SystemAccountSetRef ref
    2: required SystemAccountSet data
}

struct ExternalAccountSetObject {
    1: required ExternalAccountSetRef ref
    2: required ExternalAccountSet data
}

struct ProxyObject {
    1: required ProxyRef ref
    2: required ProxyDefinition data
}

struct GlobalsObject {
    1: required GlobalsRef ref
    2: required Globals data
}

struct RoutingRulesObject {
    1: required RoutingRulesetRef ref
    2: required RoutingRuleset data
}

struct CriterionObject {
    1: required CriterionRef ref
    2: required Criterion data
}

struct DocumentTypeObject {
    1: required DocumentTypeRef ref
    2: required DocumentType data
}

struct PaymentServiceObject {
    1: required PaymentServiceRef ref
    2: required PaymentService data
}

struct PaymentSystemObject {
    1: required PaymentSystemRef ref
    2: required PaymentSystem data
}

struct BankCardTokenServiceObject {
    1: required BankCardTokenServiceRef ref
    2: required BankCardTokenService data
}

struct MobileOperatorObject {
    1: required MobileOperatorRef ref
    2: required MobileOperator data
}

struct CryptoCurrencyObject {
    1: required CryptoCurrencyRef ref
    2: required CryptoCurrency data
}

struct CountryObject {
    1: required CountryRef ref
    2: required Country data
}

struct TradeBlocObject {
    1: required TradeBlocRef ref
    2: required TradeBloc data
}

struct LimitConfigObject {
    1: required LimitConfigRef ref
    2: required limiter_config.LimitConfig data
}

struct LimitConfigRef {
    1: required LimitConfigID id
}

typedef base.ID ShopConfigID

/** Магазин мерчанта. */
struct ShopConfig {
    1: required string name
    2: optional string description
    3: required Blocking block
    4: required Suspension suspension
    5: required PaymentInstitutionRef payment_institution
    6: optional TermSetHierarchyRef terms
    7: required ShopAccount account
    8: required PartyID party_id

    9: required ShopLocation location
    10: required CategoryRef category
    11: optional set<TurnoverLimit> turnover_limits
}

struct ShopConfigObject {
    1: required ShopConfigRef ref
    2: required ShopConfig data
}

struct ShopConfigRef {
    1: required ShopConfigID id
}

typedef base.ID WalletConfigID

struct WalletAccount {
    1: required CurrencyRef currency
    2: required AccountID settlement
}

struct WalletConfig {
    1: required string name
    2: optional string description
    3: required Blocking block
    4: required Suspension suspension
    5: required PaymentInstitutionRef payment_institution
    6: optional TermSetHierarchyRef terms
    7: required WalletAccount account
    9: required PartyID party_id
}

struct WalletConfigObject {
    1: required WalletConfigRef ref
    2: required WalletConfig data
}

struct WalletConfigRef {
    1: required WalletConfigID id
}

/** Участник. */
struct PartyConfig {
    1: required string name
    2: optional string description
    3: required Blocking block
    4: required Suspension suspension
    5: required list<ShopConfigRef> shops
    6: required list<WalletConfigRef> wallets
    7: required PartyContactInfo contact_info
}

struct PartyConfigObject {
    1: required PartyConfigRef ref
    2: required PartyConfig data
}

struct PartyConfigRef {
    1: required PartyID id
}

/* There are 3 requirements on Reference and DomainObject unions:
 * - all field types must be unique,
 * - all corresponding field names in both unions must match,
 * - all types must be accounted in DomainObjectType enum with
 *   union's field number as according values.
 *
 * Otherwise [dmt_core](https://github.com/valitydev/dmt_core)'s
 * integrity verification mechanism would break.
 */

union Reference {

    1: CategoryRef category
    2: CurrencyRef currency
    3: BusinessScheduleRef business_schedule
    4: CalendarRef calendar
    5: PaymentMethodRef payment_method
    6: BankRef bank
    8: TermSetHierarchyRef term_set_hierarchy
    9: PaymentInstitutionRef payment_institution
    10: ProviderRef provider
    11: TerminalRef terminal
    12: InspectorRef inspector
    13: SystemAccountSetRef system_account_set
    14: ExternalAccountSetRef external_account_set
    15: ProxyRef proxy
    16: GlobalsRef globals
    17: CashRegisterProviderRef cash_register_provider
    18: RoutingRulesetRef routing_rules
    19: BankCardCategoryRef bank_card_category
    20: CriterionRef criterion
    21: DocumentTypeRef document_type
    22: PaymentServiceRef payment_service
    23: PaymentSystemRef payment_system
    24: BankCardTokenServiceRef payment_token
    25: MobileOperatorRef mobile_operator
    26: CryptoCurrencyRef crypto_currency
    27: CountryRef country
    28: TradeBlocRef trade_bloc
    29: LimitConfigRef limit_config
    30: DummyRef dummy
    31: DummyLinkRef dummy_link

    32: PartyConfigRef party_config
    33: ShopConfigRef shop_config
    34: WalletConfigRef wallet_config
}

union DomainObject {
    1: CategoryObject category
    2: CurrencyObject currency
    3: BusinessScheduleObject business_schedule
    4: CalendarObject calendar
    5: PaymentMethodObject payment_method
    6: BankObject bank
    8: TermSetHierarchyObject term_set_hierarchy
    9: PaymentInstitutionObject payment_institution
    10: ProviderObject provider
    11: TerminalObject terminal
    12: InspectorObject inspector
    13: SystemAccountSetObject system_account_set
    14: ExternalAccountSetObject external_account_set
    15: ProxyObject proxy
    16: GlobalsObject globals
    17: CashRegisterProviderObject cash_register_provider
    18: RoutingRulesObject routing_rules
    19: BankCardCategoryObject bank_card_category
    20: CriterionObject criterion
    21: DocumentTypeObject document_type
    22: PaymentServiceObject payment_service
    23: PaymentSystemObject payment_system
    24: BankCardTokenServiceObject payment_token
    25: MobileOperatorObject mobile_operator
    26: CryptoCurrencyObject crypto_currency
    27: CountryObject country
    28: TradeBlocObject trade_bloc
    29: LimitConfigObject limit_config
    30: DummyObject dummy
    31: DummyLinkObject dummy_link

    32: PartyConfigObject party_config
    33: ShopConfigObject shop_config
    34: WalletConfigObject wallet_config
}

union ReflessDomainObject {
    1: Category category
    2: Currency currency
    3: BusinessSchedule business_schedule
    4: Calendar calendar
    5: PaymentMethodDefinition payment_method
    6: Bank bank
    8: TermSetHierarchy term_set_hierarchy
    9: PaymentInstitution payment_institution
    10: Provider provider
    11: Terminal terminal
    12: Inspector inspector
    13: SystemAccountSet system_account_set
    14: ExternalAccountSet external_account_set
    15: ProxyDefinition proxy
    16: Globals globals
    17: CashRegisterProvider cash_register_provider
    18: RoutingRuleset routing_rules
    19: BankCardCategory bank_card_category
    20: Criterion criterion
    21: DocumentType document_type
    22: PaymentService payment_service
    23: PaymentSystem payment_system
    24: BankCardTokenService payment_token
    25: MobileOperator mobile_operator
    26: CryptoCurrency crypto_currency
    27: Country country
    28: TradeBloc trade_bloc
    29: limiter_config.LimitConfig limit_config
    30: Dummy dummy
    31: DummyLink dummy_link

    32: PartyConfig party_config
    33: ShopConfig shop_config
    34: WalletConfig wallet_config
}

enum DomainObjectType {
    category = 1
    currency = 2
    business_schedule = 3
    calendar = 4
    payment_method = 5
    bank = 6
    term_set_hierarchy = 8
    payment_institution = 9
    provider = 10
    terminal = 11
    inspector = 12
    system_account_set = 13
    external_account_set = 14
    proxy = 15
    globals = 16
    cash_register_provider = 17
    routing_rules = 18
    bank_card_category = 19
    criterion = 20
    document_type = 21
    payment_service = 22
    payment_system = 23
    payment_token = 24
    mobile_operator = 25
    crypto_currency = 26
    country = 27
    trade_bloc = 28
    limit_config = 29
    dummy = 30
    dummy_link = 31

    party_config = 32
    shop_config = 33
    wallet_config = 34
}

/* Domain */

typedef map<Reference, DomainObject> Domain

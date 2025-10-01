include "base.thrift"

namespace java dev.vality.damsel.limiter.config
namespace erlang dmsl.limiter.config

typedef base.ID LimitConfigID
typedef i64 ShardSize
typedef i64 IntervalAmount

union TimeRangeType {
    1: TimeRangeTypeCalendar calendar
    2: TimeRangeTypeInterval interval
}

union TimeRangeTypeCalendar {
    1: TimeRangeTypeCalendarYear year
    2: TimeRangeTypeCalendarMonth month
    3: TimeRangeTypeCalendarWeek week
    4: TimeRangeTypeCalendarDay day
}

struct TimeRangeTypeCalendarYear {}
struct TimeRangeTypeCalendarMonth {}
struct TimeRangeTypeCalendarWeek {}
struct TimeRangeTypeCalendarDay {}

struct TimeRangeTypeInterval {
    1: required IntervalAmount amount // in sec
}

struct LimitConfig {
    1: required string processor_type
    2: required base.Timestamp started_at
    3: required ShardSize shard_size
    4: required TimeRangeType time_range_type
    5: required LimitContextType context_type
    6: optional LimitType type
    7: optional set<LimitScopeType> scopes
    8: optional string description
    9: optional OperationLimitBehaviour op_behaviour
    /**
     * Convert operation's amount if its context currency differs from
     * limit-turnover metric (see `LimitTurnoverAmount`).
     *
     * If undefined and currency codes do not match, then limiter
     * throws `InvalidOperationCurrency` exception (see
     * limiter-proto).
     */
    10: optional CurrencyConversion currency_conversion
}

struct CurrencyConversion {}

union LimitContextType {
    1: LimitContextTypePaymentProcessing payment_processing
    2: LimitContextTypeWithdrawalProcessing withdrawal_processing
}

struct LimitContextTypePaymentProcessing {}
struct LimitContextTypeWithdrawalProcessing {}

union LimitType {
    1: LimitTypeTurnover turnover
}

struct LimitTypeTurnover {
    /**
     * Metric to account turnover with.
     * If undefined, equivalent to specifying `LimitTurnoverNumber`.
     */
    1: optional LimitTurnoverMetric metric
}

union LimitTurnoverMetric {

    /**
     * Measure turnover over number of operations.
     */
    1: LimitTurnoverNumber number

    /**
     * Measure turnover over aggregate amount of operations denominated in a single currency.
     * In the event operation's currency differs from limit's currency operation will be accounted
     * with appropriate exchange rate fixed against operation's timestamp.
     */
    2: LimitTurnoverAmount amount

}

struct LimitTurnoverNumber {}
struct LimitTurnoverAmount {
    1: required string currency // CurrencySymbolicCode
}

union LimitScopeType {

    1: LimitScopeEmptyDetails party
    2: LimitScopeEmptyDetails shop
    3: LimitScopeEmptyDetails wallet

    /**
     * Scope over data which uniquely identifies payment tool used in a payment.
     * E.g. `domain.BankCard.token` + `domain.BankCard.exp_date` when bank card is being used as
     * payment tool.
     *
     * See: domain.thrift#L1824-L1830
     */
    5: LimitScopeEmptyDetails payment_tool
    6: LimitScopeEmptyDetails provider
    7: LimitScopeEmptyDetails terminal
    8: LimitScopeEmptyDetails payer_contact_email

    /**
     * Scopes for operation's according destination's sender or receiver
     * tokens.
     */
    9: LimitScopeEmptyDetails sender
    10: LimitScopeEmptyDetails receiver

    /**
     * Scope for operations with destination's generic resource fields.
     * See damsel's "base.Content" https://github.com/valitydev/damsel/blob/ad715bd647bc5cfa822e2b09b1329dab6a2bf295/proto/base.thrift#L20-L25
     * and it's example with generic payment tool https://github.com/valitydev/damsel/blob/ad715bd647bc5cfa822e2b09b1329dab6a2bf295/proto/domain.thrift#L1816-L1836
     */
    11: LimitScopeDestinationFieldDetails destination_field
}

struct LimitScopeEmptyDetails {}

/**
 * TODO Support universal context-based field selector
 */
struct LimitScopeDestinationFieldDetails {
    1: required list<string> field_path
}

struct OperationLimitBehaviour {
    1: optional OperationBehaviour invoice_payment_refund
}

union OperationBehaviour {
    1: Subtraction subtraction
    2: Addition addition
}

struct Subtraction {}
struct Addition {}

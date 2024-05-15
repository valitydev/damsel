include "base.thrift"
include "msgpack.thrift"
include "domain.thrift"
include "withdrawals_domain.thrift"

namespace java dev.vality.damsel.withdrawals.processing
namespace erlang dmsl.wthdproc

/// Processing

typedef base.Timestamp Timestamp

typedef base.ID WithdrawalID
typedef withdrawals_domain.Withdrawal Withdrawal
typedef domain.Failure Failure

struct WithdrawalState {
    1: required WithdrawalID id
    2: required Withdrawal withdrawal
    3: required Timestamp created_at
    4: optional Timestamp updated_at
    5: required WithdrawalStatus status
    // 99: required context.ContextSet ctx
}

union WithdrawalStatus {
    1: WithdrawalPending pending
    2: WithdrawalSucceeded succeeded
    3: WithdrawalFailed failed
}

struct WithdrawalPending {}
struct WithdrawalSucceeded {}
struct WithdrawalFailed {
    1: required Failure failure
}

// Events

typedef i64 EventID

struct Event {
    1: required EventID id
    2: required Timestamp occured_at
    3: required list<Change> changes
}

union Change {
    1: WithdrawalStatus status_changed
    2: SessionChange session
}

typedef base.ID SessionID

struct SessionChange {
    1: required SessionID id
    2: required SessionChangePayload payload
}

union SessionChangePayload {
    1: SessionStarted              session_started
    2: SessionFinished             session_finished
    3: SessionAdapterStateChanged  session_adapter_state_changed
}

struct SessionStarted {}

struct SessionFinished {
    1: required SessionResult result
}

union SessionResult {
    1: SessionSucceeded succeeded
    2: SessionFailed    failed
}

struct SessionSucceeded {
    1: required domain.TransactionInfo trx_info
}

struct SessionFailed {
    1: required Failure failure
}

struct SessionAdapterStateChanged {
    1: required msgpack.Value state
}

// Service

exception WithdrawalNotFound {}

service Processing {

    WithdrawalState Start (1: Withdrawal withdrawal) throws (
        // TODO
    )

    WithdrawalState Get (1: WithdrawalID id) throws (
        1: WithdrawalNotFound ex1
    )

}

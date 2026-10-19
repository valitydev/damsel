/**
 * Трейс процесса progressor.
 *
 * Общий каркас unit'а без доменных union'ов для task args.
 * События — payment_processing.EventPayload (invoice / invoice_template).
 */

namespace java dev.vality.damsel.progressor_trace
namespace erlang dmsl.progressor_trace

include "base.thrift"
include "payment_processing.thrift"

exception ProcessNotFound {}
exception UnknownNamespace {}

typedef list<TraceUnit> TraceData
typedef i64 TimestampMicroseconds

/**
 * Значение ns в конфиге progressor. Примеры HG: "invoice", "invoice_template".
 */
typedef string Namespace
typedef string TaskType
typedef string TaskStatus
typedef string TaskMetadata

struct HistoryRange {
    1: optional i64 offset
    2: optional i64 limit
    3: optional string direction
}

struct TraceTaskHeader {
    1: required i64 task_id
    2: required TaskType task_type
    3: required TaskStatus task_status
    4: optional TimestampMicroseconds scheduled
    5: optional TimestampMicroseconds running
    6: optional TimestampMicroseconds finished
    7: required i32 retry_attempts
    8: required i64 retry_interval
    9: optional TaskMetadata task_metadata
    10: optional string otel_trace_id
    11: optional string error
}

struct ThriftCall {
    1: required string service_name
    2: required string function_name
    3: required base.Content params
}

union TaskBody {
    1: ThriftCall thrift_call
    2: base.Content content
}

struct TraceEvent {
    1: required base.EventID event_id
    2: required TimestampMicroseconds event_timestamp
    3: required payment_processing.EventPayload payload
}

struct TraceUnit {
    1: required TraceTaskHeader header
    2: required TaskBody body
    3: required list<TraceEvent> events
}

service Trace {
    TraceData GetTrace (
        1: required Namespace ns,
        2: required base.ID process_id
    ) throws (
        1: ProcessNotFound ex
        2: UnknownNamespace ex2
    )
}

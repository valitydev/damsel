namespace java dev.vality.damsel.timeout_behaviour
namespace erlang dmsl.timeout_behaviour

include "base.thrift"
include "domain.thrift"

typedef base.Opaque Callback

union TimeoutBehaviour {
    /** Неуспешное завершение взаимодействия с пояснением возникшей проблемы. */
    1: domain.OperationFailure operation_failure
    /** Вызов прокси для обработки события истечения таймаута. */
    2: Callback callback
}

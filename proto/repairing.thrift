/**
 * Определения для задач "починки" различных машин.
 */

namespace java dev.vality.damsel.repairing
namespace erlang dmsl.repair

include "base.thrift"

struct ComplexAction {
    1: optional TimerAction    timer
    3: optional RemoveAction   remove
}

union TimerAction {
    1: SetTimerAction          set_timer
    2: UnsetTimerAction        unset_timer
}

struct SetTimerAction {
    1: required base.Timer     timer
}

struct UnsetTimerAction {}

struct RemoveAction {}

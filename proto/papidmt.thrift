include "domain_config.thrift"

namespace java dev.vality.damsel.papidmt
namespace erlang papidmt

struct HistoryWrapper {
    1: required domain_config.History history
}

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.proxy_inspector
namespace erlang dmsl.proxy_inspector

typedef string ID
typedef string Value

/**
 * Набор данных для взаимодействия с инспекторским прокси.
 */
struct Context {
    1: required PaymentInfo payment
    2: optional domain.ProxyOptions options = {}
}

/**
 * Набор данных для проверки в черных списках.
 */
struct BlackListContext {
    // ID первого уровня (party_id или provider_id)
    1: optional ID first_id
    // ID второго уровня (shop_id или terminal_id)
    2: optional ID second_id
    // Название проверяемого поля (CARD_TOKEN, EMAIL ...)
    3: required string field_name
    // Значение в списке
    4: required Value value
}

/**
 * Данные платежа, необходимые для инспекции платежа.
 */
struct PaymentInfo {
    1: required Shop shop
    2: required InvoicePayment payment
    3: required Invoice invoice
    4: required Party party
}

struct Party {
    1: required domain.PartyConfigRef party_ref
}

struct Shop {
    1: required domain.ShopConfigRef shop_ref
    2: required domain.Category     category
    3: required string              name
    4: optional string              description
    5: required domain.ShopLocation location
}

struct InvoicePayment {
    1: required domain.InvoicePaymentID id
    2: required base.Timestamp created_at
    3: required domain.Payer payer
    4: required domain.Cash cost
    5: optional bool make_recurrent
    6: optional domain.Allocation allocation
}

struct Invoice {
    1: required domain.InvoiceID id
    2: required base.Timestamp created_at
    3: required base.Timestamp due
    4: required domain.InvoiceDetails details
    5: optional domain.InvoiceClientInfo client_info
}

service InspectorProxy {
    domain.RiskScore InspectPayment (1: Context context)
        throws (1: base.InvalidRequest ex1)

    /**
    * Проверяет существование в черном списке
    **/
    bool IsBlacklisted(1: BlackListContext context)
        throws (1: base.InvalidRequest ex1)
}

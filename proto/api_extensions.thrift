include "base.thrift"
include "domain.thrift"
include "payment_processing.thrift"

namespace java dev.vality.damsel.api_extensions
namespace erlang dmsl.api_ext

// Based on `payment_processing.InvoiceTemplateCreateParams`
struct InvoiceTemplateCreateParams {
    1: optional string external_id
    2: required domain.PartyConfigRef party_id
    3: required domain.ShopConfigRef shop_id
    4: required domain.LifetimeInterval invoice_lifetime
    5: optional string name
    6: optional string description
    7: required domain.InvoiceTemplateDetails details
    8: required domain.InvoiceContext context
}

// Based on `payment_processing.InvoiceTemplateUpdateParams`
struct InvoiceTemplateUpdateParams {
    1: optional domain.LifetimeInterval invoice_lifetime
    2: optional string name
    3: optional string description
    4: optional domain.InvoiceTemplateDetails details
    5: optional domain.InvoiceContext context
}

struct AccessToken {
    1: required string payload
}

struct InvoiceTemplateAndToken {
    1: required domain.InvoiceTemplate invoice_template
    2: required AccessToken invoice_template_access_token
}

service InvoiceTemplating {

    InvoiceTemplateAndToken Create (1: InvoiceTemplateCreateParams params)
        throws (
            1: payment_processing.PartyNotFound ex1,
            2: payment_processing.InvalidPartyStatus ex2,
            3: payment_processing.ShopNotFound ex3,
            4: payment_processing.InvalidShopStatus ex4,
            5: base.InvalidRequest ex5
        )

    domain.InvoiceTemplate Get (2: domain.InvoiceTemplateID id)
        throws (
            1: payment_processing.InvoiceTemplateNotFound ex1,
            2: payment_processing.InvoiceTemplateRemoved ex2
        )

    domain.InvoiceTemplate Update (2: domain.InvoiceTemplateID id, 3: InvoiceTemplateUpdateParams params)
        throws (
            1: payment_processing.InvoiceTemplateNotFound ex1,
            2: payment_processing.InvoiceTemplateRemoved ex2,
            3: payment_processing.InvalidPartyStatus ex3,
            4: payment_processing.InvalidShopStatus ex4,
            5: base.InvalidRequest ex5
        )

    void Delete (2: domain.InvoiceTemplateID id)
        throws (
            1: payment_processing.InvoiceTemplateNotFound ex1,
            2: payment_processing.InvoiceTemplateRemoved ex2,
            3: payment_processing.InvalidPartyStatus ex3,
            4: payment_processing.InvalidShopStatus ex4
        )
}

typedef map<string, string> UrlParams

struct InvoiceWithTemplateParams {
    1: required domain.InvoiceTemplateID template_id
    2: optional domain.Cash cost
    3: optional domain.InvoiceContext context
    4: optional string external_id
    5: optional UrlParams url_params
}

struct InvoiceAccessToken {
    1: required string payload
}

struct InvoiceUrl {
    1: required string url
}

struct InvoiceAndToken {
    1: required domain.Invoice invoice
    2: required InvoiceAccessToken invoice_access_token
    3: required InvoiceUrl invoice_url
}

service Invoicing {

    InvoiceAndToken CreateWithTemplate (1: InvoiceWithTemplateParams params)
        throws (
            1: base.InvalidRequest ex1,
            2: payment_processing.InvalidPartyStatus ex2,
            3: payment_processing.InvalidShopStatus ex3,
            4: payment_processing.InvoiceTemplateNotFound ex4,
            5: payment_processing.InvoiceTemplateRemoved ex5,
            6: payment_processing.InvoiceTermsViolated ex6
        )
}

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.webhooker
namespace erlang dmsl.webhooker

typedef string Url
typedef string Key
typedef i64 WebhookID
typedef string SourceID
exception WebhookNotFound {}
exception SourceNotFound {}
exception LimitExceeded {}

struct Webhook {
    1: required WebhookID id
    2: required domain.PartyID party_id
    3: required EventFilter event_filter
    4: required Url url
    5: required Key pub_key
    6: required bool enabled
}

struct WebhookParams {
    1: required domain.PartyID party_id
    2: required EventFilter event_filter
    3: required Url url
}

union EventFilter {
    1: InvoiceEventFilter invoice
}

struct InvoiceEventFilter {
    1: required set<InvoiceEventType> types
    2: required domain.ShopID shop_id
}

union InvoiceEventType {
    1: InvoiceCreated created
    2: InvoiceStatusChanged status_changed
    3: InvoicePaymentEventType payment
}

struct InvoiceCreated {}
struct InvoiceStatusChanged {
    1: required InvoiceStatus value
}

union InvoiceStatus {
    1: InvoiceUnpaid unpaid
    2: InvoicePaid paid
    3: InvoiceCancelled cancelled
    4: InvoiceFulfilled fulfilled
}

struct InvoiceUnpaid    {}
struct InvoicePaid      {}
struct InvoiceCancelled {}
struct InvoiceFulfilled {}

union InvoicePaymentEventType {
    1: InvoicePaymentCreated created
    2: InvoicePaymentStatusChanged status_changed
    3: InvoicePaymentRefundChange invoice_payment_refund_change
    4: InvoicePaymentUserInteractionChange user_interaction
}

struct InvoicePaymentCreated {}
struct InvoicePaymentStatusChanged {
    1: required InvoicePaymentStatus value
}

union InvoicePaymentRefundChange {
    1: InvoicePaymentRefundCreated invoice_payment_refund_created
    2: InvoicePaymentRefundStatusChanged invoice_payment_refund_status_changed
}

struct InvoicePaymentRefundCreated {}
struct InvoicePaymentRefundStatusChanged {
    1: required InvoicePaymentRefundStatus value
}

struct InvoicePaymentUserInteractionChange {
    1: required UserInteractionStatus status
}

union UserInteractionStatus {
    1: UserInteractionStatusRequested requested
    2: UserInteractionStatusCompleted completed
}

struct UserInteractionStatusRequested {}
struct UserInteractionStatusCompleted {}

union InvoicePaymentStatus {
    1: InvoicePaymentPending pending
    4: InvoicePaymentProcessed processed
    2: InvoicePaymentCaptured captured
    5: InvoicePaymentCancelled cancelled
    3: InvoicePaymentFailed failed
    6: InvoicePaymentRefunded refunded
}

struct InvoicePaymentPending   {}
struct InvoicePaymentProcessed {}
struct InvoicePaymentCaptured  {}
struct InvoicePaymentCancelled {}
struct InvoicePaymentFailed    {}
struct InvoicePaymentRefunded  {}

union InvoicePaymentRefundStatus {
    1: InvoicePaymentRefundPending pending
    2: InvoicePaymentRefundSucceeded succeeded
    3: InvoicePaymentRefundFailed failed
}

struct InvoicePaymentRefundPending {}
struct InvoicePaymentRefundSucceeded {}
struct InvoicePaymentRefundFailed {}

service WebhookManager {
    list<Webhook> GetList(1: domain.PartyID party_id)
    Webhook Get(1: WebhookID webhook_id) throws (1: WebhookNotFound ex1)
    Webhook Create(1: WebhookParams webhook_params) throws (1: LimitExceeded ex1)
    void Delete(1: WebhookID webhook_id) throws (1: WebhookNotFound ex1)
}

service WebhookMessageService {
    void Send(1: WebhookID hook_id, 2: SourceID source_id) throws (1: WebhookNotFound ex1, 2: SourceNotFound ex2)
}

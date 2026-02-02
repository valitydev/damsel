/**
 * Определения и сервисы процессинга.
 */

include "base.thrift"
include "domain.thrift"
include "user_interaction.thrift"
include "timeout_behaviour.thrift"
include "repairing.thrift"
include "msgpack.thrift"

namespace java dev.vality.damsel.payment_processing
namespace erlang dmsl.payproc

/* Analytics */

struct InvoicePaymentExplanation {
    1: optional list<InvoicePaymentRouteExplanation> explained_routes
    2: optional Varset used_varset
}

struct InvoicePaymentRouteExplanation {
    1: required domain.PaymentRoute route
    2: required bool is_chosen
    3: optional domain.PaymentRouteScores scores
    4: optional list<TurnoverLimitValue> limits
    5: optional string rejection_description
}

/* Events */

typedef list<Event> Events

/**
 * Событие, атомарный фрагмент истории бизнес-объекта, например инвойса.
 */
struct Event {

    /**
     * Идентификатор события.
     * Монотонно возрастающее целочисленное значение, таким образом на множестве
     * событий задаётся отношение полного порядка (total order).
     */
    1: required base.EventID id

    /**
     * Время создания события.
     */
    2: required base.Timestamp created_at

    /**
     * Идентификатор бизнес-объекта, источника события.
     */
    3: required EventSource source

    /**
     * Содержание события, состоящее из списка (возможно пустого)
     * изменений состояния бизнес-объекта, источника события.
     */
    4: required EventPayload payload

    /**
     * Идентификатор события в рамках одной машины.
     * Монотонно возрастающее целочисленное значение.
     */
    5: optional base.SequenceID sequence
}

/**
 * Источник события, идентификатор бизнес-объекта, который породил его в
 * процессе выполнения определённого бизнес-процесса.
 */
union EventSource {
    /** Идентификатор инвойса, который породил событие. */
    1: domain.InvoiceID         invoice_id
    /** Идентификатор шаблона инвойса, который породил событие. */
    2: domain.InvoiceTemplateID invoice_template_id
}

/**
 * Один из возможных вариантов содержания события.
 */
union EventPayload {
    /** Набор изменений, порождённых инвойсом. */
    1: list<InvoiceChange>          invoice_changes
    /** Набор изменений, порождённых шаблоном инвойса. */
    2: list<InvoiceTemplateChange>  invoice_template_changes
}

/**
 * Один из возможных вариантов события, порождённого инвойсом.
 */
union InvoiceChange {
    1: InvoiceCreated          invoice_created
    2: InvoiceStatusChanged    invoice_status_changed
    3: InvoicePaymentChange    invoice_payment_change
}

union InvoiceTemplateChange {
    1: InvoiceTemplateCreated invoice_template_created
    2: InvoiceTemplateUpdated invoice_template_updated
    3: InvoiceTemplateDeleted invoice_template_deleted
}

/**
 * Событие о создании нового инвойса.
 */
struct InvoiceCreated {
    /** Данные созданного инвойса. */
    1: required domain.Invoice invoice
}

/**
 * Событие об изменении статуса инвойса.
 */
struct InvoiceStatusChanged {
    /** Новый статус инвойса. */
    1: required domain.InvoiceStatus status
}

/**
 * Событие, касающееся определённого платежа по инвойсу.
 */
struct InvoicePaymentChange {
    1: required domain.InvoicePaymentID id
    2: required InvoicePaymentChangePayload payload
    3: optional base.Timestamp occurred_at
}

/**
 * Один из возможных вариантов события, порождённого платежом по инвойсу.
 */
union InvoicePaymentChangePayload {
    1: InvoicePaymentStarted                invoice_payment_started
    8: InvoicePaymentRiskScoreChanged       invoice_payment_risk_score_changed
    9: InvoicePaymentRouteChanged           invoice_payment_route_changed
    10: InvoicePaymentCashFlowChanged       invoice_payment_cash_flow_changed
    3: InvoicePaymentStatusChanged          invoice_payment_status_changed
    2: InvoicePaymentSessionChange          invoice_payment_session_change
    7: InvoicePaymentRefundChange           invoice_payment_refund_change
    6: InvoicePaymentAdjustmentChange       invoice_payment_adjustment_change
    11: InvoicePaymentRecTokenAcquired      invoice_payment_rec_token_acquired
    12: InvoicePaymentCaptureStarted        invoice_payment_capture_started
    13: InvoicePaymentChargebackChange      invoice_payment_chargeback_change
    14: InvoicePaymentRollbackStarted       invoice_payment_rollback_started
    15: InvoicePaymentClockUpdate           invoice_payment_clock_update
    16: InvoicePaymentCashChanged           invoice_payment_cash_changed
    17: InvoicePaymentShopLimitInitiated    invoice_payment_shop_limit_initiated
    18: InvoicePaymentShopLimitApplied      invoice_payment_shop_limit_applied
}

/**
 * Событие об запуске платежа по инвойсу.
 */
struct InvoicePaymentStarted {
    /** Данные запущенного платежа. */
    1: required domain.InvoicePayment payment

    /** deprecated */
    /** Оценка риска платежа. */
    4: optional domain.RiskScore risk_score
    /** Выбранный маршрут обработки платежа. */
    2: optional domain.PaymentRoute route
    /** Данные финансового взаимодействия. */
    3: optional domain.FinalCashFlow cash_flow
}

struct InvoicePaymentCashChanged {
    1: required domain.Cash old_cash
    2: required domain.Cash new_cash
}

struct InvoicePaymentShopLimitInitiated {}

struct InvoicePaymentShopLimitApplied {}

struct InvoicePaymentClockUpdate {
    1: required domain.AccounterClock clock
}

struct InvoicePaymentRollbackStarted {
    1: required domain.OperationFailure reason
}

/**
 * Событие об изменении оценки риска платежа.
 */
struct InvoicePaymentRiskScoreChanged {
    /** Оценка риска платежа. */
    1: required domain.RiskScore risk_score
}

/**
 * Событие об изменении маршрута обработки платежа.
 */
struct InvoicePaymentRouteChanged {
    /** Выбранный маршрут обработки платежа. */
    1: required domain.PaymentRoute route
    2: optional set<domain.PaymentRoute> candidates
    3: optional map<domain.PaymentRoute, domain.PaymentRouteScores> scores
    4: optional RouteLimitContext limits
    5: optional RouteDecisionContext decision
}

/**
 * Событие об изменении данных финансового взаимодействия.
 */
struct InvoicePaymentCashFlowChanged {
    /** Данные финансового взаимодействия. */
    1: required domain.FinalCashFlow cash_flow
}

/**
 * Событие об изменении статуса платежа по инвойсу.
 */
struct InvoicePaymentStatusChanged {
    /** Статус платежа по инвойсу. */
    1: required domain.InvoicePaymentStatus status
}

/**
 * Событие в рамках сессии взаимодействия с провайдером.
 */
struct InvoicePaymentSessionChange {
    1: required domain.TargetInvoicePaymentStatus target
    2: required SessionChangePayload payload
}

/**
 * Один из возможных вариантов события, порождённого сессией взаимодействия.
 */
union SessionChangePayload {
    1: SessionStarted              session_started
    2: SessionFinished             session_finished
    3: SessionSuspended            session_suspended
    4: SessionActivated            session_activated
    5: SessionTransactionBound     session_transaction_bound
    6: SessionProxyStateChanged    session_proxy_state_changed
    7: SessionInteractionChanged   session_interaction_changed
}

struct SessionStarted {}

struct SessionFinished {
    1: required SessionResult result
}

struct SessionSuspended {
    1: optional base.Tag tag
    2: optional timeout_behaviour.TimeoutBehaviour timeout_behaviour
}

struct SessionActivated {}

union SessionResult {
    1: SessionSucceeded succeeded
    2: SessionFailed    failed
}

struct SessionSucceeded {}

struct SessionFailed {
    1: required domain.OperationFailure failure
}

/**
 * Событие о создании нового шаблона инвойса.
 */
struct InvoiceTemplateCreated {
    /** Данные созданного шаблона инвойса. */
    1: required domain.InvoiceTemplate invoice_template
}

/**
 * Событие о модификации шаблона инвойса.
 */
struct InvoiceTemplateUpdated {
    /** Данные модифицированного шаблона инвойса. */
    1: required InvoiceTemplateUpdateParams diff
}

/**
 * Событие об удалении шаблона инвойса.
 */
struct InvoiceTemplateDeleted {}

/**
 * Событие о том, что появилась связь между платежом по инвойсу и транзакцией
 * у провайдера.
 */
struct SessionTransactionBound {
    /** Данные о связанной транзакции у провайдера. */
    1: required domain.TransactionInfo trx
}

/**
 * Событие о том, что изменилось непрозрачное состояние прокси в рамках сессии.
 */
struct SessionProxyStateChanged {
    1: required base.Opaque proxy_state
}

/**
 * Событие о взаимодействии с плательщиком.
 */
struct SessionInteractionChanged {
    /** Необходимое взаимодействие */
    1: required user_interaction.UserInteraction interaction
    /**
     * Статус этого взаимодействия.
     * Если не указан, статус считается по умолчанию _requested_.
     */
    2: optional user_interaction.Status status
}

/**
 * Событие, касающееся определённого чарджбека.
 */
struct InvoicePaymentChargebackChange {
    1: required domain.InvoicePaymentChargebackID id
    2: required InvoicePaymentChargebackChangePayload payload
    3: optional base.Timestamp occurred_at
}

/**
 * Один из возможных вариантов события, порождённого чарджбеком платежа по инвойсу.
 */
union InvoicePaymentChargebackChangePayload {
    1: InvoicePaymentChargebackCreated              invoice_payment_chargeback_created
    2: InvoicePaymentChargebackStatusChanged        invoice_payment_chargeback_status_changed
    3: InvoicePaymentChargebackCashFlowChanged      invoice_payment_chargeback_cash_flow_changed
    4: InvoicePaymentChargebackBodyChanged          invoice_payment_chargeback_body_changed
    5: InvoicePaymentChargebackLevyChanged          invoice_payment_chargeback_levy_changed
    6: InvoicePaymentChargebackStageChanged         invoice_payment_chargeback_stage_changed
    7: InvoicePaymentChargebackTargetStatusChanged  invoice_payment_chargeback_target_status_changed
    8: InvoicePaymentClockUpdate                    invoice_payment_chargeback_clock_update
}

/**
 * Событие о создании чарджбека
 */
struct InvoicePaymentChargebackCreated {
    1: required domain.InvoicePaymentChargeback chargeback
}

/**
 * Событие об изменении статуса чарджбека
 */
struct InvoicePaymentChargebackStatusChanged {
    1: required domain.InvoicePaymentChargebackStatus status
}

/**
 * Событие об изменении кэшфлоу чарджбека
 */
struct InvoicePaymentChargebackCashFlowChanged {
    1: required domain.FinalCashFlow cash_flow
}

/**
 * Событие об изменении объёма чарджбека
 */
struct InvoicePaymentChargebackBodyChanged {
    1: required domain.Cash body
}

/**
 * Событие об изменении размера списываемых средств у чарджбека
 */
struct InvoicePaymentChargebackLevyChanged {
    2: required domain.Cash levy
}

/**
 * Событие об изменении стадии чарджбека
 */
struct InvoicePaymentChargebackStageChanged {
    1: required domain.InvoicePaymentChargebackStage stage
}

/**
 * Событие об изменении целевого статуса чарджбека
 */
struct InvoicePaymentChargebackTargetStatusChanged {
    1: required domain.InvoicePaymentChargebackStatus status
}

/**
 * Событие, касающееся определённого возврата платежа.
 */
struct InvoicePaymentRefundChange {
    1: required domain.InvoicePaymentRefundID id
    2: required InvoicePaymentRefundChangePayload payload
}

/**
 * Один из возможных вариантов события, порождённого возратом платежа по инвойсу.
 */
union InvoicePaymentRefundChangePayload {
    1: InvoicePaymentRefundCreated         invoice_payment_refund_created
    2: InvoicePaymentRefundStatusChanged   invoice_payment_refund_status_changed
    3: InvoicePaymentSessionChange         invoice_payment_session_change
    4: InvoicePaymentRefundRollbackStarted invoice_payment_refund_rollback_started
    5: InvoicePaymentClockUpdate           invoice_payment_refund_clock_update
}

/**
 * Событие о создании возврата платежа
 */
struct InvoicePaymentRefundCreated {
    1: required domain.InvoicePaymentRefund refund
    2: required domain.FinalCashFlow cash_flow

    /**
    * Данные проведённой вручную транзакции.
    * В случае присутствия при обработке возврата этап обращения к адаптеру будет пропущен,
    * а эти данные будут использованы в качестве результата
    */
    3: optional domain.TransactionInfo transaction_info
}

/**
 * Событие об изменении статуса возврата платежа
 */
struct InvoicePaymentRefundStatusChanged {
    1: required domain.InvoicePaymentRefundStatus status
}

struct InvoicePaymentRefundRollbackStarted {
    1: required domain.OperationFailure reason
}

/**
 * Событие, касающееся определённой корректировки платежа.
 */
struct InvoicePaymentAdjustmentChange {
    1: required domain.InvoicePaymentAdjustmentID id
    2: required InvoicePaymentAdjustmentChangePayload payload
}

/**
 * Один из возможных вариантов события, порождённого корректировкой платежа по инвойсу.
 */
union InvoicePaymentAdjustmentChangePayload {
    1: InvoicePaymentAdjustmentCreated       invoice_payment_adjustment_created
    2: InvoicePaymentAdjustmentStatusChanged invoice_payment_adjustment_status_changed
    3: InvoicePaymentClockUpdate             invoice_payment_adjustment_clock_update
}

/**
 * Событие о создании корректировки платежа
 */
struct InvoicePaymentAdjustmentCreated {
    1: required domain.InvoicePaymentAdjustment adjustment
}

/**
 * Событие об изменении статуса корректировки платежа
 */
struct InvoicePaymentAdjustmentStatusChanged {
    1: required domain.InvoicePaymentAdjustmentStatus status
}

/**
 * Событие о полуечнии рекуррентного токена
 */
struct InvoicePaymentRecTokenAcquired {
    1: required domain.Token token
}

struct InvoicePaymentCaptureStarted {
    1: required InvoicePaymentCaptureData data
}

/**
 * Диапазон для выборки событий.
 */
struct EventRange {

    /**
     * Идентификатор события, за которым должны следовать попадающие в выборку
     * события.
     *
     * Если `after` не указано, в выборку попадут события с начала истории; если
     * указано, например, `42`, то в выборку попадут события, случившиеся _после_
     * события `42`.
     */
    1: optional base.EventID after

    /**
     * Максимальное количество событий в выборке.
     *
     * В выборку может попасть количество событий, _не больше_ указанного в
     * `limit`. Если в выборку попало событий _меньше_, чем значение `limit`,
     * был достигнут конец текущей истории.
     *
     * _Допустимые значения_: неотрицательные числа
     */
    2: optional i32 limit

}

/* Invoicing service definitions */

typedef domain.InvoiceMutationParams InvoiceMutationParams

struct InvoiceParams {
    1: required domain.PartyConfigRef party_id
    2: required domain.ShopConfigRef shop_id
    3: required domain.InvoiceDetails details
    4: required base.Timestamp due
    5: required domain.Cash cost
    6: required domain.InvoiceContext context
    7: required domain.InvoiceID id
    8: optional string external_id
    9: optional domain.InvoiceClientInfo client_info
    10: optional domain.AllocationPrototype allocation
    11: optional list<InvoiceMutationParams> mutations
}

struct InvoiceWithTemplateParams {
    1: required domain.InvoiceTemplateID template_id
    2: optional domain.Cash cost
    3: optional domain.InvoiceContext context
    4: required domain.InvoiceID id
    5: optional string external_id
}

struct InvoiceTemplateCreateParams {
    10: required domain.InvoiceTemplateID      template_id
    1:  required domain.PartyConfigRef         party_id
    2:  required domain.ShopConfigRef          shop_id
    4:  required domain.LifetimeInterval       invoice_lifetime
    7:  required string                        product # for backward compatibility
    11: optional string                        name
    8:  optional string                        description
    9:  required domain.InvoiceTemplateDetails details
    6:  required domain.InvoiceContext         context
    12: optional list<InvoiceMutationParams>   mutations
}

struct InvoiceTemplateUpdateParams {
    2: optional domain.LifetimeInterval invoice_lifetime
    5: optional string product # for backward compatibility
    8: optional string name
    6: optional string description
    7: optional domain.InvoiceTemplateDetails details
    4: optional domain.InvoiceContext context
    9: optional list<InvoiceMutationParams> mutations
}

struct InvoicePaymentParams {
    1: required PayerParams payer
    8: optional domain.PayerSessionInfo payer_session_info
    2: required InvoicePaymentParamsFlow flow
    3: optional bool make_recurrent
    4: optional domain.InvoicePaymentID id
    5: optional string external_id
    6: optional domain.InvoicePaymentContext context
    7: optional base.Timestamp processing_deadline
}

struct RegisterInvoicePaymentParams {
    1: required PayerParams payer_params
    2: required domain.PaymentRoute route
    3: required domain.TransactionInfo transaction_info
    4: optional domain.Cash cost
    5: optional domain.PayerSessionInfo payer_session_info
    6: optional domain.InvoicePaymentID id
    7: optional string external_id
    8: optional domain.InvoicePaymentContext context
    9: optional domain.RiskScore risk_score
    10: optional base.Timestamp occurred_at
    11: optional domain.Token recurrent_token
}

union PayerParams {
    1: PaymentResourcePayerParams payment_resource
    2: RecurrentPayerParams recurrent
}

struct PaymentResourcePayerParams {
    1: required domain.DisposablePaymentResource resource
    2: required domain.ContactInfo               contact_info
}

struct RecurrentPayerParams{
    1: required domain.RecurrentParentPayment recurrent_parent
    2: required domain.ContactInfo            contact_info
}

union InvoicePaymentParamsFlow {
    1: InvoicePaymentParamsFlowInstant instant
    2: InvoicePaymentParamsFlowHold hold
}

struct InvoicePaymentParamsFlowInstant {}

struct InvoicePaymentParamsFlowHold {
    1: required domain.OnHoldExpiration on_hold_expiration
}

struct Invoice {
    3: required base.EventID latest_event_id
    1: required domain.Invoice invoice
    2: required list<InvoicePayment> payments
}

struct InvoicePayment {
    1: required domain.InvoicePayment payment
    6: optional domain.PaymentRoute route
    7: optional FinalCashFlow cash_flow
    2: required list<InvoicePaymentAdjustment> adjustments
    4: required list<InvoicePaymentRefund> refunds
    5: required list<InvoicePaymentSession> sessions
    8: optional list<InvoicePaymentChargeback> chargebacks
    9: optional domain.TransactionInfo last_transaction_info
    11: optional domain.Allocation allocation
    # deprecated
    3: required list<domain.InvoicePaymentRefund> legacy_refunds
}

struct InvoicePaymentRefund {
    1: required domain.InvoicePaymentRefund refund
    2: required list<InvoiceRefundSession> sessions
    3: optional FinalCashFlow cash_flow
}

struct InvoicePaymentSession {
    1: required domain.TargetInvoicePaymentStatus target_status
    2: optional domain.TransactionInfo transaction_info
}

struct InvoiceRefundSession {
    1: optional domain.TransactionInfo transaction_info
}

typedef domain.InvoicePaymentAdjustment InvoicePaymentAdjustment

struct InvoicePaymentChargeback {
    1: required domain.InvoicePaymentChargeback chargeback
    2: optional FinalCashFlow cash_flow
}

/**
 * Параметры создаваемого чарджбэка.
 */
struct InvoicePaymentChargebackParams {
    /**
     * Идентификатор чарджбэка
     */
    5: required domain.InvoicePaymentChargebackID id
    /**
    * Код причины чарджбэка
    */
    1: required domain.InvoicePaymentChargebackReason reason

    /**
     * Сумма списания: количество денежных средств, подлежащих удержанию
     * со счёта продавца.
     */
    2: required domain.Cash levy
    /**
     * Размер опротестования.
     * Если не указан, то считаем, что это возврат на полную сумму платежа.
     * Не может быть больше суммы платежа.
     */
    3: optional domain.Cash body
    /**
     * Данные проведённой вручную транзакции
     */
    4: optional domain.TransactionInfo transaction_info
    /**
     * Внешний идентификатор объекта
     */
    6: optional string external_id
    /**
     * Дополнительные метаданные по чарджбэку
     */
    7: optional domain.InvoicePaymentChargebackContext context
    /**
     * Фактическое время создания
     */
    8: optional base.Timestamp occurred_at
}

struct InvoicePaymentChargebackAcceptParams {
    /**
     * Сумма возврата.
     * Если сумма не указана, то текущая сумма не меняется
     */
    1: optional domain.Cash body
    /**
     * Сумма списания.
     * Если сумма не указана, то текущая сумма не меняется
     */
    2: optional domain.Cash levy
    /**
     * Фактическое время принятия
     */
    3: optional base.Timestamp occurred_at
}

struct InvoicePaymentChargebackReopenParams {
    /**
     * Сумма возврата.
     * Если сумма не указана, то текущая сумма не меняется
     */
    1: optional domain.Cash body

    /**
     * Сумма списания.
     */
    2: optional domain.Cash levy
    /**
     * Фактическое время опротестования
     */
    3: optional base.Timestamp occurred_at
    /**
     * Возможность переместить стадию
     */
    4: optional domain.InvoicePaymentChargebackStage move_to_stage
}

struct InvoicePaymentChargebackRejectParams {
    /**
     * Сумма списания.
     */
    1: optional domain.Cash levy
    /**
     * Фактическое время отклонения
     */
    8: optional base.Timestamp occurred_at
}

struct InvoicePaymentChargebackCancelParams {
    /**
     * Фактическое время отмены
     */
    1: optional base.Timestamp occurred_at
}

typedef domain.FinalCashFlow FinalCashFlow

/**
 * Параметры создаваемого возврата платежа.
 */
struct InvoicePaymentRefundParams {
    /** Причина, на основании которой производится возврат. */
    1: optional string reason
    /**
     * Сумма возврата.
     * Если сумма не указана, то считаем, что это возврат на полную сумму платежа.
     */
    2: optional domain.Cash cash
    /**
     * Данные проведённой вручную транзакции
     */
    3: optional domain.TransactionInfo transaction_info
    /**
     * Итоговая корзина товаров.
     * Используется для частичного возврата, содержит позиции, которые остались после возврата.
     */
    4: optional domain.InvoiceCart cart
    /**
     * Идентификатор рефанда
     */
    5: optional domain.InvoicePaymentRefundID id
    /**
     * Внешний идентификатор объекта
     */
    6: optional string external_id
    /**
     * Распределение денежных средств возврата.
     * Используется при частичном возврате, содержит транзакции, которые нужно вернуть.
     */
    7: optional domain.AllocationPrototype allocation
}

/**
 * Параметры подтверждаемого платежа.
 */
struct InvoicePaymentCaptureParams {
    /** Причина совершения операции. */
    1: required string reason
    /**
     * Подтверждаемая сумма.
     * Если сумма не указана, то считаем, что подтверждаем полную сумму платежа.
     */
    2: optional domain.Cash cash
    3: optional domain.InvoiceCart cart
    4: optional domain.AllocationPrototype allocation
}

struct InvoicePaymentCaptureData {
    1: required string reason
    2: optional domain.Cash cash
    3: optional domain.InvoiceCart cart
    4: optional domain.Allocation allocation
}

/**
 * Параметры создаваемой поправки к платежу.
 */
struct InvoicePaymentAdjustmentParams {
    /** Причина, на основании которой создаётся поправка. */
    2: required string reason
    /** Сценарий создаваемой поправки. */
    3: required InvoicePaymentAdjustmentScenario scenario
}

/**
 * Сценарий поправки к платежу.
 */
union InvoicePaymentAdjustmentScenario {
    1: domain.InvoicePaymentAdjustmentCashFlow cash_flow
    2: domain.InvoicePaymentAdjustmentStatusChange status_change
}

/* Сценарий, проверяющий состояние упавшей машины и, в случае если
   платеж упал раньше похода к провайдеру, начинает процедуру корректного
   завершения, используя заданную ошибку*/

struct InvoiceRepairFailPreProcessing {
    1:  required domain.Failure failure
}

/* Сценарий, позволяющий пропустить испекцию платежа, подменив ее результат заданым. */

struct InvoiceRepairSkipInspector {
    1:  required domain.RiskScore risk_score
}

/* Сценарий, позволяющий сымитировать отрицательный результат похода к адаптеру */

struct InvoiceRepairFailSession {
    1:  required domain.Failure failure
    2:  optional domain.TransactionInfo trx
}

/*  Сценарий, позволяющий сымитировать положительный результат похода к адаптеру */

struct InvoiceRepairFulfillSession {
    1:  optional domain.TransactionInfo trx
}

/* Комбинированная структура */

struct InvoiceRepairComplex {
    1:  required list<InvoiceRepairScenario> scenarios
}

union InvoiceRepairScenario{
    1: InvoiceRepairComplex complex
    2: InvoiceRepairFailPreProcessing fail_pre_processing
    3: InvoiceRepairSkipInspector skip_inspector
    4: InvoiceRepairFailSession fail_session
    5: InvoiceRepairFulfillSession fulfill_session
}

/* Параметры adhoc починки упавшей машины. */
struct InvoiceRepairParams {
    1: optional bool validate_transitions = true
}

/* Значение лимита. */
struct TurnoverLimitValue {
    1:  required domain.TurnoverLimit limit
    2:  required domain.Amount value
}

typedef map<domain.PaymentRoute, list<TurnoverLimitValue>> RouteLimitContext

struct RouteDecisionContext {
    1:  optional bool skip_recurrent
}

// Exceptions

// forward-declared
exception PartyNotFound {}
exception PartyNotExistsYet {}

exception ShopNotFound {}
exception WalletNotFound {}

exception InvalidPartyStatus { 1: required InvalidStatus status }
exception InvalidShopStatus { 1: required InvalidStatus status }
exception InvalidWalletStatus { 1: required InvalidStatus status }

union InvalidStatus {
    1: domain.Blocking blocking
    2: domain.Suspension suspension
}

exception RouteNotChosen {}

exception InvoiceNotFound {}

exception InvoicePaymentNotFound {}
exception InvoicePaymentRefundNotFound {}

exception InvoicePaymentChargebackNotFound {}
exception InvoicePaymentChargebackCannotReopenAfterArbitration {}
exception InvoicePaymentChargebackInvalidStage {
    1: required domain.InvoicePaymentChargebackStage stage
}
exception InvoicePaymentChargebackInvalidStatus {
    1: required domain.InvoicePaymentChargebackStatus status
}

exception InvoicePaymentAdjustmentNotFound {}

exception EventNotFound {}
exception OperationNotPermitted {}
exception InsufficientAccountBalance {}
exception InvalidRecurrentParentPayment {
    1: optional string details
}

exception InvoicePaymentPending {
    1: required domain.InvoicePaymentID id
}

exception InvoicePaymentRefundPending {
    1: required domain.InvoicePaymentRefundID id
}

exception InvoicePaymentAdjustmentPending {
    1: required domain.InvoicePaymentAdjustmentID id
}

exception InvalidInvoiceStatus {
    1: required domain.InvoiceStatus status
}

exception InvalidPaymentStatus {
    1: required domain.InvoicePaymentStatus status
}

exception InvalidPaymentTargetStatus {
    1: required domain.InvoicePaymentStatus status
}

exception InvoiceAlreadyHasStatus {
    1: required domain.InvoiceStatus status
}

exception InvoicePaymentAlreadyHasStatus {
    1: required domain.InvoicePaymentStatus status
}

exception InvalidPaymentAdjustmentStatus {
    1: required domain.InvoicePaymentAdjustmentStatus status
}

exception InvoiceTemplateNotFound {}
exception InvoiceTemplateRemoved {}

struct InvoiceUnpayable {}

struct InvoiceUnallocatable {}

union InvoiceTermsViolationReason {
    1: InvoiceUnpayable invoice_unpayable,
    2: InvoiceUnallocatable invoice_unallocatable
}

exception InvoiceTermsViolated {
    1: required InvoiceTermsViolationReason reason
}

exception InvoicePaymentAmountExceeded {
    1: required domain.Cash maximum
}

exception InconsistentRefundCurrency {
    1: required domain.CurrencySymbolicCode currency
}

exception InconsistentChargebackCurrency {
    1: required domain.CurrencySymbolicCode currency
}

exception InconsistentCaptureCurrency {
    1: required domain.CurrencySymbolicCode payment_currency
    2: optional domain.CurrencySymbolicCode passed_currency
}

exception AmountExceededCaptureBalance {
    1: required domain.Amount payment_amount
    2: optional domain.Amount passed_amount
}

exception InvoicePaymentChargebackPending {}

exception AllocationNotAllowed {}

exception AllocationExceededPaymentAmount {}

exception AllocationInvalidTransaction {
    1: required FailedAllocationTransaction transaction
    2: required string reason
}

union FailedAllocationTransaction {
    1: domain.AllocationTransaction transaction
    2: domain.AllocationTransactionPrototype transaction_prototype
}

exception AllocationNotFound {}

// @NOTE: Argument and exception tags start with 2 for historical reasons

service Invoicing {

    Invoice Create (2: InvoiceParams params)
        throws (
            2: base.InvalidRequest ex2,
            3: PartyNotFound ex3,
            4: ShopNotFound ex4,
            5: InvalidPartyStatus ex5,
            6: InvalidShopStatus ex6,
            8: InvoiceTermsViolated ex8,
            9: AllocationNotAllowed ex9,
            10: AllocationExceededPaymentAmount ex10,
            11: AllocationInvalidTransaction ex11
        )

    Invoice CreateWithTemplate (2: InvoiceWithTemplateParams params)
        throws (
            2: base.InvalidRequest ex2,
            3: InvalidPartyStatus ex3,
            4: InvalidShopStatus ex4,
            6: InvoiceTemplateNotFound ex6,
            7: InvoiceTemplateRemoved ex7,
            8: InvoiceTermsViolated ex8
        )

    Invoice Get (2: domain.InvoiceID id, 3: EventRange range)
        throws (
            2: InvoiceNotFound ex2
        )

    Events GetEvents (2: domain.InvoiceID id, 3: EventRange range)
        throws (
            2: InvoiceNotFound ex2,
            3: EventNotFound ex3,
            4: base.InvalidRequest ex4
        )

    /* Аnalytics */

    InvoicePaymentExplanation ExplainRoute (
        1: domain.InvoiceID invoice_id,
        2: domain.InvoicePaymentID payment_id
    )
        throws (
            1: InvoiceNotFound ex1,
            2: InvoicePaymentNotFound ex2,
            3: RouteNotChosen ex3
        )

    /* Terms */

    domain.TermSet ComputeTerms (
        2: domain.InvoiceID id
    )
        throws (
            2: InvoiceNotFound ex2
        )

    /* Payments */

    InvoicePayment StartPayment (
        2: domain.InvoiceID id,
        3: InvoicePaymentParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvalidInvoiceStatus ex3,
            4: InvoicePaymentPending ex4,
            5: base.InvalidRequest ex5,
            6: InvalidPartyStatus ex6,
            7: InvalidShopStatus ex7,
            9: InvalidRecurrentParentPayment ex9,
            10: OperationNotPermitted ex10
        )

    InvoicePayment RegisterPayment (
        2: domain.InvoiceID id,
        3: RegisterInvoicePaymentParams params
    )
        throws (
            1: InvoiceNotFound ex1,
            2: InvalidInvoiceStatus ex2,
            3: base.InvalidRequest ex3,
            4: InvalidPartyStatus ex4,
            5: InvalidShopStatus ex5,
            8: InvalidRecurrentParentPayment ex9
        )

    InvoicePayment GetPayment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3
        )

    void CancelPayment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: string reason
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            5: base.InvalidRequest ex5,
            6: OperationNotPermitted ex6,
            7: InvalidPartyStatus ex7,
            8: InvalidShopStatus ex8
        )

    void CapturePayment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: InvoicePaymentCaptureParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            5: base.InvalidRequest ex5,
            6: OperationNotPermitted ex6,
            7: InvalidPartyStatus ex7,
            8: InvalidShopStatus ex8,
            9: InconsistentCaptureCurrency ex9,
            10: AmountExceededCaptureBalance ex10,
            11: AllocationNotAllowed ex11,
            12: AllocationExceededPaymentAmount ex12,
            13: AllocationInvalidTransaction ex13
        )

    void CapturePaymentNew (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: InvoicePaymentCaptureParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            5: base.InvalidRequest ex5,
            6: OperationNotPermitted ex6,
            7: InvalidPartyStatus ex7,
            8: InvalidShopStatus ex8,
            9: InconsistentCaptureCurrency ex9,
            10: AmountExceededCaptureBalance ex10,
            11: AllocationNotAllowed ex11,
            12: AllocationExceededPaymentAmount ex12,
            13: AllocationInvalidTransaction ex13
        )
    /**
     * Создать поправку к платежу.
     *
     * После создания поправку необходимо либо подтвердить, если её эффекты
     * соответствуют ожиданиям, либо отклонить в противном случае (по аналогии с
     * заявками).
     * Пока созданная поправка ни подтверждена, ни отклонена, другую поправку
     * создать невозможно.
     */
    InvoicePaymentAdjustment CreatePaymentAdjustment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id,
        4: InvoicePaymentAdjustmentParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            5: InvoicePaymentAdjustmentPending ex5
            6: InvalidPaymentTargetStatus ex6
            7: InvoicePaymentAlreadyHasStatus ex7
            8: base.InvalidRequest ex8
        )

    InvoicePaymentAdjustment GetPaymentAdjustment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentAdjustmentID adjustment_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvoicePaymentAdjustmentNotFound ex4
        )

    void CapturePaymentAdjustment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentAdjustmentID adjustment_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvoicePaymentAdjustmentNotFound ex4,
            5: InvalidPaymentAdjustmentStatus ex5
        )

    void CancelPaymentAdjustment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentAdjustmentID adjustment_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvoicePaymentAdjustmentNotFound ex4,
            5: InvalidPaymentAdjustmentStatus ex5
        )

    /**
     * Создать чарджбэк
     */
    domain.InvoicePaymentChargeback CreateChargeback (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: InvoicePaymentChargebackParams params
    )
        throws (
            2:  InvoiceNotFound ex2,
            3:  InvoicePaymentNotFound ex3,
            4:  InvalidPaymentStatus ex4,
            6:  OperationNotPermitted ex6,
            7:  InsufficientAccountBalance ex7,
            8:  InvoicePaymentAmountExceeded ex8
            9:  InconsistentChargebackCurrency ex9,
            11: InvoicePaymentChargebackInvalidStatus ex11
            14: InvoicePaymentChargebackPending ex14
            /* something else? */
        )

    /**
     * Найти чарджбэк
     */
    domain.InvoicePaymentChargeback GetPaymentChargeback (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentChargebackID chargeback_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvoicePaymentChargebackNotFound ex4
        )

    /**
     * Принять чарджбэк
     */
    void AcceptChargeback (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentChargebackID chargeback_id
        5: InvoicePaymentChargebackAcceptParams params
    )
        throws (
            2:  InvoiceNotFound ex2,
            3:  InvoicePaymentNotFound ex3,
            4:  InvoicePaymentChargebackNotFound ex4
            6:  OperationNotPermitted ex6,
            8:  InvoicePaymentAmountExceeded ex8
            9:  InconsistentChargebackCurrency ex9,
            11: InvoicePaymentChargebackInvalidStatus ex11
        )

    /**
     * Отклонить чарджбэк
     */
    void RejectChargeback (
        2: domain.InvoiceID id
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentChargebackID chargeback_id
        5: InvoicePaymentChargebackRejectParams params
    )
        throws (
            2:  InvoiceNotFound ex2,
            3:  InvoicePaymentNotFound ex3,
            4:  InvoicePaymentChargebackNotFound ex4
            6:  OperationNotPermitted ex6,
            9:  InconsistentChargebackCurrency ex9,
            11: InvoicePaymentChargebackInvalidStatus ex11
        )

    /**
     * Открыть чарджбэк заново. Переход возможен из отклонённого состояния,
     * если покупатель не согласен с результатом и хочет его оспорить.
     */
    void ReopenChargeback (
        2: domain.InvoiceID id
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentChargebackID chargeback_id
        5: InvoicePaymentChargebackReopenParams params
    )
        throws (
            2:  InvoiceNotFound ex2
            3:  InvoicePaymentNotFound ex3
            4:  InvoicePaymentChargebackNotFound ex4
            6:  OperationNotPermitted ex6
            8:  InvoicePaymentAmountExceeded ex8
            9:  InconsistentChargebackCurrency ex9,
            11: InvoicePaymentChargebackInvalidStatus ex11
            13: InvoicePaymentChargebackCannotReopenAfterArbitration ex13
            14: InvoicePaymentChargebackInvalidStage ex14
        )

    /**
     * Отмена чарджбэка. Комиссия с мерчанта не взимается.
     */
    void CancelChargeback (
        2: domain.InvoiceID id
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentChargebackID chargeback_id
        5: InvoicePaymentChargebackCancelParams params
    )
        throws (
            2:  InvoiceNotFound ex2
            3:  InvoicePaymentNotFound ex3
            4:  InvoicePaymentChargebackNotFound ex4
            11: InvoicePaymentChargebackInvalidStatus ex11
            15: InvoicePaymentChargebackInvalidStage ex15
        )

    /**
     * Сделать возврат платежа.
     */
    domain.InvoicePaymentRefund RefundPayment (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: InvoicePaymentRefundParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            6: OperationNotPermitted ex6,
            7: InsufficientAccountBalance ex7,
            8: base.InvalidRequest ex8,
            9: InvoicePaymentAmountExceeded ex9,
            10: InconsistentRefundCurrency ex10,
            11: InvalidPartyStatus ex11,
            12: InvalidShopStatus ex12,
            14: InvoicePaymentChargebackPending ex14,
            15: AllocationNotAllowed ex15,
            16: AllocationExceededPaymentAmount ex16,
            17: AllocationInvalidTransaction ex17,
            18: AllocationNotFound ex18
        )


    /**
     * Сделать ручной возврат.
     */
    domain.InvoicePaymentRefund CreateManualRefund (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: InvoicePaymentRefundParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvalidPaymentStatus ex4,
            6: OperationNotPermitted ex6,
            7: InsufficientAccountBalance ex7,
            8: InvoicePaymentAmountExceeded ex8,
            9: InconsistentRefundCurrency ex9,
            10: InvalidPartyStatus ex10,
            11: InvalidShopStatus ex11,
            13: base.InvalidRequest ex13,
            14: InvoicePaymentChargebackPending ex14,
            15: AllocationNotAllowed ex15,
            16: AllocationExceededPaymentAmount ex16,
            17: AllocationInvalidTransaction ex17,
            18: AllocationNotFound ex18
        )

    domain.InvoicePaymentRefund GetPaymentRefund (
        2: domain.InvoiceID id,
        3: domain.InvoicePaymentID payment_id
        4: domain.InvoicePaymentRefundID refund_id
    )
        throws (
            2: InvoiceNotFound ex2,
            3: InvoicePaymentNotFound ex3,
            4: InvoicePaymentRefundNotFound ex4
        )

    void Fulfill (2: domain.InvoiceID id, 3: string reason)
        throws (
            2: InvoiceNotFound ex2,
            3: InvalidInvoiceStatus ex3,
            4: InvalidPartyStatus ex4,
            5: InvalidShopStatus ex5,
        )

    void Rescind (2: domain.InvoiceID id, 3: string reason)
        throws (
            2: InvoiceNotFound ex2,
            3: InvalidInvoiceStatus ex3,
            4: InvoicePaymentPending ex4,
            5: InvalidPartyStatus ex5,
            6: InvalidShopStatus ex6,
        )

    /* Ad-hoc repairs */

    void Repair (
        2: domain.InvoiceID id,
        3: list<InvoiceChange> changes,
        4: repairing.ComplexAction action,
        5: InvoiceRepairParams params
    )
        throws (
            2: InvoiceNotFound ex2,
            3: base.InvalidRequest ex3
        )

    /* Invoice payments repairs */

    void RepairWithScenario (2: domain.InvoiceID id, 3: InvoiceRepairScenario Scenario)
        throws (
            2: InvoiceNotFound ex2,
            3: base.InvalidRequest ex3
        )

    RouteLimitContext GetPaymentRoutesLimitValues (1: domain.InvoiceID id, 2: domain.InvoicePaymentID payment_id)
        throws (
            1: InvoiceNotFound ex1,
            2: InvoicePaymentNotFound ex2
            3: base.InvalidRequest ex3
        )
}

// @NOTE: Argument and exception tags start with 2 for historical reasons

service InvoiceTemplating {

    domain.InvoiceTemplate Create (2: InvoiceTemplateCreateParams params)
        throws (
            2: PartyNotFound ex2,
            3: InvalidPartyStatus ex3,
            4: ShopNotFound ex4,
            5: InvalidShopStatus ex5,
            6: base.InvalidRequest ex6
        )

    domain.InvoiceTemplate Get (2: domain.InvoiceTemplateID id)
        throws (
            2: InvoiceTemplateNotFound ex2,
            3: InvoiceTemplateRemoved ex3
        )

    domain.InvoiceTemplate Update (2: domain.InvoiceTemplateID id, 3: InvoiceTemplateUpdateParams params)
        throws (
            2: InvoiceTemplateNotFound ex2,
            3: InvoiceTemplateRemoved ex3,
            4: InvalidPartyStatus ex4,
            5: InvalidShopStatus ex5,
            6: base.InvalidRequest ex6
        )

    void Delete (2: domain.InvoiceTemplateID id)
        throws (
            2: InvoiceTemplateNotFound ex2,
            3: InvoiceTemplateRemoved ex3,
            4: InvalidPartyStatus ex4,
            5: InvalidShopStatus ex5
        )

    /* Terms */

    domain.TermSet ComputeTerms (
        2: domain.InvoiceTemplateID id
    )
        throws (
            2: InvoiceTemplateNotFound ex2,
            3: InvoiceTemplateRemoved ex3
        )
}

/* Party management service definitions */

// Types

typedef domain.WalletID WalletID
typedef domain.PaymentInstitutionRef PaymentInstitutionRef

struct Varset {
    1: optional domain.CategoryRef category
    2: optional domain.CurrencyRef currency
    3: optional domain.Cash amount
    4: optional domain.PaymentMethodRef payment_method
    5: optional domain.WalletID wallet_id
    6: optional domain.ShopID shop_id
    8: optional domain.PaymentTool payment_tool
    9: optional domain.PartyConfigRef party_ref
    10: optional domain.BinData bin_data
}

struct ProviderDetails {
    1: required domain.ProviderRef ref
    2: required string name
    3: optional string description
}

struct AccountState {
    1: required domain.AccountID account_id
    2: required domain.Amount own_amount
    3: required domain.Amount available_amount
    4: required domain.Currency currency
}

struct ProviderTerminal {
    1: required domain.TerminalRef ref
    2: required string name
    3: optional string description

    /**
     * Данные провайдера, который предоставляет данный терминал.
     */
    4: required ProviderDetails provider

    /**
     * Данные для обращения к адаптеру по данному терминалу.
     * Взаимодействие с провайдером нужно производить, обращаясь к адаптеру по
     * указанному `url`, передавая указанные `options` в рамках соответсвующего
     * протокола.
     */
    5: required domain.ProxyDefinition proxy

    /**
     * Результирующие условия обслуживания по данному терминалу.
     */
    6: optional domain.ProvisionTermSet terms
}

// Exceptions

exception PartyExists {}

struct InvalidObjectReference {
    1: optional domain.Reference ref
}

exception AccountNotFound {}

exception ShopAccountNotFound {}

exception WalletAccountNotFound {}

exception PaymentInstitutionNotFound {}

exception ProviderNotFound {}

exception TerminalNotFound {}

exception ProvisionTermSetUndefined {}

exception GlobalsNotFound {}

exception RuleSetNotFound {}

exception TermSetHierarchyNotFound {}

// Service

// @NOTE: Argument and exception tags start with 2 for historical reasons

service PartyManagement {
    /* Accounts */

    /**
     * Функции `*Simple` повторяют логику аналогичных функций без
     * этого суффикса, а в качестве номера версии неявно используют последнюю на
     * данный момент.
     */
    domain.ShopAccount GetShopAccountSimple (
        1: domain.PartyConfigRef party_ref,
        2: domain.ShopConfigRef shop_ref
    )
        throws (
            1: PartyNotFound ex1,
            2: ShopNotFound ex2,
            3: ShopAccountNotFound ex3
        )

    domain.WalletAccount GetWalletAccountSimple (
        1: domain.PartyConfigRef party_ref,
        2: domain.WalletConfigRef wallet_ref
    )
        throws (
            1: PartyNotFound ex1,
            2: WalletNotFound ex2,
            3: WalletAccountNotFound ex3
        )

    AccountState GetAccountStateSimple (
        1: domain.PartyConfigRef party_ref,
        2: domain.AccountID account_id
    )
        throws (
            1: PartyNotFound ex1,
            2: AccountNotFound ex2
        )

    /**
     * В функциях `GetShopAccount`, `GetWalletAccount` и
     * `GetAccountState` `party_ref` необходим для проверки
     * принадлежности объекта для указанной версии.
     */
    domain.ShopAccount GetShopAccount (
        1: domain.PartyConfigRef party_ref,
        2: domain.ShopConfigRef shop_ref,
        3: domain.DataRevision domain_revision
    )
        throws (
            1: PartyNotFound ex1,
            2: ShopNotFound ex2,
            3: ShopAccountNotFound ex3
        )

    domain.WalletAccount GetWalletAccount (
        1: domain.PartyConfigRef party_ref,
        2: domain.WalletConfigRef wallet_ref,
        3: domain.DataRevision domain_revision
    )
        throws (
            1: PartyNotFound ex1,
            2: WalletNotFound ex2,
            3: WalletAccountNotFound ex3
        )

    AccountState GetAccountState (
        1: domain.PartyConfigRef party_ref,
        2: domain.AccountID account_id,
        3: domain.DataRevision domain_revision
    )
        throws (
            1: PartyNotFound ex1,
            2: AccountNotFound ex2
        )

    /* Provider */

    domain.Provider ComputeProvider (
        1: domain.ProviderRef provider_ref,
        2: domain.DataRevision domain_revision,
        3: Varset varset
    )
        throws (
            1: ProviderNotFound ex1
        )

    domain.ProvisionTermSet ComputeProviderTerminalTerms (
        1: domain.ProviderRef provider_ref,
        2: domain.TerminalRef terminal_ref,
        3: domain.DataRevision domain_revision,
        4: Varset varset
    )
        throws (
            1: ProviderNotFound ex1,
            2: TerminalNotFound ex2,
            3: ProvisionTermSetUndefined ex3
        )

    /**
     * Вычислить данные терминала провайдера.
     *
     * Аргумент `varset` может быть неопределён, в этом случае расчёт результрующих
     * provision terms не производится, и в ответе они будут отсутствовать.
     */
    ProviderTerminal ComputeProviderTerminal (
        1: domain.TerminalRef terminal_ref
        2: domain.DataRevision domain_revision
        3: Varset varset
    )
        throws (
            1: TerminalNotFound ex1
        )

    /* Globals */

    domain.Globals ComputeGlobals (
        1: domain.DataRevision domain_revision,
        2: Varset varset
    )
        throws (
            1: GlobalsNotFound ex1
        )

    /* RuleSet */

    domain.RoutingRuleset ComputeRoutingRuleset (
        1: domain.RoutingRulesetRef ruleset_ref,
        2: domain.DataRevision domain_revision,
        3: Varset varset
    )
        throws (
            1: RuleSetNotFound ex1
        )

    /* Payment institutions */

    domain.PaymentInstitution ComputePaymentInstitution (
        1: PaymentInstitutionRef ref,
        2: domain.DataRevision domain_revision,
        3: Varset varset
    )
        throws (
            1: PartyNotFound ex1,
            2: PaymentInstitutionNotFound ex2
        )

    domain.TermSet ComputeTerms (
        1: domain.TermSetHierarchyRef ref,
        2: domain.DataRevision domain_revision,
        3: Varset varset
    )
        throws (
            1: TermSetHierarchyNotFound ex1
        )
}

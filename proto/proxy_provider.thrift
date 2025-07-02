include "base.thrift"
include "domain.thrift"
include "user_interaction.thrift"
include "timeout_behaviour.thrift"

namespace java dev.vality.damsel.proxy_provider
namespace erlang dmsl.proxy_provider

/**
 * Непрозрачное для процессинга состояние адаптера, связанное с определённой сессией взаимодействия
 * с третьей стороной.
 */
typedef base.Opaque ProxyState

/**
 * Запрос/ответ адаптера при обработке обратного вызова в рамках сессии.
 */
typedef base.Opaque Callback
typedef base.Opaque CallbackResponse

/**
 * Требование адаптера к процессингу, отражающее дальнейший прогресс сессии взаимодействия
 * с третьей стороной.
 */
union Intent {
    1: FinishIntent finish
    2: SleepIntent sleep
    3: SuspendIntent suspend
}

/**
 * Требование завершить сессию взаимодействия с третьей стороной.
 */
struct FinishIntent {
    1: required FinishStatus status
}

/**
 * Статус, c которым завершилась сессия взаимодействия с третьей стороной.
 */
union FinishStatus {
    /** Успешное завершение взаимодействия. */
    1: Success success
    /** Неуспешное завершение взаимодействия с пояснением возникшей проблемы. */
    2: domain.Failure failure
}

struct Success {
    /** Токен для последующих взаимодействий. */
    1: optional domain.Token token
    /**
     * Измененная сумма операции.
     * Используется для согласования, если провайдер посчитал сумму по другому.
     * Можно установить только на шаг processed платежа
     */
    2: optional Cash changed_cost
}

/**
 * Требование прервать на определённое время сессию взаимодействия, с намерением продолжить
 * её потом.
 */
struct SleepIntent {
    /** Таймер, определяющий когда следует продолжить взаимодействие. */
    1: required base.Timer timer

    /**
     * Взаимодействие с пользователем, в случае если таковое необходимо для продолжения прогресса
     * в рамках сессии взаимодействия.
     */
    2: optional user_interaction.UserInteraction user_interaction

    /**
     * Завершение (последнего запрошенного) взаимодействия с пользователем.
     * Если не было ни одного взаимодействия с пользователем или последнее запрошенное
     * взаимодействие с пользователем уже завершено, передача этого статуса не является ошибкой,
     * просто никак не обрабатываеся. Если адаптер одновременно и запрашивает взаимодейвие с
     * пользователем, и завершение, это обрабатывается как завершение предыдущего (если такое
     * вообще было) и запросом нового.
     */
    3: optional user_interaction.Completed user_interaction_completion
}

typedef base.Tag CallbackTag

/**
 * Требование приостановить сессию взаимодействия, с продолжением по факту прихода обратного
 * запроса (далее: callback), либо выполняет один из указаных вариантов timeout_behaviour.
 * Если не указан timeout_behaviour, сессия завершается с неуспешным завершением
 * по факту истечения заданного времени ожидания.
 */
struct SuspendIntent {
    /**
     * Ассоциация (далее: tag), по которой обработчик callback сможет идентифицировать сессию
     * взаимодействия с провайдером, чтобы продолжить по ней взаимодействие. Для этого адаптер
     * должен будет вызвать `ProcessPaymentCallback` в сервисе процессинга.
     *
     * В рамках одной сессии взаимодействия адаптер может переиспользовать один и тот же tag
     * сколько угодно раз.
     */
    1: required CallbackTag tag

    /**
     * Таймер, определяющий время, в течение которого процессинг ожидает обратный запрос.
     */
    2: required base.Timer timeout

    /**
     * Взаимодействие с пользователем, в случае если таковое необходимо для продолжения прогресса
     * в рамках сессии взаимодействия.
     */
    3: optional user_interaction.UserInteraction user_interaction

    /**
     * Завершение (последнего запрошенного) взаимодействия с пользователем.
     * Если не было ни одного взаимодействия с пользователем или последнее запрошенное
     * взаимодействие с пользователем уже завершено, передача этого статуса не является ошибкой,
     * просто никак не обрабатываеся. Если адаптер одновременно и запрашивает взаимодейвие с
     * пользователем, и завершение, то это обрабатывается как завершение предыдущего (если такое
     * вообще было) и запросом нового.
     */
    5: optional user_interaction.Completed user_interaction_completion

    /**
    * Поведение процессинга в случае истечения заданного timeout
    */
    4: optional timeout_behaviour.TimeoutBehaviour timeout_behaviour
}

struct RecurrentPaymentTool {
    1: required base.ID                          id
    2: required base.Timestamp                   created_at
    3: required domain.DisposablePaymentResource payment_resource
    4: required Cash                             minimal_payment_cost
}

/**
 * Данные, необходимые для генерации многоразового токена
 */
struct RecurrentTokenInfo {
    1: required RecurrentPaymentTool   payment_tool
    2: optional domain.TransactionInfo trx
    3: required Shop                   shop
}

/**
 * Данные сессии взаимодействия с адаптером в рамках генерации многоразового токена.
 */
struct RecurrentTokenSession {
    1: optional ProxyState state
}

/**
 * Набор данных для взаимодействия с адаптером в рамках проведения генерации многоразового токена.
 */
struct RecurrentTokenContext {
    1: required RecurrentTokenSession session
    2: required RecurrentTokenInfo    token_info
    3: optional domain.ProxyOptions   options = {}
}

struct RecurrentTokenProxyResult {
    1: required RecurrentTokenIntent   intent
    2: optional ProxyState             next_state
    4: optional domain.TransactionInfo trx
}

union RecurrentTokenIntent {
    1: RecurrentTokenFinishIntent finish
    2: SleepIntent                sleep
    3: SuspendIntent              suspend
}

struct RecurrentTokenFinishIntent {
    1: required RecurrentTokenFinishStatus status
}

union RecurrentTokenFinishStatus {
    1: RecurrentTokenSuccess success
    2: domain.Failure        failure
}

struct RecurrentTokenSuccess {
    1: required domain.Token token
}

struct RecurrentTokenCallbackResult {
    1: required CallbackResponse          response
    2: required RecurrentTokenProxyResult result
}

/**
 * Данные платежа, необходимые для обращения к провайдеру.
 */
struct PaymentInfo {
    1: required Shop                  shop
    2: required Invoice               invoice
    3: required InvoicePayment        payment
    4: optional InvoicePaymentRefund  refund
    5: optional InvoicePaymentCapture capture
}

struct Shop {
    1: required domain.ShopID       id
    2: required domain.Category     category
    3: required string              name
    4: optional string              description
    5: required domain.ShopLocation location
}

struct Invoice {
    1: required domain.InvoiceID      id
    2: required base.Timestamp        created_at
    3: required base.Timestamp        due
    7: required domain.InvoiceDetails details
    6: required Cash                  cost
}

union PaymentResource {
    1: domain.DisposablePaymentResource disposable_payment_resource
    2: RecurrentPaymentResource         recurrent_payment_resource
}

struct RecurrentPaymentResource {
    1: required domain.PaymentTool      payment_tool
    2: required domain.Token            rec_token
}

struct InvoicePayment {
    1: required domain.InvoicePaymentID id
    2: required base.Timestamp          created_at
    3: optional domain.TransactionInfo  trx
    6: required PaymentResource         payment_resource
    11: optional domain.PaymentService  payment_service
    10: optional domain.PayerSessionInfo payer_session_info
    5: required Cash                    cost
    7: required domain.ContactInfo      contact_info
    8: optional bool                    make_recurrent
    9: optional base.Timestamp          processing_deadline
}

struct InvoicePaymentRefund {
    1: required domain.InvoicePaymentRefundID id
    2: required base.Timestamp                created_at
    4: required Cash                          cash
    3: optional domain.TransactionInfo        trx
}

struct InvoicePaymentCapture {
    1: required Cash cost
}

struct Cash {
    1: required domain.Amount   amount
    2: required domain.Currency currency
}

/**
 * Данные сессии взаимодействия с адаптером.
 *
 * В момент, когда адаптер успешно завершает сессию взаимодействия, процессинг считает,
 * что поставленная цель достигнута, и платёж перешёл в соответствующий статус.
 */
struct Session {
    1: required domain.TargetInvoicePaymentStatus target
    2: optional ProxyState                        state
}

/**
 * Набор данных для взаимодействия с адаптером в рамках платежа.
 */
struct PaymentContext {
    1: required Session             session
    2: required PaymentInfo         payment_info
    3: optional domain.ProxyOptions options      = {}
}

/**
 * Результат обращения к адаптеру в рамках сессии.
 *
 * В результате обращения адаптер может решить, следует ли:
 *  - завершить сессию взаимодействия с провайдером (FinishIntent); или
 *  - просто приостановить на определённое время (SleepIntent), обновив своё состояние, которое
 *    вернётся к нему в последующем запросе; или
 *  - приостановить до получения обратного запроса (SuspendIntent), обновив своё состояние, которое
 *    вернётся к нему при получени означенного обратного запроса.
 *
 * Прокси может связать с текущим платежом данные транзакции у провайдера для учёта в нашей системе,
 * причём на эти данные налагаются следующие требования:
 *  - данные должны быть связаны на момент завершения сессии взаимодействия с провайдером в рамках
 *    достижения цели по переводу платежа в статус `processed`;
 *  - идентификатор связанной транзакции _не может измениться_ при последующих обращениях в адаптер
 *    по текущему платежу.
 */
struct PaymentProxyResult {
    1: required Intent                 intent
    2: optional ProxyState             next_state
    3: optional domain.TransactionInfo trx
}

/**
 * Результат обработки адаптером обратного вызова в рамках сессии.
 */
struct PaymentCallbackResult {
    1: required CallbackResponse           response
    2: required PaymentCallbackProxyResult result
}

struct PaymentCallbackProxyResult {
    /**
     * Требование адаптера к процессингу по дальнейшему взаимодействию с провайдером.
     *
     * Если задано, то процессинг считает callback с данным tag'ом _обработанным_, и все
     * последующие вызовы `ProcessPaymentCallback` будут отклонены с ошибкой. Но с одним исключением:
     * если адаптер здесь переиспользует тот же tag в рамках требования suspend, тогда с точки
     * зрения процессинга это будет требование ожидания _нового_ обратного запроса, просто с тем
     * же tag'ом.
     *
     * Если значение не задано, то callback считается по-прежнему _необработанным_, адаптер
     * может повторно вызвать `ProcessPaymentCallback` с тем же tag'ом.
     */
    1: optional Intent                 intent
    2: optional ProxyState             next_state
    3: optional domain.TransactionInfo trx
}

service ProviderProxy {

    /**
     * Запрос к адаптеру на создание многоразового токена.
     */
    RecurrentTokenProxyResult GenerateToken (
        1: RecurrentTokenContext context
    )

    /**
     * Запрос к адаптеру на обработку обратного вызова от провайдера в рамках сессии получения
     * многоразового токена.
     */
    RecurrentTokenCallbackResult HandleRecurrentTokenCallback (
        1: Callback              callback
        2: RecurrentTokenContext context
    )

    /**
     * Запрос к адаптеру на проведение взаимодействия с провайдером в рамках платежной сессии.
     */
    PaymentProxyResult ProcessPayment (1: PaymentContext context)

    /**
     * Запрос к адаптеру на обработку callback от провайдера в рамках платежной сессии.
     */
    PaymentCallbackResult HandlePaymentCallback (1: Callback callback, 2: PaymentContext context)

}

exception PaymentNotFound {}

/**
 * Набор изменений в сессии платежа.
 */
struct PaymentSessionChange {
    1: required PaymentSessionStatusChange status
}

/**
 * Изменение статуса сессии.
 *
 * TODO Может быть использовать FinishStatus вместо этого юниона
 */
union PaymentSessionStatusChange {
    // Reserved
    // 1: Success success

    2: domain.Failure failure
}

service ProviderProxyHost {

    /**
     * Запрос к процессингу на обработку callback от провайдера в рамках взаимодействия по платежу.
     */
    CallbackResponse ProcessPaymentCallback (1: CallbackTag tag, 2: Callback callback)
        throws (1: base.InvalidRequest ex1)

    /**
     * Запрос к процессингу на обработку callback от провайдера в рамках взаимодействия по
     * получению многоразового токена.
     */
    CallbackResponse ProcessRecurrentTokenCallback (1: CallbackTag tag, 2: Callback callback)
        throws (1: base.InvalidRequest ex1)

    /**
     * Запрос-костыль к процессингу для получения актуального состояния платежа.
     */
    PaymentInfo GetPayment (1: CallbackTag tag)
        throws (1: PaymentNotFound ex1)

    /**
     * Изменить соответствующую callback-тегу сессию платежа.
     *
     * NOTE Кроме костыль функции по получению инфо платежа все
     * функции сервиса хоста оперируют непрозрачным содержимым типов
     * Callback и CallbackResponse.
     */
    void ChangePaymentSession (1: CallbackTag tag, 2: PaymentSessionChange change)
        throws (1: base.InvalidRequest ex1)
}

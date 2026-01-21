/**
 * Определения и сервисы для работы с Customer и каскадированием рекуррентных платежей.
 *
 * Customer — агрегатор информации о плательщике в рамках конкретной Party.
 * BankCard — самостоятельная сущность банковской карты, которая может быть связана с несколькими Customer'ами.
 */

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.customer
namespace erlang dmsl.customer

/* Идентификаторы */

typedef base.ID CustomerID
typedef base.ID BankCardID
typedef base.ID RecurrentTokenID

/* BankCard — самостоятельная сущность банковской карты */

/**
 * Рекуррентный токен, полученный от провайдера.
 * Используется для проведения рекуррентных платежей без повторного ввода данных карты.
 */
struct RecurrentToken {
    /** Уникальный идентификатор токена */
    1: required RecurrentTokenID id
    /** Идентификатор провайдера, выдавшего токен */
    2: required domain.ProviderRef provider_ref
    /** Идентификатор терминала, через который был получен токен */
    3: required domain.TerminalRef terminal_ref
    /** Рекуррентный токен от провайдера */
    4: required domain.Token token
    /** Время создания токена */
    5: required base.Timestamp created_at
    /**
     * Статус токена.
     * Токен может быть помечен как недействительный после hard decline.
     */
    6: required RecurrentTokenStatus status
}

/**
 * Статус рекуррентного токена.
 */
union RecurrentTokenStatus {
    1: RecurrentTokenActive active
    2: RecurrentTokenInvalidated invalidated
}

struct RecurrentTokenActive {}

struct RecurrentTokenInvalidated {
    /** Причина инвалидации токена */
    1: optional string reason
    /** Время инвалидации */
    2: required base.Timestamp invalidated_at
}

/**
 * Ссылка на BankCard.
 * Используется для связи Customer с BankCard (many-to-many).
 */
struct BankCardRef {
    1: required BankCardID id
}

/**
 * Ключ для идентификации рекуррентного токена — пара провайдер + терминал.
 */
struct ProviderTerminalKey {
    1: required domain.ProviderRef provider_ref
    2: required domain.TerminalRef terminal_ref
}

/**
 * BankCard — самостоятельная сущность банковской карты.
 */
struct BankCard {
    /** Уникальный идентификатор записи (UUID) */
    1: required BankCardID id
    /** Токенизированные данные карты */
    2: required domain.Token bank_card_token
    /**
     * Массив Party, которые могут использовать эту запись.
     * По умолчанию содержит одну Party — владельца.
     * Расшаривание между Party возможно только через ручную миграцию.
     */
    3: required list<domain.PartyConfigRef> party_refs
    /** Маска карты (первые 6 и последние 4 цифры), например "424242******4242" */
    4: optional string card_mask
    /** Время создания записи */
    5: required base.Timestamp created_at
    /**
     * Рекуррентные токены для этой карты.
     * Ключ — пара провайдер + терминал.
     */
    6: required map<ProviderTerminalKey, RecurrentToken> recurrent_tokens
}

/* Customer — агрегатор для мерчанта */

/**
 * Ссылка на платёж
 */
struct PaymentRef {
    1: required domain.InvoiceID invoice_id
    2: required domain.InvoicePaymentID payment_id
}

/**
 * Информация о платеже Customer.
 */
struct CustomerPayment {
    1: required domain.InvoiceID invoice_id
    2: required domain.InvoicePaymentID payment_id
    3: required base.Timestamp created_at
}

/**
 * Customer — агрегатор информации о плательщике в рамках конкретной Party.
 *
 * Customer связывает:
 * - Party (мерчант, которому принадлежит Customer)
 * - Список проведённых платежей
 * - Банковские карты (через many-to-many связь с BankCard)
 */
struct Customer {
    /** Уникальный идентификатор Customer */
    1: required CustomerID id
    /** Party, которой принадлежит Customer */
    2: required domain.PartyConfigRef party_ref
    /** Время создания Customer */
    3: required base.Timestamp created_at
    /** Статус Customer */
    4: required CustomerStatus status
    /** Контактная информация плательщика */
    5: optional domain.ContactInfo contact_info
    /** Метаданные Customer (произвольные данные мерчанта) */
    6: optional domain.Metadata metadata
}

/**
 * Статус Customer.
 */
union CustomerStatus {
    1: CustomerActive active
    2: CustomerDeleted deleted
}

struct CustomerActive {}

struct CustomerDeleted {
    1: required base.Timestamp deleted_at
}

/**
 * Полное состояние Customer с связанными данными.
 */
struct CustomerState {
    1: required Customer customer
    /** Список ссылок на банковские карты Customer */
    2: required list<BankCardRef> bank_card_refs
    /** Список ссылок на платежи */
    3: required list<PaymentRef> payment_refs
}

/* Параметры создания и поиска */

/**
 * Параметры создания Customer.
 */
struct CustomerParams {
    /** Party, которой будет принадлежать Customer */
    1: required domain.PartyConfigRef party_ref
    /** Контактная информация плательщика */
    2: optional domain.ContactInfo contact_info
    /** Метаданные Customer */
    3: optional domain.Metadata metadata
}

/**
 * Параметры поиска BankCard.
 */
struct BankCardSearchParams {
    /** Токен карты для поиска */
    1: required domain.Token bank_card_token
    /** Party, в рамках которой искать */
    2: required domain.PartyConfigRef party_ref
}

/**
 * Параметры добавления BankCard к Customer.
 */
struct BankCardParams {
    /** Токен карты */
    1: required domain.Token bank_card_token
    /** Маска карты */
    2: optional string card_mask
}

/**
 * Параметры добавления рекуррентного токена к BankCard.
 */
struct RecurrentTokenParams {
    1: required BankCardID bank_card_id
    2: required domain.ProviderRef provider_ref
    3: required domain.TerminalRef terminal_ref
    4: required domain.Token token
}

/**
 * Параметры инвалидации рекуррентного токена.
 */
struct InvalidateRecurrentTokenParams {
    1: required BankCardID bank_card_id
    2: required ProviderTerminalKey key
    3: optional string reason
}

/**
 * Информация о банковской карте для API.
 * Возвращается мерчанту без чувствительных данных.
 */
struct BankCardInfo {
    1: required BankCardID id
    2: required string card_mask
    3: required base.Timestamp created_at
    /** Список провайдеров, для которых есть рекуррентные токены */
    4: required list<domain.ProviderRef> recurrent_providers
}

/* Исключения */

exception CustomerNotFound {}

exception CustomerAlreadyExists {
    1: required CustomerID id
}

exception BankCardNotFound {}

exception InvalidRecurrentParent {
    1: optional string reason
}

exception RecurrentTokenNotFound {}

/* Пагинация */

typedef string ContinuationToken

struct CustomerPaymentsResponse {
    1: required list<CustomerPayment> payments
    2: optional ContinuationToken continuation_token
}

struct CustomerBankCardsResponse {
    1: required list<BankCardInfo> bank_cards
    2: optional ContinuationToken continuation_token
}

/* Сервисы */

/**
 * Сервис управления Customer.
 * Предоставляет API для создания, получения и управления Customer.
 */
service CustomerManagement {

    /**
     * Создать нового Customer.
     */
    Customer Create(1: CustomerParams params)
        throws (
            1: CustomerAlreadyExists already_exists
            2: base.InvalidRequest invalid_request
        )

    /**
     * Получить Customer по ID.
     */
    CustomerState Get(1: CustomerID customer_id)
        throws (1: CustomerNotFound not_found)

    /**
     * Найти Customer по parent invoice/payment (для рекуррентных платежей).
     */
    CustomerState GetByParentPayment(
        1: domain.InvoiceID invoice_id,
        2: domain.InvoicePaymentID payment_id
    )
        throws (
            1: CustomerNotFound not_found
            2: InvalidRecurrentParent invalid_parent
        )

    /**
     * Удалить Customer (soft delete).
     */
    void Delete(1: CustomerID customer_id)
        throws (1: CustomerNotFound not_found)

    /**
     * Добавить банковскую карту к Customer.
     * Если BankCard с таким bank_card_token уже существует для данной Party,
     * будет использована существующая запись.
     */
    BankCard AddBankCard(
        1: CustomerID customer_id,
        2: BankCardParams params
    )
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Удалить связь Customer с банковской картой.
     * Не удаляет саму BankCard, только убирает связь.
     */
    void RemoveBankCard(
        1: CustomerID customer_id,
        2: BankCardID bank_card_id
    )
        throws (
            1: CustomerNotFound not_found
            2: BankCardNotFound bank_card_not_found
        )

    /**
     * Добавить платёж к Customer.
     */
    void AddPayment(
        1: CustomerID customer_id,
        2: domain.InvoiceID invoice_id,
        3: domain.InvoicePaymentID payment_id
    )
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Получить список платежей Customer.
     */
    CustomerPaymentsResponse GetPayments(
        1: CustomerID customer_id,
        2: i32 limit,
        3: optional ContinuationToken continuation_token
    )
        throws (1: CustomerNotFound not_found)

    /**
     * Получить список банковских карт Customer.
     */
    CustomerBankCardsResponse GetBankCards(
        1: CustomerID customer_id,
        2: i32 limit,
        3: optional ContinuationToken continuation_token
    )
        throws (1: CustomerNotFound not_found)
}

/**
 * Сервис работы с BankCard.
 * Внутренний сервис для поиска и управления BankCard.
 */
service BankCardStorage {

    /**
     * Получить BankCard по ID.
     */
    BankCard Get(1: BankCardID id)
        throws (1: BankCardNotFound not_found)

    /**
     * Найти BankCard по токену карты и Party.
     */
    BankCard Find(1: BankCardSearchParams params)
        throws (1: BankCardNotFound not_found)

    /**
     * Создать новую BankCard.
     */
    BankCard Create(
        1: domain.PartyConfigRef party_ref,
        2: BankCardParams params
    )
        throws (1: base.InvalidRequest invalid_request)

    /**
     * Получить все активные рекуррентные токены для BankCard.
     * Возвращает только токены со статусом `active`.
     * Инвалидированные токены не включаются в результат.
     */
    list<RecurrentToken> GetRecurrentTokens(1: BankCardID bank_card_id)
        throws (1: BankCardNotFound not_found)

    /**
     * Добавить рекуррентный токен к BankCard.
     */
    RecurrentToken AddRecurrentToken(1: RecurrentTokenParams params)
        throws (
            1: BankCardNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Инвалидировать рекуррентный токен.
     */
    void InvalidateRecurrentToken(1: InvalidateRecurrentTokenParams params)
        throws (
            1: BankCardNotFound not_found
            2: RecurrentTokenNotFound token_not_found
        )
}

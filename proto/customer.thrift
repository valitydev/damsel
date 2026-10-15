/**
 * Определения и сервисы для работы с Customer и каскадированием рекуррентных платежей.
 *
 * Customer — агрегатор информации о плательщике.
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
/** Идентификатор вывода в fistful */
typedef base.ID WithdrawalID

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

/* Terminal affinity — привязка плательщика к терминалу */

/**
 * Привязка Customer к терминалу.
 *
 * У Customer может быть несколько активных привязок. При выборе роута среди
 * доступных кандидатов предпочитается привязка, созданная раньше
 * (с меньшим bind_seq). См. domain.RoutingAffinity.
 */
struct TerminalAffinity {
    1: required domain.ProviderRef provider_ref
    2: required domain.TerminalRef terminal_ref
    /**
     * Порядковый номер привязки, растёт монотонно. Чем меньше, тем раньше
     * создана привязка и тем выше её приоритет.
     */
    3: required i64 bind_seq
    /** Время создания привязки; точка отсчёта для TTL since_bound */
    4: required base.Timestamp bound_at
    /**
     * Время последнего успешного платежа через привязку;
     * точка отсчёта для TTL since_last_use.
     */
    5: required base.Timestamp last_used_at
}

/**
 * Параметры привязки Customer к терминалу.
 * Операция идемпотентна по платежу: повтор с тем же payment ничего не меняет, а вызов
 * по новому платежу обновляет last_used_at (подробнее — у BindTerminalAffinity).
 */
struct TerminalAffinityParams {
    1: required CustomerID customer_id
    2: required domain.ProviderRef provider_ref
    3: required domain.TerminalRef terminal_ref
    /**
     * Если задан и существующая привязка к этому терминалу по нему уже истекла,
     * она снимается, а вместо неё создаётся новая с очередным bind_seq.
     */
    4: optional domain.RoutingAffinityTtl ttl
    /**
     * Платёж, по итогам которого создаётся привязка.
     *
     * Служит ключом идемпотентности: повторная привязка по тому же платежу
     * ничего не меняет и возвращает существующую запись. Без него повтор шага
     * машины неотличим от нового успешного платежа, и привязка, истёкшая между
     * попытками, была бы снята и создана заново с новым порядковым номером,
     * то есть переехала бы в конец истории.
     *
     * Этот же платёж запоминается за Customer, поэтому отдельный вызов
     * AddPayment для него не нужен.
     */
    5: required PaymentRef payment
    /**
     * Party, в которой проведён платёж. Customer должен быть к ней привязан.
     */
    6: required domain.PartyConfigRef party_ref
}

/**
 * Параметры снятия привязки.
 */
struct ReleaseTerminalAffinityParams {
    1: required CustomerID customer_id
    2: required ProviderTerminalKey key
    3: optional string reason
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
     * Карта, привязанная к Customer, доступна всем Party, к которым он привязан.
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
 * Ссылка на вывод
 */
struct WithdrawalRef {
    1: required WithdrawalID withdrawal_id
}

/**
 * Информация о выводе Customer.
 */
struct CustomerWithdrawal {
    1: required WithdrawalID withdrawal_id
    2: required base.Timestamp created_at
}

/**
 * Customer — агрегатор информации о плательщике.
 *
 * Customer может быть привязан к нескольким Party: к той, в которой он создан, и к тем,
 * в которых ему назначен external_id. Customer всегда возвращается в контексте одной из них.
 *
 * Customer связывает:
 * - Party (мерчанты, к которым привязан Customer)
 * - Список проведённых платежей
 * - Банковские карты (через many-to-many связь с BankCard)
 */
struct Customer {
    /** Уникальный идентификатор Customer */
    1: required CustomerID id
    /** Party, в контексте которой возвращён Customer */
    2: required domain.PartyConfigRef party_ref
    /** Время создания Customer */
    3: required base.Timestamp created_at
    /** Статус Customer */
    4: required CustomerStatus status
    /** Контактная информация плательщика */
    5: optional domain.ContactInfo contact_info
    /** Метаданные Customer (произвольные данные мерчанта) */
    6: optional domain.Metadata metadata
    /** Внешний идентификатор Customer в рамках party_ref */
    7: optional string external_id
    /**
     * Email плательщика в нормализованном виде (нижний регистр, без пробелов
     * по краям). Уникален в рамках party_ref. Служит идентификатором плательщика
     * для привязки к терминалу; не путать с external_id — идентификатором,
     * который назначает мерчант.
     */
    8: optional string email
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
 * Полное состояние Customer со связанными данными.
 */
struct CustomerState {
    1: required Customer customer
    /** Список ссылок на банковские карты Customer */
    2: required list<BankCardRef> bank_card_refs
    /** Список ссылок на платежи Customer, проведённые в party_ref Customer */
    3: required list<PaymentRef> payment_refs
    /** Список ссылок на выводы Customer, проведённые в party_ref Customer */
    4: required list<WithdrawalRef> withdrawal_refs
}

/* Параметры создания и поиска */

/**
 * Параметры создания Customer.
 */
struct CustomerParams {
    /** Party, в которой создаётся Customer */
    1: required domain.PartyConfigRef party_ref
    /** Контактная информация плательщика */
    2: optional domain.ContactInfo contact_info
    /** Метаданные Customer */
    3: optional domain.Metadata metadata
    /** Внешний идентификатор Customer в рамках party_ref */
    4: optional string external_id
    /** Email плательщика; нормализуется сервисом. Уникален в рамках party_ref */
    5: optional string email
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
    2: optional string card_mask
    3: required base.Timestamp created_at
    /** Список провайдеров, для которых есть рекуррентные токены */
    4: required list<domain.ProviderRef> recurrent_providers
}

/* Исключения */

exception CustomerNotFound {}

exception CustomerAlreadyExists {
    1: required CustomerID id
}

/** Email уже занят другим Customer этой party */
exception CustomerEmailConflict {
    1: required CustomerID id
}

/**
 * Невозможно назначить external_id: в party уже есть конфликтующая привязка —
 * этот external_id занят другим Customer, либо у Customer в этой party уже есть
 * другой external_id.
 */
exception CustomerExternalIDConflict {
    /** Customer из существующей привязки */
    1: required CustomerID id
    /** external_id из существующей привязки */
    2: required string external_id
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

struct CustomerWithdrawalsResponse {
    1: required list<CustomerWithdrawal> withdrawals
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
            3: CustomerEmailConflict email_conflict
        )

    /**
     * Получить Customer по ID в контексте party.
     * Если Customer не привязан к party, возвращается CustomerNotFound.
     */
    CustomerState Get(1: CustomerID customer_id, 2: domain.PartyConfigRef party_ref)
        throws (1: CustomerNotFound not_found)

    /**
     * Найти Customer по parent invoice/payment (для рекуррентных платежей) в контексте party.
     * Если Customer, которому принадлежит платёж, не привязан к party,
     * возвращается CustomerNotFound. Если привязан, но платёж проведён в другой party,
     * возвращается InvalidRecurrentParent.
     */
    CustomerState GetByParentPayment(
        1: domain.InvoiceID invoice_id,
        2: domain.InvoicePaymentID payment_id,
        3: domain.PartyConfigRef party_ref
    )
        throws (
            1: CustomerNotFound not_found
            2: InvalidRecurrentParent invalid_parent
        )

    /**
     * Найти Customer по выводу в контексте party.
     * Если вывод не найден, проведён в другой party или Customer, которому он
     * принадлежит, не привязан к party, возвращается CustomerNotFound.
     */
    CustomerState GetByWithdrawal(
        1: WithdrawalID withdrawal_id,
        2: domain.PartyConfigRef party_ref
    )
        throws (1: CustomerNotFound not_found)

    /**
     * Получить Customer по external_id и party.
     * Находит также Customer, созданный в другой party, если в данной party ему назначен
     * этот external_id.
     */
    CustomerState GetByExternalID(
        1: string external_id,
        2: domain.PartyConfigRef party_ref
    )
        throws (1: CustomerNotFound not_found)

    /**
     * Найти Customer по external_id в рамках party или создать его в ней, если он не найден.
     * Операция идемпотентна и безопасна при конкурентных вызовах: единственность
     * Customer гарантируется уникальностью external_id в рамках party.
     */
    Customer FindOrCreateByExternalID(
        1: domain.PartyConfigRef party_ref,
        2: string external_id
    )
        throws (1: base.InvalidRequest invalid_request)

    /**
     * Назначить Customer внешний идентификатор в party.
     * Если Customer ещё не привязан к party, он привязывается к ней, и его карты
     * становятся доступны в этой party. Операция идемпотентна: повторный вызов
     * с тем же external_id ничего не меняет.
     */
    void AddExternalID(
        1: CustomerID customer_id,
        2: domain.PartyConfigRef party_ref,
        3: string external_id
    )
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
            3: CustomerExternalIDConflict external_id_conflict
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
     * Добавить платёж, проведённый в party, к Customer.
     * Если Customer не привязан к party, возвращается CustomerNotFound.
     * Party платежа фиксируется при первом добавлении.
     *
     * Для платежей, по которым создаётся привязка к терминалу, вызывать не нужно:
     * BindTerminalAffinity запоминает платёж сам.
     */
    void AddPayment(
        1: CustomerID customer_id,
        2: domain.InvoiceID invoice_id,
        3: domain.InvoicePaymentID payment_id,
        4: domain.PartyConfigRef party_ref
    )
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Получить список платежей Customer, проведённых в party.
     * Если Customer не привязан к party, возвращается CustomerNotFound.
     */
    CustomerPaymentsResponse GetPayments(
        1: CustomerID customer_id,
        2: i32 limit,
        3: optional ContinuationToken continuation_token,
        4: domain.PartyConfigRef party_ref
    )
        throws (1: CustomerNotFound not_found)

    /**
     * Добавить вывод, проведённый в party, к Customer.
     * Если Customer не привязан к party, возвращается CustomerNotFound.
     * Операция идемпотентна: повторный вызов с тем же withdrawal_id ничего не меняет,
     * party вывода фиксируется при первом добавлении.
     * Если вывод уже привязан к другому Customer, возвращается InvalidRequest.
     */
    void AddWithdrawal(
        1: CustomerID customer_id,
        2: WithdrawalID withdrawal_id,
        3: domain.PartyConfigRef party_ref
    )
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Получить список выводов Customer, проведённых в party.
     * Если Customer не привязан к party, возвращается CustomerNotFound.
     */
    CustomerWithdrawalsResponse GetWithdrawals(
        1: CustomerID customer_id,
        2: i32 limit,
        3: optional ContinuationToken continuation_token,
        4: domain.PartyConfigRef party_ref
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

    /**
     * Найти Customer по email в рамках party или создать, если его нет.
     * Операция идемпотентна и безопасна при конкурентных вызовах: единственность
     * Customer гарантируется уникальностью email в рамках party. Email нормализуется
     * сервисом. CustomerEmailConflict не бросает.
     */
    Customer FindOrCreateByEmail(
        1: domain.PartyConfigRef party_ref,
        2: string email
    )
        throws (1: base.InvalidRequest invalid_request)

    /**
     * Получить Customer по email и party.
     */
    CustomerState GetByEmail(
        1: domain.PartyConfigRef party_ref,
        2: string email
    )
        throws (1: CustomerNotFound not_found)

    /**
     * Получить активные привязки Customer к терминалам.
     * Истечение по TTL здесь не проверяется: TTL задаётся в настройках кандидата
     * роутинга, и учитывать его должна вызывающая сторона.
     */
    list<TerminalAffinity> GetTerminalAffinities(1: CustomerID customer_id)
        throws (1: CustomerNotFound not_found)

    /**
     * Привязать Customer к терминалу по итогам успешного платежа.
     *
     * Идемпотентно по платежу: повторный вызов с тем же PaymentRef возвращает
     * существующую привязку, не меняя ни её порядковый номер, ни срок. Вызов по
     * новому платежу обновляет last_used_at, а если привязка к этому терминалу
     * истекла по ttl — снимает её и создаёт заново в конце истории.
     *
     * Платёж запоминается за Customer в том же вызове, поэтому отдельно звать
     * AddPayment для него не требуется.
     * Если Customer не привязан к party_ref, возвращается CustomerNotFound.
     */
    TerminalAffinity BindTerminalAffinity(1: TerminalAffinityParams params)
        throws (
            1: CustomerNotFound not_found
            2: base.InvalidRequest invalid_request
        )

    /**
     * Снять привязку Customer к терминалу.
     */
    void ReleaseTerminalAffinity(1: ReleaseTerminalAffinityParams params)
        throws (1: CustomerNotFound not_found)

    /**
     * Снять привязки всех Customer к терминалу.
     * Административная операция, например при выводе терминала из эксплуатации.
     */
    void ReleaseTerminalAffinitiesByTerminal(
        1: ProviderTerminalKey key,
        2: optional string reason
    )
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

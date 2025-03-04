/**
 * Интерфейс и связанные с ним определения сервиса конфигурации предметной
 * области (domain config).
 */

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.domain_config_v2
namespace erlang dmsl.domain_conf_v2

typedef string AuthorID
typedef string AuthorEmail
typedef string AuthorName

struct AuthorParams {
    1: required AuthorEmail email
    2: required AuthorName name
}

struct Author {
    1: required AuthorID id
    2: required AuthorEmail email
    3: required AuthorName name
}

exception AuthorNotFound {}
exception AuthorAlreadyExists {}

service AuthorManagement {
    Author Create (1: AuthorParams params)
        throws (1: AuthorAlreadyExists ex1)

    Author Get (1: AuthorID id)
        throws (1: AuthorNotFound ex1)

    void Delete (1: AuthorID id)
        throws (1: AuthorNotFound ex1)
}

typedef string ContinuationToken

/**
 * Маркер вершины истории.
 */
struct Head {}

typedef i64 Version
typedef i32 Limit

union VersionReference {
    1: Version version
    2: Head head
}

/**
 * Возможные операции над набором объектов.
 */

union Operation {
    1: InsertOp insert
    2: UpdateOp update
    3: RemoveOp remove
}

// Создание объекта.
// object - желаемый объект без ID, если не указан force_ref,
//          то ID для него генерируется
// force_ref - указать желаемый ID создаваемого объекта,
//             так же необходим при создании объекта ID которого невозможно сгенерировать
struct InsertOp {
    1: required domain.ReflessDomainObject object
    2: optional domain.Reference force_ref
}

// Обновление объекта
// object - новая версия объекта (реф объекта есть внутри)
struct UpdateOp {
    1: required domain.DomainObject object
}

// Мягкое удаление объекта,
// в будущих версиях объект будет недоступен, но доступен в прошлых версиях
struct RemoveOp {
    1: required domain.Reference ref
}

struct CommitResponse {
    1: required Version version
    2: required set<domain.DomainObject> new_objects
}

struct VersionedObject {
    1: required VersionedObjectInfo info
    2: required domain.DomainObject object
}

struct VersionedObjectInfo {
    1: required Version version
    2: required domain.Reference ref
    3: required base.Timestamp changed_at
    4: required Author changed_by
}

struct ObjectVersionsResponse {
    1: required list<VersionedObjectInfo> result
    2: required i64 total_count
    3: optional ContinuationToken continuation_token
}

struct SearchRequestParams {
    1: required string query
    2: required Version version
    3: optional domain.DomainObjectTypes type
    4: optional i32 limit
    5: optional ContinuationToken continuation_token
}

struct SearchResponse {
    1: required list<VersionedObjectInfo> result
    2: required i64 total_count
    3: optional ContinuationToken continuation_token
}

/**
 * Объект не найден в домене
 */
exception ObjectNotFound {}

/**
 * Неизвестный тип объекта
 */
exception ObjectTypeNotFound {}

/**
 * Возникает в случаях, если коммит
 * несовместим с уже примененными ранее
 */
exception OperationConflict { 1: required Conflict conflict }

union Conflict {
    1: ObjectAlreadyExistsConflict object_already_exists
    2: ObjectNeedsReference object_needs_reference
    3: ObjectNotFoundConflict object_not_found
    4: ObjectVersionNotFoundConflict version_not_found
    5: ObjectReferenceMismatchConflict object_reference_mismatch
}

struct ObjectAlreadyExistsConflict {
    1: required domain.Reference object_ref
}

struct ObjectNeedsReference {
    1: required domain.ReflessDomainObject object
}

struct ObjectNotFoundConflict {
    1: required domain.Reference object_ref
}

struct ObjectVersionNotFoundConflict {
    1: required domain.Reference object_ref
    2: required Version version
}

struct ObjectReferenceMismatchConflict {
    1: required domain.Reference object_ref
}

exception OperationInvalid { 1: required list<OperationError> errors }

union OperationError {
    1: ObjectReferenceCycle object_reference_cycle
    2: NonexistantObject object_not_exists
    3: BadObjectReference bad_ref
}

struct ObjectReferenceCycle {
    1: required list<domain.Reference> cycle
}

struct NonexistantObject {
    1: required domain.Reference object_ref
    2: required list<domain.Reference> referenced_by
}

struct BadObjectReference {
    1: required domain.Reference object_ref
    2: required domain.ReflessDomainObject object
}

/**
 * Попытка совершить коммит на устаревшую версию
 */
exception ObsoleteCommitVersion {
    1: required Version latest_version
}

exception VersionNotFound {}

/**
 * Интерфейс сервиса конфигурации предметной области.
 */
service RepositoryClient {

    /**
     * Возвращает объект из домена определенной или последней версии
     */
    VersionedObject CheckoutObject (1: VersionReference version_ref, 2: domain.Reference object_ref)
        throws (1: VersionNotFound ex1, 2: ObjectNotFound ex2)

}

struct RequestParams {
    1: required Limit limit
    2: optional ContinuationToken continuation_token
}

service Repository {

    /**
     * Возвращает номер последней версии домен конфига.
     */
    Version GetLatestVersion ()

    /**
     * Применить изменения к определенной глобальной версии.
     * Возвращает следующую версию
     */
    CommitResponse Commit (1: Version version, 2: list<Operation> ops, 3: AuthorID author_id)
        throws (
            1: VersionNotFound ex1
            2: OperationConflict ex2
            3: OperationInvalid ex3
            4: ObsoleteCommitVersion ex4
            5: AuthorNotFound ex5
        )

    /**
     * Возвращает список версий (изменений) объекта по убыванию номера
     * версии (сначала самые поздние изменения объекта).
     */
    ObjectVersionsResponse GetObjectHistory (1: domain.Reference ref, 2: RequestParams request_params)
        throws (1: ObjectNotFound ex1)

    /**
     * Возвращает список версий (изменений) ВСЕХ объектов в домене по
     * убыванию номера версии (сначала самые поздние изменения
     * объектов).
     */
    ObjectVersionsResponse GetAllObjectsHistory (1: RequestParams request_params)

    /**
     * Возвращает список объектов данного типа.
     */
    ObjectVersionsResponse GetObjectsByType (
        1: Version version
        2: domain.DomainObjectTypes type
        3: RequestParams request_params
    )
        throws (1: ObjectTypeNotFound ex1)

    SearchResponse SearchObjects (
        1: SearchRequestParams request_params
    )
        throws (1: ObjectTypeNotFound ex1)
}

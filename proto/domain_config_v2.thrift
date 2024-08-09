/**
 * Интерфейс и связанные с ним определения сервиса конфигурации предметной
 * области (domain config).
 */

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.domain_config_v2
namespace erlang dmsl.domain_conf_v2

typedef string UserOpID
typedef string UserOpEmail
typedef string UserOpName

struct UserOpParams {
    1: required UserOpEmail email
    2: required UserOpName name
}

struct UserOp {
    1: required UserOpID id
    2: required UserOpEmail email
    3: required UserOpName name
}

exception UserOpNotFound {}

service UserOpManagement {
    UserOp Create (1: UserOpParams params)

    UserOp Get (1: UserOpID id)
        throws (1: UserOpNotFound ex1)

    void Delete (1: UserOpID id)
        throws (1: UserOpNotFound ex1)
}

typedef string ContinuationToken

/**
 * Маркер вершины истории.
 */
struct GlobalHead {}
struct Head {}

typedef i64 BaseVersion
typedef i32 Limit

union VersionReference {
    1: BaseVersion version
    2: Head head
}

union ScopedReference {
    1: VersionReference global_ref
    2: VersionReference local_ref
}

union Version {
    1: BaseVersion global_vs
    2: BaseVersion local_vs
}

/**
 * Возможные операции над набором объектов.
 */

struct Commit {
    1: required list<Operation> ops
}

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
// targeted_ref - ID объекта, который нужно обновить
// targeted_version - версия объекта, которую нужно обновить,
//                    может быть как глобальной для всего конфига,
//                    так и локальной для конкретного объекта.
//                    Если версия объекта изменилась до момента
//                    создания запроса, то вернется исключение
// new_object - новая версия объекта
struct UpdateOp {
    1: required domain.Reference targeted_ref
    2: required Version targeted_version
    3: required domain.DomainObject new_object
}

// Мягкое удаление объекта,
// в будущих версиях объект будет недоступен, но доступен в прошлых версиях
struct RemoveOp {
    1: required domain.Reference ref
}

struct VersionedObject {
    1: required Version global_version
    2: required Version local_version
    3: required domain.DomainObject object
    4: required base.Timestamp created_at
}

struct ObjectVersion {
    1: required domain.Reference ref
    2: required Version global_version
    3: required Version local_version
    4: required base.Timestamp created_at
    5: required UserOp author
}

struct GetLocalVersionsRequest {
    1: required domain.Reference ref
    2: required i32 limit
    3: optional ContinuationToken continuation_token
}

struct GetGlobalVersionsRequest {
    1: required i32 limit
    2: optional ContinuationToken continuation_token
}

struct GetVersionsResponse {
    1: required list<ObjectVersion> result
    2: optional ContinuationToken continuation_token
}

/**
 * Требуемая версия отсутствует
 */
exception LocalVersionNotFound {}

/**
 * Требуемая глобальная версия отсутствует
 */
exception GlobalVersionNotFound {}

/**
 * Объект не найден в домене
 */
exception ObjectNotFound {}

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
}

struct ObjectReferenceCycle {
    1: required list<domain.Reference> cycle
}

struct NonexistantObject {
    1: required domain.Reference object_ref
    2: required list<domain.Reference> referenced_by
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
    VersionedObject CheckoutObject (
        1: VersionReference version_ref
        2: domain.Reference object_ref
    )
        throws (
            1: VersionNotFound ex1
            2: ObjectNotFound ex2
        )
    
    GetVersionsResponse GetLocalVersions (1: GetLocalVersionsRequest req)
        throws (
            1: ObjectNotFound ex1
        )

    GetVersionsResponse GetGlobalVersions (1: GetGlobalVersionsRequest req)

}

service Repository {

    /**
     * Применить изменения к определенной глобальной версии.
     * Возвращает следующую версию
     */
    BaseVersion Commit (
        1: BaseVersion global_version
        2: Commit commit
        3: UserOpID user_op_id
    )
        throws (
            1: VersionNotFound ex1
            2: OperationConflict ex2
            3: OperationInvalid ex3
            4: ObsoleteCommitVersion ex4
            5: UserOpNotFound ex5
        )
}

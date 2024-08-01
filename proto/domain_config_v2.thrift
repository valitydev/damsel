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

typedef i64 GlobalVersion
typedef i64 LocalVersion
typedef i32 Limit

union GlobalVersionReference {
    1: GlobalVersion version
    2: GlobalHead head
}

union LocalVersionReference {
    1: LocalVersion version
    2: Head head
}

union VersionReference {
    1: GlobalVersionReference global
    2: LocalVersionReference local
}

union Version {
    1: GlobalVersion global
    2: LocalVersion local
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

struct InsertOp {
    1: required domain.ReflessDomainObject object
    2: optional domain.Reference force_ref
}

struct UpdateOp {
    1: required domain.Reference targeted_ref
    2: required Version targeted_version
    3: required domain.DomainObject new_object
}

struct RemoveOp {
    1: required domain.Reference ref
}

struct VersionedObject {
    1: required GlobalVersion global_version
    2: required LocalVersion version
    3: required domain.DomainObject object
    4: required base.Timestamp created_at
}

struct ObjectVersion {
    1: required domain.Reference ref
    2: required GlobalVersion global_version
    3: required LocalVersion version
    4: required base.Timestamp created_at
    5: required UserOp author
}

struct GetObjectVersionsRequest {
    1: required domain.Reference ref
    2: required i32 limit
    3: optional ContinuationToken continuation_token
}

struct GetObjectVersionsResponse {
    1: required list<ObjectVersion> result
    2: optional ContinuationToken continuation_token
}

struct GetGlobalVersionsRequest {
    1: required i32 limit
    2: optional ContinuationToken continuation_token
}

struct GetGlobalVersionsResponse {
    1: required list<ObjectVersion> result
    2: optional ContinuationToken continuation_token
}

/**
 * Требуемая версия отсутствует
 */
exception VersionNotFound {}

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

/**
 * Интерфейс сервиса конфигурации предметной области.
 */
service RepositoryClient {

    /**
     * Возвращает объект из домена определенной или последней версии
     */
    VersionedObject checkoutObject (
        1: VersionReference version_ref
        2: domain.Reference object_ref
    )
        throws (
            1: VersionNotFound ex1
            2: ObjectNotFound ex2
        )
    
    GetObjectVersionsResponse GetObjectVersions (1: GetObjectVersionsRequest req)
        throws (
            1: ObjectNotFound ex1
        )

    GetGlobalVersionsResponse GetGlobalVersions (1: GetGlobalVersionsResponse req)

}

service Repository {

    /**
     * Применить изменения к определенной версии.
     * Возвращает следующую версию
     */
    LocalVersion Commit (
        1: LocalVersion version
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

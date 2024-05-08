/**
 * Интерфейс и связанные с ним определения сервиса конфигурации предметной
 * области (domain config).
 */

include "base.thrift"
include "domain.thrift"

namespace java dev.vality.damsel.domain_config
namespace erlang dmsl.domain_conf

/**
 * Маркер вершины истории.
 */
struct Head {}

typedef i64 Version
typedef i32 Limit

/**
 * Референс может указывать либо на конкретную
 * версию либо на наиболее актуальную.
 */
union Reference {
    1: Version version
    2: Head head
}

/**
 * Снэпшот это определенная версия данных
 * конфигурации домена
 */
struct Snapshot {
    1: required Version version
    2: required domain.Domain domain
    /*
     * Отметка времени создания этой версии снепшота или изменения
     * версии конфига.
     */
    3: optional base.Timestamp created_at
}

/**
 * Возможные операции над набором объектов.
 */

struct Commit {
    1: required list<Operation> ops
    2: optional base.Timestamp created_at
}

/**
 * История это последовательность коммитов
 */
typedef map<Version, Commit> History

union Operation {
    1: InsertOp insert
    2: UpdateOp update
    3: RemoveOp remove
}

struct InsertOp {
    1: required domain.DomainObject object
}

/**
 * Содержит значения до и после внесенных изменений
 */
struct UpdateOp {
    1: required domain.DomainObject old_object
    2: required domain.DomainObject new_object
}

struct RemoveOp {
    1: required domain.DomainObject object
}

struct VersionedObject {
    1: required Version version
    2: required domain.DomainObject object
    /*
     * Нет возможности отслеживать отметку времени изменения
     * конкретного объекта, но можно точно знать (в соответствии с
     * версией снепшота) отметку которой этот объект современен.
     */
    3: optional base.Timestamp contemporary_at
}

/**
 * Требуемая версия отсутствует
 */
exception VersionNotFound {}

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
    2: ObjectNotFoundConflict object_not_found
    3: ObjectReferenceMismatchConflict object_reference_mismatch

    // deprecated
    // 4: ObjectsNotExistConflict objects_not_exist
}

struct ObjectAlreadyExistsConflict {
    1: required domain.Reference object_ref
}

struct ObjectNotFoundConflict {
    1: required domain.Reference object_ref
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
exception ObsoleteCommitVersion {}

/**
 * Интерфейс сервиса конфигурации предметной области.
 */
service RepositoryClient {

    /**
     * Возвращает объект из домена определенной или последней версии
     */
    VersionedObject checkoutObject (1: Reference version_ref, 2: domain.Reference object_ref)
        throws (1: VersionNotFound ex1, 2: ObjectNotFound ex2);

}

service Repository {

    /**
     * Применить изменения к определенной версии.
     * Возвращает следующую версию
     */
    Version Commit (1: Version version, 2: Commit commit)
        throws (
            1: VersionNotFound ex1
            2: OperationConflict ex2
            4: OperationInvalid ex4
            3: ObsoleteCommitVersion ex3
        )

    /**
     * Получить снэпшот конкретной версии
     */
    Snapshot Checkout (1: Reference reference)
        throws (1: VersionNotFound ex1)

    /**
     * Получить новые коммиты следующие за указанной версией
     */
    History PullRange (1: Version after, 2: Limit limit)
        throws (1: VersionNotFound ex1)

    // Deprecated
    History Pull (1: Version version)
        throws (1: VersionNotFound ex1)

}

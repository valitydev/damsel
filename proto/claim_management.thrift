namespace java dev.vality.damsel.claim_management
namespace erlang dmsl.claimmgmt

include "base.thrift"
include "domain.thrift"
include "msgpack.thrift"

typedef base.ClaimID ClaimID
typedef i64 ModificationID
typedef base.ClaimRevision ClaimRevision
typedef string ContinuationToken
typedef base.ID FileID
typedef base.ID DocumentID
typedef base.ID CommentID
typedef base.ID UserID
typedef base.ID CashRegisterID
typedef base.ID IdentityID
typedef base.ID WalletID
typedef i32 CashRegisterProviderID

typedef string MetadataKey
typedef msgpack.Value MetadataValue
typedef map<MetadataKey, MetadataValue> Metadata

typedef list<ModificationUnit> ClaimChangeset
typedef list<Modification> ModificationChangeset

exception ClaimNotFound {}
exception ModificationNotFound { 1: required i64 modification_id }
exception ModificationWrongType {}
exception PartyNotFound {}
exception InvalidClaimRevision {}
exception BadContinuationToken { 1: string reason }
exception LimitExceeded { 1: string reason }
exception ChangesetConflict { 1: required ClaimID conflicted_id }

union InvalidStatus {
    1: domain.Blocking blocking
    2: domain.Suspension suspension
}

union InvalidChangesetReason {
    1: InvalidClaimChangesetReason invalid_claim_changeset
    2: InvalidPartyChangesetReason invalid_party_changeset
    3: InvalidIdentityChangesetReason invalid_identity_changeset
    4: InvalidNewWalletChangesetReason invalid_wallet_changeset
}

// TODO: Fill with claim modification errors
union InvalidClaimChangesetReason{}

// Placeholder type for reasons without additional information
struct InvalidClaimConcreteReason{}

struct InvalidIdentityChangesetReason {
    1: required IdentityID id
    2: required InvalidIdentityReason reason
}

union InvalidIdentityReason {
    1: InvalidClaimConcreteReason already_exists
    2: InvalidClaimConcreteReason provider_not_found
    3: InvalidClaimConcreteReason party_inaccessible
}

struct InvalidNewWalletChangesetReason {
    1: required WalletID id
    2: required InvalidNewWalletReason reason
}

union InvalidNewWalletReason {
    1: InvalidClaimConcreteReason already_exists
    2: InvalidClaimConcreteReason identity_not_found
    3: InvalidClaimConcreteReason currency_not_found
    4: InvalidClaimConcreteReason currency_not_allowed
    5: InvalidClaimConcreteReason party_inaccessible
}

union InvalidPartyChangesetReason {
    1: InvalidContract invalid_contract
    2: InvalidShop invalid_shop
    3: InvalidWallet invalid_wallet
    4: InvalidContractor invalid_contractor
}

struct InvalidContract {
    1: required domain.ContractID id
    2: required InvalidContractReason reason
}

struct InvalidShop {
    1: required domain.ShopID id
    2: required InvalidShopReason reason
}

struct InvalidWallet {
    1: required domain.WalletID id
    2: required InvalidWalletReason reason
}

struct InvalidContractor {
    1: required domain.ContractorID id
    2: required InvalidContractorReason reason
}

union InvalidContractReason {
    1: InvalidClaimConcreteReason not_exists
    2: InvalidClaimConcreteReason already_exists
    3: domain.ContractStatus invalid_status
    4: domain.ContractAdjustmentID contract_adjustment_already_exists
    7: InvalidObjectReference invalid_object_reference
    8: ContractorNotExists contractor_not_exists

    // Deprecated
    5: domain.PayoutToolID payout_tool_not_exists
    6: domain.PayoutToolID payout_tool_already_exists
}

union InvalidShopReason {
    1: InvalidClaimConcreteReason not_exists
    2: InvalidClaimConcreteReason already_exists
    3: InvalidClaimConcreteReason account_not_exists
    4: InvalidStatus invalid_status
    5: ContractTermsViolated contract_terms_violated
    7: InvalidObjectReference invalid_object_reference

    // Deprecated
    6: InvalidShopPayoutTool payout_tool_invalid
}

union InvalidWalletReason {
    1: InvalidClaimConcreteReason not_exists
    2: InvalidClaimConcreteReason already_exists
    3: InvalidClaimConcreteReason account_not_exists
    4: InvalidStatus invalid_status
    5: ContractTermsViolated contract_terms_violated
}

union InvalidContractorReason {
    1: InvalidClaimConcreteReason not_exists
    2: InvalidClaimConcreteReason already_exists
}

struct ContractorNotExists {
    1: optional domain.ContractorID id
}

struct ContractTermsViolated {
    1: required domain.ContractID contract_id
    2: required domain.TermSet terms
}

// Deprecated
union InvalidShopPayoutTool {
    1: PayoutToolNotSetForPayouts not_set_for_payouts
    2: PayoutToolCurrencyMismatch currency_mismatch
    3: PayoutToolNotInContract not_in_contract
}

struct PayoutToolNotSetForPayouts {
    1: required domain.BusinessScheduleRef payout_schedule
}

struct PayoutToolCurrencyMismatch {
    1: required domain.CurrencyRef shop_account_currency
    2: required domain.PayoutToolID payout_tool_id
    3: required domain.CurrencyRef payout_tool_currency
}

struct PayoutToolNotInContract {
    1: required domain.ContractID contract_id
    2: required domain.PayoutToolID payout_tool_id
}

struct InvalidObjectReference {
    1: optional domain.Reference ref
}

exception InvalidChangeset {
    3: optional InvalidChangesetReason reason
    2: required ModificationChangeset invalid_changeset
    1: optional string reason_legacy
}
exception InvalidClaimStatus {
    1: required ClaimStatus status
}
exception MetadataKeyNotFound {}

struct UserInfo {
    1: required UserID id
    2: required string email
    3: required string username
    4: required UserType type
}

union UserType {
    1: InternalUser internal_user
    2: ExternalUser external_user
}

struct InternalUser {}

struct ExternalUser {}

struct ScheduleChanged {
    1: optional domain.BusinessScheduleRef schedule
}

struct ShopContractChanged {
    1: required domain.ContractID contract_id

    // Deprecated
    2: optional domain.PayoutToolID payout_tool_id
}

// Deprecated
struct PayoutToolParams {
    1: required domain.CurrencyRef currency
    2: required domain.PayoutToolInfo tool_info
}

struct ContractParams {
    1: optional domain.ContractorID contractor_id
    2: optional domain.ContractTemplateRef template
    3: optional domain.PaymentInstitutionRef payment_institution
}

struct ShopModificationUnit {
    1: required domain.ShopID id
    2: required ShopModification modification
}

struct ShopContractModification {
    1: required domain.ContractID contract_id

    // Deprecated
    2: optional domain.PayoutToolID payout_tool_id
}

struct ScheduleModification {
    1: optional domain.BusinessScheduleRef schedule
}

struct ShopAccountParams {
    1: required domain.CurrencyRef currency
}

union ShopModification {
    1: ShopParams creation
    2: domain.CategoryRef category_modification
    3: domain.ShopDetails details_modification
    4: ShopContractModification contract_modification
    6: domain.ShopLocation location_modification
    7: ShopAccountParams shop_account_creation
    9: CashRegisterModificationUnit cash_register_modification_unit
    10: set<domain.TurnoverLimit> turnover_limits_modification

    // Deprecated
    5: domain.PayoutToolID payout_tool_modification
    8: ScheduleModification payout_schedule_modification
}

struct ShopParams {
    1: required domain.CategoryRef category
    2: required domain.ShopLocation location
    3: required domain.ShopDetails details
    4: required domain.ContractID contract_id

    // Deprecated
    5: optional domain.PayoutToolID payout_tool_id
}

struct CashRegisterModificationUnit {
    1: required CashRegisterID id
    2: required CashRegisterModification modification
}

union CashRegisterModification {
    1: CashRegisterParams creation
}

struct CashRegisterParams {
    1: required CashRegisterProviderID cash_register_provider_id
    2: required base.StringMap cash_register_provider_params
}

struct ContractorModificationUnit {
    1: required domain.ContractorID id
    2: required ContractorModification modification
}

union ContractorModification {
    1: domain.Contractor creation
    2: domain.ContractorIdentificationLevel identification_level_modification
}

struct ContractModificationUnit {
    1: required domain.ContractID id
    2: required ContractModification modification
}

union ContractModification {
    1: ContractParams creation
    2: ContractTermination termination
    3: ContractAdjustmentModificationUnit adjustment_modification
    5: domain.LegalAgreement legal_agreement_binding
    6: domain.ReportPreferences report_preferences_modification
    7: domain.ContractorID contractor_modification

    // Deprecated
    4: PayoutToolModificationUnit payout_tool_modification
}

struct ContractTermination {
    1: optional string reason
}

struct ContractAdjustmentModificationUnit {
    1: required domain.ContractAdjustmentID adjustment_id
    2: required ContractAdjustmentModification modification
}

struct ContractAdjustmentParams {
    1: required domain.ContractTemplateRef template
}

union ContractAdjustmentModification {
    1: ContractAdjustmentParams creation
}

// Deprecated
struct PayoutToolModificationUnit {
    1: required domain.PayoutToolID payout_tool_id
    2: required PayoutToolModification modification
}

union PayoutToolModification {
    1: PayoutToolParams creation
    2: domain.PayoutToolInfo info_modification
}

struct WalletModificationUnit {
    1: required domain.WalletID id
    2: required WalletModification modification
}

union WalletModification {
    1: WalletParams creation
    2: WalletAccountParams account_creation
}

struct WalletParams {
    1: optional string name
    2: required domain.ContractID contract_id
}

struct WalletAccountParams {
    1: required domain.CurrencyRef currency
}

union DocumentModification {
    1: DocumentCreated creation
    2: DocumentChanged changed
}

struct DocumentCreated {}
struct DocumentChanged {}

struct DocumentModificationUnit {
    1: required DocumentID id
    2: required DocumentModification modification
    3: optional domain.DocumentTypeRef type
}

union FileModification {
    1: FileCreated creation
    2: FileDeleted deletion
    3: FileChanged changed
}

struct FileCreated {}
struct FileDeleted {}
struct FileChanged {}

struct FileModificationUnit {
    1: required FileID id
    2: required FileModification modification
}

union CommentModification {
    1: CommentCreated creation
    2: CommentDeleted deletion
    3: CommentChanged changed
}

struct CommentCreated {}
struct CommentDeleted {}
struct CommentChanged {}

struct CommentModificationUnit {
    1: required CommentID id
    2: required CommentModification modification
}

struct StatusChanged {}

union StatusModification {
    1: StatusChanged change
}

struct StatusModificationUnit {
    1: required ClaimStatus status
    2: required StatusModification modification
}

struct ExternalInfoModificationUnit {
    1: required DocumentID document_id
    2: optional DocumentID roistat_id
}

union ClaimModification {
    1: DocumentModificationUnit document_modification
    2: FileModificationUnit file_modification
    3: CommentModificationUnit comment_modification
    4: StatusModificationUnit status_modification
    5: ExternalInfoModificationUnit external_info_modification
}

struct AdditionalInfoModificationUnit {
    1: optional string party_name
    2: optional list<string> manager_contact_emails
    3: optional string comment
}

union PartyModification {
    1: ContractorModificationUnit contractor_modification
    2: ContractModificationUnit contract_modification
    3: ShopModificationUnit shop_modification
    4: WalletModificationUnit wallet_modification
    5: AdditionalInfoModificationUnit additional_info_modification
}

struct IdentityModificationUnit {
    1: required IdentityID id
    2: required IdentityModification modification
}

union IdentityModification {
    1: IdentityParams creation
}

struct NewWalletModificationUnit {
    1: required WalletID id
    2: required NewWalletModification modification
}

union NewWalletModification {
    1: NewWalletParams creation
}

union PartyModificationChange {
    1: ContractorModificationUnit contractor_modification
    2: ContractModificationUnit contract_modification
    3: ShopModificationUnit shop_modification
    4: AdditionalInfoModificationUnit additional_info_modification
}

union ClaimModificationChange {
    1: DocumentModificationUnit document_modification
    2: FileModificationUnit file_modification
    3: CommentModificationUnit comment_modification
}

struct IdentityParams {
    1: required domain.PartyID party_id
    2: required string name
    3: required string provider
    4: optional Metadata metadata
}

struct NewWalletParams {
    1: required IdentityID identity_id
    2: required string name
    3: required domain.CurrencyRef currency
    4: optional Metadata metadata
}

struct ModificationUnit {
    1: required ModificationID modification_id
    2: required base.Timestamp created_at
    3: required Modification modification
    4: required UserInfo user_info
    5: optional base.Timestamp changed_at
    6: optional base.Timestamp removed_at
}

union Modification {
    1: PartyModification party_modification
    2: ClaimModification claim_modification
    3: IdentityModificationUnit identity_modification
    4: NewWalletModificationUnit wallet_modification
}

union ModificationChange {
    1: PartyModificationChange party_modification
    2: ClaimModificationChange claim_modification
    3: IdentityModificationUnit identity_modification
    4: NewWalletModificationUnit wallet_modification
}

struct Claim {
    1: required ClaimID id
    8: required domain.PartyID party_id
    2: required ClaimStatus status
    3: required ClaimChangeset changeset
    4: required ClaimRevision revision
    5: required base.Timestamp created_at
    6: optional base.Timestamp updated_at
    7: optional Metadata metadata
}

union ClaimStatus {
    1: ClaimPending pending
    2: ClaimReview review
    3: ClaimPendingAcceptance pending_acceptance
    4: ClaimAccepted accepted
    5: ClaimDenied denied
    6: ClaimRevoked revoked
}

struct ClaimPending {}

struct ClaimReview {}

struct ClaimPendingAcceptance {}

struct ClaimAccepted {}

struct ClaimDenied {
    1: optional string reason
}

struct ClaimRevoked {
    1: optional string reason
}

struct ClaimSearchQuery {
    1: optional domain.PartyID party_id
    5: optional ClaimID claim_id
    2: optional list<ClaimStatus> statuses
    6: optional string email
    3: optional ContinuationToken continuation_token
    4: required i32 limit
}

struct ClaimSearchResponse {
    1: required list<Claim> result
    2: optional ContinuationToken continuation_token
}

struct Event {
    1: required base.Timestamp occured_at
    2: required Change         change
    3: optional UserInfo user_info
}

union Change {
    1: ClaimCreated          created
    2: ClaimUpdated          updated
    3: ClaimStatusChanged    status_changed
}

struct ClaimCreated {
    1: required domain.PartyID     party_id
    2: required ClaimID            id
    3: required ModificationChangeset changeset
    4: required ClaimRevision      revision
    5: required base.Timestamp     created_at
}

struct ClaimUpdated {
    1: required domain.PartyID     party_id
    2: required ClaimID            id
    3: required ModificationChangeset changeset
    4: required ClaimRevision      revision
    5: required base.Timestamp     updated_at
}

struct ClaimStatusChanged {
    1: required domain.PartyID party_id
    2: required ClaimID        id
    3: required ClaimStatus    status
    4: required ClaimRevision  revision
    5: required base.Timestamp updated_at
}

service ClaimManagement {

        Claim CreateClaim (1: domain.PartyID party_id, 2: ModificationChangeset changeset)
            throws (1: InvalidChangeset ex1)

        Claim GetClaim (1: domain.PartyID party_id, 2: ClaimID id)
            throws (1: ClaimNotFound ex1)

        ClaimSearchResponse SearchClaims (1: ClaimSearchQuery claim_request)
                throws (1: LimitExceeded ex1, 2: BadContinuationToken ex2)

        void AcceptClaim (1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3
                )

        void UpdateClaim (1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision, 4: ModificationChangeset changeset)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3,
                    4: ChangesetConflict ex4,
                    5: InvalidChangeset ex5
                )

        void UpdateModification(
                    1: domain.PartyID party_id,
                    2: ClaimID id,
                    3: ClaimRevision revision,
                    4: ModificationID modification_id,
                    5: ModificationChange modification_change)
                throws (
                    1: ModificationNotFound ex1,
                    2: ModificationWrongType ex2
                )

        void RemoveModification(
                    1: domain.PartyID party_id,
                    2: ClaimID id,
                    3: ClaimRevision revision,
                    4: ModificationID modification_id)
                throws (
                    1: ModificationNotFound ex1,
                    2: ModificationWrongType ex2
                )

        void RequestClaimReview(1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3
                )

        void RequestClaimChanges(1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3
                )

        void DenyClaim (1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision, 4: string reason)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3
                )

        void RevokeClaim (1: domain.PartyID party_id, 2: ClaimID id, 3: ClaimRevision revision, 4: string reason)
                throws (
                    1: ClaimNotFound ex1,
                    2: InvalidClaimStatus ex2,
                    3: InvalidClaimRevision ex3
                )

        MetadataValue GetMetadata (1: domain.PartyID party_id, 2: ClaimID id, 3: MetadataKey key)
                throws (1: ClaimNotFound ex1, 2: MetadataKeyNotFound ex2)

        void SetMetadata (1: domain.PartyID party_id, 2: ClaimID id, 3: MetadataKey key, 4: MetadataValue value)
                throws (1: ClaimNotFound ex1)

        void RemoveMetadata (1: domain.PartyID party_id, 2: ClaimID id, 3: MetadataKey key)
                throws (1: ClaimNotFound ex1)

}

service ClaimCommitter {

        void Accept (1: domain.PartyID party_id, 2: Claim claim)
                throws (
                    1: PartyNotFound ex1,
                    2: InvalidChangeset ex2
                )

        void Commit (1: domain.PartyID party_id, 2: Claim claim)
}

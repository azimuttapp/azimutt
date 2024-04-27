import {groupBy, indexBy, isNotUndefined} from "@azimutt/utils";
import {AttributeName, Database, Entity, EntityId, Relation} from "../database";
import {entityRefToId, entityToId} from "../databaseUtils";
import {isPrimaryKeysMissing} from "./rules/primaryKeyMissing";
import {getMisalignedRelation, RelationMisaligned} from "./rules/relationMisaligned";
import {AttributeWithRef, getInconsistentAttributeTypes} from "./rules/attributeInconsistentType";
import {getDuplicatedIndexes, IndexDuplicated} from "./rules/indexDuplicated";
import {getMissingIndexOnRelation, MissingIndex} from "./rules/indexOnRelation";
import {checkNamingConsistency, InconsistentNaming} from "./rules/namingConsistency";
import {getMissingRelations} from "./rules/relationMissing";

export * from "./rule"

export function analyzeDatabase(db: Database) {
    const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
    const relations: Record<EntityId, Relation[]> = groupBy(db.relations || [], r => entityRefToId(r.src))
    const missingPrimaryKeys: Entity[] = (db.entities || []).filter(isPrimaryKeysMissing)
    const misalignedRelations: RelationMisaligned[] = (db.relations || []).map(r => getMisalignedRelation(r, entities)).filter(isNotUndefined)
    const inconsistentAttributeTypes: Record<AttributeName, AttributeWithRef[]> = getInconsistentAttributeTypes(db.entities || [])
    const duplicatedIndexes: IndexDuplicated[] = (db.entities || []).flatMap(getDuplicatedIndexes)
    const missingIndexOnRelations: MissingIndex[] = (db.relations || []).flatMap(r => getMissingIndexOnRelation(r, entities))
    const inconsistentNaming: InconsistentNaming = checkNamingConsistency(db.entities || [])
    const missingRelations: Relation[] = getMissingRelations(db.entities || [], db.relations || [])
// TODO: tables with too many columns
// TODO: tables with too many indexes
// TODO: tables with too heavy indexes
// TODO: tables without indexes
// TODO: unused index
// TODO: unused table
// TODO: slow queries
// TODO: queries not using indexes
// TODO: JSON columns with different schemas
// TODO: sequence/auto_increment exhaustion
// TODO: no business primary key
}

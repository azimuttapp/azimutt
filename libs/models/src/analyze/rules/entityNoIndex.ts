import {Entity} from "../../database";

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableWithoutIndex.elm
export function hasEntityNoIndex(entity: Entity): boolean {
    return entity.pk === undefined && (entity.indexes || []).length === 0
}

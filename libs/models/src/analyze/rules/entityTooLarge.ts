import {Entity} from "../../database";

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableTooBig.elm
export function isEntityTooLarge(entity: Entity): boolean {
    return entity.attrs.length > 30
}

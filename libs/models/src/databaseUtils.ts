import {filterValues} from "@azimutt/utils";
import {
    AttributeId,
    AttributePath,
    AttributePathId,
    AttributeRef,
    AttributeType,
    AttributeTypeParsed,
    EntityId,
    EntityRef,
    Namespace,
    NamespaceId
} from "./database";

export function formatNamespace(n: Namespace): NamespaceId {
    return [
        n.database || '',
        n.catalog || '',
        n.schema || ''
    ].map(addQuotes).join('.').replace(/^\.+/, '')
}

export function parseNamespace(id: NamespaceId): Namespace {
    const [schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    return filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
}

export function formatEntityRef(ref: EntityRef): EntityId {
    const ns = formatNamespace(ref)
    return ns ? `${ns}.${ref.entity}` : addQuotes(ref.entity)
}

export function parseEntityRef(id: EntityId): EntityRef {
    const [entity, schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    const namespace = filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
    return {...namespace, entity}
}

export function formatAttributePath(path: AttributePath): AttributePathId {
    return path.join('.')
}

export function parseAttributePath(path: AttributePathId): AttributePath {
    return path.split('.')
}

export function formatAttributeRef(ref: AttributeRef): AttributeId {
    return `${formatEntityRef(ref)}(${ref.attribute})`
}

export function parseAttributeRef(id: AttributeId): AttributeRef {
    const [, entityId, attributeId] = id.match(/^(.*)\((.*)\)$/) || []
    const entity = parseEntityRef(entityId || id)
    const attribute = parseAttributePath(attributeId || '')
    return {...entity, attribute}
}

export function parseAttributeType(type: AttributeType): AttributeTypeParsed {
    return {full: type, kind: 'unknown'}
}

function addQuotes(value: string): string {
    if (value.match(/^\w*$/)) {
        return value
    } else {
        return `"${value}"`
    }
}

function removeQuotes(value: string): string {
    if (value.startsWith('"') && value.endsWith('"')) {
        return value.slice(1, -1)
    } else {
        return value
    }
}

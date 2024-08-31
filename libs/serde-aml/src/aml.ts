import {removeEmpty, removeUndefined} from "@azimutt/utils";
import {Attribute, Database, Entity, Namespace, ParserResult} from "@azimutt/models";
import * as parser from "./parser";

export function parse(content: string): ParserResult<Database> {
    // return ParserResult.failure([{name: 'GlobalException', message: 'Not implemented'}])
    return parser.parse(content).map(buildDatabase)
}

export function generate(database: Database): string {
    return 'Not implemented'
}

function buildDatabase(ast: parser.AmlAst): Database {
    const db: Database = {entities: [], relations: [], types: []}
    let namespace: Namespace = {}
    ast.forEach(stmt => {
        if (stmt.statement === 'Namespace') {
            namespace = buildNamespace(stmt, namespace)
        } else if (stmt.statement === 'Entity') {
            db.entities?.push(buildEntity(stmt, namespace)) // TODO: check is entity already exists
        } else if (stmt.statement === 'Relation') {
            // TODO: relation
        } else if (stmt.statement === 'Type') {
            // TODO: type
        } else {
            // Empty: do nothing
        }
    })
    return removeEmpty(db)
}

function buildNamespace(n: parser.NamespaceAst, current: Namespace): Namespace {
    const schema = n.schema.identifier
    const catalog = n.catalog?.identifier || current.catalog
    const database = n.database?.identifier || current.database
    return {schema, catalog, database}
}

function buildEntity(e: parser.EntityAst, namespace: Namespace): Entity {
    const entityNamespace = removeUndefined({schema: e.schema?.identifier, catalog: e.catalog?.identifier, database: e.database?.identifier})
    return {
        ...namespace,
        ...entityNamespace,
        name: e.name.identifier,
        attrs: e.attrs.map(buildAttribute)
    }
}

function buildAttribute(a: parser.AttributeAst): Attribute {
    return {
        name: a.name.identifier,
        type: a.type?.identifier || 'unknown'
    }
}

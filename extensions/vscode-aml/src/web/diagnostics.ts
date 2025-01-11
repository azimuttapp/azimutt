import {Diagnostic, DiagnosticSeverity} from "vscode";
import {groupBy, isNever} from "@azimutt/utils";
import {EntityId, entityRefToId, ParserError, ParserErrorLevel} from "@azimutt/models";
// @ts-ignore
import {EntityStatement, TokenInfo} from "@azimutt/aml/out/amlAst";
import {AmlDocument} from "./cache";
import {tokenToRange} from "./utils";

export function computeDiagnostics(doc: AmlDocument): Diagnostic[] {
    const entities: EntityStatement[] = doc.ast?.statements.filter(s => s.kind === 'Entity') || []
    const entitiesById: Record<EntityId, EntityStatement[]> = groupBy(entities, entityId)
    return doc.errors.concat(
        duplicateEntities(entitiesById),
        // TODO: duplicateAttributes()
        // TODO: badRelationRef()
        // TODO: badTypeForRelation()
    ).map(e => new Diagnostic(tokenToRange(e.position), e.message, levelToSeverity(e.level)))
}

function duplicateEntities(entitiesById: Record<EntityId, EntityStatement[]>): ParserError[] {
    return Object.values(entitiesById).filter(e => e.length > 1).flatMap(dups => dups.slice(1).map(e => {
        return warning(`'${e.name.value}' already defined at line ${dups[0].name.token.position.start.line}`, e.name.token)
    }))
}

const warning = (message: string, pos: TokenInfo): ParserError => ({...pos, message, kind: '', level: ParserErrorLevel.enum.warning})
const entityId = (e: EntityStatement): EntityId => entityRefToId({database: e.database?.value, catalog: e.catalog?.value, schema: e.schema?.value, entity: e.name.value})

function levelToSeverity(level: ParserErrorLevel): DiagnosticSeverity {
    if (level === ParserErrorLevel.enum.error) { return DiagnosticSeverity.Error }
    else if (level === ParserErrorLevel.enum.warning) { return DiagnosticSeverity.Warning }
    else if (level === ParserErrorLevel.enum.info) { return DiagnosticSeverity.Information }
    else if (level === ParserErrorLevel.enum.hint) { return DiagnosticSeverity.Hint }
    return isNever(level)
}

import {z} from "zod";
import {mapValues, removeUndefined} from "@azimutt/utils";
import {
    columnPathSeparator,
    columnValueFromLegacy,
    columnValueToLegacy,
    LegacyColumnName,
    LegacyColumnType,
    LegacyColumnValue,
    LegacySchemaName,
    LegacyTableName
} from "./legacyDatabase";
import {ConnectorAttributeStats, ConnectorAttributeStatsValue, ConnectorEntityStats} from "../interfaces/connector";
import {AttributeRef, AttributeType} from "../database";

export const LegacyTableSampleValues = z.record(LegacyColumnValue)
export type LegacyTableSampleValues = z.infer<typeof LegacyTableSampleValues>

// keep sync with frontend/src/Models/Project/TableStats.elm
export const LegacyTableStats = z.object({
    schema: LegacySchemaName.nullable(),
    table: LegacyTableName,
    rows: z.number(),
    sample_values: LegacyTableSampleValues
}).strict()
export type LegacyTableStats = z.infer<typeof LegacyTableStats>

export function tableStatsFromLegacy(s: LegacyTableStats): ConnectorEntityStats {
    return removeUndefined({
        schema: s.schema || undefined,
        entity: s.table,
        rows: s.rows,
        sampleValues: mapValues(s.sample_values, columnValueFromLegacy)
    })
}

export function tableStatsToLegacy(s: ConnectorEntityStats): LegacyTableStats {
    return {
        schema: s.schema || null,
        table: s.entity,
        rows: s.rows,
        sample_values: mapValues(s.sampleValues, columnValueToLegacy)
    }
}

export const LegacyColumnCommonValue = z.object({value: LegacyColumnValue, count: z.number()})
export type LegacyColumnCommonValue = z.infer<typeof LegacyColumnCommonValue>

// keep sync with frontend/src/Models/Project/ColumnStats.elm
export const LegacyColumnStats = z.object({
    schema: LegacySchemaName.nullable(),
    table: LegacyTableName,
    column: LegacyColumnName,
    type: LegacyColumnType,
    rows: z.number(),
    nulls: z.number(),
    cardinality: z.number(),
    common_values: LegacyColumnCommonValue.array()
}).strict()
export type LegacyColumnStats = z.infer<typeof LegacyColumnStats>

export function columnStatsFromLegacy(s: LegacyColumnStats): ConnectorAttributeStats {
    return {
        schema: s.schema || undefined,
        entity: s.table,
        attribute: [s.column],
        type: s.type,
        rows: s.rows,
        nulls: s.nulls,
        cardinality: s.cardinality,
        commonValues: s.common_values.map(({value, count}) => ({value: columnValueFromLegacy(value), count}))
    }
}

export function columnStatsToLegacy(s: ConnectorAttributeStats): LegacyColumnStats {
    return {
        schema: s.schema || null,
        table: s.entity,
        column: s.attribute.join(columnPathSeparator),
        type: s.type,
        rows: s.rows,
        nulls: s.nulls,
        cardinality: s.cardinality,
        common_values: s.commonValues.map(({value, count}) => ({value: columnValueToLegacy(value), count}))
    }
}

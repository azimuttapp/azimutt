import {removeUndefined} from "@azimutt/utils";
import {ConnectorQueryHistoryOpts, DatabaseQuery, handleError} from "@azimutt/models";
import {Conn} from "./connect";
import {getTableColumns, scopeOp, scopeValue} from "./helpers";

export type RawQuery = {
    database_id: number
    database_name: string
    // query_owner: string
    query_id: number
    query: string
    plan_count: number
    plan_time_total: number
    plan_time_min: number
    plan_time_max: number
    plan_time_mean: number
    plan_time_sd: number
    exec_count: number
    exec_time_total: number
    exec_time_min: number
    exec_time_max: number
    exec_time_mean: number
    exec_time_sd: number
    rows_impacted: number
    blocks_read: number
    blocks_write: number
    blocks_hit: number
    blocks_dirtied: number
    blocks_tmp_read: number
    blocks_tmp_write: number
    blocks_tmp_hit: number
    blocks_tmp_dirtied: number
    blocks_query_read: number
    blocks_query_write: number
}

export const getQueryHistory = (opts: ConnectorQueryHistoryOpts) => async (conn: Conn): Promise<DatabaseQuery[]> => {
    // https://www.postgresql.org/docs/current/pgstatstatements.html
    // `s.toplevel = true`: get only top level queries
    // `queryid IS NOT NULL`: get only visible queries (<insufficient privilege>)
    // shared blocks (regular tables & indexes), local blocks (temp tables & indexes), temp blocks (query sorts, hashes and others)
    const sCols = await getTableColumns(undefined, 'pg_stat_statements', opts)(conn) // check column presence to include them or not
    return conn.query<RawQuery>(`
        SELECT d.oid                 AS database_id
             , d.datname             AS database_name
             -- , u.rolname             AS query_owner
             , s.queryid             AS query_id
             , s.query               AS query
             , s.plans               AS plan_count
             , s.total_plan_time     AS plan_time_total
             , s.min_plan_time       AS plan_time_min
             , s.max_plan_time       AS plan_time_max
             , s.mean_plan_time      AS plan_time_mean
             , s.stddev_plan_time    AS plan_time_sd
             , s.calls               AS exec_count
             , s.total_exec_time     AS exec_time_total
             , s.min_exec_time       AS exec_time_min
             , s.max_exec_time       AS exec_time_max
             , s.mean_exec_time      AS exec_time_mean
             , s.stddev_exec_time    AS exec_time_sd
             , s.rows                AS rows_impacted
             , s.shared_blks_read    AS blocks_read
             , s.shared_blks_written AS blocks_write
             , s.shared_blks_hit     AS blocks_hit
             , s.shared_blks_dirtied AS blocks_dirtied
             , s.local_blks_read     AS blocks_tmp_read
             , s.local_blks_written  AS blocks_tmp_write
             , s.local_blks_hit      AS blocks_tmp_hit
             , s.local_blks_dirtied  AS blocks_tmp_dirtied
             , s.temp_blks_read      AS blocks_query_read
             , s.temp_blks_written   AS blocks_query_write
        FROM pg_stat_statements s
                 JOIN pg_database d ON d.oid = s.dbid
                 -- JOIN pg_authid u ON u.oid = s.userid
        WHERE ${sCols.includes('toplevel') ? 's.toplevel = true AND ' : ''}queryid IS NOT NULL${scopeFilter('d.datname', opts.database)}${'' /* scopeFilter('u.rolname', opts.user) */}
        ORDER BY exec_time_total DESC;`, [], 'getQueryHistory'
    ).then(queries => queries.map(buildQuery)).catch(handleError(`Failed to get historical queries`, [], opts))
}

function scopeFilter(field: string, value: string | undefined): string {
    return value ? ` AND ${field} ${scopeOp(value)} '${scopeValue(value)}'` : ''
}

function buildQuery(q: RawQuery): DatabaseQuery {
    return removeUndefined({
        id: q.query_id.toString(),
        user: undefined, // q.query_owner,
        database: q.database_name,
        query: q.query,
        rows: q.rows_impacted,
        plan: {
            count: q.plan_count,
            minTime: q.plan_time_min,
            maxTime: q.plan_time_max,
            sumTime: q.plan_time_total,
            meanTime: q.plan_time_mean,
            sdTime: q.plan_time_sd,
        },
        exec: {
            count: q.exec_count,
            minTime: q.exec_time_min,
            maxTime: q.exec_time_max,
            sumTime: q.exec_time_total,
            meanTime: q.exec_time_mean,
            sdTime: q.exec_time_sd,
        },
        blocks: {sumRead: q.blocks_read, sumWrite: q.blocks_write, sumHit: q.blocks_hit, sumDirty: q.blocks_dirtied},
        blocksTmp: {sumRead: q.blocks_tmp_read, sumWrite: q.blocks_tmp_write, sumHit: q.blocks_tmp_hit, sumDirty: q.blocks_tmp_dirtied},
        blocksQuery: {sumRead: q.blocks_query_read, sumWrite: q.blocks_query_write},
    })
}

import {ConnectorQueryHistoryOpts, DatabaseQuery, handleError} from "@azimutt/models";
import {Conn} from "./connect";

export type RawQuery = {
    SQL_ID: string
    USERNAME: string
    DATABASE_NAME: string
    ROWS_PROCESSED: number
}

export const getQueryHistory = (opts: ConnectorQueryHistoryOpts) => async (conn: Conn): Promise<DatabaseQuery[]> => {
    // FIXME Can't get queries from "normal" users :/
    return Promise.reject('Not implemented')
    /* return conn.query<RawQuery>(`
        SELECT h.SQL_ID
             , u.USERNAME
             , i.INSTANCE_NAME AS DATABASE_NAME
             , s.ROWS_PROCESSED
        FROM DBA_HIST_SQLSTAT h
                 JOIN V$SQL s ON s.SQL_ID = h.SQL_ID
                 JOIN DBA_HIST_ACTIVE_SESS_HISTORY a ON h.SQL_ID = a.SQL_ID
                 JOIN DBA_USERS u ON a.USER_ID = u.USER_ID
                 JOIN V$INSTANCE i ON h.INSTANCE_NUMBER = i.INSTANCE_NUMBER
        ORDER BY h.SQL_ID;`, [], 'getQueryHistory'
    ).then(res => res.map(q => ({
        id: q.SQL_ID,
        user: q.USERNAME,
        database: q.DATABASE_NAME,
        query: '',
        rows: q.ROWS_PROCESSED,
        plan: undefined,
        exec: undefined,
        blocks: undefined,
        blocksTmp: undefined,
        blocksQuery: undefined,
    }))).catch(handleError(`Failed to get historical queries`, [], opts)) */
}

/*
SELECT h.SQL_ID              AS SQL_ID
     , u.USERNAME
     , s.SQL_TEXT            AS SQL_TEXT
     , s.SQL_FULLTEXT        AS SQL_TEXT_FULL
     , h.PARSING_SCHEMA_NAME AS SCHEMA_H
     , s.PARSING_SCHEMA_NAME AS SCHEMA_S
     , h.MODULE              AS MODULE_H
     , s.MODULE              AS MODULE_S
     , h.ACTION              AS ACTION_H
     , s.ACTION              AS ACTION_S
     , h.FETCHES_TOTAL
     , s.FETCHES
     , h.LOADS_TOTAL
     , s.LOADS
     , s.FIRST_LOAD_TIME
     , s.LAST_LOAD_TIME
     , s.LAST_ACTIVE_TIME
     , h.EXECUTIONS_TOTAL
     , s.EXECUTIONS
     , s.USERS_EXECUTING
     , h.DISK_READS_TOTAL
     , h.ROWS_PROCESSED_TOTAL
     , s.ROWS_PROCESSED
     , h.CPU_TIME_TOTAL
     , s.CPU_TIME
     , h.ELAPSED_TIME_TOTAL
     , s.ELAPSED_TIME
     , h.IOWAIT_TOTAL
     , h.DIRECT_WRITES_TOTAL
     , h.PHYSICAL_READ_REQUESTS_TOTAL
     , s.PHYSICAL_READ_REQUESTS
     , h.PHYSICAL_READ_BYTES_TOTAL
     , s.PHYSICAL_READ_BYTES
     , h.PHYSICAL_WRITE_REQUESTS_TOTAL
     , s.PHYSICAL_WRITE_REQUESTS
     , h.PHYSICAL_WRITE_BYTES_TOTAL
     , s.PHYSICAL_WRITE_BYTES
FROM DBA_HIST_SQLSTAT h
         JOIN V$SQL s ON s.SQL_ID = h.SQL_ID
         JOIN DBA_HIST_ACTIVE_SESS_HISTORY a ON a.SQL_ID = h.SQL_ID
         JOIN DBA_USERS u ON u.USER_ID = a.USER_ID
WHERE s.SQL_FULLTEXT IS NOT NULL AND s.LAST_ACTIVE_TIME >= (sysdate - 1 / 24);
 */

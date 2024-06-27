import {
  ConnectorQueryHistoryOpts,
  DatabaseQuery,
  handleError,
} from "@azimutt/models"
import { Conn } from "./connect"

export type RawQuery = {
  id: string
  query: string
  rows: number
  database: string
  user: string
}

export const getQueryHistory =
  (opts: ConnectorQueryHistoryOpts) =>
  async (conn: Conn): Promise<DatabaseQuery[]> => {
    return conn
      .query(
        `
        SELECT
            h.sql_id,
            i.instance_name AS DATABASE_NAME,
            s.rows_processed,
            u.username
        FROM
            dba_hist_sqlstat h
        JOIN
            v$sql s ON s.sql_id = h.sql_id
        JOIN
            dba_hist_active_sess_history a ON h.sql_id = a.sql_id
        JOIN
            dba_users u ON a.user_id = u.user_id
        JOIN
            gv$instance i ON h.instance_number = i.instance_number
        ORDER BY
            h.sql_id`,
        [],
        "getQueryHistory"
      )
      .then((queries) => {
        return queries.reduce<RawQuery[]>((acc, row) => {
          const [id, databaseName, rows, user] = row as any[]
          acc.push({ id, query: "", database: databaseName, rows, user })
          return acc
        }, [])
      })
      .catch(handleError(`Failed to get historical queries`, [], opts))
  }

import {distinct} from "@azimutt/utils";
import {QueryResults} from "@azimutt/models";
import {Conn} from "./connect";

export const execQuery = (query: string, parameters: any[]) => async (conn: Conn): Promise<QueryResults> => {
    return conn.underlying.query(query, {parameters}).then(r => QueryResults.parse({
        query,
        attributes: distinct(r.rows.flatMap(Object.keys)).map(name => ({name})),
        rows: r.rows
    }))
}

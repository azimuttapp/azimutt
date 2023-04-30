import {QueryResult} from "pg";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {connect} from "./connect";

export async function execQuery(application: string, url: DatabaseUrlParsed, query: string, values: any[]): Promise<QueryResult> {
    return await connect(application, url, async client => await client.query(query, values))
}

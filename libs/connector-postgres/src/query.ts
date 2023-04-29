import {QueryResult} from "pg";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {connect} from "./connect";

export async function query(application: string, url: DatabaseUrlParsed, query: string): Promise<QueryResult> {
    return await connect(application, url, async client => await client.query(query))
}

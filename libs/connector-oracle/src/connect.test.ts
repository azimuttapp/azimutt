import {describe, test} from "@jest/globals";
import {parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

// Use this test to troubleshoot database connection errors.
// If you don't succeed with the first one (Azimutt `connect`), try with the second one (raw node lib) and once you found a way, tell us how to fix ;)
// Of course, you can contact us (issues or contact@azimutt.app) to do it together.
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe("connect", () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = "jdbc:oracle:thin:sys/oracle@//localhost:1521/FREE"

    // TODO 2: write a valid query for your database
    const query = "SELECT * FROM C##AZIMUTT.USERS"
    const parameters: any[] = []

    // TODO 3: unskip this test first and run it (`npm run test -- src/connect.test.ts`)
    test.skip("Azimutt should connect", async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), {logger, logQueries: true})
        console.log("results", results)
    })
})

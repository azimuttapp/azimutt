import { describe, expect, test } from "@jest/globals"
import { DatabaseUrlParsed, parseDatabaseUrl } from "@azimutt/models"
import { connect } from "./connect"
import { getColumnStats, getTableStats } from "./stats"
import { application, logger } from "./constants.test"

describe("stats", () => {
  // local url, install db or replace it to test
  const url: DatabaseUrlParsed = parseDatabaseUrl(
    "jdbc:oracle:thin:sys/oracle@//localhost:1521/FREE"
  )

  test.skip("getTableStats", async () => {
    const stats = await connect(
      application,
      url,
      getTableStats({ schema: "C##AZIMUTT", entity: "USERS" }),
      { logger, logQueries: true }
    )
    console.log("getTableStats", stats)
    expect(stats.rows).toEqual(2)
  })
  test.skip("getColumnStats", async () => {
    const stats = await connect(
      application,
      url,
      getColumnStats({
        schema: "C##AZIMUTT",
        entity: "USERS",
        attribute: ["NAME"],
      }),
      { logger, logQueries: true }
    )
    console.log("getColumnStats", stats)
    expect(stats.rows).toEqual(2)
  })
})

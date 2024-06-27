import { describe, expect, test } from "@jest/globals"
import { parseDatabaseUrl, ConnectorSchemaOpts } from "@azimutt/models"
import { connect } from "./connect"
import { getSchema } from "./oracle"
import { application, logger } from "./constants.test"

// run these test with a postgres db loaded with `integration/postgres.sql` script, you can use the `integration/compose.yaml`
describe("integration", () => {
  const url = parseDatabaseUrl(
    "jdbc:oracle:thin:sys/oracle@//localhost:1521/FREE"
  )

  test.skip("getSchema", async () => {
    const schemaOpts: ConnectorSchemaOpts = {
      schema: undefined,
      sampleSize: 10,
      inferRelations: true,
      ignoreErrors: false,
      logQueries: true,
      logger,
    }
    const schema = await connect(application, url, getSchema(schemaOpts), {
      logger,
      logQueries: true,
    })
    expect(schema.entities?.length).toEqual(8)
    expect(schema.relations?.length).toEqual(8)
    // polymorphic relation
    expect(
      schema.entities
        ?.find((t) => t.name === "C##AZIMUTT.USERS")
        ?.attrs.find((c) => c.name === "item_type")?.stats?.distinctValues
    ).toEqual(["ID", "NAME"])
  })
})

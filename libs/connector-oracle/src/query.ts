import { AttributeRef, QueryResults } from "@azimutt/models"
import { Conn, QueryResultArrayMode, QueryResultField } from "./connect"

export const execQuery =
  (query: string, parameters: any[]) =>
  (conn: Conn): Promise<QueryResults> => {
    return conn
      .queryArrayMode(query, parameters)
      .then((result) => buildResults(conn, query, result))
  }

async function buildResults(
  conn: Conn,
  query: string,
  result: QueryResultArrayMode
): Promise<QueryResults> {
  const attributes = buildAttributes(result.fields)
  const rows = result.rows.map((row) =>
    attributes.reduce((acc, col, i) => ({ ...acc, [col.name]: row[i] }), {})
  )
  return { query, attributes, rows }
}

function buildAttributes(
  fields: QueryResultField[]
): { name: string; ref?: AttributeRef }[] {
  const keys: { [key: string]: true } = {}
  return fields.map((f) => {
    const name = uniqueName(f.name, keys)
    keys[name] = true
    return { name }
  })
}

function uniqueName(
  name: string,
  currentNames: { [key: string]: true },
  cpt: number = 1
): string {
  const newName = cpt === 1 ? name : `${name}_${cpt}`
  if (currentNames[newName]) {
    return uniqueName(name, currentNames, cpt + 1)
  } else {
    return newName
  }
}

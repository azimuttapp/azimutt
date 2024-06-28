import { AttributePath, EntityRef, SqlFragment } from "@azimutt/models"

export function buildSqlTable(ref: EntityRef): SqlFragment {
  const sqlSchema = ref.schema ? `"${ref.schema}".` : ""
  return `${sqlSchema}"${ref.entity}"`
}

export function buildSqlColumn(path: AttributePath): SqlFragment {
  const [head, ...tail] = path
  return `"${head}"${tail.map((t) => `->'${t}'`).join("")}`
}

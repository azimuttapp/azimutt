import {z} from "zod";
import {CreateTable} from "./createTable";
import {Grant} from "./grant";
import {Rollback} from "./rollback";
import {Select} from "./select";
import {Update} from "./update";

export {Select} from "./select";

// SqlScript = SqlCommand[]
// SqlStatement = SqlCommand
// SqlFragment = string
// https://www.postgresql.org/docs/current/sql-commands.html
// https://dev.mysql.com/doc/refman/8.3/en/sql-statements.html
// https://learn.microsoft.com/sql/t-sql/queries/select-transact-sql

export const SqlStatement = z.discriminatedUnion("command", [
    CreateTable,
    Grant,
    Rollback,
    Select,
    Update,
])
export type SqlStatement = z.infer<typeof SqlStatement>

export const SqlScript = SqlStatement.array()
export type SqlScript = z.infer<typeof SqlScript>

export type SqlScriptText = string // a whole script, list of statements
export type SqlStatementText = string // a single statement
export type SqlFragmentText = string // a part of a statement

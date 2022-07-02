module PagesComponents.Projects.Id_.Models.Notes exposing (Notes, NotesKey, NotesRef(..), asKey, columnKey, fromColumn, fromKey, fromTable, tableKey)

import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.TableId as TableId exposing (TableId)


type alias Notes =
    String


type alias NotesKey =
    String


type NotesRef
    = TableNote TableId
    | ColumnNote ColumnRef
    | Invalid NotesKey


fromTable : TableId -> NotesRef
fromTable id =
    TableNote id


fromColumn : ColumnRef -> NotesRef
fromColumn ref =
    ColumnNote ref


tableKey : TableId -> NotesKey
tableKey id =
    id |> fromTable |> asKey


columnKey : ColumnRef -> NotesKey
columnKey ref =
    ref |> fromColumn |> asKey


fromKey : NotesKey -> NotesRef
fromKey key =
    case key |> String.split "." of
        schema :: table :: [] ->
            TableNote ( schema, table )

        schema :: table :: column :: [] ->
            ColumnNote { table = ( schema, table ), column = column }

        _ ->
            Invalid key


asKey : NotesRef -> NotesKey
asKey ref =
    case ref of
        Invalid _ ->
            ""

        TableNote t ->
            TableId.toString t

        ColumnNote c ->
            ColumnRef.toString c

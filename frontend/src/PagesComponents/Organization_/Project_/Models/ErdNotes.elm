module PagesComponents.Organization_.Project_.Models.ErdNotes exposing (ErdNotes, create, get, getColumn, getTable, set, unpack)

import Dict exposing (Dict)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.ErdNotesTable as ErdNotesTable exposing (ErdNotesTable)
import PagesComponents.Organization_.Project_.Models.Notes as Notes exposing (Notes, NotesKey, NotesRef(..))
import Services.Lenses exposing (mapColumns, setTable)


type alias ErdNotes =
    Dict TableId ErdNotesTable


create : Dict NotesKey Notes -> ErdNotes
create notes =
    notes |> Dict.foldl (\k v b -> b |> set (Notes.fromKey k) (Just v)) Dict.empty


unpack : ErdNotes -> Dict NotesKey Notes
unpack notes =
    notes |> Dict.foldl (\k v -> Dict.union (ErdNotesTable.unpack k v)) Dict.empty


get : NotesRef -> ErdNotes -> Maybe Notes
get ref notes =
    case ref of
        Invalid _ ->
            Nothing

        TableNote table ->
            notes |> Dict.get table |> Maybe.andThen .table

        ColumnNote { table, column } ->
            notes |> Dict.get table |> Maybe.andThen (.columns >> ColumnPath.get column)


set : NotesRef -> Maybe Notes -> ErdNotes -> ErdNotes
set ref value notes =
    case ref of
        Invalid _ ->
            notes

        TableNote table ->
            notes |> Dict.update table (Maybe.withDefault ErdNotesTable.empty >> setTable value >> Just)

        ColumnNote { table, column } ->
            notes |> Dict.update table (Maybe.withDefault ErdNotesTable.empty >> mapColumns (ColumnPath.update column (\_ -> value)) >> Just)


getTable : TableId -> ErdNotes -> Maybe Notes
getTable table notes =
    notes |> Dict.get table |> Maybe.andThen .table


getColumn : ColumnRef -> ErdNotes -> Maybe Notes
getColumn ref notes =
    notes |> Dict.get ref.table |> Maybe.andThen (.columns >> ColumnPath.get ref.column)

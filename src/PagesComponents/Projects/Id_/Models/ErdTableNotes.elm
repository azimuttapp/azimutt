module PagesComponents.Projects.Id_.Models.ErdTableNotes exposing (ErdTableNotes, createAll, empty, get, set, unpackAll)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Notes as Notes exposing (Notes, NotesKey, NotesRef(..))
import Services.Lenses exposing (mapColumns, setTable)


type alias ErdTableNotes =
    { table : Maybe Notes
    , columns : Dict ColumnName Notes
    }


empty : ErdTableNotes
empty =
    { table = Nothing, columns = Dict.empty }


createAll : Dict NotesKey Notes -> Dict TableId ErdTableNotes
createAll notes =
    notes |> Dict.foldl (\k v b -> b |> set (Notes.fromKey k) (Just v)) Dict.empty


unpackAll : Dict TableId ErdTableNotes -> Dict NotesKey Notes
unpackAll notes =
    notes |> Dict.foldl (\k v -> Dict.union (unpack k v)) Dict.empty


unpack : TableId -> ErdTableNotes -> Dict NotesKey Notes
unpack table notes =
    Dict.fromList
        ((notes.table |> Maybe.toList |> List.map (\n -> ( Notes.tableKey table, n )))
            ++ (notes.columns |> Dict.toList |> List.map (\( col, n ) -> ( Notes.columnKey { table = table, column = col }, n )))
        )


get : NotesRef -> Dict TableId ErdTableNotes -> Maybe Notes
get ref notes =
    case ref of
        Invalid _ ->
            Nothing

        TableNote table ->
            notes |> Dict.get table |> Maybe.andThen .table

        ColumnNote { table, column } ->
            notes |> Dict.get table |> Maybe.andThen (.columns >> Dict.get column)


set : NotesRef -> Maybe Notes -> Dict TableId ErdTableNotes -> Dict TableId ErdTableNotes
set ref value notes =
    case ref of
        Invalid _ ->
            notes

        TableNote table ->
            notes |> Dict.update table (Maybe.withDefault empty >> setTable value >> Just)

        ColumnNote { table, column } ->
            notes |> Dict.update table (Maybe.withDefault empty >> mapColumns (Dict.update column (\_ -> value)) >> Just)

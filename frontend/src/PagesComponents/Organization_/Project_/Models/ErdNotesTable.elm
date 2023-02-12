module PagesComponents.Organization_.Project_.Models.ErdNotesTable exposing (ErdNotesTable, empty, unpack)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPathStr)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.Notes as Notes exposing (Notes, NotesKey, NotesRef(..))


type alias ErdNotesTable =
    { table : Maybe Notes
    , columns : Dict ColumnPathStr Notes
    }


empty : ErdNotesTable
empty =
    { table = Nothing, columns = Dict.empty }


unpack : TableId -> ErdNotesTable -> Dict NotesKey Notes
unpack table notes =
    Dict.fromList
        ((notes.table |> Maybe.toList |> List.map (\n -> ( Notes.tableKey table, n )))
            ++ (notes.columns |> Dict.toList |> List.map (\( col, n ) -> ( Notes.columnKey { table = table, column = ColumnPath.fromString col }, n )))
        )

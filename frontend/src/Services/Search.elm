module Services.Search exposing (columnHasNotes, columnHasTag, columnNoNotes, columnNoTag, hasNotes, hasTag, noNotes, noTag, notInLayouts, tableHasNotes, tableHasTag, tableNoNotes, tableNoTag, tableNotInLayouts)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Models.Project.ColumnPath as ColumnPath
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Metadata as Metadata exposing (Metadata)
import Models.Project.TableMeta exposing (TableMeta)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


notInLayouts : String
notInLayouts =
    "!layout"


tableNotInLayouts : Dict LayoutName ErdLayout -> ErdTable -> Bool
tableNotInLayouts layouts table =
    layouts |> Dict.all (\_ l -> l.tables |> List.any (\lt -> lt.id == table.id) |> not) |> not


noNotes : String
noNotes =
    "!notes"


tableNoNotes : Metadata -> ErdTable -> Bool
tableNoNotes metadata table =
    metadata |> Metadata.getNotes table.id Nothing |> Maybe.all String.isEmpty


columnNoNotes : Maybe TableMeta -> ErdColumn -> Bool
columnNoNotes meta col =
    meta |> Maybe.andThen (.columns >> ColumnPath.get col.path) |> Maybe.andThen .notes |> Maybe.all String.isEmpty


hasNotes : String
hasNotes =
    "notes:"


tableHasNotes : String -> Metadata -> ErdTable -> Bool
tableHasNotes text metadata table =
    metadata |> Metadata.getNotes table.id Nothing |> Maybe.any (String.contains text)


columnHasNotes : String -> Maybe TableMeta -> ErdColumn -> Bool
columnHasNotes text meta col =
    meta |> Maybe.andThen (.columns >> ColumnPath.get col.path) |> Maybe.andThen .notes |> Maybe.any (String.contains text)


noTag : String
noTag =
    "!tag"


tableNoTag : Metadata -> ErdTable -> Bool
tableNoTag metadata table =
    metadata |> Metadata.getTags table.id Nothing |> Maybe.all List.isEmpty


columnNoTag : Maybe TableMeta -> ErdColumn -> Bool
columnNoTag meta col =
    meta |> Maybe.andThen (.columns >> ColumnPath.get col.path) |> Maybe.map .tags |> Maybe.all List.isEmpty


hasTag : String
hasTag =
    "tag:"


tableHasTag : String -> Metadata -> ErdTable -> Bool
tableHasTag tag metadata table =
    metadata |> Metadata.getTags table.id Nothing |> Maybe.any (List.any (\v -> String.toLower v == tag))


columnHasTag : String -> Maybe TableMeta -> ErdColumn -> Bool
columnHasTag tag meta col =
    meta |> Maybe.andThen (.columns >> ColumnPath.get col.path) |> Maybe.map .tags |> Maybe.any (List.any (\v -> String.toLower v == tag))

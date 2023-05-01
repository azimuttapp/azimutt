module Models.Project.Metadata exposing (Metadata, countNotes, countTags, decode, encode, getNotes, getTags, putNotes, putTags)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Tag exposing (Tag)
import Models.Project.ColumnMeta as ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableMeta as TableMeta exposing (TableMeta)
import Services.Lenses exposing (setNotes, setTags)


type alias Metadata =
    Dict TableId TableMeta


getNotes : TableId -> Maybe ColumnPath -> Metadata -> Maybe Notes
getNotes table column metadata =
    metadata |> getItem table column .notes .notes |> Maybe.andThen identity


getTags : TableId -> Maybe ColumnPath -> Metadata -> Maybe (List Tag)
getTags table column metadata =
    metadata |> getItem table column .tags .tags


getItem : TableId -> Maybe ColumnPath -> (TableMeta -> v) -> (ColumnMeta -> v) -> Metadata -> Maybe v
getItem table column tableGet columnGet metadata =
    column
        |> Maybe.map (\c -> metadata |> Dict.get table |> Maybe.andThen (.columns >> ColumnPath.get c) |> Maybe.map columnGet)
        |> Maybe.withDefault (metadata |> Dict.get table |> Maybe.map tableGet)


putNotes : TableId -> Maybe ColumnPath -> Maybe Notes -> Metadata -> Metadata
putNotes table column notes metadata =
    metadata |> putItem table column setNotes setNotes notes


putTags : TableId -> Maybe ColumnPath -> List Tag -> Metadata -> Metadata
putTags table column tags metadata =
    metadata |> putItem table column setTags setTags tags


putItem : TableId -> Maybe ColumnPath -> (v -> TableMeta -> TableMeta) -> (v -> ColumnMeta -> ColumnMeta) -> v -> Metadata -> Metadata
putItem table column tableSet columnSet v metadata =
    metadata |> Dict.update table (upsertItem column tableSet columnSet v)


upsertItem : Maybe ColumnPath -> (v -> TableMeta -> TableMeta) -> (v -> ColumnMeta -> ColumnMeta) -> v -> Maybe TableMeta -> Maybe TableMeta
upsertItem column tableSet columnSet v meta =
    meta |> Maybe.map (updateItem column tableSet columnSet v) |> Maybe.withDefault (createItem column tableSet columnSet v) |> Just


createItem : Maybe ColumnPath -> (v -> TableMeta -> TableMeta) -> (v -> ColumnMeta -> ColumnMeta) -> v -> TableMeta
createItem column tableSet columnSet v =
    column
        |> Maybe.map (\c -> TableMeta.empty |> (\t -> { t | columns = Dict.fromList [ ( c |> ColumnPath.toString, ColumnMeta.empty |> columnSet v ) ] }))
        |> Maybe.withDefault (TableMeta.empty |> tableSet v)


updateItem : Maybe ColumnPath -> (v -> TableMeta -> TableMeta) -> (v -> ColumnMeta -> ColumnMeta) -> v -> TableMeta -> TableMeta
updateItem column tableSet columnSet item meta =
    column
        |> Maybe.map (\path -> { meta | columns = meta.columns |> upsertColumnItem path columnSet item })
        |> Maybe.withDefault (meta |> tableSet item)


upsertColumnItem : ColumnPath -> (v -> ColumnMeta -> ColumnMeta) -> v -> Dict ColumnPathStr ColumnMeta -> Dict ColumnPathStr ColumnMeta
upsertColumnItem column set v meta =
    meta |> Dict.update (column |> ColumnPath.toString) (Maybe.withDefault ColumnMeta.empty >> set v >> Just)


countNotes : Metadata -> Int
countNotes meta =
    meta |> collectItem .notes .notes |> List.filter Maybe.isJust |> List.length


countTags : Metadata -> Int
countTags meta =
    meta |> collectItem .tags .tags |> List.filter List.nonEmpty |> List.length


collectItem : (TableMeta -> v) -> (ColumnMeta -> v) -> Metadata -> List v
collectItem tableGet columnGet meta =
    meta |> Dict.values |> List.concatMap (\t -> tableGet t :: (t.columns |> Dict.values |> List.map columnGet))


encode : Metadata -> Value
encode value =
    value |> Encode.withDefault (Encode.dict TableId.toString TableMeta.encode) Dict.empty


decode : Decode.Decoder Metadata
decode =
    Decode.customDict TableId.parse TableMeta.decode

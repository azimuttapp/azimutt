module PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat, ErdColumnPropsNested(..), add, createAll, createFlat, filter, find, flatten, getIndex, initAll, map, member, nest, remove, unpackAll)

import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)


type alias ErdColumnProps =
    { name : ColumnName
    , children : ErdColumnPropsNested
    , highlighted : Bool
    }


type ErdColumnPropsNested
    = ErdColumnPropsNested (List ErdColumnProps)


type alias ErdColumnPropsFlat =
    { path : ColumnPath
    , highlighted : Bool
    }


createFlat : ColumnPath -> ErdColumnPropsFlat
createFlat path =
    { path = path
    , highlighted = False
    }


createAll : List ColumnPath -> List ErdColumnProps
createAll columns =
    columns
        |> List.groupByL .head
        |> List.map
            (\( name, cols ) ->
                { name = name
                , children = cols |> List.filterMap (.tail >> Nel.fromList) |> createAll |> ErdColumnPropsNested
                , highlighted = False
                }
            )


unpackAll : List ErdColumnProps -> List ColumnPath
unpackAll columns =
    columns |> flatten |> List.map .path


flatten : List ErdColumnProps -> List ErdColumnPropsFlat
flatten columns =
    columns |> List.concatMap (\col -> col.name |> ColumnPath.fromString |> (\p -> { path = p, highlighted = col.highlighted } :: (col.children |> flattenNested p)))


flattenNested : ColumnPath -> ErdColumnPropsNested -> List ErdColumnPropsFlat
flattenNested path (ErdColumnPropsNested columns) =
    columns |> List.concatMap (\col -> path |> ColumnPath.child col.name |> (\p -> { path = p, highlighted = col.highlighted } :: (col.children |> flattenNested p)))


nest : List ErdColumnPropsFlat -> List ErdColumnProps
nest columns =
    columns
        |> List.groupByL (.path >> .head)
        |> List.map
            (\( name, cols ) ->
                { name = name
                , children = cols |> List.filterMap (\c -> c.path.tail |> Nel.fromList |> Maybe.map (\p -> { c | path = p })) |> nest |> ErdColumnPropsNested
                , highlighted = cols |> List.find (\c -> c.path.tail == []) |> Maybe.mapOrElse .highlighted False
                }
            )


initAll : ProjectSettings -> List ErdRelation -> ErdTable -> List ErdColumnProps
initAll settings relations table =
    let
        tableRelations : List ErdRelation
        tableRelations =
            relations |> List.filter (\r -> r.src.table == table.id)
    in
    table.columns
        |> Dict.values
        |> List.filterNot (ProjectSettings.hideColumn settings.hiddenColumns)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.take settings.hiddenColumns.max
        |> List.map
            (\c ->
                { name = c.path.head
                , children = ErdColumnPropsNested []
                , highlighted = False
                }
            )


find : ColumnPath -> List ErdColumnProps -> Maybe ErdColumnProps
find path columns =
    columns
        |> List.find (\c -> c.name == path.head)
        |> Maybe.andThen
            (\c ->
                path.tail
                    |> Nel.fromList
                    |> Maybe.mapOrElse (\p -> c |> children |> find p) (Just c)
            )


member : ColumnPath -> List ErdColumnProps -> Bool
member path columns =
    columns |> find path |> Maybe.isJust


getIndex : ColumnPath -> List ErdColumnProps -> Maybe Int
getIndex path columns =
    columns |> unpackAll |> List.zipWithIndex |> List.find (\( p, _ ) -> p == path) |> Maybe.map (\( _, i ) -> i)


remove : ColumnPath -> List ErdColumnProps -> List ErdColumnProps
remove path columns =
    columns
        |> List.filterMap
            (\c ->
                if c.name == path.head then
                    path.tail |> Nel.fromList |> Maybe.map (\p -> c |> mapChildren (remove p))

                else
                    Just c
            )


add : ColumnPath -> List ErdColumnProps -> List ErdColumnProps
add path columns =
    if columns |> List.memberBy .name path.head then
        columns
            |> List.map
                (\c ->
                    if c.name == path.head then
                        path.tail |> Nel.fromList |> Maybe.mapOrElse (\p -> c |> mapChildren (add p)) c

                    else
                        c
                )

    else
        columns
            ++ [ { name = path.head
                 , children = ErdColumnPropsNested (path.tail |> Nel.fromList |> Maybe.mapOrElse (\p -> [] |> add p) [])
                 , highlighted = False
                 }
               ]


filter : (ColumnPath -> ErdColumnProps -> Bool) -> List ErdColumnProps -> List ErdColumnProps
filter predicate columns =
    columns |> List.filter (\c -> c |> predicate (ColumnPath.fromString c.name)) |> List.map (\c -> c |> mapChildren (filterNested (ColumnPath.fromString c.name) predicate))


filterNested : ColumnPath -> (ColumnPath -> ErdColumnProps -> Bool) -> List ErdColumnProps -> List ErdColumnProps
filterNested path predicate columns =
    columns |> List.filter (\c -> c |> predicate (path |> ColumnPath.child c.name)) |> List.map (\c -> c |> mapChildren (filterNested (path |> ColumnPath.child c.name) predicate))


map : (ColumnPath -> ErdColumnProps -> ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
map transform columns =
    columns |> List.map (\c -> c |> transform (ColumnPath.fromString c.name) |> mapChildren (mapNested (ColumnPath.fromString c.name) transform))


mapNested : ColumnPath -> (ColumnPath -> ErdColumnProps -> ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
mapNested path transform columns =
    columns |> List.map (\c -> c |> transform (path |> ColumnPath.child c.name) |> mapChildren (mapNested (path |> ColumnPath.child c.name) transform))


children : ErdColumnProps -> List ErdColumnProps
children column =
    column.children |> (\(ErdColumnPropsNested cols) -> cols)


mapChildren : (List ErdColumnProps -> List ErdColumnProps) -> ErdColumnProps -> ErdColumnProps
mapChildren transform column =
    { column | children = column |> children |> transform |> ErdColumnPropsNested }

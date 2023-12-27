module PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat, ErdColumnPropsNested(..), children, createAll, createChildren, filter, find, flatten, getIndex, initAll, insertAt, map, mapAll, mapAt, mapAtTL, member, nest, remove, removeWithIndex, unpackAll)

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
    -- TODO: remove this model (replace with ErdColumnProps everywhere)
    { path : ColumnPath
    , highlighted : Bool
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


createChildren : List ColumnName -> ErdColumnProps -> ErdColumnProps
createChildren names column =
    { column | children = names |> List.map (\name -> { name = name, children = ErdColumnPropsNested [], highlighted = False }) |> ErdColumnPropsNested }


unpackAll : List ErdColumnProps -> List ColumnPath
unpackAll columns =
    columns |> flatten |> List.map .path


flatten : List ErdColumnProps -> List ErdColumnPropsFlat
flatten columns =
    -- TODO: remove this method
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
        |> List.zipWithIndex
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.take settings.hiddenColumns.max
        |> List.map
            (\( c, _ ) ->
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


removeWithIndex : ColumnPath -> List ErdColumnProps -> ( List ErdColumnProps, Maybe Int )
removeWithIndex path columns =
    columns
        |> List.zipWithIndex
        |> List.map
            (\( c, i ) ->
                if c.name == path.head then
                    path.tail |> Nel.fromList |> Maybe.map (\p -> c |> mapChildrenT (removeWithIndex p)) |> Maybe.withDefault ( c, Just i )

                else
                    ( c, Nothing )
            )
        |> (\result ->
                -- remove prop if found at depth of path
                ( result |> List.filterMap (\( c, found ) -> found |> Maybe.filter (\_ -> path.tail |> List.isEmpty) |> Maybe.flipWith c)
                , result |> List.filterMap Tuple.second |> List.head
                )
           )


insertAt : Int -> ColumnPath -> List ErdColumnProps -> List ErdColumnProps
insertAt index path columns =
    if columns |> List.memberBy .name path.head then
        columns
            |> List.map
                (\c ->
                    if c.name == path.head then
                        path.tail |> Nel.fromList |> Maybe.mapOrElse (\p -> c |> mapChildren (insertAt index p)) c

                    else
                        c
                )

    else
        columns
            |> List.insertAt index
                { name = path.head
                , children = ErdColumnPropsNested (path.tail |> Nel.fromList |> Maybe.mapOrElse (\p -> [] |> insertAt index p) [])
                , highlighted = False
                }


map : (ColumnPath -> ErdColumnProps -> ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
map f columns =
    columns |> List.map (\c -> c |> f (ColumnPath.fromString c.name) |> mapChildren (mapNested (ColumnPath.fromString c.name) f))


mapNested : ColumnPath -> (ColumnPath -> ErdColumnProps -> ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
mapNested path f columns =
    columns |> List.map (\c -> c |> f (path |> ColumnPath.child c.name) |> mapChildren (mapNested (path |> ColumnPath.child c.name) f))


mapAt : Maybe ColumnPath -> (List ErdColumnProps -> List ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
mapAt path f columns =
    -- apply `f` on columns under the given path
    path |> Maybe.mapOrElse (\p -> columns |> List.map (mapChildren (mapAt (p.tail |> Nel.fromList) f))) (f columns)


mapAtTL : Maybe ColumnPath -> (List ErdColumnProps -> ( List ErdColumnProps, List a )) -> List ErdColumnProps -> ( List ErdColumnProps, List a )
mapAtTL path f columns =
    -- apply `f` on columns under the given path
    path |> Maybe.mapOrElse (\p -> columns |> List.mapTL (mapChildrenT (mapAtTL (p.tail |> Nel.fromList) f))) (f columns)


mapAll : (Maybe ColumnPath -> List ErdColumnProps -> List ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
mapAll f columns =
    -- apply `f` everywhere in the nested structure
    columns |> f Nothing |> List.map (\col -> col |> mapChildren (mapAllNested (col.name |> ColumnPath.fromString) f))


mapAllNested : ColumnPath -> (Maybe ColumnPath -> List ErdColumnProps -> List ErdColumnProps) -> List ErdColumnProps -> List ErdColumnProps
mapAllNested path f columns =
    columns |> f (Just path) |> List.map (\col -> col |> mapChildren (mapAllNested (path |> ColumnPath.child col.name) f))


filter : (ColumnPath -> ErdColumnProps -> Bool) -> List ErdColumnProps -> List ErdColumnProps
filter predicate columns =
    columns |> List.filter (\c -> c |> predicate (ColumnPath.fromString c.name)) |> List.map (\c -> c |> mapChildren (filterNested (ColumnPath.fromString c.name) predicate))


filterNested : ColumnPath -> (ColumnPath -> ErdColumnProps -> Bool) -> List ErdColumnProps -> List ErdColumnProps
filterNested path predicate columns =
    columns |> List.filter (\c -> c |> predicate (path |> ColumnPath.child c.name)) |> List.map (\c -> c |> mapChildren (filterNested (path |> ColumnPath.child c.name) predicate))


children : ErdColumnProps -> List ErdColumnProps
children column =
    column.children |> (\(ErdColumnPropsNested cols) -> cols)


mapChildren : (List ErdColumnProps -> List ErdColumnProps) -> ErdColumnProps -> ErdColumnProps
mapChildren f column =
    { column | children = column |> children |> f |> ErdColumnPropsNested }


mapChildrenT : (List ErdColumnProps -> ( List ErdColumnProps, a )) -> ErdColumnProps -> ( ErdColumnProps, a )
mapChildrenT f column =
    column |> children |> f |> (\( cols, a ) -> ( { column | children = cols |> ErdColumnPropsNested }, a ))

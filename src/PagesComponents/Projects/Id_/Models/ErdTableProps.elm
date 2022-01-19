module PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps, create, setColor, setHighlightedColumns, setPosition, setSelected, setSize, unpack)

import Dict exposing (Dict)
import Libs.Models.Color exposing (Color)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Relation exposing (Relation)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelationProps as ErdRelationProps exposing (ErdRelationProps)
import Set exposing (Set)


type alias ErdTableProps =
    { id : TableId
    , position : Position
    , size : Size
    , isHover : Bool
    , color : Color
    , shownColumns : List ColumnName
    , highlightedColumns : Set ColumnName
    , columnProps : Dict ColumnName ErdColumnProps
    , selected : Bool
    , hiddenColumns : Bool
    , relatedTables : Dict TableId ErdRelationProps
    }


create : List Relation -> List TableProps -> TableProps -> ErdTableProps
create tableRelations shownTables props =
    { id = props.id
    , position = props.position
    , size = props.size
    , isHover = False
    , color = props.color
    , shownColumns = props.columns
    , highlightedColumns = Set.empty
    , columnProps = props.columns |> ErdColumnProps.createAll props.position props.size props.color Set.empty props.selected
    , selected = props.selected
    , hiddenColumns = props.hiddenColumns
    , relatedTables =
        tableRelations
            |> List.filterMap
                (\r ->
                    if r.src.table == props.id then
                        Just ( r.ref.table, ErdRelationProps.create shownTables r.ref.table )

                    else if r.ref.table == props.id then
                        Just ( r.src.table, ErdRelationProps.create shownTables r.src.table )

                    else
                        Nothing
                )
            |> Dict.fromList
    }


unpack : Dict TableId ErdTableProps -> TableId -> Maybe TableProps
unpack props id =
    props
        |> Dict.get id
        |> Maybe.map
            (\prop ->
                { id = id
                , position = prop.position
                , size = prop.size
                , color = prop.color
                , columns = prop.shownColumns
                , selected = prop.selected
                , hiddenColumns = prop.hiddenColumns
                }
            )


setPosition : Position -> ErdTableProps -> ErdTableProps
setPosition position props =
    if props.position == position then
        props

    else
        { props | position = position, columnProps = props.columnProps |> Dict.map (\_ p -> { p | position = position }) }


setSize : Size -> ErdTableProps -> ErdTableProps
setSize size props =
    if props.size == size then
        props

    else
        { props | size = size, columnProps = props.columnProps |> Dict.map (\_ p -> { p | size = size }) }


setColor : Color -> ErdTableProps -> ErdTableProps
setColor color props =
    if props.color == color then
        props

    else
        { props | color = color, columnProps = props.columnProps |> Dict.map (\_ p -> { p | color = color }) }


setHighlightedColumns : Set ColumnName -> ErdTableProps -> ErdTableProps
setHighlightedColumns highlightedColumns props =
    if props.highlightedColumns == highlightedColumns then
        props

    else
        { props
            | highlightedColumns = highlightedColumns
            , columnProps =
                props.columnProps
                    |> Dict.map
                        (\c p ->
                            (highlightedColumns |> Set.member c)
                                |> (\highlighted ->
                                        if p.highlighted == highlighted then
                                            p

                                        else
                                            { p | highlighted = highlighted }
                                   )
                        )
        }


setSelected : Bool -> ErdTableProps -> ErdTableProps
setSelected selected props =
    if props.selected == selected then
        props

    else
        { props | selected = selected, columnProps = props.columnProps |> Dict.map (\_ p -> { p | selected = selected }) }

module PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps, area, buildRelatedTables, create, init, mapPosition, mapSelected, mapShowHiddenColumns, mapShownColumns, setColor, setHighlightedColumns, setHover, setPosition, setSelected, setShowHiddenColumns, setShownColumns, setSize, unpack)

import Dict exposing (Dict)
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Tailwind exposing (Color)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdRelationProps as ErdRelationProps exposing (ErdRelationProps)
import PagesComponents.Projects.Id_.Models.ErdTable as ErdTable exposing (ErdTable)
import Services.Lenses exposing (setHighlighted)
import Set exposing (Set)



-- some data are duplicated between ErdTableProps and ErdColumnProps
-- this allows to have a reference equality on change to lazily render views
-- each model is updated only when the view needs to be rendered so only the tables and relations that actually change are rendered
-- it creates some complexity on the model and update part but it's for the good of performance ^^


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
    , showHiddenColumns : Bool
    , relatedTables : Dict TableId ErdRelationProps
    }


create : List Relation -> List TableId -> TableProps -> ErdTableProps
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
    , showHiddenColumns = props.hiddenColumns
    , relatedTables = buildRelatedTables tableRelations shownTables props.id
    }


buildRelatedTables : List Relation -> List TableId -> TableId -> Dict TableId ErdRelationProps
buildRelatedTables tableRelations shownTables table =
    tableRelations
        |> List.filterMap
            (\r ->
                if r.src.table == table then
                    Just ( r.ref.table, ErdRelationProps.create shownTables r.ref.table )

                else if r.ref.table == table then
                    Just ( r.src.table, ErdRelationProps.create shownTables r.src.table )

                else
                    Nothing
            )
        |> Dict.fromList


unpack : ErdTableProps -> TableProps
unpack props =
    { id = props.id
    , position = props.position
    , size = props.size
    , color = props.color
    , columns = props.shownColumns
    , selected = props.selected
    , hiddenColumns = props.showHiddenColumns
    }


init : ProjectSettings -> List ErdRelation -> List TableId -> ErdTable -> ErdTableProps
init settings erdRelations shownTables erdTable =
    let
        relations : List Relation
        relations =
            erdRelations |> List.map ErdRelation.unpack

        table : Table
        table =
            erdTable |> ErdTable.unpack
    in
    TableProps.init settings relations table |> create relations shownTables


area : ErdTableProps -> Area
area props =
    { position = props.position, size = props.size }


setPosition : Position -> ErdTableProps -> ErdTableProps
setPosition position props =
    if props.position == position then
        props

    else
        { props | position = position, columnProps = props.columnProps |> Dict.map (\_ p -> { p | position = position }) }


mapPosition : (Position -> Position) -> ErdTableProps -> ErdTableProps
mapPosition transform props =
    setPosition (transform props.position) props


setSize : Size -> ErdTableProps -> ErdTableProps
setSize size props =
    if props.size == size then
        props

    else
        { props | size = size, columnProps = props.columnProps |> Dict.map (\_ p -> { p | size = size }) }


setHover : Bool -> ErdTableProps -> ErdTableProps
setHover isHover props =
    if props.isHover == isHover then
        props

    else
        { props | isHover = isHover }


setColor : Color -> ErdTableProps -> ErdTableProps
setColor color props =
    if props.color == color then
        props

    else
        { props | color = color, columnProps = props.columnProps |> Dict.map (\_ p -> { p | color = color }) }


setShownColumns : List ColumnName -> ErdTableProps -> ErdTableProps
setShownColumns shownColumns props =
    if props.shownColumns == shownColumns then
        props

    else
        { props
            | shownColumns = shownColumns
            , columnProps =
                shownColumns
                    |> ErdColumnProps.createAll props.position props.size props.color props.highlightedColumns props.selected
                    -- if the recomputed version is the same as the existing one, keep the older to preserve referential equality
                    |> Dict.map (\c p -> props.columnProps |> Dict.get c |> Maybe.mapOrElse (\prev -> B.cond (p == prev) prev p) p)
        }


mapShownColumns : (List ColumnName -> List ColumnName) -> ErdTableProps -> ErdTableProps
mapShownColumns transform props =
    setShownColumns (transform props.shownColumns) props


setHighlightedColumns : Set ColumnName -> ErdTableProps -> ErdTableProps
setHighlightedColumns highlightedColumns props =
    if props.highlightedColumns == highlightedColumns then
        props

    else
        { props
            | highlightedColumns = highlightedColumns
            , columnProps = props.columnProps |> Dict.map (\c -> setHighlighted (highlightedColumns |> Set.member c))
        }


setSelected : Bool -> ErdTableProps -> ErdTableProps
setSelected selected props =
    if props.selected == selected then
        props

    else
        { props | selected = selected, columnProps = props.columnProps |> Dict.map (\_ p -> { p | selected = selected }) }


mapSelected : (Bool -> Bool) -> ErdTableProps -> ErdTableProps
mapSelected transform props =
    setSelected (transform props.selected) props


setShowHiddenColumns : Bool -> ErdTableProps -> ErdTableProps
setShowHiddenColumns showHiddenColumns props =
    if props.showHiddenColumns == showHiddenColumns then
        props

    else
        { props | showHiddenColumns = showHiddenColumns }


mapShowHiddenColumns : (Bool -> Bool) -> ErdTableProps -> ErdTableProps
mapShowHiddenColumns transform props =
    setShowHiddenColumns (transform props.showHiddenColumns) props

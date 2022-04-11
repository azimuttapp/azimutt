module PagesComponents.Projects.Id_.Models.ErdTableProps exposing (ErdTableProps, area, buildRelatedTables, create, init, mapCollapsed, mapPosition, mapSelected, mapShowHiddenColumns, mapShownColumns, setCollapsed, setColor, setHighlightedColumns, setHover, setPosition, setSelected, setShowHiddenColumns, setShownColumns, setSize, unpack)

import Dict exposing (Dict)
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color)
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdRelationProps as ErdRelationProps exposing (ErdRelationProps)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.Notes as NoteRef exposing (Notes, NotesKey)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint)
import Services.Lenses exposing (setHighlighted)
import Set exposing (Set)



-- some data are duplicated between ErdTableProps and ErdColumnProps
-- this allows to have a reference equality on change to lazily render views
-- each model is updated only when the view needs to be rendered so only the tables and relations that actually change are rendered
-- it creates some complexity on the model and update part but it's for the good of performance ^^


type alias ErdTableProps =
    { id : TableId
    , positionHint : Maybe PositionHint
    , position : Position
    , size : Size
    , isHover : Bool
    , color : Color
    , shownColumns : List ColumnName
    , highlightedColumns : Set ColumnName
    , columnProps : Dict ColumnName ErdColumnProps
    , selected : Bool
    , collapsed : Bool
    , showHiddenColumns : Bool
    , relatedTables : Dict TableId ErdRelationProps
    , notes : Maybe String
    }


create : List Relation -> List TableId -> Maybe PositionHint -> Dict NotesKey Notes -> TableProps -> ErdTableProps
create tableRelations shownTables hint notes props =
    { id = props.id
    , positionHint = hint
    , position = props.position
    , size = props.size
    , isHover = False
    , color = props.color
    , shownColumns = props.columns
    , highlightedColumns = Set.empty
    , columnProps = props.columns |> ErdColumnProps.createAll props.id props.position props.size props.color Set.empty props.selected props.collapsed notes
    , selected = props.selected
    , collapsed = props.collapsed
    , showHiddenColumns = props.hiddenColumns
    , relatedTables = buildRelatedTables tableRelations shownTables props.id
    , notes = notes |> Dict.get (NoteRef.tableKey props.id)
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
    , collapsed = props.collapsed
    , hiddenColumns = props.showHiddenColumns
    }


init : ProjectSettings -> List ErdRelation -> List TableId -> Maybe PositionHint -> Dict NotesKey Notes -> ErdTable -> ErdTableProps
init settings erdRelations shownTables hint notes table =
    let
        relations : List Relation
        relations =
            erdRelations |> List.map ErdRelation.unpack
    in
    { id = table.id
    , position = Position.zero
    , size = Size.zero
    , color = computeColor table.id
    , columns = table.columns |> Ned.values |> Nel.toList |> List.map .name |> computeColumns settings relations table
    , selected = False
    , collapsed = settings.collapseTableColumns
    , hiddenColumns = False
    }
        |> create relations shownTables hint notes


computeColumns : ProjectSettings -> List Relation -> ErdTable -> List ColumnName -> List ColumnName
computeColumns settings relations table columns =
    let
        tableRelations : List Relation
        tableRelations =
            relations |> Relation.withTableSrc table.id
    in
    columns
        |> List.filterMap (\c -> table.columns |> Ned.get c)
        |> List.filterNot (ProjectSettings.hideColumn settings.hiddenColumns)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.map .name


computeColor : TableId -> Color
computeColor ( _, table ) =
    String.wordSplit table
        |> List.head
        |> Maybe.map String.hashCode
        |> Maybe.map (modBy (List.length Tw.list))
        |> Maybe.andThen (\index -> Tw.list |> List.get index)
        |> Maybe.withDefault Tw.default


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


setShownColumns : List ColumnName -> Dict NotesKey Notes -> ErdTableProps -> ErdTableProps
setShownColumns shownColumns notes props =
    if props.shownColumns == shownColumns then
        props

    else
        { props
            | shownColumns = shownColumns
            , columnProps =
                shownColumns
                    |> ErdColumnProps.createAll props.id props.position props.size props.color props.highlightedColumns props.selected props.collapsed notes
                    -- if the recomputed version is the same as the existing one, keep the older to preserve referential equality
                    |> Dict.map (\c p -> props.columnProps |> Dict.get c |> Maybe.mapOrElse (\prev -> B.cond (p == prev) prev p) p)
        }


mapShownColumns : (List ColumnName -> List ColumnName) -> Dict NotesKey Notes -> ErdTableProps -> ErdTableProps
mapShownColumns transform notes props =
    setShownColumns (transform props.shownColumns) notes props


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


setCollapsed : Bool -> ErdTableProps -> ErdTableProps
setCollapsed collapsed props =
    if props.collapsed == collapsed then
        props

    else
        { props | collapsed = collapsed, columnProps = props.columnProps |> Dict.map (\_ p -> { p | collapsed = collapsed }) }


mapCollapsed : (Bool -> Bool) -> ErdTableProps -> ErdTableProps
mapCollapsed transform props =
    setCollapsed (transform props.collapsed) props


setShowHiddenColumns : Bool -> ErdTableProps -> ErdTableProps
setShowHiddenColumns showHiddenColumns props =
    if props.showHiddenColumns == showHiddenColumns then
        props

    else
        { props | showHiddenColumns = showHiddenColumns }


mapShowHiddenColumns : (Bool -> Bool) -> ErdTableProps -> ErdTableProps
mapShowHiddenColumns transform props =
    setShowHiddenColumns (transform props.showHiddenColumns) props

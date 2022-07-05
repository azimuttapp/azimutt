module PagesComponents.Id_.Models.ErdTableLayout exposing (ErdTableLayout, buildRelatedTables, create, init, unpack)

import Dict exposing (Dict)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Id_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Id_.Models.ErdRelationProps as ErdRelationProps exposing (ErdRelationProps)
import PagesComponents.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Id_.Models.PositionHint exposing (PositionHint)
import Set exposing (Set)


type alias ErdTableLayout =
    { id : TableId
    , props : ErdTableProps -- props should be separated from columns to Lazy checks
    , columns : List ErdColumnProps -- list order is used for display
    , relatedTables : Dict TableId ErdRelationProps
    }


create : Set TableId -> List Relation -> TableProps -> ErdTableLayout
create shownTables relations props =
    { id = props.id
    , props = ErdTableProps.create props
    , columns = props.columns |> List.map ErdColumnProps.create
    , relatedTables = buildRelatedTables shownTables relations
    }


unpack : ErdTableLayout -> TableProps
unpack layout =
    { id = layout.id
    , position = layout.props.position
    , size = layout.props.size
    , color = layout.props.color
    , columns = layout.columns |> List.map .name
    , selected = layout.props.selected
    , collapsed = layout.props.collapsed
    , hiddenColumns = layout.props.showHiddenColumns
    }


init : ProjectSettings -> Set TableId -> List Relation -> Bool -> Maybe PositionHint -> ErdTable -> ErdTableLayout
init settings shownTables relations collapsed hint table =
    { id = table.id
    , props = ErdTableProps.init collapsed hint table
    , columns = ErdColumnProps.initAll settings relations table
    , relatedTables = buildRelatedTables shownTables relations
    }


buildRelatedTables : Set TableId -> List Relation -> Dict TableId ErdRelationProps
buildRelatedTables shownTables relations =
    relations
        |> List.concatMap (\r -> [ r.src.table, r.ref.table ])
        |> List.map (\t -> ( t, ErdRelationProps.create shownTables t ))
        |> Dict.fromList

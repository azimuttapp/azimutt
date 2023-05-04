module PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout, buildGroupArea, buildRelatedTables, create, init, unpack)

import Dict exposing (Dict)
import Libs.List as List
import Models.Area as Area
import Models.Project.Group exposing (Group)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdRelationProps as ErdRelationProps exposing (ErdRelationProps)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Set exposing (Set)


type alias ErdTableLayout =
    { id : TableId
    , props : ErdTableProps -- props should be separated from columns to Lazy checks
    , columns : List ErdColumnProps -- list order is used for display

    -- FIXME: related tables are wrong when multiple tables are displayed at the same time :/
    , relatedTables : Dict TableId ErdRelationProps
    }


create : Set TableId -> List ErdRelation -> TableProps -> ErdTableLayout
create shownTables relations props =
    { id = props.id
    , props = ErdTableProps.create props
    , columns = props.columns |> ErdColumnProps.createAll
    , relatedTables = buildRelatedTables shownTables relations
    }


unpack : ErdTableLayout -> TableProps
unpack layout =
    { id = layout.id
    , position = layout.props.position
    , size = layout.props.size
    , color = layout.props.color
    , columns = layout.columns |> ErdColumnProps.unpackAll
    , selected = layout.props.selected
    , collapsed = layout.props.collapsed
    , hiddenColumns = layout.props.showHiddenColumns
    }


init : ProjectSettings -> Set TableId -> List ErdRelation -> Bool -> Maybe PositionHint -> ErdTable -> ErdTableLayout
init settings shownTables relations collapsed hint table =
    { id = table.id
    , props = ErdTableProps.init collapsed hint table
    , columns = ErdColumnProps.initAll settings relations table
    , relatedTables = buildRelatedTables shownTables relations
    }


buildRelatedTables : Set TableId -> List ErdRelation -> Dict TableId ErdRelationProps
buildRelatedTables shownTables relations =
    relations
        |> List.concatMap (\r -> [ r.src.table, r.ref.table ])
        |> List.map (\t -> ( t, ErdRelationProps.create shownTables t ))
        |> Dict.fromList


buildGroupArea : List ErdTableLayout -> Group -> Maybe ( Group, Area.Canvas )
buildGroupArea displayedTables group =
    group.tables
        |> List.filterMap (\id -> displayedTables |> List.find (\t -> t.id == id))
        |> List.map (.props >> Area.offGrid)
        |> Area.mergeCanvas
        |> Maybe.map (\area -> ( group, area |> Area.withPadding 30 ))

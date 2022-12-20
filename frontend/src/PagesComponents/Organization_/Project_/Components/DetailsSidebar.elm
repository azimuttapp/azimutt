module PagesComponents.Organization_.Project_.Components.DetailsSidebar exposing (ColumnData, Heading, Model, Msg(..), SchemaData, Selected, TableData, View(..), selected, update, view)

import Components.Atoms.Icon as Icon
import Components.Organisms.Details as Details
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h2, span, text)
import Html.Attributes exposing (class, id, name, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats exposing (ColumnStats)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId, SourceIdStr)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableStats exposing (TableStats)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Notes exposing (Notes)
import Ports
import Services.Lenses exposing (setSearch, setView)


type alias Model =
    { id : HtmlId, view : View, openedCollapse : HtmlId, search : String }


type View
    = ListView
    | SchemaView SchemaData
    | TableView TableData
    | ColumnView ColumnData


type alias SchemaData =
    { schema : Heading SchemaName Never, tables : List ErdTable }


type alias TableData =
    { schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout }


type alias ColumnData =
    { schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout, column : Heading ErdColumn ErdColumnProps }


type alias Heading item props =
    { item : item, prev : Maybe item, next : Maybe item, shown : Maybe props }


type Msg
    = Close
    | Toggle
    | SearchUpdate String
    | ShowList
    | ShowSchema SchemaName
    | ShowTable TableId
    | ShowColumn ColumnRef
    | ToggleCollapse HtmlId



-- INIT


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v, openedCollapse = "", search = "" }



-- UPDATE


update : Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update erd msg model =
    case msg of
        Close ->
            ( Nothing, Cmd.none )

        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (listView |> init |> Just), Cmd.none )

        SearchUpdate search ->
            ( model |> Maybe.map (setSearch search), Cmd.none )

        ShowList ->
            ( model |> setViewM listView, Cmd.none )

        ShowSchema schema ->
            ( model |> setViewM (schemaView erd schema), Cmd.none )

        ShowTable table ->
            ( model |> setViewM (tableView erd table), Cmd.batch (erd.sources |> filterDatabaseSources |> List.map (Ports.getTableStats table)) )

        ShowColumn column ->
            ( model |> setViewM (columnView erd column), Cmd.batch (erd.sources |> filterDatabaseSources |> List.map (Ports.getColumnStats column)) )

        ToggleCollapse id ->
            ( model |> Maybe.map (\m -> { m | openedCollapse = Bool.cond (m.openedCollapse == id) "" id }), Cmd.none )


setViewM : View -> Maybe Model -> Maybe Model
setViewM v model =
    model |> Maybe.mapOrElse (setView v) (init v) |> Just


listView : View
listView =
    ListView


schemaView : Erd -> SchemaName -> View
schemaView erd name =
    SchemaView
        { schema = Details.buildSchemaHeading erd name
        , tables = erd.tables |> Dict.values |> List.filterBy .schema name |> List.sortBy .name
        }


tableView : Erd -> TableId -> View
tableView erd id =
    (erd |> Erd.getTable id)
        |> Maybe.mapOrElse
            (\table ->
                TableView
                    { schema = Details.buildSchemaHeading erd table.schema
                    , table = Details.buildTableHeading erd table
                    }
            )
            listView


columnView : Erd -> ColumnRef -> View
columnView erd ref =
    (erd |> Erd.getTable ref.table)
        |> Maybe.mapOrElse
            (\table ->
                (table.columns |> Dict.get ref.column)
                    |> Maybe.mapOrElse
                        (\column ->
                            ColumnView
                                { schema = Details.buildSchemaHeading erd table.schema
                                , table = Details.buildTableHeading erd table
                                , column = Details.buildColumnHeading erd table column
                                }
                        )
                        (tableView erd table.id)
            )
            listView


filterDatabaseSources : List Source -> List ( SourceId, DatabaseUrl )
filterDatabaseSources sources =
    sources |> List.filterMap (\s -> s |> Source.databaseUrl |> Maybe.map (\url -> ( s.id, url )))



-- VIEW


view : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Dict TableId (Dict SourceIdStr TableStats) -> Dict ColumnId (Dict SourceIdStr ColumnStats) -> Erd -> Model -> Html msg
view wrap showTable hideTable showColumn hideColumn loadLayout tableStats columnStats erd model =
    div [ class "flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ class "text-lg font-medium text-gray-900" ] [ text "Details" ]
                , div [ class "ml-3 flex h-7 items-center" ]
                    [ button [ type_ "button", onClick (wrap Close), class "rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                        [ span [ class "sr-only" ] [ text "Close panel" ]
                        , Icon.outline Icon.X ""
                        ]
                    ]
                ]
            ]
        , div [ class "relative mt-6 flex-1 px-4 sm:px-6" ]
            [ div [ class "absolute inset-0" ]
                [ case model.view of
                    ListView ->
                        viewTableList wrap (model.id ++ "-list") erd (erd.tables |> Dict.values) model.search

                    SchemaView v ->
                        viewSchema wrap erd v

                    TableView v ->
                        viewTable wrap showTable hideTable loadLayout erd model.openedCollapse tableStats v

                    ColumnView v ->
                        viewColumn wrap showTable hideTable showColumn hideColumn loadLayout erd model.openedCollapse columnStats v
                ]
            ]
        ]


viewTableList : (Msg -> msg) -> HtmlId -> Erd -> List ErdTable -> String -> Html msg
viewTableList wrap htmlId erd tables search =
    Details.viewList (ShowTable >> wrap) (SearchUpdate >> wrap) htmlId erd.settings.defaultSchema tables search


viewSchema : (Msg -> msg) -> Erd -> SchemaData -> Html msg
viewSchema wrap erd model =
    Details.viewSchema (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) erd.settings.defaultSchema model.schema model.tables


viewTable : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> Dict TableId (Dict SourceIdStr TableStats) -> TableData -> Html msg
viewTable wrap _ _ loadLayout erd openedCollapse stats model =
    let
        tableNotes : Maybe Notes
        tableNotes =
            erd.notes |> Dict.get model.table.item.id |> Maybe.andThen .table

        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id model.table.item.id) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.table.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)

        tableStats : Dict SourceIdStr TableStats
        tableStats =
            stats |> Dict.getOrElse model.table.item.id Dict.empty
    in
    Details.viewTable (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table tableNotes inLayouts inSources tableStats


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> Dict ColumnId (Dict SourceIdStr ColumnStats) -> ColumnData -> Html msg
viewColumn wrap _ _ _ _ loadLayout erd openedCollapse stats model =
    let
        columnNotes : Maybe Notes
        columnNotes =
            erd.notes |> Dict.get model.table.item.id |> Maybe.andThen (\n -> n.columns |> Dict.get model.column.item.name)

        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == model.table.item.id && (t.columns |> List.memberBy .name model.column.item.name))) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.column.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)

        columnStats : Dict SourceIdStr ColumnStats
        columnStats =
            stats |> Dict.getOrElse ( model.table.item.id, model.column.item.name ) Dict.empty
    in
    Details.viewColumn (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) (ShowColumn >> wrap) loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table model.column columnNotes inLayouts inSources columnStats



-- HELPERS


type alias Selected =
    String


selected : Model -> Selected
selected model =
    case model.view of
        ListView ->
            ""

        SchemaView data ->
            data.schema.item

        TableView data ->
            data.schema.item ++ "." ++ data.table.item.name

        ColumnView data ->
            data.schema.item ++ "." ++ data.table.item.name ++ "." ++ data.column.item.name

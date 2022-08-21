module PagesComponents.Projects.Id_.Components.DetailsSidebar exposing (ColumnData, Heading, Model, Msg(..), SchemaData, TableData, View(..), update, view)

import Components.Atoms.Icon as Icon
import Components.Organisms.Details as Details
import Conf
import Dict
import Html exposing (Html, button, div, h2, span, text)
import Html.Attributes exposing (class, id, name, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (setView)


type alias Model =
    { id : HtmlId, view : View, openedCollapse : HtmlId }


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
    | ShowList
    | ShowSchema SchemaName
    | ShowTable TableId
    | ShowColumn ColumnRef
    | ToggleCollapse HtmlId



-- INIT


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v, openedCollapse = "" }



-- UPDATE


update : Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update erd msg model =
    case msg of
        Close ->
            ( Nothing, Cmd.none )

        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (listView |> init |> Just), Cmd.none )

        ShowList ->
            ( model |> setViewM listView, Cmd.none )

        ShowSchema schema ->
            ( model |> setViewM (schemaView erd schema), Cmd.none )

        ShowTable table ->
            ( model |> setViewM (tableView erd table), Cmd.none )

        ShowColumn column ->
            ( model |> setViewM (columnView erd column), Cmd.none )

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
    (erd.tables |> Dict.get id)
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
    (erd.tables |> Dict.get ref.table)
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



-- VIEW


view : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> Model -> Html msg
view wrap showTable hideTable showColumn hideColumn loadLayout erd model =
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
                        viewTableList wrap erd (erd.tables |> Dict.values)

                    SchemaView v ->
                        viewSchema wrap erd v

                    TableView v ->
                        viewTable wrap showTable hideTable loadLayout erd model.openedCollapse v

                    ColumnView v ->
                        viewColumn wrap showTable hideTable showColumn hideColumn loadLayout erd model.openedCollapse v
                ]
            ]
        ]


viewTableList : (Msg -> msg) -> Erd -> List ErdTable -> Html msg
viewTableList wrap erd tables =
    Details.viewList (ShowTable >> wrap) erd.settings.defaultSchema tables


viewSchema : (Msg -> msg) -> Erd -> SchemaData -> Html msg
viewSchema wrap erd model =
    Details.viewSchema (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) erd.settings.defaultSchema model.schema model.tables


viewTable : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> TableData -> Html msg
viewTable wrap _ _ loadLayout erd openedCollapse model =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id model.table.item.id) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.table.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)
    in
    Details.viewTable (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table inLayouts inSources


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> ColumnData -> Html msg
viewColumn wrap _ _ _ _ loadLayout erd openedCollapse model =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == model.table.item.id && (t.columns |> List.memberBy .name model.column.item.name))) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.column.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)
    in
    Details.viewColumn (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) (ShowColumn >> wrap) loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table model.column inLayouts inSources

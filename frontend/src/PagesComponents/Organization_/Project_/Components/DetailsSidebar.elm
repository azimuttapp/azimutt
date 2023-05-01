module PagesComponents.Organization_.Project_.Components.DetailsSidebar exposing (ColumnData, Heading, Model, Msg(..), SchemaData, Selected, TableData, View(..), selected, update, view)

import Browser.Dom as Dom
import Components.Atoms.Icon as Icon
import Components.Organisms.Details as Details
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h2, span, text)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Tag as Tag exposing (Tag)
import Libs.Task as T
import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats exposing (ColumnStats)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Metadata as Metadata
import Models.Project.Origin exposing (Origin)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId, SourceIdStr)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableStats exposing (TableStats)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))
import PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg(..))
import Ports
import Services.Lenses exposing (setEditNotes, setSearch, setView)
import Task


type alias Model =
    { id : HtmlId, view : View, search : String, editNotes : Maybe Notes, editTags : Maybe String, openedCollapse : HtmlId }


type View
    = ListView
    | SchemaView SchemaData
    | TableView TableData
    | ColumnView ColumnData


type alias SchemaData =
    { id : SchemaName, schema : Heading SchemaName Never, tables : List ErdTable }


type alias TableData =
    { id : TableId, schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout }


type alias ColumnData =
    { id : ColumnRef, schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout, column : Heading ErdColumn ErdColumnProps }


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
    | EditNotes HtmlId Notes
    | EditNotesUpdate Notes
    | SaveNotes TableId (Maybe ColumnPath) Notes Notes
    | EditTags HtmlId (List Tag)
    | EditTagsUpdate String
    | SaveTags TableId (Maybe ColumnPath) (List Tag) (List Tag)



-- INIT


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v, search = "", editNotes = Nothing, editTags = Nothing, openedCollapse = "" }



-- UPDATE


update : (String -> msg) -> (NotesMsg -> msg) -> (TagsMsg -> msg) -> Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update noop notesMsg tagsMsg erd msg model =
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

        EditNotes id content ->
            ( model |> Maybe.map (\m -> { m | editNotes = Just content }), Dom.focus id |> Task.attempt (\_ -> noop "focus-notes-input") )

        EditNotesUpdate content ->
            ( model |> Maybe.map (\m -> { m | editNotes = m.editNotes |> Maybe.map (\_ -> content) }), Cmd.none )

        SaveNotes table column initialNotes updatedNotes ->
            ( model |> Maybe.map (\m -> { m | editNotes = Nothing }), NSave table column initialNotes updatedNotes |> notesMsg |> T.send )

        EditTags id tags ->
            ( model |> Maybe.map (\m -> { m | editTags = tags |> Tag.tagsToString |> Just }), Dom.focus id |> Task.attempt (\_ -> noop "focus-tags-input") )

        EditTagsUpdate content ->
            ( model |> Maybe.map (\m -> { m | editTags = m.editTags |> Maybe.map (\_ -> content) }), Cmd.none )

        SaveTags tableId columnPath initialTags updatedTags ->
            ( model |> Maybe.map (\m -> { m | editTags = Nothing }), TSave tableId columnPath initialTags updatedTags |> tagsMsg |> T.send )


setViewM : View -> Maybe Model -> Maybe Model
setViewM v model =
    model |> Maybe.mapOrElse (setView v >> setEditNotes Nothing) (init v) |> Just


listView : View
listView =
    ListView


schemaView : Erd -> SchemaName -> View
schemaView erd name =
    SchemaView
        { id = name
        , schema = Details.buildSchemaHeading erd name
        , tables = erd.tables |> Dict.values |> List.filterBy .schema name |> List.sortBy .name
        }


tableView : Erd -> TableId -> View
tableView erd id =
    (erd |> Erd.getTable id)
        |> Maybe.mapOrElse
            (\table ->
                TableView
                    { id = table.id
                    , schema = Details.buildSchemaHeading erd table.schema
                    , table = Details.buildTableHeading erd table
                    }
            )
            listView


columnView : Erd -> ColumnRef -> View
columnView erd ref =
    (erd |> Erd.getTable ref.table)
        |> Maybe.mapOrElse
            (\table ->
                (table |> ErdTable.getColumn ref.column)
                    |> Maybe.mapOrElse
                        (\column ->
                            ColumnView
                                { id = { table = table.id, column = column.path }
                                , schema = Details.buildSchemaHeading erd table.schema
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


view : (Msg -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Dict TableId (Dict SourceIdStr TableStats) -> Dict ColumnId (Dict SourceIdStr ColumnStats) -> Erd -> Model -> Html msg
view wrap showTable showColumn hideColumn loadLayout tableStats columnStats erd model =
    let
        heading : List (Html msg)
        heading =
            case model.view of
                ListView ->
                    [ text "All tables" ]

                SchemaView v ->
                    [ span [ class "font-bold" ] [ text v.id ], text " schema tables" ]

                TableView v ->
                    [ span [ class "font-bold" ] [ text (TableId.show erd.settings.defaultSchema v.id) ], text " table details" ]

                ColumnView v ->
                    [ span [ class "font-bold" ]
                        [ span [ onClick (v.id.table |> ShowTable |> wrap), class "cursor-pointer" ] [ text (TableId.show erd.settings.defaultSchema v.id.table) ]
                        , text "."
                        , span [] [ text (ColumnPath.show v.id.column) ]
                        ]
                    , text " column details"
                    ]
    in
    div [ class "flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ class "text-lg font-medium text-gray-900 truncate" ] heading
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
                        viewTableList wrap showTable (model.id ++ "-list") erd (erd.tables |> Dict.values) model.search

                    SchemaView v ->
                        viewSchema wrap showTable erd v

                    TableView v ->
                        viewTable wrap showTable loadLayout erd model.editNotes model.editTags model.openedCollapse tableStats v

                    ColumnView v ->
                        viewColumn wrap showTable showColumn hideColumn loadLayout erd model.editNotes model.editTags model.openedCollapse columnStats v
                ]
            ]
        ]


viewTableList : (Msg -> msg) -> (TableId -> msg) -> HtmlId -> Erd -> List ErdTable -> String -> Html msg
viewTableList wrap showTable htmlId erd tables search =
    Details.viewList (ShowTable >> wrap) showTable (SearchUpdate >> wrap) htmlId erd.settings.defaultSchema tables search


viewSchema : (Msg -> msg) -> (TableId -> msg) -> Erd -> SchemaData -> Html msg
viewSchema wrap showTable erd model =
    Details.viewSchema (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) showTable erd.settings.defaultSchema model.schema model.tables


viewTable : (Msg -> msg) -> (TableId -> msg) -> (LayoutName -> msg) -> Erd -> Maybe Notes -> Maybe String -> HtmlId -> Dict TableId (Dict SourceIdStr TableStats) -> TableData -> Html msg
viewTable wrap showTable loadLayout erd editNotes editTags openedCollapse stats model =
    let
        initialNotes : Notes
        initialNotes =
            erd.metadata |> Metadata.getNotes model.id Nothing |> Maybe.withDefault ""

        notesModel : Details.NotesModel msg
        notesModel =
            { notes = initialNotes
            , editing = editNotes
            , edit = \id content -> EditNotes id content |> wrap
            , update = EditNotesUpdate >> wrap
            , save = SaveNotes model.id Nothing initialNotes >> wrap
            }

        initialTags : List Tag
        initialTags =
            erd.metadata |> Metadata.getTags model.id Nothing |> Maybe.withDefault []

        tagsModel : Details.TagsModel msg
        tagsModel =
            { tags = initialTags
            , editing = editTags
            , edit = \id tags -> EditTags id tags |> wrap
            , update = EditTagsUpdate >> wrap
            , save = Tag.tagsFromString >> SaveTags model.id Nothing initialTags >> wrap
            }

        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id model.id) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.table.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)

        tableStats : Dict SourceIdStr TableStats
        tableStats =
            stats |> Dict.getOrElse model.id Dict.empty
    in
    Details.viewTable (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) showTable loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table notesModel tagsModel inLayouts inSources tableStats


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> Maybe Notes -> Maybe String -> HtmlId -> Dict ColumnId (Dict SourceIdStr ColumnStats) -> ColumnData -> Html msg
viewColumn wrap showTable _ _ loadLayout erd editNotes editTags openedCollapse stats model =
    let
        initialNotes : Notes
        initialNotes =
            erd.metadata |> Metadata.getNotes model.id.table (Just model.id.column) |> Maybe.withDefault ""

        notesModel : Details.NotesModel msg
        notesModel =
            { notes = initialNotes
            , editing = editNotes
            , edit = \id content -> EditNotes id content |> wrap
            , update = EditNotesUpdate >> wrap
            , save = SaveNotes model.id.table (Just model.id.column) initialNotes >> wrap
            }

        initialTags : List Tag
        initialTags =
            erd.metadata |> Metadata.getTags model.id.table (Just model.id.column) |> Maybe.withDefault []

        tagsModel : Details.TagsModel msg
        tagsModel =
            { tags = initialTags
            , editing = editTags
            , edit = \id tags -> EditTags id tags |> wrap
            , update = EditTagsUpdate >> wrap
            , save = Tag.tagsFromString >> SaveTags model.id.table (Just model.id.column) initialTags >> wrap
            }

        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == model.id.table && (t.columns |> ErdColumnProps.member model.id.column))) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            model.column.item.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)

        columnStats : Dict SourceIdStr ColumnStats
        columnStats =
            stats |> Dict.getOrElse (ColumnId.fromRef model.id) Dict.empty
    in
    Details.viewColumn (ShowList |> wrap) (ShowSchema >> wrap) (ShowTable >> wrap) (ShowColumn >> wrap) showTable loadLayout (ToggleCollapse >> wrap) openedCollapse erd.settings.defaultSchema model.schema model.table model.column notesModel tagsModel inLayouts inSources columnStats



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
            data.schema.item ++ "." ++ data.table.item.name ++ "." ++ ColumnPath.toString data.column.item.path

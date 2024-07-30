module Components.Slices.DataExplorer exposing (DataExplorerDisplay(..), DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SharedDocState, VisualEditor, VisualEditorFilter, doc, docInit, init, update, view)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Components.Molecules.Editor as Editor
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.DataExplorerDetails as DataExplorerDetails
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Conf
import DataSources.DbMiner.DbQuery as DbQuery
import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), RowQuery, operationFromString, operationHasValue, operationToString, operationsForType, operatorFromString, operatorToString, operators)
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, input, label, nav, option, p, select, span, table, td, text, tr)
import Html.Attributes exposing (class, classList, disabled, for, id, name, selected, style, tabindex, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned exposing (Ned)
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Task as T
import Models.DbSource as DbSource exposing (DbSource)
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project as Project
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapDetailsT, mapFilters, mapResultsT, mapVisualEditor, setOperation, setOperator, setValue)
import Services.Toasts as Toasts
import Track



-- TODO:
--  - popover with JSON editor when hover a JSON value in table row => bad CSS? hard to setup :/
--  - Enable data exploration for other db: MySQL, SQL Server, MongoDB, Couchbase...
--  - Better error handling on connectors (cf PostgreSQL)
--
--  - column stats in query header (quick analysis on query results) => add bar chart & data list
--  - query relation counts on `exploreTable`, `filterTable` & `findRow` (like prisma)
--  - saved queries ({ name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId })
--  - Nested queries like Trevor: on rows & group by
--  - pin a column and replace the fk by it => special tag (`main`)
--  - chart view: scatter plot (view one numerical column related to an other, at a third numeric for dot size, or a categorical (<10 distinct values) one for dot color)
--  - data update: double click on a value to edit it, add a submit option to push them to the database (like datagrip)
--  - shorten uuid to its first component in results
--  - Add filter button on results to change editor (visual or query) and allow to trigger a new query
--  - Polymorphic relations??? Composite primary key???


type alias Model =
    { display : Maybe DataExplorerDisplay
    , activeTab : DataExplorerTab
    , selectedSource : Maybe SourceId
    , visualEditor : VisualEditor
    , queryEditor : QueryEditor
    , results : List DataExplorerQuery.Model
    , resultsSeq : Int
    , details : List DataExplorerDetails.Model
    , detailsSeq : Int
    }


type DataExplorerDisplay
    = BottomDisplay
    | FullScreenDisplay


type DataExplorerTab
    = VisualEditorTab
    | QueryEditorTab


type alias VisualEditor =
    { table : Maybe TableId, filters : List VisualEditorFilter }


type alias VisualEditorFilter =
    { operator : FilterOperator, column : ColumnPath, kind : ColumnType, nullable : Bool, operation : FilterOperation, value : DbValue }


type alias QueryEditor =
    Editor.Model


type Msg
    = Open (Maybe SourceId) (Maybe SqlQueryOrigin)
    | Close
    | UpdateDisplay (Maybe DataExplorerDisplay)
    | UpdateTab DataExplorerTab
    | UpdateSource (Maybe SourceId)
    | UpdateTable (Maybe TableId)
    | AddFilter Table ColumnPath
    | UpdateFilterOperator Int FilterOperator
    | UpdateFilterOperation Int FilterOperation
    | UpdateFilterValue Int DbValue
    | DeleteFilter Int
    | UpdateQuery Editor.Msg
    | RunQuery DbSource SqlQueryOrigin
    | DeleteQuery DataExplorerQuery.Id
    | QueryMsg DataExplorerQuery.Id DataExplorerQuery.Msg
    | OpenDetails DbSourceInfo RowQuery
    | CloseDetails DataExplorerQuery.Id
    | DetailsMsg DataExplorerDetails.Id DataExplorerDetails.Msg
    | LlmGenerateSql SourceId



-- INIT


init : Model
init =
    { display = Nothing
    , activeTab = QueryEditorTab
    , selectedSource = Nothing
    , visualEditor = { table = Nothing, filters = [] }
    , queryEditor = Editor.init ""
    , results = []
    , resultsSeq = 1
    , details = []
    , detailsSeq = 1
    }



-- UPDATE


update : (Msg -> msg) -> (Toasts.Msg -> msg) -> (Maybe SourceId -> msg) -> ProjectInfo -> List Source -> Msg -> Model -> ( Model, Extra msg )
update wrap showToast openGenerateSql project sources msg model =
    case msg of
        Open sourceId query ->
            let
                selected : Maybe SourceId
                selected =
                    sourceId
                        |> Maybe.orElse model.selectedSource
                        |> Maybe.orElse (sources |> List.find (Source.databaseUrl >> Maybe.isJust) |> Maybe.map .id)
                        |> Maybe.orElse (sources |> List.find (.kind >> SourceKind.isDatabase) |> Maybe.map .id)

                source : Maybe DbSource
                source =
                    selected |> Maybe.andThen (\id -> sources |> List.findBy .id id |> Maybe.andThen DbSource.fromSource)

                tab : DataExplorerTab
                tab =
                    query |> Maybe.mapOrElse (\_ -> QueryEditorTab) model.activeTab
            in
            ( { model
                | display = Just BottomDisplay
                , activeTab = tab
                , selectedSource = selected
                , queryEditor = query |> Maybe.map (.sql >> Editor.init) |> Maybe.withDefault model.queryEditor
              }
            , Extra.cmdL
                (Track.dataExplorerOpened sources source query project
                    :: focusMainInput tab
                    :: (Maybe.map2 (\src q -> RunQuery src q |> wrap |> T.send) source query |> Maybe.toList)
                )
            )

        Close ->
            ( { model | display = Nothing }, Extra.none )

        UpdateDisplay d ->
            ( { model | display = d }, Extra.none )

        UpdateTab tab ->
            ( { model | activeTab = tab }, focusMainInput tab |> Extra.cmd )

        UpdateSource source ->
            ( { model | selectedSource = source, visualEditor = { table = Nothing, filters = [] } }, Extra.none )

        UpdateTable table ->
            ( { model | visualEditor = { table = table, filters = [] } }, Extra.none )

        AddFilter table path ->
            ( table |> Table.getColumnI path |> Maybe.mapOrElse (\col -> model |> mapVisualEditor (mapFilters (List.insert { operator = DbAnd, column = path, kind = col.kind, nullable = col.nullable, operation = DbEqual, value = DbString "" }))) model, Extra.none )

        UpdateFilterOperator i operator ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setOperator operator))), Extra.none )

        UpdateFilterOperation i operation ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setOperation operation))), Extra.none )

        UpdateFilterValue i value ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setValue value))), Extra.none )

        DeleteFilter i ->
            ( model |> mapVisualEditor (mapFilters (List.removeAt i)), Extra.none )

        UpdateQuery message ->
            ( { model | queryEditor = Editor.update message model.queryEditor }, Extra.none )

        RunQuery source query ->
            { model | resultsSeq = model.resultsSeq + 1 } |> mapResultsT (List.prependT (DataExplorerQuery.init project model.resultsSeq (DbSource.toInfo source) (query |> DbQuery.addLimit source.db.kind)))

        DeleteQuery id ->
            ( { model | results = model.results |> List.filter (\r -> r.id /= id) }, Extra.none )

        QueryMsg id m ->
            model |> mapResultsT (List.mapByTE .id id (DataExplorerQuery.update showToast project m))

        OpenDetails source query ->
            { model | detailsSeq = model.detailsSeq + 1 } |> mapDetailsT (List.prependT (DataExplorerDetails.init project model.detailsSeq source query))

        CloseDetails id ->
            ( { model | details = model.details |> List.removeBy .id id }, Extra.none )

        DetailsMsg id m ->
            model |> mapDetailsT (List.mapByTE .id id (DataExplorerDetails.update project m))

        LlmGenerateSql source ->
            ( model, source |> Just |> openGenerateSql |> Extra.msg )


focusMainInput : DataExplorerTab -> Cmd msg
focusMainInput tab =
    case tab of
        VisualEditorTab ->
            Ports.focus "data-explorer-dialog-visual-editor-table-input"

        QueryEditorTab ->
            Ports.focus "data-explorer-dialog-query-editor-input"



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> ((msg -> String -> Html msg) -> msg) -> (Source -> msg) -> (TableId -> msg) -> (DbSourceInfo -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> String -> HtmlId -> HtmlId -> Model -> Erd -> DataExplorerDisplay -> Html msg
view wrap toggleDropdown openModal updateSource _ {- showTable -} showTableRow openNotes _ {- navbarHeight -} openedDropdown htmlId model erd display =
    div [ class "h-full flex" ]
        [ div [ class "basis-1/3 flex-1 overflow-y-auto flex flex-col border-r" ]
            -- TODO: put header on the whole width
            [ viewHeader wrap model.activeTab display
            , viewSources wrap (htmlId ++ "-sources") erd.sources model.selectedSource
            , (model.selectedSource |> Maybe.andThen (\id -> erd.sources |> List.findBy .id id))
                |> Maybe.map
                    (\source ->
                        (source |> DbSource.fromSource)
                            |> Maybe.map
                                (\db ->
                                    case model.activeTab of
                                        VisualEditorTab ->
                                            viewVisualExplorer wrap erd.settings.defaultSchema (htmlId ++ "-visual-editor") db model.visualEditor

                                        QueryEditorTab ->
                                            viewQueryEditor wrap toggleDropdown openedDropdown (htmlId ++ "-query-editor") db model.queryEditor
                                )
                            |> Maybe.withDefault
                                (div [ class "m-3" ]
                                    [ Alert.withActions
                                        { color = Tw.blue
                                        , icon = Icon.ExclamationCircle
                                        , title = "Missing database url"
                                        , actions = [ Button.secondary3 Tw.blue [ onClick (source |> updateSource) ] [ text "Update source" ] ]
                                        }
                                        [ text "Open settings (top right ", Icon.outline Icon.Cog "inline", text ") to add the database url for this source and query it." ]
                                    ]
                                )
                    )
                |> Maybe.withDefault (div [] [])
            ]
        , div [ class "basis-2/3 flex-1 overflow-y-auto bg-gray-50 pb-28" ]
            [ viewResults wrap toggleDropdown openModal (\s q -> showTableRow s q Nothing Nothing) openNotes openedDropdown erd (htmlId ++ "-results") model.results ]

        -- Don't show TableRow details, load them directly into the layout, TODO: clean everything once sure about this change...
        --, let
        --    hasFullScreen : Bool
        --    hasFullScreen =
        --        model.results
        --            |> List.any
        --                (\r ->
        --                    case r.state of
        --                        DataExplorerQuery.StateSuccess s ->
        --                            s.fullScreen
        --
        --                        _ ->
        --                            False
        --                )
        --  in
        --  viewRowDetails wrap showTable showTableRow (\s q -> OpenDetails s q |> wrap) openNotes navbarHeight hasFullScreen erd (htmlId ++ "-details") model.details
        ]


viewHeader : (Msg -> msg) -> DataExplorerTab -> DataExplorerDisplay -> Html msg
viewHeader wrap activeTab display =
    div [ class "px-3 flex justify-between border-b border-gray-200" ]
        [ div [ class "sm:flex sm:items-baseline" ]
            [ h3 [ class "text-base font-semibold leading-6 text-gray-900 whitespace-nowrap" ] [ text "Data explorer", Badge.basic Tw.green [ class "ml-1" ] [ text "Beta" ] |> Tooltip.br "Data exploration is free while in beta." ]
            , div [ class "ml-6 mt-0" ]
                [ nav [ class "flex space-x-6" ]
                    ([ VisualEditorTab, QueryEditorTab ] |> List.map (viewHeaderTab wrap activeTab))
                ]
            ]
        , div [ class "py-2 flex flex-shrink-0 self-center" ]
            [ case display of
                FullScreenDisplay ->
                    button [ onClick (Just BottomDisplay |> UpdateDisplay |> wrap), title "minimize", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                        [ Icon.solid Icon.ChevronDoubleDown "" ]

                BottomDisplay ->
                    button [ onClick (Just FullScreenDisplay |> UpdateDisplay |> wrap), title "maximize", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                        [ Icon.solid Icon.ChevronDoubleUp "" ]
            , button [ onClick (wrap Close), title "close", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
            ]
        ]


viewHeaderTab : (Msg -> msg) -> DataExplorerTab -> DataExplorerTab -> Html msg
viewHeaderTab wrap active tab =
    let
        style : TwClass
        style =
            if tab == active then
                "border-indigo-500 text-indigo-600"

            else
                "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
    in
    button [ type_ "button", onClick (UpdateTab tab |> wrap), css [ style, "whitespace-nowrap border-b-2 px-1 py-2 text-sm font-medium" ] ]
        [ text
            (case tab of
                VisualEditorTab ->
                    "Visual editor"

                QueryEditorTab ->
                    "Query editor"
            )
        ]


viewSources : (Msg -> msg) -> HtmlId -> List Source -> Maybe SourceId -> Html msg
viewSources wrap htmlId sources selectedSource =
    let
        sourceInput : HtmlId
        sourceInput =
            htmlId ++ "-input"
    in
    case sources |> List.filter (.kind >> SourceKind.isDatabase) of
        [] ->
            div [ class "mt-3 mx-3" ]
                [ Alert.withDescription
                    { color = Tw.blue
                    , icon = Icon.InformationCircle
                    , title = "No database source in project"
                    }
                    [ p [] [ text "Azimutt can explore nicely your database if you have a source with a database url." ]
                    , p [] [ text "To add one, open settings (top right cog), click on 'add source' and provide your database url." ]
                    , p []
                        [ text "Local databases are accessible with "
                        , extLink "https://www.npmjs.com/package/azimutt" [ class "link" ] [ text "Azimutt CLI" ]
                        , text " ("
                        , Badge.basic Tw.blue [] [ text "npx azimutt@latest gateway" ] |> Tooltip.t "Starts the Azimutt Gateway on your computer to access local databases."
                        , text ")."
                        ]
                    ]
                ]

        db :: [] ->
            selectedSource
                |> Maybe.map (\_ -> div [] [])
                |> Maybe.withDefault
                    (div [ class "mt-3 mx-3" ]
                        [ Alert.withActions
                            { color = Tw.red
                            , icon = Icon.ExclamationCircle
                            , title = "Ooops"
                            , actions = [ Button.secondary2 Tw.red [ onClick (Just db.id |> UpdateSource |> wrap) ] [ text ("Select " ++ db.name ++ " source") ] ]
                            }
                            [ p [] [ text "You project has one database source but it's not selected in data explorer." ]
                            , p []
                                [ text "This is not expected, if you see this, please report to "
                                , extLink ("mailto:" ++ Conf.constants.azimuttEmail) [ class "link" ] [ text "Azimutt team" ]
                                , text "."
                                ]
                            ]
                        ]
                    )

        dbs ->
            div []
                [ select
                    [ id sourceInput
                    , name sourceInput
                    , onInput (SourceId.fromString >> UpdateSource >> wrap)
                    , class "mt-3 mx-3 block rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    ]
                    (option [] [ text "-- select a source" ] :: (dbs |> List.map (\s -> option [ value (SourceId.toString s.id), selected (selectedSource == Just s.id) ] [ text (s.name ++ (s |> Source.databaseUrl |> Maybe.mapOrElse (\_ -> "") " (needs url)")) ])))
                ]


viewVisualExplorer : (Msg -> msg) -> SchemaName -> HtmlId -> DbSource -> VisualEditor -> Html msg
viewVisualExplorer wrap defaultSchema htmlId source model =
    let
        tables : List TableId
        tables =
            source.tables |> Dict.values |> List.map .id
    in
    if tables |> List.isEmpty then
        div [ class "mt-3 mx-3" ]
            [ p [] [ text "No tables in ", bText source.name, text " source 😥" ]
            , p [] [ text "Try to refresh it or choose an other one." ]
            ]

    else
        div [ class "mt-3 mx-3" ]
            [ viewVisualExplorerTable wrap defaultSchema (htmlId ++ "-table-input") tables model.table
            , model.table |> Maybe.andThen (\id -> source.tables |> Dict.get id) |> Maybe.mapOrElse (viewVisualExplorerFilterAdd wrap (htmlId ++ "-filter-add")) (div [] [])
            , viewVisualExplorerFilterShow wrap (htmlId ++ "-filter") model.filters
            , viewVisualExplorerSubmit wrap source model
            ]


viewVisualExplorerTable : (Msg -> msg) -> SchemaName -> HtmlId -> List TableId -> Maybe TableId -> Html msg
viewVisualExplorerTable wrap defaultSchema htmlId tables table =
    div []
        [ label [ for htmlId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text "Explore table:" ]
        , select
            [ id htmlId
            , name htmlId
            , onInput (TableId.fromString >> UpdateTable >> wrap)
            , class "rounded-md mt-1 py-1.5 pl-3 pr-10 block w-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ]
            (option [] [] :: (tables |> List.map (\id -> option [ value (TableId.toString id), selected (table |> Maybe.has id) ] [ text (TableId.show defaultSchema id) ])))
        ]


viewVisualExplorerFilterAdd : (Msg -> msg) -> HtmlId -> Table -> Html msg
viewVisualExplorerFilterAdd wrap htmlId table =
    div [ class "mt-3" ]
        [ label [ for htmlId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text "Filter on column:" ]
        , div [ class "mt-1 flex rounded-md shadow-sm" ]
            [ div [ class "relative flex flex-grow items-stretch focus-within:z-10" ]
                [ select
                    [ id htmlId
                    , name htmlId
                    , onInput (ColumnPath.fromString >> AddFilter table >> wrap)
                    , class "py-1.5 pl-3 pr-10 block w-full rounded-md border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    ]
                    (option [ selected True ] []
                        :: (table.columns
                                |> Dict.values
                                |> List.concatMap Column.flatten
                                |> List.map (\c -> option [ value (ColumnPath.toString c.path), selected False ] [ text (ColumnPath.show c.path ++ ": " ++ c.column.kind) ])
                           )
                    )
                ]
            ]
        ]


viewVisualExplorerFilterShow : (Msg -> msg) -> HtmlId -> List VisualEditorFilter -> Html msg
viewVisualExplorerFilterShow wrap htmlId filters =
    if filters |> List.isEmpty then
        div [] []

    else
        div [ class "mt-3" ]
            [ table [ class "w-full" ]
                (filters
                    |> List.indexedMap
                        (\i f ->
                            tr [ class "text-left" ]
                                [ td []
                                    [ if i == 0 then
                                        text ""

                                      else
                                        select
                                            [ name (htmlId ++ "-" ++ String.fromInt i ++ "-operator")
                                            , onInput (operatorFromString >> Maybe.withDefault DbAnd >> UpdateFilterOperator i >> wrap)
                                            , class "py-1.5 pl-3 pr-10 block rounded-md border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                            ]
                                            (operators |> List.map (\o -> option [ value (operatorToString o), selected (o == f.operator) ] [ text (operatorToString o) ]))
                                    ]
                                , td [ class "font-bold" ] [ text (ColumnPath.show f.column) ]
                                , td []
                                    [ select
                                        [ name (htmlId ++ "-" ++ String.fromInt i ++ "-operation")
                                        , onInput (operationFromString >> Maybe.withDefault DbEqual >> UpdateFilterOperation i >> wrap)
                                        , class "py-1.5 pl-3 pr-10 block rounded-md border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                        ]
                                        (operationsForType f.kind f.nullable |> List.map (\o -> option [ value (operationToString o), selected (o == f.operation) ] [ text (operationToString o) ]))
                                    ]
                                , td []
                                    [ if operationHasValue f.operation then
                                        input
                                            [ type_ "text"
                                            , name (htmlId ++ "-" ++ String.fromInt i ++ "-value")
                                            , value (f.value |> DbValue.toString)
                                            , onInput (DbValue.fromString f.kind >> UpdateFilterValue i >> wrap)
                                            , class "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                            ]
                                            []

                                      else
                                        text ""
                                    ]
                                , td [ class "text-right" ] [ button [ type_ "button", onClick (DeleteFilter i |> wrap), class "py-1.5 text-gray-400" ] [ Icon.outline Icon.Trash "w-5 h-5" ] ]
                                ]
                        )
                )
            ]


viewVisualExplorerSubmit : (Msg -> msg) -> DbSource -> VisualEditor -> Html msg
viewVisualExplorerSubmit wrap source model =
    let
        query : SqlQueryOrigin
        query =
            model.table |> Maybe.mapOrElse (\table -> DbQuery.filterTable source.db.kind { table = table, filters = model.filters |> List.map (\f -> { operator = f.operator, column = f.column, operation = f.operation, value = f.value }) }) { sql = "", origin = "filterTableEmpty", db = source.db.kind }
    in
    div [ class "mt-3 flex items-center justify-end" ]
        [ button [ type_ "button", onClick (query |> RunQuery source |> wrap), disabled (query.sql == ""), class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300" ]
            [ text "Fetch data" ]
        ]


viewQueryEditor : (Msg -> msg) -> (HtmlId -> msg) -> HtmlId -> HtmlId -> DbSource -> QueryEditor -> Html msg
viewQueryEditor wrap toggleDropdown openedDropdown htmlId source model =
    let
        ( inputId, optionsButton ) =
            ( htmlId ++ "-input", htmlId ++ "-button-options" )
    in
    div [ class "flex-1 flex flex-col relative" ]
        [ div [ class "m-3 block flex-1 rounded-md shadow-sm ring-1 ring-inset ring-gray-300" ] [ Editor.sql (UpdateQuery >> wrap) inputId model ]
        , div [ class "absolute bottom-6 right-6 z-10 inline-flex flex-row-reverse gap-3" ]
            [ button
                [ type_ "button"
                , onClick ({ sql = model.content, origin = "userQuery", db = source.db.kind } |> RunQuery source |> wrap)
                , disabled (model.content == "")
                , class "relative inline-flex items-center rounded bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                ]
                [ text "Run query" ]
            , div [ class "relative" ]
                [ button
                    [ type_ "button"
                    , onClick (toggleDropdown optionsButton)
                    , id optionsButton
                    , class "relative inline-flex items-center rounded px-2 py-2 text-sm font-semibold bg-white text-gray-500 ring-1 ring-inset ring-gray-300 shadow-sm hover:bg-gray-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 focus:z-10"
                    , ariaExpanded True
                    , ariaHaspopup "true"
                    ]
                    [ span [ class "sr-only" ] [ text "Open AI options" ]
                    , Icon.outline Icon.Sparkles "h-5 w-5"
                    ]
                , div [ classList [ ( "hidden", openedDropdown /= optionsButton ) ], class "w-56 absolute bottom-full mb-3 right-0 flex-col items-end z-max origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none", role "menu", ariaOrientation "vertical", ariaLabelledby optionsButton, tabindex -1 ]
                    [ div [ class "py-1", role "none" ]
                        [ button [ type_ "button", onClick (LlmGenerateSql source.id |> wrap), class "text-gray-700 block w-full text-left px-4 py-2 text-sm hover:bg-gray-100 hover:text-gray-900", role "menuitem", tabindex -1 ]
                            [ Icon.outline Icon.Sparkles "h-5 w-5 inline mr-1", text "Generate SQL from text" ]
                        ]
                    ]
                ]
            ]
        ]


viewResults : (Msg -> msg) -> (HtmlId -> msg) -> ((msg -> String -> Html msg) -> msg) -> (DbSourceInfo -> RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> HtmlId -> Erd -> HtmlId -> List DataExplorerQuery.Model -> Html msg
viewResults wrap toggleDropdown openModal openRow openNotes openedDropdown erd htmlId results =
    if results |> List.isEmpty then
        div [ class "m-3 p-12 block rounded-lg border-2 border-dashed border-gray-200 text-gray-300 text-center text-sm font-semibold" ] [ text "Query results" ]

    else
        div []
            (results
                |> List.indexedMap
                    (\i r ->
                        div [ class "m-3 px-2 py-1 rounded-md bg-white shadow", classList [ ( "mb-6", i == 0 ) ] ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) toggleDropdown openModal openRow (DeleteQuery r.id |> wrap) openNotes openedDropdown erd (htmlId ++ "-" ++ String.fromInt r.id) r
                            ]
                    )
            )


viewRowDetails : (Msg -> msg) -> (TableId -> msg) -> (DbSourceInfo -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (DbSourceInfo -> RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> String -> Bool -> Erd -> HtmlId -> List DataExplorerDetails.Model -> Html msg
viewRowDetails wrap showTable showTableRow openRowDetails openNotes navbarHeight hasFullScreen erd htmlId details =
    div []
        (details
            |> List.indexedMap (\i m -> DataExplorerDetails.view (DetailsMsg m.id >> wrap) (CloseDetails m.id |> wrap) showTable showTableRow (openRowDetails m.source) openNotes navbarHeight hasFullScreen erd (htmlId ++ "-" ++ String.fromInt m.id) (Just i) m)
            |> List.reverse
        )



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, model : Model, oneSource : Model, noSource : Model }


docInit : DocState
docInit =
    { openedDropdown = ""
    , model = { init | selectedSource = Just docSource1.id, results = docQueryResults, resultsSeq = List.length docQueryResults + 1 }
    , oneSource = init
    , noSource = init
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorer"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "data explorer" .model (\s m -> { s | model = m }) (docErd |> Erd.setSources docSources) docSources
            , docComponentState "one source" .oneSource (\s m -> { s | oneSource = m }) (docErd |> Erd.setSources [ docSource1 ]) (docSources |> List.take 1)
            , docComponentState "no source" .noSource (\s m -> { s | noSource = m }) (docErd |> Erd.setSources []) []
            ]


docQueryResults : List DataExplorerQuery.Model
docQueryResults =
    [ { id = 3
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = { sql = DataExplorerQuery.docCityQuery, origin = "doc", db = DatabaseKind.PostgreSQL }
      , state = DataExplorerQuery.docCitySuccess
      }
    , { id = 2
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = { sql = DataExplorerQuery.docProjectsQuery, origin = "doc", db = DatabaseKind.PostgreSQL }
      , state = DataExplorerQuery.docProjectsSuccess
      }
    , { id = 1
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = { sql = DataExplorerQuery.docUsersQuery, origin = "doc", db = DatabaseKind.PostgreSQL }
      , state = DataExplorerQuery.docUsersSuccess
      }
    ]


docErd : Erd
docErd =
    Project.create Nothing [] "Azimutt" docSource1 |> Erd.create


docSources : List Source
docSources =
    [ docSource1, docSource2, docSource3 ]


docSource1 : Source
docSource1 =
    DataExplorerQuery.docSource


docSource2 : Source
docSource2 =
    { docSource1
        | id = SourceId.one
        , name = "azimutt_prod"
        , tables =
            [ DataExplorerQuery.docTable "public" "users" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "created_at", "timestamp", False ) ]
            , Table.empty |> (\t -> { t | id = ( "", "key_values" ), name = "key_values", columns = docKeyValueColumns })
            ]
                |> Dict.fromListBy .id
        , relations = []
    }


docSource3 : Source
docSource3 =
    { docSource1 | id = SourceId.two, name = "new", tables = Dict.empty, relations = [] }


docKeyValueColumns : Dict ColumnName Column
docKeyValueColumns =
    [ Column.empty |> (\c -> { c | index = 0, name = "key", kind = "varchar", nullable = False })
    , Column.empty |> (\c -> { c | index = 1, name = "value", kind = "json", nullable = True, columns = Just (NestedColumns docKeyValueNestedColumns) })
    ]
        |> Dict.fromListBy .name


docKeyValueNestedColumns : Ned ColumnName Column
docKeyValueNestedColumns =
    Ned.build ( "name", Column.empty |> (\c -> { c | index = 0, name = "name", kind = "varchar", nullable = False }) )
        [ ( "score", Column.empty |> (\c -> { c | index = 1, name = "score", kind = "int", nullable = True }) )
        ]



-- DOC HELPERS


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Erd -> List Source -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set erd sources =
    ( name, \{ dataExplorerDocState } -> dataExplorerDocState |> (\s -> div [ style "height" "500px" ] [ view (docUpdate s get set sources) (docToggleDropdown s) docOpenModal docUpdateSource docShowTable docShowTableRow docOpenNotes "0px" s.openedDropdown "data-explorer" (get s) erd (get s |> .display |> Maybe.withDefault BottomDisplay) ]) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set sources m =
    s |> get |> update docWrap docShowToast docOpenGenerateSql ProjectInfo.zero sources m |> Tuple.first |> set s |> docSetState


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docOpenModal : (msg -> String -> Html msg) -> ElmBook.Msg (SharedDocState x)
docOpenModal _ =
    logAction "openModal"


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap _ =
    logAction "wrap"


docShowToast : Toasts.Msg -> ElmBook.Msg state
docShowToast _ =
    logAction "showToast"


docOpenGenerateSql : Maybe SourceId -> ElmBook.Msg state
docOpenGenerateSql _ =
    logAction "openGenerateSql"


docUpdateSource : Source -> ElmBook.Msg state
docUpdateSource _ =
    logAction "updateSource"


docShowTable : TableId -> ElmBook.Msg state
docShowTable _ =
    logAction "showTable"


docShowTableRow : DbSourceInfo -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ElmBook.Msg state
docShowTableRow _ _ _ _ =
    logAction "showTableRow"


docOpenNotes : TableId -> Maybe ColumnPath -> ElmBook.Msg state
docOpenNotes _ _ =
    logAction "openNotes"

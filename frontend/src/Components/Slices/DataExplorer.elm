module Components.Slices.DataExplorer exposing (DataExplorerDisplay(..), DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SharedDocState, VisualEditor, VisualEditorFilter, doc, docInit, init, update, view)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.DataExplorerDetails as DataExplorerDetails
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Conf
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, input, label, nav, option, p, select, table, td, text, textarea, tr)
import Html.Attributes exposing (autofocus, class, classList, disabled, for, id, name, placeholder, selected, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned exposing (Ned)
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Task as T
import Libs.Time as Time
import Models.DbSource as DbSource exposing (DbSource)
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Metadata exposing (Metadata)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Ports
import Services.Lenses exposing (mapDetailsCmd, mapFilters, mapResultsCmd, mapVisualEditor, setOperation, setOperator, setValue)
import Services.QueryBuilder as QueryBuilder exposing (SqlQuery)
import Track



-- TODO:
--  - popover with JSON when hover a JSON value in table row => bad CSS? hard to setup :/
--  - Check embed mode to remove drag, hover & others
--  - Show incoming rows in the side bar (and results?)
--  - Enable data exploration for other db: MySQL, SQL Server, MongoDB, Couchbase... (QueryBuilder...)
--  - Better error handling on connectors (cf PostgreSQL)
--
--  - column stats in query header (quick analysis on query results)
--  - pin a column and replace the fk by it
--  - Nested queries like Trevor: on rows & group by
--  - Double click on a value to edit it, add a submit option to push them to the database (like datagrip)
--  - shorten uuid to its first component in results
--  - Add filter button on results to change editor (visual or query) and allow to trigger a new query
--  - Polymorphic relations??? Composite primary key???


type alias Model =
    { display : Maybe DataExplorerDisplay
    , activeTab : DataExplorerTab
    , source : Maybe DbSource
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
    { operator : QueryBuilder.FilterOperator, column : ColumnPath, kind : ColumnType, nullable : Bool, operation : QueryBuilder.FilterOperation, value : DbValue }


type alias QueryEditor =
    SqlQuery



-- TODO type alias SavedQuery =
--    { name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId }


type Msg
    = Open (Maybe SourceId) (Maybe SqlQuery)
    | Close
    | UpdateDisplay (Maybe DataExplorerDisplay)
    | UpdateTab DataExplorerTab
    | UpdateSource (Maybe DbSource)
    | UpdateTable (Maybe TableId)
    | AddFilter Table ColumnPath
    | UpdateFilterOperator Int QueryBuilder.FilterOperator
    | UpdateFilterOperation Int QueryBuilder.FilterOperation
    | UpdateFilterValue Int DbValue
    | DeleteFilter Int
    | UpdateQuery SqlQuery
    | RunQuery DbSource SqlQuery
    | DeleteQuery DataExplorerQuery.Id
    | QueryMsg DataExplorerQuery.Id DataExplorerQuery.Msg
    | OpenDetails DbSourceInfo QueryBuilder.RowQuery
    | CloseDetails DataExplorerQuery.Id
    | DetailsMsg DataExplorerDetails.Id DataExplorerDetails.Msg



-- INIT


init : Model
init =
    { display = Nothing
    , activeTab = VisualEditorTab
    , source = Nothing
    , visualEditor = { table = Nothing, filters = [] }
    , queryEditor = ""
    , results = []
    , resultsSeq = 1
    , details = []
    , detailsSeq = 1
    }



-- UPDATE


update : (Msg -> msg) -> ProjectInfo -> List Source -> Msg -> Model -> ( Model, Cmd msg )
update wrap project sources msg model =
    case msg of
        Open source query ->
            let
                dbSources : List DbSource
                dbSources =
                    sources |> List.filterMap DbSource.fromSource

                tab : DataExplorerTab
                tab =
                    query |> Maybe.mapOrElse (\_ -> QueryEditorTab) model.activeTab
            in
            ( { model
                | display = Just BottomDisplay
                , activeTab = tab
                , source =
                    source
                        |> Maybe.andThen (\id -> dbSources |> List.find (\s -> s.id == id))
                        |> Maybe.orElse model.source
                        |> Maybe.orElse (dbSources |> List.head)
                , queryEditor = query |> Maybe.withDefault model.queryEditor
              }
            , Cmd.batch
                (Track.dataExplorerOpened sources query project
                    :: focusMainInput tab
                    :: (Maybe.map2 (\src q -> RunQuery src q |> wrap |> T.send) (source |> Maybe.andThen (\id -> dbSources |> List.findBy .id id)) query |> Maybe.toList)
                )
            )

        Close ->
            ( { model | display = Nothing }, Cmd.none )

        UpdateDisplay d ->
            ( { model | display = d }, Cmd.none )

        UpdateTab tab ->
            ( { model | activeTab = tab }, focusMainInput tab )

        UpdateSource source ->
            ( { model | source = source, visualEditor = { table = Nothing, filters = [] } }, Cmd.none )

        UpdateTable table ->
            ( { model | visualEditor = { table = table, filters = [] } }, Cmd.none )

        AddFilter table path ->
            ( table |> Table.getColumn path |> Maybe.mapOrElse (\col -> model |> mapVisualEditor (mapFilters (List.add { operator = QueryBuilder.OpAnd, column = path, kind = col.kind, nullable = col.nullable, operation = QueryBuilder.OpEqual, value = DbString "" }))) model, Cmd.none )

        UpdateFilterOperator i operator ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setOperator operator))), Cmd.none )

        UpdateFilterOperation i operation ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setOperation operation))), Cmd.none )

        UpdateFilterValue i value ->
            ( model |> mapVisualEditor (mapFilters (List.mapAt i (setValue value))), Cmd.none )

        DeleteFilter i ->
            ( model |> mapVisualEditor (mapFilters (List.removeAt i)), Cmd.none )

        UpdateQuery content ->
            ( { model | queryEditor = content }, Cmd.none )

        RunQuery source query ->
            { model | resultsSeq = model.resultsSeq + 1 } |> mapResultsCmd (List.prependCmd (DataExplorerQuery.init project (model.activeTab == QueryEditorTab) model.resultsSeq (DbSource.toInfo source) (query |> QueryBuilder.limitResults source.db.kind)))

        DeleteQuery id ->
            ( { model | results = model.results |> List.filter (\r -> r.id /= id) }, Cmd.none )

        QueryMsg id m ->
            --model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update (QueryMsg id >> wrap) m))
            model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update project m))

        OpenDetails source query ->
            { model | detailsSeq = model.detailsSeq + 1 } |> mapDetailsCmd (List.prependCmd (DataExplorerDetails.init project model.detailsSeq source query))

        CloseDetails id ->
            ( { model | details = model.details |> List.removeBy .id id }, Cmd.none )

        DetailsMsg id m ->
            --model |> mapDetailsCmd (List.mapByCmd .id id (DataExplorerDetails.update (DetailsMsg id >> wrap) m))
            model |> mapDetailsCmd (List.mapByCmd .id id (DataExplorerDetails.update project m))


focusMainInput : DataExplorerTab -> Cmd msg
focusMainInput tab =
    case tab of
        VisualEditorTab ->
            Ports.focus "data-explorer-dialog-visual-editor-table-input"

        QueryEditorTab ->
            Ports.focus "data-explorer-dialog-query-editor-input"



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> (TableId -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> String -> HtmlId -> SchemaName -> HtmlId -> List Source -> ErdLayout -> Metadata -> Model -> DataExplorerDisplay -> Html msg
view wrap toggleDropdown showTable showTableRow openNotes navbarHeight openedDropdown defaultSchema htmlId sources layout metadata model display =
    let
        hasFullScreen : Bool
        hasFullScreen =
            model.results
                |> List.any
                    (\r ->
                        case r.state of
                            DataExplorerQuery.StateSuccess s ->
                                s.fullScreen

                            _ ->
                                False
                    )
    in
    div [ class "h-full flex" ]
        [ div [ class "basis-1/3 flex-1 overflow-y-auto flex flex-col border-r" ]
            -- TODO: put header on the whole width
            [ viewHeader wrap model.activeTab model.source display
            , viewSources wrap (htmlId ++ "-sources") sources model.source
            , case model.activeTab of
                VisualEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewVisualExplorer wrap defaultSchema (htmlId ++ "-visual-editor") s model.visualEditor) (div [] [])

                QueryEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewQueryEditor wrap (htmlId ++ "-query-editor") s model.queryEditor) (div [] [])
            ]
        , div [ class "basis-2/3 flex-1 overflow-y-auto bg-gray-50 pb-28" ]
            [ viewResults wrap toggleDropdown (\s q -> OpenDetails s q |> wrap) openNotes openedDropdown defaultSchema sources metadata (htmlId ++ "-results") model.results ]
        , viewDetails wrap showTable showTableRow (\s q -> OpenDetails s q |> wrap) openNotes navbarHeight hasFullScreen defaultSchema sources layout metadata (htmlId ++ "-details") model.details
        ]


viewHeader : (Msg -> msg) -> DataExplorerTab -> Maybe DbSource -> DataExplorerDisplay -> Html msg
viewHeader wrap activeTab source display =
    div [ class "px-3 flex justify-between border-b border-gray-200" ]
        [ div [ class "sm:flex sm:items-baseline" ]
            [ h3 [ class "text-base font-semibold leading-6 text-gray-900" ] [ text "Data explorer" ]
            , source
                |> Maybe.map
                    (\_ ->
                        div [ class "ml-6 mt-0" ]
                            [ nav [ class "flex space-x-6" ]
                                ([ VisualEditorTab, QueryEditorTab ] |> List.map (viewHeaderTab wrap activeTab))
                            ]
                    )
                |> Maybe.withDefault (div [] [])
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


viewSources : (Msg -> msg) -> HtmlId -> List Source -> Maybe DbSource -> Html msg
viewSources wrap htmlId sources selectedSource =
    let
        sourceInput : HtmlId
        sourceInput =
            htmlId ++ "-input"
    in
    case sources |> List.filterMap DbSource.fromSource of
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
                        , Badge.basic Tw.blue [] [ text "npx azimutt gateway" ] |> Tooltip.t "Starts the Azimutt Gateway on your computer to access local databases."
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
                            , actions = [ Button.secondary2 Tw.red [ onClick (Just db |> UpdateSource |> wrap) ] [ text ("Select " ++ db.name ++ " source") ] ]
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

        dbSources ->
            div []
                [ select
                    [ id sourceInput
                    , name sourceInput
                    , onInput (SourceId.fromString >> Maybe.andThen (\id -> dbSources |> List.findBy .id id) >> UpdateSource >> wrap)
                    , class "mt-3 mx-3 block rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    ]
                    (option [] [ text "-- select a source" ] :: (dbSources |> List.map (\s -> option [ value (SourceId.toString s.id), selected (selectedSource |> Maybe.hasBy .id s.id) ] [ text s.name ])))
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
                                            , onInput (QueryBuilder.operatorFromString >> Maybe.withDefault QueryBuilder.OpAnd >> UpdateFilterOperator i >> wrap)
                                            , class "py-1.5 pl-3 pr-10 block rounded-md border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                            ]
                                            (QueryBuilder.operators |> List.map (\o -> option [ value (QueryBuilder.operatorToString o), selected (o == f.operator) ] [ text (QueryBuilder.operatorToString o) ]))
                                    ]
                                , td [ class "font-bold" ] [ text (ColumnPath.show f.column) ]
                                , td []
                                    [ select
                                        [ name (htmlId ++ "-" ++ String.fromInt i ++ "-operation")
                                        , onInput (QueryBuilder.stringToOperation >> Maybe.withDefault QueryBuilder.OpEqual >> UpdateFilterOperation i >> wrap)
                                        , class "py-1.5 pl-3 pr-10 block rounded-md border-0 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                        ]
                                        (QueryBuilder.operationsForType f.kind f.nullable |> List.map (\o -> option [ value (QueryBuilder.operationToString o), selected (o == f.operation) ] [ text (QueryBuilder.operationToString o) ]))
                                    ]
                                , td []
                                    [ if QueryBuilder.operationHasValue f.operation then
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
        query : String
        query =
            model.table |> Maybe.mapOrElse (\table -> QueryBuilder.filterTable source.db.kind { table = table, filters = model.filters |> List.map (\f -> { operator = f.operator, column = f.column, operation = f.operation, value = f.value }) }) ""
    in
    div [ class "mt-3 flex items-center justify-end" ]
        [ button [ type_ "button", onClick (query |> RunQuery source |> wrap), disabled (query == ""), class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300" ]
            [ text "Fetch data" ]
        ]


viewQueryEditor : (Msg -> msg) -> HtmlId -> DbSource -> QueryEditor -> Html msg
viewQueryEditor wrap htmlId source model =
    let
        inputId : HtmlId
        inputId =
            htmlId ++ "-input"
    in
    div [ class "flex-1 flex flex-col relative" ]
        [ textarea
            [ name inputId
            , id inputId
            , value model
            , onInput (UpdateQuery >> wrap)
            , autofocus True
            , placeholder ("Write a query for " ++ source.name)
            , class "m-3 py-1.5 block flex-1 rounded-md border-0 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ]
            []
        , div [ class "absolute bottom-6 right-6" ]
            [ button
                [ type_ "button"
                , onClick (model |> RunQuery source |> wrap)
                , disabled (model == "")
                , class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                ]
                [ text "Run query" ]
            ]
        ]


viewResults : (Msg -> msg) -> (HtmlId -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> HtmlId -> SchemaName -> List Source -> Metadata -> HtmlId -> List DataExplorerQuery.Model -> Html msg
viewResults wrap toggleDropdown openRow openNotes openedDropdown defaultSchema sources metadata htmlId results =
    if results |> List.isEmpty then
        div [ class "m-3 p-12 block rounded-lg border-2 border-dashed border-gray-200 text-gray-300 text-center text-sm font-semibold" ] [ text "Query results" ]

    else
        div []
            (results
                |> List.indexedMap
                    (\i r ->
                        div [ class "m-3 px-2 py-1 rounded-md bg-white shadow", classList [ ( "mb-6", i == 0 ) ] ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) toggleDropdown openRow (DeleteQuery r.id |> wrap) openNotes openedDropdown defaultSchema (sources |> List.find (\s -> s.id == r.source.id)) metadata (htmlId ++ "-" ++ String.fromInt r.id) r
                            ]
                    )
            )


viewDetails : (Msg -> msg) -> (TableId -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> String -> Bool -> SchemaName -> List Source -> ErdLayout -> Metadata -> HtmlId -> List DataExplorerDetails.Model -> Html msg
viewDetails wrap showTable showTableRow openRowDetails openNotes navbarHeight hasFullScreen defaultSchema sources layout metadata htmlId details =
    div []
        (details
            |> List.indexedMap (\i m -> DataExplorerDetails.view (DetailsMsg m.id >> wrap) (CloseDetails m.id |> wrap) showTable showTableRow (openRowDetails m.source) openNotes navbarHeight hasFullScreen defaultSchema (sources |> List.findBy .id m.source.id) (layout.tables |> List.findBy .id m.query.table) (metadata |> Dict.get m.query.table) (htmlId ++ "-" ++ String.fromInt m.id) (Just i) m)
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
    , model = { init | source = DbSource.fromSource docSource1, results = docQueryResults, resultsSeq = List.length docQueryResults + 1 }
    , oneSource = init
    , noSource = init
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorer"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "data explorer" .model (\s m -> { s | model = m }) docSources
            , docComponentState "one source" .oneSource (\s m -> { s | oneSource = m }) (docSources |> List.take 1)
            , docComponentState "no source" .noSource (\s m -> { s | noSource = m }) []
            ]


docQueryResults : List DataExplorerQuery.Model
docQueryResults =
    [ { id = 3
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = DataExplorerQuery.docCityQuery
      , state = DataExplorerQuery.docCitySuccess
      }
    , { id = 2
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = DataExplorerQuery.docProjectsQuery
      , state = DataExplorerQuery.docProjectsSuccess
      }
    , { id = 1
      , source = docSource1 |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero
      , query = DataExplorerQuery.docUsersQuery
      , state = DataExplorerQuery.docUsersSuccess
      }
    ]


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
            , Table.new "" "key_values" False docKeyValueColumns Nothing [] [] [] Nothing []
            ]
                |> Dict.fromListMap .id
        , relations = []
    }


docSource3 : Source
docSource3 =
    { docSource1 | id = SourceId.two, name = "new", tables = Dict.empty, relations = [] }


docKeyValueColumns : Dict ColumnName Column
docKeyValueColumns =
    [ { index = 0, name = "key", kind = "varchar", nullable = False, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }
    , { index = 1, name = "value", kind = "json", nullable = True, default = Nothing, comment = Nothing, columns = Just (NestedColumns docKeyValueNestedColumns), origins = [] }
    ]
        |> Dict.fromListMap .name


docKeyValueNestedColumns : Ned ColumnName Column
docKeyValueNestedColumns =
    Ned.build ( "name", { index = 0, name = "name", kind = "varchar", nullable = False, default = Nothing, comment = Nothing, columns = Nothing, origins = [] } )
        [ ( "score", { index = 1, name = "score", kind = "int", nullable = True, default = Nothing, comment = Nothing, columns = Nothing, origins = [] } )
        ]


docMetadata : Metadata
docMetadata =
    Dict.empty


docLayout : ErdLayout
docLayout =
    ErdLayout.empty Time.zero



-- DOC HELPERS


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set sources =
    ( name, \{ dataExplorerDocState } -> dataExplorerDocState |> (\s -> div [ style "height" "500px" ] [ view (docUpdate s get set sources) (docToggleDropdown s) docShowTable docShowTableRow docOpenNotes "0px" s.openedDropdown "public" "data-explorer" sources docLayout docMetadata (get s) (get s |> .display |> Maybe.withDefault BottomDisplay) ]) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set sources m =
    s |> get |> update docWrap ProjectInfo.zero sources m |> Tuple.first |> set s |> docSetState


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap _ =
    logAction "wrap"


docShowTable : TableId -> ElmBook.Msg state
docShowTable _ =
    logAction "showTable"


docShowTableRow : DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ElmBook.Msg state
docShowTableRow _ _ _ _ =
    logAction "showTableRow"


docOpenNotes : TableId -> Maybe ColumnPath -> ElmBook.Msg state
docOpenNotes _ _ =
    logAction "openNotes"

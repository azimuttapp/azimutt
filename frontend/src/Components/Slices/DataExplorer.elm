module Components.Slices.DataExplorer exposing (DataExplorerDisplay(..), DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SharedDocState, VisualEditor, doc, docInit, init, update, view)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.DataExplorerDetails as DataExplorerDetails
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, input, label, nav, option, p, select, table, td, text, textarea, tr)
import Html.Attributes exposing (autofocus, class, disabled, for, id, name, placeholder, selected, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned exposing (Ned)
import Libs.Tailwind as Tw exposing (TwClass)
import Models.DbSource as DbSource exposing (DbSource)
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Services.Lenses exposing (mapDetailsCmd, mapFilters, mapResultsCmd, mapVisualEditor, setOperation, setOperator, setValue)
import Services.QueryBuilder as QueryBuilder



-- TODO:
--  - shorten uuid to its first component in results
--  - pin a column and replace the fk by it
--  - add search within results (left of 3 dots)
--  - ERD data exploration: show a row in ERD (from the sidebar) and allow to explore data relations
--  - Add filter button on results which can change editor (visual or query) and allow to trigger a new query
--  - Incoming rows in the side bar (and results?)
--  - handle time better, remove all Time.zero not in doc


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
    QueryBuilder.TableQuery


type alias QueryEditor =
    String



-- TODO type alias SavedQuery =
--    { name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId }


type Msg
    = OpenExplorer (Maybe SourceId) (Maybe String)
    | CloseExplorer
    | UpdateExplorerDisplay (Maybe DataExplorerDisplay)
    | UpdateTab DataExplorerTab
    | UpdateSource (Maybe DbSource)
    | UpdateTable (Maybe TableId)
    | AddFilter Table ColumnPath
    | UpdateFilterOperator Int QueryBuilder.FilterOperator
    | UpdateFilterOperation Int QueryBuilder.FilterOperation
    | UpdateFilterValue Int String
    | DeleteFilter Int
    | UpdateQuery String
    | RunQuery DbSource String
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


update : List Source -> Msg -> Model -> ( Model, Cmd msg )
update sources msg model =
    case msg of
        OpenExplorer source query ->
            let
                dbSources : List DbSource
                dbSources =
                    sources |> List.filterMap DbSource.fromSource
            in
            ( { model
                | display = Just BottomDisplay
                , activeTab = query |> Maybe.mapOrElse (\_ -> QueryEditorTab) model.activeTab
                , source =
                    source
                        |> Maybe.andThen (\id -> dbSources |> List.find (\s -> s.id == id))
                        |> Maybe.orElse model.source
                        |> Maybe.orElse (dbSources |> List.head)
                , queryEditor = query |> Maybe.withDefault model.queryEditor
              }
              -- TODO: run query if present with source
            , Cmd.none
            )

        CloseExplorer ->
            ( { model | display = Nothing }, Cmd.none )

        UpdateExplorerDisplay d ->
            ( { model | display = d }, Cmd.none )

        UpdateTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        UpdateSource source ->
            ( { model | source = source, visualEditor = { table = Nothing, filters = [] } }, Cmd.none )

        UpdateTable table ->
            ( { model | visualEditor = { table = table, filters = [] } }, Cmd.none )

        AddFilter table path ->
            ( table |> Table.getColumn path |> Maybe.mapOrElse (\col -> model |> mapVisualEditor (mapFilters (List.add { operator = QueryBuilder.OpAnd, column = path, kind = col.kind, nullable = col.nullable, operation = QueryBuilder.OpEqual, value = "" }))) model, Cmd.none )

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
            { model | resultsSeq = model.resultsSeq + 1 } |> mapResultsCmd (List.prependCmd (DataExplorerQuery.init model.resultsSeq (DbSource.toInfo source) (query |> QueryBuilder.limitResults source.db.kind)))

        DeleteQuery id ->
            ( { model | results = model.results |> List.filter (\r -> r.id /= id) }, Cmd.none )

        QueryMsg id m ->
            --model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update (QueryMsg id >> wrap) m))
            model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update m))

        OpenDetails source query ->
            { model | detailsSeq = model.detailsSeq + 1 } |> mapDetailsCmd (List.prependCmd (DataExplorerDetails.init model.detailsSeq source query))

        CloseDetails id ->
            ( { model | details = model.details |> List.removeBy .id id }, Cmd.none )

        DetailsMsg id m ->
            --model |> mapDetailsCmd (List.mapByCmd .id id (DataExplorerDetails.update (DetailsMsg id >> wrap) m))
            model |> mapDetailsCmd (List.mapByCmd .id id (DataExplorerDetails.update m))



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> String -> HtmlId -> SchemaName -> HtmlId -> List Source -> Model -> DataExplorerDisplay -> Html msg
view wrap toggleDropdown navbarHeight openedDropdown defaultSchema htmlId sources model display =
    div [ class "h-full flex" ]
        [ div [ class "basis-1/3 flex-1 overflow-y-auto flex flex-col border-r" ]
            -- TODO: put header on the whole width
            [ viewHeader wrap model.activeTab display
            , viewSources wrap (htmlId ++ "-sources") sources model.source
            , case model.activeTab of
                VisualEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewVisualExplorer wrap defaultSchema (htmlId ++ "-visual-editor") s model.visualEditor) (div [] [])

                QueryEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewQueryEditor wrap (htmlId ++ "-query-editor") s model.queryEditor) (div [] [])
            ]
        , div [ class "basis-2/3 flex-1 overflow-y-auto bg-gray-50 pb-28" ]
            [ viewResults wrap toggleDropdown (\s q -> OpenDetails s q |> wrap) openedDropdown defaultSchema sources (htmlId ++ "-results") model.results ]
        , viewDetails wrap (\s q -> OpenDetails s q |> wrap) navbarHeight defaultSchema sources (htmlId ++ "-details") model.details
        ]


viewHeader : (Msg -> msg) -> DataExplorerTab -> DataExplorerDisplay -> Html msg
viewHeader wrap activeTab display =
    div [ class "px-3 flex justify-between border-b border-gray-200" ]
        [ div [ class "sm:flex sm:items-baseline" ]
            [ h3 [ class "text-base font-semibold leading-6 text-gray-900" ] [ text "Data explorer" ]
            , div [ class "ml-6 mt-0" ]
                [ nav [ class "flex space-x-6" ]
                    ([ VisualEditorTab, QueryEditorTab ] |> List.map (viewHeaderTab wrap activeTab))
                ]
            ]
        , div [ class "py-2 flex flex-shrink-0 self-center" ]
            [ case display of
                FullScreenDisplay ->
                    button [ onClick (Just BottomDisplay |> UpdateExplorerDisplay |> wrap), title "minimize", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                        [ Icon.solid Icon.ChevronDoubleDown "" ]

                BottomDisplay ->
                    button [ onClick (Just FullScreenDisplay |> UpdateExplorerDisplay |> wrap), title "maximize", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                        [ Icon.solid Icon.ChevronDoubleUp "" ]
            , button [ onClick (wrap CloseExplorer), title "close", class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
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
                    [ p [] [ text "Azimutt is able to query your database if you add a source with a database url." ]
                    , p [] [ text "To access this, open settings (top right cog), click on 'add source' and fill your connection." ]
                    , p []
                        [ text "Local databases are accessible with "
                        , extLink "https://www.npmjs.com/package/azimutt" [ class "link" ] [ text "Azimutt CLI" ]
                        , text " ("
                        , Badge.basic Tw.blue [] [ text "npx azimutt gateway" ] |> Tooltip.t "Starts the Azimutt Gateway on your computer to access local databases."
                        , text ")."
                        ]
                    ]
                ]

        _ :: [] ->
            -- TODO: if source is not selected, select it
            div [] []

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


viewVisualExplorerFilterShow : (Msg -> msg) -> HtmlId -> List QueryBuilder.TableFilter -> Html msg
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
                                            , onInput (QueryBuilder.stringToOperator >> Maybe.withDefault QueryBuilder.OpAnd >> UpdateFilterOperator i >> wrap)
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
                                            , value f.value
                                            , onInput (UpdateFilterValue i >> wrap)
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


viewVisualExplorerSubmit : (Msg -> msg) -> DbSource -> QueryBuilder.TableQuery -> Html msg
viewVisualExplorerSubmit wrap source model =
    let
        query : String
        query =
            model |> QueryBuilder.filterTable source.db.kind
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


viewResults : (Msg -> msg) -> (HtmlId -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> HtmlId -> SchemaName -> List Source -> HtmlId -> List DataExplorerQuery.Model -> Html msg
viewResults wrap toggleDropdown openRow openedDropdown defaultSchema sources htmlId results =
    if results |> List.isEmpty then
        div [ class "m-3 p-12 block rounded-lg border-2 border-dashed border-gray-200 text-gray-300 text-center text-sm font-semibold" ] [ text "Query results" ]

    else
        div []
            (results
                |> List.map
                    (\r ->
                        div [ class "m-3 px-3 py-2 rounded-md bg-white shadow" ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) toggleDropdown openRow (DeleteQuery r.id |> wrap) openedDropdown defaultSchema sources (htmlId ++ "-" ++ String.fromInt r.id) r
                            ]
                    )
            )


viewDetails : (Msg -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> String -> SchemaName -> List Source -> HtmlId -> List DataExplorerDetails.Model -> Html msg
viewDetails wrap openRow navbarHeight defaultSchema sources htmlId details =
    div []
        (details
            |> List.indexedMap (\i m -> DataExplorerDetails.view (DetailsMsg m.id >> wrap) (CloseDetails m.id |> wrap) (openRow m.source) navbarHeight defaultSchema sources (htmlId ++ "-" ++ String.fromInt m.id) (Just i) m)
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



-- DOC HELPERS


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set sources =
    ( name, \{ dataExplorerDocState } -> dataExplorerDocState |> (\s -> div [ style "height" "500px" ] [ view (docUpdate s get set sources) (docToggleDropdown s) "0px" s.openedDropdown "public" "data-explorer" sources (get s) (get s |> .display |> Maybe.withDefault BottomDisplay) ]) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set sources m =
    s |> get |> update sources m |> Tuple.first |> set s |> docSetState


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDocState = state })

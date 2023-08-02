module Components.Slices.DataExplorer exposing (DataExplorerDisplay(..), DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SharedDocState, VisualEditor, doc, docInit, init, update, view)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.DataExplorerRow as DataExplorerRow
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, input, label, nav, option, p, select, table, td, text, textarea, tr)
import Html.Attributes exposing (autofocus, class, disabled, for, id, name, placeholder, selected, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Dict as Dict
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Time as Time
import Models.DatabaseQueryResults exposing (DatabaseQueryResults)
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SourceInfo exposing (SourceInfo)
import Ports
import Services.Lenses exposing (mapDetailsCmd, mapFilters, mapResultsCmd, mapVisualEditor, setOperation, setOperator, setValue)
import Services.QueryBuilder as QueryBuilder
import Time



-- TODO:
--  - ERD data exploration: show a row in ERD (from the sidebar) and allow to explore data relations
--  - Add filter button on results which can change editor (visual or query) and allow to trigger a new query
--  - Linked rows in the side bar
--  - handle time better, remove all Time.zero not in doc


type alias Model =
    { display : Maybe DataExplorerDisplay
    , activeTab : DataExplorerTab
    , source : Maybe ( Source, DatabaseUrl )
    , visualEditor : VisualEditor
    , queryEditor : QueryEditor
    , resultsSeq : Int
    , results : List DataExplorerQuery.Model
    , details : List DataExplorerRow.Model
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
    | UpdateSource (Maybe ( Source, DatabaseUrl ))
    | UpdateTable (Maybe TableId)
    | AddFilter Table ColumnPath
    | UpdateFilterOperator Int QueryBuilder.FilterOperator
    | UpdateFilterOperation Int QueryBuilder.FilterOperation
    | UpdateFilterValue Int String
    | DeleteFilter Int
    | UpdateQuery String
    | RunQuery String
    | GotQueryResults String (Result String DatabaseQueryResults) Time.Posix Time.Posix
    | DeleteQuery DataExplorerQuery.QueryId
    | QueryMsg DataExplorerQuery.QueryId DataExplorerQuery.Msg
    | OpenDetails SourceInfo QueryBuilder.RowQuery
    | CloseDetails Int
    | DetailsMsg Int DataExplorerRow.Msg



-- INIT


init : Model
init =
    { display = Nothing
    , activeTab = VisualEditorTab
    , source = Nothing
    , visualEditor = { table = Nothing, filters = [] }
    , queryEditor = ""
    , resultsSeq = 1
    , results = []
    , details = []
    }



-- UPDATE


update : (Msg -> msg) -> List Source -> Msg -> Model -> ( Model, Cmd msg )
update wrap sources msg model =
    case msg of
        OpenExplorer source query ->
            let
                dbSources : List ( Source, DatabaseUrl )
                dbSources =
                    sources |> List.filterMap withUrl
            in
            ( { model
                | display = Just BottomDisplay
                , activeTab = query |> Maybe.mapOrElse (\_ -> QueryEditorTab) model.activeTab
                , source =
                    source
                        |> Maybe.andThen (\id -> dbSources |> List.find (\( s, _ ) -> s.id == id))
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

        RunQuery query ->
            model.source
                |> Maybe.map
                    (\( source, url ) ->
                        ( { model | resultsSeq = model.resultsSeq + 1, results = DataExplorerQuery.init model.resultsSeq (Source.toInfo source) query :: model.results }
                          -- TODO: add tracking with editor source (visual or query)
                        , Ports.runDatabaseQuery ("data-explorer-query/" ++ String.fromInt model.resultsSeq) url query
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        GotQueryResults context result started finished ->
            case context |> String.split "/" of
                "data-explorer-query" :: idStr :: [] ->
                    idStr
                        |> String.toInt
                        |> Maybe.map (\id -> model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update (QueryMsg id >> wrap) (DataExplorerQuery.GotResult result started finished))))
                        |> Maybe.withDefault ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DeleteQuery id ->
            ( { model | results = model.results |> List.filter (\r -> r.id /= id) }, Cmd.none )

        QueryMsg id m ->
            model |> mapResultsCmd (List.mapByCmd .id id (DataExplorerQuery.update (QueryMsg id >> wrap) m))

        OpenDetails source query ->
            -- FIXME: trigger query to get data row
            -- FIXME: get time correctly
            ( { model | details = { source = source, query = query, startedAt = Time.zero, state = DataExplorerRow.StateLoading } :: model.details }, Cmd.none )

        CloseDetails index ->
            ( { model | details = model.details |> List.removeAt index }, Cmd.none )

        DetailsMsg index m ->
            model |> mapDetailsCmd (List.mapAtCmd index (DataExplorerRow.update (DetailsMsg index >> wrap) m))



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> HtmlId -> SchemaName -> HtmlId -> List Source -> Model -> DataExplorerDisplay -> Html msg
view wrap openDropdown openedDropdown defaultSchema htmlId sources model display =
    div [ class "h-full flex" ]
        -- TODO: change width: 1/3 for editor and 2/3 for results
        [ div [ class "flex-1 overflow-y-auto flex flex-col border-r" ]
            -- TODO: put header on the whole width
            [ viewHeader wrap model.activeTab display
            , viewSources wrap (htmlId ++ "-sources") sources model.source
            , case model.activeTab of
                VisualEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewVisualExplorer wrap defaultSchema (htmlId ++ "-visual-editor") s model.visualEditor) (div [] [])

                QueryEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewQueryEditor wrap (htmlId ++ "-query-editor") s model.queryEditor) (div [] [])
            ]
        , div [ class "flex-1 overflow-y-auto bg-gray-50 pb-28" ]
            [ viewResults wrap openDropdown (\s q -> OpenDetails s q |> wrap) openedDropdown defaultSchema (htmlId ++ "-results") model.results ]
        , viewDetails wrap defaultSchema (htmlId ++ "-details") model.details
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


viewSources : (Msg -> msg) -> HtmlId -> List Source -> Maybe ( Source, DatabaseUrl ) -> Html msg
viewSources wrap htmlId sources selectedSource =
    let
        sourceInput : HtmlId
        sourceInput =
            htmlId ++ "-input"
    in
    case sources |> List.filterMap withUrl of
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
                    , onInput (SourceId.fromString >> Maybe.andThen (\id -> dbSources |> List.findBy (Tuple.first >> .id) id) >> UpdateSource >> wrap)
                    , class "mt-3 mx-3 block rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    ]
                    (option [] [ text "-- select a source" ] :: (dbSources |> List.map (\( s, _ ) -> option [ value (SourceId.toString s.id), selected (selectedSource |> Maybe.hasBy (Tuple.first >> .id) s.id) ] [ text s.name ])))
                ]


viewVisualExplorer : (Msg -> msg) -> SchemaName -> HtmlId -> ( Source, DatabaseUrl ) -> VisualEditor -> Html msg
viewVisualExplorer wrap defaultSchema htmlId ( source, dbUrl ) model =
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
            , viewVisualExplorerSubmit wrap (DatabaseKind.fromUrl dbUrl) model
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


viewVisualExplorerSubmit : (Msg -> msg) -> DatabaseKind -> QueryBuilder.TableQuery -> Html msg
viewVisualExplorerSubmit wrap db model =
    let
        query : String
        query =
            QueryBuilder.filterTable db model
    in
    div [ class "mt-3 flex items-center justify-end" ]
        [ button [ type_ "button", onClick (query |> RunQuery |> wrap), disabled (query == ""), class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300" ]
            [ text "Fetch data" ]
        ]


viewQueryEditor : (Msg -> msg) -> HtmlId -> ( Source, DatabaseUrl ) -> QueryEditor -> Html msg
viewQueryEditor wrap htmlId ( source, _ ) model =
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
                , onClick (model |> RunQuery |> wrap)
                , disabled (model == "")
                , class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                ]
                [ text "Run query" ]
            ]
        ]


viewResults : (Msg -> msg) -> (HtmlId -> msg) -> (SourceInfo -> QueryBuilder.RowQuery -> msg) -> HtmlId -> SchemaName -> HtmlId -> List DataExplorerQuery.Model -> Html msg
viewResults wrap openDropdown openRow openedDropdown defaultSchema htmlId results =
    if results |> List.isEmpty then
        div [ class "m-3 p-12 block rounded-lg border-2 border-dashed border-gray-200 text-gray-300 text-center text-sm font-semibold" ] [ text "Query results" ]

    else
        div []
            (results
                |> List.map
                    (\r ->
                        div [ class "m-3 px-3 py-2 rounded-md bg-white shadow" ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) openDropdown openRow (DeleteQuery r.id |> wrap) openedDropdown defaultSchema docSources (htmlId ++ "-" ++ String.fromInt r.id) r
                            ]
                    )
            )


viewDetails : (Msg -> msg) -> SchemaName -> HtmlId -> List DataExplorerRow.Model -> Html msg
viewDetails wrap defaultSchema htmlId details =
    div []
        (details
            |> List.indexedMap (\i m -> DataExplorerRow.view (DetailsMsg i >> wrap) (CloseDetails i |> wrap) defaultSchema (htmlId ++ "-" ++ String.fromInt i) (Just i) m)
            |> List.reverse
        )



-- HELPERS


withUrl : Source -> Maybe ( Source, DatabaseUrl )
withUrl source =
    source |> Source.databaseUrl |> Maybe.map (\url -> ( source, url ))



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, model : Model, oneSource : Model, noSource : Model }


docInit : DocState
docInit =
    { openedDropdown = ""
    , model = { init | source = withUrl docSource1, resultsSeq = List.length docQueryResults + 1, results = docQueryResults }
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
      , source = Source.toInfo docSource1
      , query = DataExplorerQuery.docCityQuery
      , state = DataExplorerQuery.docCitySuccess
      }
    , { id = 2
      , source = Source.toInfo docSource1
      , query = DataExplorerQuery.docProjectsQuery
      , state = DataExplorerQuery.docProjectsSuccess
      }
    , { id = 1
      , source = Source.toInfo docSource1
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


docVisualEditor : QueryBuilder.TableQuery
docVisualEditor =
    { table = Just ( "public", "users" )
    , filters =
        [ { operator = QueryBuilder.OpAnd, column = Nel "name" [], kind = "varchar", nullable = False, operation = QueryBuilder.OpEqual, value = "Kabul" }
        , { operator = QueryBuilder.OpOr, column = Nel "name" [], kind = "varchar", nullable = False, operation = QueryBuilder.OpIsNull, value = "" }
        ]
    }



-- DOC HELPERS


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set sources =
    ( name, \{ dataExplorerDocState } -> dataExplorerDocState |> (\s -> div [ style "height" "500px" ] [ view (docUpdate s get set sources) (docOpenDropdown s) s.openedDropdown "public" "data-explorer" sources (get s) (get s |> .display |> Maybe.withDefault BottomDisplay) ]) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set sources m =
    s |> get |> update docWrap sources m |> Tuple.first |> set s |> docSetState


docOpenDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docOpenDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"

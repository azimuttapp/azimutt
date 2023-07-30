module Components.Slices.DataExplorer exposing (DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SavedQuery, SharedDocState, VisualEditor, doc, docInit, init)

import Array
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
import Libs.Bool as Bool
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
import Libs.Task as T
import Libs.Time as Time
import Models.Project.Column as Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.UserId exposing (UserId)
import Services.Lenses exposing (mapFilters, mapVisualEditor, setOperation, setOperator, setValue)
import Services.QueryBuilder as QueryBuilder
import Task
import Time



-- TODO:
--  - Simple exploration vs SQL editor on the left
--  - List of Query Results on the right
--  - Row details in the side bar
--  - Linked rows in the side bar
--  - stackable side bars


type alias Model =
    { activeTab : DataExplorerTab
    , source : Maybe ( Source, DatabaseUrl )
    , visualEditor : VisualEditor
    , queryEditor : QueryEditor
    , savedQueries : List SavedQuery
    , resultsSeq : Int
    , results : List DataExplorerQuery.Model
    , details : List DataExplorerRow.Model
    , fullSize : Bool
    }


type DataExplorerTab
    = VisualEditorTab
    | QueryEditorTab


type alias VisualEditor =
    QueryBuilder.TableQuery


type alias QueryEditor =
    String


type alias SavedQuery =
    { name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId }


type Msg
    = Noop
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
    | TimedQuery String Time.Posix
    | QueryMsg DataExplorerQuery.QueryId DataExplorerQuery.Msg
    | DeleteQuery DataExplorerQuery.QueryId
    | Close
    | ToggleFullSize



-- INIT


init : List Source -> List SavedQuery -> Maybe SourceId -> Maybe String -> Model
init sources savedQueries source query =
    { activeTab = query |> Maybe.mapOrElse (\_ -> QueryEditorTab) VisualEditorTab
    , source = selectSource sources source
    , visualEditor = { table = Nothing, filters = [] }
    , queryEditor = query |> Maybe.withDefault ""
    , savedQueries = savedQueries
    , resultsSeq = 1
    , results = []
    , details = []
    , fullSize = False
    }


selectSource : List Source -> Maybe SourceId -> Maybe ( Source, DatabaseUrl )
selectSource sources source =
    let
        dbSources : List ( Source, DatabaseUrl )
        dbSources =
            sources |> List.filterMap withUrl
    in
    source |> Maybe.andThen (\id -> dbSources |> List.find (\( s, _ ) -> s.id == id)) |> Maybe.orElse (dbSources |> List.head)



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
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
            ( model, Time.now |> Task.perform (TimedQuery query >> wrap) )

        TimedQuery query now ->
            -- TODO: launch query with Cmd
            model.source
                |> Maybe.map
                    (\( source, _ ) ->
                        let
                            result : DataExplorerQuery.Model
                            result =
                                DataExplorerQuery.init model.resultsSeq (Source.toInfo source) query now
                        in
                        ( { model | resultsSeq = model.resultsSeq + 1, results = result :: model.results }, Cmd.none )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        DeleteQuery id ->
            ( { model | results = model.results |> List.filter (\r -> r.id /= id) }, Cmd.none )

        QueryMsg id m ->
            let
                ( results, cmds ) =
                    model.results
                        |> List.map
                            (\r ->
                                if r.id == id then
                                    DataExplorerQuery.update (QueryMsg r.id >> wrap) m r

                                else
                                    ( r, Cmd.none )
                            )
                        |> List.unzip
            in
            ( { model | results = results }, Cmd.batch cmds )

        _ ->
            ( model, Noop |> wrap |> T.send )



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> Time.Posix -> HtmlId -> SchemaName -> HtmlId -> List Source -> Model -> Html msg
view wrap openDropdown now openedDropdown defaultSchema htmlId sources model =
    div [ class "h-full flex" ]
        [ div [ class "flex-1 overflow-y-auto flex flex-col border-r" ]
            -- TODO: put header on the whole width
            [ viewHeader wrap model.activeTab model.fullSize
            , viewSources wrap (htmlId ++ "-sources") sources model.source
            , case model.activeTab of
                VisualEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewVisualExplorer wrap defaultSchema (htmlId ++ "-visual-editor") s model.visualEditor) (div [] [])

                QueryEditorTab ->
                    model.source |> Maybe.mapOrElse (\s -> viewQueryEditor wrap (htmlId ++ "-query-editor") s model.queryEditor) (div [] [])
            ]
        , div [ class "flex-1 overflow-y-auto bg-gray-50 pb-28" ]
            [ viewResults wrap openDropdown now openedDropdown (htmlId ++ "-results") model.results ]
        ]


viewHeader : (Msg -> msg) -> DataExplorerTab -> Bool -> Html msg
viewHeader wrap activeTab sizeFull =
    div [ class "px-3 flex justify-between border-b border-gray-200" ]
        [ div [ class "sm:flex sm:items-baseline" ]
            [ h3 [ class "text-base font-semibold leading-6 text-gray-900" ] [ text "Data explorer" ]
            , div [ class "ml-6 mt-0" ]
                [ nav [ class "flex space-x-6" ]
                    ([ VisualEditorTab, QueryEditorTab ] |> List.map (viewHeaderTab wrap activeTab))
                ]
            ]
        , div [ class "pb-2 flex flex-shrink-0 self-center" ]
            [ button [ onClick (wrap ToggleFullSize), title (Bool.cond sizeFull "minimize" "maximize"), class "rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                [ if sizeFull then
                    Icon.solid Icon.ChevronDoubleDown ""

                  else
                    Icon.solid Icon.ChevronDoubleUp ""
                ]
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
    button [ type_ "button", onClick (UpdateTab tab |> wrap), css [ style, "whitespace-nowrap border-b-2 px-1 pb-2 text-sm font-medium" ] ]
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
            div [] []

        dbSources ->
            div []
                [ select
                    [ id sourceInput
                    , name sourceInput
                    , onInput (SourceId.fromString >> Maybe.andThen (\id -> dbSources |> List.findBy (Tuple.first >> .id) id) >> UpdateSource >> wrap)
                    , class "mt-3 mx-3 block rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    ]
                    (dbSources |> List.map (\( s, _ ) -> option [ value (SourceId.toString s.id), selected (selectedSource |> Maybe.hasBy (Tuple.first >> .id) s.id) ] [ text s.name ]))
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


viewResults : (Msg -> msg) -> (HtmlId -> msg) -> Time.Posix -> HtmlId -> HtmlId -> List DataExplorerQuery.Model -> Html msg
viewResults wrap openDropdown now openedDropdown htmlId results =
    if results |> List.isEmpty then
        div [ class "m-3 p-12 block rounded-lg border-2 border-dashed border-gray-200 text-gray-300 text-center text-sm font-semibold" ] [ text "Query results" ]

    else
        div []
            (results
                |> List.map
                    (\r ->
                        div [ class "m-3 px-3 py-2 rounded-md bg-white shadow" ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) openDropdown (DeleteQuery r.id |> wrap) now openedDropdown (htmlId ++ "-" ++ String.fromInt r.id) r
                            ]
                    )
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
    , model = init docSources [] Nothing Nothing |> (\m -> { m | resultsSeq = 3, results = docQueryResults })
    , oneSource = init (docSources |> List.take 1) [] Nothing Nothing
    , noSource = init [] [] Nothing Nothing
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
    [ { id = 2
      , source = Source.toInfo docSource1
      , query = "SELECT * FROM city;"
      , executions = Nel { startedAt = Time.zero, state = DataExplorerQuery.StateSuccess DataExplorerQuery.docSuccessState1 } []
      }
    , { id = 1
      , source = Source.toInfo docSource1
      , query = "SELECT * FROM users;"
      , executions = Nel { startedAt = Time.zero, state = DataExplorerQuery.StateSuccess DataExplorerQuery.docSuccessState2 } []
      }
    ]


docSources : List Source
docSources =
    [ docSource1, docSource2, docSource3 ]


docSource1 : Source
docSource1 =
    { id = SourceId.zero
    , name = "azimutt_dev"
    , kind = DatabaseConnection "postgresql://postgres:postgres@localhost:5432/azimutt_dev"
    , content = Array.empty
    , tables =
        [ docTable "public" "users" [ ( "id", "int", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "provider", "varchar", True ), ( "provider_uid", "varchar", True ), ( "avatar", "varchar", False ), ( "github_username", "varchar", True ), ( "twitter_username", "varchar", True ), ( "is_admin", "boolean", False ), ( "hashed_password", "varchar", True ), ( "last_signin", "timestamp", False ), ( "created_at", "timestamp", False ), ( "updated_at", "timestamp", False ), ( "confirmed_at", "timestamp", True ), ( "deleted_at", "timestamp", True ), ( "data", "json", False ), ( "onboarding", "json", False ), ( "provider_data", "json", True ), ( "tags", "varchar[]", False ) ]
        , docTable "public" "cities" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "country_code", "varchar", False ), ( "district", "varchar", False ), ( "population", "int", False ) ]
        ]
            |> Dict.fromListMap .id
    , relations = []
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


docSource2 : Source
docSource2 =
    { docSource1
        | id = SourceId.one
        , name = "azimutt_prod"
        , tables =
            [ docTable "public" "users" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "created_at", "timestamp", False ) ]
            , Table.new "" "key_values" False docKeyValueColumns Nothing [] [] [] Nothing []
            ]
                |> Dict.fromListMap .id
    }


docSource3 : Source
docSource3 =
    { docSource1 | id = SourceId.two, name = "new", tables = Dict.empty }


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


docTable : SchemaName -> TableName -> List ( ColumnName, ColumnType, Bool ) -> Table
docTable schema name columns =
    { id = ( schema, name )
    , schema = schema
    , name = name
    , view = False
    , columns = columns |> List.indexedMap (\i ( col, kind, nullable ) -> { index = i, name = col, kind = kind, nullable = nullable, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }) |> Dict.fromListMap .name
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , origins = []
    }



-- DOC HELPERS


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> List Source -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set sources =
    ( name, \{ dataExplorerDocState } -> dataExplorerDocState |> (\s -> div [ style "height" "500px" ] [ view (docUpdate s get set) (docOpenDropdown s) Time.zero s.openedDropdown "public" "data-explorer" sources (get s) ]) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docWrap m |> Tuple.first |> set s |> docSetState


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

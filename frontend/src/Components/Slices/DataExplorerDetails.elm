module Components.Slices.DataExplorerDetails exposing (DocState, FailureState, Id, Model, Msg(..), SharedDocState, State(..), SuccessState, doc, docInit, init, update, view)

import Components.Atoms.Icon as Icon
import Components.Atoms.Icons as Icons
import Components.Slices.DataExplorerValue as DataExplorerValue
import DataSources.DbMiner.DbQuery as DbQuery
import DataSources.DbMiner.DbTypes exposing (RowQuery)
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dt, h2, p, pre, span, text)
import Html.Attributes exposing (class, id, style, title, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaLabelledby, ariaModal, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel exposing (Nel)
import Libs.Result as Result
import Libs.Set as Set
import Libs.Tailwind as Tw
import Libs.Time as Time
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.DbSourceInfoWithUrl as DbSourceInfoWithUrl exposing (DbSourceInfoWithUrl)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project as Project
import Models.Project.Column exposing (Column)
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Comment exposing (Comment)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableRow as TableRow
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.QueryResult as QueryResult exposing (QueryResult, QueryResultColumn, QueryResultRow, QueryResultSuccess)
import Models.SqlQuery exposing (SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps as ErdTableProps
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapState)
import Set exposing (Set)
import Time
import Track


type alias Model =
    { id : Id
    , source : DbSourceInfoWithUrl
    , query : RowQuery
    , state : State
    , expanded : Set ColumnName
    }


type alias Id =
    Int


type State
    = StateLoading
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias FailureState =
    { error : String, startedAt : Time.Posix, failedAt : Time.Posix }


type alias SuccessState =
    { columns : List QueryResultColumn
    , values : QueryResultRow
    , startedAt : Time.Posix
    , succeededAt : Time.Posix
    }


type Msg
    = GotResult QueryResult
    | ExpandValue ColumnPathStr



-- INIT


dbPrefix : String
dbPrefix =
    "data-explorer-details"


init : ProjectInfo -> Id -> DbSourceInfoWithUrl -> RowQuery -> ( Model, Extra msg )
init project id source query =
    let
        sqlQuery : SqlQueryOrigin
        sqlQuery =
            DbQuery.findRow source.db.kind query
    in
    ( { id = id, source = source, query = query, state = StateLoading, expanded = Set.empty }
    , Extra.cmdL [ Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt id) source.id source.db.url sqlQuery, Track.dataExplorerDetailsOpened source sqlQuery project ]
    )


initFailure : Time.Posix -> Time.Posix -> String -> State
initFailure started finished err =
    StateFailure { error = err, startedAt = started, failedAt = finished }


initSuccess : Time.Posix -> Time.Posix -> QueryResultSuccess -> State
initSuccess started finished res =
    StateSuccess
        { columns = res.columns
        , values = res.rows |> List.head |> Maybe.withDefault Dict.empty
        , startedAt = started
        , succeededAt = finished
        }



-- UPDATE


update : ProjectInfo -> Msg -> Model -> ( Model, Extra msg )
update project msg model =
    case msg of
        GotResult res ->
            ( model |> mapState (\_ -> res.result |> Result.fold (initFailure res.started res.finished) (initSuccess res.started res.finished)), Track.dataExplorerDetailsResult res project |> Extra.cmd )

        ExpandValue column ->
            ( { model | expanded = model.expanded |> Set.toggle column }, Extra.none )



-- VIEW


view : (Msg -> msg) -> msg -> (TableId -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> String -> Bool -> Erd -> HtmlId -> Maybe Int -> Model -> Html msg
view wrap close showTable showTableRow openRowDetails openNotes navbarHeight hasFullScreen erd htmlId openDepth model =
    let
        titleId : HtmlId
        titleId =
            htmlId ++ "-title"

        zIndex : String
        zIndex =
            if hasFullScreen then
                "z-max"

            else
                openDepth |> Maybe.andThen (\i -> [ "z-16", "z-15", "z-14", "z-13", "z-12", "z-11" ] |> List.get i) |> Maybe.withDefault "z-10"

        top : String
        top =
            if hasFullScreen then
                "0px"

            else
                navbarHeight
    in
    div
        [ ariaLabelledby titleId
        , role "dialog"
        , ariaModal True
        , css [ "relative", zIndex ]
        ]
        [ div [ class "fixed inset-0 overflow-hidden pointer-events-none" ]
            [ div [ class "absolute inset-0 overflow-hidden" ]
                [ div [ class "pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10", style "top" top ]
                    [ {-
                         TODO: fix in and out animations
                         Slide-over panel, show/hide based on slide-over state.

                         Entering: "transform transition ease-in-out duration-500 sm:duration-700"
                           From: "translate-x-full"
                           To: "translate-x-0"
                         Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
                           From: "translate-x-0"
                           To: "translate-x-full"
                      -}
                      div
                        [ css
                            [ "pointer-events-auto w-screen max-w-md transform transition ease-in-out duration-200 sm:duration-400"
                            , openDepth |> Maybe.andThen (\i -> [ "translate-x-0", "-translate-x-6", "-translate-x-12", "-translate-x-16", "-translate-x-20" ] |> List.get i) |> Maybe.withDefault "translate-x-full"
                            ]
                        ]
                        [ viewSlideOverContent wrap close showTable showTableRow openRowDetails openNotes erd titleId model
                        ]
                    ]
                ]
            ]
        ]


viewSlideOverContent : (Msg -> msg) -> msg -> (TableId -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> Erd -> HtmlId -> Model -> Html msg
viewSlideOverContent wrap close showTable showTableRow openRowDetails openNotes erd titleId model =
    let
        table : Maybe Table
        table =
            erd.sources |> List.findBy .id model.source.id |> Maybe.andThen (Source.getTableI model.query.table)

        erdTable : Maybe ErdTable
        erdTable =
            erd.tables |> TableId.dictGetI model.query.table

        tableMeta : Maybe TableMeta
        tableMeta =
            erd.metadata |> TableId.dictGetI model.query.table

        color : Tw.Color
        color =
            erd |> Erd.currentLayout |> .tables |> List.findBy .id model.query.table |> Maybe.mapOrElse (.props >> .color) (ErdTableProps.computeColor model.query.table)

        tableLabel : String
        tableLabel =
            TableId.show erd.settings.defaultSchema model.query.table

        panelTitle : String
        panelTitle =
            tableLabel ++ ": " ++ (model.query.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString) |> String.join "/")
    in
    div [ class "flex h-full flex-col overflow-y-auto bg-white shadow-xl" ]
        [ div [ css [ Tw.bg_500 color, "p-6" ] ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ id titleId, title panelTitle, class "text-base font-semibold leading-6 text-white truncate" ]
                    [ button [ type_ "button", onClick (showTable model.query.table), title ("Show table: " ++ tableLabel), class "mr-1" ] [ Icon.solid Icon.Eye "w-4 h-4 inline" ]
                    , table |> Maybe.andThen .comment |> Maybe.mapOrElse (\c -> span [ title c.text, class "mr-1" ] [ Icon.outline Icons.comment "w-4 h-4 inline" ]) (text "")
                    , tableMeta |> Maybe.andThen .notes |> Maybe.mapOrElse (\n -> button [ type_ "button", onClick (openNotes model.query.table Nothing), title n, class "mr-1" ] [ Icon.outline Icons.notes "w-4 h-4 inline" ]) (text "")
                    , text panelTitle
                    ]
                , div [ class "ml-3 flex h-7 items-center" ]
                    [ button [ type_ "button", onClick close, css [ Tw.bg_500 color, Tw.text_200 color, "relative rounded-md hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2" ] ]
                        [ span [ class "absolute -inset-2.5" ] []
                        , span [ class "sr-only" ] [ text "Close panel" ]
                        , Icon.solid Icon.X "h-6 w-6"
                        ]
                    ]
                ]
            ]
        , div [ class "relative flex-1 pt-3 pb-6 px-6 space-y-3 overflow-y-auto" ]
            (case model.state of
                StateLoading ->
                    [ text "Loading... " ]

                StateFailure res ->
                    [ p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "Error" ]
                    , pre [ class "px-6 py-4 block text-sm whitespace-pre overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
                    ]

                StateSuccess res ->
                    [ div [ class "flex flex-wrap space-x-3" ]
                        [ button [ type_ "button", onClick (showTableRow model.query (res |> toRow |> Just) Nothing), class "inline-flex w-full flex-1 items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" ]
                            [ text "Add to layout" ]
                        ]
                    , div [ class "space-y-3" ]
                        ((res.columns |> QueryResult.buildColumnTargets erd model.source)
                            |> List.map
                                (\col ->
                                    let
                                        comment : Maybe String
                                        comment =
                                            (table |> Maybe.andThen (Table.getColumnI col.path) |> Maybe.andThen .comment |> Maybe.map .text)
                                                |> Maybe.orElse (erdTable |> Maybe.andThen (ErdTable.getColumnI col.path) |> Maybe.andThen .comment |> Maybe.map .text)

                                        meta : Maybe ColumnMeta
                                        meta =
                                            tableMeta |> Maybe.andThen (.columns >> Dict.get col.pathStr)
                                    in
                                    div []
                                        [ dt [ class "text-sm font-medium text-gray-500 sm:w-40 sm:flex-shrink-0" ]
                                            [ text (ColumnPath.show col.path)
                                            , comment |> Maybe.mapOrElse (\c -> span [ title c, class "ml-1 opacity-50" ] [ Icon.outline Icons.comment "w-3 h-3 inline" ]) (text "")
                                            , meta |> Maybe.andThen .notes |> Maybe.mapOrElse (\n -> button [ type_ "button", onClick (openNotes model.query.table (Just col.path)), title n, class "ml-1 opacity-50" ] [ Icon.outline Icons.notes "w-3 h-3 inline" ]) (text "")
                                            ]
                                        , dd [ class "text-sm text-gray-900 sm:col-span-2 overflow-hidden text-ellipsis" ]
                                            [ DataExplorerValue.view openRowDetails (ExpandValue col.pathStr |> wrap) erd.settings.defaultSchema False (model.expanded |> Set.member col.pathStr) (res.values |> Dict.get col.pathStr) col
                                            ]
                                        ]
                                )
                        )
                    ]
            )
        ]


toRow : SuccessState -> TableRow.SuccessState
toRow state =
    { columns = state.columns |> List.filterMap (\c -> state.values |> Dict.get c.pathStr |> Maybe.map (\v -> { path = c.path, pathStr = c.pathStr, value = v, linkedBy = Dict.empty }))
    , startedAt = state.startedAt
    , loadedAt = state.succeededAt
    }



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerDetailsDocState : DocState }


type alias DocState =
    { details : List Model }


docInit : DocState
docInit =
    { details = [] }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerDetails"
        |> Chapter.renderStatefulComponentList
            [ ( "app"
              , \{ dataExplorerDetailsDocState } ->
                    let
                        s : DocState
                        s =
                            dataExplorerDetailsDocState
                    in
                    div []
                        [ docButton "Open loading" (docOpen docModel s)
                        , docButton "Open failure" (docOpen { docModel | state = StateFailure docFailureState } s)
                        , docButton "Open success" (docOpen { docModel | state = StateSuccess docSuccessState } s)
                        , div []
                            (s.details
                                |> List.indexedMap
                                    (\i m ->
                                        div [ class "mt-1" ]
                                            [ view (docUpdate i s) (docClose i s) docShowTable docShowTableRow docOpenRowDetails docOpenNotes "0px" False docErd ("data-explorer-details-" ++ String.fromInt i) (Just i) m
                                            , docButton ("Close " ++ String.fromInt i) (docClose i s)
                                            ]
                                    )
                                |> List.reverse
                            )
                        ]
              )
            ]


docButton : String -> ElmBook.Msg (SharedDocState x) -> Html (ElmBook.Msg (SharedDocState x))
docButton name msg =
    button [ type_ "button", onClick msg, class "mr-3 rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" ] [ text name ]


docModel : Model
docModel =
    init ProjectInfo.zero 1 docSourceInfo { source = docSourceInfo.id, table = ( "public", "city" ), primaryKey = Nel { column = Nel "id" [], value = DbInt 1 } [] } |> Tuple.first


docErd : Erd
docErd =
    Project.create Nothing [] "Azimutt" (Source.aml "aml" Time.zero SourceId.zero) |> Erd.create


docSourceInfo : DbSourceInfoWithUrl
docSourceInfo =
    DbSourceInfoWithUrl.zero


docFailureState : FailureState
docFailureState =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", startedAt = Time.zero, failedAt = Time.zero }


docSuccessState : SuccessState
docSuccessState =
    { columns = [ "id", "name", "country_code", "district", "population" ] ++ (List.range 1 15 |> List.map (\i -> "col" ++ String.fromInt i)) |> List.map (docColumn "public" "city")
    , values = docCityColumnValues 1 "Kabul" "AFG" "Kabol" 1780000
    , startedAt = Time.zero
    , succeededAt = Time.zero
    }


docColumn : SchemaName -> TableName -> ColumnPathStr -> QueryResultColumn
docColumn schema table column =
    { path = ColumnPath.fromString column, pathStr = column, ref = Just { table = ( schema, table ), column = ColumnPath.fromString column } }


docCityColumnValues : Int -> String -> String -> String -> Int -> QueryResultRow
docCityColumnValues id name country_code district population =
    [ ( "id", DbInt id ), ( "name", DbString name ), ( "country_code", DbString country_code ), ( "district", DbString district ), ( "population", DbInt population ) ] ++ (List.range 1 15 |> List.map (\i -> ( "col" ++ String.fromInt i, DbString ("value" ++ String.fromInt i) ))) |> Dict.fromList



-- DOC HELPERS


docUpdate : Int -> DocState -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate i s msg =
    docSetState { s | details = s.details |> List.mapAt i (update ProjectInfo.zero msg >> Tuple.first) }


docOpen : Model -> DocState -> ElmBook.Msg (SharedDocState x)
docOpen m s =
    docSetState { s | details = m :: s.details }


docClose : Int -> DocState -> ElmBook.Msg (SharedDocState x)
docClose i s =
    docSetState { s | details = s.details |> List.removeAt i }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDetailsDocState = state })


docShowTable : TableId -> ElmBook.Msg state
docShowTable _ =
    logAction "showTable"


docShowTableRow : RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ElmBook.Msg state
docShowTableRow _ _ _ =
    logAction "showTableRow"


docOpenRowDetails : RowQuery -> ElmBook.Msg state
docOpenRowDetails _ =
    logAction "openRowDetails"


docOpenNotes : TableId -> Maybe ColumnPath -> ElmBook.Msg state
docOpenNotes _ _ =
    logAction "openNotes"

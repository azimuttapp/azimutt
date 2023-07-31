module Components.Slices.QueryPane exposing (DisplayMode, Model, Msg(..), doc, update, view)

import Array
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Conf
import Dict exposing (Dict)
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, label, option, p, pre, select, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (autofocus, class, classList, disabled, for, id, name, placeholder, rows, scope, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.Result as Result
import Libs.Tailwind as Tw
import Libs.Task as T
import Libs.Time as Time
import Models.DatabaseQueryResults exposing (DatabaseQueryResults, DatabaseQueryResultsColumn)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import Ports
import Services.Lenses exposing (setDisplay, setInput, setLoading, setResults, setSource)
import Track


type alias Model =
    { id : HtmlId
    , sizeFull : Bool
    , source : Maybe ( Source, DatabaseUrl )
    , input : String
    , loading : Bool
    , results : Maybe (Result String DatabaseQueryResults)
    , display : DisplayMode
    }


type DisplayMode
    = DisplayTable
    | DisplayDocument


displayToString : DisplayMode -> String
displayToString display =
    case display of
        DisplayTable ->
            "table"

        DisplayDocument ->
            "document"


stringToDisplay : String -> DisplayMode
stringToDisplay value =
    case value of
        "document" ->
            DisplayDocument

        _ ->
            DisplayTable


type Msg
    = Toggle
    | Open (Maybe SourceId) (Maybe String)
    | Close
    | ToggleSizeFull
    | UseSource (Maybe ( Source, DatabaseUrl ))
    | InputUpdate String
    | RunQuery DatabaseUrl String
    | GotResults (Result String DatabaseQueryResults)
    | ClearResults
    | SetDisplay DisplayMode



-- INIT


init : List Source -> Maybe SourceId -> Maybe String -> Model
init sources source input =
    { id = Conf.ids.queryPaneDialog, sizeFull = False, source = selectSource sources source, input = input |> Maybe.withDefault "", loading = False, results = Nothing, display = DisplayTable }


selectSource : List Source -> Maybe SourceId -> Maybe ( Source, DatabaseUrl )
selectSource sources source =
    let
        dbSources : List ( Source, DatabaseUrl )
        dbSources =
            sources |> List.filterMap withUrl
    in
    source |> Maybe.andThen (\id -> dbSources |> List.find (\( s, _ ) -> s.id == id)) |> Maybe.orElse (dbSources |> List.head)



-- UPDATE


update : (Msg -> msg) -> Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update wrap erd msg model =
    case msg of
        Toggle ->
            model
                |> Maybe.mapOrElse (\_ -> Nothing) (init erd.sources Nothing Nothing |> Just)
                |> Maybe.map (\m -> ( Just m, Cmd.batch [ m.source |> Maybe.mapOrElse (\_ -> Ports.focus "query-pane-dialog-editor-query") Cmd.none, Track.queryPaneOpened erd.sources erd ] ))
                |> Maybe.withDefault ( Nothing, Track.queryPaneClosed erd )

        Open source input ->
            let
                m : Model
                m =
                    model |> Maybe.map (setSource (selectSource erd.sources source) >> setInput (input |> Maybe.withDefault "")) |> Maybe.withDefault (init erd.sources source input)
            in
            ( m |> Just, Cmd.batch [ Maybe.map2 (\i ( _, url ) -> RunQuery url i |> wrap |> T.send) input m.source |> Maybe.withDefault Cmd.none, Track.queryPaneOpened erd.sources erd ] )

        Close ->
            ( Nothing, Track.queryPaneClosed erd )

        ToggleSizeFull ->
            ( model |> Maybe.map (\m -> { m | sizeFull = not m.sizeFull }), Cmd.none )

        UseSource source ->
            ( model |> Maybe.map (setSource source), Cmd.none )

        InputUpdate input ->
            ( model |> Maybe.map (setInput input), Cmd.none )

        RunQuery databaseUrl query ->
            ( model |> Maybe.map (setLoading True >> setResults Nothing), Ports.runDatabaseQuery databaseUrl query )

        GotResults results ->
            ( model |> Maybe.map (setLoading False >> setResults (Just results)), Cmd.none )

        ClearResults ->
            ( model |> Maybe.map (setResults Nothing), Cmd.none )

        SetDisplay mode ->
            ( model |> Maybe.map (setDisplay mode), Cmd.none )



-- VIEW


view : (Msg -> msg) -> List Source -> Model -> Html msg
view wrap sources model =
    let
        dbSources : List ( Source, DatabaseUrl )
        dbSources =
            sources |> List.filterMap withUrl
    in
    div [ class "py-5 h-full min-w-full max-w-full overflow-scroll" ]
        ([ viewHeading wrap (model.id ++ "-heading") dbSources model.sizeFull model.source
         ]
            ++ (model.source
                    |> Maybe.mapOrElse
                        (\source ->
                            [ viewQueryEditor wrap (model.id ++ "-editor") source model.input model.loading ]
                                ++ (model.results |> Maybe.mapOrElse (\results -> [ viewQueryResults wrap (model.id ++ "-results") model.display results ]) [])
                        )
                        [ viewNoSourceWarning ]
               )
        )


viewHeading : (Msg -> msg) -> HtmlId -> List ( Source, DatabaseUrl ) -> Bool -> Maybe ( Source, DatabaseUrl ) -> Html msg
viewHeading wrap htmlId dbSources sizeFull source =
    let
        sourceInput : HtmlId
        sourceInput =
            htmlId ++ "-source"
    in
    div [ class "flex px-6 space-x-3" ]
        [ div [ class "flex flex-1" ]
            [ h3 [ class "text-lg leading-6 font-medium text-gray-900" ] [ text "Query your database" ]
            , if List.length dbSources > 1 then
                select [ name sourceInput, id sourceInput, onInput (SourceId.fromString >> Maybe.andThen (\id -> dbSources |> List.findBy (Tuple.first >> .id) id) >> UseSource >> wrap), class "ml-2 block border-0 py-0 pl-2 pr-8 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6" ]
                    (dbSources |> List.map (\( s, _ ) -> option [ value (SourceId.toString s.id), selected (source |> Maybe.hasBy (Tuple.first >> .id) s.id) ] [ text s.name ]))

              else
                span [] []
            ]
        , div [ class "flex-shrink-0 self-center flex" ]
            [ button [ onClick (wrap ToggleSizeFull), title (Bool.cond sizeFull "minimize" "maximize"), class "-m-2 p-2 rounded-full flex items-center text-gray-400 hover:text-gray-600" ]
                [ if sizeFull then
                    Icon.solid Icon.ChevronDoubleDown ""

                  else
                    Icon.solid Icon.ChevronDoubleUp ""
                ]
            , button [ onClick (wrap Close), title "close", class "-m-2 p-2 rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
            ]
        ]


viewQueryEditor : (Msg -> msg) -> HtmlId -> ( Source, DatabaseUrl ) -> String -> Bool -> Html msg
viewQueryEditor wrap htmlId ( source, databaseUrl ) input loading =
    let
        queryInput : HtmlId
        queryInput =
            htmlId ++ "-query"
    in
    div [ class "mt-3 px-6" ]
        [ div [ class "relative" ]
            [ textarea
                [ name queryInput
                , id queryInput
                , rows 3
                , value input
                , onInput (InputUpdate >> wrap)
                , autofocus True
                , placeholder ("Write your query for " ++ source.name ++ " database...")
                , class "block w-full border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                ]
                []
            , div [ class "absolute bottom-2 right-2" ]
                [ button
                    [ type_ "button"
                    , onClick (input |> RunQuery databaseUrl |> wrap)
                    , disabled (input == "" || loading)
                    , class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                    ]
                    (if loading then
                        [ Icon.loading "-ml-1 mr-2 animate-spin", text "Execute" ]

                     else
                        [ text "Execute" ]
                    )
                ]
            ]
        ]


viewQueryResults : (Msg -> msg) -> HtmlId -> DisplayMode -> Result String DatabaseQueryResults -> Html msg
viewQueryResults wrap htmlId display results =
    let
        displayId : HtmlId
        displayId =
            htmlId ++ "-display"
    in
    div []
        (results
            |> Result.fold
                (\err ->
                    [ div [ class "mt-3 px-6" ]
                        [ Alert.withDescription { color = Tw.red, icon = Icon.Exclamation, title = "Error 😱" } [ pre [] [ text err ] ]
                        ]
                    ]
                )
                (\res ->
                    [ div [ class "flex justify-between py-1" ]
                        [ p [ class "px-1 text-sm text-gray-500" ] [ text ((res.rows |> List.length |> String.fromInt) ++ " rows") ]
                        , span [ class "px-1 inline-flex rounded-md shadow-sm" ]
                            [ label [ for displayId, class "sr-only" ] [ text "View mode" ]
                            , select [ id displayId, name displayId, onInput (stringToDisplay >> SetDisplay >> wrap), class "block w-full rounded-md border-0 bg-white py-0 pl-3 pr-9 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" ]
                                ([ DisplayTable, DisplayDocument ] |> List.map (\d -> option [ value (displayToString d), selected (d == display) ] [ text (displayToString d ++ " view") ]))
                            ]
                        ]
                    , case display of
                        DisplayTable ->
                            viewQueryResultsTable DisplayTable res.columns res.rows

                        DisplayDocument ->
                            viewQueryResultsTable DisplayDocument [ { name = "document", ref = Nothing } ] (res.rows |> List.map (\r -> Dict.fromList [ ( "document", JsValue.Object r ) ]))
                    ]
                )
        )


viewQueryResultsTable : DisplayMode -> List DatabaseQueryResultsColumn -> List (Dict String JsValue) -> Html msg
viewQueryResultsTable display columns rows =
    table [ class "min-w-full divide-y divide-gray-300" ]
        [ thead [] [ viewQueryResultsTableHeader columns ]
        , tbody [ class "divide-y divide-gray-200" ] (rows |> List.indexedMap (viewQueryResultsTableRow display columns))
        ]


viewQueryResultsTableHeader : List DatabaseQueryResultsColumn -> Html msg
viewQueryResultsTableHeader columns =
    tr [ class "bg-gray-100" ]
        (({ name = "#", ref = Nothing } :: columns)
            |> List.map
                (\col ->
                    th [ scope "col", class "max-w-xs truncate p-1 whitespace-nowrap align-top text-left text-xs font-mono font-semibold text-gray-900" ] [ text col.name ]
                )
        )


viewQueryResultsTableRow : DisplayMode -> List DatabaseQueryResultsColumn -> Int -> Dict String JsValue -> Html msg
viewQueryResultsTableRow display columns i row =
    let
        rest : Dict String JsValue
        rest =
            row |> Dict.filter (\k _ -> columns |> List.memberBy .name k |> not)
    in
    tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 i == 1 ) ] ]
        ([ viewQueryResultsRowValue display (JsValue.Int (i + 1) |> Just) ]
            ++ (columns |> List.map (\col -> row |> Dict.get col.name |> viewQueryResultsRowValue display))
            ++ Bool.cond (rest |> Dict.isEmpty) [] [ viewQueryResultsRowValue display (rest |> JsValue.Object |> Just) ]
        )


viewQueryResultsRowValue : DisplayMode -> Maybe JsValue -> Html msg
viewQueryResultsRowValue display value =
    td [ title (value |> Maybe.mapOrElse JsValue.toJson ""), class "max-w-xs truncate p-1 whitespace-nowrap align-top text-left text-xs font-mono text-gray-500" ]
        [ case display of
            DisplayTable ->
                JsValue.view value

            DisplayDocument ->
                JsValue.viewRaw value
        ]


viewNoSourceWarning : Html msg
viewNoSourceWarning =
    div [ class "mt-3 px-6" ]
        [ Alert.withDescription
            { color = Tw.blue
            , icon = Icon.InformationCircle
            , title = "No database source in project"
            }
            [ p [] [ text "Azimutt is able to query your database if you add a source with a database url." ]
            , p [] [ text "To access this, open settings (top right cog), click on 'add source' and fill the connection url for your database." ]
            ]
        ]



-- HELPERS


withUrl : Source -> Maybe ( Source, DatabaseUrl )
withUrl source =
    source |> Source.databaseUrl |> Maybe.map (\url -> ( source, url ))



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "QueryPane"
        |> Chapter.renderComponentList
            [ ( "no source", view (\_ -> logAction "msg") [] { docModel | source = Nothing } )
            , ( "1 source", view (\_ -> logAction "msg") [ docSource1 ] docModel )
            , ( "2 sources", view (\_ -> logAction "msg") docSources docModel )
            , ( "with input", view (\_ -> logAction "msg") docSources { docModel | input = docQuery } )
            , ( "loading", view (\_ -> logAction "msg") docSources { docModel | input = docQuery, loading = True } )
            , ( "with result error", view (\_ -> logAction "msg") docSources { docModel | input = docQuery, results = Just docResultError } )
            , ( "with empty result", view (\_ -> logAction "msg") docSources { docModel | input = docQuery, results = Just docResultEmpty } )
            , ( "with results", view (\_ -> logAction "msg") docSources { docModel | input = docQuery, results = Just docResults } )
            , ( "with results as documents", view (\_ -> logAction "msg") docSources { docModel | input = docQuery, results = Just docResults, display = DisplayDocument } )
            ]


docModel : Model
docModel =
    { id = "html-id", sizeFull = False, source = Just ( docSource1, "url1" ), input = "", loading = False, results = Nothing, display = DisplayTable }


docQuery : String
docQuery =
    "SELECT * FROM users;"


docResultError : Result String DatabaseQueryResults
docResultError =
    Err "Some unknown error..."


docColumns : List DatabaseQueryResultsColumn
docColumns =
    [ { name = "id", ref = Just { table = ( "public", "users" ), column = Nel.from "id" } }, { name = "name", ref = Nothing }, { name = "data", ref = Nothing } ]


docResultEmpty : Result String DatabaseQueryResults
docResultEmpty =
    Ok { query = docQuery, columns = docColumns, rows = [] }


docResults : Result String DatabaseQueryResults
docResults =
    Ok
        { query = docQuery
        , columns = docColumns
        , rows =
            [ Dict.fromList [ ( "id", JsValue.Int 3 ), ( "name", JsValue.String "Loïc" ) ]
            , Dict.fromList [ ( "id", JsValue.Int 4 ), ( "name", JsValue.String "Samir" ), ( "data", JsValue.Object (Dict.fromList [ ( "affiliation", JsValue.String "github" ) ]) ) ]
            ]
        }


docSources : List Source
docSources =
    [ docSource1, docSource2 ]


docSource1 : Source
docSource1 =
    { id = SourceId.zero, name = "source 1", kind = DatabaseConnection "url1", content = Array.empty, tables = Dict.empty, relations = [], types = Dict.empty, enabled = True, fromSample = Nothing, createdAt = Time.zero, updatedAt = Time.zero }


docSource2 : Source
docSource2 =
    { docSource1 | id = SourceId.one, name = "source 2" }

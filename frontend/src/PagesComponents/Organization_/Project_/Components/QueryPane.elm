module PagesComponents.Organization_.Project_.Components.QueryPane exposing (Model, Msg(..), update, view)

import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Conf
import Dict exposing (Dict)
import Html exposing (Html, button, div, h3, option, p, pre, select, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (autofocus, class, classList, disabled, id, name, placeholder, rows, scope, selected, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw
import Models.DatabaseQueryResults exposing (DatabaseQueryResults)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import Ports
import Services.Lenses exposing (setInput, setLoading, setResults, setSource)


type alias Model =
    { id : HtmlId, source : Maybe ( Source, DatabaseUrl ), input : String, loading : Bool, results : Maybe (Result String DatabaseQueryResults) }


type Msg
    = Toggle
    | Close
    | UseSource (Maybe ( Source, DatabaseUrl ))
    | InputUpdate String
    | RunQuery DatabaseUrl String
    | GotResults (Result String DatabaseQueryResults)
    | ClearResults



-- INIT


init : Erd -> Model
init erd =
    { id = Conf.ids.queryPaneDialog, source = erd.sources |> List.filterMap withUrl |> List.head, input = "", loading = False, results = Nothing }



-- UPDATE


update : Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update erd msg model =
    case msg of
        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (init erd |> Just), Cmd.none )

        Close ->
            ( Nothing, Cmd.none )

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



-- VIEW


view : (Msg -> msg) -> Erd -> Model -> Html msg
view wrap erd model =
    let
        dbSources : List ( Source, DatabaseUrl )
        dbSources =
            erd.sources |> List.filterMap withUrl
    in
    div [ class "h-full py-5" ]
        ([ viewHeading wrap (model.id ++ "-heading") dbSources model.source
         ]
            ++ (model.source
                    |> Maybe.mapOrElse
                        (\source ->
                            [ viewQueryEditor wrap (model.id ++ "-editor") source model.input model.loading ]
                                ++ (model.results |> Maybe.mapOrElse (\results -> [ viewQueryResults results ]) [])
                        )
                        [ viewNoSourceWarning ]
               )
        )


viewHeading : (Msg -> msg) -> HtmlId -> List ( Source, DatabaseUrl ) -> Maybe ( Source, DatabaseUrl ) -> Html msg
viewHeading wrap htmlId dbSources source =
    let
        sourceInput : HtmlId
        sourceInput =
            htmlId ++ "-source"
    in
    div [ class "flex px-6 space-x-3" ]
        [ div [ class "flex flex-1" ]
            [ h3 [ class "text-lg leading-6 font-medium text-gray-900" ] [ text "Query your database" ]
            , if List.length dbSources > 1 then
                select [ name sourceInput, id sourceInput, onInput (SourceId.fromString >> Maybe.andThen (\id -> dbSources |> List.findBy (Tuple.first >> .id) id) >> UseSource >> wrap), class "ml-2 block rounded-md border-0 py-0 pl-2 pr-8 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6" ]
                    (dbSources |> List.map (\( s, _ ) -> option [ value (SourceId.toString s.id), selected (source |> Maybe.hasBy (Tuple.first >> .id) s.id) ] [ text s.name ]))

              else
                span [] []
            ]
        , div [ class "flex-shrink-0 self-center flex" ]
            [ button [ onClick (wrap Close), class "-m-2 p-2 rounded-full flex items-center text-gray-400 hover:text-gray-600" ] [ Icon.solid Icon.X "" ]
            ]
        ]


viewQueryEditor : (Msg -> msg) -> HtmlId -> ( Source, DatabaseUrl ) -> String -> Bool -> Html msg
viewQueryEditor wrap htmlId ( source, databaseUrl ) input loading =
    let
        queryInput : HtmlId
        queryInput =
            htmlId ++ "-editor"
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
                , class "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                ]
                []
            , div [ class "absolute bottom-2 right-2" ]
                [ button
                    [ type_ "button"
                    , onClick (input |> RunQuery databaseUrl |> wrap)
                    , disabled (input == "" || loading)
                    , class "inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                    ]
                    (if loading then
                        [ Icon.loading "-ml-1 mr-2 animate-spin", text "Run" ]

                     else
                        [ text "Run" ]
                    )
                ]
            ]
        ]


viewQueryResults : Result String DatabaseQueryResults -> Html msg
viewQueryResults results =
    div [ class "min-w-full max-w-full overflow-scroll" ]
        (results
            |> Result.fold
                (\err ->
                    [ div [ class "mt-3 px-6" ]
                        [ Alert.withDescription { color = Tw.red, icon = Icon.Exclamation, title = "Error 😱" } [ pre [] [ text err ] ]
                        ]
                    ]
                )
                (\res ->
                    [ p [ class "px-1 text-sm text-gray-500" ] [ text ((res.rows |> List.length |> String.fromInt) ++ " rows") ]
                    , table [ class "min-w-full divide-y divide-gray-300" ]
                        [ thead [] [ viewQueryResultsHeader res.columns ]
                        , tbody [ class "divide-y divide-gray-200" ] (res.rows |> List.indexedMap (viewQueryResultsRow res.columns))
                        ]
                    ]
                )
        )


viewQueryResultsHeader : List String -> Html msg
viewQueryResultsHeader columns =
    tr [] (("#" :: columns) |> List.map (\col -> th [ scope "col", class "whitespace-nowrap p-1 text-left text-sm font-semibold text-gray-900 max-w-xs truncate" ] [ text col ]))


viewQueryResultsRow : List String -> Int -> Dict String JsValue -> Html msg
viewQueryResultsRow columns i row =
    let
        rest : Dict String JsValue
        rest =
            row |> Dict.filter (\k _ -> columns |> List.member k |> not)
    in
    tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 i == 1 ) ] ]
        ([ viewQueryResultsRowValue (JsValue.Int (i + 1)) ]
            ++ (columns |> List.map (\col -> row |> Dict.getOrElse col JsValue.Null |> viewQueryResultsRowValue))
            ++ Bool.cond (rest |> Dict.isEmpty) [] [ viewQueryResultsRowValue (rest |> JsValue.Object) ]
        )


viewQueryResultsRowValue : JsValue -> Html msg
viewQueryResultsRowValue value =
    td [ title (value |> JsValue.toString), class "whitespace-nowrap p-1 text-sm text-gray-500 max-w-xs truncate" ] [ text (value |> JsValue.toString) ]


viewNoSourceWarning : Html msg
viewNoSourceWarning =
    div [ class "mt-3" ]
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

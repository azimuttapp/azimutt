module Services.DatabaseSource exposing (Model, Msg(..), example, init, update, viewInput, viewParsing)

import Components.Molecules.Divider as Divider
import Components.Molecules.Tooltip as Tooltip
import Conf
import DataSources.DatabaseMiner.DatabaseAdapter as DatabaseAdapter
import DataSources.DatabaseMiner.DatabaseSchema as DatabaseSchema exposing (DatabaseSchema)
import Html exposing (Html, div, img, input, p, span, text)
import Html.Attributes exposing (class, disabled, id, name, placeholder, src, type_, value)
import Html.Events exposing (onBlur, onInput)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Task as T
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.ProjectInfo exposing (ProjectInfo)
import Ports
import Random
import Services.Backend as Backend
import Services.Lenses exposing (mapShow)
import Services.SourceLogs as SourceLogs
import Time
import Track


type alias Model msg =
    { source : Maybe Source
    , url : String
    , selectedUrl : Maybe (Result String String)
    , loadedSchema : Maybe (Result Backend.Error String)
    , parsedSchema : Maybe (Result Decode.Error DatabaseSchema)
    , parsedSource : Maybe (Result String Source)
    , callback : Result String Source -> msg
    , show : HtmlId
    }


type Msg
    = UpdateUrl DatabaseUrl
    | GetSchema DatabaseUrl
    | GotSchema (Result Backend.Error String)
    | ParseSource
    | BuildSource SourceId
    | UiToggle HtmlId



-- INIT


example : String
example =
    "postgres://<user>:<password>@<host>:<port>/<db_name>"


init : Maybe Source -> (Result String Source -> msg) -> Model msg
init src callback =
    { source = src
    , url = ""
    , selectedUrl = Nothing
    , loadedSchema = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Maybe ProjectInfo -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap now project msg model =
    case msg of
        UpdateUrl url ->
            ( { model | url = url }, Cmd.none )

        GetSchema schemaUrl ->
            if schemaUrl == "" then
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl }), Cmd.none )

            else
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl, selectedUrl = Just (Ok schemaUrl) })
                , Backend.getDatabaseSchema schemaUrl (GotSchema >> wrap)
                )

        GotSchema result ->
            ( { model | loadedSchema = Just result }, T.send (ParseSource |> wrap) )

        ParseSource ->
            ( { model | parsedSchema = model.loadedSchema |> Maybe.andThen Result.toMaybe |> Maybe.map (Decode.decodeString DatabaseSchema.decode) }, SourceId.generator |> Random.generate (BuildSource >> wrap) )

        BuildSource sourceId ->
            Maybe.map2
                (\url -> Result.map (DatabaseAdapter.buildSource now (model.source |> Maybe.mapOrElse .id sourceId) url))
                (model.selectedUrl |> Maybe.andThen Result.toMaybe)
                ((model.parsedSchema |> Maybe.map (Result.mapError Decode.errorToString))
                    |> Maybe.orElse (model.loadedSchema |> Maybe.map (Result.map (\_ -> DatabaseSchema.empty) >> Result.mapError Backend.errorToString))
                )
                |> (\source ->
                        ( { model | parsedSource = source }
                        , source
                            |> Maybe.map (\s -> Cmd.batch [ s |> model.callback |> T.send, s |> Track.dbSourceCreated project |> Ports.track ])
                            |> Maybe.withDefault (Err "Source not available" |> Track.dbSourceCreated project |> Ports.track)
                        )
                   )

        UiToggle htmlId ->
            ( model |> mapShow (\s -> B.cond (s == htmlId) "" htmlId), Cmd.none )



-- VIEW


viewInput : (Msg -> msg) -> HtmlId -> Model msg -> Html msg
viewInput wrap htmlId model =
    let
        error : Maybe String
        error =
            model.selectedUrl |> Maybe.andThen Result.toError

        inputStyles : TwClass
        inputStyles =
            error
                |> Maybe.mapOrElse (\_ -> "text-red-500 placeholder-red-300 border-red-300 focus:border-red-500 focus:ring-red-500")
                    "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"
    in
    div []
        [ div [ class "flex space-x-10" ]
            ([ ( "postgresql", Nothing )
             , ( "mysql", Just "https://github.com/azimuttapp/azimutt/issues/114" )
             , ( "oracle", Just (Conf.constants.azimuttNewIssue "Support oracle database import" "") )
             , ( "sql-server", Just "https://github.com/azimuttapp/azimutt/issues/113" )
             , ( "mariadb", Just (Conf.constants.azimuttNewIssue "Support mariadb database import" "") )
             , ( "sqlite", Just "https://github.com/azimuttapp/azimutt/issues/115" )
             ]
                |> List.map
                    (\( name, requestLink ) ->
                        requestLink
                            |> Maybe.mapOrElse
                                (\link ->
                                    extLink link [] [ img [ src (Backend.resourceUrl ("/assets/logos/" ++ name ++ ".png")), class "grayscale opacity-50" ] [] ]
                                        |> Tooltip.t "Click to ask support (done on demand)"
                                )
                                (span [] [ img [ src (Backend.resourceUrl ("/assets/logos/" ++ name ++ ".png")) ] [] ])
                    )
            )
        , div [ class "mt-3 flex rounded-md shadow-sm" ]
            [ span [ css [ inputStyles, "inline-flex items-center px-3 rounded-l-md border border-r-0 bg-gray-50 text-gray-500 sm:text-sm" ] ] [ text "Database url" ]
            , input
                [ type_ "text"
                , id (htmlId ++ "-url")
                , name (htmlId ++ "-url")
                , placeholder ("ex: " ++ example)
                , value model.url
                , disabled ((model.selectedUrl |> Maybe.andThen Result.toMaybe) /= Nothing && model.loadedSchema == Nothing)
                , onInput (UpdateUrl >> wrap)
                , onBlur (GetSchema model.url |> wrap)
                , css [ inputStyles, "flex-1 min-w-0 block w-full px-3 py-2 rounded-none rounded-r-md sm:text-sm", Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200" ] ]
                ]
                []
            ]
        , error |> Maybe.mapOrElse (\err -> p [ class "mt-1 text-sm text-red-500" ] [ text err ]) (p [] [])
        ]


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    (model.selectedUrl |> Maybe.andThen Result.toMaybe |> Maybe.map (\url -> DatabaseUrl.databaseName url ++ " database"))
        |> Maybe.mapOrElse
            (\dbName ->
                div []
                    [ div [ class "mt-6" ]
                        [ Divider.withLabel
                            ((model.parsedSource |> Maybe.map (\_ -> "Loaded!"))
                                |> Maybe.orElse (model.parsedSchema |> Maybe.map (\_ -> "Building..."))
                                |> Maybe.orElse (model.loadedSchema |> Maybe.map (\_ -> "Parsing..."))
                                |> Maybe.withDefault "Fetching..."
                            )
                        ]
                    , SourceLogs.viewContainer
                        [ SourceLogs.viewFile UiToggle model.show dbName (model.loadedSchema |> Maybe.andThen Result.toMaybe) |> Html.map wrap
                        , model.loadedSchema |> Maybe.mapOrElse (Result.mapError Backend.errorToString >> SourceLogs.viewError) (div [] [])
                        , model.parsedSchema |> Maybe.mapOrElse (SourceLogs.viewParsedSchema UiToggle model.show) (div [] []) |> Html.map wrap
                        , model.parsedSource |> Maybe.mapOrElse SourceLogs.viewResult (div [] [])
                        ]
                    , if model.parsedSource == Nothing then
                        div [] [ img [ class "mt-1 rounded-l-lg", src (Backend.resourceUrl "/assets/images/exploration.gif") ] [] ]

                      else
                        div [] []
                    ]
            )
            (div [] [])

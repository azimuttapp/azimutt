module Services.DatabaseSource exposing (Model, Msg(..), init, update, viewInput, viewParsing)

import Components.Molecules.Divider as Divider
import DataSources.DatabaseSourceParser.DatabaseAdapter as DatabaseAdapter
import DataSources.DatabaseSourceParser.DatabaseSchema as DatabaseSchema exposing (DatabaseSchema)
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (class, disabled, id, name, placeholder, src, type_, value)
import Html.Events exposing (onBlur, onInput)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus)
import Libs.Task as T
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Random
import Services.Backend as Backend
import Services.Lenses exposing (mapShow)
import Services.SourceLogs as SourceLogs
import Time


type alias Model msg =
    { defaultSchema : SchemaName
    , source : Maybe Source
    , url : String
    , selectedUrl : Maybe String
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


init : SchemaName -> Maybe Source -> (Result String Source -> msg) -> Model msg
init defaultSchema src callback =
    { defaultSchema = defaultSchema
    , source = src
    , url = ""
    , selectedUrl = Nothing
    , loadedSchema = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Backend.Url -> Time.Posix -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap backendUrl now msg model =
    case msg of
        UpdateUrl url ->
            ( { model | url = url }, Cmd.none )

        GetSchema schemaUrl ->
            ( init model.defaultSchema model.source model.callback |> (\m -> { m | url = schemaUrl, selectedUrl = Just schemaUrl })
            , Backend.getDatabaseSchema backendUrl schemaUrl (GotSchema >> wrap)
            )

        GotSchema result ->
            ( { model | loadedSchema = Just result }, T.send (ParseSource |> wrap) )

        ParseSource ->
            ( { model | parsedSchema = model.loadedSchema |> Maybe.andThen Result.toMaybe |> Maybe.map (Decode.decodeString DatabaseSchema.decode) }, SourceId.generator |> Random.generate (BuildSource >> wrap) )

        BuildSource sourceId ->
            ( { model
                | parsedSource =
                    Maybe.map2
                        (\url -> Result.map (DatabaseAdapter.buildSource now (model.source |> Maybe.mapOrElse .id sourceId) url))
                        model.selectedUrl
                        ((model.parsedSchema |> Maybe.map (Result.mapError Decode.errorToString))
                            |> Maybe.orElse (model.loadedSchema |> Maybe.map (Result.map (\_ -> DatabaseSchema.empty) >> Result.mapError Backend.errorToString))
                        )
              }
            , Cmd.none
            )

        UiToggle htmlId ->
            ( model |> mapShow (\s -> B.cond (s == htmlId) "" htmlId), Cmd.none )



-- VIEW


viewInput : HtmlId -> Model msg -> Html Msg
viewInput htmlId model =
    div [ class "mt-3 flex rounded-md shadow-sm" ]
        [ span [ class "inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm" ] [ text "Database url" ]
        , input
            [ type_ "text"
            , id (htmlId ++ "-url")
            , name (htmlId ++ "-url")
            , placeholder "ex: postgres://<user>:<password>@<host>:<port>/<db_name>"
            , value model.url
            , disabled (model.selectedUrl /= Nothing && model.loadedSchema == Nothing)
            , onInput UpdateUrl
            , onBlur (GetSchema model.url)
            , css [ "flex-1 min-w-0 block w-full px-3 py-2 border-gray-300 rounded-none rounded-r-md sm:text-sm", focus [ "ring-indigo-500 border-indigo-500" ], Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200" ] ]
            ]
            []
        ]


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    (model.selectedUrl |> Maybe.map (\url -> DatabaseUrl.databaseName url ++ " database"))
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
                        , model.loadedSchema |> Maybe.mapOrElse SourceLogs.viewBackendError (div [] [])
                        , model.parsedSchema |> Maybe.mapOrElse (SourceLogs.viewParsedSchema UiToggle model.show model.defaultSchema) (div [] []) |> Html.map wrap
                        , model.parsedSource |> Maybe.mapOrElse (\_ -> div [] [ text "Done!" ]) (div [] [])
                        ]
                    , if model.parsedSource == Nothing then
                        div [] [ img [ class "mt-1 rounded-l-lg", src "/assets/images/illustrations/exploration.gif" ] [] ]

                      else
                        div [] []
                    ]
            )
            (div [] [])

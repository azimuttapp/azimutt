module Services.JsonSource exposing (Model, Msg(..), init, kind, update, viewInput, viewLocalInput, viewParsing, viewRemoteInput)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import DataSources.JsonMiner.JsonAdapter as JsonAdapter
import DataSources.JsonMiner.JsonSchema as JsonSchema exposing (JsonSchema)
import FileValue exposing (File)
import Html exposing (Html, div, input, p, span, text)
import Html.Attributes exposing (class, id, name, placeholder, type_, value)
import Html.Events exposing (onBlur, onInput)
import Http
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Http as Http
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind exposing (TwClass)
import Libs.Task as T
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Ports
import Random
import Services.Lenses exposing (mapShow, setId, setParsedSchema, setParsedSource)
import Services.SourceLogs as SourceLogs
import Time
import Track


type alias Model msg =
    { source : Maybe Source
    , url : String
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe (Result String FileUrl)
    , loadedSchema : Maybe ( SourceInfo, FileContent )
    , parsedSchema : Maybe (Result Decode.Error JsonSchema)
    , parsedSource : Maybe (Result String Source)
    , callback : Result String Source -> msg
    , show : HtmlId
    }


type Msg
    = UpdateRemoteFile FileUrl
    | GetRemoteFile FileUrl
    | GotRemoteFile FileUrl (Result Http.Error FileContent)
    | GetLocalFile File
    | GotFile SourceInfo FileContent
    | ParseSource
    | BuildSource
    | UiToggle HtmlId



-- INIT


kind : String
kind =
    "json-source"


init : Maybe Source -> (Result String Source -> msg) -> Model msg
init source callback =
    { source = source
    , url = ""
    , selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , loadedSchema = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap now msg model =
    case msg of
        UpdateRemoteFile url ->
            ( { model | url = url }, Cmd.none )

        GetRemoteFile schemaUrl ->
            if schemaUrl == "" then
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl }), Cmd.none )

            else if schemaUrl |> String.startsWith "http" |> not then
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl, selectedRemoteFile = Just (Err "Invalid url, it should start with 'http'") }), Cmd.none )

            else
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl, selectedRemoteFile = Just (Ok schemaUrl) })
                , Http.get { url = schemaUrl, expect = Http.expectString (GotRemoteFile schemaUrl >> wrap) }
                )

        GotRemoteFile url result ->
            case result of
                Ok content ->
                    ( model, SourceId.generator |> Random.generate (\sourceId -> GotFile (SourceInfo.jsonRemote now sourceId url content Nothing) content |> wrap) )

                Err err ->
                    ( model |> setParsedSource (err |> Http.errorToString |> Err |> Just), T.send (model.callback (err |> Http.errorToString |> Err)) )

        GetLocalFile file ->
            ( init model.source model.callback |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile kind file
            )

        GotFile sourceInfo fileContent ->
            ( { model | loadedSchema = Just ( sourceInfo |> setId (model.source |> Maybe.mapOrElse .id sourceInfo.id), fileContent ) }
            , T.send (ParseSource |> wrap)
            )

        ParseSource ->
            model.loadedSchema
                |> Maybe.map (\( _, json ) -> ( model |> setParsedSchema (json |> Decode.decodeString JsonSchema.decode |> Just), T.send (BuildSource |> wrap) ))
                |> Maybe.withDefault ( model, Cmd.none )

        BuildSource ->
            Maybe.map2 (\( info, _ ) schema -> schema |> Result.map (JsonAdapter.buildSource info) |> Result.mapError Decode.errorToString)
                model.loadedSchema
                model.parsedSchema
                |> Maybe.map (\source -> ( model |> setParsedSource (source |> Just), Cmd.batch [ T.send (model.callback source), Ports.track (Track.parsedJsonSource source) ] ))
                |> Maybe.withDefault ( model, Cmd.none )

        UiToggle htmlId ->
            ( model |> mapShow (\s -> B.cond (s == htmlId) "" htmlId), Cmd.none )



-- VIEW


viewInput : (Msg -> msg) -> (String -> msg) -> HtmlId -> Model msg -> Html msg
viewInput wrap noop htmlId model =
    div []
        [ viewLocalInput wrap noop (htmlId ++ "-local-file")
        , div [ class "mt-3" ] [ Divider.withLabel "OR" ]
        , div [ class "mt-3" ] [ viewRemoteInput wrap (htmlId ++ "-remote-file") model.url (model.selectedRemoteFile |> Maybe.andThen Result.toError) ]
        ]


viewLocalInput : (Msg -> msg) -> (String -> msg) -> HtmlId -> Html msg
viewLocalInput wrap noop htmlId =
    FileInput.input
        { id = htmlId
        , onDrop = \f _ -> f |> GetLocalFile |> wrap
        , onOver = \_ _ -> noop htmlId
        , onLeave = Nothing
        , onSelect = GetLocalFile >> wrap
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x DocumentAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your JSON schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".json file only" ]
                ]
        , mimes = [ ".json" ]
        }


viewRemoteInput : (Msg -> msg) -> HtmlId -> String -> Maybe String -> Html msg
viewRemoteInput wrap htmlId model error =
    let
        inputStyles : TwClass
        inputStyles =
            error
                |> Maybe.mapOrElse (\_ -> "text-red-500 placeholder-red-300 border-red-300 focus:border-red-500 focus:ring-red-500")
                    "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"
    in
    div []
        [ div [ class "flex rounded-md shadow-sm" ]
            [ span [ css [ inputStyles, "inline-flex items-center px-3 rounded-l-md border border-r-0 bg-gray-50 text-gray-500 sm:text-sm" ] ] [ text "Remote schema" ]
            , input
                [ type_ "text"
                , id htmlId
                , name htmlId
                , placeholder "ex: https://azimutt.app/samples/gospeak.json"
                , value model
                , onInput (UpdateRemoteFile >> wrap)
                , onBlur (model |> GetRemoteFile |> wrap)
                , css [ inputStyles, "flex-1 min-w-0 block w-full px-3 py-2 rounded-none rounded-r-md sm:text-sm" ]
                ]
                []
            ]
        , error |> Maybe.mapOrElse (\err -> p [ class "mt-1 text-sm text-red-500" ] [ text err ]) (span [] [])
        ]


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    ((model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file")) |> Maybe.orElse (model.selectedRemoteFile |> Maybe.andThen Result.toMaybe |> Maybe.map (\u -> u ++ " file")))
        |> Maybe.mapOrElse
            (\fileName ->
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
                        [ SourceLogs.viewFile UiToggle model.show fileName (model.loadedSchema |> Maybe.map Tuple.second) |> Html.map wrap
                        , model.parsedSchema |> Maybe.mapOrElse (SourceLogs.viewParsedSchema UiToggle model.show) (div [] []) |> Html.map wrap
                        , model.parsedSource |> Maybe.mapOrElse SourceLogs.viewError (div [] [])
                        , model.parsedSource |> Maybe.mapOrElse SourceLogs.viewResult (div [] [])
                        ]
                    ]
            )
            (div [] [])

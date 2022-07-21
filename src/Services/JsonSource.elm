module Services.JsonSource exposing (Model, Msg(..), gotLocalFile, gotRemoteFile, init, kind, update, viewInput, viewParsing)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import DataSources.JsonSourceParser.JsonAdapter as JsonAdapter
import DataSources.JsonSourceParser.JsonSchema as JsonSchema exposing (JsonSchema)
import FileValue exposing (File)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Ports
import Services.Lenses exposing (mapShow, setId, setParsedSchema, setParsedSource)
import Services.SourceLogs as SourceLogs
import Time
import Track


type alias Model msg =
    { defaultSchema : SchemaName
    , source : Maybe Source
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe FileUrl
    , loadedSchema : Maybe ( SourceInfo, FileContent )
    , parsedSchema : Maybe (Result Decode.Error JsonSchema)
    , parsedSource : Maybe (Result String Source)
    , callback : Result String Source -> msg
    , show : HtmlId
    }


type Msg
    = UpdateRemoteFile FileUrl
    | GetRemoteFile FileUrl
    | GetLocalFile File
    | GotFile SourceInfo FileContent
    | ParseSource
    | BuildSource
    | UiToggle HtmlId



-- INIT


init : SchemaName -> Maybe Source -> (Result String Source -> msg) -> Model msg
init defaultSchema source callback =
    { defaultSchema = defaultSchema
    , source = source
    , selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , loadedSchema = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap msg model =
    case msg of
        UpdateRemoteFile url ->
            ( { model | selectedRemoteFile = B.cond (url == "") Nothing (Just url) }, Cmd.none )

        GetRemoteFile url ->
            ( init model.defaultSchema model.source model.callback |> (\m -> { m | selectedRemoteFile = Just url })
            , Ports.readRemoteFile kind url Nothing
            )

        GetLocalFile file ->
            ( init model.defaultSchema model.source model.callback |> (\m -> { m | selectedLocalFile = Just file })
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



-- SUBSCRIPTIONS


kind : String
kind =
    "json-source"


gotLocalFile : Time.Posix -> SourceId -> File -> FileContent -> Msg
gotLocalFile now sourceId file content =
    GotFile (SourceInfo.jsonLocal now sourceId file) content


gotRemoteFile : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> Msg
gotRemoteFile now sourceId url content sample =
    GotFile (SourceInfo.jsonRemote now sourceId url content sample) content



-- VIEW


viewInput : HtmlId -> (File -> msg) -> msg -> Html msg
viewInput htmlId onSelect noop =
    FileInput.input
        { id = htmlId
        , onDrop = \f _ -> onSelect f
        , onOver = \_ _ -> noop
        , onLeave = Nothing
        , onSelect = onSelect
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x DocumentAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your JSON schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".json file only" ]
                ]
        , mimes = [ ".json" ]
        }


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    ((model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file")) |> Maybe.orElse (model.selectedRemoteFile |> Maybe.map (\u -> u ++ " file")))
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
                        , model.parsedSchema |> Maybe.mapOrElse (SourceLogs.viewParsedSchema UiToggle model.show model.defaultSchema) (div [] []) |> Html.map wrap
                        , model.parsedSource |> Maybe.mapOrElse (\_ -> div [] [ text "Done!" ]) (div [] [])
                        ]
                    ]
            )
            (div [] [])

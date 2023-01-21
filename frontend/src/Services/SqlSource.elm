module Services.SqlSource exposing (Model, Msg(..), ParsingMsg(..), SqlParsing, example, hasErrors, init, kind, update, viewInput, viewLocalInput, viewParsing, viewRemoteInput)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import Conf
import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.SqlAdapter as SqlAdapter exposing (SqlSchema, SqlSchemaError)
import DataSources.SqlMiner.SqlParser as SqlParser exposing (Command)
import DataSources.SqlMiner.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import FileValue exposing (File)
import Html exposing (Html, div, input, p, pre, span, text)
import Html.Attributes exposing (class, href, id, name, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Http
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (css)
import Libs.Http as Http
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Task as T
import Models.Project.Column exposing (Column)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Ports
import Random
import Services.Lenses exposing (mapParsedSchemaM, mapShow, setId, setParsedSource)
import Services.SourceLogs as SourceLogs
import Time
import Track
import Url exposing (percentEncode)


type alias Model msg =
    { source : Maybe Source
    , url : String
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe (Result String FileUrl)
    , loadedFile : Maybe ( SourceInfo, FileContent )
    , parsedSchema : Maybe (SqlParsing msg)
    , parsedSource : Maybe (Result String Source)
    , callback : ( Maybe (SqlParsing msg), Result String Source ) -> msg
    }


type alias SqlParsing msg =
    { cpt : Int
    , fileContent : FileContent
    , lines : Maybe (List SourceLine)
    , statements : Maybe (Dict Int SqlStatement)
    , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
    , schemaIndex : Int
    , schema : Maybe SqlSchema
    , show : HtmlId
    , buildMsg : ParsingMsg -> msg
    , buildProject : msg
    }


type Msg
    = UpdateRemoteFile FileUrl
    | GetRemoteFile FileUrl
    | GotRemoteFile FileUrl (Result Http.Error FileContent)
    | GetLocalFile File
    | GotFile SourceInfo FileContent
    | ParseMsg ParsingMsg
    | BuildSource
    | UiToggle HtmlId


type ParsingMsg
    = BuildLines
    | BuildStatements
    | BuildCommand
    | EvolveSchema



-- INIT


kind : String
kind =
    "sql-source"


example : String
example =
    "https://azimutt.app/elm/samples/basic.sql"


init : Maybe Source -> (( Maybe (SqlParsing msg), Result String Source ) -> msg) -> Model msg
init source callback =
    { source = source
    , url = ""
    , selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , loadedFile = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    }


parsingInit : FileContent -> (ParsingMsg -> msg) -> msg -> SqlParsing msg
parsingInit fileContent buildMsg buildProject =
    { cpt = 0
    , fileContent = fileContent
    , lines = Nothing
    , statements = Nothing
    , commands = Nothing
    , schemaIndex = 0
    , schema = Nothing
    , show = ""
    , buildMsg = buildMsg
    , buildProject = buildProject
    }



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Maybe ProjectInfo -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap now project msg model =
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
                    ( model, SourceId.generator |> Random.generate (\sourceId -> GotFile (SourceInfo.sqlRemote now sourceId url content Nothing) content |> wrap) )

                Err err ->
                    ( model |> setParsedSource (err |> Http.errorToString |> Err |> Just), T.send (model.callback ( Nothing, err |> Http.errorToString |> Err )) )

        GetLocalFile file ->
            ( init model.source model.callback |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile kind file
            )

        GotFile sourceInfo fileContent ->
            ( { model
                | loadedFile = Just ( sourceInfo |> setId (model.source |> Maybe.mapOrElse .id sourceInfo.id), fileContent )
                , parsedSchema = Just (parsingInit fileContent (ParseMsg >> wrap) (BuildSource |> wrap))
              }
            , T.send (BuildLines |> ParseMsg |> wrap)
            )

        ParseMsg parseMsg ->
            Maybe.map2
                (\parsedSchema ( sourceInfo, _ ) ->
                    parsingUpdate sourceInfo.id parseMsg parsedSchema
                        |> (\( parsed, message ) ->
                                ( { model | parsedSchema = Just parsed }
                                  -- 342 is an arbitrary number to break Elm message batching
                                  -- not too often to not increase compute time too much, not too scarce to not freeze the browser
                                , B.cond ((parsed.cpt |> modBy 342) == 1) (T.sendAfter 1 message) (T.send message)
                                )
                           )
                )
                model.parsedSchema
                model.loadedFile
                |> Maybe.withDefault ( model, Cmd.none )

        BuildSource ->
            model.parsedSchema
                |> Maybe.andThen
                    (\parsedSchema ->
                        parsedSchema.schema
                            |> Maybe.map3 (\( sourceInfo, _ ) lines schema -> ( parsedSchema, SqlAdapter.buildSource sourceInfo lines schema ))
                                model.loadedFile
                                parsedSchema.lines
                    )
                |> Maybe.map
                    (\( parsedSchema, source ) ->
                        ( model |> setParsedSource (source |> Ok |> Just)
                        , Cmd.batch [ T.send (model.callback ( Just parsedSchema, Ok source )), Track.sqlSourceCreated project parsedSchema source |> Ports.track ]
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        UiToggle htmlId ->
            ( model |> mapParsedSchemaM (mapShow (\s -> B.cond (s == htmlId) "" htmlId)), Cmd.none )


parsingUpdate : SourceId -> ParsingMsg -> SqlParsing msg -> ( SqlParsing msg, msg )
parsingUpdate sourceId msg model =
    (case msg of
        BuildLines ->
            ( { model | lines = model.fileContent |> SqlParser.splitLines |> Just }, model.buildMsg BuildStatements )

        BuildStatements ->
            model.lines |> Maybe.mapOrElse (\l -> l |> SqlParser.buildStatements |> (\statements -> ( { model | statements = statements |> Dict.fromIndexedList |> Just }, model.buildMsg BuildCommand ))) ( model, model.buildMsg BuildStatements )

        BuildCommand ->
            let
                index : Int
                index =
                    model.commands |> Maybe.withDefault Dict.empty |> Dict.size
            in
            model.statements
                |> Maybe.withDefault Dict.empty
                |> Dict.get index
                |> Maybe.map (\s -> ( { model | commands = model.commands |> Maybe.withDefault Dict.empty |> Dict.insert index ( s, s |> SqlParser.parseCommand ) |> Just }, model.buildMsg BuildCommand ))
                |> Maybe.withDefault ( model, model.buildMsg EvolveSchema )

        EvolveSchema ->
            (model.commands |> Maybe.withDefault Dict.empty |> Dict.get model.schemaIndex)
                |> Maybe.map
                    (\( statement, command ) ->
                        case command of
                            Ok cmd ->
                                model.schema
                                    |> Maybe.withDefault SqlAdapter.initSchema
                                    |> SqlAdapter.evolve sourceId ( statement, cmd )
                                    |> (\schema -> ( { model | schemaIndex = model.schemaIndex + 1, schema = Just schema }, model.buildMsg EvolveSchema ))

                            Err _ ->
                                ( { model | schemaIndex = model.schemaIndex + 1 }, model.buildMsg EvolveSchema )
                    )
                |> Maybe.withDefault ( model, model.buildProject )
    )
        |> Tuple.mapFirst parsingCptInc


parsingCptInc : SqlParsing msg -> SqlParsing msg
parsingCptInc model =
    { model | cpt = model.cpt + 1 }



-- VIEW


viewInput : (Msg -> msg) -> (String -> msg) -> HtmlId -> Model msg -> Html msg
viewInput wrap noop htmlId model =
    div []
        [ viewLocalInput wrap noop (htmlId ++ "-local-file")
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text "Azimutt has a flexible SQL parser which can handle ", bText "most SQL dialects", text ". Errors are fixed within a few days when sent." ]
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
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your SQL schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".sql file only" ]
                ]
        , mimes = [ ".sql" ]
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
                , placeholder ("ex: " ++ example)
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
        |> Maybe.map
            (\fileName ->
                div []
                    [ div [ class "mt-6" ]
                        [ Divider.withLabel
                            ((model.parsedSource |> Maybe.map (\_ -> "Loaded!"))
                                |> Maybe.orElse (model.parsedSchema |> Maybe.map (\_ -> "Building..."))
                                |> Maybe.orElse (model.loadedFile |> Maybe.map (\_ -> "Parsing..."))
                                |> Maybe.withDefault "Fetching..."
                            )
                        ]
                    , viewLogs fileName model |> Html.map wrap
                    , viewErrorAlert model.parsedSchema
                    ]
            )
        |> Maybe.withDefault (div [] [])


viewLogs : String -> Model msg -> Html Msg
viewLogs filename model =
    let
        show : HtmlId
        show =
            model.parsedSchema |> Maybe.mapOrElse .show ""
    in
    SourceLogs.viewContainer
        [ SourceLogs.viewFile UiToggle show filename (model.parsedSchema |> Maybe.map .fileContent)
        , model.parsedSchema |> Maybe.andThen .lines |> Maybe.mapOrElse (viewLogsLines show) (div [] [])
        , model.parsedSchema |> Maybe.andThen .statements |> Maybe.mapOrElse (viewLogsStatements show) (div [] [])
        , model.parsedSchema |> Maybe.andThen .commands |> Maybe.mapOrElse (viewLogsCommands (model.parsedSchema |> Maybe.andThen .statements)) (div [] [])
        , viewLogsErrors (model.parsedSchema |> Maybe.andThen .schema |> Maybe.mapOrElse .errors [])
        , model.parsedSchema |> Maybe.andThen .schema |> Maybe.mapOrElse (normalizeSchema >> Ok >> SourceLogs.viewParsedSchema UiToggle show) (div [] [])
        , model.parsedSource |> Maybe.mapOrElse SourceLogs.viewError (div [] [])
        , model.parsedSource |> Maybe.mapOrElse SourceLogs.viewResult (div [] [])
        ]


viewLogsLines : HtmlId -> List SourceLine -> Html Msg
viewLogsLines show lines =
    let
        count : Int
        count =
            lines |> List.length

        pad : Int -> String
        pad =
            let
                size : Int
                size =
                    count |> String.fromInt |> String.length
            in
            \i -> i |> String.fromInt |> String.padLeft size ' '
    in
    div []
        [ div [ class "cursor-pointer", onClick (UiToggle "lines") ] [ text ("Found " ++ (count |> String.pluralize "line") ++ " in the file.") ]
        , if show == "lines" then
            div []
                (lines
                    |> List.map
                        (\line ->
                            div [ class "flex items-start" ]
                                [ pre [ class "select-none" ] [ text (pad (line.index + 1) ++ ". ") ]
                                , pre [ class "whitespace-pre font-mono" ] [ text line.text ]
                                ]
                        )
                )

          else
            div [] []
        ]


viewLogsStatements : HtmlId -> Dict Int SqlStatement -> Html Msg
viewLogsStatements show statements =
    let
        count : Int
        count =
            statements |> Dict.size

        pad : Int -> String
        pad =
            let
                size : Int
                size =
                    count |> String.fromInt |> String.length
            in
            \i -> i |> String.fromInt |> String.padLeft size ' '
    in
    div []
        [ div [ class "cursor-pointer", onClick (UiToggle "statements") ] [ text ("Found " ++ (count |> String.pluralize "SQL statement") ++ ".") ]
        , if show == "statements" then
            div []
                (statements
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map
                        (\( i, s ) ->
                            div [ class "flex items-start" ]
                                [ pre [ class "select-none" ] [ text (pad (i + 1) ++ ". ") ]
                                , pre [ class "whitespace-pre font-mono" ] [ text (buildRawSql s) ]
                                ]
                        )
                )

          else
            div [] []
        ]


viewLogsCommands : Maybe (Dict Int SqlStatement) -> Dict Int ( SqlStatement, Result (List ParseError) Command ) -> Html msg
viewLogsCommands statements commands =
    div []
        (commands
            |> Dict.toList
            |> List.sortBy (\( i, _ ) -> i)
            |> List.map (\( _, ( s, r ) ) -> r |> Result.bimap (\e -> ( s, e )) (\c -> ( s, c )))
            |> Result.partition
            |> (\( errs, cmds ) ->
                    if (cmds |> List.length) == (statements |> Maybe.mapOrElse Dict.size 0) then
                        [ div [] [ text "All statements were correctly parsed." ] ]

                    else if errs |> List.isEmpty then
                        [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed.") ] ]

                    else
                        (errs |> List.map (\( s, e ) -> viewParseError s e))
                            ++ [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed, " ++ (errs |> List.length |> String.fromInt) ++ " were in error.") ] ]
               )
        )


viewLogsErrors : List (List SqlSchemaError) -> Html msg
viewLogsErrors schemaErrors =
    if schemaErrors |> List.isEmpty then
        div [] []

    else
        div []
            ((schemaErrors |> List.map viewSchemaError)
                ++ [ div [] [ text ((schemaErrors |> List.length |> String.fromInt) ++ " statements can't be added to the schema.") ] ]
            )


normalizeSchema : SqlSchema -> { tables : List { schema : String, table : String, columns : List Column } }
normalizeSchema schema =
    { tables = schema.tables |> Dict.values |> List.map (\t -> { schema = t.schema, table = t.name, columns = t.columns |> Dict.values }) }


viewParseError : SqlStatement -> List ParseError -> Html msg
viewParseError statement errors =
    div [ class "text-red-500" ]
        (div [] [ text ("Parsing error line " ++ (1 + statement.head.index |> String.fromInt) ++ ":") ]
            :: (errors |> List.map (\error -> div [ class "pl-3" ] [ text error ]))
        )


viewSchemaError : List SqlSchemaError -> Html msg
viewSchemaError errors =
    div [ class "text-red-500" ]
        (div [] [ text "Schema error:" ]
            :: (errors |> List.map (\error -> div [ class "pl-3" ] [ text error ]))
        )


viewErrorAlert : Maybe (SqlParsing msg) -> Html msg
viewErrorAlert model =
    let
        parseErrors : List (List ParseError)
        parseErrors =
            model |> Maybe.andThen .commands |> Maybe.map (Dict.values >> List.filterMap (Tuple.second >> Result.toError)) |> Maybe.withDefault []

        schemaErrors : List (List SqlSchemaError)
        schemaErrors =
            model |> Maybe.andThen .schema |> Maybe.mapOrElse .errors []
    in
    if (parseErrors |> List.isEmpty) && (schemaErrors |> List.isEmpty) then
        div [] []

    else
        div [ class "mt-6" ]
            [ Alert.withActions
                { color = Tw.red
                , icon = XCircle
                , title = "Oh no! We had " ++ (((parseErrors |> List.length) + (schemaErrors |> List.length)) |> String.fromInt) ++ " errors."
                , actions = [ Link.light2 Tw.red [ href (sendErrorReport parseErrors schemaErrors) ] [ text "Send error report" ] ]
                }
                [ p []
                    [ text "Parsing every SQL dialect is not a trivial task. But every error report allows to improve it. "
                    , bText "Please send it"
                    , text ", you will be able to edit it if needed to remove your private information."
                    ]
                , p [] [ text "In the meantime, you can look at the errors and your schema and try to simplify it. Or just use it as is, only not recognized statements will be missing." ]
                ]
            ]


sendErrorReport : List (List ParseError) -> List (List SqlSchemaError) -> String
sendErrorReport parseErrors schemaErrors =
    let
        email : String
        email =
            Conf.constants.azimuttEmail

        subject : String
        subject =
            "[Azimutt] SQL Parser error report"

        body : String
        body =
            "Hi Azimutt team!\nGot some errors using the Azimutt SQL parser.\nHere are the details..."
                ++ (if parseErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Parsing errors -------------------------------------------------------------\n\n"
                            ++ (parseErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
                ++ (if schemaErrors |> List.isEmpty then
                        ""

                    else
                        "\n\n\n------------------------------------------------------------- Schema errors -------------------------------------------------------------\n\n"
                            ++ (schemaErrors |> List.indexedMap (\i errors -> String.fromInt (i + 1) ++ ".\n" ++ (errors |> String.join "\n")) |> String.join "\n\n")
                   )
    in
    "mailto:" ++ email ++ "?subject=" ++ percentEncode subject ++ "&body=" ++ percentEncode body



-- HELPERS


hasErrors : SqlParsing msg -> Bool
hasErrors parser =
    (parser.commands |> Maybe.any (Dict.values >> List.any (\( _, r ) -> r |> Result.isErr))) || (parser.schema |> Maybe.mapOrElse .errors [] |> List.nonEmpty)

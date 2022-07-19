module Services.SqlSource exposing (Model, Msg(..), ParsingMsg(..), SqlParsing, UiMsg, gotLocalFile, gotRemoteFile, hasErrors, init, kind, update, viewInput, viewParsing)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.FileInput as FileInput
import Components.Molecules.Tooltip as Tooltip
import Conf
import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlParser.SqlAdapter as SqlAdapter exposing (SqlSchema, SqlSchemaError)
import DataSources.SqlParser.SqlParser as SqlParser exposing (Command)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import FileValue exposing (File)
import Html exposing (Html, div, li, p, pre, span, text, ul)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw
import Libs.Task as T
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RelationId as RelationId
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Ports
import Services.Lenses exposing (mapParsedSchemaM, mapShow, setParsedSource)
import Time
import Track
import Url exposing (percentEncode)


type alias Model msg =
    { defaultSchema : SchemaName
    , source : Maybe Source
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe FileUrl
    , loadedFile : Maybe ( SourceInfo, FileContent )
    , parsedSchema : Maybe (SqlParsing msg)
    , parsedSource : Maybe Source
    , callback : ( SqlParsing msg, Source ) -> msg
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
    | SelectRemoteFile FileUrl
    | SelectLocalFile File
    | FileLoaded SourceInfo FileContent
    | ParseMsg ParsingMsg
    | UiMsg UiMsg
    | BuildSource


type ParsingMsg
    = BuildLines
    | BuildStatements
    | BuildCommand
    | EvolveSchema


type UiMsg
    = Toggle HtmlId



-- INIT


init : SchemaName -> Maybe Source -> (( SqlParsing msg, Source ) -> msg) -> Model msg
init defaultSchema source callback =
    { defaultSchema = defaultSchema
    , source = source
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


update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap msg model =
    case msg of
        UpdateRemoteFile url ->
            ( { model | selectedRemoteFile = B.cond (url == "") Nothing (Just url) }, Cmd.none )

        SelectRemoteFile url ->
            ( init model.defaultSchema model.source model.callback |> (\m -> { m | selectedRemoteFile = Just url })
            , Ports.readRemoteFile kind url Nothing
            )

        SelectLocalFile file ->
            ( init model.defaultSchema model.source model.callback |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile kind file
            )

        FileLoaded sourceInfo fileContent ->
            ( { model
                | loadedFile = Just ( sourceInfo, fileContent )
                , parsedSchema = Just (parsingInit fileContent (ParseMsg >> wrap) (BuildSource |> wrap))
              }
            , T.send (BuildLines |> ParseMsg |> wrap)
            )

        ParseMsg parseMsg ->
            Maybe.map2
                (\parsedSchema ( sourceInfo, _ ) ->
                    parsingUpdate model.defaultSchema sourceInfo.id parseMsg parsedSchema
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

        UiMsg (Toggle htmlId) ->
            ( model |> mapParsedSchemaM (mapShow (\s -> B.cond (s == htmlId) "" htmlId)), Cmd.none )

        BuildSource ->
            model.parsedSchema
                |> Maybe.andThen
                    (\parsedSchema ->
                        parsedSchema.schema
                            |> Maybe.map3 (\( sourceInfo, _ ) lines schema -> ( parsedSchema, SqlAdapter.buildSqlSource sourceInfo lines schema ))
                                model.loadedFile
                                parsedSchema.lines
                    )
                |> Maybe.map
                    (\( parsedSchema, source ) ->
                        ( model |> setParsedSource (Just source)
                        , Cmd.batch [ T.send (model.callback ( parsedSchema, source )), Ports.track (Track.parsedSQLSource parsedSchema source) ]
                        )
                    )
                |> Maybe.withDefault ( model, Cmd.none )


parsingUpdate : SchemaName -> SourceId -> ParsingMsg -> SqlParsing msg -> ( SqlParsing msg, msg )
parsingUpdate defaultSchema sourceId msg model =
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
                                    |> SqlAdapter.evolve defaultSchema sourceId ( statement, cmd )
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



-- SUBSCRIPTIONS


kind : String
kind =
    "sql-source"


gotLocalFile : Time.Posix -> SourceId -> File -> FileContent -> Msg
gotLocalFile now sourceId file content =
    FileLoaded (SourceInfo.sqlLocal now sourceId file) content


gotRemoteFile : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> Msg
gotRemoteFile now sourceId url content sample =
    FileLoaded (SourceInfo.sqlRemote now sourceId url content sample) content



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
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your SQL schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".sql file only" ]
                ]
        , mimes = [ ".sql" ]
        }


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    ((model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file"))
        |> Maybe.orElse (model.selectedRemoteFile |> Maybe.map (\u -> u ++ " file"))
    )
        |> Maybe.map2
            (\parsedSchema fileName ->
                div []
                    [ div [ class "mt-6" ] [ Divider.withLabel (model.parsedSource |> Maybe.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                    , viewLogs wrap model.defaultSchema fileName parsedSchema
                    , viewErrorAlert parsedSchema
                    , model.source |> Maybe.map2 (viewSourceDiff model.defaultSchema) model.parsedSource |> Maybe.withDefault (div [] [])
                    ]
            )
            model.parsedSchema
        |> Maybe.withDefault (div [] [])


viewLogs : (Msg -> msg) -> SchemaName -> String -> SqlParsing msg -> Html msg
viewLogs wrap defaultSchema filename model =
    div [ class "mt-6 px-4 py-2 max-h-96 overflow-y-auto font-mono text-xs bg-gray-50 shadow rounded-lg" ]
        [ viewLogsFile wrap model.show filename model.fileContent
        , model.lines |> Maybe.mapOrElse (viewLogsLines wrap model.show) (div [] [])
        , model.statements |> Maybe.mapOrElse (viewLogsStatements wrap model.show) (div [] [])
        , model.commands |> Maybe.mapOrElse (viewLogsCommands model.statements) (div [] [])
        , viewLogsErrors (model.schema |> Maybe.mapOrElse .errors [])
        , model.schema |> Maybe.mapOrElse (viewLogsSchema wrap defaultSchema model.show) (div [] [])
        ]


viewLogsFile : (Msg -> msg) -> HtmlId -> String -> FileContent -> Html msg
viewLogsFile wrap show filename content =
    div []
        [ div [ class "cursor-pointer", onClick (wrap (UiMsg (Toggle "file"))) ] [ text ("Loaded " ++ filename ++ ".") ]
        , if show == "file" then
            div [] [ pre [ class "whitespace-pre font-mono" ] [ text content ] ]

          else
            div [] []
        ]


viewLogsLines : (Msg -> msg) -> HtmlId -> List SourceLine -> Html msg
viewLogsLines wrap show lines =
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
        [ div [ class "cursor-pointer", onClick (wrap (UiMsg (Toggle "lines"))) ] [ text ("Found " ++ (count |> String.pluralize "line") ++ " in the file.") ]
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


viewLogsStatements : (Msg -> msg) -> HtmlId -> Dict Int SqlStatement -> Html msg
viewLogsStatements wrap show statements =
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
        [ div [ class "cursor-pointer", onClick (wrap (UiMsg (Toggle "statements"))) ] [ text ("Found " ++ (count |> String.pluralize "SQL statement") ++ ".") ]
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


viewLogsSchema : (Msg -> msg) -> SchemaName -> HtmlId -> SqlSchema -> Html msg
viewLogsSchema wrap defaultSchema htmlId schema =
    let
        count : Int
        count =
            schema.tables |> Dict.size

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
        [ div [ class "cursor-pointer", onClick (wrap (UiMsg (Toggle "tables"))) ] [ text ("Schema built with " ++ (count |> String.pluralize "table") ++ ".") ]
        , if htmlId == "tables" then
            div []
                (schema.tables
                    |> Dict.values
                    |> List.sortBy (\t -> TableId.toString t.id)
                    |> List.indexedMap
                        (\i t ->
                            div [ class "flex items-start" ]
                                [ pre [ class "select-none" ] [ text (pad (i + 1) ++ ". ") ]
                                , pre [ class "whitespace-pre font-mono" ] [ text (TableId.show defaultSchema t.id) ]
                                ]
                        )
                )

          else
            div [] []
        ]


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


viewErrorAlert : SqlParsing msg -> Html msg
viewErrorAlert model =
    let
        parseErrors : List (List ParseError)
        parseErrors =
            model.commands |> Maybe.map (Dict.values >> List.filterMap (Tuple.second >> Result.toError)) |> Maybe.withDefault []

        schemaErrors : List (List SqlSchemaError)
        schemaErrors =
            model.schema |> Maybe.mapOrElse .errors []
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


viewSourceDiff : SchemaName -> Source -> Source -> Html msg
viewSourceDiff defaultSchema newSource oldSource =
    let
        ( removedTables, updatedTables, newTables ) =
            List.diff .id (oldSource.tables |> Dict.values |> List.map Table.clearOrigins) (newSource.tables |> Dict.values |> List.map Table.clearOrigins)

        ( removedRelations, updatedRelations, newRelations ) =
            List.diff .id (oldSource.relations |> List.map Relation.clearOrigins) (newSource.relations |> List.map Relation.clearOrigins)
    in
    if List.nonEmpty updatedTables || List.nonEmpty newTables || List.nonEmpty removedTables || List.nonEmpty updatedRelations || List.nonEmpty newRelations || List.nonEmpty removedRelations then
        div [ class "mt-3" ]
            [ Alert.withDescription { color = Tw.green, icon = CheckCircle, title = "Source parsed, here are the changes:" }
                [ ul [ class "list-disc list-inside" ]
                    ([ viewSourceDiffItem "modified table" (updatedTables |> List.map (\( old, new ) -> ( TableId.show defaultSchema new.id, tableDiff old new )))
                     , viewSourceDiffItem "new table" (newTables |> List.map (\t -> ( TableId.show defaultSchema t.id, Nothing )))
                     , viewSourceDiffItem "removed table" (removedTables |> List.map (\t -> ( TableId.show defaultSchema t.id, Nothing )))
                     , viewSourceDiffItem "modified relation" (updatedRelations |> List.map (\( old, new ) -> ( RelationId.show defaultSchema new.id, relationDiff old new )))
                     , viewSourceDiffItem "new relation" (newRelations |> List.map (\r -> ( RelationId.show defaultSchema r.id, Nothing )))
                     , viewSourceDiffItem "removed relation" (removedRelations |> List.map (\r -> ( RelationId.show defaultSchema r.id, Nothing )))
                     ]
                        |> List.filterMap identity
                    )
                ]
            ]

    else
        div [ class "mt-3" ]
            [ Alert.withDescription { color = Tw.green, icon = CheckCircle, title = "Source parsed" }
                [ text "There is no differences but you can still refresh the source to change the last updated date." ]
            ]


viewSourceDiffItem : String -> List ( String, Maybe String ) -> Maybe (Html msg)
viewSourceDiffItem label items =
    items
        |> List.head
        |> Maybe.map
            (\_ ->
                li []
                    [ bText (items |> String.pluralizeL label)
                    , text " ("
                    , span [] (items |> List.map (\( item, details ) -> text item |> Tooltip.t (details |> Maybe.withDefault "")) |> List.intersperse (text ", "))
                    , text ")"
                    ]
            )



-- HELPERS


hasErrors : SqlParsing msg -> Bool
hasErrors parser =
    (parser.commands |> Maybe.any (Dict.values >> List.any (\( _, r ) -> r |> Result.isErr))) || (parser.schema |> Maybe.mapOrElse .errors [] |> List.nonEmpty)


tableDiff : Table -> Table -> Maybe String
tableDiff old new =
    let
        ( removedColumns, updatedColumns, newColumns ) =
            List.diff .name (old.columns |> Dict.values) (new.columns |> Dict.values)

        primaryKey : Bool
        primaryKey =
            old.primaryKey /= new.primaryKey

        ( removedUniques, updatedUniques, newUniques ) =
            List.diff .name old.uniques new.uniques

        ( removedIndexes, updatedIndexes, newIndexes ) =
            List.diff .name old.indexes new.indexes

        ( removedChecks, updatedChecks, newChecks ) =
            List.diff .name old.checks new.checks

        comment : Bool
        comment =
            old.comment /= new.comment
    in
    [ newColumns |> List.head |> Maybe.map (\_ -> (newColumns |> String.pluralizeL "new column") ++ ": " ++ (newColumns |> List.map .name |> String.join ", "))
    , removedColumns |> List.head |> Maybe.map (\_ -> (removedColumns |> String.pluralizeL "removed column") ++ ": " ++ (removedColumns |> List.map .name |> String.join ", "))
    , updatedColumns |> List.head |> Maybe.map (\_ -> (updatedColumns |> String.pluralizeL "updated column") ++ ": " ++ (updatedColumns |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , B.maybe primaryKey "primary key updated"
    , newUniques |> List.head |> Maybe.map (\_ -> (newUniques |> String.pluralizeL "new unique") ++ ": " ++ (newUniques |> List.map .name |> String.join ", "))
    , removedUniques |> List.head |> Maybe.map (\_ -> (removedUniques |> String.pluralizeL "removed unique") ++ ": " ++ (removedUniques |> List.map .name |> String.join ", "))
    , updatedUniques |> List.head |> Maybe.map (\_ -> (updatedUniques |> String.pluralizeL "updated unique") ++ ": " ++ (updatedUniques |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , newIndexes |> List.head |> Maybe.map (\_ -> (newIndexes |> String.pluralizeL "new index") ++ ": " ++ (newIndexes |> List.map .name |> String.join ", "))
    , removedIndexes |> List.head |> Maybe.map (\_ -> (removedIndexes |> String.pluralizeL "removed index") ++ ": " ++ (removedIndexes |> List.map .name |> String.join ", "))
    , updatedIndexes |> List.head |> Maybe.map (\_ -> (updatedIndexes |> String.pluralizeL "updated index") ++ ": " ++ (updatedIndexes |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , newChecks |> List.head |> Maybe.map (\_ -> (newChecks |> String.pluralizeL "new check") ++ ": " ++ (newChecks |> List.map .name |> String.join ", "))
    , removedChecks |> List.head |> Maybe.map (\_ -> (removedChecks |> String.pluralizeL "removed check") ++ ": " ++ (removedChecks |> List.map .name |> String.join ", "))
    , updatedChecks |> List.head |> Maybe.map (\_ -> (updatedChecks |> String.pluralizeL "updated check") ++ ": " ++ (updatedChecks |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , B.maybe comment "comment updated"
    ]
        |> List.filterMap identity
        |> String.join ", "
        |> String.maybeNonEmpty


relationDiff : Relation -> Relation -> Maybe String
relationDiff old new =
    let
        name : Bool
        name =
            old.name /= new.name
    in
    [ B.maybe name "name updated"
    ]
        |> List.filterMap identity
        |> String.join ", "
        |> String.maybeNonEmpty

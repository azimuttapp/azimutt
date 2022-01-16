module Services.SQLSource exposing (ParsingMsg(..), SQLParsing, SQLSource, SQLSourceMsg(..), gotLocalFile, gotRemoteFile, init, update, viewParsing)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Conf
import DataSources.SqlParser.FileParser as FileParser exposing (SchemaError, SqlSchema)
import DataSources.SqlParser.ProjectAdapter as ProjectAdapter
import DataSources.SqlParser.StatementParser exposing (Command)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, li, p, span, text, ul)
import Html.Styled.Attributes exposing (css, href)
import Libs.Bool as B
import Libs.Dict as D
import Libs.FileInput exposing (File)
import Libs.Html.Styled exposing (bText)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, FileLineContent)
import Libs.Models.Color as Color
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Result as R
import Libs.String as S
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId as RelationId
import Models.Project.SampleName exposing (SampleKey)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId
import Models.SourceInfo exposing (SourceInfo)
import Ports
import Tailwind.Utilities as Tw
import Time
import Track
import Url exposing (percentEncode)


type alias SQLSource msg =
    { project : Maybe Project
    , source : Maybe Source
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe FileUrl
    , selectedSample : Maybe String
    , loadedFile : Maybe ( ProjectId, SourceInfo, FileContent )
    , parsedSchema : Maybe (SQLParsing msg)
    , parsedSource : Maybe Source
    }


type alias SQLParsing msg =
    { cpt : Int
    , fileContent : FileContent
    , lines : Maybe (List FileLineContent)
    , statements : Maybe (Dict Int SqlStatement)
    , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
    , schemaIndex : Int
    , schemaErrors : List (List SchemaError)
    , schema : Maybe SqlSchema
    , buildMsg : ParsingMsg -> msg
    , buildProject : msg
    }


type SQLSourceMsg
    = SelectLocalFile File
    | SelectRemoteFile FileUrl
    | SelectSample String
    | FileLoaded ProjectId SourceInfo FileContent
    | ParseMsg ParsingMsg
    | BuildSource


type ParsingMsg
    = BuildLines
    | BuildStatements
    | BuildCommand
    | EvolveSchema



-- INIT


init : Maybe Project -> Maybe Source -> SQLSource msg
init project source =
    { project = project
    , source = source
    , selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , selectedSample = Nothing
    , loadedFile = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    }


parsingInit : FileContent -> (ParsingMsg -> msg) -> msg -> SQLParsing msg
parsingInit fileContent buildMsg buildProject =
    { cpt = 0
    , fileContent = fileContent
    , lines = Nothing
    , statements = Nothing
    , commands = Nothing
    , schemaIndex = 0
    , schemaErrors = []
    , schema = Nothing
    , buildMsg = buildMsg
    , buildProject = buildProject
    }



-- UPDATE


update : SQLSourceMsg -> (SQLSourceMsg -> msg) -> SQLSource msg -> ( SQLSource msg, Cmd msg )
update msg wrap model =
    case msg of
        SelectLocalFile file ->
            ( init model.project model.source |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile (model.project |> Maybe.map .id) (model.source |> Maybe.map .id) file
            )

        SelectRemoteFile url ->
            ( init model.project model.source |> (\m -> { m | selectedRemoteFile = Just url })
            , Ports.readRemoteFile (model.project |> Maybe.map .id) (model.source |> Maybe.map .id) url Nothing
            )

        SelectSample sample ->
            ( init model.project model.source |> (\m -> { m | selectedSample = Just sample })
            , Conf.schemaSamples |> Dict.get sample |> Maybe.map (\s -> Ports.readRemoteFile (model.project |> Maybe.map .id) (model.source |> Maybe.map .id) s.url (Just s.key)) |> Maybe.withDefault Cmd.none
            )

        FileLoaded projectId sourceInfo fileContent ->
            ( { model
                | loadedFile = Just ( projectId, sourceInfo, fileContent )
                , parsedSchema = Just (parsingInit fileContent (ParseMsg >> wrap) (BuildSource |> wrap))
              }
            , T.send (BuildLines |> ParseMsg |> wrap)
            )

        ParseMsg parseMsg ->
            model.parsedSchema
                |> Maybe.map
                    (\p ->
                        p
                            |> parsingUpdate parseMsg
                            |> (\( parsed, message ) ->
                                    ( { model | parsedSchema = Just parsed }
                                      -- 342 is an arbitrary number to break Elm message batching
                                      -- not too often to not increase compute time too much, not too scarce to not freeze the browser
                                    , B.cond ((parsed.cpt |> modBy 342) == 1) (T.sendAfter 1 message) (T.send message)
                                    )
                               )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        BuildSource ->
            model.parsedSchema
                |> Maybe.andThen (\parsedSchema -> parsedSchema.schema |> Maybe.map3 (\( _, sourceInfo, _ ) lines schema -> ( parsedSchema, ProjectAdapter.buildSourceFromSql sourceInfo lines schema )) model.loadedFile parsedSchema.lines)
                |> Maybe.map (\( parsedSchema, source ) -> ( { model | parsedSource = Just source }, Ports.track (Track.parsedSource parsedSchema source) ))
                |> Maybe.withDefault ( model, Cmd.none )


parsingUpdate : ParsingMsg -> SQLParsing msg -> ( SQLParsing msg, msg )
parsingUpdate msg model =
    (case msg of
        BuildLines ->
            ( { model | lines = model.fileContent |> FileParser.parseLines |> Just }, model.buildMsg BuildStatements )

        BuildStatements ->
            model.lines |> M.mapOrElse (\l -> l |> FileParser.parseStatements |> (\statements -> ( { model | statements = statements |> D.fromIndexedList |> Just }, model.buildMsg BuildCommand ))) ( model, model.buildMsg BuildStatements )

        BuildCommand ->
            let
                index : Int
                index =
                    model.commands |> Maybe.withDefault Dict.empty |> Dict.size
            in
            model.statements
                |> Maybe.withDefault Dict.empty
                |> Dict.get index
                |> Maybe.map (\s -> ( { model | commands = model.commands |> Maybe.withDefault Dict.empty |> Dict.insert index ( s, s |> FileParser.parseCommand ) |> Just }, model.buildMsg BuildCommand ))
                |> Maybe.withDefault ( model, model.buildMsg EvolveSchema )

        EvolveSchema ->
            model.commands
                |> Maybe.withDefault Dict.empty
                |> Dict.get model.schemaIndex
                |> Maybe.map
                    (\( s, c ) ->
                        case c of
                            Ok cmd ->
                                case model.schema |> Maybe.withDefault Dict.empty |> FileParser.evolve ( s, cmd ) of
                                    Ok schema ->
                                        ( { model | schemaIndex = model.schemaIndex + 1, schema = Just schema }, model.buildMsg EvolveSchema )

                                    Err errors ->
                                        ( { model | schemaIndex = model.schemaIndex + 1, schemaErrors = errors :: model.schemaErrors }, model.buildMsg EvolveSchema )

                            Err _ ->
                                ( { model | schemaIndex = model.schemaIndex + 1 }, model.buildMsg EvolveSchema )
                    )
                |> Maybe.withDefault ( model, model.buildProject )
    )
        |> Tuple.mapFirst parsingCptInc


parsingCptInc : SQLParsing msg -> SQLParsing msg
parsingCptInc model =
    { model | cpt = model.cpt + 1 }



-- SUBSCRIPTIONS


gotLocalFile : Time.Posix -> ProjectId -> SourceId -> File -> FileContent -> SQLSourceMsg
gotLocalFile now projectId sourceId file content =
    FileLoaded projectId (SourceInfo sourceId (lastSegment file.name) (localSource file) True Nothing now now) content


gotRemoteFile : Time.Posix -> ProjectId -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SQLSourceMsg
gotRemoteFile now projectId sourceId url content sample =
    FileLoaded projectId (SourceInfo sourceId (lastSegment url) (remoteSource url content) True sample now now) content


localSource : File -> SourceKind
localSource file =
    LocalFile file.name file.size file.lastModified


remoteSource : FileUrl -> FileContent -> SourceKind
remoteSource url content =
    RemoteFile url (String.length content)


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path



-- VIEW


viewParsing : SQLSource msg -> Html msg
viewParsing model =
    div []
        (((model.selectedLocalFile |> Maybe.map (\f -> f.name ++ " file"))
            |> M.orElse (model.selectedRemoteFile |> Maybe.map (\u -> u ++ " file"))
            |> M.orElse (model.selectedSample |> Maybe.map (\s -> s ++ " sample"))
         )
            |> Maybe.map2
                (\parsedSchema sourceText ->
                    [ div [ css [ Tw.mt_6 ] ] [ Divider.withLabel (model.parsedSource |> M.mapOrElse (\_ -> "Parsed!") "Parsing ...") ]
                    , viewLogs sourceText parsedSchema
                    , viewErrorAlert parsedSchema
                    , model.source |> Maybe.map2 viewSourceDiff model.parsedSource |> Maybe.withDefault (div [] [])
                    ]
                )
                model.parsedSchema
            |> Maybe.withDefault []
        )


viewLogs : String -> SQLParsing msg -> Html msg
viewLogs source model =
    div [ css [ Tw.mt_6, Tw.px_4, Tw.py_2, Tw.max_h_96, Tw.overflow_y_auto, Tw.font_mono, Tw.text_xs, Tw.bg_gray_50, Tw.shadow, Tw.rounded_lg ] ]
        ([ div [] [ text ("Loaded " ++ source ++ ".") ] ]
            ++ (model.lines |> M.mapOrElse (\l -> [ div [] [ text ("Found " ++ (l |> List.length |> String.fromInt) ++ " lines in the file.") ] ]) [])
            ++ (model.statements |> M.mapOrElse (\s -> [ div [] [ text ("Found " ++ (s |> Dict.size |> String.fromInt) ++ " SQL statements.") ] ]) [])
            ++ (model.commands
                    |> M.mapOrElse
                        (\commands ->
                            commands
                                |> Dict.toList
                                |> List.sortBy (\( i, _ ) -> i)
                                |> List.map (\( _, ( s, r ) ) -> r |> R.bimap (\e -> ( s, e )) (\c -> ( s, c )))
                                |> R.partition
                                |> (\( errs, cmds ) ->
                                        if (cmds |> List.length) == (model.statements |> M.mapOrElse Dict.size 0) then
                                            [ div [] [ text "All statements were correctly parsed." ] ]

                                        else if errs |> List.isEmpty then
                                            [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed.") ] ]

                                        else
                                            (errs |> List.map (\( s, e ) -> viewParseError s e))
                                                ++ [ div [] [ text ((cmds |> List.length |> String.fromInt) ++ " statements were correctly parsed, " ++ (errs |> List.length |> String.fromInt) ++ " were in error.") ] ]
                                   )
                        )
                        []
               )
            ++ (if model.schemaErrors |> List.isEmpty then
                    []

                else
                    (model.schemaErrors |> List.map viewSchemaError) ++ [ div [] [ text ((model.schemaErrors |> List.length |> String.fromInt) ++ " statements can't be added to the schema.") ] ]
               )
            ++ (model.schema |> M.mapOrElse (\s -> [ div [] [ text ("Schema built with " ++ (s |> Dict.size |> String.fromInt) ++ " tables.") ] ]) [])
        )


viewParseError : SqlStatement -> List ParseError -> Html msg
viewParseError statement errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text ("Paring error line " ++ (statement.head.line |> String.fromInt) ++ ":") ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewSchemaError : List SchemaError -> Html msg
viewSchemaError errors =
    div [ css [ Tw.text_red_500 ] ]
        (div [] [ text "Schema error:" ]
            :: (errors |> List.map (\error -> div [ css [ Tw.pl_3 ] ] [ text error ]))
        )


viewErrorAlert : SQLParsing msg -> Html msg
viewErrorAlert model =
    let
        parseErrors : List (List ParseError)
        parseErrors =
            model.commands |> Maybe.map (Dict.values >> List.filterMap (\( _, r ) -> r |> R.toErrMaybe)) |> Maybe.withDefault []
    in
    if (parseErrors |> List.isEmpty) && (model.schemaErrors |> List.isEmpty) then
        div [] []

    else
        div [ css [ Tw.mt_6 ] ]
            [ Alert.withActions
                { color = Color.red
                , icon = XCircle
                , title = "Oh no! We had " ++ (((parseErrors |> List.length) + (model.schemaErrors |> List.length)) |> String.fromInt) ++ " errors."
                , actions = [ Link.light2 Color.red [ href (sendErrorReport parseErrors model.schemaErrors) ] [ text "Send error report" ] ]
                }
                [ p []
                    [ text "Parsing every SQL dialect is not a trivial task. But every error report allows to improve it. "
                    , bText "Please send it"
                    , text ", you will be able to edit it if needed to remove your private information."
                    ]
                , p [] [ text "In the meantime, you can look at the errors and your schema and try to simplify it. Or just use it as is, only not recognized statements will be missing." ]
                ]
            ]


sendErrorReport : List (List ParseError) -> List (List SchemaError) -> String
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


viewSourceDiff : Source -> Source -> Html msg
viewSourceDiff newSource oldSource =
    let
        ( removedTables, existingTables, newTables ) =
            L.zipBy .id (oldSource.tables |> Dict.values) (newSource.tables |> Dict.values)

        updatedTables : List ( Table, Table )
        updatedTables =
            existingTables |> List.filter (\( oldTable, newTable ) -> oldTable /= newTable)

        ( removedRelations, existingRelations, newRelations ) =
            L.zipBy .id oldSource.relations newSource.relations

        updatedRelations : List ( Relation, Relation )
        updatedRelations =
            existingRelations |> List.filter (\( oldRelation, newRelation ) -> oldRelation /= newRelation)
    in
    if L.nonEmpty updatedTables || L.nonEmpty newTables || L.nonEmpty removedTables || L.nonEmpty updatedRelations || L.nonEmpty newRelations || L.nonEmpty removedRelations then
        div [ css [ Tw.mt_3 ] ]
            [ Alert.withDescription { color = Color.green, icon = CheckCircle, title = "Source parsed, here are the changes:" }
                [ ul [ css [ Tw.list_disc, Tw.list_inside ] ]
                    ([ viewSourceDiffItem "modified table" (updatedTables |> List.map (\( _, t ) -> TableId.show t.id))
                     , viewSourceDiffItem "new table" (newTables |> List.map (\t -> TableId.show t.id))
                     , viewSourceDiffItem "removed table" (removedTables |> List.map (\t -> TableId.show t.id))
                     , viewSourceDiffItem "modified relation" (updatedRelations |> List.map (\( _, r ) -> RelationId.show r.id))
                     , viewSourceDiffItem "new relation" (newRelations |> List.map (\r -> RelationId.show r.id))
                     , viewSourceDiffItem "removed relation" (removedRelations |> List.map (\r -> RelationId.show r.id))
                     ]
                        |> List.filterMap identity
                    )
                ]
            ]

    else
        div [ css [ Tw.mt_3 ] ]
            [ Alert.withDescription { color = Color.green, icon = CheckCircle, title = "Source parsed" }
                [ text "There is no differences but you can still refresh the source to change the last updated date." ]
            ]


viewSourceDiffItem : String -> List String -> Maybe (Html msg)
viewSourceDiffItem label items =
    items
        |> List.head
        |> Maybe.map
            (\_ ->
                li []
                    [ bText (items |> S.pluralizeL label)
                    , text " ("
                    , span [] (items |> List.map (\item -> span [] [ text item ]) |> List.intersperse (text ", "))
                    , text ")"
                    ]
            )

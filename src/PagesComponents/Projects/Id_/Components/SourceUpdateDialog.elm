module PagesComponents.Projects.Id_.Components.SourceUpdateDialog exposing (Model, Msg(..), init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.Modal as Modal
import Conf
import DataSources.DatabaseSchemaParser.DatabaseAdapter as DatabaseAdapter
import Html exposing (Html, br, div, h3, input, li, p, span, text, ul)
import Html.Attributes exposing (class, disabled, id, name, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Libs.DateTime as DateTime
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css, role)
import Libs.Http as Http
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Random
import Services.Backend as Backend exposing (BackendUrl)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSource, mapJsonSourceCmd, mapM, mapMCmd, mapSqlSourceCmd, setStatus, setUrl)
import Services.SqlSource as SqlSource
import Time


type alias Model msg =
    { id : HtmlId
    , sqlSource : SqlSource.Model msg
    , databaseSource : DatabaseSource.Model
    , jsonSource : JsonSource.Model msg
    }


type Msg
    = Open (Maybe Source)
    | Close
    | SqlSourceMsg SqlSource.Msg
    | DatabaseSourceMsg DatabaseSource.Msg
    | JsonSourceMsg JsonSource.Msg


init : (String -> msg) -> SchemaName -> Maybe Source -> Model msg
init noop defaultSchema source =
    { id = Conf.ids.sourceUpdateDialog
    , sqlSource = SqlSource.init defaultSchema source (\_ -> noop "project-settings-sql-source-parsed")
    , databaseSource = DatabaseSource.init source
    , jsonSource = JsonSource.init source (\_ -> noop "project-settings-json-source-parsed")
    }


update : (Msg -> msg) -> (Source -> msg) -> (HtmlId -> msg) -> (String -> msg) -> Time.Posix -> BackendUrl -> SchemaName -> Msg -> Maybe (Model msg) -> ( Maybe (Model msg), Cmd msg )
update wrap sourceSet modalOpen noop now backendUrl defaultSchema msg model =
    case msg of
        Open source ->
            ( Just (init noop defaultSchema source), T.sendAfter 1 (modalOpen Conf.ids.sourceUpdateDialog) )

        Close ->
            ( Nothing, Cmd.none )

        SqlSourceMsg message ->
            model |> mapMCmd (mapSqlSourceCmd (SqlSource.update (SqlSourceMsg >> wrap) message))

        DatabaseSourceMsg (DatabaseSource.UpdateUrl url) ->
            ( model |> mapM (mapDatabaseSource (setUrl url)), Cmd.none )

        DatabaseSourceMsg (DatabaseSource.FetchSchema url) ->
            ( model |> mapM (mapDatabaseSource (setStatus (DatabaseSource.Fetching url)))
            , Backend.getDatabaseSchema backendUrl url (DatabaseSource.GotSchema url >> DatabaseSourceMsg >> wrap)
            )

        DatabaseSourceMsg (DatabaseSource.GotSchema url result) ->
            ( model, Random.generate (DatabaseSource.GotSchemaWithId url result >> DatabaseSourceMsg >> wrap) SourceId.generator )

        DatabaseSourceMsg (DatabaseSource.GotSchemaWithId url result sourceId) ->
            ( model
                |> mapM
                    (mapDatabaseSource
                        (\db ->
                            db
                                |> setStatus
                                    (result
                                        |> Result.fold (Http.errorToString >> DatabaseSource.Error)
                                            (DatabaseAdapter.buildDatabaseSource now (db.source |> Maybe.mapOrElse .id sourceId) url >> DatabaseSource.Success)
                                    )
                        )
                    )
            , Cmd.none
            )

        DatabaseSourceMsg DatabaseSource.DropSchema ->
            ( model |> mapM (mapDatabaseSource (setStatus DatabaseSource.Pending)), Cmd.none )

        DatabaseSourceMsg (DatabaseSource.CreateProject source) ->
            ( model, T.send (sourceSet source) )

        JsonSourceMsg message ->
            model |> mapMCmd (mapJsonSourceCmd (JsonSource.update (JsonSourceMsg >> wrap) message))


view : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> (String -> msg) -> Time.Zone -> Time.Posix -> Bool -> Model msg -> Html msg
view wrap sourceSet modalClose noop zone now opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        close : msg
        close =
            Close |> wrap |> modalClose
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = close
        }
        (model.sqlSource.source
            |> Maybe.mapOrElse
                (\source ->
                    case source.kind of
                        SqlFileLocal filename _ updatedAt ->
                            sqlLocalFileModal wrap sourceSet close noop zone now titleId source filename updatedAt model.sqlSource

                        SqlFileRemote url _ ->
                            sqlRemoteFileModal wrap sourceSet close zone now titleId source url model.sqlSource

                        DatabaseConnection url ->
                            databaseModal wrap sourceSet close zone now (model.id ++ "-database") titleId source url model.databaseSource

                        JsonFileLocal filename _ updatedAt ->
                            sqlLocalFileModal wrap sourceSet close noop zone now titleId source filename updatedAt model.sqlSource

                        JsonFileRemote url _ ->
                            sqlRemoteFileModal wrap sourceSet close zone now titleId source url model.sqlSource

                        AmlEditor ->
                            userDefinedModal close titleId
                )
                (newSourceModal wrap sourceSet close noop titleId model.sqlSource)
        )


sqlLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SqlSource.Model msg -> List (Html msg)
sqlLocalFileModal wrap sourceSet close noop zone now titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text "This source came from the "
                    , bText (DateTime.formatDate zone updatedAt)
                    , text " version of "
                    , bText fileName
                    , text (" file (" ++ (updatedAt |> DateTime.human now) ++ ").")
                    , br [] []
                    , text "Please upload its new version to update the source."
                    ]
                ]
            ]
        , div [ class "mt-3" ] [ SqlSource.viewInput "file-upload" (SqlSource.SelectLocalFile >> SqlSourceMsg >> wrap) (noop "update-source-local-file") ]
        , case ( source.kind, model.loadedFile |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( SqlFileLocal name1 _ updated1, Just (SqlFileLocal name2 _ updated2) ) ->
                [ Just [ text "Your file name changed from ", bText name1, text " to ", bText name2 ] |> Maybe.filter (\_ -> name1 /= name2)
                , Just [ text "You file is ", bText "older", text " than the previous one" ] |> Maybe.filter (\_ -> updated1 |> DateTime.greaterThan updated2)
                ]
                    |> List.filterMap identity
                    |> (\warnings ->
                            if warnings == [] then
                                div [] []

                            else
                                div [ class "mt-3" ]
                                    [ Alert.withDescription { color = Tw.yellow, icon = Exclamation, title = "Found some strange things" }
                                        [ ul [ role "list", class "list-disc list-inside" ] (warnings |> List.map (li []))
                                        ]
                                    ]
                       )

            _ ->
                div [] []
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (model.parsedSource |> Maybe.map sourceSet) "Update source"
        , closeBtn close
        ]
    ]


sqlRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> SqlSource.Model msg -> List (Html msg)
sqlRemoteFileModal wrap sourceSet close zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text "This source came from "
                    , bText fileUrl
                    , text " which was fetched the "
                    , bText (DateTime.formatDate zone source.updatedAt)
                    , text (" (" ++ (source.updatedAt |> DateTime.human now) ++ ").")
                    , br [] []
                    , text "Click on the button to fetch it again now."
                    ]
                ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (fileUrl |> SqlSource.SelectRemoteFile |> SqlSourceMsg >> wrap) ] [ text "Fetch file again" ]
            ]
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (model.parsedSource |> Maybe.map sourceSet) "Update source"
        , closeBtn close
        ]
    ]


databaseModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> DatabaseUrl -> DatabaseSource.Model -> List (Html msg)
databaseModal wrap sourceSet close zone now htmlId titleId source url model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text ("Refresh " ++ source.name ++ " source") ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text "This source came from "
                    , bText url
                    , text " which was fetched the "
                    , bText (DateTime.formatDate zone source.updatedAt)
                    , text (" (" ++ (source.updatedAt |> DateTime.human now) ++ ").")
                    , br [] []
                    , text "Click on the button to fetch it again now."
                    ]
                ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (DatabaseSource.FetchSchema url |> DatabaseSourceMsg |> wrap) ] [ text "Fetch schema again" ]
            ]
        , DatabaseSource.view (htmlId ++ "-source") model |> Html.map (DatabaseSourceMsg >> wrap)
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (model |> DatabaseSource.source |> Maybe.map sourceSet) "Update source"
        , closeBtn close
        ]
    ]


userDefinedModal : msg -> HtmlId -> List (Html msg)
userDefinedModal close titleId =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "This is a user source, it can't be refreshed!" ]
            ]
        , p [ class "mt-3" ]
            [ text """A user source is a source created by a user to add some information to the project.
                      For example relations, tables, columns or documentation that are useful and not present in the sources.
                      So it doesn't make sense to refresh it (not out of sync), just edit or delete it if needed."""
            , br [] []
            , text "You should not see this, so if you came here normally, this is a bug. Please help us and "
            , extLink Conf.constants.azimuttBugReport [ class "link" ] [ text "report it" ]
            , text ". What would be useful to fix it is what steps you did to get here."
            ]
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (close |> Just) "Close"
        ]
    ]


newSourceModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> HtmlId -> SqlSource.Model msg -> List (Html msg)
newSourceModal wrap sourceSet close noop titleId model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ]
                [ text "Add a source" ]
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text """A project can have several sources. They are independent and merged together when enabled to build the usable schema.
                      It's a great way to explore multiple database at once or create isolated schema evolutions."""
                    ]
                ]
            ]
        , div [ class "mt-3" ] [ SqlSource.viewInput "file-upload" (SqlSource.SelectLocalFile >> SqlSourceMsg >> wrap) (noop "new-source-local-file") ]
        , div [ class "my-3" ] [ Divider.withLabel "OR" ]
        , div [ class "flex rounded-md shadow-sm" ]
            [ span [ class "inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm" ] [ text "Remote schema" ]
            , input
                [ type_ "text"
                , id "file-remote"
                , name "file-remote"
                , placeholder "https://azimutt.app/samples/gospeak.sql"
                , value (model.selectedRemoteFile |> Maybe.withDefault "")
                , onInput (SqlSource.UpdateRemoteFile >> SqlSourceMsg >> wrap)
                , onBlur (model.selectedRemoteFile |> Maybe.mapOrElse (SqlSource.SelectRemoteFile >> SqlSourceMsg >> wrap) (noop "new-source-remote-file"))
                , class "flex-1 min-w-0 block w-full px-3 py-2 border-gray-300 rounded-none rounded-r-md sm:text-sm focus:ring-indigo-500 focus:border-indigo-500"
                ]
                []
            ]
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        ]
    , div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (model.parsedSource |> Maybe.map sourceSet) "Add source"
        , closeBtn close
        ]
    ]



-- HELPERS


primaryBtn : Maybe msg -> String -> Html msg
primaryBtn clicked label =
    Button.primary3 Tw.primary (clicked |> Maybe.mapOrElse (\c -> [ onClick c ]) [ disabled True ]) [ text label ]


closeBtn : msg -> Html msg
closeBtn close =
    Button.white3 Tw.gray [ onClick close ] [ text "Close" ]

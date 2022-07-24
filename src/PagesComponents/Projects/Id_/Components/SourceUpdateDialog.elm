module PagesComponents.Projects.Id_.Components.SourceUpdateDialog exposing (Model, Msg(..), Tab, init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, br, div, h3, li, p, text, ul)
import Html.Attributes exposing (class, disabled, id)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.DateTime as DateTime
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css, role)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceCmd, mapJsonSourceCmd, mapMCmd, mapSqlSourceCmd)
import Services.SourceDiff as SourceDiff
import Services.SqlSource as SqlSource
import Time


type alias Model msg =
    { id : HtmlId
    , source : Maybe Source
    , sqlSource : SqlSource.Model msg
    , databaseSource : DatabaseSource.Model msg
    , jsonSource : JsonSource.Model msg
    , newSourceTab : Tab
    }


type Tab
    = TabDatabase
    | TabSql
    | TabJson


type Msg
    = Open (Maybe Source)
    | Close
    | SqlSourceMsg SqlSource.Msg
    | DatabaseSourceMsg DatabaseSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | UpdateTab Tab


init : (String -> msg) -> SchemaName -> Maybe Source -> Model msg
init noop defaultSchema source =
    { id = Conf.ids.sourceUpdateDialog
    , source = source
    , sqlSource = SqlSource.init defaultSchema source (\_ -> noop "project-settings-sql-source-callback")
    , databaseSource = DatabaseSource.init defaultSchema source (\_ -> noop "project-settings-database-source-callback")
    , jsonSource = JsonSource.init defaultSchema source (\_ -> noop "project-settings-json-source-callback")
    , newSourceTab = TabDatabase
    }


update : (Msg -> msg) -> (HtmlId -> msg) -> (String -> msg) -> Time.Posix -> Backend.Url -> SchemaName -> Msg -> Maybe (Model msg) -> ( Maybe (Model msg), Cmd msg )
update wrap modalOpen noop now backendUrl defaultSchema msg model =
    case msg of
        Open source ->
            ( Just (init noop defaultSchema source), T.sendAfter 1 (modalOpen Conf.ids.sourceUpdateDialog) )

        Close ->
            ( Nothing, Cmd.none )

        SqlSourceMsg message ->
            model |> mapMCmd (mapSqlSourceCmd (SqlSource.update (SqlSourceMsg >> wrap) now message))

        DatabaseSourceMsg message ->
            model |> mapMCmd (mapDatabaseSourceCmd (DatabaseSource.update (DatabaseSourceMsg >> wrap) backendUrl now message))

        JsonSourceMsg message ->
            model |> mapMCmd (mapJsonSourceCmd (JsonSource.update (JsonSourceMsg >> wrap) now message))

        UpdateTab kind ->
            ( model |> Maybe.map (\m -> { m | newSourceTab = kind }), Cmd.none )


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
        (model.source
            |> Maybe.mapOrElse
                (\source ->
                    case source.kind of
                        DatabaseConnection url ->
                            databaseModal wrap sourceSet close zone now titleId source url model.databaseSource

                        SqlFileLocal filename _ updatedAt ->
                            sqlLocalFileModal wrap sourceSet close noop zone now (model.id ++ "-sql") titleId source filename updatedAt model.sqlSource

                        SqlFileRemote url _ ->
                            sqlRemoteFileModal wrap sourceSet close zone now titleId source url model.sqlSource

                        JsonFileLocal filename _ updatedAt ->
                            jsonLocalFileModal wrap sourceSet close noop zone now (model.id ++ "-json") titleId source filename updatedAt model.jsonSource

                        JsonFileRemote url _ ->
                            jsonRemoteFileModal wrap sourceSet close zone now titleId source url model.jsonSource

                        AmlEditor ->
                            userDefinedModal close titleId
                )
                (newSourceModal wrap sourceSet close noop (model.id ++ "-new") titleId model)
        )


databaseModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> DatabaseUrl -> DatabaseSource.Model msg -> List (Html msg)
databaseModal wrap sourceSet close zone now titleId source url model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ remoteFileInfo zone now url source.updatedAt ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (url |> DatabaseSource.GetSchema |> DatabaseSourceMsg |> wrap) ] [ text "Fetch schema again" ]
            ]
        , DatabaseSource.viewParsing (DatabaseSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


sqlLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SqlSource.Model msg -> List (Html msg)
sqlLocalFileModal wrap sourceSet close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ localFileInfo zone now fileName updatedAt ]
            ]
        , div [ class "mt-3" ] [ SqlSource.viewLocalInput (SqlSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedFile |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( SqlFileLocal name1 _ updated1, Just (SqlFileLocal name2 _ updated2) ) ->
                localFileWarnings ( name1, name2 ) ( updated1, updated2 )

            _ ->
                div [] []
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


sqlRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> SqlSource.Model msg -> List (Html msg)
sqlRemoteFileModal wrap sourceSet close zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ remoteFileInfo zone now fileUrl source.updatedAt ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (fileUrl |> SqlSource.GetRemoteFile |> SqlSourceMsg >> wrap) ] [ text "Fetch file again" ]
            ]
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


jsonLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> JsonSource.Model msg -> List (Html msg)
jsonLocalFileModal wrap sourceSet close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ localFileInfo zone now fileName updatedAt ]
            ]
        , div [ class "mt-3" ] [ JsonSource.viewLocalInput (JsonSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedSchema |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( JsonFileLocal name1 _ updated1, Just (JsonFileLocal name2 _ updated2) ) ->
                localFileWarnings ( name1, name2 ) ( updated1, updated2 )

            _ ->
                div [] []
        , JsonSource.viewParsing (JsonSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


jsonRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> JsonSource.Model msg -> List (Html msg)
jsonRemoteFileModal wrap sourceSet close zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ remoteFileInfo zone now fileUrl source.updatedAt ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (fileUrl |> JsonSource.GetRemoteFile |> JsonSourceMsg >> wrap) ] [ text "Fetch file again" ]
            ]
        , JsonSource.viewParsing (JsonSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


userDefinedModal : msg -> HtmlId -> List (Html msg)
userDefinedModal close titleId =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId "This is a user source, it can't be refreshed!"
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


newSourceModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> HtmlId -> HtmlId -> Model msg -> List (Html msg)
newSourceModal wrap sourceSet close noop htmlId titleId model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId "Add a source"
            , div [ class "mt-2" ]
                [ p [ class "text-sm text-gray-500" ]
                    [ text """A project can have several sources. They are independent and merged together when enabled to build the usable schema.
                      It's a great way to explore multiple database at once or create isolated schema evolutions."""
                    ]
                ]
            ]
        , div [ class "mt-3" ]
            [ Bool.cond (model.newSourceTab == TabDatabase) Button.primary1 Button.white1 Tw.primary [ onClick (TabDatabase |> UpdateTab |> wrap) ] [ text "Database" ]
            , Bool.cond (model.newSourceTab == TabSql) Button.primary1 Button.white1 Tw.primary [ onClick (TabSql |> UpdateTab |> wrap), class "ml-3" ] [ text "SQL" ]
            , Bool.cond (model.newSourceTab == TabJson) Button.primary1 Button.white1 Tw.primary [ onClick (TabJson |> UpdateTab |> wrap), class "ml-3" ] [ text "JSON" ]
            ]
        , case model.newSourceTab of
            TabDatabase ->
                newDatabaseSource wrap (htmlId ++ "-database") model.databaseSource

            TabSql ->
                newSqlSource wrap noop (htmlId ++ "-sql") model.sqlSource

            TabJson ->
                newJsonSource wrap noop (htmlId ++ "-json") model.jsonSource
        ]
    , case model.newSourceTab of
        TabDatabase ->
            newSourceButtons sourceSet close model.databaseSource.parsedSource

        TabSql ->
            newSourceButtons sourceSet close model.sqlSource.parsedSource

        TabJson ->
            newSourceButtons sourceSet close model.jsonSource.parsedSource
    ]


newDatabaseSource : (Msg -> msg) -> HtmlId -> DatabaseSource.Model msg -> Html msg
newDatabaseSource wrap htmlId model =
    div [ class "mt-3" ]
        [ DatabaseSource.viewInput (DatabaseSourceMsg >> wrap) htmlId model
        , DatabaseSource.viewParsing (DatabaseSourceMsg >> wrap) model
        ]


newSqlSource : (Msg -> msg) -> (String -> msg) -> HtmlId -> SqlSource.Model msg -> Html msg
newSqlSource wrap noop htmlId model =
    div [ class "mt-3" ]
        [ SqlSource.viewInput (SqlSourceMsg >> wrap) noop htmlId model
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        ]


newJsonSource : (Msg -> msg) -> (String -> msg) -> HtmlId -> JsonSource.Model msg -> Html msg
newJsonSource wrap noop htmlId model =
    div [ class "mt-3" ]
        [ JsonSource.viewInput (JsonSourceMsg >> wrap) noop htmlId model
        , JsonSource.viewParsing (JsonSourceMsg >> wrap) model
        ]


newSourceButtons : (Source -> msg) -> msg -> Maybe (Result String Source) -> Html msg
newSourceButtons sourceSet close parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.map sourceSet) "Add source"
        , closeBtn close
        ]



-- HELPERS


modalTitle : HtmlId -> String -> Html msg
modalTitle titleId title =
    h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ] [ text title ]


localFileInfo : Time.Zone -> Time.Posix -> FileName -> FileUpdatedAt -> Html msg
localFileInfo zone now fileName updatedAt =
    p [ class "text-sm text-gray-500" ]
        [ text "This source came from the "
        , bText (DateTime.formatDate zone updatedAt)
        , text " version of "
        , bText fileName
        , text (" file (" ++ (updatedAt |> DateTime.human now) ++ ").")
        , br [] []
        , text "Please upload its new version to update the source."
        ]


remoteFileInfo : Time.Zone -> Time.Posix -> FileUrl -> Time.Posix -> Html msg
remoteFileInfo zone now fileUrl updatedAt =
    p [ class "text-sm text-gray-500" ]
        [ text "This source came from "
        , bText fileUrl
        , text " which was fetched the "
        , bText (DateTime.formatDate zone updatedAt)
        , text (" (" ++ (updatedAt |> DateTime.human now) ++ ").")
        , br [] []
        , text "Click on the button to fetch it again now."
        ]


localFileWarnings : ( FileName, FileName ) -> ( FileUpdatedAt, FileUpdatedAt ) -> Html msg
localFileWarnings ( name1, name2 ) ( updated1, updated2 ) =
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


viewSourceDiff : { a | source : Maybe Source, defaultSchema : SchemaName, parsedSource : Maybe (Result String Source) } -> Html msg
viewSourceDiff model =
    model.source |> Maybe.map2 (SourceDiff.view model.defaultSchema) (model.parsedSource |> Maybe.andThen Result.toMaybe) |> Maybe.withDefault (div [] [])


updateSourceButtons : (Source -> msg) -> msg -> Maybe (Result String Source) -> Html msg
updateSourceButtons sourceSet close parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.map sourceSet) "Update source"
        , closeBtn close
        ]


primaryBtn : Maybe msg -> String -> Html msg
primaryBtn clicked label =
    Button.primary3 Tw.primary (clicked |> Maybe.mapOrElse (\c -> [ onClick c ]) [ disabled True ]) [ text label ]


closeBtn : msg -> Html msg
closeBtn close =
    Button.white3 Tw.gray [ onClick close ] [ text "Close" ]

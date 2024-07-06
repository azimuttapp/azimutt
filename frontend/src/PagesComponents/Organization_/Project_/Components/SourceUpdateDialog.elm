module PagesComponents.Organization_.Project_.Components.SourceUpdateDialog exposing (Model, Msg(..), Tab, init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, br, div, h3, li, p, text, ul)
import Html.Attributes exposing (class, disabled, id)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css, role)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.DateTime as DateTime
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.AmlSource as AmlSource
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSourceT, mapDatabaseSourceT, mapJsonSourceT, mapMT, mapPrismaSourceT, mapSqlSourceT)
import Services.PrismaSource as PrismaSource
import Services.SourceDiff as SourceDiff
import Services.SqlSource as SqlSource
import Time


type alias Model msg =
    { id : HtmlId
    , source : Maybe Source
    , databaseSource : DatabaseSource.Model msg
    , sqlSource : SqlSource.Model msg
    , prismaSource : PrismaSource.Model msg
    , jsonSource : JsonSource.Model msg
    , amlSource : AmlSource.Model
    , newSourceTab : Tab
    }


type Tab
    = TabDatabase
    | TabSql
    | TabPrisma
    | TabJson
    | TabAml


type Msg
    = Open (Maybe Source)
    | Close
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | PrismaSourceMsg PrismaSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | AmlSourceMsg AmlSource.Msg
    | UpdateTab Tab


init : (String -> msg) -> HtmlId -> Maybe Source -> Model msg
init noop dialogId source =
    { id = dialogId
    , source = source
    , databaseSource = DatabaseSource.init source (\_ -> noop "project-settings-database-source-callback")
    , sqlSource = SqlSource.init source (\_ -> noop "project-settings-sql-source-callback")
    , prismaSource = PrismaSource.init source (\_ -> noop "project-settings-prisma-source-callback")
    , jsonSource = JsonSource.init source (\_ -> noop "project-settings-json-source-callback")
    , amlSource = AmlSource.init
    , newSourceTab = TabDatabase
    }


update : (Msg -> msg) -> (HtmlId -> msg) -> (String -> msg) -> Time.Posix -> Maybe ProjectInfo -> Msg -> Maybe (Model msg) -> ( Maybe (Model msg), Extra msg )
update wrap modalOpen noop now project msg model =
    case msg of
        Open source ->
            ( Just (init noop Conf.ids.sourceUpdateDialog source), modalOpen Conf.ids.sourceUpdateDialog |> T.sendAfter 1 |> Extra.cmd )

        Close ->
            ( Nothing, Extra.none )

        DatabaseSourceMsg message ->
            model |> mapMT (mapDatabaseSourceT (DatabaseSource.update (DatabaseSourceMsg >> wrap) now project message)) |> Extra.defaultT

        SqlSourceMsg message ->
            model |> mapMT (mapSqlSourceT (SqlSource.update (SqlSourceMsg >> wrap) now project message)) |> Extra.defaultT

        PrismaSourceMsg message ->
            model |> mapMT (mapPrismaSourceT (PrismaSource.update (PrismaSourceMsg >> wrap) now project message)) |> Extra.defaultT

        JsonSourceMsg message ->
            model |> mapMT (mapJsonSourceT (JsonSource.update (JsonSourceMsg >> wrap) now project message)) |> Extra.defaultT

        AmlSourceMsg message ->
            model |> mapMT (mapAmlSourceT (AmlSource.update (AmlSourceMsg >> wrap) now project message)) |> Extra.defaultT

        UpdateTab kind ->
            ( model |> Maybe.map (\m -> { m | newSourceTab = kind }), Extra.none )


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
                        DatabaseConnection _ url _ ->
                            databaseModal wrap sourceSet close zone now titleId source url model.databaseSource

                        SqlLocalFile filename _ updatedAt ->
                            sqlLocalFileModal wrap sourceSet close noop zone now (model.id ++ "-sql") titleId source filename updatedAt model.sqlSource

                        SqlRemoteFile url _ ->
                            sqlRemoteFileModal wrap sourceSet close zone now titleId source url model.sqlSource

                        PrismaLocalFile filename _ updatedAt ->
                            prismaLocalFileModal wrap sourceSet close noop zone now (model.id ++ "-prisma") titleId source filename updatedAt model.prismaSource

                        PrismaRemoteFile url _ ->
                            prismaRemoteFileModal wrap sourceSet close zone now titleId source url model.prismaSource

                        JsonLocalFile filename _ updatedAt ->
                            jsonLocalFileModal wrap sourceSet close noop zone now (model.id ++ "-json") titleId source filename updatedAt model.jsonSource

                        JsonRemoteFile url _ ->
                            jsonRemoteFileModal wrap sourceSet close zone now titleId source url model.jsonSource

                        AmlEditor ->
                            userDefinedModal close titleId
                )
                (newSourceModal wrap sourceSet close noop (model.id ++ "-new") titleId model)
        )


databaseModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> Maybe DatabaseUrl -> DatabaseSource.Model msg -> List (Html msg)
databaseModal wrap sourceSet close zone now titleId source urlM model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ remoteFileInfo zone now (urlM |> Maybe.withDefault "<hidden>") source.updatedAt ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ urlM
                |> Maybe.map (\url -> Button.primary5 Tw.primary [ onClick (url |> DatabaseSource.GetSchema |> DatabaseSourceMsg |> wrap) ] [ text "Fetch schema again" ])
                |> Maybe.withDefault (Button.primary5 Tw.primary [ disabled True ] [ text "Fetch schema again" ])
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
            ( SqlLocalFile name1 _ updated1, Just (SqlLocalFile name2 _ updated2) ) ->
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


prismaLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> PrismaSource.Model msg -> List (Html msg)
prismaLocalFileModal wrap sourceSet close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ localFileInfo zone now fileName updatedAt ]
            ]
        , div [ class "mt-3" ] [ PrismaSource.viewLocalInput (PrismaSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedSchema |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( PrismaLocalFile name1 _ updated1, Just (PrismaLocalFile name2 _ updated2) ) ->
                localFileWarnings ( name1, name2 ) ( updated1, updated2 )

            _ ->
                div [] []
        , PrismaSource.viewParsing (PrismaSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons sourceSet close model.parsedSource
    ]


prismaRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> Source -> FileUrl -> PrismaSource.Model msg -> List (Html msg)
prismaRemoteFileModal wrap sourceSet close zone now titleId source fileUrl model =
    [ div [ class "max-w-3xl mx-6 mt-6" ]
        [ div [ css [ "mt-3", sm [ "mt-5" ] ] ]
            [ modalTitle titleId ("Refresh " ++ source.name ++ " source")
            , div [ class "mt-2" ] [ remoteFileInfo zone now fileUrl source.updatedAt ]
            ]
        , div [ class "mt-3 flex justify-center" ]
            [ Button.primary5 Tw.primary [ onClick (fileUrl |> PrismaSource.GetRemoteFile |> PrismaSourceMsg >> wrap) ] [ text "Fetch file again" ]
            ]
        , PrismaSource.viewParsing (PrismaSourceMsg >> wrap) model
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
            ( JsonLocalFile name1 _ updated1, Just (JsonLocalFile name2 _ updated2) ) ->
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
            , Bool.cond (model.newSourceTab == TabPrisma) Button.primary1 Button.white1 Tw.primary [ onClick (TabPrisma |> UpdateTab |> wrap), class "ml-3" ] [ text "Prisma" ]
            , Bool.cond (model.newSourceTab == TabJson) Button.primary1 Button.white1 Tw.primary [ onClick (TabJson |> UpdateTab |> wrap), class "ml-3" ] [ text "JSON" ]
            , Bool.cond (model.newSourceTab == TabAml) Button.primary1 Button.white1 Tw.primary [ onClick (TabAml |> UpdateTab |> wrap), class "ml-3" ] [ text "AML" ]
            ]
        , div [ class "mt-3" ]
            (case model.newSourceTab of
                TabDatabase ->
                    [ DatabaseSource.viewInput (DatabaseSourceMsg >> wrap) (htmlId ++ "-database") model.databaseSource
                    , DatabaseSource.viewParsing (DatabaseSourceMsg >> wrap) model.databaseSource
                    ]

                TabSql ->
                    [ SqlSource.viewInput (SqlSourceMsg >> wrap) noop (htmlId ++ "-sql") model.sqlSource
                    , SqlSource.viewParsing (SqlSourceMsg >> wrap) model.sqlSource
                    ]

                TabPrisma ->
                    [ PrismaSource.viewInput (PrismaSourceMsg >> wrap) noop (htmlId ++ "-prisma") model.prismaSource
                    , PrismaSource.viewParsing (PrismaSourceMsg >> wrap) model.prismaSource
                    ]

                TabJson ->
                    [ JsonSource.viewInput (JsonSourceMsg >> wrap) noop (htmlId ++ "-json") model.jsonSource
                    , JsonSource.viewParsing (JsonSourceMsg >> wrap) model.jsonSource
                    ]

                TabAml ->
                    [ AmlSource.viewInput (AmlSourceMsg >> wrap) (htmlId ++ "-aml") model.amlSource
                    ]
            )
        ]
    , case model.newSourceTab of
        TabDatabase ->
            newSourceButtons (DatabaseSource.GetSchema >> DatabaseSourceMsg >> wrap) sourceSet close model.databaseSource.url model.databaseSource.parsedSource

        TabSql ->
            newSourceButtons (SqlSource.GetRemoteFile >> SqlSourceMsg >> wrap) sourceSet close model.sqlSource.url model.sqlSource.parsedSource

        TabPrisma ->
            newSourceButtons (PrismaSource.GetRemoteFile >> PrismaSourceMsg >> wrap) sourceSet close model.prismaSource.url model.prismaSource.parsedSource

        TabJson ->
            newSourceButtons (JsonSource.GetRemoteFile >> JsonSourceMsg >> wrap) sourceSet close model.jsonSource.url model.jsonSource.parsedSource

        TabAml ->
            newSourceButtonsNoRemote sourceSet close model.amlSource.parsedSource
    ]


newSourceButtons : (String -> msg) -> (Source -> msg) -> msg -> String -> Maybe (Result String Source) -> Html msg
newSourceButtons extractSchema sourceSet close url parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        (case ( url, parsedSource |> Maybe.andThen Result.toMaybe ) of
            ( _, Just source ) ->
                [ primaryBtn (source |> sourceSet |> Just) "Add source to project"
                , closeBtn close
                ]

            _ ->
                if url /= "" then
                    [ primaryBtn (url |> extractSchema |> Just) "Extract source"
                    , closeBtn close
                    ]

                else
                    [ closeBtn close ]
        )


newSourceButtonsNoRemote : (Source -> msg) -> msg -> Maybe (Result String Source) -> Html msg
newSourceButtonsNoRemote sourceSet close parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.map sourceSet) "Add source to project"
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


viewSourceDiff : { a | source : Maybe Source, parsedSource : Maybe (Result String Source) } -> Html msg
viewSourceDiff model =
    model.source |> Maybe.map2 (SourceDiff.view Conf.schema.empty) (model.parsedSource |> Maybe.andThen Result.toMaybe) |> Maybe.withDefault (div [] [])


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

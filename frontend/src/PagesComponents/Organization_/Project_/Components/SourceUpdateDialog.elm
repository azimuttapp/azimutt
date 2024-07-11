module PagesComponents.Organization_.Project_.Components.SourceUpdateDialog exposing (Model, Msg(..), Tab, init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, div, h3, input, label, li, option, p, select, span, text, ul)
import Html.Attributes exposing (class, disabled, for, id, name, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as Bool
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (css, role)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.DateTime as DateTime
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceKind as SourceKind exposing (SourceKind(..))
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.AmlSource as AmlSource
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSourceT, mapDatabaseSourceT, mapJsonSourceT, mapKind, mapMT, mapPrismaSourceT, mapSqlSourceT, setName)
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
    , amlSource = AmlSource.init source
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
view wrap updateSource modalClose noop zone now opened model =
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
                        DatabaseConnection db ->
                            viewDatabaseModal wrap updateSource close zone now (model.id ++ "-database") titleId source db.url model.databaseSource

                        SqlLocalFile file ->
                            viewSqlLocalFileModal wrap updateSource close noop zone now (model.id ++ "-sql-local") titleId source file.name file.modified model.sqlSource

                        SqlRemoteFile file ->
                            viewSqlRemoteFileModal wrap updateSource close zone now (model.id ++ "-sql-remote") titleId source file.url model.sqlSource

                        PrismaLocalFile file ->
                            viewPrismaLocalFileModal wrap updateSource close noop zone now (model.id ++ "-prisma-local") titleId source file.name file.modified model.prismaSource

                        PrismaRemoteFile file ->
                            viewPrismaRemoteFileModal wrap updateSource close zone now (model.id ++ "-prisma-remote") titleId source file.url model.prismaSource

                        JsonLocalFile file ->
                            viewJsonLocalFileModal wrap updateSource close noop zone now (model.id ++ "-json-local") titleId source file.name file.modified model.jsonSource

                        JsonRemoteFile file ->
                            viewJsonRemoteFileModal wrap updateSource close zone now (model.id ++ "-prisma-remote") titleId source file.url model.jsonSource

                        AmlEditor ->
                            viewAmlModal wrap updateSource close zone now (model.id ++ "-aml") titleId source model.amlSource
                )
                (viewNewSourceModal wrap updateSource close noop (model.id ++ "-new") titleId model)
        )


viewDatabaseModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> Maybe DatabaseUrl -> DatabaseSource.Model msg -> List (Html msg)
viewDatabaseModal wrap updateSource close zone now htmlId titleId source url model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (DatabaseSource.UpdateName >> DatabaseSourceMsg >> wrap) False
        , inputText (htmlId ++ "-url-input") "Database url" model.url (DatabaseSource.UpdateUrl >> DatabaseSourceMsg >> wrap) (url /= Nothing)
        , inputSelect (htmlId ++ "-storage-input") "Database url storage" (DatabaseUrlStorage.toString model.storage) (DatabaseUrlStorage.fromString >> DatabaseSource.UpdateStorage >> DatabaseSourceMsg >> wrap) (DatabaseUrlStorage.all |> List.map (\s -> { value = DatabaseUrlStorage.toString s, label = "In " ++ DatabaseUrlStorage.toString s }))
        , p [ class "mt-1 text-sm text-gray-500" ] [ text (DatabaseUrlStorage.explain model.storage) ]
        , p [ class "mt-3 text-sm text-gray-500" ] [ text "Database last loaded on ", source.updatedAt |> viewDate zone now, text "." ]
        , url
            |> Maybe.orElse (String.nonEmptyMaybe model.url)
            |> Maybe.map (\u -> Button.primary5 Tw.primary [ onClick (u |> DatabaseSource.GetSchema |> DatabaseSourceMsg |> wrap), class "mt-1" ] [ text "Fetch schema again" ])
            |> Maybe.withDefault (Button.primary5 Tw.primary [ disabled True, class "mt-1" ] [ text "Fetch schema again" ])
        , DatabaseSource.viewParsing (DatabaseSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource
        close
        (model.parsedSource
            |> Maybe.andThen Result.toMaybe
            |> Maybe.orElse
                (model.source
                    |> Maybe.filter (\s -> s.name /= model.name || Source.databaseUrl s /= String.nonEmptyMaybe model.url || Source.databaseUrlStorage s /= Just model.storage)
                    |> Maybe.map (\s -> s |> setName model.name |> mapKind (SourceKind.setDatabaseUrl (String.nonEmptyMaybe model.url) >> SourceKind.setDatabaseUrlStorage model.storage))
                )
        )
    ]


viewSqlLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> SqlSource.Model msg -> List (Html msg)
viewSqlLocalFileModal wrap updateSource close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (SqlSource.UpdateName >> SqlSourceMsg >> wrap) False
        , inputText (htmlId ++ "-path-input") "File path" fileName noop True
        , localFileInfo zone now source.updatedAt updatedAt
        , div [ class "mt-3" ] [ SqlSource.viewLocalInput (SqlSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedFile |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( SqlLocalFile file1, Just (SqlLocalFile file2) ) ->
                localFileWarnings ( file1.name, file2.name ) ( file1.modified, file2.modified )

            _ ->
                div [] []
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewSqlRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileUrl -> SqlSource.Model msg -> List (Html msg)
viewSqlRemoteFileModal wrap updateSource close zone now htmlId titleId source fileUrl model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (SqlSource.UpdateName >> SqlSourceMsg >> wrap) False
        , inputText (htmlId ++ "-url-input") "File url" fileUrl (SqlSource.UpdateRemoteFile >> SqlSourceMsg >> wrap) True
        , remoteFileInfo zone now source.updatedAt
        , Button.primary5 Tw.primary [ onClick (fileUrl |> SqlSource.GetRemoteFile |> SqlSourceMsg >> wrap), class "mt-1" ] [ text "Fetch file again" ]
        , SqlSource.viewParsing (SqlSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewPrismaLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> PrismaSource.Model msg -> List (Html msg)
viewPrismaLocalFileModal wrap updateSource close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (PrismaSource.UpdateName >> PrismaSourceMsg >> wrap) False
        , inputText (htmlId ++ "-path-input") "File path" fileName noop True
        , localFileInfo zone now source.updatedAt updatedAt
        , div [ class "mt-3" ] [ PrismaSource.viewLocalInput (PrismaSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedSchema |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( PrismaLocalFile file1, Just (PrismaLocalFile file2) ) ->
                localFileWarnings ( file1.name, file2.name ) ( file1.modified, file2.modified )

            _ ->
                div [] []
        , PrismaSource.viewParsing (PrismaSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewPrismaRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileUrl -> PrismaSource.Model msg -> List (Html msg)
viewPrismaRemoteFileModal wrap updateSource close zone now htmlId titleId source fileUrl model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (PrismaSource.UpdateName >> PrismaSourceMsg >> wrap) False
        , inputText (htmlId ++ "-url-input") "File url" fileUrl (PrismaSource.UpdateRemoteFile >> PrismaSourceMsg >> wrap) True
        , remoteFileInfo zone now source.updatedAt
        , Button.primary5 Tw.primary [ onClick (fileUrl |> PrismaSource.GetRemoteFile |> PrismaSourceMsg >> wrap), class "mt-1" ] [ text "Fetch file again" ]
        , PrismaSource.viewParsing (PrismaSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewJsonLocalFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileName -> FileUpdatedAt -> JsonSource.Model msg -> List (Html msg)
viewJsonLocalFileModal wrap updateSource close noop zone now htmlId titleId source fileName updatedAt model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (JsonSource.UpdateName >> JsonSourceMsg >> wrap) False
        , inputText (htmlId ++ "-path-input") "File path" fileName noop True
        , localFileInfo zone now source.updatedAt updatedAt
        , div [ class "mt-3" ] [ JsonSource.viewLocalInput (JsonSourceMsg >> wrap) noop (htmlId ++ "-local-file") ]
        , case ( source.kind, model.loadedSchema |> Maybe.map (\( src, _ ) -> src.kind) ) of
            ( JsonLocalFile file1, Just (JsonLocalFile file2) ) ->
                localFileWarnings ( file1.name, file2.name ) ( file1.modified, file2.modified )

            _ ->
                div [] []
        , JsonSource.viewParsing (JsonSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewJsonRemoteFileModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> FileUrl -> JsonSource.Model msg -> List (Html msg)
viewJsonRemoteFileModal wrap updateSource close zone now htmlId titleId source fileUrl model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (JsonSource.UpdateName >> JsonSourceMsg >> wrap) False
        , inputText (htmlId ++ "-url-input") "File url" fileUrl (JsonSource.UpdateRemoteFile >> JsonSourceMsg >> wrap) True
        , remoteFileInfo zone now source.updatedAt
        , Button.primary5 Tw.primary [ onClick (fileUrl |> JsonSource.GetRemoteFile |> JsonSourceMsg >> wrap), class "mt-1" ] [ text "Fetch file again" ]
        , JsonSource.viewParsing (JsonSourceMsg >> wrap) model
        , viewSourceDiff model
        ]
    , updateSourceButtons updateSource close (model.parsedSource |> makeUpdateSource model.source model.name)
    ]


viewAmlModal : (Msg -> msg) -> (Source -> msg) -> msg -> Time.Zone -> Time.Posix -> HtmlId -> HtmlId -> Source -> AmlSource.Model -> List (Html msg)
viewAmlModal wrap updateSource close zone now htmlId titleId source model =
    [ div [ class "w-3xl mx-6 mt-6" ]
        [ modalTitle titleId ("Update " ++ source.name ++ " source")
        , inputText (htmlId ++ "-name-input") "Source name" model.name (AmlSource.UpdateName >> AmlSourceMsg >> wrap) False
        , p [ class "mt-3 text-sm text-gray-500" ] [ text "Source last edited on ", source.updatedAt |> viewDate zone now, text "." ]
        , div [ class "mt-3" ]
            [ Alert.simple Tw.blue
                Icon.ExclamationCircle
                [ text "If you are looking to edit this source content (AML), click on "
                , Icon.solid Icon.Terminal "inline"
                , text " in the source list or "
                , Icon.solid Icon.Pencil "inline"
                , text " in editor (bottom right)."
                ]
            ]
        ]
    , updateSourceButtons updateSource close (model.source |> Maybe.filter (\s -> s.name /= model.name) |> Maybe.map (setName model.name))
    ]


viewNewSourceModal : (Msg -> msg) -> (Source -> msg) -> msg -> (String -> msg) -> HtmlId -> HtmlId -> Model msg -> List (Html msg)
viewNewSourceModal wrap updateSource close noop htmlId titleId model =
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
            newSourceButtons (DatabaseSource.GetSchema >> DatabaseSourceMsg >> wrap) updateSource close model.databaseSource.url model.databaseSource.parsedSource

        TabSql ->
            newSourceButtons (SqlSource.GetRemoteFile >> SqlSourceMsg >> wrap) updateSource close model.sqlSource.url model.sqlSource.parsedSource

        TabPrisma ->
            newSourceButtons (PrismaSource.GetRemoteFile >> PrismaSourceMsg >> wrap) updateSource close model.prismaSource.url model.prismaSource.parsedSource

        TabJson ->
            newSourceButtons (JsonSource.GetRemoteFile >> JsonSourceMsg >> wrap) updateSource close model.jsonSource.url model.jsonSource.parsedSource

        TabAml ->
            newSourceButtonsNoRemote updateSource close model.amlSource.parsedSource
    ]


newSourceButtons : (String -> msg) -> (Source -> msg) -> msg -> String -> Maybe (Result String Source) -> Html msg
newSourceButtons extractSchema updateSource close url parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        (case ( url, parsedSource |> Maybe.andThen Result.toMaybe ) of
            ( _, Just source ) ->
                [ primaryBtn (source |> updateSource |> Just) "Add source to project"
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
newSourceButtonsNoRemote updateSource close parsedSource =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.map updateSource) "Add source to project"
        , closeBtn close
        ]



-- HELPERS


modalTitle : HtmlId -> String -> Html msg
modalTitle titleId title =
    h3 [ id titleId, class "text-lg leading-6 text-center font-medium text-gray-900" ] [ text title ]


localFileInfo : Time.Zone -> Time.Posix -> Time.Posix -> FileUpdatedAt -> Html msg
localFileInfo zone now sourceUpdated fileUpdated =
    p [ class "mt-3 text-sm text-gray-500" ]
        [ text "File loaded on ", sourceUpdated |> viewDate zone now, text " with a file from ", fileUpdated |> viewDate zone now, text "." ]


remoteFileInfo : Time.Zone -> Time.Posix -> Time.Posix -> Html msg
remoteFileInfo zone now sourceUpdated =
    p [ class "mt-3 text-sm text-gray-500" ]
        [ text "File loaded on ", sourceUpdated |> viewDate zone now, text "." ]


viewDate : Time.Zone -> Time.Posix -> Time.Posix -> Html msg
viewDate zone now date =
    span [] [ bText (DateTime.formatDate zone date), text (" (" ++ (date |> DateTime.human now) ++ ")") ]


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


inputText : HtmlId -> String -> String -> (String -> msg) -> Bool -> Html msg
inputText inputId inputLabel inputValue onChange isDisabled =
    div [ class "mt-3" ]
        [ label [ for inputId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text inputLabel ]
        , div [ class "mt-1" ]
            [ input
                [ type_ "text"
                , id inputId
                , name inputId
                , value inputValue
                , onInput onChange
                , disabled isDisabled
                , placeholder inputLabel
                , css [ "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6", Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200" ] ]
                ]
                []
            ]
        ]


inputSelect : HtmlId -> String -> String -> (String -> msg) -> List { value : String, label : String } -> Html msg
inputSelect inputId inputLabel inputValue onChange inputOptions =
    div [ class "mt-3" ]
        [ label [ for inputId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text inputLabel ]
        , select
            [ id inputId
            , name inputId
            , onInput onChange
            , class "mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ]
            (inputOptions |> List.map (\o -> option [ value o.value, selected (o.value == inputValue) ] [ text o.label ]))
        ]


viewSourceDiff : { a | source : Maybe Source, parsedSource : Maybe (Result String Source) } -> Html msg
viewSourceDiff model =
    model.source |> Maybe.map2 (SourceDiff.view Conf.schema.empty) (model.parsedSource |> Maybe.andThen Result.toMaybe) |> Maybe.withDefault (div [] [])


updateSourceButtons : (Source -> msg) -> msg -> Maybe Source -> Html msg
updateSourceButtons updateSource close source =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ primaryBtn (source |> Maybe.map updateSource) "Update source"
        , closeBtn close
        ]


primaryBtn : Maybe msg -> String -> Html msg
primaryBtn clicked label =
    Button.primary3 Tw.primary (clicked |> Maybe.mapOrElse (\c -> [ onClick c ]) [ disabled True ]) [ text label ]


closeBtn : msg -> Html msg
closeBtn close =
    Button.white3 Tw.gray [ onClick close ] [ text "Close" ]


makeUpdateSource : Maybe Source -> String -> Maybe (Result String Source) -> Maybe Source
makeUpdateSource source name parsedSource =
    (parsedSource |> Maybe.andThen Result.toMaybe)
        |> Maybe.orElse (source |> Maybe.filter (\s -> s.name /= name) |> Maybe.map (setName name))

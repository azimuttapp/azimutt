module Services.DatabaseSource exposing (Model, Msg(..), example, init, update, viewInput, viewParsing)

import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon
import Components.Molecules.Alert as Alert
import Components.Molecules.Divider as Divider
import Components.Molecules.Tooltip as Tooltip
import DataSources.JsonMiner.JsonAdapter as JsonAdapter
import DataSources.JsonMiner.JsonSchema exposing (JsonSchema)
import Html exposing (Html, br, button, div, img, input, label, option, p, select, text)
import Html.Attributes exposing (class, disabled, for, id, name, placeholder, selected, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as B
import Libs.Html exposing (extLink, iText)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Task as T
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.ProjectInfo exposing (ProjectInfo)
import Models.SourceInfo as SourceInfo
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Random
import Services.Backend as Backend
import Services.Lenses exposing (mapShow)
import Services.SourceLogs as SourceLogs
import Services.Urls as Urls
import Time
import Track


type alias Model msg =
    { source : Maybe Source
    , name : String
    , engine : DatabaseKind
    , url : String
    , storage : DatabaseUrlStorage
    , selectedUrl : Maybe (Result String String)
    , parsedSchema : Maybe (Result String JsonSchema)
    , parsedSource : Maybe (Result String Source)
    , callback : Result String Source -> msg
    , show : HtmlId
    }


type Msg
    = UpdateName String
    | UpdateEngine DatabaseKind
    | UpdateUrl DatabaseUrl
    | UpdateStorage (Maybe DatabaseUrlStorage)
    | GetSchema DatabaseUrl
    | GotSchema (Result String JsonSchema)
    | BuildSource SourceId
    | UiToggle HtmlId


databases : List { key : DatabaseKind, sampleUrl : String }
databases =
    [ { key = DatabaseKind.PostgreSQL, sampleUrl = "postgres://<user>:<pass>@<host>:<port>/<db>" }
    , { key = DatabaseKind.MySQL, sampleUrl = "mysql://<user>:<pass>@<host>:<port>/<db>" }
    , { key = DatabaseKind.MariaDB, sampleUrl = "mariadb://<user>:<pass>@<host>:<port>/<db>" }
    , { key = DatabaseKind.SQLServer, sampleUrl = "Server=<host>,<port>;Database=<db>;User Id=<user>;Password=<pass>" }
    , { key = DatabaseKind.Oracle, sampleUrl = "oracle:thin:<user>/<pass>@<host>:<port>/<db>" }
    , { key = DatabaseKind.Couchbase, sampleUrl = "couchbases://<user>:<pass>@<host>" }
    , { key = DatabaseKind.MongoDB, sampleUrl = "mongodb+srv://<user>:<pass>@<host>" }
    , { key = DatabaseKind.Snowflake, sampleUrl = "snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>" }
    , { key = DatabaseKind.BigQuery, sampleUrl = "bigquery://bigquery.googleapis.com/<project>?key=<auth-key-path>" }
    ]


databasesNext : List { key : String, issue : String }
databasesNext =
    [ { key = "sqlite", issue = "https://github.com/azimuttapp/azimutt/issues/115" }
    ]



-- INIT


example : String
example =
    "<protocol>://<user>:<pass>@<host>:<port>/<db>"


init : Maybe Source -> (Result String Source -> msg) -> Model msg
init source callback =
    { source = source
    , name = source |> Maybe.mapOrElse .name ""
    , engine = source |> Maybe.andThen Source.databaseKind |> Maybe.orElse (databases |> List.head |> Maybe.map .key) |> Maybe.withDefault DatabaseKind.default
    , url = source |> Maybe.andThen Source.databaseUrl |> Maybe.withDefault ""
    , storage = source |> Maybe.andThen Source.databaseUrlStorage |> Maybe.withDefault DatabaseUrlStorage.default
    , selectedUrl = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    , show = ""
    }



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Maybe ProjectInfo -> Msg -> Model msg -> ( Model msg, Extra msg )
update wrap now project msg model =
    case msg of
        UpdateName name ->
            ( { model | name = name }, Extra.none )

        UpdateEngine key ->
            ( { model | engine = key }, Extra.none )

        UpdateUrl url ->
            ( { model | url = url, selectedUrl = Nothing, parsedSchema = Nothing, parsedSource = Nothing }, Extra.none )

        UpdateStorage storage ->
            ( storage |> Maybe.mapOrElse (\s -> { model | storage = s }) model, Extra.none )

        GetSchema schemaUrl ->
            if schemaUrl == "" then
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl }), Extra.none )

            else
                ( init model.source model.callback |> (\m -> { m | url = schemaUrl, selectedUrl = Just (Ok schemaUrl) })
                , Ports.getDatabaseSchema schemaUrl |> Extra.cmd
                )

        GotSchema result ->
            ( { model | parsedSchema = Just result }, SourceId.generator |> Random.generate (BuildSource >> wrap) |> Extra.cmd )

        BuildSource sourceId ->
            Maybe.map2
                (\( url, kind ) -> JsonAdapter.buildSource (SourceInfo.database now (model.source |> Maybe.mapOrElse .id sourceId) model.name kind url model.storage) >> Ok)
                (model.selectedUrl |> Maybe.andThen Result.toMaybe |> Maybe.andThenZip DatabaseKind.fromUrl)
                (model.parsedSchema |> Maybe.andThen Result.toMaybe)
                |> (\source ->
                        ( { model | parsedSource = Just (source |> Maybe.withDefault (Err "Can't build source")) }
                        , source
                            |> Maybe.map (\s -> Cmd.batch [ s |> model.callback |> T.send, s |> Track.sourceCreated project "database" ])
                            |> Maybe.withDefault (Err "Can't build source" |> Track.sourceCreated project "database")
                            |> Extra.cmd
                        )
                   )

        UiToggle htmlId ->
            ( model |> mapShow (\s -> B.cond (s == htmlId) "" htmlId), Extra.none )



-- VIEW


viewInput : (Msg -> msg) -> HtmlId -> Model msg -> Html msg
viewInput wrap htmlId model =
    let
        error : Maybe String
        error =
            model.selectedUrl |> Maybe.andThen Result.toError

        inputStyles : TwClass
        inputStyles =
            error
                |> Maybe.mapOrElse (\_ -> "text-red-500 placeholder-red-300 border-red-300 focus:border-red-500 focus:ring-red-500")
                    "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"

        sampleUrl : String
        sampleUrl =
            databases |> List.find (\db -> db.key == model.engine) |> Maybe.orElse (databases |> List.head) |> Maybe.mapOrElse .sampleUrl example
    in
    div []
        [ div [ class "flex space-x-4" ]
            ((databases |> List.map (\db -> button [ type_ "button", onClick (UpdateEngine db.key |> wrap) ] [ img [ src (Backend.resourceUrl ("/assets/logos/" ++ DatabaseKind.toString db.key ++ ".png")) ] [] ]))
                ++ (databasesNext |> List.map (\db -> extLink db.issue [] [ img [ src (Backend.resourceUrl ("/assets/logos/" ++ db.key ++ ".png")), class "grayscale opacity-50" ] [] ] |> Tooltip.t "Click to ask support (made on demand)"))
            )
        , div [ class "mt-3 flex shadow-sm" ]
            [ label [ for (htmlId ++ "-url"), css [ inputStyles, "inline-flex items-center px-3 border border-r-0 rounded-l-md bg-gray-50 text-gray-500 sm:text-sm" ] ] [ text "Database url" ]
            , input
                [ type_ "text"
                , id (htmlId ++ "-url")
                , name (htmlId ++ "-url")
                , placeholder ("ex: " ++ sampleUrl)
                , value model.url
                , disabled ((model.selectedUrl |> Maybe.andThen Result.toMaybe) /= Nothing && model.parsedSchema == Nothing)
                , onInput (UpdateUrl >> wrap)
                , css [ inputStyles, "flex-1 px-3 py-2 z-max sm:text-sm", Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200" ] ]
                ]
                []
            , div [ class "inline-flex items-center" ]
                [ label [ for (htmlId ++ "-storage"), class "sr-only" ] [ text "Database url storage" ]
                , select
                    [ id (htmlId ++ "-storage")
                    , name (htmlId ++ "-storage")
                    , disabled ((model.selectedUrl |> Maybe.andThen Result.toMaybe) /= Nothing && model.parsedSchema == Nothing)
                    , onInput (DatabaseUrlStorage.fromString >> UpdateStorage >> wrap)
                    , css [ inputStyles, "h-full pl-2 pr-7 border-l-0 rounded-r-md text-gray-500 sm:text-sm" ]
                    ]
                    (DatabaseUrlStorage.all |> List.map (\s -> option [ value (DatabaseUrlStorage.toString s), selected (s == model.storage) ] [ text ("Store in " ++ DatabaseUrlStorage.toString s) ]))
                ]
            ]
        , p [ class "mt-2 text-sm text-gray-500" ] [ text ("Sample " ++ DatabaseKind.show model.engine ++ " url: " ++ sampleUrl) ]
        , error |> Maybe.mapOrElse (\err -> p [ class "mt-1 text-sm text-red-500" ] [ text err ]) (p [] [])
        , case model.engine of
            DatabaseKind.BigQuery ->
                div [ class "mt-3" ]
                    [ Alert.simple Tw.indigo
                        Icon.LightBulb
                        [ text "The `key` parameter should be the path to your account key (ex: "
                        , Badge.basic Tw.indigo [] [ text "bigquery://?key=~/.bq/key.json" ]
                        , text ")."
                        , br [] []
                        , text "You can add `dataset` and `table` parameters with LIKE syntax to limit the import scope."
                        ]
                    ]

            _ ->
                div [] []
        , div [ class "mt-3" ]
            [ Alert.simple Tw.blue
                Icon.QuestionMarkCircle
                [ text "Access databases from your computer using "
                , extLink Urls.cliNpm [ class "link" ] [ text "Azimutt CLI" ]
                , text " (install "
                , extLink "https://docs.npmjs.com/downloading-and-installing-node-js-and-npm" [ class "link" ] [ text "npm" ]
                , text " & run "
                , Badge.basic Tw.blue [] [ text "npx azimutt@latest gateway" ] |> Tooltip.br "Starts the Azimutt Gateway on your computer to access local databases."
                , text "), "
                , text "otherwise Azimutt will use the hosted gateway to connect."
                , text " For security prefer to use a "
                , iText "read-only user"
                , text " and on a "
                , iText "non-production database"
                , text "."
                ]
            ]
        ]


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing wrap model =
    (model.selectedUrl |> Maybe.andThen Result.toMaybe |> Maybe.map (\url -> DatabaseUrl.databaseName url ++ " database"))
        |> Maybe.mapOrElse
            (\dbName ->
                div []
                    [ div [ class "mt-6" ]
                        [ Divider.withLabel
                            ((model.parsedSource |> Maybe.map (\_ -> "Loaded!"))
                                |> Maybe.orElse (model.parsedSchema |> Maybe.map (\_ -> "Building..."))
                                |> Maybe.withDefault "Fetching..."
                            )
                        ]
                    , SourceLogs.viewContainer
                        [ SourceLogs.viewFile UiToggle model.show dbName (model.parsedSchema |> Maybe.map (\_ -> "")) |> Html.map wrap
                        , model.parsedSchema |> Maybe.mapOrElse (SourceLogs.viewParsedSchema UiToggle model.show) (div [] []) |> Html.map wrap
                        , model.parsedSource |> Maybe.mapOrElse (Ok >> SourceLogs.viewResult) (div [] [])
                        ]
                    , if model.parsedSource == Nothing then
                        div [] [ img [ class "mt-1 rounded-l-lg", src (Backend.resourceUrl "/assets/images/exploration.gif") ] [] ]

                      else
                        div [] []
                    ]
            )
            (div [] [])

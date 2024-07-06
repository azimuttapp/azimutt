module Components.Slices.LlmGenerateSqlBody exposing (DocState, Model, Msg(..), SharedDocState, doc, docInit, init, update, view)

import Array
import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import ElmBook
import ElmBook.Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, br, div, h3, label, option, p, select, text, textarea)
import Html.Attributes exposing (autofocus, class, disabled, for, id, name, placeholder, rows, selected, value)
import Html.Events exposing (onClick, onInput)
import Libs.Dict as Dict
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind exposing (DatabaseKind(..))
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Result as Result
import Libs.Tailwind as Tw exposing (sm)
import Libs.Task as T
import Libs.Time as Time
import Libs.Tuple3 as Tuple3
import Models.OpenAIModel as OpenAIModel exposing (OpenAIModel)
import Models.Position as Position
import Models.Project as Project
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPathStr)
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage
import Models.Project.Relation exposing (Relation)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId, SourceIdStr)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableIdStr)
import Models.Project.TableName exposing (TableName)
import Models.Size as Size
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import Ports
import Services.Lenses exposing (setCurrentLayout, setLayouts, setTables)
import Shared exposing (Prompt)
import Track


type alias Model =
    { id : HtmlId
    , sources : List ( SourceId, SourceName, DatabaseKind )
    , source : Maybe ( SourceId, SourceName, DatabaseKind )
    , prompt : String
    , loading : Bool
    , generatedSql : Maybe (Result String SqlQuery)
    }


type Msg
    = SetSource (Maybe SourceId)
    | SetPrompt String
    | GenerateSql
    | SqlGenerated (Result String SqlQuery)


init : HtmlId -> Erd -> Maybe SourceId -> Model
init id erd source =
    let
        sources : List ( SourceId, SourceName, DatabaseKind )
        sources =
            erd.sources |> List.filterMap (\s -> s |> Source.databaseKind |> Maybe.map (\kind -> ( s.id, s.name, kind )))
    in
    { id = id
    , sources = sources
    , source = sources |> List.find (\( s, _, _ ) -> source |> Maybe.has s) |> Maybe.orElse (sources |> List.head)
    , prompt = ""
    , loading = False
    , generatedSql = Nothing
    }


update : (Prompt msg -> String -> msg) -> (String -> msg) -> Erd -> Msg -> Model -> ( Model, Cmd msg )
update openPrompt updateLlmKey erd msg model =
    case msg of
        SetSource source ->
            ( { model | source = source |> Maybe.andThen (\id -> model.sources |> List.findBy Tuple3.first id) }, Cmd.none )

        SetPrompt prompt ->
            ( { model | prompt = prompt }, Cmd.none )

        GenerateSql ->
            erd.settings.llm
                |> Maybe.map
                    (\llm ->
                        model.source
                            |> Maybe.andThenZip (\( id, _, _ ) -> erd.sources |> List.findBy .id id)
                            |> Maybe.map
                                (\( ( _, _, kind ), source ) ->
                                    ( { model | loading = True }
                                    , Cmd.batch [ Ports.llmGenerateSql llm.key llm.model model.prompt kind source, Track.generateSqlQueried erd.project source llm.model model.prompt ]
                                    )
                                )
                            |> Maybe.withDefault ( { model | generatedSql = Err "No selected database source" |> Just }, Cmd.none )
                    )
                |> Maybe.withDefault ( model, promptLlmKey openPrompt updateLlmKey |> T.send )

        SqlGenerated result ->
            ( { model | loading = False, generatedSql = Just result }
            , Track.generateSqlReplied erd.project (model.source |> findSource erd) (getLlmModel erd) model.prompt result
            )


promptLlmKey : (Prompt msg -> String -> msg) -> (String -> msg) -> msg
promptLlmKey openPrompt updateLlmKey =
    openPrompt
        { color = Tw.blue
        , icon = Icon.Key
        , title = "OpenAI API Key"
        , message =
            p []
                [ text "Please enter your OpenAI API Key to use it within Azimutt."
                , br [] []
                , text "You can get it on "
                , extLink "https://platform.openai.com/api-keys" [ class "link" ] [ text "platform.openai.com/api-keys" ]
                , text "."
                ]
        , confirm = "Save"
        , cancel = "Cancel"
        , onConfirm = updateLlmKey >> T.send
        }
        ""


view : (Msg -> msg) -> (Cmd msg -> msg) -> (List msg -> msg) -> (String -> msg) -> (SourceId -> SqlQueryOrigin -> msg) -> msg -> HtmlId -> Erd -> Model -> Html msg
view wrap send batch toastSuccess openDataExplorer onClose titleId erd model =
    let
        ( sourceHtmlId, promptHtmlId, sqlHtmlId ) =
            ( model.id ++ "-source", model.id ++ "-prompt", model.id ++ "-sql" )
    in
    div [ class "" ]
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline Icon.Sparkles "text-primary-600"
                ]
            , div [ css [ "mt-3 w-full text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Generate SQL"
                    , Badge.basic Tw.green [ class "ml-1" ] [ text "Beta" ] |> Tooltip.br "SQL generation is free while in beta."
                    ]
                , p [ class "mt-1 text-sm leading-6 text-gray-600" ] [ text "Write in plain english the query you want, Azimutt will generate it for you." ]
                , if model.sources |> List.isEmpty then
                    p [ class "mt-4 rounded bg-yellow-50 p-4 text-sm text-yellow-700" ]
                        [ text "SQL queries are built for a specific database"
                        , br [] []
                        , text "Add a source with URL connection to generate and execute SQL queries."
                        ]

                  else
                    div [ class "mt-4" ]
                        [ div [ class "flex items-center justify-between" ]
                            [ label [ for promptHtmlId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text "What do you want?" ]
                            , if List.length model.sources > 1 then
                                let
                                    sourceValue : SourceIdStr
                                    sourceValue =
                                        model.source |> Maybe.mapOrElse (Tuple3.first >> SourceId.toString) ""
                                in
                                select [ name sourceHtmlId, id sourceHtmlId, onInput (SourceId.fromString >> SetSource >> wrap), class "rounded-md border-gray-300 py-1 pl-2 pr-8 text-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500" ]
                                    ((model.sources |> List.map (\( id, name, _ ) -> { value = SourceId.toString id, label = name })) |> List.map (\i -> option [ value i.value, selected (i.value == sourceValue) ] [ text i.label ]))

                              else
                                text ""
                            ]
                        , div [ class "mt-2" ]
                            [ textarea
                                [ rows 4
                                , name promptHtmlId
                                , id promptHtmlId
                                , value model.prompt
                                , onInput (SetPrompt >> wrap)
                                , disabled model.loading
                                , autofocus True
                                , placeholder "Who is the last created user?"
                                , class "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:text-gray-500 disabled:bg-gray-50"
                                ]
                                []
                            , p [ class "mt-1 text-sm leading-6 text-gray-400" ]
                                [ text "Tip: for best results, describe precisely what you need. Ideally with exact table and column names, use schema exploration to find them."
                                ]
                            ]
                        ]
                , model.generatedSql
                    |> Maybe.map
                        (Result.fold
                            (\err -> p [ class "mt-4 rounded bg-red-50 p-4 text-sm text-red-700" ] [ text err ])
                            (\sql ->
                                div [ class "mt-4" ]
                                    [ label [ for promptHtmlId, class "block text-sm font-medium leading-6 text-gray-900" ] [ text "Generated SQL" ]
                                    , div [ class "mt-2" ]
                                        [ textarea
                                            [ rows (sql |> String.split "\n" |> List.length)
                                            , name sqlHtmlId
                                            , id sqlHtmlId
                                            , value sql
                                            , disabled True
                                            , class "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:text-gray-500 disabled:bg-gray-50"
                                            ]
                                            []
                                        ]
                                    ]
                            )
                        )
                    |> Maybe.withDefault (text "")
                ]
            ]
        , div [ class "px-6 py-3 mt-6 flex flex-col sm:flex-row items-center justify-between sm:flex-row-reverse bg-gray-50 rounded-b-lg gap-3" ]
            [ div [ class "flex flex-col sm:flex-row sm:flex-row-reverse gap-3" ]
                [ model.generatedSql
                    |> Maybe.andThen Result.toMaybe
                    |> Maybe.map2
                        (\( sourceId, _, dbKind ) sql ->
                            Button.primary3 Tw.green [ onClick (batch [ onClose, openDataExplorer sourceId { sql = sql, origin = "llm-generate-sql", db = dbKind } ]), css [ "w-full text-base", sm [ "w-auto text-sm" ] ] ] [ text "Execute SQL" ]
                        )
                        model.source
                    |> Maybe.withDefault (text "")
                , if model.prompt == "" then
                    text ""

                  else if model.loading then
                    Button.primary3 Tw.primary [ disabled True, css [ "w-full text-base", sm [ "w-auto text-sm" ] ] ] [ Icon.loading "mr-2 inline animate-spin", text "Generating SQL" ]

                  else if model.generatedSql == Nothing then
                    Button.primary3 Tw.primary [ onClick (GenerateSql |> wrap), css [ "w-full text-base", sm [ "w-auto text-sm" ] ] ] [ text "Generate SQL" ]

                  else
                    Button.primary3 Tw.primary [ onClick (GenerateSql |> wrap), css [ "w-full text-base", sm [ "w-auto text-sm" ] ] ] [ text "Generate SQL again" ]
                , Button.white3 Tw.gray [ onClick onClose, css [ "w-full text-base", sm [ "w-auto text-sm" ] ] ] [ text "Close" ]
                ]
            , (model.generatedSql |> Maybe.andThen Result.toMaybe)
                |> Maybe.map
                    (\query ->
                        div [ class "flex flex-row gap-1" ]
                            [ Button.transparent3 Tw.gray
                                [ onClick
                                    (batch
                                        [ toastSuccess "Awesome! Enjoy Azimutt AI 🤘"
                                        , Track.generateSqlSucceeded erd.project (model.source |> findSource erd) (getLlmModel erd) model.prompt query |> send
                                        ]
                                    )
                                , css [ "w-full text-base", sm [ "w-auto text-sm" ] ]
                                ]
                                [ Icon.outline Icon.ThumbUp "h-5 w-5" ]
                            , Button.transparent3 Tw.gray
                                [ onClick
                                    (batch
                                        [ toastSuccess ("Ok, noted! We'll try to improve it. Don't hesitate to reach out to discuss more: " ++ Conf.constants.azimuttEmail)
                                        , Track.generateSqlFailed erd.project (model.source |> findSource erd) (getLlmModel erd) model.prompt query |> send
                                        ]
                                    )
                                , css [ "w-full text-base", sm [ "w-auto text-sm" ] ]
                                ]
                                [ Icon.outline Icon.ThumbDown "h-5 w-5" ]
                            ]
                    )
                |> Maybe.withDefault (text "")
            ]
        ]



-- HELPERS


findSource : Erd -> Maybe ( SourceId, SourceName, DatabaseKind ) -> Maybe Source
findSource erd source =
    source |> Maybe.andThen (\( id, _, _ ) -> erd.sources |> List.findBy .id id)


getLlmModel : Erd -> OpenAIModel
getLlmModel erd =
    erd.settings.llm |> Maybe.mapOrElse .model OpenAIModel.default



-- DOCUMENTATION


type alias SharedDocState x =
    { x | llmGenerateSqlDocState : DocState }


type alias DocState =
    { dynamic : Model }


docInit : DocState
docInit =
    { dynamic = init "dynamic" docErd Nothing }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "LlmGenerateSqlBody"
        |> Chapter.renderStatefulComponentList
            [ docComponent "dynamic" (\model -> view docUpdateStateDynamic docSend docBatch docToast docOpenDatExplorer docOnClose docTitleId docErd model.dynamic)
            , docComponentStatic "empty" docModelEmpty
            , docComponentStatic "with prompt" { docModelEmpty | prompt = "Who is Loïc?" }
            , docComponentStatic "loading" { docModelEmpty | prompt = "Who is Loïc?", loading = True }
            , docComponentStatic "with result" { docModelEmpty | prompt = "Who is Loïc?", generatedSql = Ok "SELECT * FROM users WHERE name='Loïc';" |> Just }
            , docComponentStatic "with error" { docModelEmpty | prompt = "Who is Loïc?", generatedSql = Err "Bad API key" |> Just }
            , docComponentStatic "no source" { docModelEmpty | sources = [], source = Nothing }
            , docComponentStatic "multi sources" { docModelEmpty | sources = [ ( docSource.id, docSource.name, PostgreSQL ), ( docSource2.id, docSource2.name, PostgreSQL ) ] }
            ]


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ llmGenerateSqlDocState } -> render llmGenerateSqlDocState )


docComponentStatic : String -> Model -> ( String, SharedDocState x -> Html (ElmBook.Msg state) )
docComponentStatic name model =
    ( name, \_ -> view docWrap docSend docBatch docToast docOpenDatExplorer docOnClose docTitleId docErd { model | id = name } )


docUpdateStateDynamic : Msg -> ElmBook.Msg (SharedDocState x)
docUpdateStateDynamic msg =
    docUpdateState .dynamic (\m s -> { s | dynamic = m }) msg


docUpdateState : (DocState -> Model) -> (Model -> DocState -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdateState get set msg =
    ElmBook.Actions.updateStateWithCmd
        (\s ->
            s.llmGenerateSqlDocState
                |> get
                |> update docOpenPrompt docUpdateLlmKey docErd msg
                |> Tuple.mapFirst (\r -> { s | llmGenerateSqlDocState = s.llmGenerateSqlDocState |> set r })
        )


docWrap : Msg -> ElmBook.Msg state
docWrap _ =
    ElmBook.Actions.logAction "wrap"


docOpenPrompt : Prompt msg -> String -> ElmBook.Msg state
docOpenPrompt _ _ =
    ElmBook.Actions.logAction "openPrompt"


docUpdateLlmKey : String -> ElmBook.Msg state
docUpdateLlmKey _ =
    ElmBook.Actions.logAction "updateLlmKey"


docSend : Cmd msg -> ElmBook.Msg state
docSend _ =
    ElmBook.Actions.logAction "send"


docBatch : List msg -> ElmBook.Msg state
docBatch _ =
    ElmBook.Actions.logAction "batch"


docToast : String -> ElmBook.Msg state
docToast _ =
    ElmBook.Actions.logAction "toast"


docOpenDatExplorer : SourceId -> SqlQueryOrigin -> ElmBook.Msg state
docOpenDatExplorer _ _ =
    ElmBook.Actions.logAction "openDatExplorer"


docOnClose : ElmBook.Msg state
docOnClose =
    ElmBook.Actions.logAction "onClose"


docTitleId : String
docTitleId =
    "modal-id-title"


docModelEmpty : Model
docModelEmpty =
    { id = "", sources = [ ( docSource.id, docSource.name, PostgreSQL ) ], source = Just ( docSource.id, docSource.name, PostgreSQL ), prompt = "", loading = False, generatedSql = Nothing }


docErd : Erd
docErd =
    docSource
        |> Project.create [] "Azimutt"
        |> Erd.create
        |> setLayouts (Dict.fromList [ ( "init layout", docBuildLayout [ ( "users", [ "id", "name" ] ) ] ) ])
        |> setCurrentLayout "init layout"


docSource : Source
docSource =
    { id = SourceId.one
    , name = "azimutt_dev"
    , kind = DatabaseConnection PostgreSQL (Just "postgresql://postgres:postgres@localhost/azimutt_dev") DatabaseUrlStorage.Project
    , content = Array.empty
    , tables =
        [ { docTableEmpty
            | name = "users"
            , columns =
                [ { docColumnEmpty | name = "id", kind = "uuid" }
                , { docColumnEmpty | name = "name", kind = "varchar" }
                ]
                    |> Dict.fromListIndexedMap (\i c -> ( c.name, { c | index = i + 1 } ))
          }
        , { docTableEmpty
            | name = "events"
            , columns =
                [ { docColumnEmpty | name = "id", kind = "uuid" }
                , { docColumnEmpty | name = "name", kind = "varchar" }
                , { docColumnEmpty | name = "created_by", kind = "uuid" }
                ]
                    |> Dict.fromListIndexedMap (\i c -> ( c.name, { c | index = i + 1 } ))
          }
        ]
            |> Dict.fromListMap (\t -> ( ( t.schema, t.name ), { t | id = ( t.schema, t.name ) } ))
    , relations =
        [ docBuildRelation ( "events", "created_by" ) ( "users", "id" )
        ]
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


docSource2 : Source
docSource2 =
    { id = SourceId.two
    , name = "cockpit_dev"
    , kind = DatabaseConnection PostgreSQL (Just "postgresql://postgres:postgres@localhost/cockpit_dev") DatabaseUrlStorage.Project
    , content = Array.empty
    , tables = Dict.empty
    , relations = []
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


docTableEmpty : Table
docTableEmpty =
    Table.empty


docColumnEmpty : Column
docColumnEmpty =
    Column.empty


docBuildRelation : ( TableName, ColumnName ) -> ( TableName, ColumnName ) -> Relation
docBuildRelation ( srcTable, srcColumn ) ( refTable, refColumn ) =
    { id = ( ( ( "", srcTable ), srcColumn ), ( ( "", refTable ), refColumn ) ), name = "", src = { table = ( "", srcTable ), column = Nel srcColumn [] }, ref = { table = ( "", refTable ), column = Nel refColumn [] } }


docBuildLayout : List ( TableIdStr, List ColumnPathStr ) -> ErdLayout
docBuildLayout tables =
    ErdLayout.empty Time.zero
        |> setTables
            (tables
                |> List.map
                    (\( table, columns ) ->
                        { id = TableId.parse table
                        , props = ErdTableProps Nothing Position.zeroGrid Size.zeroCanvas Tw.red True True True
                        , columns = columns |> List.map ColumnPath.fromString |> ErdColumnProps.createAll
                        , relatedTables = Dict.empty
                        }
                    )
            )

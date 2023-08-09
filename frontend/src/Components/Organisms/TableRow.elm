module Components.Organisms.TableRow exposing (DocState, Model, Msg(..), SharedDocState, doc, docInit, init, update, view)

import Array
import Components.Atoms.Icon as Icon
import Components.Atoms.Icons as Icons
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dl, dt, p, span, text)
import Html.Attributes exposing (class, classList, id, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Html.Events exposing (onDblClick, onPointerUp)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DateTime as DateTime
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Nel as Nel exposing (Nel)
import Libs.Result as Result
import Libs.Set as Set
import Libs.String as String
import Libs.Tailwind exposing (TwClass, focus)
import Libs.Time as Time
import Models.DbSource as DbSource exposing (DbSource)
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Position as Position
import Models.Project.Column exposing (Column)
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableRow as TableRow exposing (FailureState, LoadingState, State(..), SuccessState, TableRow, TableRowValue)
import Models.QueryResult exposing (QueryResult, QueryResultSuccess)
import Models.Size as Size
import Ports
import Services.Lenses exposing (mapSelected, mapState, setState)
import Services.QueryBuilder as QueryBuilder exposing (RowQuery)
import Set
import Time


type alias Model =
    TableRow


type Msg
    = GotResult QueryResult
    | ExpandValue ColumnName
    | ToggleValue ColumnName
    | ToggleHiddenValues
    | Refresh



-- INIT


dbPrefix : String
dbPrefix =
    "table-row"


init : TableRow.Id -> Time.Posix -> DbSourceInfo -> RowQuery -> ( TableRow, Cmd msg )
init id now source query =
    let
        queryStr : String
        queryStr =
            QueryBuilder.findRow source.db.kind query
    in
    ( { id = id
      , position = Position.zeroGrid
      , size = Size.zeroCanvas
      , source = source.id
      , query = query
      , state = StateLoading { query = queryStr, startedAt = now }
      , selected = False
      }
      -- TODO: add tracking with editor source (visual or query)
    , Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt id) source.db.url queryStr
    )


initFailure : String -> Time.Posix -> Time.Posix -> String -> State
initFailure query started finished err =
    StateFailure { query = query, error = err, startedAt = started, failedAt = finished }


initSuccess : Time.Posix -> Time.Posix -> QueryResultSuccess -> State
initSuccess started finished res =
    StateSuccess
        { values = res.columns |> List.filterMap (\c -> res.rows |> List.head |> Maybe.andThen (Dict.get c.name) |> Maybe.map (\v -> { column = c.name, value = v }))
        , hidden = Set.empty
        , expanded = Set.empty
        , showHidden = False
        , startedAt = started
        , loadedAt = finished
        }



-- UPDATE


update : Time.Posix -> List Source -> Msg -> Model -> ( Model, Cmd msg )
update now sources msg model =
    case msg of
        GotResult res ->
            ( model |> mapState (mapLoading (\l -> res.result |> Result.fold (initFailure l.query res.started res.finished) (initSuccess res.started res.finished))), Cmd.none )

        ExpandValue column ->
            ( model |> mapState (mapSuccess (\s -> { s | expanded = s.expanded |> Set.toggle column })), Cmd.none )

        ToggleValue column ->
            ( model |> mapState (mapSuccess (\s -> { s | hidden = s.hidden |> Set.toggle column })), Cmd.none )

        ToggleHiddenValues ->
            ( model |> mapState (mapSuccess (\s -> { s | showHidden = not s.showHidden })), Cmd.none )

        Refresh ->
            sources
                -- TODO: show error if can't find source or if not database
                -- TODO: allow to change source for a table row? (click on the footer)
                |> List.findBy .id model.source
                |> Maybe.andThen DbSourceInfo.fromSource
                |> Maybe.mapOrElse
                    (\s ->
                        let
                            queryStr : String
                            queryStr =
                                QueryBuilder.findRow s.db.kind model.query
                        in
                        ( model |> setState (StateLoading { query = queryStr, startedAt = now })
                        , Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt model.id) s.db.url queryStr
                        )
                    )
                    ( model, Cmd.none )


mapLoading : (LoadingState -> State) -> State -> State
mapLoading f state =
    case state of
        StateLoading s ->
            f s

        _ ->
            state


mapSuccess : (SuccessState -> SuccessState) -> State -> State
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> (HtmlId -> Bool -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> msg -> Time.Posix -> Platform -> SchemaName -> HtmlId -> HtmlId -> Maybe DbSource -> Maybe TableMeta -> TableRow -> Html msg
view wrap toggleDropdown selectItem openTableRow delete now platform defaultSchema openedDropdown htmlId source tableMeta model =
    let
        table : Maybe Table
        table =
            source |> Maybe.andThen (.tables >> Dict.get model.query.table)

        relations : List Relation
        relations =
            source |> Maybe.mapOrElse (.relations >> List.filter (\r -> r.src.table == model.query.table || r.ref.table == model.query.table)) []
    in
    div [ class "max-w-xs bg-white text-default-500 text-xs border", classList [ ( "ring-2 ring-gray-300", model.selected ) ] ]
        [ viewHeader wrap toggleDropdown selectItem delete platform defaultSchema openedDropdown (htmlId ++ "-header") model
        , case model.state of
            StateLoading s ->
                viewLoading s

            StateFailure s ->
                viewFailure s

            StateSuccess s ->
                viewSuccess wrap openTableRow source tableMeta table relations model s
        , viewFooter now source model
        ]


viewHeader : (Msg -> msg) -> (HtmlId -> msg) -> (HtmlId -> Bool -> msg) -> msg -> Platform -> SchemaName -> HtmlId -> HtmlId -> TableRow -> Html msg
viewHeader wrap toggleDropdown selectItem delete platform defaultSchema openedDropdown htmlId model =
    let
        dropdownId : HtmlId
        dropdownId =
            htmlId ++ "-settings"

        table : String
        table =
            TableId.show defaultSchema model.query.table

        filter : String
        filter =
            model.query.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString) |> String.join "/"
    in
    div [ onPointerUp (\e -> selectItem (TableRow.toHtmlId model.id) (e.ctrl || e.shift)) platform, class "p-2 flex items-center bg-default-50 border-b border-gray-200 cursor-pointer" ]
        [ div [ title (table ++ ": " ++ filter), class "flex-grow text-center truncate" ] [ bText table, text (": " ++ filter) ]
        , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = openedDropdown == dropdownId }
            (\m ->
                button
                    [ type_ "button"
                    , id m.id
                    , onClick (toggleDropdown m.id)
                    , ariaExpanded m.isOpen
                    , ariaHaspopup "true"
                    , css [ "flex text-sm opacity-25", focus [ "outline-none" ] ]
                    ]
                    [ span [ class "sr-only" ] [ text "Open table settings" ]
                    , Icon.solid Icon.DotsVertical "w-4 h-4"
                    ]
            )
            (\_ ->
                div []
                    ([ { label = "Refresh data", content = ContextMenu.Simple { action = wrap Refresh } }
                     , { label = "Delete", content = ContextMenu.Simple { action = delete } }
                     ]
                        |> List.map ContextMenu.btnSubmenu
                    )
            )
        ]


viewLoading : LoadingState -> Html msg
viewLoading res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ Icon.loading "mr-2 inline animate-spin", text "Loading..." ]
        , viewQuery "mt-2 px-3 py-2 text-sm" res.query
        ]


viewFailure : FailureState -> Html msg
viewFailure res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ text "Error" ]
        , div [ class "mt-1 px-6 py-4 block overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
        , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
        , viewQuery "mt-1 px-3 py-2" res.query
        ]


viewSuccess : (Msg -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> Maybe DbSource -> Maybe TableMeta -> Maybe Table -> List Relation -> TableRow -> SuccessState -> Html msg
viewSuccess wrap openTableRow source tableMeta table relations row res =
    let
        ( hiddenValues, values ) =
            res.values |> List.partition (\v -> res.hidden |> Set.member v.column)
    in
    div []
        [ Keyed.node "dl" [ class "divide-y divide-gray-200" ] (values |> List.map (\v -> ( v.column, viewValue wrap openTableRow source row.query.table tableMeta table relations v )))
        , if hiddenValues |> List.isEmpty |> not then
            div [ onClick (ToggleHiddenValues |> wrap), class "px-2 py-1 font-medium border-t border-gray-200 opacity-75 cursor-pointer" ]
                [ text ("... " ++ (hiddenValues |> String.pluralizeL " more value")) ]

          else
            div [] []
        , if res.showHidden && (hiddenValues |> List.isEmpty |> not) then
            Keyed.node "dl" [ class "divide-y divide-gray-200 border-t border-gray-200 opacity-50" ] (hiddenValues |> List.map (\v -> ( v.column, viewValue wrap openTableRow source row.query.table tableMeta table relations v )))

          else
            dl [] []
        ]


viewValue : (Msg -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> msg) -> Maybe DbSource -> TableId -> Maybe TableMeta -> Maybe Table -> List Relation -> TableRowValue -> Html msg
viewValue wrap openTableRow source id tableMeta table relations value =
    let
        column : Maybe Column
        column =
            table |> Maybe.andThen (\t -> t.columns |> Dict.get value.column)

        meta : Maybe ColumnMeta
        meta =
            tableMeta |> Maybe.andThen (\m -> m.columns |> Dict.get value.column)

        linkTo : Maybe ColumnRef
        linkTo =
            if value.value == DbNull then
                Nothing

            else
                relations |> List.find (\r -> r.src.table == id && r.src.column.head == value.column) |> Maybe.map .ref

        linkedBy : List ColumnRef
        linkedBy =
            if value.value == DbNull then
                []

            else
                relations |> List.filter (\r -> r.ref.table == id && r.ref.column.head == value.column) |> List.map .src
    in
    div [ onDblClick (\_ -> ToggleValue value.column |> wrap) Platform.PC, class "px-2 py-1 flex justify-between font-medium hover:bg-gray-50" ]
        [ dt [ class "whitespace-pre" ]
            [ text value.column
            , column |> Maybe.andThen .comment |> Maybe.mapOrElse (\c -> span [ title c.text, class "ml-1 opacity-50" ] [ Icon.outline Icons.comment "w-3 h-3 inline" ]) (text "")
            , meta |> Maybe.andThen .notes |> Maybe.mapOrElse (\notes -> span [ title notes, class "ml-1 opacity-50" ] [ Icon.outline Icons.notes "w-3 h-3 inline" ]) (text "")
            ]
        , dd [ title (DbValue.toString value.value), class "ml-3 opacity-50 truncate" ]
            [ text (DbValue.toString value.value)
            ]
        , Maybe.map2
            (\r s ->
                button
                    [ type_ "button"
                    , onClick (openTableRow (DbSource.toInfo s) { table = r.table, primaryKey = Nel { column = r.column, value = value.value } [] })
                    , class "ml-1 opacity-50"
                    ]
                    [ Icon.solid Icon.ExternalLink "w-3 h-3 inline" ]
            )
            linkTo
            source
            |> Maybe.withDefault (text "")
        ]


viewQuery : TwClass -> String -> Html msg
viewQuery classes query =
    div [ css [ "block overflow-x-auto rounded bg-gray-50 border border-gray-200", classes ] ] [ text query ]


viewFooter : Time.Posix -> Maybe DbSource -> Model -> Html msg
viewFooter now source model =
    let
        time : Time.Posix
        time =
            case model.state of
                StateLoading s ->
                    s.startedAt

                StateFailure s ->
                    s.failedAt

                StateSuccess s ->
                    s.loadedAt
    in
    div [ class "px-3 py-1 bg-default-50 text-right italic border-t border-gray-200" ]
        [ text "from "
        , source |> Maybe.mapOrElse (\s -> text s.name) (span [ title (SourceId.toString model.source) ] [ text "unknown source" ])
        , text ", "
        , span [ title (DateTime.toIso time) ] [ text (DateTime.human now time) ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableRowDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId
    , user : Model
    , event : Model
    , failure : Model
    , loading : Model
    }


docInit : DocState
docInit =
    { openedDropdown = ""
    , user = docSuccessUser
    , event = docSuccessEvent
    , failure = docFailure
    , loading = docLoading
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "TableRow"
        |> Chapter.renderStatefulComponentList
            [ ( "table row"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .user (\s m -> { s | user = m }) "table-row-users"
                        , docView tableRowDocState .event (\s m -> { s | event = m }) "table-row-event"
                        ]
              )
            , ( "error", \{ tableRowDocState } -> div [ class "p-3 bg-gray-100" ] [ docView tableRowDocState .failure (\s m -> { s | failure = m }) "table-row-failure" ] )
            , ( "loading", \{ tableRowDocState } -> div [ class "p-3 bg-gray-100" ] [ docView tableRowDocState .loading (\s m -> { s | loading = m }) "table-row-loading" ] )
            ]


docView : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Html (ElmBook.Msg (SharedDocState x))
docView s get set htmlId =
    view (docUpdate s get set) (docToggleDropdown s) (docSelectItem s get set) docOpenTableRow docDelete docNow docPlatform docDefaultSchema s.openedDropdown htmlId (docSource |> DbSource.fromSource) (Just docTableMeta) (get s)


docSuccessUser : TableRow
docSuccessUser =
    { id = 1
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = SourceId.zero
    , query = { table = ( "public", "users" ), primaryKey = Nel { column = Nel "id" [], value = DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a" } [] }
    , state =
        StateSuccess
            { values =
                [ { column = "id", value = DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a" }
                , { column = "slug", value = DbString "loicknuchel" }
                , { column = "name", value = DbString "Loïc Knuchel" }
                , { column = "email", value = DbString "loicknuchel@gmail.com" }
                , { column = "provider", value = DbString "github" }
                , { column = "provider_uid", value = DbString "653009" }
                , { column = "avatar", value = DbString "https://avatars.githubusercontent.com/u/653009?v=4" }
                , { column = "github_username", value = DbString "loicknuchel" }
                , { column = "twitter_username", value = DbString "loicknuchel" }
                , { column = "is_admin", value = DbBool True }
                , { column = "hashed_password", value = DbNull }
                , { column = "last_signin", value = DbString "2023-04-27 17:55:11.582485" }
                , { column = "created_at", value = DbString "2023-04-27 17:55:11.612429" }
                , { column = "updated_at", value = DbString "2023-07-19 20:57:53.438550" }
                , { column = "confirmed_at", value = DbString "2023-04-27 17:55:11.582485" }
                , { column = "deleted_at", value = DbNull }
                , { column = "data", value = DbObject (Dict.fromList [ ( "attributed_to", DbNull ), ( "attributed_from", DbNull ) ]) }
                , { column = "onboarding", value = DbNull }
                , { column = "provider_data", value = DbObject (Dict.fromList [ ( "id", DbInt 653009 ), ( "bio", DbString "Principal engineer at Doctolib" ), ( "blog", DbString "https://loicknuchel.fr" ), ( "plan", DbObject (Dict.fromList [ ( "name", DbString "free" ) ]) ) ]) }
                ]
            , hidden = Set.fromList [ "provider", "provider_uid", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "hashed_password" ]
            , expanded = Set.empty
            , showHidden = False
            , startedAt = Time.millisToPosix 1690964408438
            , loadedAt = Time.millisToPosix 1690964408438
            }
    , selected = False
    }


docSuccessEvent : TableRow
docSuccessEvent =
    { id = 2
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , state =
        StateSuccess
            { values =
                [ { column = "id", value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" }
                , { column = "name", value = DbString "editor_source_created" }
                , { column = "data", value = DbNull }
                , { column = "details", value = DbObject (Dict.fromList [ ( "kind", DbString "DatabaseConnection" ), ( "format", DbString "database" ), ( "nb_table", DbInt 12 ), ( "nb_relation", DbInt 25 ) ]) }
                , { column = "created_by", value = DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a" }
                , { column = "created_at", value = DbString "2023-04-29 15:25:40.659800" }
                , { column = "organization_id", value = DbString "2d803b04-90d7-4e05-940f-5e887470b595" }
                , { column = "project_id", value = DbString "a2cf8a87-0316-40eb-98ce-72659dae9420" }
                ]
            , hidden = Set.fromList []
            , expanded = Set.empty
            , showHidden = False
            , startedAt = Time.millisToPosix 1691079663421
            , loadedAt = Time.millisToPosix 1691079663421
            }
    , selected = False
    }


docLoading : TableRow
docLoading =
    { id = 3
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , state = StateLoading { query = "SELECT * FROM public.events WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", startedAt = Time.millisToPosix 1691079663421 }
    , selected = False
    }


docFailure : TableRow
docFailure =
    { id = 4
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , state = StateFailure { query = "SELECT * FROM public.event WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", error = "relation \"public.event\" does not exist", startedAt = Time.millisToPosix 1691079663421, failedAt = Time.millisToPosix 1691079663421 }
    , selected = False
    }


docNow : Time.Posix
docNow =
    Time.millisToPosix 1691079793039


docDefaultSchema : SchemaName
docDefaultSchema =
    "public"


docSource : Source
docSource =
    { id = SourceId.one
    , name = "azimutt_dev"
    , kind = DatabaseConnection "postgresql://postgres:postgres@localhost:5432/azimutt_dev"
    , content = Array.empty
    , tables =
        [ docTable "public" "users" [ ( "id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "provider", "varchar", True ), ( "provider_uid", "varchar", True ), ( "avatar", "varchar", False ), ( "github_username", "varchar", True ), ( "twitter_username", "varchar", True ), ( "is_admin", "boolean", False ), ( "hashed_password", "varchar", True ), ( "last_signin", "timestamp", False ), ( "created_at", "timestamp", False ), ( "updated_at", "timestamp", False ), ( "confirmed_at", "timestamp", True ), ( "deleted_at", "timestamp", True ), ( "data", "json", False ), ( "onboarding", "json", False ), ( "provider_data", "json", True ), ( "tags", "varchar[]", False ) ]
        , docTable "public" "organizations" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "projects" [ ( "id", "uuid", False ), ( "organization_id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "events" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "details", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ), ( "organization_id", "uuid", True ), ( "project_id", "uuid", True ) ]
        , docTable "public" "city" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "country_code", "varchar", False ), ( "district", "varchar", False ), ( "population", "int", False ) ]
        ]
            |> Dict.fromListMap .id
    , relations =
        [ docRelation ( "public", "organizations", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "projects", "organization_id" ) ( "public", "organizations", "id" )
        , docRelation ( "public", "projects", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "events", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "events", "organization_id" ) ( "public", "organizations", "id" )
        , docRelation ( "public", "events", "project_id" ) ( "public", "projects", "id" )
        ]
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


docTableMeta : TableMeta
docTableMeta =
    { notes = Nothing
    , tags = []
    , columns = Dict.empty
    }


docTable : SchemaName -> TableName -> List ( ColumnName, ColumnType, Bool ) -> Table
docTable schema name columns =
    { id = ( schema, name )
    , schema = schema
    , name = name
    , view = False
    , columns = columns |> List.indexedMap (\i ( col, kind, nullable ) -> { index = i, name = col, kind = kind, nullable = nullable, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }) |> Dict.fromListMap .name
    , primaryKey = Just { name = Just (name ++ "_pk"), columns = Nel (Nel "id" []) [], origins = [] }
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , origins = []
    }


docRelation : ( SchemaName, TableName, ColumnName ) -> ( SchemaName, TableName, ColumnName ) -> Relation
docRelation ( fromSchema, fromTable, fromColumn ) ( toSchema, toTable, toColumn ) =
    Relation.new (fromTable ++ "." ++ fromColumn ++ "->" ++ toTable ++ "." ++ toColumn) { table = ( fromSchema, fromTable ), column = Nel fromColumn [] } { table = ( toSchema, toTable ), column = Nel toColumn [] } []


docPlatform : Platform
docPlatform =
    Platform.PC


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set msg =
    s |> get |> update Time.zero [ docSource ] msg |> Tuple.first |> set s |> docSetState


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | tableRowDocState = state })


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docSelectItem : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Bool -> ElmBook.Msg (SharedDocState x)
docSelectItem s get set _ _ =
    s |> get |> mapSelected not |> set s |> docSetState


docOpenTableRow : DbSourceInfo -> QueryBuilder.RowQuery -> ElmBook.Msg state
docOpenTableRow _ _ =
    logAction "openTableRow"


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"

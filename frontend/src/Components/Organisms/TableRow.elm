module Components.Organisms.TableRow exposing (DocState, Model, Msg(..), SharedDocState, doc, docInit, update, view)

import Array
import Components.Atoms.Icon as Icon
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Dict
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dl, dt, span, text)
import Html.Attributes exposing (class, id, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Html.Events exposing (onDblClick)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DateTime as DateTime
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform as Platform
import Libs.Nel as Nel exposing (Nel)
import Libs.Set as Set
import Libs.String as String
import Libs.Tailwind exposing (focus)
import Libs.Time as Time
import Models.JsValue as JsValue
import Models.Position as Position
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId
import Models.Project.TableName exposing (TableName)
import Models.Project.TableRow exposing (TableRow, TableRowValue)
import Models.Size as Size
import Services.QueryBuilder exposing (RowQuery)
import Set
import Time


type alias Model =
    TableRow


type Msg
    = ExpandValue ColumnName
    | ToggleValue ColumnName
    | ToggleHiddenValues
    | Refresh



-- UPDATE


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        ExpandValue column ->
            ( { model | expanded = model.expanded |> Set.toggle column }, Cmd.none )

        ToggleValue column ->
            ( { model | hidden = model.hidden |> Set.toggle column }, Cmd.none )

        ToggleHiddenValues ->
            ( { model | showHidden = not model.showHidden }, Cmd.none )

        Refresh ->
            -- TODO!
            ( model, Cmd.none )



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> msg -> Time.Posix -> SchemaName -> HtmlId -> HtmlId -> List Source -> TableRow -> Html msg
view wrap toggleDropdown delete now defaultSchema openedDropdown htmlId sources model =
    let
        ( hiddenValues, values ) =
            model.values |> List.partition (\v -> model.hidden |> Set.member v.column)
    in
    div [ class "max-w-xs border text-xs" ]
        [ viewHeader wrap toggleDropdown delete defaultSchema openedDropdown (htmlId ++ "-header") model.query
        , Keyed.node "dl" [ class "divide-y divide-gray-200 border-t border-b border-gray-200" ] (values |> List.map (\v -> ( v.column, viewValue wrap v )))
        , if List.length hiddenValues > 0 then
            div [ onClick (ToggleHiddenValues |> wrap), class "px-2 py-1 font-medium text-gray-500 cursor-pointer opacity-75" ]
                [ text ("... " ++ (hiddenValues |> String.pluralizeL " more value")) ]

          else
            div [] []
        , if model.showHidden then
            Keyed.node "dl" [ class "divide-y divide-gray-200 border-t border-b border-gray-200 opacity-50" ] (hiddenValues |> List.map (\v -> ( v.column, viewValue wrap v )))

          else
            dl [] []
        , viewFooter now sources model
        ]


viewHeader : (Msg -> msg) -> (HtmlId -> msg) -> msg -> SchemaName -> HtmlId -> HtmlId -> RowQuery -> Html msg
viewHeader wrap toggleDropdown delete defaultSchema openedDropdown htmlId query =
    let
        dropdownId : HtmlId
        dropdownId =
            htmlId ++ "-settings"

        table : String
        table =
            TableId.show defaultSchema query.table

        filter : String
        filter =
            query.primaryKey |> Nel.toList |> List.map .value |> String.join "/"
    in
    div [ class "p-2 flex items-center bg-gray-100" ]
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


viewValue : (Msg -> msg) -> TableRowValue -> Html msg
viewValue wrap value =
    div [ onDblClick (\_ -> ToggleValue value.column |> wrap) Platform.PC, class "px-2 py-1 flex justify-between font-medium hover:bg-gray-50" ]
        [ dt [ class "text-gray-500" ] [ text value.column ]
        , dd [ title (JsValue.toString value.value), class "ml-3 text-gray-900 truncate" ]
            [ text (JsValue.toJson value.value)
            ]
        ]


viewFooter : Time.Posix -> List Source -> Model -> Html msg
viewFooter now sources model =
    div [ class "px-3 py-1 bg-gray-100 text-gray-500 text-right italic" ]
        [ text "from "
        , sources |> List.findBy .id model.source |> Maybe.mapOrElse (\s -> text s.name) (span [ title (SourceId.toString model.source) ] [ text "unknown source" ])
        , text " "
        , span [ title (DateTime.toIso model.loadedAt) ] [ text (DateTime.human now model.loadedAt) ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableRowDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, user : TableRow, event : TableRow }


docInit : DocState
docInit =
    { openedDropdown = "", user = docUserTableRow, event = docEventTableRow }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "TableRow"
        |> Chapter.renderStatefulComponentList
            [ ( "table row"
              , \{ tableRowDocState } ->
                    div [ class "p-3 flex items-start space-x-3" ]
                        [ view (docUpdate tableRowDocState .user (\s m -> { s | user = m })) (docToggleDropdown tableRowDocState) docDelete docNow docDefaultSchema tableRowDocState.openedDropdown "table-row-users" docSources tableRowDocState.user
                        , view (docUpdate tableRowDocState .event (\s m -> { s | event = m })) (docToggleDropdown tableRowDocState) docDelete docNow docDefaultSchema tableRowDocState.openedDropdown "table-row-events" docSources tableRowDocState.event
                        ]
              )
            ]


docUserTableRow : TableRow
docUserTableRow =
    { position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = SourceId.zero
    , query = { table = ( "public", "users" ), primaryKey = Nel { column = Nel "id" [], kind = "uuid", value = "11bd9544-d56a-43d7-9065-6f1f25addf8a" } [] }
    , values =
        [ { column = "id", value = JsValue.String "11bd9544-d56a-43d7-9065-6f1f25addf8a" }
        , { column = "slug", value = JsValue.String "loicknuchel" }
        , { column = "name", value = JsValue.String "Loïc Knuchel" }
        , { column = "email", value = JsValue.String "loicknuchel@gmail.com" }
        , { column = "provider", value = JsValue.String "github" }
        , { column = "provider_uid", value = JsValue.String "653009" }
        , { column = "avatar", value = JsValue.String "https://avatars.githubusercontent.com/u/653009?v=4" }
        , { column = "github_username", value = JsValue.String "loicknuchel" }
        , { column = "twitter_username", value = JsValue.String "loicknuchel" }
        , { column = "is_admin", value = JsValue.Bool True }
        , { column = "hashed_password", value = JsValue.Null }
        , { column = "last_signin", value = JsValue.String "2023-04-27 17:55:11.582485" }
        , { column = "created_at", value = JsValue.String "2023-04-27 17:55:11.612429" }
        , { column = "updated_at", value = JsValue.String "2023-07-19 20:57:53.438550" }
        , { column = "confirmed_at", value = JsValue.String "2023-04-27 17:55:11.582485" }
        , { column = "deleted_at", value = JsValue.Null }
        , { column = "data", value = JsValue.Object (Dict.fromList [ ( "attributed_to", JsValue.Null ), ( "attributed_from", JsValue.Null ) ]) }
        , { column = "onboarding", value = JsValue.Null }
        , { column = "provider_data", value = JsValue.Object (Dict.fromList [ ( "id", JsValue.Int 653009 ), ( "bio", JsValue.String "Principal engineer at Doctolib" ), ( "blog", JsValue.String "https://loicknuchel.fr" ), ( "plan", JsValue.Object (Dict.fromList [ ( "name", JsValue.String "free" ) ]) ) ]) }
        ]
    , hidden = Set.fromList [ "provider", "provider_uid", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "hashed_password" ]
    , expanded = Set.empty
    , showHidden = False
    , loadedAt = Time.millisToPosix 1690964408438
    }


docEventTableRow : TableRow
docEventTableRow =
    { position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource1.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], kind = "uuid", value = "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , values =
        [ { column = "id", value = JsValue.String "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" }
        , { column = "name", value = JsValue.String "editor_source_created" }
        , { column = "data", value = JsValue.Null }
        , { column = "details", value = JsValue.Object (Dict.fromList [ ( "kind", JsValue.String "DatabaseConnection" ), ( "format", JsValue.String "database" ), ( "nb_table", JsValue.Int 12 ), ( "nb_relation", JsValue.Int 25 ) ]) }
        , { column = "created_by", value = JsValue.String "11bd9544-d56a-43d7-9065-6f1f25addf8a" }
        , { column = "created_at", value = JsValue.String "2023-04-29 15:25:40.659800" }
        , { column = "organization_id", value = JsValue.String "2d803b04-90d7-4e05-940f-5e887470b595" }
        , { column = "project_id", value = JsValue.String "a2cf8a87-0316-40eb-98ce-72659dae9420" }
        ]
    , hidden = Set.fromList []
    , expanded = Set.empty
    , showHidden = False
    , loadedAt = Time.millisToPosix 1691079663421
    }


docNow : Time.Posix
docNow =
    Time.millisToPosix 1691079793039


docDefaultSchema : SchemaName
docDefaultSchema =
    "public"


docSources : List Source
docSources =
    [ docSource1 ]


docSource1 : Source
docSource1 =
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


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set msg =
    s |> get |> update msg |> Tuple.first |> set s |> docSetState


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | tableRowDocState = state })


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"

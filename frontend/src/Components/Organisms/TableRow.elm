module Components.Organisms.TableRow exposing (DocState, Model, Msg(..), SharedDocState, TableRowHover, TableRowRelation, TableRowRelationColumn, TableRowSuccess, doc, docInit, init, initRelation, initRelationColumn, update, view)

import Array
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Icons as Icons
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Popover as Popover
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dl, dt, p, span, text)
import Html.Attributes exposing (class, classList, id, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Keyed as Keyed
import Libs.Dict as Dict
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
import Libs.Tailwind as Tw exposing (Color, TwClass, focus)
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
import Models.Project.TableRow as TableRow exposing (State(..), TableRow, TableRowValue)
import Models.QueryResult exposing (QueryResult, QueryResultSuccess)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.PositionHint as PositionHint exposing (PositionHint)
import Ports
import Services.Lenses exposing (mapSelected, mapState, setPrevious, setState)
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
    | Cancel
    | Refresh
    | Restore TableRow.SuccessState


type alias TableRowSuccess =
    { row : TableRow, state : TableRow.SuccessState, color : Color }


type alias TableRowRelation =
    { id : String, src : TableRowRelationColumn, ref : TableRowRelationColumn }


type alias TableRowRelationColumn =
    { row : TableRow, state : TableRow.SuccessState, color : Color, value : TableRowValue, index : Int }


type alias TableRowHover =
    ( TableRow.Id, Maybe ColumnName )



-- INIT


dbPrefix : String
dbPrefix =
    "table-row"


init : TableRow.Id -> Time.Posix -> DbSourceInfo -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ( TableRow, Cmd msg )
init id now source query previous hint =
    let
        queryStr : String
        queryStr =
            QueryBuilder.findRow source.db.kind query
    in
    ( { id = id
      , positionHint = hint
      , position = Position.zeroGrid
      , size = Size.zeroCanvas
      , source = source.id
      , query = query
      , state = previous |> Maybe.mapOrElse StateSuccess (StateLoading { query = queryStr, startedAt = now, previous = Nothing })
      , selected = False
      }
      -- TODO: add tracking with editor source (visual or query)
    , previous |> Maybe.mapOrElse (\_ -> Cmd.none) (Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt id) source.db.url queryStr)
    )


initFailure : String -> Maybe TableRow.SuccessState -> Time.Posix -> Time.Posix -> String -> TableRow.State
initFailure query previous started finished err =
    StateFailure { query = query, error = err, startedAt = started, failedAt = finished, previous = previous }


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


initRelationColumn : TableRowSuccess -> ( TableRowValue, Int ) -> TableRowRelationColumn
initRelationColumn row ( value, index ) =
    { row = row.row, state = row.state, color = row.color, value = value, index = index }


initRelation : TableRowRelationColumn -> TableRowRelationColumn -> TableRowRelation
initRelation src ref =
    let
        rowId : RowQuery -> String
        rowId query =
            TableId.toString query.table :: (query.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString)) |> String.join "-"
    in
    { id = [ SourceId.toString src.row.source, rowId src.row.query, String.fromInt src.index, rowId ref.row.query, String.fromInt ref.index ] |> String.join "-", src = src, ref = ref }



-- UPDATE


update : Time.Posix -> List Source -> Msg -> Model -> ( Model, Cmd msg )
update now sources msg model =
    case msg of
        GotResult res ->
            ( model |> mapStateLoading (\l -> res.result |> Result.fold (initFailure l.query l.previous res.started res.finished) (initSuccess res.started res.finished)), Cmd.none )

        ExpandValue column ->
            ( model |> mapState (mapSuccess (\s -> { s | expanded = s.expanded |> Set.toggle column })), Cmd.none )

        ToggleValue column ->
            ( model |> mapState (mapSuccess (\s -> { s | hidden = s.hidden |> Set.toggle column })), Cmd.none )

        ToggleHiddenValues ->
            ( model |> mapState (mapSuccess (\s -> { s | showHidden = not s.showHidden })), Cmd.none )

        Cancel ->
            ( model |> mapStateLoading (\l -> initFailure l.query l.previous l.startedAt now "Query canceled"), Cmd.none )

        Refresh ->
            sources
                -- TODO: show error toast if can't find source or if not database
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
                        ( model |> setState (StateLoading { query = queryStr, startedAt = now, previous = model |> TableRow.stateSuccess })
                        , Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt model.id) s.db.url queryStr
                        )
                    )
                    ( model, Cmd.none )

        Restore success ->
            ( model |> setState (StateSuccess success), Cmd.none )


mapStateLoading : (TableRow.LoadingState -> State) -> TableRow -> TableRow
mapStateLoading f row =
    case row.state of
        StateLoading s ->
            { row | state = f s }

        _ ->
            row


mapLoading : (TableRow.LoadingState -> TableRow.LoadingState) -> State -> State
mapLoading f state =
    case state of
        StateLoading s ->
            StateLoading (f s)

        _ ->
            state


mapFailure : (TableRow.FailureState -> TableRow.FailureState) -> State -> State
mapFailure f state =
    case state of
        StateFailure s ->
            StateFailure (f s)

        _ ->
            state


mapSuccess : (TableRow.SuccessState -> TableRow.SuccessState) -> State -> State
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> (HtmlId -> msg) -> (HtmlId -> Bool -> msg) -> (TableId -> msg) -> (TableRowHover -> Bool -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> msg -> Time.Posix -> Platform -> SchemaName -> HtmlId -> HtmlId -> HtmlId -> Maybe DbSource -> Maybe TableRowHover -> List TableRowRelation -> Color -> Maybe TableMeta -> TableRow -> Html msg
view wrap toggleDropdown openPopover selectItem showTable hover showTableRow delete now platform defaultSchema openedDropdown openedPopover htmlId source hoverRow rowRelations color tableMeta model =
    let
        table : Maybe Table
        table =
            source |> Maybe.andThen (.tables >> Dict.get model.query.table)

        relations : List Relation
        relations =
            source |> Maybe.mapOrElse (.relations >> List.filter (\r -> r.src.table == model.query.table || r.ref.table == model.query.table)) []
    in
    div
        [ onMouseEnter (hover ( model.id, Nothing ) True)
        , onMouseLeave (hover ( model.id, Nothing ) False)
        , class "max-w-xs bg-white text-default-500 text-xs border hover:shadow-md"
        , classList [ ( "ring-2 ring-gray-300", model.selected ) ]
        ]
        [ viewHeader wrap toggleDropdown selectItem showTable delete platform defaultSchema openedDropdown (htmlId ++ "-header") color model
        , case model.state of
            StateLoading s ->
                viewLoading wrap delete s

            StateFailure s ->
                viewFailure wrap delete s

            StateSuccess s ->
                viewSuccess wrap openPopover hover showTableRow source openedPopover (htmlId ++ "-body") hoverRow tableMeta table relations rowRelations color model s
        , viewFooter now source model
        ]


viewHeader : (Msg -> msg) -> (HtmlId -> msg) -> (HtmlId -> Bool -> msg) -> (TableId -> msg) -> msg -> Platform -> SchemaName -> HtmlId -> HtmlId -> Color -> TableRow -> Html msg
viewHeader wrap toggleDropdown selectItem showTable delete platform defaultSchema openedDropdown htmlId color model =
    let
        dropdownId : HtmlId
        dropdownId =
            htmlId ++ "-settings"

        tableLabel : String
        tableLabel =
            TableId.show defaultSchema model.query.table

        filter : String
        filter =
            model.query.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString) |> String.join "/"
    in
    div [ onPointerUp (\e -> selectItem (TableRow.toHtmlId model.id) (e.ctrl || e.shift)) platform, css [ "p-2 flex items-center border-b border-gray-200 cursor-pointer", Tw.bg_50 color ] ]
        [ div [ title (tableLabel ++ ": " ++ filter), class "flex-grow text-center truncate" ]
            [ button [ onClick (showTable model.query.table), title ("Show " ++ tableLabel ++ " table"), css [ Tw.text_500 color, "mr-1 opacity-50" ] ] [ Icon.solid Icon.Eye "w-3 h-3 inline" ]
            , span [ css [ Tw.text_500 color, "font-bold" ] ] [ text tableLabel ]
            , text (": " ++ filter)
            ]
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


viewLoading : (Msg -> msg) -> msg -> TableRow.LoadingState -> Html msg
viewLoading wrap delete res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ Icon.loading "mr-2 inline animate-spin", text "Loading..." ]
        , viewQuery "mt-2 px-3 py-2 text-sm" res.query
        , div [ class "mt-6 flex justify-around" ]
            [ Button.white1 Tw.indigo [ onClick (Cancel |> wrap), title "Cancel fetching data" ] [ text "Cancel" ]
            , res.previous |> Maybe.map (\p -> Button.white1 Tw.emerald [ onClick (Restore p |> wrap), title "Restore previous data" ] [ text "Restore" ]) |> Maybe.withDefault (text "")
            , Button.white1 Tw.red [ onClick delete, title "Remove this row" ] [ text "Delete" ]
            ]
        ]


viewFailure : (Msg -> msg) -> msg -> TableRow.FailureState -> Html msg
viewFailure wrap delete res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ text "Error" ]
        , div [ class "mt-1 px-6 py-4 block overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
        , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
        , viewQuery "mt-1 px-3 py-2" res.query
        , div [ class "mt-6 flex justify-around" ]
            [ Button.white1 Tw.indigo [ onClick (Refresh |> wrap), title "Retry fetching data" ] [ text "Refresh" ]
            , res.previous |> Maybe.map (\p -> Button.white1 Tw.emerald [ onClick (Restore p |> wrap), title "Restore previous data" ] [ text "Restore" ]) |> Maybe.withDefault (text "")
            , Button.white1 Tw.red [ onClick delete, title "Remove this row" ] [ text "Delete" ]
            ]
        ]


viewSuccess : (Msg -> msg) -> (HtmlId -> msg) -> (TableRowHover -> Bool -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> Maybe DbSource -> HtmlId -> HtmlId -> Maybe TableRowHover -> Maybe TableMeta -> Maybe Table -> List Relation -> List TableRowRelation -> Color -> TableRow -> TableRow.SuccessState -> Html msg
viewSuccess wrap openPopover hover showTableRow source openedPopover htmlId hoverRow tableMeta table relations rowRelations color row res =
    let
        ( hiddenValues, values ) =
            res.values |> List.partition (\v -> res.hidden |> Set.member v.column)

        hasHiddenValues : Bool
        hasHiddenValues =
            hiddenValues |> List.isEmpty |> not
    in
    div []
        [ Keyed.node "dl" [ class "divide-y divide-gray-200" ] (values |> List.map (\v -> ( v.column, viewValue wrap hover showTableRow source hoverRow row.query.table tableMeta table relations rowRelations color row v )))
        , if hasHiddenValues then
            let
                popoverId : HtmlId
                popoverId =
                    htmlId ++ "-hidden-values-popover"

                showPopover : Bool
                showPopover =
                    not res.showHidden && openedPopover == popoverId

                popover : Html msg
                popover =
                    if showPopover then
                        Keyed.node "dl" [ class "divide-y divide-gray-200 shadow-md" ] (hiddenValues |> List.map (\v -> ( v.column, viewValue wrap hover showTableRow source hoverRow row.query.table tableMeta table relations rowRelations color row v )))

                    else
                        div [] []
            in
            div []
                [ div [ onClick (ToggleHiddenValues |> wrap), onMouseEnter (openPopover popoverId), onMouseLeave (openPopover ""), class "px-2 py-1 font-medium border-t border-gray-200 opacity-75 cursor-pointer" ]
                    [ text ("... " ++ (hiddenValues |> String.pluralizeL " more value")) ]
                    |> Popover.r popover showPopover
                , if res.showHidden then
                    Keyed.node "dl" [ class "divide-y divide-gray-200 border-t border-gray-200 opacity-50" ] (hiddenValues |> List.map (\v -> ( v.column, viewValue wrap hover showTableRow source hoverRow row.query.table tableMeta table relations rowRelations color row v )))

                  else
                    dl [] []
                ]

          else
            div [] []
        ]


viewValue : (Msg -> msg) -> (TableRowHover -> Bool -> msg) -> (DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> Maybe DbSource -> Maybe TableRowHover -> TableId -> Maybe TableMeta -> Maybe Table -> List Relation -> List TableRowRelation -> Color -> TableRow -> TableRowValue -> Html msg
viewValue wrap hover showTableRow source hoverRow id tableMeta table relations rowRelations color row value =
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

        isColumn : TableRowRelationColumn -> Bool
        isColumn c =
            c.row.id == row.id && c.value.column == value.column

        isHover : TableRowRelationColumn -> TableRowHover -> Bool
        isHover c h =
            h == ( c.row.id, Just c.value.column )

        highlight : Bool
        highlight =
            hoverRow |> Maybe.any (\h -> h == ( row.id, Just value.column ) || (rowRelations |> List.any (\r -> (isColumn r.src && isHover r.ref h) || (isColumn r.ref && isHover r.src h))))
    in
    div
        [ onDblClick (\_ -> ToggleValue value.column |> wrap) Platform.PC
        , onMouseEnter (hover ( row.id, Just value.column ) True)
        , onMouseLeave (hover ( row.id, Just value.column ) False)
        , css
            [ "px-2 py-1 flex justify-between font-medium"
            , if highlight then
                Tw.batch [ Tw.text_500 color, Tw.bg_50 color ]

              else
                "text-default-500 bg-white"
            ]
        ]
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
                    , onClick (showTableRow (DbSource.toInfo s) { table = r.table, primaryKey = Nel { column = r.column, value = value.value } [] } Nothing (Just (PositionHint.PlaceRight row.position row.size)))
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
    , openedPopover : HtmlId
    , user : Model
    , event : Model
    , failure : Model
    , loading : Model
    }


docInit : DocState
docInit =
    { openedDropdown = ""
    , openedPopover = ""
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
            , ( "error"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .failure (\s m -> { s | failure = m }) "table-row-failure"
                        , docView tableRowDocState (.failure >> mapState (mapFailure (setPrevious (TableRow.stateSuccess docSuccessUser)))) (\s m -> { s | failure = m }) "table-row-failure-with-previous"
                        ]
              )
            , ( "loading"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .loading (\s m -> { s | loading = m }) "table-row-loading"
                        , docView tableRowDocState (.loading >> mapState (mapLoading (setPrevious (TableRow.stateSuccess docSuccessUser)))) (\s m -> { s | loading = m }) "table-row-loading-with-previous"
                        ]
              )
            ]


docView : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Html (ElmBook.Msg (SharedDocState x))
docView s get set htmlId =
    view (docUpdate s get set) (docToggleDropdown s) (docOpenPopover s) (docSelectItem s get set) docShowTable docHoverTableRow docShowTableRow docDelete docNow docPlatform docDefaultSchema s.openedDropdown s.openedPopover htmlId (docSource |> DbSource.fromSource) Nothing [] Tw.indigo (Just docTableMeta) (get s)


docSuccessUser : TableRow
docSuccessUser =
    { id = 1
    , positionHint = Nothing
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
    , positionHint = Nothing
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
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , state = StateLoading { query = "SELECT * FROM public.events WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", startedAt = Time.millisToPosix 1691079663421, previous = Nothing }
    , selected = False
    }


docFailure : TableRow
docFailure =
    { id = 4
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , query = { table = ( "public", "events" ), primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } [] }
    , state = StateFailure { query = "SELECT * FROM public.event WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", error = "relation \"public.event\" does not exist", startedAt = Time.millisToPosix 1691079663421, failedAt = Time.millisToPosix 1691079663421, previous = Nothing }
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


docOpenPopover : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docOpenPopover s id =
    docSetState { s | openedPopover = id }


docSelectItem : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Bool -> ElmBook.Msg (SharedDocState x)
docSelectItem s get set _ _ =
    s |> get |> mapSelected not |> set s |> docSetState


docShowTable : TableId -> ElmBook.Msg state
docShowTable _ =
    logAction "showTable"


docHoverTableRow : TableRowHover -> Bool -> ElmBook.Msg state
docHoverTableRow _ _ =
    logAction "hoverTableRow"


docShowTableRow : DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ElmBook.Msg state
docShowTableRow _ _ _ _ =
    logAction "showTableRow"


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"

module Components.Slices.DataExplorer exposing (BasicExplorer, DataExplorerTab(..), DocState, Model, Msg(..), QueryEditor, SavedQuery, SharedDocState, doc, docInit, init)

import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.DataExplorerRow as DataExplorerRow
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, nav, text, textarea)
import Html.Attributes exposing (autofocus, class, disabled, id, name, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Tailwind exposing (TwClass)
import Libs.Task as T
import Libs.Time as Time
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.SourceInfo as SourceInfo
import Models.UserId exposing (UserId)
import Services.Lenses exposing (setContent)
import Services.QueryBuilder as QueryBuilder
import Task
import Time



-- TODO:
--  - Simple exploration vs SQL editor on the left
--  - List of Query Results on the right
--  - Row details in the side bar
--  - Linked rows in the side bar
--  - stackable side bars


type alias Model =
    { activeTab : DataExplorerTab
    , source : Maybe ( Source, DatabaseUrl )
    , tabVisualEditor : BasicExplorer
    , tabQueryEditor : QueryEditor
    , savedQueries : List SavedQuery
    , resultsSeq : Int
    , results : List DataExplorerQuery.Model
    , details : List DataExplorerRow.Model
    }


type DataExplorerTab
    = VisualEditorTab
    | QueryEditorTab


type alias BasicExplorer =
    { builder : QueryBuilder.TableQuery, query : String }


type alias QueryEditor =
    { content : String }


type alias SavedQuery =
    { name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId }


type Msg
    = Noop
    | ChangeTab DataExplorerTab
    | UpdateQuery String
    | RunQuery String
    | TimedQuery String Time.Posix
    | QueryMsg Int DataExplorerQuery.Msg



-- INIT


init : List SavedQuery -> Maybe String -> Model
init savedQueries query =
    { activeTab = query |> Maybe.mapOrElse (\_ -> QueryEditorTab) VisualEditorTab
    , source = Nothing
    , tabVisualEditor = { builder = { table = Nothing, filters = [] }, query = "" }
    , tabQueryEditor = { content = query |> Maybe.withDefault "" }
    , savedQueries = savedQueries
    , resultsSeq = 1
    , results = []
    , details = []
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        ChangeTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        UpdateQuery content ->
            ( { model | tabQueryEditor = model.tabQueryEditor |> setContent content }, Cmd.none )

        RunQuery query ->
            ( model, Time.now |> Task.perform (TimedQuery query >> wrap) )

        TimedQuery query now ->
            -- TODO: launch query with Cmd
            model.source
                |> Maybe.map
                    (\( source, _ ) ->
                        let
                            result : DataExplorerQuery.Model
                            result =
                                DataExplorerQuery.init model.resultsSeq (Source.toInfo source) query now
                        in
                        ( { model | resultsSeq = model.resultsSeq + 1, results = result :: model.results }, Cmd.none )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        QueryMsg id m ->
            let
                ( results, cmds ) =
                    model.results
                        |> List.map
                            (\r ->
                                if r.id == id then
                                    DataExplorerQuery.update (QueryMsg r.id >> wrap) m r

                                else
                                    ( r, Cmd.none )
                            )
                        |> List.unzip
            in
            ( { model | results = results }, Cmd.batch cmds )

        _ ->
            ( model, Noop |> wrap |> T.send )



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> Time.Posix -> HtmlId -> List Source -> Model -> Html msg
view wrap openDropdown now openedDropdown sources model =
    div [ class "flex h-full" ]
        [ div [ class "flex-1 flex flex-col overflow-y-auto border-r" ]
            [ viewHeader wrap model.activeTab
            , case model.activeTab of
                VisualEditorTab ->
                    viewVisualExplorer

                QueryEditorTab ->
                    viewQueryEditor wrap model.tabQueryEditor
            ]
        , if sources |> List.isEmpty then
            div [] []

          else
            div [] []
        , div [ class "flex-1 overflow-y-auto bg-gray-50 pb-20" ]
            (model.results
                |> List.map
                    (\r ->
                        div [ class "m-3 px-3 py-2 rounded-md bg-white shadow" ]
                            [ DataExplorerQuery.view (QueryMsg r.id >> wrap) openDropdown now openedDropdown r
                            ]
                    )
            )
        ]


viewHeader : (Msg -> msg) -> DataExplorerTab -> Html msg
viewHeader wrap activeTab =
    div [ class "border-b border-gray-200" ]
        [ div [ class "sm:flex sm:items-baseline" ]
            [ h3 [ class "text-base font-semibold leading-6 text-gray-900" ] [ text "Data explorer" ]
            , div [ class "mt-4 sm:ml-10 sm:mt-0" ]
                [ nav [ class "-mb-px flex space-x-8" ]
                    ([ VisualEditorTab, QueryEditorTab ] |> List.map (viewHeaderTab wrap activeTab))
                ]
            ]
        ]


viewHeaderTab : (Msg -> msg) -> DataExplorerTab -> DataExplorerTab -> Html msg
viewHeaderTab wrap active tab =
    let
        style : TwClass
        style =
            if tab == active then
                "border-indigo-500 text-indigo-600"

            else
                "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
    in
    button [ type_ "button", onClick (ChangeTab tab |> wrap), css [ style, "whitespace-nowrap border-b-2 px-1 pb-4 text-sm font-medium" ] ]
        [ text
            (case tab of
                VisualEditorTab ->
                    "Visual editor"

                QueryEditorTab ->
                    "Query editor"
            )
        ]


viewVisualExplorer : Html msg
viewVisualExplorer =
    div [] [ text "Visual Explorer" ]


viewQueryEditor : (Msg -> msg) -> QueryEditor -> Html msg
viewQueryEditor wrap editor =
    div [ class "flex-1 flex flex-col relative" ]
        [ textarea
            [ name "comment"
            , id "comment"
            , value editor.content
            , onInput (UpdateQuery >> wrap)
            , autofocus True
            , placeholder "Write your database query"
            , class "m-3 py-1.5 block flex-1 rounded-md border-0 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ]
            []
        , div [ class "absolute bottom-6 right-6" ]
            [ button
                [ type_ "button"
                , onClick (editor.content |> RunQuery |> wrap)
                , disabled (editor.content == "")
                , class "inline-flex items-center bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-indigo-300"
                ]
                [ text "Run query" ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, model : Model }


docInit : DocState
docInit =
    { openedDropdown = "", model = docModel }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorer"
        |> Chapter.renderStatefulComponentList
            [ ( "data explorer"
              , \{ dataExplorerDocState } ->
                    let
                        s : DocState
                        s =
                            dataExplorerDocState
                    in
                    div [ style "height" "500px" ]
                        [ view (docUpdate s .model (\s2 m2 -> { s2 | model = m2 })) (docOpenDropdown s) Time.zero s.openedDropdown [] s.model
                        ]
              )
            ]


docModel : Model
docModel =
    { activeTab = QueryEditorTab
    , source = Nothing
    , tabVisualEditor = { builder = { table = Nothing, filters = [] }, query = "" }
    , tabQueryEditor = { content = "" }
    , savedQueries = []
    , resultsSeq = 3
    , results =
        [ { id = 2
          , source = SourceInfo.database Time.zero SourceId.zero "azimutt_dev"
          , query = "SELECT * FROM city;"
          , executions = Nel { startedAt = Time.zero, state = DataExplorerQuery.StateSuccess DataExplorerQuery.docSuccessState1 } []
          }
        , { id = 1
          , source = SourceInfo.database Time.zero SourceId.zero "azimutt_dev"
          , query = "SELECT * FROM users;"
          , executions = Nel { startedAt = Time.zero, state = DataExplorerQuery.StateSuccess DataExplorerQuery.docSuccessState2 } []
          }
        ]
    , details = []
    }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDocState = state })


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docWrap m |> Tuple.first |> set s |> docSetState


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"


docOpenDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docOpenDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }

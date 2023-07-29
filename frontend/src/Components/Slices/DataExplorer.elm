module Components.Slices.DataExplorer exposing (BasicExplorer, DataExplorerTab(..), Model, Msg(..), SavedQuery, SqlEditor, doc, init)

import Components.Slices.DataExplorerQuery as DataExplorerQuery
import Components.Slices.DataExplorerRow as DataExplorerRow
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, text)
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.Source exposing (Source)
import Models.UserId exposing (UserId)
import Services.QueryBuilder as QueryBuilder
import Time



-- TODO:
--  - Simple exploration vs SQL editor on the left
--  - List of Query Results on the right
--  - Row details in the side bar
--  - Linked rows in the side bar
--  - stackable side bars


type alias Model =
    { activeTab : DataExplorerTab
    , tabBasic : BasicExplorer
    , tabSql : SqlEditor
    , savedQueries : List SavedQuery
    , results : List DataExplorerQuery.Model
    , details : List DataExplorerRow.Model
    }


type DataExplorerTab
    = BasicTab
    | SqlTab


type alias BasicExplorer =
    { builder : QueryBuilder.TableQuery, query : String }


type alias SqlEditor =
    { content : String }


type alias SavedQuery =
    { name : String, description : String, query : String, createdAt : Time.Posix, createdBy : UserId }


type Msg
    = Noop



-- INIT


init : List SavedQuery -> Maybe String -> Model
init savedQueries query =
    { activeTab = query |> Maybe.mapOrElse (\_ -> SqlTab) BasicTab
    , tabBasic = { builder = { table = Nothing, filters = [] }, query = "" }
    , tabSql = { content = query |> Maybe.withDefault "" }
    , savedQueries = savedQueries
    , results = []
    , details = []
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        _ ->
            ( model, Noop |> wrap |> T.send )



-- VIEW


view : (Msg -> msg) -> List Source -> Model -> Html msg
view wrap sources model =
    div [] [ text "Data Explorer" ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "DataExplorer"
        |> Chapter.renderComponentList
            [ ( "empty", view (\_ -> logAction "msg") [] docModel )
            ]


docModel : Model
docModel =
    { activeTab = BasicTab
    , tabBasic = { builder = { table = Nothing, filters = [] }, query = "" }
    , tabSql = { content = "" }
    , savedQueries = []
    , results = []
    , details = []
    }

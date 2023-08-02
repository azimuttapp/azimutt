module Components.Organisms.TableRow exposing (DocState, SharedDocState, doc, docInit, view)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, text)
import Models.JsValue as JsValue
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.SourceId as SourceId
import Models.Project.TableId as TableId
import Models.Project.TableRow exposing (TableRow)


view : SchemaName -> TableRow -> Html msg
view defaultSchema model =
    div [] [ text (TableId.show defaultSchema model.table) ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableRowDocState : DocState }


type alias DocState =
    { model : TableRow }


docInit : DocState
docInit =
    { model = docModel }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "TableRow"
        |> Chapter.renderStatefulComponentList
            [ ( "table row", \{ tableRowDocState } -> view docDefaultSchema tableRowDocState.model )
            ]


docModel : TableRow
docModel =
    { source = SourceId.zero
    , table = ( "public", "users" )
    , values = [ { column = "id", value = JsValue.Int 1 }, { column = "name", value = JsValue.String "Loïc" } ]
    }


docDefaultSchema : SchemaName
docDefaultSchema =
    "public"

module PagesComponents.App.View exposing (viewApp)

import FontAwesome.Styles as Icon
import Html exposing (Html, node, text)
import Html.Attributes exposing (href, rel)
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy7)
import Libs.Maybe as M
import PagesComponents.App.Models exposing (Model, Msg(..))
import PagesComponents.App.Views.Command exposing (viewCommands)
import PagesComponents.App.Views.Erd exposing (viewErd)
import PagesComponents.App.Views.Menu exposing (viewMenu)
import PagesComponents.App.Views.Modals.Confirm exposing (viewConfirm)
import PagesComponents.App.Views.Modals.CreateLayout exposing (viewCreateLayoutModal)
import PagesComponents.App.Views.Modals.FindPath exposing (viewFindPathModal)
import PagesComponents.App.Views.Modals.HelpInstructions exposing (viewHelpModal)
import PagesComponents.App.Views.Modals.SchemaSwitch exposing (viewSchemaSwitchModal)
import PagesComponents.App.Views.Navbar exposing (viewNavbar)
import PagesComponents.App.Views.Settings exposing (viewSettings)


viewApp : Model -> List (Html Msg)
viewApp model =
    List.concatMap identity
        [ [ Icon.css
          , node "style" [] [ text "body { overflow: hidden; }" ]
          , node "link" [ rel "stylesheet", href "/assets/bootstrap.min.css" ] []
          ]
        , [ lazy4 viewNavbar model.search model.storedProjects model.project model.virtualRelation ]
        , [ lazy viewMenu (model.project |> Maybe.map .schema) ]
        , [ lazy2 viewSettings model.time model.project ]
        , [ lazy7 viewErd model.hover model.cursorMode model.dragState model.virtualRelation model.selection model.domInfos (model.project |> Maybe.map .schema) ]
        , [ lazy2 viewCommands model.cursorMode (model.project |> Maybe.map (\p -> p.schema.layout.canvas)) ]
        , [ lazy4 viewSchemaSwitchModal model.time model.switch (model.project |> Maybe.map (\_ -> "Azimutt, easily explore your SQL schema!") |> Maybe.withDefault "Choose your project:") model.storedProjects ]
        , [ lazy viewCreateLayoutModal model.newLayout ]
        , Maybe.map2 (\p fp -> lazy3 viewFindPathModal p.schema.tables p.settings.findPath fp) model.project model.findPath |> M.toList
        , [ viewHelpModal ]
        , [ lazy viewConfirm model.confirm ]
        ]

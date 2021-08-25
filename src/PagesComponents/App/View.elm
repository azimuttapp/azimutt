module PagesComponents.App.View exposing (viewApp)

import FontAwesome.Styles as Icon
import Html exposing (Html, node, text)
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4)
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


viewApp : Model -> List (Html Msg)
viewApp model =
    List.concatMap identity
        [ [ Icon.css, node "style" [] [ text "body { overflow: hidden; }" ] ]
        , [ lazy2 viewNavbar model.search model.project ]
        , [ lazy viewMenu (model.project |> Maybe.map .schema) ]
        , [ lazy3 viewErd model.hover model.sizes (model.project |> Maybe.map .schema) ]
        , [ lazy viewCommands (model.project |> Maybe.map (\p -> p.schema.layout.canvas)) ]
        , [ lazy4 viewSchemaSwitchModal model.time model.switch (model.project |> Maybe.map (\_ -> "Azimutt, easily explore your SQL schema!") |> Maybe.withDefault "Load a new schema") model.storedProjects ]
        , [ lazy viewCreateLayoutModal model.newLayout ]
        , Maybe.map2 (\p fp -> lazy3 viewFindPathModal p.schema.tables p.settings.findPath fp) model.project model.findPath |> M.toList
        , [ viewHelpModal ]
        , [ lazy viewConfirm model.confirm ]
        ]

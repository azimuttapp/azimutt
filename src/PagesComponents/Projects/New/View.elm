module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Gen.Route as Route
import Html.Styled exposing (Html, a, h1, text)
import Html.Styled.Attributes exposing (href)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..))
import Shared
import Tailwind.Utilities as Tw


viewNewProject : Shared.Model -> Model -> List (Html Msg)
viewNewProject shared model =
    appShell shared.theme
        (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft [ Tw.inline_block ], text " ", text model.navigationActive ] ]
        [ h1 [] [ text "Content" ] ]
        []

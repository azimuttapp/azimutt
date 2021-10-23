module PagesComponents.App.View exposing (viewApp)

import Dict exposing (Dict)
import FontAwesome.Styles as Icon
import Html exposing (Html, node, text)
import Html.Attributes exposing (href, rel)
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy7)
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Nel as Nel
import Models.Project exposing (Project, ProjectSourceId, Source)
import PagesComponents.App.Models exposing (Model, Msg(..))
import PagesComponents.App.Updates.Helpers exposing (setSchema)
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
    let
        project : Maybe Project
        project =
            model.project |> Maybe.map filterSources
    in
    List.concatMap identity
        [ [ Icon.css
          , node "style" [] [ text "body { overflow: hidden; }" ]
          , node "link" [ rel "stylesheet", href "/assets/bootstrap.min.css" ] []
          ]
        , [ lazy4 viewNavbar model.search model.storedProjects project model.virtualRelation ]
        , [ lazy viewMenu (project |> Maybe.map .schema) ]
        , [ lazy2 viewSettings model.time project ]
        , [ lazy7 viewErd model.hover model.cursorMode model.dragState model.virtualRelation model.selection model.domInfos (project |> Maybe.map .schema) ]
        , [ lazy2 viewCommands model.cursorMode (project |> Maybe.map (\p -> p.schema.layout.canvas)) ]
        , [ lazy4 viewSchemaSwitchModal model.time model.switch (project |> Maybe.map (\_ -> "Azimutt, easily explore your SQL schema!") |> Maybe.withDefault "Choose your project:") model.storedProjects ]
        , [ lazy viewCreateLayoutModal model.newLayout ]
        , Maybe.map2 (\p fp -> lazy3 viewFindPathModal p.schema.tables p.settings.findPath fp) project model.findPath |> M.toList
        , [ viewHelpModal ]
        , [ lazy viewConfirm model.confirm ]
        ]


filterSources : Project -> Project
filterSources project =
    let
        sources : Dict ProjectSourceId Bool
        sources =
            project.sources |> Nel.toList |> List.map (\s -> ( s.id, s.enabled )) |> Dict.fromList
    in
    project
        |> setSchema
            (\schema ->
                { schema
                    | tables = schema.tables |> Dict.filter (\_ -> hasEnabledSource sources)
                    , relations = schema.relations |> List.filter (hasEnabledSource sources)
                }
            )


hasEnabledSource : Dict ProjectSourceId Bool -> { item | sources : List Source } -> Bool
hasEnabledSource sources i =
    i.sources == [] || (i.sources |> List.any (\s -> sources |> D.getOrElse s.id False))

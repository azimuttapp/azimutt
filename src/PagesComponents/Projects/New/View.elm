module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Kbd as Kbd
import Components.Molecules.FileInput as FileInput
import Components.Molecules.ItemList as ItemList
import Conf
import Dict
import Gen.Route as Route
import Html exposing (Html, a, aside, div, form, h2, li, nav, p, span, text, ul)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (ariaCurrent, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (hover, lg, sm)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.New.Models exposing (Model, Msg(..), Tab(..))
import Services.SQLSource as SQLSource exposing (SQLSourceMsg(..))


viewNewProject : Model -> List (Html Msg)
viewNewProject model =
    appShell (\link -> SelectMenu link.text)
        ToggleMobileMenu
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline ArrowLeft "inline-block", text " ", text model.selectedMenu ] ]
        [ viewContent model
            { tabs =
                [ { tab = Schema, icon = DocumentText, text = "From SQL schema" }
                , { tab = Sample, icon = Collection, text = "From sample" }
                ]
            }
        ]
        []


type alias PageModel =
    { tabs : List (TabModel Tab)
    }


type alias TabModel tab =
    { tab : tab, icon : Icon, text : String }


viewContent : Model -> PageModel -> Html Msg
viewContent model page =
    div [ css [ "divide-y", lg [ "grid grid-cols-12 divide-x" ] ] ]
        [ aside [ css [ "py-6", lg [ "col-span-3" ] ] ]
            [ nav [ css [ "space-y-1" ] ] (page.tabs |> List.map (viewTab model.selectedTab)) ]
        , div [ css [ "px-4 py-6", sm [ "p-6" ], lg [ "pb-8 col-span-9 rounded-r-lg" ] ] ]
            [ viewTabContent model ]
        ]


viewTab : Tab -> TabModel Tab -> Html Msg
viewTab selected tab =
    if tab.tab == selected then
        a [ href "", css [ "bg-primary-50 border-primary-500 text-primary-700 border-l-4 px-3 py-2 flex items-center text-sm font-medium", hover [ "bg-primary-50 text-primary-700" ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon "-ml-1 mr-3 text-primary-500"
            , span [ css [ "truncate" ] ] [ text tab.text ]
            ]

    else
        a [ href "", onClick (SelectTab tab.tab), css [ "border-transparent text-gray-900 border-l-4 px-3 py-2 flex items-center text-sm font-medium", hover [ "bg-gray-50 text-gray-900" ] ] ]
            [ Icon.outline tab.icon "-ml-1 mr-3 text-gray-400"
            , span [ css [ "truncate" ] ] [ text tab.text ]
            ]


viewTabContent : Model -> Html Msg
viewTabContent model =
    div []
        ([ case model.selectedTab of
            Schema ->
                viewSchemaUpload model.openedCollapse

            Sample ->
                viewSampleSelection model.parsing.selectedSample
         , SQLSource.viewParsing model.parsing
         ]
            ++ (model.parsing.parsedSource |> Maybe.map2 (\( projectId, _, _ ) source -> [ viewActions projectId source ]) model.parsing.loadedFile |> Maybe.withDefault [])
        )


viewSchemaUpload : HtmlId -> Html Msg
viewSchemaUpload openedCollapse =
    div []
        [ viewHeading "Import your SQL schema" "Everything stay on your machine, don't worry about your schema privacy."
        , form []
            [ div [ css [ "mt-6 grid grid-cols-1 gap-y-6 gap-x-4", sm [ "grid-cols-6" ] ] ]
                [ div [ css [ sm [ "col-span-6" ] ] ]
                    [ FileInput.basic "file-upload" (SelectLocalFile >> SQLSourceMsg) Noop
                    ]
                ]
            ]
        , div [ css [ "mt-3" ] ]
            [ div [ onClick (ToggleCollapse "get-schema"), css [ "tw-link text-sm text-gray-500" ] ] [ text "How to get my database schema?" ]
            , div [ css [ "mt-1 mb-3 p-3 border rounded border-gray-300", B.cond (openedCollapse == "get-schema") "" "hidden" ] ]
                [ p []
                    [ text "An "
                    , bText "SQL schema"
                    , text " is a SQL file with all the needed instructions to create your database, so it contains your database structure. Here are some ways to get it:"
                    , ul [ css [ "list-disc list-inside pl-3" ] ]
                        [ li [] [ bText "Export it", text " from your database: connect to your database using your favorite client and follow the instructions to extract the schema (ex: ", extLink "https://stackoverflow.com/a/54504510/15051232" [ css [ "tw-link" ] ] [ text "DBeaver" ], text ")" ]
                        , li [] [ bText "Find it", text " in your project: some frameworks like Rails store the schema in your project, so you may have it (ex: with Rails it's ", Kbd.badge [] [ "db/structure.sql" ], text " if you use the SQL version)" ]
                        ]
                    ]
                , p [ css [ "mt-3" ] ] [ text "If you have no idea on what I'm talking about just before, ask to the developers working on the project or your database administrator 😇" ]
                ]
            ]
        , div []
            [ div [ onClick (ToggleCollapse "data-privacy"), css [ "tw-link text-sm text-gray-500" ] ] [ text "What about data privacy?" ]
            , div [ css [ "mt-1 p-3 border rounded border-gray-300", B.cond (openedCollapse == "data-privacy") "" "hidden" ] ]
                [ p [] [ text "Your application schema may be a sensitive information, but no worries with Azimutt, everything stay on your machine. In fact, there is even no server at all!" ]
                , p [ css [ "mt-3" ] ] [ text "Your schema is read and ", bText "parsed in your browser", text ", and then saved with the layouts in your browser ", bText "local storage", text ". Nothing fancy ^^" ]
                ]
            ]
        ]


viewSampleSelection : Maybe String -> Html Msg
viewSampleSelection selectedSample =
    div []
        [ viewHeading "Explore a sample schema" "If you want to see what Azimutt is capable of, you can pick a schema a play with it."
        , ItemList.withIcons
            (Conf.schemaSamples
                |> Dict.values
                |> List.sortBy .tables
                |> List.map
                    (\s ->
                        { color = s.color
                        , icon = s.icon
                        , title = s.name ++ " (" ++ (s.tables |> String.fromInt) ++ " tables)"
                        , description = s.description
                        , active = selectedSample == Nothing || selectedSample == Just s.key
                        , onClick = SQLSourceMsg (SelectSample s.key)
                        }
                    )
            )
        ]


viewHeading : String -> String -> Html msg
viewHeading title description =
    div []
        [ h2 [ css [ "text-lg leading-6 font-medium text-gray-900" ] ] [ text title ]
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text description ]
        ]


viewActions : ProjectId -> Source -> Html Msg
viewActions projectId source =
    div [ css [ "mt-6" ] ]
        [ div [ css [ "flex justify-end" ] ]
            [ Button.white3 Tw.primary [ onClick DropSchema ] [ text "Trash this" ]
            , Button.primary3 Tw.primary [ onClick (CreateProject projectId source), css [ "ml-3" ] ] [ text "Create project!" ]
            ]
        ]

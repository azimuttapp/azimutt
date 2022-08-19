module PagesComponents.Projects.New.View exposing (viewNewProject)

import Components.Atoms.Badge as Badge
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Link as Link
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Conf
import DataSources.JsonMiner.JsonSchema as JsonSchema
import Dict
import Gen.Route as Route
import Html exposing (Html, a, aside, div, h2, li, nav, p, pre, span, text, ul)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (ariaCurrent, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw exposing (hover, lg, sm)
import Models.Project.Source exposing (Source)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Projects.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)
import Services.DatabaseSource as DatabaseSource
import Services.ImportProject as ImportProject
import Services.JsonSource as JsonSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared
import Time
import Url exposing (Url)


viewNewProject : Url -> Shared.Model -> Model -> List (Html Msg)
viewNewProject currentUrl shared model =
    appShell shared.conf
        currentUrl
        shared.user
        (\link -> SelectMenu link.text)
        DropdownToggle
        Logout
        model
        [ a [ href (Route.toHref Route.Projects) ] [ Icon.outline Icon.ArrowLeft "inline-block", text " ", text model.selectedMenu ] ]
        [ viewContent "new-project"
            shared.zone
            model
            { tabs =
                [ { tab = TabDatabase, icon = Icon.Database, content = [ text "From database connection", Badge.rounded Tw.green [ class "ml-3" ] [ text "New" ] ] }
                , { tab = TabSql, icon = Icon.DocumentText, content = [ text "From SQL structure" ] }
                , { tab = TabJson, icon = Icon.Code, content = [ text "From JSON" ] }
                , { tab = TabEmptyProject, icon = Icon.Document, content = [ text "Empty project" ] }
                , { tab = TabProject, icon = Icon.FolderDownload, content = [ text "Import project" ] }
                , { tab = TabSamples, icon = Icon.Gift, content = [ text "Explore sample" ] }
                ]
            }
        ]
        [ viewModal model
        , Lazy.lazy2 Toasts.view Toast model.toasts
        ]


type alias PageModel msg =
    { tabs : List (TabModel Tab msg)
    }


type alias TabModel tab msg =
    { tab : tab, icon : Icon, content : List (Html msg) }


viewContent : HtmlId -> Time.Zone -> Model -> PageModel Msg -> Html Msg
viewContent htmlId zone model page =
    div [ css [ "divide-y", lg [ "grid grid-cols-12 divide-x" ] ] ]
        [ aside [ css [ "py-6", lg [ "col-span-3" ] ] ]
            [ nav [ css [ "space-y-1" ] ] (page.tabs |> List.map (viewTab model.selectedTab)) ]
        , div [ css [ "px-4 py-6", sm [ "p-6" ], lg [ "pb-8 col-span-9 rounded-r-lg" ] ] ]
            [ viewTabContent (htmlId ++ "-tab") zone model ]
        ]


viewTab : Tab -> TabModel Tab Msg -> Html Msg
viewTab selected tab =
    if tab.tab == selected then
        a [ href "", css [ "bg-primary-50 border-primary-500 text-primary-700 border-l-4 px-3 py-2 flex items-center text-sm font-medium", hover [ "bg-primary-50 text-primary-700" ] ], ariaCurrent "page" ]
            [ Icon.outline tab.icon "-ml-1 mr-3 text-primary-500"
            , span [ css [ "truncate" ] ] tab.content
            ]

    else
        a [ href "", onClick (InitTab tab.tab), css [ "border-transparent text-gray-900 border-l-4 px-3 py-2 flex items-center text-sm font-medium", hover [ "bg-gray-50 text-gray-900" ] ] ]
            [ Icon.outline tab.icon "-ml-1 mr-3 text-gray-400"
            , span [ css [ "truncate" ] ] tab.content
            ]


viewTabContent : HtmlId -> Time.Zone -> Model -> Html Msg
viewTabContent htmlId zone model =
    case model.selectedTab of
        TabDatabase ->
            model.databaseSource |> Maybe.mapOrElse (viewDatabaseSourceTab (htmlId ++ "-database")) (div [] [])

        TabSql ->
            model.sqlSource |> Maybe.mapOrElse (viewSqlSourceTab (htmlId ++ "-sql") model.openedCollapse) (div [] [])

        TabJson ->
            model.jsonSource |> Maybe.mapOrElse (viewJsonSourceTab (htmlId ++ "-json") model.openedCollapse) (div [] [])

        TabEmptyProject ->
            viewEmptyProjectTab

        TabProject ->
            model.importProject |> Maybe.mapOrElse (viewImportProjectTab (htmlId ++ "-project") zone model.projects) (div [] [])

        TabSamples ->
            model.sampleProject |> Maybe.mapOrElse (viewSampleProjectTab zone model.projects) (div [] [])


viewDatabaseSourceTab : HtmlId -> DatabaseSource.Model Msg -> Html Msg
viewDatabaseSourceTab htmlId model =
    div []
        [ viewHeading "Extract your database schema" [ text "Sadly browsers can't directly connect to a database so this extraction will be made through Azimutt servers but nothing is stored." ]
        , div [ class "mt-6" ] [ DatabaseSource.viewInput DatabaseSourceMsg htmlId model ]
        , DatabaseSource.viewParsing DatabaseSourceMsg model
        , viewSourceActionButtons (InitTab TabDatabase) model.parsedSource
        ]


viewSqlSourceTab : HtmlId -> HtmlId -> SqlSource.Model Msg -> Html Msg
viewSqlSourceTab htmlId openedCollapse model =
    div []
        [ viewHeading "Import your SQL schema" [ text "Everything stay on your machine, don't worry about your schema privacy." ]
        , div [ class "mt-6" ] [ SqlSource.viewInput SqlSourceMsg Noop htmlId model ]
        , div [ class "mt-3" ] [ viewHowToGetSchemaCollapse htmlId openedCollapse ]
        , viewDataPrivacyCollapse htmlId openedCollapse
        , SqlSource.viewParsing SqlSourceMsg model
        , viewSourceActionButtons (InitTab TabSql) model.parsedSource
        ]


viewJsonSourceTab : HtmlId -> HtmlId -> JsonSource.Model Msg -> Html Msg
viewJsonSourceTab htmlId openedCollapse model =
    div []
        [ viewHeading "Import your custom source in JSON" [ text "If you have a data source not (yet) supported by Azimutt, you can extract and format its schema into JSON to import it here." ]
        , div [ class "mt-6" ] [ JsonSource.viewInput JsonSourceMsg Noop htmlId model ]
        , div [ class "mt-3" ] [ viewJsonSourceSchemaCollapse htmlId openedCollapse ]
        , JsonSource.viewParsing JsonSourceMsg model
        , viewSourceActionButtons (InitTab TabJson) model.parsedSource
        ]


viewEmptyProjectTab : Html Msg
viewEmptyProjectTab =
    div []
        [ viewHeading "Create a new project" [ text "When you don't want to import a schema, just create it in Azimutt using ", extLink "https://azimutt.app/blog/aml-a-language-to-define-your-database-schema" [ class "link" ] [ text "AML" ], text "." ]
        , div [ css [ "mt-20" ] ]
            [ div [ css [ "flex justify-center" ] ]
                [ Button.primary5 Tw.primary [ onClick (CreateEmptyProject Conf.constants.newProjectName), id "create-project-btn", css [ "ml-3" ] ] [ text "Create new project!" ]
                ]
            ]
        ]


viewImportProjectTab : HtmlId -> Time.Zone -> List ProjectInfo -> ImportProject.Model -> Html Msg
viewImportProjectTab htmlId zone projects model =
    div []
        [ viewHeading "Import an existing project" [ text "If you have an Azimutt project, you can load it here." ]
        , div [ class "mt-6" ] [ ImportProject.viewLocalInput ImportProjectMsg Noop (htmlId ++ "-remote-file") ]
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text "Download your project with the button on the bottom of the settings (top right cog)." ]
        , ImportProject.viewParsing ImportProjectMsg zone Nothing model
        , model.parsedProject
            |> Maybe.andThen Result.toMaybe
            |> Maybe.map
                (\project ->
                    div [ css [ "mt-6" ] ]
                        [ div [ css [ "flex justify-end" ] ]
                            (Button.white3 Tw.primary [ onClick (InitTab TabProject) ] [ text "Don't import" ]
                                :: (projects
                                        |> List.find (\p -> p.id == project.id)
                                        |> Maybe.map
                                            (\p ->
                                                [ Button.secondary3 Tw.red [ onClick (CreateProject project |> confirm ("Replace " ++ p.name ++ " project?") (text "This operation can't be undone")), css [ "ml-3" ] ] [ text "Replace existing project" ]
                                                , Button.primary3 Tw.primary [ onClick (CreateProjectNew project), id "create-project-btn", css [ "ml-3" ] ] [ text "Import in new project!" ]
                                                ]
                                            )
                                        |> Maybe.withDefault [ Button.primary3 Tw.primary [ onClick (CreateProject project), id "create-project-btn", css [ "ml-3" ] ] [ text "Import project!" ] ]
                                   )
                            )
                        ]
                )
            |> Maybe.withDefault (div [] [])
        ]


viewSampleProjectTab : Time.Zone -> List ProjectInfo -> ImportProject.Model -> Html Msg
viewSampleProjectTab zone projects model =
    div []
        [ viewHeading "Explore a sample schema" [ text "If you want to see what Azimutt is capable of, you can pick a schema a play with it." ]
        , ItemList.withIcons
            (Conf.schemaSamples
                |> Dict.values
                |> List.sortBy .tables
                |> List.map
                    (\sample ->
                        { color = sample.color
                        , icon = sample.icon
                        , title = sample.name ++ " (" ++ (sample.tables |> String.fromInt) ++ " tables)"
                        , description = sample.description
                        , active = model.selectedSample |> Maybe.all (\s -> s == sample.key)
                        , onClick = ImportProject.GetRemoteFile sample.url (Just sample.key) |> SampleProjectMsg
                        }
                    )
            )
        , ImportProject.viewParsing SampleProjectMsg zone Nothing model
        , model.parsedProject
            |> Maybe.andThen Result.toMaybe
            |> Maybe.map
                (\project ->
                    div [ css [ "mt-6" ] ]
                        [ div [ css [ "flex justify-end" ] ]
                            (Button.white3 Tw.primary [ onClick (InitTab TabSamples) ] [ text "Cancel" ]
                                :: (projects
                                        |> List.find (\p -> p.id == project.id)
                                        |> Maybe.map (\p -> [ Link.primary3 Tw.primary [ href (Route.toHref (Route.Projects__Id_ { id = p.id })), id "create-project-btn", css [ "ml-3" ] ] [ text "View this project" ] ])
                                        |> Maybe.withDefault [ Button.primary3 Tw.primary [ onClick (CreateProject project), id "create-project-btn", css [ "ml-3" ] ] [ text "Load sample" ] ]
                                   )
                            )
                        ]
                )
            |> Maybe.withDefault (div [] [])
        ]



-- HELPERS


viewHeading : String -> List (Html msg) -> Html msg
viewHeading title description =
    div []
        [ h2 [ css [ "text-lg leading-6 font-medium text-gray-900" ] ] [ text title ]
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] description
        ]


viewHowToGetSchemaCollapse : HtmlId -> HtmlId -> Html Msg
viewHowToGetSchemaCollapse htmlId openedCollapse =
    div []
        [ div [ onClick (ToggleCollapse (htmlId ++ "-get-schema")), css [ "link text-sm text-gray-500" ] ] [ text "How to get my database schema?" ]
        , div [ css [ "mt-1 mb-3 p-3 border rounded border-gray-300", B.cond (openedCollapse == (htmlId ++ "-get-schema")) "" "hidden" ] ]
            [ p []
                [ text "An "
                , bText "SQL schema"
                , text " is a SQL file with all the needed instructions to create your database, so it contains your database structure. Here are some ways to get it:"
                , ul [ css [ "list-disc list-inside pl-3" ] ]
                    [ li [] [ bText "Export it", text " from your database: connect to your database using your favorite client and follow the instructions to extract the schema (ex: ", extLink "https://stackoverflow.com/a/54504510/15051232" [ css [ "link" ] ] [ text "DBeaver" ], text ")" ]
                    , li [] [ bText "Find it", text " in your project: some frameworks like Rails store the schema in your project, so you may have it (ex: with Rails it's ", Kbd.badge [] [ "db/structure.sql" ], text " if you use the SQL version)" ]
                    ]
                ]
            , p [ css [ "mt-3" ] ] [ text "If you have no idea on what I'm talking about just before, ask to the developers working on the project or your database administrator 😇" ]
            ]
        ]


viewDataPrivacyCollapse : HtmlId -> HtmlId -> Html Msg
viewDataPrivacyCollapse htmlId openedCollapse =
    div []
        [ div [ onClick (ToggleCollapse (htmlId ++ "-data-privacy")), css [ "link text-sm text-gray-500" ] ] [ text "What about data privacy?" ]
        , div [ css [ "mt-1 p-3 border rounded border-gray-300", B.cond (openedCollapse == (htmlId ++ "-data-privacy")) "" "hidden" ] ]
            [ p [] [ text "Your application schema may be a sensitive information, but no worries with Azimutt, everything stay on your machine. In fact, there is even no server at all!" ]
            , p [ css [ "mt-3" ] ] [ text "Your schema is read and ", bText "parsed in your browser", text ", and then saved with the layouts in your browser ", bText "local storage", text ". Nothing fancy ^^" ]
            ]
        ]


viewJsonSourceSchemaCollapse : HtmlId -> HtmlId -> Html Msg
viewJsonSourceSchemaCollapse htmlId openedCollapse =
    div []
        [ div [ onClick (ToggleCollapse (htmlId ++ "-json-schema")), css [ "link text-sm text-gray-500" ] ] [ text "What is the schema for the JSON?" ]
        , div [ css [ "mt-1 mb-3 p-3 border rounded border-gray-300", B.cond (openedCollapse == (htmlId ++ "-json-schema")) "" "hidden" ] ]
            [ p [] [ text "Here is the JSON schema defining what is expected:" ]
            , pre [] [ text JsonSchema.jsonSchema ]
            , p []
                [ text "You can use "
                , extLink "https://www.jsonschemavalidator.net" [ class "link" ] [ text "jsonschemavalidator.net" ]
                , text " to validate your JSON against this schema."
                ]
            ]
        ]


viewSourceActionButtons : Msg -> Maybe (Result String Source) -> Html Msg
viewSourceActionButtons drop parsedSource =
    parsedSource
        |> Maybe.mapOrElse
            (\source ->
                div [ css [ "mt-6" ] ]
                    [ div [ css [ "flex justify-end" ] ]
                        (source
                            |> Result.fold (\_ -> [ Button.white3 Tw.primary [ onClick drop ] [ text "Clear" ] ])
                                (\src ->
                                    [ Button.white3 Tw.primary [ onClick drop ] [ text "Trash this" ]
                                    , Button.primary3 Tw.primary [ onClick (CreateProjectFromSource src), id "create-project-btn", css [ "ml-3" ] ] [ text "Create project!" ]
                                    ]
                                )
                        )
                    ]
            )
            (div [] [])


viewModal : Model -> Html Msg
viewModal model =
    Keyed.node "div"
        [ class "az-modals" ]
        ([ model.confirm |> Maybe.map (\m -> ( m.id, viewConfirm (model.openedDialogs |> List.member m.id) m ))
         ]
            |> List.filterMap identity
            |> List.sortBy (\( id, _ ) -> model.openedDialogs |> List.indexOf id |> Maybe.withDefault 0 |> negate)
        )


viewConfirm : Bool -> ConfirmDialog -> Html Msg
viewConfirm opened model =
    Modal.confirm
        { id = model.id
        , icon = model.content.icon
        , color = model.content.color
        , title = model.content.title
        , message = model.content.message
        , confirm = model.content.confirm
        , cancel = model.content.cancel
        , onConfirm = ModalClose (ConfirmAnswer True model.content.onConfirm)
        , onCancel = ModalClose (ConfirmAnswer False Cmd.none)
        }
        opened

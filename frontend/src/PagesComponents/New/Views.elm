module PagesComponents.New.Views exposing (title, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Icons as Icons
import Components.Atoms.Kbd as Kbd
import Components.Atoms.Link as Link
import Components.Molecules.ItemList as ItemList
import Components.Molecules.Modal as Modal
import Conf
import DataSources.JsonMiner.JsonSchema as JsonSchema
import Gen.Route as Route
import Html exposing (Html, a, aside, div, h2, h3, li, nav, p, pre, span, text, ul)
import Html.Attributes exposing (class, href, id, rel, target)
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
import Models.OrganizationId exposing (OrganizationId)
import Models.Project as Project
import Models.Project.Source exposing (Source)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import PagesComponents.Helpers exposing (appShell)
import PagesComponents.New.Models exposing (ConfirmDialog, Model, Msg(..), Tab(..), confirm)
import Services.Backend as Backend exposing (Sample)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.PrismaSource as PrismaSource
import Services.ProjectSource as ProjectSource
import Services.SampleSource as SampleSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared
import Time
import Url exposing (Url)
import View exposing (View)


title : String
title =
    Conf.constants.defaultTitle


view : Shared.Model -> Url -> Maybe OrganizationId -> Model -> View Msg
view shared currentUrl urlOrganization model =
    { title = title, body = model |> viewNewProject shared currentUrl urlOrganization }


viewNewProject : Shared.Model -> Url -> Maybe OrganizationId -> Model -> List (Html Msg)
viewNewProject shared currentUrl urlOrganization model =
    let
        backUrl : String
        backUrl =
            shared.user |> Maybe.mapOrElse (\_ -> urlOrganization |> Backend.organizationUrl) Backend.homeUrl
    in
    appShell currentUrl
        urlOrganization
        shared.user
        (\link -> SelectMenu link.text)
        DropdownToggle
        model
        [ a [ href backUrl ] [ Icon.outline Icon.ArrowLeft "inline-block", text " ", text model.selectedMenu ] ]
        [ viewContent "new-project"
            shared.zone
            shared.projects
            urlOrganization
            model
            { tabs =
                [ { tab = TabDatabase, icon = Icons.sources.database, content = [ text "From database connection" ] }
                , { tab = TabSql, icon = Icons.sources.sql, content = [ text "From SQL structure" ] }
                , { tab = TabPrisma, icon = Icons.sources.prisma, content = [ text "From Prisma Schema" ] }
                , { tab = TabJson, icon = Icons.sources.json, content = [ text "From JSON" ] }
                , { tab = TabEmptyProject, icon = Icons.sources.empty, content = [ text "From scratch (db design)" ] }
                , { tab = TabProject, icon = Icons.sources.project, content = [ text "Import project" ] }
                , { tab = TabSamples, icon = Icons.sources.sample, content = [ text "Explore sample" ] }
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


viewContent : HtmlId -> Time.Zone -> List ProjectInfo -> Maybe OrganizationId -> Model -> PageModel Msg -> Html Msg
viewContent htmlId zone projects urlOrganization model page =
    div [ css [ "divide-y", lg [ "grid grid-cols-12 divide-x" ] ] ]
        [ aside [ css [ "py-6", lg [ "col-span-3" ] ] ]
            [ nav [ css [ "space-y-1" ] ] (page.tabs |> List.map (viewTab model.selectedTab)) ]
        , div [ css [ "px-4 py-6", sm [ "p-6" ], lg [ "pb-8 col-span-9 rounded-r-lg" ] ] ]
            [ viewTabContent (htmlId ++ "-tab") zone projects urlOrganization model ]
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


viewTabContent : HtmlId -> Time.Zone -> List ProjectInfo -> Maybe OrganizationId -> Model -> Html Msg
viewTabContent htmlId zone projects urlOrganization model =
    case model.selectedTab of
        TabDatabase ->
            model.databaseSource |> Maybe.mapOrElse (viewDatabaseSourceTab (htmlId ++ "-database") model.openedCollapse projects) (div [] [])

        TabSql ->
            model.sqlSource |> Maybe.mapOrElse (viewSqlSourceTab (htmlId ++ "-sql") model.openedCollapse projects) (div [] [])

        TabPrisma ->
            model.prismaSource |> Maybe.mapOrElse (viewPrismaSourceTab (htmlId ++ "-prisma") model.openedCollapse projects) (div [] [])

        TabJson ->
            model.jsonSource |> Maybe.mapOrElse (viewJsonSourceTab (htmlId ++ "-json") model.openedCollapse projects) (div [] [])

        TabEmptyProject ->
            viewEmptyProjectTab

        TabProject ->
            model.projectSource |> Maybe.mapOrElse (viewProjectSourceTab (htmlId ++ "-project") zone projects) (div [] [])

        TabSamples ->
            model.sampleSource |> Maybe.mapOrElse (viewSampleSourceTab urlOrganization projects model.samples) (div [] [])


viewDatabaseSourceTab : HtmlId -> HtmlId -> List ProjectInfo -> DatabaseSource.Model Msg -> Html Msg
viewDatabaseSourceTab htmlId openedCollapse projects model =
    div []
        [ viewHeading "Extract your database schema" [ text "Browsers can't connect to databases, schema extraction is done through a proxy, Azimutt Gateway or ", extLink "https://www.npmjs.com/package/azimutt" [ class "link" ] [ text "CLI" ], text ". Nothing is stored." ]
        , div [ class "mt-6" ] [ DatabaseSource.viewInput DatabaseSourceMsg htmlId model ]
        , div [ class "mt-3" ] [ viewDataPrivacyCollapse htmlId openedCollapse ]
        , DatabaseSource.viewParsing DatabaseSourceMsg model
        , viewSourceActionButtons (InitTab TabDatabase) (DatabaseSource.GetSchema >> DatabaseSourceMsg) projects model.url model.parsedSource
        ]


viewSqlSourceTab : HtmlId -> HtmlId -> List ProjectInfo -> SqlSource.Model Msg -> Html Msg
viewSqlSourceTab htmlId openedCollapse projects model =
    div []
        [ viewHeading "Import your SQL schema" [ text "Everything stay on your machine, don't worry about your schema privacy." ]
        , div [ class "mt-6" ] [ SqlSource.viewInput SqlSourceMsg Noop htmlId model ]
        , div [ class "mt-3" ] [ viewHowToGetSchemaCollapse htmlId openedCollapse ]
        , viewDataPrivacyCollapse htmlId openedCollapse
        , SqlSource.viewParsing SqlSourceMsg model
        , viewSourceActionButtons (InitTab TabSql) (SqlSource.GetRemoteFile >> SqlSourceMsg) projects model.url model.parsedSource
        ]


viewPrismaSourceTab : HtmlId -> HtmlId -> List ProjectInfo -> PrismaSource.Model Msg -> Html Msg
viewPrismaSourceTab htmlId openedCollapse projects model =
    div []
        [ viewHeading "Import your Prisma Schema" [ text "Everything stay on your machine, don't worry about your schema privacy." ]
        , div [ class "mt-6" ] [ PrismaSource.viewInput PrismaSourceMsg Noop htmlId model ]
        , div [ class "mt-3" ] [ viewDataPrivacyCollapse htmlId openedCollapse ]
        , PrismaSource.viewParsing PrismaSourceMsg model
        , viewSourceActionButtons (InitTab TabSql) (PrismaSource.GetRemoteFile >> PrismaSourceMsg) projects model.url model.parsedSource
        ]


viewJsonSourceTab : HtmlId -> HtmlId -> List ProjectInfo -> JsonSource.Model Msg -> Html Msg
viewJsonSourceTab htmlId openedCollapse projects model =
    div []
        [ viewHeading "Import your custom source in JSON" [ text "If you have a data source not (yet) supported by Azimutt, you can extract and format its schema into JSON to import it here." ]
        , div [ class "mt-6" ] [ JsonSource.viewInput JsonSourceMsg Noop htmlId model ]
        , div [ class "mt-3" ] [ viewJsonSourceSchemaCollapse htmlId openedCollapse ]
        , viewDataPrivacyCollapse htmlId openedCollapse
        , JsonSource.viewParsing JsonSourceMsg model
        , viewSourceActionButtons (InitTab TabJson) (JsonSource.GetRemoteFile >> JsonSourceMsg) projects model.url model.parsedSource
        ]


viewEmptyProjectTab : Html Msg
viewEmptyProjectTab =
    div []
        [ viewHeading "Create a new project" [ text "When you don't want to import a schema, just create it in Azimutt using ", extLink "https://github.com/azimuttapp/azimutt/blob/main/docs/aml/README.md" [ class "link" ] [ text "AML" ], text "." ]
        , div [ css [ "mt-20" ] ]
            [ div [ css [ "flex justify-center" ] ]
                [ Button.primary5 Tw.primary [ onClick (CreateEmptyProject Conf.constants.newProjectName), id "create-project-btn", css [ "ml-3" ] ] [ text "Create new project!" ]
                ]
            ]
        ]


viewProjectSourceTab : HtmlId -> Time.Zone -> List ProjectInfo -> ProjectSource.Model -> Html Msg
viewProjectSourceTab htmlId zone projects model =
    div []
        [ viewHeading "Import an existing project" [ text "If you have an Azimutt project, you can load it here." ]
        , div [ class "mt-6" ] [ ProjectSource.viewLocalInput ProjectSourceMsg Noop (htmlId ++ "-remote-file") ]
        , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text "Download your project with the button on the bottom of the settings (top right cog)." ]
        , ProjectSource.viewParsing ProjectSourceMsg zone Nothing model
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
                                                [ Button.secondary3 Tw.red [ onClick (project |> CreateProjectTmp |> confirm ("Replace " ++ p.name ++ " project?") (text "This operation can't be undone")), css [ "ml-3" ] ] [ text "Replace existing project" ]
                                                , Button.primary3 Tw.primary [ onClick (project |> Project.duplicate projects |> CreateProjectTmp), id "create-project-btn", css [ "ml-3" ] ] [ text "Import in new project!" ]
                                                ]
                                            )
                                        |> Maybe.withDefault [ Button.primary3 Tw.primary [ onClick (CreateProjectTmp project), id "create-project-btn", css [ "ml-3" ] ] [ text "Import project!" ] ]
                                   )
                            )
                        ]
                )
            |> Maybe.withDefault (div [] [])
        ]


viewSampleSourceTab : Maybe OrganizationId -> List ProjectInfo -> List Sample -> SampleSource.Model -> Html Msg
viewSampleSourceTab urlOrganization projects samples model =
    div []
        [ viewHeading "Explore a sample schema" [ text "If you want to see what Azimutt is capable of, you can pick a schema a play with it." ]
        , if samples == [] then
            h3 [ class "mt-2 text-sm font-medium text-gray-900" ] [ text "No sample project 😓" ]

          else
            ItemList.withIcons
                (samples
                    |> List.sortBy .nb_tables
                    |> List.map
                        (\sample ->
                            { color = sample.color
                            , icon = sample.icon
                            , title = sample.name ++ " (" ++ (sample.nb_tables |> String.fromInt) ++ " tables)"
                            , description = sample.description
                            , active = model.selectedSample |> Maybe.all (\s -> s.slug == sample.slug)
                            , onClick = SampleSource.GetSample sample |> SampleSourceMsg
                            }
                        )
                )
        , SampleSource.viewParsing model
        , model.parsedProject
            |> Maybe.andThen Result.toMaybe
            |> Maybe.map
                (\project ->
                    div [ css [ "mt-6" ] ]
                        [ div [ css [ "flex justify-end" ] ]
                            (Button.white3 Tw.primary [ onClick (InitTab TabSamples) ] [ text "Cancel" ]
                                :: (projects
                                        |> List.find (\p -> p.id == project.id)
                                        |> Maybe.map (\p -> [ Link.primary3 Tw.primary [ href (Route.toHref (Route.Organization___Project_ { organization = urlOrganization |> Maybe.withDefault (ProjectInfo.organizationId p), project = p.id })), id "create-project-btn", css [ "ml-3" ] ] [ text "View this project" ] ])
                                        |> Maybe.withDefault [ Button.primary3 Tw.primary [ onClick (CreateProjectTmp project), id "create-project-btn", css [ "ml-3" ] ] [ text "Load sample" ] ]
                                   )
                            )
                        ]
                )
            |> Maybe.withDefault (div [] [])
        ]



-- HELPERS


viewHeading : String -> List (Html msg) -> Html msg
viewHeading heading description =
    div []
        [ h2 [ css [ "text-lg leading-6 font-medium text-gray-900" ] ] [ text heading ]
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
            [ p [] [ text "Your application schema may be a sensitive information, but no worries with Azimutt, we are ", bText "privacy focused", text "." ]
            , p [ css [ "mt-1" ] ] [ text "Your schema is ", bText "read and parsed in your browser", text ". You can explore it without leaking anything to Azimutt server." ]
            , p [ css [ "mt-1" ] ] [ text "When saving your project you can choose between ", bText "local", text " or ", bText "remote", text " storage. The first one offers full privacy, your schema don't leave your computer. The second offers collaboration, sharing it with other people." ]
            , p [ css [ "mt-1" ] ] [ text "If you are worried, please ", a [ href ("mailto:" ++ Conf.constants.azimuttEmail), target "_blank", rel "noopener", class "link" ] [ text "contact us" ], text ", we take this very seriously and do whatever is possible to satisfy needs." ]
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


viewSourceActionButtons : Msg -> (String -> Msg) -> List ProjectInfo -> String -> Maybe (Result String Source) -> Html Msg
viewSourceActionButtons drop extractSchema projects url parsedSource =
    div [ css [ "mt-6" ] ]
        [ div [ css [ "flex justify-end" ] ]
            (case ( url, parsedSource ) of
                ( _, Just source ) ->
                    source
                        |> Result.fold (\_ -> [ Button.white3 Tw.primary [ onClick drop ] [ text "Clear" ] ])
                            (\src ->
                                [ Button.white3 Tw.primary [ onClick drop ] [ text "Trash this" ]
                                , Button.primary3 Tw.primary [ onClick (CreateProjectTmp (Project.create projects src.name src)), id "create-project-btn", css [ "ml-3" ] ] [ text "Create project!" ]
                                ]
                            )

                ( u, _ ) ->
                    if u /= "" then
                        [ Button.primary3 Tw.primary [ onClick (extractSchema url) ] [ text "Extract schema" ] ]

                    else
                        []
            )
        ]


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

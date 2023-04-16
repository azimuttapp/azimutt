module PagesComponents.Organization_.Project_.Views.Navbar.Title exposing (NavbarTitleArgs, argsToString, viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Avatar as Avatar
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Html exposing (Html, br, button, div, small, span, text)
import Html.Attributes exposing (class, classList, disabled, id, tabindex, type_)
import Html.Events exposing (onClick)
import Html.Lazy as Lazy
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.String as String
import Libs.Tailwind as Tw exposing (focus, focus_ring_offset_600)
import Libs.Task as T
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Models exposing (LayoutMsg(..), Msg(..), confirmDanger, prompt)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout
import Services.Backend as Backend
import Shared exposing (GlobalConf)


type alias NavbarTitleArgs =
    String


argsToString : Bool -> LayoutName -> HtmlId -> HtmlId -> NavbarTitleArgs
argsToString dirty currentLayout htmlId openedDropdown =
    [ B.cond dirty "Y" "N", currentLayout, htmlId, openedDropdown ] |> String.join "~"


stringToArgs : NavbarTitleArgs -> ( ( Bool, LayoutName ), ( HtmlId, HtmlId ) )
stringToArgs args =
    case args |> String.split "~" of
        [ dirty, currentLayout, htmlId, openedDropdown ] ->
            ( ( dirty == "Y", currentLayout ), ( htmlId, openedDropdown ) )

        _ ->
            ( ( False, "" ), ( "", "" ) )


viewNavbarTitle : GlobalConf -> ErdConf -> List ProjectInfo -> ProjectInfo -> Dict LayoutName ErdLayout -> NavbarTitleArgs -> Html Msg
viewNavbarTitle gConf eConf projects project layouts args =
    let
        ( ( dirty, currentLayout ), ( htmlId, openedDropdown ) ) =
            stringToArgs args
    in
    div [ class "flex justify-center items-center text-white" ]
        ([ if eConf.projectManagement then
            -- FIXME: propose to move project from local to remote and the reverse
            button [ onClick (MoveProjectTo (B.cond (project.storage == ProjectStorage.Local) ProjectStorage.Remote ProjectStorage.Local)), css [ "mx-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ Icon.outline (ProjectInfo.icon project) ""
                ]
                |> Tooltip.b (ProjectInfo.title project)

           else
            div [] []
         , if eConf.projectManagement then
            Lazy.lazy7 viewProjectsDropdown gConf.platform eConf projects project dirty (htmlId ++ "-projects") (openedDropdown |> String.filterStartsWith (htmlId ++ "-projects"))

           else
            div [] [ text project.name ]
         ]
            ++ viewLayoutsMaybe gConf.platform eConf currentLayout layouts (htmlId ++ "-layouts") (openedDropdown |> String.filterStartsWith (htmlId ++ "-layouts"))
        )


viewProjectsDropdown : Platform -> ErdConf -> List ProjectInfo -> ProjectInfo -> Bool -> HtmlId -> HtmlId -> Html Msg
viewProjectsDropdown platform eConf projects project dirty htmlId openedDropdown =
    let
        projectsPerOrganization : Dict OrganizationId (List ProjectInfo)
        projectsPerOrganization =
            projects |> List.groupBy (.organization >> Maybe.mapOrElse .id OrganizationId.zero)

        currentOrganization : OrganizationId
        currentOrganization =
            project.organization |> Maybe.mapOrElse .id OrganizationId.zero

        currentOrganizationProjects : List ProjectInfo
        currentOrganizationProjects =
            projectsPerOrganization |> Dict.getOrElse currentOrganization []

        organizationProjects : List ( Organization, List ProjectInfo )
        organizationProjects =
            projectsPerOrganization
                |> Dict.remove currentOrganization
                |> Dict.toList
                |> List.map (\( _, p ) -> ( p |> List.head |> Maybe.andThen .organization |> Maybe.withDefault (Organization.zero |> (\z -> { z | name = "Draft" })), p ))
    in
    Dropdown.dropdown { id = htmlId, direction = BottomRight, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "flex justify-center items-center p-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ span [ css [ "mr-1", B.cond dirty "opacity-1" "opacity-0" ] ] [ text "*" ]
                , span [] [ text project.name ]
                , Icon.solid ChevronDown ("transform transition " ++ B.cond m.isOpen "-rotate-180" "")
                ]
        )
        (\_ ->
            div [ class "divide-y divide-gray-100" ]
                ([ if eConf.save then
                    [ ContextMenu.btnHotkey "" TriggerSaveProject [ text "Save project" ] platform (Conf.hotkeys |> Dict.getOrElse "save" [])
                    , ContextMenu.btn "" (RenameProject |> prompt "Rename project" (text "") project.name) [ text "Rename project" ]
                    , ContextMenu.btn "" (DeleteProject project |> confirmDanger "Delete project?" (text "This action is definitive!")) [ text "Delete project" ]
                    ]

                   else
                    [ ContextMenu.btnDisabled "" [ text "Save project" |> Tooltip.r "You are in read-one mode" ]
                    , ContextMenu.btnDisabled "" [ text "Rename project" |> Tooltip.r "You are in read-one mode" ]
                    , ContextMenu.btnDisabled "" [ text "Delete project" |> Tooltip.r "You are in read-one mode" ]
                    ]
                 , currentOrganizationProjects |> List.map (viewProjectsDropdownItem project.id)
                 , organizationProjects
                    |> List.map
                        (\( org, orgProjects ) ->
                            ContextMenu.submenuHtml [ Avatar.xs org.logo org.name "mr-2", span [] [ text (org.name ++ " »") ] ]
                                (orgProjects |> List.map (viewProjectsDropdownItem project.id))
                        )
                 , [ ContextMenu.link { url = currentOrganization |> Just |> Maybe.filter (\id -> projectsPerOrganization |> Dict.member id) |> Backend.organizationUrl, text = "Back to dashboard" } ]
                 ]
                    |> List.filterNot List.isEmpty
                    |> List.map (\section -> div [ role "none", class "py-1" ] section)
                )
        )


viewProjectsDropdownItem : ProjectId -> ProjectInfo -> Html msg
viewProjectsDropdownItem current p =
    ContextMenu.linkHtml (Route.toHref (Route.Organization___Project_ { organization = p |> ProjectInfo.organizationId, project = p.id }))
        [ class "flex", classList [ ( "text-gray-400 bg-gray-100", p.id == current ) ], disabled (p.id == current) ]
        [ p.organization
            |> Maybe.map (\o -> Avatar.xsWithIcon o.logo o.name (ProjectInfo.icon p) "mr-2")
            |> Maybe.withDefault (Icon.outline (ProjectInfo.icon p) "mr-2")
        , text p.name
        ]


viewLayoutsMaybe : Platform -> ErdConf -> LayoutName -> Dict LayoutName ErdLayout -> HtmlId -> HtmlId -> List (Html Msg)
viewLayoutsMaybe platform conf currentLayout layouts htmlId openedDropdown =
    if conf.layoutManagement then
        [ Icon.slash "text-primary-300"
        , Lazy.lazy5 viewLayouts platform currentLayout layouts htmlId openedDropdown
        ]

    else
        [ Icon.slash "text-primary-300", text currentLayout ]


viewLayouts : Platform -> LayoutName -> Dict LayoutName ErdLayout -> HtmlId -> HtmlId -> Html Msg
viewLayouts platform currentLayout layouts htmlId openedDropdown =
    Dropdown.dropdown { id = htmlId, direction = BottomLeft, isOpen = openedDropdown == htmlId }
        (\m ->
            button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "flex justify-center items-center p-1 rounded-full", focus_ring_offset_600 Tw.primary ] ]
                [ span [] [ text currentLayout ]
                , Icon.solid ChevronDown ("transform transition " ++ B.cond m.isOpen "-rotate-180" "")
                ]
        )
        (\_ ->
            div [ class "min-w-max divide-y divide-gray-100" ]
                [ div [ role "none", class "py-1" ]
                    [ ContextMenu.btnHotkey "" (NewLayout.Open Nothing |> NewLayoutMsg) [ text "Create new layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" []) ]
                , div [ role "none", class "py-1" ]
                    (layouts
                        |> Dict.toList
                        |> List.sortBy (\( name, _ ) -> name)
                        |> List.map (\( name, layout ) -> viewLayoutItem (currentLayout == name) name layout)
                    )
                ]
        )


viewLayoutItem : Bool -> LayoutName -> ErdLayout -> Html Msg
viewLayoutItem isCurrent name layout =
    span [ role "menuitem", tabindex -1, css [ "flex", B.cond isCurrent ContextMenu.itemCurrentStyles ContextMenu.itemStyles ] ]
        [ button [ type_ "button", onClick (name |> confirmDeleteLayout layout), disabled isCurrent, css [ focus [ "outline-none" ], Tw.disabled [ "text-gray-400" ] ] ] [ Icon.solid Trash "inline-block" ] |> Tooltip.t (B.cond isCurrent "" "Delete this layout")
        , button [ type_ "button", onClick (name |> Just |> NewLayout.Open |> NewLayoutMsg), css [ "ml-1", focus [ "outline-none" ] ] ] [ Icon.solid DocumentDuplicate "inline-block" ] |> Tooltip.t "Duplicate this layout"
        , button [ type_ "button", onClick (name |> LLoad |> LayoutMsg), css [ "flex-grow text-left ml-3", focus [ "outline-none" ] ] ]
            [ text name
            , text " "
            , small [] [ text ("(" ++ (layout.tables |> String.pluralizeL "table") ++ ")") ]
            ]
        ]


confirmDeleteLayout : ErdLayout -> LayoutName -> Msg
confirmDeleteLayout layout name =
    ConfirmOpen
        { color = Tw.red
        , icon = Trash
        , title = "Delete layout"
        , message =
            span []
                [ text "Are you sure you want to delete "
                , bText name
                , text " layout?"
                , br [] []
                , text ("It contains " ++ (layout.tables |> String.pluralizeL "table") ++ ".")
                ]
        , confirm = "Delete " ++ name ++ " layout"
        , cancel = "Cancel"
        , onConfirm = T.send (name |> LDelete |> LayoutMsg)
        }

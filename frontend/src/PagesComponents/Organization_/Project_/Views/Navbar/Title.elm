module PagesComponents.Organization_.Project_.Views.Navbar.Title exposing (LayoutFolder(..), NavbarTitleArgs, argsToString, buildFolders, viewNavbarTitle)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Avatar as Avatar
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.NewLayoutBody as NewLayoutBody
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Html exposing (Html, button, div, small, span, text, ul)
import Html.Attributes exposing (class, classList, disabled, id, tabindex, title, type_)
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
import Libs.Tuple3 as Tuple3
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
                    [ ContextMenu.btnHotkey "" TriggerSaveProject [] [ text "Save project" ] platform (Conf.hotkeys |> Dict.getOrElse "save" [])
                    , ContextMenu.btn "" (RenameProject |> prompt "Rename project" (text "") project.name) [] [ text "Rename project" ]
                    , ContextMenu.btn "" (DeleteProject project |> confirmDanger "Delete project?" (text "This action is definitive!")) [] [ text "Delete project" ]
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
                            ContextMenu.submenuHtml ContextMenu.BottomRight
                                [ Avatar.xs org.logo org.name "mr-2", span [] [ text (org.name ++ " »") ] ]
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
            div [ class "min-w-max divide-y divide-gray-100 text-gray-700" ]
                [ div [ role "none", class "py-1" ]
                    [ ContextMenu.btnHotkey "" (NewLayoutBody.Create |> NewLayout.Open |> NewLayoutMsg) [] [ text "Create new layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" [])
                    , div [ class "flex justify-between" ]
                        [ ContextMenu.btn "grow text-center" (NewLayoutBody.Rename currentLayout |> NewLayout.Open |> NewLayoutMsg) [ title "Rename this layout" ] [ Icon.solid PencilAlt "inline-block" ]
                        , ContextMenu.btn "grow text-center" (NewLayoutBody.Duplicate currentLayout |> NewLayout.Open |> NewLayoutMsg) [ title "Duplicate this layout" ] [ Icon.solid DocumentDuplicate "inline-block" ]
                        , ContextMenu.btn "grow text-center" (currentLayout |> confirmDeleteLayout) [ title "Delete this layout" ] [ Icon.solid Trash "inline-block" ]
                        ]
                    ]

                --, ul [ class "context-menu max-h-96 overflow-y-auto" ] -- FIXME: overflow-y-auto make nested menu not visible :/
                , ul [ class "context-menu py-1" ]
                    (layouts |> buildFolders |> viewLayoutFolders currentLayout "" |> List.map ContextMenu.nestedItem)
                ]
        )


type LayoutFolder
    = LayoutItem String ( LayoutName, ErdLayout )
    | LayoutFolder String (List LayoutFolder)


buildFolders : Dict LayoutName ErdLayout -> List LayoutFolder
buildFolders layouts =
    layouts |> Dict.toList |> List.map (\( name, layout ) -> ( name |> String.split "/" |> List.map String.trim, name, layout )) |> buildFoldersNested


buildFoldersNested : List ( List String, LayoutName, ErdLayout ) -> List LayoutFolder
buildFoldersNested layouts =
    layouts
        |> List.groupBy (\( parts, _, _ ) -> parts |> List.headOr "")
        |> Dict.toList
        |> List.sortBy (\( folder, _ ) -> folder |> String.toLower)
        |> List.concatMap
            (\( folder, items ) ->
                case items of
                    ( parts, name, layout ) :: [] ->
                        [ LayoutItem (parts |> String.join " / ") ( name, layout ) ]

                    _ ->
                        let
                            ( folderName, folderItems ) =
                                buildFoldersNestedFlat folder (items |> List.map (Tuple3.mapFirst (List.drop 1)))
                        in
                        [ LayoutFolder folderName (folderItems |> buildFoldersNested) ]
            )


buildFoldersNestedFlat : String -> List ( List String, LayoutName, ErdLayout ) -> ( String, List ( List String, LayoutName, ErdLayout ) )
buildFoldersNestedFlat folder layouts =
    case layouts |> List.groupBy (\( parts, _, _ ) -> parts |> List.headOr "") |> Dict.keys of
        sub :: [] ->
            buildFoldersNestedFlat (folder ++ " / " ++ sub) (layouts |> List.map (Tuple3.mapFirst (List.drop 1)))

        _ ->
            ( folder, layouts )


countLayouts : List LayoutFolder -> Int
countLayouts folders =
    folders
        |> List.map
            (\folder ->
                case folder of
                    LayoutItem _ _ ->
                        1

                    LayoutFolder _ items ->
                        countLayouts items
            )
        |> List.sum


viewLayoutFolders : LayoutName -> String -> List LayoutFolder -> List (ContextMenu.Nested Msg)
viewLayoutFolders currentLayout folderPrefix folders =
    folders
        |> List.map
            (\folder ->
                case folder of
                    LayoutItem folderName ( layoutName, layout ) ->
                        ContextMenu.SingleItem (viewLayoutItem (currentLayout == layoutName) folderName layoutName layout)

                    LayoutFolder folderName items ->
                        let
                            prefix : String
                            prefix =
                                folderPrefix ++ folderName ++ "/"
                        in
                        ContextMenu.NestedItem ContextMenu.BottomRight (viewLayoutFolder (currentLayout |> String.startsWith prefix) folderName (countLayouts items)) (items |> viewLayoutFolders currentLayout prefix)
            )


viewLayoutItem : Bool -> String -> LayoutName -> ErdLayout -> Html Msg
viewLayoutItem isCurrent folderName layoutName layout =
    button [ type_ "button", onClick (layoutName |> LLoad |> LayoutMsg), role "menuitem", tabindex -1, css [ "w-full text-left", B.cond isCurrent ContextMenu.itemCurrentStyles ContextMenu.itemStyles, focus [ "outline-none" ] ] ]
        [ text folderName, text " ", small [] [ text ("(" ++ ((List.length layout.tables + List.length layout.tableRows + List.length layout.memos) |> String.pluralize "item") ++ ")") ] ]


viewLayoutFolder : Bool -> String -> Int -> Html msg
viewLayoutFolder isCurrent folderName count =
    button [ type_ "button", role "menuitem", tabindex -1, css [ "w-full text-left", B.cond isCurrent ContextMenu.itemCurrentStyles ContextMenu.itemStyles, focus [ "outline-none" ] ] ]
        [ text folderName, text " ", small [] [ text ("(" ++ (count |> String.pluralize "layout") ++ ")") ] ]


confirmDeleteLayout : LayoutName -> Msg
confirmDeleteLayout name =
    ConfirmOpen
        { color = Tw.red
        , icon = Trash
        , title = "Delete layout"
        , message = span [] [ text "Are you sure you want to delete ", bText name, text " layout?" ]
        , confirm = "Delete " ++ name ++ " layout"
        , cancel = "Cancel"
        , onConfirm = T.send (name |> LDelete |> LayoutMsg)
        }

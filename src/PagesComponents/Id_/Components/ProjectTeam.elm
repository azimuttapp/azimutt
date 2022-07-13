module PagesComponents.Id_.Components.ProjectTeam exposing (Model, Msg(..), init, update, view)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Tooltip as Tooltip
import Html exposing (Html, br, div, img, input, label, p, text)
import Html.Attributes exposing (alt, class, disabled, for, id, name, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html exposing (bText)
import Libs.Html.Attributes exposing (ariaDescribedby, css, role)
import Libs.Maybe as Maybe
import Libs.Models.Email as Email
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus, sm)
import Libs.Task as T
import Models.User as User exposing (User)
import Models.UserId exposing (UserId)
import PagesComponents.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports
import Shared exposing (Confirm)


type alias Model =
    { shareInput : String
    , searching : Bool
    , shareUser : Maybe ( String, Maybe User )
    , addingOwner : Bool
    , removingOwner : Maybe UserId
    , owners : List User
    }


type Msg
    = ShareUpdate String
    | SearchUser String
    | UpdateShareUser (Maybe ( String, Maybe User ))
    | AddOwner ProjectInfo User
    | RemoveOwner ProjectInfo (List User) User
    | UpdateOwners (List User)


init : Model
init =
    { shareInput = ""
    , searching = False
    , shareUser = Nothing
    , addingOwner = False
    , removingOwner = Nothing
    , owners = []
    }


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        ShareUpdate value ->
            ( { model | shareInput = value }, Cmd.none )

        SearchUser email ->
            ( { model | searching = True }, Ports.getUser email )

        UpdateShareUser value ->
            ( { model | searching = False, shareUser = value }, Cmd.none )

        AddOwner project user ->
            ( { model | addingOwner = True }, Ports.setOwners project.id ((model.owners |> List.map .id) ++ [ user.id ]) )

        RemoveOwner project owners user ->
            ( { model | removingOwner = Just user.id }, Ports.setOwners project.id (owners |> List.map .id |> List.filter (\id -> id /= user.id)) )

        UpdateOwners value ->
            ( { model | shareInput = "", shareUser = Nothing, addingOwner = False, removingOwner = Nothing, owners = value }, Cmd.none )


view : (Confirm msg -> msg) -> Cmd msg -> (Msg -> msg) -> HtmlId -> User -> ProjectInfo -> Model -> Html msg
view confirm onDelete wrap htmlId user project model =
    div []
        [ shareWithForm wrap htmlId model project
        , listOwners confirm onDelete wrap user model.owners model.removingOwner project
        ]


shareWithForm : (Msg -> msg) -> HtmlId -> Model -> ProjectInfo -> Html msg
shareWithForm wrap htmlId model project =
    let
        ( inputId, descriptionId ) =
            ( htmlId ++ "-email", htmlId ++ "-email-description" )

        inputBorder : String
        inputBorder =
            if model.shareInput == "" || Email.isValid model.shareInput then
                "border-gray-300"

            else
                "border-red-300"

        inputIndicator : Html msg
        inputIndicator =
            if model.shareInput == "" || Email.isValid model.shareInput then
                div [] []

            else
                div [ class "absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none" ] [ Icon.solid ExclamationCircle "text-red-500" ]
    in
    div []
        [ label [ for inputId, class "block text-sm font-medium text-gray-700" ] [ text "Share with:" ]
        , div [ class "mt-1" ]
            [ div [ class "flex justify-between" ]
                [ div [ class "relative grow" ]
                    [ input
                        [ type_ "email"
                        , name "email"
                        , id inputId
                        , placeholder "friend@mail.com"
                        , ariaDescribedby descriptionId
                        , value model.shareInput
                        , onInput (ShareUpdate >> wrap)
                        , css [ "block w-full rounded-md shadow-sm", inputBorder, focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ]
                        ]
                        []
                    , inputIndicator
                    ]
                , if model.shareInput |> Email.isValid |> not then
                    Button.primary3 Tw.emerald [ disabled True, class "ml-3 whitespace-nowrap" ] [ text "Search" ]

                  else if model.searching then
                    Button.primary3 Tw.emerald [ disabled True, class "ml-3 whitespace-nowrap" ] [ Icon.loading "animate-spin mr-3", text "Search" ]

                  else
                    Button.primary3 Tw.emerald [ onClick (SearchUser model.shareInput |> wrap), class "ml-3 whitespace-nowrap" ] [ text "Search" ]
                ]
            ]
        , case model.shareUser of
            Nothing ->
                div [] []

            Just ( email, Nothing ) ->
                div [ class "py-3 text-red-500" ]
                    [ bText ("No user with email: " ++ email)
                    , br [] []
                    , bText "Please check email address or them to join Azimutt before if not done."
                    ]

            Just ( _, Just user ) ->
                div [ class "flex justify-between items-center" ]
                    [ showUser user
                    , if model.owners |> List.any (\u -> u.id == user.id) then
                        Button.primary3 Tw.emerald [ disabled True, class "ml-3 whitespace-nowrap" ] [ text "Already owner" ]

                      else if model.addingOwner then
                        Button.primary3 Tw.emerald
                            [ disabled True, class "ml-3 whitespace-nowrap" ]
                            [ Icon.loading "animate-spin mr-3", text "Add as owner" ]

                      else
                        Button.primary3 Tw.emerald
                            [ onClick (AddOwner project user |> wrap), class "ml-3 whitespace-nowrap" ]
                            [ text "Add as owner" ]
                    ]
        , p [ class "mt-1 text-sm text-gray-500", id descriptionId ]
            [ text "Use email to share project ownership with other people."
            , br [] []
            , text "All owners have the same rights, they can add/remove owners but also delete the project!"
            , br [] []
            , text "Make sure you trust them!"
            ]
        ]


listOwners : (Confirm msg -> msg) -> Cmd msg -> (Msg -> msg) -> User -> List User -> Maybe UserId -> ProjectInfo -> Html msg
listOwners confirm onDelete wrap user owners removingOwner project =
    div [ class "mt-3" ]
        [ div [ class "text-sm font-semibold text-gray-800" ] [ text "Project owners:" ]
        , if owners == [] then
            div [ class "pl-6 pt-6 pb-7" ] [ Icon.loading "animate-spin" ]

          else
            div [ role "list", class "divide-y divide-gray-200" ]
                (owners
                    |> List.map
                        (\owner ->
                            div [ class "flex justify-between items-center" ]
                                [ showUser owner
                                , if user.id /= owner.id then
                                    if removingOwner |> Maybe.has owner.id then
                                        Button.primary1 Tw.red
                                            [ disabled True, class "ml-3 whitespace-nowrap" ]
                                            [ Icon.loading "animate-spin mr-3", text "Remove" ]

                                    else
                                        Button.primary1 Tw.red
                                            [ onClick (removeOwner confirm wrap project owners owner), class "ml-3 whitespace-nowrap" ]
                                            [ text "Remove" ]

                                  else if List.length owners == 1 then
                                    Button.primary1 Tw.red
                                        [ onClick (deleteProject confirm onDelete project), class "ml-3 whitespace-nowrap" ]
                                        [ text "Leave and delete" ]
                                        |> Tooltip.tl "This project will be deleted!"

                                  else
                                    Button.primary1 Tw.red
                                        [ onClick (removeYou confirm project owners owner), class "ml-3 whitespace-nowrap" ]
                                        [ text "Leave" ]
                                        |> Tooltip.tl "You will no longer access this project!"
                                ]
                        )
                )
        ]


showUser : User -> Html msg
showUser user =
    div [ class "py-4 flex" ]
        [ img [ class "h-10 w-10 rounded-full", src (user |> User.avatar), alt user.name ] []
        , div [ class "ml-3" ]
            [ p [ class "text-sm font-medium text-gray-900" ] [ text user.name ]
            , p [ class "text-sm text-gray-500" ] [ text user.email ]
            ]
        ]


removeOwner : (Confirm msg -> msg) -> (Msg -> msg) -> ProjectInfo -> List User -> User -> msg
removeOwner confirm wrap project owners user =
    confirm
        { color = Tw.red
        , icon = Icon.UserRemove
        , title = "Remove " ++ user.name ++ "?"
        , message =
            div []
                [ bText user.name
                , text " will no longer have access to "
                , bText project.name
                , text " project."
                , br [] []
                , text "You can still add it back later it you want."
                ]
        , confirm = "Remove " ++ user.name
        , cancel = "Cancel"
        , onConfirm = RemoveOwner project owners user |> wrap |> T.send
        }


removeYou : (Confirm msg -> msg) -> ProjectInfo -> List User -> User -> msg
removeYou confirm project owners user =
    confirm
        { color = Tw.red
        , icon = Icon.UserRemove
        , title = "Leave " ++ project.name ++ " project?"
        , message =
            div []
                [ text "You will no longer have access to "
                , bText project.name
                , text " project."
                , br [] []
                , text "If you need to access it again, you will have to ask others to add you back."
                ]
        , confirm = "Leave " ++ project.name ++ " project"
        , cancel = "Cancel"
        , onConfirm = Ports.setOwners project.id (owners |> List.map .id |> List.filter (\id -> id /= user.id))
        }


deleteProject : (Confirm msg -> msg) -> Cmd msg -> ProjectInfo -> msg
deleteProject confirm onDelete project =
    confirm
        { color = Tw.red
        , icon = Icon.UserRemove
        , title = "Delete " ++ project.name ++ " project?"
        , message =
            div []
                [ text "As you are the last owner of "
                , bText project.name
                , text " project, it will be deleted if you leave."
                , br [] []
                , bText "This action can't be reverted"
                , text ", everything will be lost."
                ]
        , confirm = "Delete " ++ project.name ++ " project"
        , cancel = "Cancel"
        , onConfirm = Cmd.batch [ Ports.dropProject project, onDelete ]
        }

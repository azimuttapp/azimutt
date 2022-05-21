module PagesComponents.Projects.Id_.Views.Modals.ProjectUpload exposing (viewProjectUpload)

import Components.Atoms.Button as Button
import Components.Molecules.Modal as Modal
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw
import Models.Project.ProjectStorage as ProjectStorage
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectUploadDialog, ProjectUploadMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)


viewProjectUpload : Bool -> Erd -> ProjectUploadDialog -> Html Msg
viewProjectUpload opened erd model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        -- MoveProjectTo ProjectStorage.Browser
        -- MoveProjectTo ProjectStorage.Cloud
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = ModalClose (ProjectUploadMsg PUClose)
        }
        [ div [ class "p-3" ]
            [ h1 [ class "text-4xl font-black" ] [ text erd.project.name ]
            , if erd.project.storage == ProjectStorage.Cloud then
                Button.primary3 Tw.primary [ onClick (MoveProjectTo ProjectStorage.Browser) ] [ text "Move project to local" ]

              else
                Button.primary3 Tw.primary [ onClick (MoveProjectTo ProjectStorage.Cloud) ] [ text "Move project to cloud" ]
            ]
        ]

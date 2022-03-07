module Components.Slices.Content exposing (CenteredModel, centered, doc)

import Components.Atoms.Dots as Dots
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html, a, blockquote, div, figcaption, figure, h1, h2, img, li, p, span, strong, text, ul)
import Html.Attributes exposing (alt, height, href, src, width)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, css, role)
import Libs.Maybe as Maybe
import Libs.Tailwind exposing (lg, sm)


type alias CenteredModel msg =
    { section : String
    , title : String
    , introduction : Maybe String
    , content : List (Html msg)
    , dots : Bool
    }


centered : CenteredModel msg -> Html msg
centered model =
    div [ css [ "relative py-16 bg-white overflow-hidden" ] ]
        [ B.cond model.dots
            (div [ css [ "hidden", lg [ "block absolute inset-y-0 h-full w-full" ] ] ]
                [ div [ css [ "relative h-full text-lg max-w-prose mx-auto" ], ariaHidden True ]
                    [ Dots.dotsTopRight "74b3fd99-0a6f-4271-bef2-e80eeafdf357" 384
                    , Dots.dotsMiddleLeft "f210dbf6-a58d-4871-961e-36d5016a0f49" 384
                    , Dots.dotsBottomRight "d3eb07ae-5182-43e6-857d-35c643af9034" 384
                    ]
                ]
            )
            (div [] [])
        , div [ css [ "relative px-4", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ div [ css [ "text-lg max-w-prose mx-auto" ] ]
                ([ span [ css [ "block text-base text-center text-indigo-600 font-semibold tracking-wide uppercase" ] ] [ text model.section ]
                 , h1 [ css [ "mt-2 block text-3xl text-center leading-8 font-extrabold tracking-tight text-gray-900", sm [ "text-4xl" ] ] ] [ text model.title ]
                 ]
                    ++ (model.introduction |> Maybe.mapOrElse (\intro -> [ p [ css [ "mt-8 text-xl text-gray-500 leading-8" ] ] [ text intro ] ]) [])
                )
            , div [ css [ "mt-6 prose prose-indigo prose-lg text-gray-500 mx-auto" ] ] model.content
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Content"
        |> renderComponentList
            [ ( "centered"
              , centered
                    { section = "Introducing"
                    , title = "JavaScript for Beginners"
                    , introduction = Just "Aliquet nec orci mattis amet quisque ullamcorper neque, nibh sem. At arcu, sit dui mi, nibh dui, diam eget aliquam. Quisque id at vitae feugiat egestas ac. Diam nulla orci at in viverra scelerisque eget. Eleifend egestas fringilla sapien."
                    , content =
                        [ p []
                            [ text "Faucibus commodo massa rhoncus, volutpat. "
                            , strong [] [ text "Dignissim" ]
                            , text " sed "
                            , strong [] [ text "eget risus enim" ]
                            , text ". Mattis mauris semper sed amet vitae sed turpis id. Id dolor praesent donec est. Odio penatibus risus viverra tellus varius sit neque erat velit. Faucibus commodo massa rhoncus, volutpat. Dignissim sed eget risus enim. "
                            , a [ href "#" ] [ text "Mattis mauris semper" ]
                            , text " sed amet vitae sed turpis id."
                            ]
                        , ul [ role "list" ]
                            [ li [] [ text "Quis elit egestas venenatis mattis dignissim." ]
                            , li [] [ text "Cras cras lobortis vitae vivamus ultricies facilisis tempus." ]
                            , li [] [ text "Orci in sit morbi dignissim metus diam arcu pretium." ]
                            ]
                        , p [] [ text "Quis semper vulputate aliquam venenatis egestas sagittis quisque orci. Donec commodo sit viverra aliquam porttitor ultrices gravida eu. Tincidunt leo, elementum mattis elementum ut nisl, justo, amet, mattis. Nunc purus, diam commodo tincidunt turpis. Amet, duis sed elit interdum dignissim." ]
                        , h2 [] [ text "From beginner to expert in 30 days" ]
                        , p [] [ text "Id orci tellus laoreet id ac. Dolor, aenean leo, ac etiam consequat in. Convallis arcu ipsum urna nibh. Pharetra, euismod vitae interdum mauris enim, consequat vulputate nibh. Maecenas pellentesque id sed tellus mauris, ultrices mauris. Tincidunt enim cursus ridiculus mi. Pellentesque nam sed nullam sed diam turpis ipsum eu a sed convallis diam." ]
                        , blockquote [] [ p [] [ text "Sagittis scelerisque nulla cursus in enim consectetur quam. Dictum urna sed consectetur neque tristique pellentesque. Blandit amet, sed aenean erat arcu morbi." ] ]
                        , p [] [ text "Faucibus commodo massa rhoncus, volutpat. Dignissim sed eget risus enim. Mattis mauris semper sed amet vitae sed turpis id. Id dolor praesent donec est. Odio penatibus risus viverra tellus varius sit neque erat velit." ]
                        , figure []
                            [ img [ css [ "w-full rounded-lg" ], src "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-1.2.1&auto=format&fit=facearea&w=1310&h=873&q=80&facepad=3", alt "", width 1310, height 873 ] []
                            , figcaption [] [ text "Sagittis scelerisque nulla cursus in enim consectetur quam." ]
                            ]
                        , h2 [] [ text "Everything you need to get up and running" ]
                        , p []
                            [ text "Purus morbi dignissim senectus mattis "
                            , a [ href "#" ] [ text "adipiscing" ]
                            , text ". Amet, massa quam varius orci dapibus volutpat cras. In amet eu ridiculus leo sodales cursus tristique. Tincidunt sed tempus ut viverra ridiculus non molestie. Gravida quis fringilla amet eget dui tempor dignissim. Facilisis auctor venenatis varius nunc, congue erat ac. Cras fermentum convallis quam."
                            ]
                        , p [] [ text "Faucibus commodo massa rhoncus, volutpat. Dignissim sed eget risus enim. Mattis mauris semper sed amet vitae sed turpis id. Id dolor praesent donec est. Odio penatibus risus viverra tellus varius sit neque erat velit." ]
                        ]
                    , dots = True
                    }
              )
            ]

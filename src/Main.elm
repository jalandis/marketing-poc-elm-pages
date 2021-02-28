module Main exposing (main)

import Color
import Date
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font as Font
import Element.Region
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as JD
import OptimizedDecoder as Decode exposing (Decoder)
import Pages exposing (images, pages)
import Pages.Directory as Directory exposing (Directory)
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform exposing (Page)
import Pages.Secrets as Secrets
import Pages.StaticHttp as StaticHttp
import Palette
import Time



--type alias CreatePage body =
--    { path : List String
--    , content : Result String body
--    }
--
--
--createPages : StaticHttp.Request (List (CreatePage body))


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = "elm-pages - A statically typed site generator."
    , iarcRatingId = Nothing
    , name = "elm-pages docs"
    , themeColor = Just Color.white
    , startUrl = pages.index
    , shortName = Just "elm-pages"
    , sourceIcon = images.iconPng
    , icons = []
    }


type alias View =
    ()


type alias Metadata =
    ()


main : Pages.Platform.Program Model Msg Metadata View Pages.PathKey
main =
    Pages.Platform.init
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ _ -> subscriptions
        , documents =
            [ { extension = "md"
              , metadata = JD.succeed ()
              , body = \_ -> Ok ()
              }
            ]
        , onPageChange = Just OnPageChange
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , internals = Pages.internals
        }
        |> Pages.Platform.withFileGenerator fileGenerator
        |> Pages.Platform.toProgram


fileGenerator :
    List { path : PagePath Pages.PathKey, frontmatter : metadata, body : String }
    ->
        StaticHttp.Request
            (List
                (Result String
                    { path : List String
                    , content : String
                    }
                )
            )
fileGenerator siteMetadata =
    StaticHttp.succeed
        [ Ok { path = [ "hello.txt" ], content = "Hello there!" }
        , Ok { path = [ "goodbye.txt" ], content = "Goodbye there!" }
        ]


type alias Model =
    {}


init :
    Maybe
        { metadata : Metadata
        , path :
            { path : PagePath Pages.PathKey
            , query : Maybe String
            , fragment : Maybe String
            }
        }
    -> ( Model, Cmd Msg )
init maybePagePath =
    ( Model, Cmd.none )


type Msg
    = OnPageChange
        { path : PagePath Pages.PathKey
        , query : Maybe String
        , fragment : Maybe String
        , metadata : Metadata
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange page ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type alias Company =
    { name : String
    , logoUrl : String
    , loc : String
    }


companyView : Company -> Element msg
companyView company =
    Element.column []
        [ Element.el [] (Element.text company.name)
        , Element.el [] (Element.text <| "Lines of code: " ++ company.loc)
        , Element.image []
            { src = company.logoUrl
            , description = company.name ++ " logo"
            }
        ]


type alias Pokemon =
    { name : String, sprite : String }


get url decoder =
    StaticHttp.get (Secrets.succeed url)
        decoder


pokemonDetailRequest : StaticHttp.Request (List Pokemon)
pokemonDetailRequest =
    get
        "https://pokeapi.co/api/v2/pokemon/?limit=3"
        (Decode.field "results"
            (Decode.list
                (Decode.map2 Tuple.pair
                    (Decode.field "name" Decode.string)
                    (Decode.field "url" Decode.string)
                    |> Decode.map
                        (\( name, url ) ->
                            get url
                                (Decode.at [ "sprites", "front_default" ] Decode.string
                                    |> Decode.map (Pokemon name)
                                )
                        )
                )
            )
        )
        |> StaticHttp.andThen StaticHttp.combine


view :
    List ( PagePath Pages.PathKey, Metadata )
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    ->
        StaticHttp.Request
            { view : Model -> View -> { title : String, body : Html Msg }
            , head : List (Head.Tag Pages.PathKey)
            }
view siteMetadata page =
    case page.frontmatter of
        () ->
            StaticHttp.map2
                (\starCount pokemon ->
                    { view =
                        \model viewForPage ->
                            { title = "Landing Page"
                            , body =
                                [ header page starCount
                                , Element.column
                                    [ Element.paddingXY 25 10 ]
                                    [ Element.row []
                                        [ Element.text "Built on: "
                                        , Element.text <| Date.format "EEEE, d MMMM y" <| Date.fromPosix Time.utc Pages.builtAt
                                        ]
                                    , pokemon
                                        |> List.map pokemonView
                                        |> Element.column
                                            [ Element.spacing 10
                                            , Element.padding 30
                                            , Element.centerX
                                            ]
                                    ]
                                ]
                                    |> Element.column [ Element.width Element.fill ]
                                    |> layout
                            }
                    , head = head page.frontmatter
                    }
                )
                (get "https://api.github.com/repos/dillonkearns/elm-pages"
                    (Decode.field "stargazers_count" Decode.int)
                )
                pokemonDetailRequest


pokemonView : Pokemon -> Element msg
pokemonView pokemon =
    Element.row []
        [ Element.image [] { src = pokemon.sprite, description = pokemon.name ++ " sprite" }
        , Element.text pokemon.name
        ]


layout body =
    body
        |> Element.layout
            [ Element.width Element.fill
            , Font.size 20
            , Font.family [ Font.typeface "Roboto" ]
            , Font.color (Element.rgba255 0 0 0 0.8)
            ]


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.image [ Element.width Element.fill ]
        { src = ImagePath.toString articleImage
        , description = "Article cover photo"
        }


header : { path : PagePath Pages.PathKey, frontmatter : Metadata } -> Int -> Element msg
header currentPage starCount =
    Element.column [ Element.width Element.fill ]
        [ Element.el
            [ Element.height (Element.px 4)
            , Element.width Element.fill
            , Element.Background.gradient
                { angle = 0.2
                , steps =
                    [ Element.rgb255 0 242 96
                    , Element.rgb255 5 117 230
                    ]
                }
            ]
            Element.none
        , Element.row
            [ Element.paddingXY 25 4
            , Element.spaceEvenly
            , Element.width Element.fill
            , Element.Region.navigation
            , Element.Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Element.Border.color (Element.rgba255 40 80 40 0.4)
            ]
            [ Element.link []
                { url =
                    if currentPage.path == pages.index then
                        PagePath.toString pages.otherPage

                    else
                        PagePath.toString pages.index
                , label =
                    Element.row
                        [ Font.size 30
                        , Element.spacing 16
                        , Element.htmlAttribute (Attr.id "navbar-title")
                        ]
                        [ Element.text "Elm Marketing Site POC"
                        ]
                }
            , Element.row [ Element.spacing 15 ]
                [ elmDocsLink
                , githubRepoLink starCount
                ]
            ]
        ]


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : () -> List (Head.Tag Pages.PathKey)
head () =
    Seo.summaryLarge
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages external data example"
        , image =
            { url = images.iconPng
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = siteTagline
        , locale = Nothing
        , title = "External Data Example"
        }
        |> Seo.website


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://elm-pages.com"


siteTagline : String
siteTagline =
    "A statically typed site generator - elm-pages"


githubRepoLink : Int -> Element msg
githubRepoLink starCount =
    Element.newTabLink []
        { url = "https://github.com/dillonkearns/elm-pages"
        , label =
            Element.row [ Element.spacing 5 ]
                [ Element.image
                    [ Element.width (Element.px 22)
                    , Font.color Palette.color.primary
                    ]
                    { src = ImagePath.toString Pages.images.github, description = "Github repo" }
                , Element.text <| String.fromInt starCount
                ]
        }


elmDocsLink : Element msg
elmDocsLink =
    Element.newTabLink []
        { url = "https://package.elm-lang.org/packages/dillonkearns/elm-pages/latest/"
        , label =
            Element.image
                [ Element.width (Element.px 22)
                , Font.color Palette.color.primary
                ]
                { src = ImagePath.toString Pages.images.elmLogo, description = "Elm Package Docs" }
        }

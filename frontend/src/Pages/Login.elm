module Pages.Login exposing (Model, Msg(..), init, update, view)

import Db.Auth as Auth
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Platform.Cmd exposing (Cmd)
import String
import Svg exposing (Svg, node, svg)
import Svg.Attributes as SA


type alias Model =
    { username : String
    , password : String
    , error : Maybe String
    , isSubmitting : Bool
    }


type Msg
    = SetUsername String
    | SetPassword String
    | Submit
    | LoginResult (Result Http.Error Auth.LoginResponse)
    | GoogleLogin
    | GithubLogin


init : ( Model, Cmd Msg )
init =
    ( { username = ""
      , password = ""
      , error = Nothing
      , isSubmitting = False
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetUsername u ->
            ( { model | username = u }, Cmd.none )

        SetPassword p ->
            ( { model | password = p }, Cmd.none )

        GoogleLogin ->
            ( model, Cmd.none )

        GithubLogin ->
            ( model, Cmd.none )

        Submit ->
            if model.isSubmitting then
                ( model, Cmd.none )

            else
                let
                    body =
                        Encode.object
                            [ ( "username", Encode.string model.username )
                            , ( "password", Encode.string model.password )
                            ]
                in
                ( { model | isSubmitting = True, error = Nothing }
                , Auth.login body LoginResult
                )

        LoginResult (Ok response) ->
            if response.ok then
                ( { model
                    | isSubmitting = False
                    , error = Nothing
                  }
                , Cmd.none
                )

            else
                ( { model
                    | isSubmitting = False
                    , error = Just response.message
                  }
                , Cmd.none
                )

        LoginResult (Err httpError) ->
            ( { model | isSubmitting = False, error = Just (httpErrorToString httpError) }, Cmd.none )


googleSvgIcon : Svg msg
googleSvgIcon =
    svg
        [ SA.version "1.1"
        , SA.viewBox "0 0 48 48"
        , SA.style "display: block"
        ]
        [ node "path"
            [ SA.fill "#EA4335"
            , SA.d "M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
            ]
            []
        , node "path"
            [ SA.fill "#4285F4"
            , SA.d "M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
            ]
            []
        , node "path"
            [ SA.fill "#FBBC05"
            , SA.d "M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
            ]
            []
        , node "path"
            [ SA.fill "#34A853"
            , SA.d "M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
            ]
            []
        , node "path"
            [ SA.fill "none"
            , SA.d "M0 0h48v48H0z"
            ]
            []
        ]


googleButton : Html Msg
googleButton =
    Html.button [ HE.onClick GoogleLogin, HA.class "gsi-material-button" ]
        [ Html.div [ HA.class "gsi-material-button-state" ] []
        , Html.div [ HA.class "gsi-material-button-content-wrapper" ]
            [ Html.div [ HA.class "gsi-material-button-icon" ]
                [ googleSvgIcon ]
            , Html.span [ HA.class "gsi-material-button-contents" ] [ Html.text "Continue with Google" ]
            , Html.span [ HA.style "display" "none" ] [ Html.text "Continue with Google" ]
            ]
        ]


githubSvgIcon : Svg msg
githubSvgIcon =
    svg
        [ SA.version "1.1"
        , SA.viewBox "0 0 512 512"
        , SA.style "width: 30px; vertical-align: middle; border-right:0.5px solid #aaa; border-top-left-radius: 15%; border-bottom-left-radius: 15%;"
        ]
        [ node "rect"
            [ SA.width "512"
            , SA.height "512"
            , SA.fill "#1B1817"
            ]
            []
        , node "path"
            [ SA.fill "#fff"
            , SA.d "M335 499c14 0 12 17 12 17H165s-2-17 12-17c13 0 16-6 16-12l-1-50c-71 16-86-28-86-28-12-30-28-37-28-37-24-16 1-16 1-16 26 2 40 26 40 26 22 39 59 28 74 22 2-17 9-28 16-35-57-6-116-28-116-126 0-28 10-51 26-69-3-6-11-32 3-67 0 0 21-7 70 26 42-12 86-12 128 0 49-33 70-26 70-26 14 35 6 61 3 67 16 18 26 41 26 69 0 98-60 120-117 126 10 8 18 24 18 48l-1 70c0 6 3 12 16 12z"
            ]
            []
        ]


githubButton : Html Msg
githubButton =
    Html.button
        [ HE.onClick GithubLogin
        , HA.class "github-button"
        ]
        [ githubSvgIcon
        , Html.span [] [ Html.text "Continue with GitHub" ]
        ]


httpErrorToString : Http.Error -> String
httpErrorToString httpError =
    case httpError of
        Http.BadUrl msg ->
            "Bad url: " ++ msg

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus code ->
            "Bad status: " ++ String.fromInt code

        Http.BadBody msg ->
            "Bad body: " ++ msg


view : Model -> Html Msg
view model =
    Html.div [ HA.class "login-register-container" ]
        [ Html.h1 [] [ Html.text "LOGIN" ]
        , Html.div [ HA.class "input-group" ]
            [ Html.label [ HA.for "username" ] [ Html.text "USERNAME" ]
            , Html.input
                [ HA.placeholder "username123"
                , HA.id "username"
                , HA.type_ "text"
                , HA.value model.username
                , HE.onInput SetUsername
                ]
                []
            ]
        , Html.div [ HA.class "input-group" ]
            [ Html.label [ HA.for "pasword" ] [ Html.text " PASSWORD" ]
            , Html.input
                [ HA.placeholder "••••••••"
                , HA.id "password"
                , HA.type_ "password"
                , HA.value model.password
                , HE.onInput SetPassword
                ]
                []
            ]
        , case model.error of
            Just e ->
                Html.div [ HA.class "error" ] [ Html.text e ]

            Nothing ->
                Html.div [] []
        , Html.button [ HA.class "custom-button", HA.class "submit-button", HE.onClick Submit, HA.disabled model.isSubmitting ]
            [ Html.text
                (if model.isSubmitting then
                    "SIGNING IN..."

                 else
                    "SIGN IN"
                )
            ]
        , Html.div [ HA.class "divider" ] [ Html.text "OR" ]
        , Html.div [ HA.class "social-login" ]
            [ googleButton
            , githubButton
            ]
        , Html.div [ HA.class "footer" ]
            [ Html.text "Don't have an account? "
            , Html.a [] [ Html.text "Sign up" ]
            ]
        ]

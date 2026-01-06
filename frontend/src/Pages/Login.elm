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


googleButton : Html Msg
googleButton =
    Html.button
        [ HE.onClick GoogleLogin
        , HA.class "button-unset"
        ]
        [ Html.i [ HA.class "nes-icon google is-large" ] []
        ]


githubButton : Html Msg
githubButton =
    Html.button
        [ HE.onClick GithubLogin
        , HA.class "button-unset"
        ]
        [ Html.i [ HA.class "nes-icon github is-large" ] []
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

module Pages.Login exposing (Model, Msg(..), init, update, view)

import Api.Auth as Auth
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Platform.Cmd exposing (Cmd)
import String


type alias Model =
    { email : String
    , password : String
    , error : Maybe String
    , isSubmitting : Bool
    }


type Msg
    = SetEmail String
    | SetPassword String
    | Submit
    | LoginResult (Result Http.Error Auth.LoginResponse)


init : ( Model, Cmd Msg )
init =
    ( { email = ""
      , password = ""
      , error = Nothing
      , isSubmitting = False
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetEmail e ->
            ( { model | email = e }, Cmd.none )

        SetPassword p ->
            ( { model | password = p }, Cmd.none )

        Submit ->
            if model.isSubmitting then
                ( model, Cmd.none )

            else
                let
                    body =
                        Encode.object
                            [ ( "email", Encode.string model.email )
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
    Html.form
        [ HA.class "login-form"
        , HE.preventDefaultOn "submit" (Decode.succeed ( Submit, True ))
        ]
        [ Html.div []
            [ Html.label [] [ Html.text "Email" ]
            , Html.input [ HA.type_ "text", HA.value model.email, HE.onInput SetEmail ] []
            ]
        , Html.div []
            [ Html.label [] [ Html.text "Password" ]
            , Html.input [ HA.type_ "password", HA.value model.password, HE.onInput SetPassword ] []
            ]
        , case model.error of
            Just e ->
                Html.div [ HA.class "error" ] [ Html.text e ]

            Nothing ->
                Html.div [] []
        , Html.button [ HA.disabled model.isSubmitting ]
            [ Html.text
                (if model.isSubmitting then
                    "Signing in..."

                 else
                    "Sign in"
                )
            ]
        ]

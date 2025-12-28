module Pages.Dashboard exposing (..)

import Db.Auth as Auth
import Html exposing (Html)
import Http


type alias Model =
    { user : Maybe User
    }


type alias User =
    { email : Maybe String
    , firstname : Maybe String
    , lastname : Maybe String
    , createdAt : String
    }


type Msg
    = GotUser (Result Http.Error Auth.UserResponse)


init : ( Model, Cmd Msg )
init =
    ( { user = Nothing }
    , Auth.getMe GotUser
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser (Ok response) ->
            case response.user of
                Just user ->
                    ( { model | user = Just user }
                    , Cmd.none
                    )

                Nothing ->
                    -- user missing → likely not authenticated
                    ( model, Cmd.none )

        GotUser (Err httpError) ->
            ( model, Cmd.none )


view : Model -> Bool -> Html Msg
view model isLoggedIn =
    if isLoggedIn then
        Html.div []
            [ case model.user of
                Just user ->
                    Html.div []
                        [ Html.p [] [ Html.text ("Email: " ++ (Maybe.withDefault "Not provided" user.email)) ]
                        , Html.p [] [ Html.text ("First Name: " ++ (Maybe.withDefault "Not provided" user.firstname)) ]
                        , Html.p [] [ Html.text ("Last Name: " ++ (Maybe.withDefault "Not provided"  user.lastname)) ]
                        , Html.p [] [ Html.text ("Created At: " ++ user.createdAt) ]
                        ]

                Nothing ->
                    Html.p [] [ Html.text "User data not available." ]
            ]

    else
        Html.div [] [ Html.text "Please log in" ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

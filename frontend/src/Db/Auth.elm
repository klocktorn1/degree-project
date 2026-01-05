module Db.Auth exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode


type alias LoginResponse =
    { ok : Bool
    , message : String
    }


type alias RegisterResponse =
    { ok : Bool
    , message : String
    }


type alias UserResponse =
    { user : Maybe User
    }


type alias User =
    { email : Maybe String
    , firstname : Maybe String
    , lastname : Maybe String
    , createdAt : String
    }


googleClientId : String
googleClientId =
    "410839726466-e2f6cb7hfk5n3euenjngsia9qdfkjrhn.apps.googleusercontent.com"


googleRedirectUri : String
googleRedirectUri =
    baseUrl ++ "/auth/google/callback"


googleOAuthUrl : String
googleOAuthUrl =
    "https://accounts.google.com/o/oauth2/v2/auth?"
        ++ "client_id="
        ++ googleClientId
        ++ "&redirect_uri="
        ++ googleRedirectUri
        ++ "&response_type=code"
        ++ "&scope=openid email profile"
        ++ "&access_type=offline"
        ++ "&prompt=consent"


githubClientId : String
githubClientId =
    "Ov23li9EHrE7iB79p8Ph"


githubRedirectUri : String
githubRedirectUri =
    baseUrl ++ "/auth/github/callback"


githubOAuthUrl : String
githubOAuthUrl =
    "https://github.com/login/oauth/authorize?"
        ++ "client_id="
        ++ githubClientId
        ++ "&redirect_uri="
        ++ githubRedirectUri
        ++ "&scope=read:user user:email"


baseUrl : String
baseUrl =
    "https://degree-project-xnqu-git-main-nicholas-snow-mattssons-projects.vercel.app"


loginDecoder : Decode.Decoder LoginResponse
loginDecoder =
    Decode.map2 LoginResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


registerDecoder : Decode.Decoder RegisterResponse
registerDecoder =
    Decode.map2 RegisterResponse
        (Decode.field "ok" Decode.bool)
        (Decode.field "message" Decode.string)


userResponseDecoder : Decode.Decoder UserResponse
userResponseDecoder =
    Decode.map UserResponse
        (Decode.field "user" (Decode.maybe userDecoder))


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map4 User
        (Decode.field "email" (Decode.maybe Decode.string))
        (Decode.field "firstname" (Decode.maybe Decode.string))
        (Decode.field "lastname" (Decode.maybe Decode.string))
        (Decode.field "createdAt" Decode.string)


login : Encode.Value -> (Result Http.Error LoginResponse -> msg) -> Cmd msg
login body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/login"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg loginDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


register : Encode.Value -> (Result Http.Error RegisterResponse -> msg) -> Cmd msg
register body toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/register"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg registerDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getMe : (Result Http.Error UserResponse -> msg) -> Cmd msg
getMe toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url = baseUrl ++ "/users/me"
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg userResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getExerciseResults : Maybe String -> Maybe String -> (Result Http.Error UserResponse -> msg) -> Cmd msg
getExerciseResults maybeAccessToken maybeId toMsg =
    case ( maybeAccessToken, maybeId ) of
        ( Just token, Just id ) ->
            Http.request
                { method = "GET"
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , url = baseUrl ++ "/users/" ++ id
                , body = Http.emptyBody
                , expect = Http.expectJson toMsg userResponseDecoder
                , timeout = Nothing
                , tracker = Nothing
                }

        _ ->
            Cmd.none


refreshToken : (Result Http.Error () -> msg) -> Cmd msg
refreshToken toMsg =
    Http.request
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/auth/refresh"
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


logout : (Result Http.Error () -> msg) -> Cmd msg
logout toMsg =
    Http.post
        { url = baseUrl ++ "/auth/logout"
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        }

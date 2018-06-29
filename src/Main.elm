port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Http exposing (..)
import Json.Decode exposing (field, string)
import Auth0
import Authentication

main : Program (Maybe Auth0.LoggedInUser) Model Msg
main = Html.programWithFlags
           { init = init
           , update = update
           , subscriptions = subscriptions
           , view = view
           }

-- Ports

port auth0authorize : Auth0.Options -> Cmd msg
port auth0authResult : (Auth0.RawAuthenticationResult -> msg) -> Sub msg
port auth0logout : () -> Cmd msg

type alias Model =
  { authModel: Authentication.Model,
    message: String
  }


-- Init

init : Maybe Auth0.LoggedInUser -> (Model, Cmd Msg)
init initialUser =
  ( Model (Authentication.init auth0authorize auth0logout initialUser) "", Cmd.none )


-- Update

type Msg
  = AuthenticationMsg Authentication.Msg
  | HitPublicEndpoint
  | PublicEndpoint (Result Http.Error String)
  | HitPrivateEndpoint
  | PrivateEndpoint (Result Http.Error String)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    AuthenticationMsg authMsg ->
      let
          (authModel, cmd) =
            Authentication.update authMsg model.authModel
      in
          ( { model | authModel = authModel }, Cmd.map AuthenticationMsg cmd )
    HitPublicEndpoint ->
      (model, Http.send PublicEndpoint (Http.post
      "https://zwv6qo00gd.execute-api.eu-west-2.amazonaws.com/dev/api/public" Http.emptyBody (field
      "message" string)))
    PublicEndpoint (Ok newMessage) ->
      ( { model | message = newMessage }, Cmd.none)
    PublicEndpoint (Err _) ->
      (model, Cmd.none)
    HitPrivateEndpoint ->
      (model, Http.send PrivateEndpoint (postWithAuth
      "https://zwv6qo00gd.execute-api.eu-west-2.amazonaws.com/dev/api/private"
      (Authentication.getToken model.authModel)
      ))
    PrivateEndpoint (Ok newMessage) ->
      ( { model | message = newMessage }, Cmd.none )
    PrivateEndpoint (Err _) ->
      (model, Cmd.none)

postWithAuth : String -> String -> Http.Request String
postWithAuth url token =
  let
      decoder = field "message" string
      headers =
        [
          Http.header "Authorization" ("Bearer " ++ token)
        ]
  in
    Http.request
      {
        method = "POST"
      , headers = headers
      , url = url
      , body = Http.emptyBody
      , expect = Http.expectJson decoder
      , timeout = Nothing
      , withCredentials = False
      }

-- Subscriptions

subscriptions : a -> Sub Msg
subscriptions model =
  auth0authResult (Authentication.handleAuthResult >> AuthenticationMsg)

-- View

view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "jumbotron text-center" ]
            [ div []
                (case Authentication.tryGetUserProfile model.authModel of
                    Nothing ->
                        [ p [] [ text "Please log in" ] ]

                    Just user ->
                        [ p [] [ text ("Hello, " ++ user.email ++ "!") ] ]
                )
            , p []
                [ button
                    [ class "btn btn-primary"
                    , onClick
                        (AuthenticationMsg
                            (if Authentication.isLoggedIn model.authModel then
                                Authentication.LogOut
                                else
                                Authentication.ShowLogIn
                            )
                        )
                    ]
                    [ text
                        (if Authentication.isLoggedIn model.authModel then
                            "Log Out"
                            else
                            "Log In"
                        )
                    ]
                ]
            , p []
              [ button
                [ class "btn btn-primary", onClick HitPublicEndpoint ]
                [ text "Ping public endpoint" ]
              ]
            , p []
              [ button
                [ class "btn btn-primary", onClick HitPrivateEndpoint ]
                [ text "Ping private endpoint" ]
              ]
            , p [] [text model.message]
            ]
        ]

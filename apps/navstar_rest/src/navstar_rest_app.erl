%%%-------------------------------------------------------------------
%% @doc navstar public API
%% @end
%%%-------------------------------------------------------------------

-module(navstar_rest_app).

-behaviour(application).

%% Application callbacks
-export([
    start/2,
    stop/1
]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    setup_cowboy(),
    navstar_rest_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
setup_cowboy() ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/lashup/kv/[...]", navstar_rest_lashup_handler, []}
        ]}
    ]),
    Port = application:get_env(navstar, port, 62080),
    {ok, _} = cowboy:start_http(http, 100, [{port, Port}], [
        {env, [{dispatch, Dispatch}]}
    ]).
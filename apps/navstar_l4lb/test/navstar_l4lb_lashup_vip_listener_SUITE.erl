-module(navstar_l4lb_lashup_vip_listener_SUITE).
-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include("navstar_l4lb.hrl").


%% root tests
all() ->
  [test_uninitalized_table,
   lookup_vip,
   lookup_failure,
   lookup_failure2,
   lookup_failure3].

init_per_suite(Config) ->
  %% this might help, might not...
  os:cmd(os:find_executable("epmd") ++ " -daemon"),
  {ok, Hostname} = inet:gethostname(),
  case net_kernel:start([list_to_atom("runner@" ++ Hostname), shortnames]) of
    {ok, _} -> ok;
    {error, {already_started, _}} -> ok
  end,
  Config.

end_per_suite(Config) ->
  net_kernel:stop(),
  Config.

init_per_testcase(test_uninitalized_table, Config) -> Config;
init_per_testcase(_, Config) ->
  meck:new(navstar_l4lb_lashup_vip_listener, [passthrough]),
  meck:expect(navstar_l4lb_lashup_vip_listener, setup_monitor, fun() -> ok end),
  application:set_env(navstar_l4lb, enable_networking, false),
  {ok, _} = application:ensure_all_started(navstar_l4lb),
  Config.

end_per_testcase(test_uninitalized_table, _Config) -> ok;
end_per_testcase(_, _Config) ->
  meck:unload(navstar_l4lb_lashup_vip_listener),
  ok = application:stop(navstar_l4lb),
  ok = application:stop(lashup),
  ok = application:stop(mnesia).

test_uninitalized_table(_Config) ->
  IP = {10, 0, 1, 10},
  [] = navstar_l4lb_lashup_vip_listener:lookup_vips([{ip, IP}]),
  ok.

lookup_failure(_Config) ->
  IP = {10, 0, 1, 10},
  [{badmatch, IP}] = navstar_l4lb_lashup_vip_listener:lookup_vips([{ip, IP}]),
  Name = <<"foobar.marathon">>,
  [{badmatch, Name}] = navstar_l4lb_lashup_vip_listener:lookup_vips([{name, Name}]),
  ok.

lookup_failure2(Config) ->
  {ok, _} = lashup_kv:request_op(?VIPS_KEY2, {update, [{update,
                                                       {{tcp, {1, 2, 3, 4}, 5000}, riak_dt_orswot},
                                                       {add, {{10, 0, 1, 10}, {{10, 0, 1, 10}, 17780}}}}]}),
  lookup_failure(Config),
  ok.

lookup_failure3(Config) ->
  {ok, _} = lashup_kv:request_op(?VIPS_KEY2, {update, [{update,
                                                       {{tcp, {name, {<<"de8b9dc86">>, <<"marathon">>}}, 6000},
                                                        riak_dt_orswot},
                                                       {add, {{10, 0, 1, 31}, {{10, 0, 1, 31}, 12998}}}}]}),
  lookup_failure(Config),
  ok.

lookup_vip(_Config) ->
  {ok, _} = lashup_kv:request_op(?VIPS_KEY2, {update, [{update,
                                                       {{tcp, {name, {<<"de8b9dc86">>, <<"marathon">>}}, 6000},
                                                        riak_dt_orswot},
                                                       {add, {{10, 0, 1, 31}, {{10, 0, 1, 31}, 12998}}}}]}),
  [] = navstar_l4lb_lashup_vip_listener:lookup_vips([]),
  [{ip, IP}] = navstar_l4lb_lashup_vip_listener:lookup_vips([{name, <<"de8b9dc86.marathon">>}]),
  [{name, <<"de8b9dc86.marathon">>}] = navstar_l4lb_lashup_vip_listener:lookup_vips([{ip, IP}]),
  ok.

%%%-------------------------------------------------------------------
%% @doc db top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(db_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

-define(WORKER(Id, Mod, Args),
        {Id, {Mod, start_link, Args},
         permanent, 5000, worker, [Mod]}).

-define(SUP(Id, Mod, Args),
        {Id, {Mod, start_link, Args},
         permanent, infinity, supervisor, [Mod]}).


%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    lager:info("starting main supervisor"),
    Children = [?WORKER(client, db_client,[])],

    {ok, { {one_for_one, 5, 10}, Children } }.

%%====================================================================
%% Internal functions
%%====================================================================

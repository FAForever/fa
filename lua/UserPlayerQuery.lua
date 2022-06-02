--------------------------------------------------------------------------------
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- Author: Bob Berry
--
-- QUERY
-- A facility for players to ask a question of another player and receive a
-- response. Suppose we have users W,X,Y,Z. A query from W->X begins in W's
-- user layer. It is marshalled into the Sim and sent to all players (W,X,Y,Z).
-- Each Sim processes the query and sends it back up into their respective user
-- layers. Although all players can see the queries and do work on them, only
-- the army the query is intended for (specified in the .To field of the
-- queryData) can generate a result for the query. The result begins in the user
-- layer of the target army and the information is passed back to everyone in
-- exactly the same way the query originally started.
--
-- This file is the USER side of the query system. The other half lives in
-- /lua/SimPlayerQuery.lua
--
--------------------------------------------------------------------------------

-- Listeners interested in specific incoming queries (the query itself, not the
-- result)
local QueryListeners = {}
function AddQueryListener( queryName, callback )
    table.insert( QueryListeners, { Name=queryName, Callback=callback } )
end

-- Listeners interested in specific query results
local ResultListeners = {}
function AddResultListener( queryName, callback )
    table.insert( ResultListeners, { Name=queryName, Callback=callback } )
end

-- list of id->callbacks for pending queries.
local PendingQueries = {}

-- the next id number we are going to issue.
local nextId = 1

-- Primary entry point of the query system. Call Query with queryData with a
-- minimum form of:
--   data = {
--       From = <armyIndex>  -- who the query is coming from
--       To = <armyIndex>    -- who the query is going to
--       Name = <queryName>  -- name of the query type
--   }
--
-- resultCallback is function called when the query results are returned (if
-- ever)
--
-- Calls OnPlayerQuery(queryData) in the sim. All players will receive it
-- regardless of whether their focus army is specified in the From or To fields.
-- This allows everyone to inspect all query traffic.
--
function Query( queryData, resultCallback )
    queryData.MsgId = nextId
    SimCallback( { Func="OnPlayerQuery", Args=queryData } )
    PendingQueries[nextId] = resultCallback
    nextId = nextId + 1
end

-- Send a query result where resultData has a minimum form of:
--   data = {
--       From = <armyIndex>  -- who the query is coming from
--       To = <armyIndex>    -- who the query is going to
--       Name = <queryName>  -- name of the query type
--   }
-- Callbacks do not occur until the sim processes the result and sends it back
-- up to the user layer.
function SendResult( originalQuery, resultData )
    resultData.InResponseTo = originalQuery.MsgId
    resultData.ToCommandSource = originalQuery.FromCommandSource
    SimCallback( { Func="OnPlayerQueryResult", Args=resultData } )
end

-- UserSync calls this when new queries arrive. The query may or may not be
-- for this focusArmy. It is the query listeners job to filter out queries meant
-- for other users. This lets anyone hear all traffic for any query type.
function ProcessQueries( queries )
    for k,v in queries do
        for index,listener in QueryListeners do
            if listener.Name == v.Name then
                listener.Callback(v)
            end
        end
    end
end

-- UserSync calls this when the query results are in. Just as above, the listeners
-- are responsible for examining if the query result is intended for this
-- focus army.
function ProcessQueryResults( results )
    for k,v in results do
        for index,listener in ResultListeners do
            if listener.Name == v.Name then
                listener.Callback(v)
            end
        end
        if v.ToCommandSource == SessionGetLocalCommandSource() then
            local id = v.InResponseTo
            local callback = PendingQueries[id]
            if callback then
                PendingQueries[id] = nil
                callback(v)
            end
        end
    end
end

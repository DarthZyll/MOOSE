--- **Tasking** - The TASK_CARGO models tasks for players to transport @{Cargo}.
-- 
-- ![Banner Image]()
-- 
-- 
-- 
-- ====
--
-- # **API CHANGE HISTORY**
--
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
--
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
--
-- Hereby the change log:
--
-- 2017-03-09: Revised version.
--
-- ===
--
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
--   * **[WingThor]**: Concept, Advice & Testing.
--        
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--   
-- @module Task_A2G

do -- TASK_CARGO

  --- @type TASK_CARGO
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  ---
  -- # TASK_CARGO class, extends @{Task#TASK}
  -- 
  -- The TASK_CARGO class defines @{Cargo} transport tasks, 
  -- based on the tasking capabilities defined in @{Task#TASK}.
  -- The TASK_CARGO is implemented using a @{Statemachine#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process.
  --   * **Planned**: The cargo task is planned.
  --   * **Assigned**: The cargo task is assigned to a @{Group#GROUP}.
  --   * **Success**: The cargo task is successfully completed.
  --   * **Failed**: The cargo task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- # 1.1) Set the scoring of achievements in a cargo task.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO TASK_CARGO
  --   
  TASK_CARGO = {
    ClassName = "TASK_CARGO",
  }
  
  --- Instantiates a new TASK_CARGO.
  -- @param #TASK_CARGO self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param AI.AI_Cargo#AI_CARGO Cargo The cargo.
  -- @param #string TaskType The type of Cargo task.
  -- @return #TASK_CARGO self
  function TASK_CARGO:New( Mission, SetGroup, TaskName, Cargo, TaskType )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType ) ) -- Tasking.Task#TASK_CARGO
    self:F()
  
    self.Cargo = Cargo
    self.TaskType = TaskType

    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "RouteToCargo", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned", "RouteToCargo", "RoutingToCargo" )
    Fsm:AddProcess   ( "RoutingToCargo", "RouteToCargoPickup", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtCargo" } )
    
    Fsm:AddTransition( { "Arrived", "RoutingToCargo" }, "ArriveAtCargo", "ArrivedAtCargo" )
    
    Fsm:AddTransition( { "ArrivedAtCargo", "LandAtCargo" }, "Land", "Landing" )
    Fsm:AddTransition( "Landing", "Landed", "Landed" )
    Fsm:AddTransition( "OnGround", "PrepareBoarding", "AwaitBoarding" )
    Fsm:AddTransition( "AwaitBoarding", "Board", "Boarding" )
    Fsm:AddTransition( "Boarding", "Boarded", "Boarded" )
    
    Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
    Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    
    
    --- Route to Cargo
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_CARGO#TASK_CARGO Task
    function Fsm:onafterRouteToCargo( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      
      Task:SetCargoPickup( Task.Cargo, TaskUnit )
      self:__RouteToCargoPickup( 0.1 )
    end

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_CARGO#TASK_CARGO Task
    function Fsm:OnAfterArriveAtCargo( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self:__Land( 0.1 )      
    end
    
    return self
 
  end
  
  --- @param #TASK_CARGO self
  function TASK_CARGO:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_CARGO self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The cargo.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetCargoPickup( Cargo, TaskUnit  )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )
  
    local ActRouteCargo = ProcessUnit:GetProcess( "RoutingToCargo", "RouteToCargoPickup" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteCargo:SetPointVec2( Cargo:GetPointVec2() )
    ActRouteCargo:SetRange( Cargo:GetBoardingRange() )
    return self
  end
  
  --- @param #TASK_CARGO self
  -- @param Core.Point#POINT_VEC2 TargetPointVec2 The PointVec2 object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_CARGO:SetTargetPointVec2( TargetPointVec2, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteTarget:SetPointVec2( TargetPointVec2 )
  end
   

  --- @param #TASK_CARGO self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Point#POINT_VEC2 The PointVec2 object where the Target is located on the map.
  function TASK_CARGO:GetTargetPointVec2( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteTarget:GetPointVec2()
  end


  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_CARGO:SetTargetZone( TargetZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteTarget:SetZone( TargetZone )
  end
   

  --- @param #TASK_CARGO self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_CARGO:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the target has been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnDestroy( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when all targets hav been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the A2G attack has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetPenaltyOnFailed( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end

  
end 


do -- TASK_CARGO_TRANSPORT

  --- The TASK_CARGO_TRANSPORT class
  -- @type TASK_CARGO_TRANSPORT
  -- @extends #TASK_CARGO
  TASK_CARGO_TRANSPORT = {
    ClassName = "TASK_CARGO_TRANSPORT",
  }
  
  --- Instantiates a new TASK_CARGO_TRANSPORT.
  -- @param #TASK_CARGO_TRANSPORT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param AI_Cargo#AI_CARGO Cargo The cargo.
  -- @return #TASK_CARGO_TRANSPORT self
  function TASK_CARGO_TRANSPORT:New( Mission, SetGroup, TaskName, Cargo )
    local self = BASE:Inherit( self, TASK_CARGO:New( Mission, SetGroup, TaskName, Cargo, "TRANSPORT" ) ) -- #TASK_CARGO_TRANSPORT
    self:F()
    
    return self
  end 

end


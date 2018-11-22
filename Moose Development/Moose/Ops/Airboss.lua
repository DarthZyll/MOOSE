--- **Functional** - (R2.5) - Manages aircraft operations on carriers.
-- 
-- The AIRBOSS class manages recoveries of human pilots and AI aircraft on aircraft carriers.
--
-- Features:
--
--    * CASE I, II and III recoveries.
--    * Supports human pilots as well as AI flight groups.
--    * Automatic LSO grading.
--    * Different skill levels from tipps on-the-fly for students to complete ziplip for pros.
--    * Rescue helo option.
--    * Recovery tanker option.
--    * Voice overs for LSO and AIRBOSS calls. Can easily be customized by users.
--    * Automatic TACAN and ICLS channel setting.
--    * Different radio channels for LSO and airboss calls.
--    * F10 radio menu including carrier info (weather, radio frequencies, TACAN/ICLS channels, LSO grades).
--    * Multiple carriers supported (due to object oriented approach).
--
-- **PLEASE NOTE** that his class is work in progress and in an **alpha** stage and very much work in progress.
-- 
-- At the moment training parameters are optimized for F/A-18C Hornet as aircraft and USS John C. Stennis as carrier.
-- Other aircraft and carriers **might** be possible in future but would need a different set of optimized parameters.
--
-- ===
--
-- ### Author: **funkyfranky**
-- ### Co-author: **Bankler** (Carrier trainer idea and script)
--
-- @module Ops.Airboss
-- @image MOOSE.JPG

--- AIRBOSS class.
-- @type AIRBOSS
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field Wrapper.Unit#UNIT carrier Aircraft carrier unit on which we want to practice.
-- @field #string carriertype Type name of aircraft carrier.
-- @field #AIRBOSS.CarrierParameters carrierparam Carrier specifc parameters.
-- @field #string alias Alias of the carrier.
-- @field Wrapper.Airbase#AIRBASE airbase Carrier airbase object.
-- @field Core.Radio#BEACON beacon Carrier beacon for TACAN and ICLS.
-- @field #number TACANchannel TACAN channel.
-- @field #string TACANmode TACAN mode, i.e. "X" or "Y".
-- @field #number ICLSchannel ICLS channel.
-- @field Core.Radio#RADIO LSOradio Radio for LSO calls.
-- @field Core.Radio#RADIO Carrierradio Radio for carrier calls.
-- @field #AIRBOSS.RadioCalls radiocall LSO and Airboss call sound files and texts.
-- @field Core.Zone#ZONE_UNIT zoneCCA Carrier controlled area (CCA), i.e. a zone of 50 NM radius around the carrier.
-- @field Core.Zone#ZONE_UNIT zoneCCZ Carrier controlled zone (CCZ), i.e. a zone of 5 NM radius around the carrier.
-- @field Core.Zone#ZONE_UNIT zoneInitial Zone usually 3 NM astern of carrier where pilots start their CASE I pattern.
-- @field #table players Table of players. 
-- @field #table menuadded Table of units where the F10 radio menu was added.
-- @field #AIRBOSS.Checkpoint Upwind Upwind checkpoint.
-- @field #AIRBOSS.Checkpoint BreakEarly Early break checkpoint.
-- @field #AIRBOSS.Checkpoint BreakLate Late brak checkpoint.
-- @field #AIRBOSS.Checkpoint Abeam Abeam checkpoint.
-- @field #AIRBOSS.Checkpoint Ninety At the ninety checkpoint.
-- @field #AIRBOSS.Checkpoint Wake Right behind the carrier.
-- @field #AIRBOSS.Checkpoint Groove In the groove checkpoint.
-- @field #AIRBOSS.Checkpoint Trap Landing checkpoint.
-- @field #AIRBOSS.Checkpoint Descent4k Case II/III descent at 4000 ft/min right after leaving holding pattern.
-- @field #AIRBOSS.Checkpoint Platform Case II/III descent at 2000 ft/min at 5000 ft platform.
-- @field #AIRBOSS.Checkpoint DirtyUp Case II/III dirty up and on speed position at 1200 ft and 10-12 NM from the carrier.
-- @field #AIRBOSS.Checkpoint Bullseye Case III intercept glideslope and follow ICLS aka "bullseye".
-- @field #number case Recovery case I, II or III in progress.
-- @field #table flights List of all flights in the CCA.
-- @field #table Qmarshal Queue of marshalling aircraft groups.
-- @field #table Qpattern Queue of aircraft groups in the landing pattern.
-- @field Ops.RescueHelo#RESCUEHELO rescuehelo Rescue helo flying in close formation with the carrier.
-- @field Ops.RecoveryTanker#RECOVERYTANKER tanker Recovery tanker flying overhead of carrier.
-- @field Functional.Warehouse#WAREHOUSE warehouse Warehouse object of the carrier.
-- @field #table recoverytime List of time intervals when aircraft are recovered.
-- @extends Core.Fsm#FSM

--- The boss!
--
-- ===
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Main.jpg)
--
-- # The AIRBOSS Concept
--
-- On an aircraft carrier, the AIRBOSS is guy who is in charge!
-- 
-- # Recovery Cases
-- 
-- The AIRBOSS class supports all three commonly used recovery cases, i.e.
--     * CASE I, which is for daytime and good weather
--     * CASE II, for daytime but poor visibility conditions and
--     * CASE III for nighttime recoveries.
--     
-- ## CASE I
-- 
-- When CASE I recovery is active, 
--
-- @field #AIRBOSS
AIRBOSS = {
  ClassName    = "AIRBOSS",
  lid          = nil,
  Debug        = true,
  carrier      = nil,
  carriertype  = nil,
  carrierparam =  {},
  alias        = nil,
  airbase      = nil,
  beacon       = nil,
  TACANchannel = nil,
  TACANmode    = nil,
  ICLSchannel  = nil,
  LSOradio     = nil,
  LSOfreq      = nil,
  Carrierradio = nil,
  Carrierfreq  = nil,
  radiocall    =  {},
  zoneCCA      = nil,
  zoneCCZ      = nil,
  zoneInitial  = nil,
  players      =  {},
  menuadded    =  {},
  Upwind       =  {},
  Abeam        =  {},
  BreakEarly   =  {},
  BreakLate    =  {},
  Ninety       =  {},
  Wake         =  {},
  Groove       =  {},
  Trap         =  {},
  Descent4k    =  {},
  Platform     =  {},
  DirtyUp      =  {},
  Bullseye     =  {},
  case         =   1,
  flights      =  {},
  Qpattern     =  {},
  Qmarshal     =  {},
  Nmaxpattern  = nil,
  rescuehelo   = nil,
  tanker       = nil,
  warehouse    = nil,
  recoverytime =  {},
}

--- Player aircraft types capable of landing on carriers.
-- @type AIRBOSS.AircraftPlayer
-- @field #string AV8B AV-8B Night Harrier.
-- @field #string HORNET F/A-18C Lot 20 Hornet.
-- @field #string A4EC Community A-4E-C mod.
AIRBOSS.AircraftPlayer={
  AV8B="AV8BNA",
  HORNET="FA-18C_hornet",
  A4EC="A-4E-C",
}

--- Aircraft types capable of landing on carrier (human+AI).
-- @type AIRBOSS.AircraftCarrier
-- @field #string AV8B AV-8B Night Harrier.
-- @field #string HORNET F/A-18C Lot 20 Hornet.
-- @field #string A4EC Community A-4E-C mod.
-- @field #string S3B Lockheed S-3B Viking.
-- @field #string S3BTANKER Lockheed S-3B Viking tanker.
-- @field #string E2D Grumman E-2D Hawkeye AWACS.
-- @field #string FA18C F/A-18C Hornet (AI).
-- @field #string F14A F-14A (AI).
AIRBOSS.AircraftCarrier={
  AV8B="AV8BNA",
  HORNET="FA-18C_hornet",
  A4EC="A-4E-C",
  S3B="S-3B",
  S3BTANKER="S-3B Tanker",
  E2D="E-2C",
  FA18C="F/A-18C",
  F14A="F-14A",
}

--- Carrier types.
-- @type AIRBOSS.CarrierType
-- @field #string STENNIS USS John C. Stennis (CVN-74)
-- @field #string VINSON USS Carl Vinson (CVN-70)
-- @field #string TARAWA USS Tarawa (LHA-1)
-- @field #string KUZNETSOV Admiral Kuznetsov (CV 1143.5)
AIRBOSS.CarrierType={
  STENNIS="Stennis",
  VINSON="Vinson",
  TARAWA="LHA_Tarawa",
  KUZNETSOV="KUZNECOW",
}

--- Carrier Parameters.
-- @type AIRBOSS.CarrierParameters
-- @field #number rwyangle Runway angle in degrees. for carriers with angled deck. For USS Stennis -9 degrees.
-- @field #number sterndist Distance in meters from carrier position to stern of carrier. For USS Stennis -150 meters.
-- @field #number deckheight Height of deck in meters. For USS Stennis ~22 meters.
-- @field #number wire1 Distance in meters from carrier position to first wire.
-- @field #number wire2 Distance in meters from carrier position to second wire.
-- @field #number wire3 Distance in meters from carrier position to third wire.
-- @field #number wire4 Distance in meters from carrier position to fourth wire.

--- Aircraft Parameters.
-- @type AIRBOSS.AircraftParameters
-- @field #number AoA Onspeed Angle of Attack.
-- @field #number Dboat Ideal distance to the carrier.


--- Pattern steps.
-- @type AIRBOSS.PatternStep
AIRBOSS.PatternStep={
  UNDEFINED="Undefined",
  COMMENCING="Commencing",
  HOLDING="Holding",
  DESCENT4K="Descent 4000 ft/min",
  PLATFORM="Platform",
  DIRTYUP="Level out and Dirty Up",
  BULLSEYE="Follow Bullseye",
  INITIAL="Initial",
  UPWIND="Upwind",
  EARLYBREAK="Early Break",
  LATEBREAK="Late Break",
  ABEAM="Abeam",
  NINETY="Ninety",
  WAKE="Wake",
  FINAL="On Final",
  GROOVE_XX="Groove X",
  GROOVE_RB="Groove Roger Ball",
  GROOVE_IM="Groove In the Middle",
  GROOVE_IC="Groove In Close",
  GROOVE_AR="Groove At the Ramp",
  GROOVE_IW="Groove In the Wires",
  DEBRIEF="Debrief",
}

--- Radio sound file and subtitle.
-- @type AIRBOSS.RadioSound
-- @field #string normal Sound file normal.
-- @field #string louder Sound file loud.
-- @field #string subtitle Subtitle displayed during transmission.
-- @field #number duration Duration in seconds the subtitle is displayed.

--- LSO and Airboss radio calls.
-- @type AIRBOSS.RadioCalls
-- @field #AIRBOSS.RadioSound RIGHTFORLINEUP "Right for line up!" call.
-- @field #AIRBOSS.RadioSound COMELEFT "Come left!" call.
-- @field #AIRBOSS.RadioSound HIGH "You're high!" call.
-- @field #AIRBOSS.RadioSound POWER Sound file "Power!" call.
-- @field #AIRBOSS.RadioSound SLOW Sound file "You're slow!" call.
-- @field #AIRBOSS.RadioSound FAST Sound file "You're fast!" call.
-- @field #AIRBOSS.RadioSound CALLTHEBALL Sound file "Call the ball." call.
-- @field #AIRBOSS.RadioSound ROGERBALL "Roger, ball." call.
-- @field #AIRBOSS.RadioSound WAVEOFF "Wave off!" call.
-- @field #AIRBOSS.RadioSound BOLTER "Bolter, bolter!" call.
-- @field #AIRBOSS.RadioSound LONGINGROOVE "You're long in the groove. Depart and re-enter." call.

--- Default radio call sound files.
-- @type AIRBOSS.Soundfile
-- @field #AIRBOSS.RadioSound RIGHTFORLINEUP
-- @field #AIRBOSS.RadioSound COMELEFT
-- @field #AIRBOSS.RadioSound HIGH
-- @field #AIRBOSS.RadioSound POWER
-- @field #AIRBOSS.RadioSound CALLTHEBALL
-- @field #AIRBOSS.RadioSound ROGERBALL
-- @field #AIRBOSS.RadioSound WAVEOFF
-- @field #AIRBOSS.RadioSound BOLTER
-- @field #AIRBOSS.RadioSound LONGINGROOVE
AIRBOSS.Soundfile={
  RIGHTFORLINEUP={
    normal="LSO - RightLineUp(S).ogg",
    louder="LSO - RightLineUp(L).ogg",
    subtitle="Right for line up.",
    duration=3,
  },
  COMELEFT={
    normal="LSO - ComeLeft(S).ogg",
    louder="LSO - ComeLeft(L).ogg",
    subtitle="Come left.",
    duration=3,
  },
  HIGH={
    normal="LSO - High(S).ogg",
    louder="LSO - High(L).ogg",
    subtitle="You're high.",
    duration=3,
  },
  POWER={
    normal="LSO - Power(S).ogg",
    louder="LSO - Power(L).ogg",
    subtitle="Power.",
    duration=3,
  },
  SLOW={
    normal="LSO-Slow-Normal.ogg",
    louder="LSO-Slow-Loud.ogg",
    subtitle="You're slow.",
    duration=3,
  },
  FAST={
    normal="LSO-Fast-Normal.ogg",
    louder="LSO-Fast-Loud.ogg",
    subtitle="You're fast.",
    duration=3,
  },
  CALLTHEBALL={
    normal="LSO - Call the Ball.ogg",
    louder="LSO - Call the Ball.ogg",
    subtitle="Call the ball.",
    duration=3,
  },
  ROGERBALL={
    normal="LSO - Roger.ogg",
    subtitle="Roger ball!",
    duration=3,
  },  
  WAVEOFF={
    normal="LSO - WaveOff.ogg",
    subtitle="Wave off!",
    duration=3,
  },  
  BOLTER={
    normal="LSO - Bolter.ogg",
    subtitle="Bolter, Bolter!",
    duration=3,
  },
  LONGINGROOVE={
    normal="LSO - Long in Groove.ogg",
    subtitle="You're long in the groove. Depart and re-enter.",
    duration=3,
  }
}


--- Difficulty level.
-- @type AIRBOSS.Difficulty
-- @field #string EASY Easy difficulty: error margin 10 for high score and 20 for low score. No score for deviation >20.
-- @field #string NORMAL Normal difficulty: error margin 5 deviation from ideal for high score and 10 for low score. No score for deviation >10.
-- @field #string HARD Hard difficulty: error margin 2.5 deviation from ideal value for high score and 5 for low score. No score for deviation >5.
AIRBOSS.Difficulty={
  EASY="Flight Student",
  NORMAL="Naval Aviator",
  HARD="TOPGUN Graduate",
}

--- Recovery time.
-- @type AIRBOSS.Recovery
-- @field #number START Start of recovery.
-- @field #number STOP End of recovery.

--- Groove position.
-- @type AIRBOSS.GroovePos
-- @field #string X0 Entering the groove.
-- @field #string XX At the start, i.e. 3/4 from the run down.
-- @field #string RB Roger ball.
-- @field #string IM In the middle.
-- @field #string IC In close.
-- @field #string AR At the ramp.
-- @field #string IW In the wires.
AIRBOSS.GroovePos={
  X0="X0",
  XX="X",
  RB="RB",
  IM="IM",
  IC="IC",
  AR="AR",
  IW="IW",
}

--- Groove data.
-- @type AIRBOSS.GrooveData
-- @field #number Step Current step.
-- @field #number AoA Angle of Attack.
-- @field #number Alt Altitude in meters.
-- @field #number GSE Glide slope error in degrees.
-- @field #number LUE Lineup error in degrees.
-- @field #number Roll Roll angle.

--- LSO grade
-- @type AIRBOSS.LSOgrade
-- @field #string grade LSO grade, i.e. _OK_, OK, (OK), --, CUT
-- @field #number points Points received.
-- @field #string details Detailed flight analyis analysis.

--- Checkpoint parameters triggering the next step in the pattern.
-- @type AIRBOSS.Checkpoint
-- @field #string name Name of checkpoint.
-- @field #number Xmin Minimum allowed longitual distance to carrier.
-- @field #number Xmax Maximum allowed longitual distance to carrier.
-- @field #number Zmin Minimum allowed latitudal distance to carrier.
-- @field #number Zmax Maximum allowed latitudal distance to carrier.
-- @field #number Rmin Minimum allowed range to carrier.
-- @field #number Rmax Maximum allowed range to carrier.
-- @field #number Amin Minimum allowed angle to carrier.
-- @field #number Amax Maximum allowed angle to carrier.
-- @field #number LimitXmin Latitudal threshold for triggering the next step if X<Xmin.
-- @field #number LimitXmax Latitudal threshold for triggering the next step if X>Xmax.
-- @field #number LimitZmin Latitudal threshold for triggering the next step if Z<Zmin.
-- @field #number LimitZmax Latitudal threshold for triggering the next step if Z>Zmax.
-- @field #number Altitude Optimal altitude at this point.
-- @field #number AoA Optimal AoA at this point.
-- @field #number Distance Optimal distance at this point.
-- @field #number Speed Optimal speed at this point.
-- @field #table Checklist Table of checklist text items to display at this point.

--- Player data table holding all important parameters of each player.
-- @type AIRBOSS.PlayerData
-- @field Wrapper.Unit#UNIT unit Aircraft of the player.
-- @field #string name Player name. 
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field Wrapper.Group#GROUP group Aircraft group the player is in.
-- @field #string callsign Callsign of player.
-- @field #string actype Aircraft type.
-- @field #string onboard Onboard number.
-- @field #string difficulty Difficulty level.
-- @field #string step Coming pattern step.
-- @field #number passes Number of passes.
-- @field #boolean attitudemonitor If true, display aircraft attitude and other parameters constantly.
-- @field #table debrief Debrief analysis of the current step of this pass.
-- @field #table grades LSO grades of player passes.
-- @field #boolean holding If true, player is in holding zone.
-- @field #boolean landed If true, player landed or attempted to land.
-- @field #boolean bolter If true, LSO told player to bolter.
-- @field #boolean boltered If true, player boltered.
-- @field #boolean waveoff If true, player was waved off during final approach.
-- @field #boolean patternwo If true, player was waved of during the pattern.
-- @field #boolean lig If true, player was long in the groove.
-- @field #number Tlso Last time the LSO gave an advice.
-- @field #AIRBOSS.GroovePos groove Data table at each position in the groove. Elemets are of type @{#AIRBOSS.GrooveData}.
-- @field #string seclead Name of section lead.
-- @field #table menu F10 radio menu

--- Parameters of a flight group.
-- @type AIRBOSS.Flightitem
-- @field Wrapper.Group#GROUP group Flight group.
-- @field #string groupname Name of the group.
-- @field #number nunits Number of units in group.
-- @field #number dist0 Distance to carrier in meters when the group was first detected inside the CCA.
-- @field #number time Time the flight was added to the queue.
-- @field Core.UserFlag#USERFLAG flag User flag for triggering events for the flight.
-- @field #boolean ai If true, flight is AI. If false, flight is a human player.
-- @field #AIRBOSS.PlayerData player Player data for human pilots.
-- @field #string actype Aircraft type name.
-- @field #table onboardnumbers Onboard numbers of aircraft in the group.
-- @field #number case Recovery case of flight.
-- @field #table section Other human flight groups belonging to this flight. This flight is the lead.

--- Main radio menu.
-- @field #table MenuF10
AIRBOSS.MenuF10={}

--- Airboss class version.
-- @field #string version
AIRBOSS.version="0.3.2w"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Set case II and III times. 
-- TODO: Add radio transmission queue for LSO and airboss.
-- TODO: Get correct wire when trapped.
-- TODO: Add radio check (LSO, AIRBOSS) to F10 radio menu.
-- TODO: Right pattern step after bolter/wo/patternWO?
-- TODO: Handle crash event. Delete A/C from queue, send rescue helo, stop carrier?
-- TODO: Get fuel state in pounds.
-- TODO: Add user functions.
-- TODO: Generalize parameters for other carriers.
-- TODO: Generalize parameters for other aircraft.
-- TODO: CASE II.
-- TODO: CASE III.
-- TODO: Foul deck check.
-- TODO: Persistence of results.
-- TODO: Strike group with helo bringing cargo etc.
-- DONE: Add aircraft numbers in queue to carrier info F10 radio output.
-- DONE: Monitor holding of players/AI in zoneHolding.
-- DONE: Transmission via radio.
-- DONE: Get board numbers.
-- DONE: Get an _OK_ pass if long in groove. Possible other pattern wave offs as well?!
-- DONE: Add scoring to radio menu.
-- DONE: Optimized debrief.
-- DONE: Add automatic grading.
-- DONE: Fix radio menu.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRBOSS class object for a specific aircraft carrier unit.
-- @param #AIRBOSS self
-- @param carriername Name of the aircraft carrier unit as defined in the mission editor.
-- @param alias (Optional) Alias for the carrier. This will be used for radio messages and the F10 radius menu. Default is the carrier name as defined in the mission editor.
-- @return #AIRBOSS self or nil if carrier unit does not exist.
function AIRBOSS:New(carriername, alias)

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #AIRBOSS
  
  -- Debug.
  self:F2({carriername=carriername, alias=alias})

  -- Set carrier unit.
  self.carrier=UNIT:FindByName(carriername)
  
  -- Check if carrier unit exists.
  if self.carrier==nil then
    -- Error message.
    local text=string.format("ERROR: Carrier unit %s could not be found! Make sure this UNIT is defined in the mission editor and check the spelling of the unit name carefully.", carriername)
    MESSAGE:New(text, 120):ToAll()
    self:E(text)
    return nil
  end
      
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRBOSS %s | ", carriername)
  
  -- Get carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Set alias.
  self.alias=alias or carriername
  
  -- Set carrier airbase object.
  self.airbase=AIRBASE:FindByName(carriername)
  
  -- Create carrier beacon.
  self.beacon=BEACON:New(self.carrier)
  
  -- Set up Airboss radio.  
  self.Carrierradio=RADIO:New(self.carrier)
  self.Carrierradio:SetAlias("AIRBOSS")
  self:SetCarrierradio()
  
  -- Set up LSO radio.  
  self.LSOradio=RADIO:New(self.carrier)
  self.LSOradio:SetAlias("LSO")
  self:SetLSOradio()
  
  -- Init carrier parameters.
  if self.carriertype==AIRBOSS.CarrierType.STENNIS then
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.VINSON then
    -- TODO: Carl Vinson parameters.
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.TARAWA then
    -- TODO: Tarawa parameters.
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.KUZNETSOV then
    -- TODO: Kusnetsov parameters - maybe...
    self:_InitStennis()
  else
    self:E(self.lid.."ERROR: Unknown carrier type!")
    return nil
  end
  
  -- Zone 3 NM astern and 100 m starboard of the carrier with radius of 0.5 km.
  self.zoneInitial=ZONE_UNIT:New("Initial Zone", self.carrier, 0.5*1000, {dx=-UTILS.NMToMeters(3), dy=100, relative_to_unit=true})
  
  -- CCA 50 NM radius zone around the carrier.
  self:SetCarrierControlledArea()
  
  -- CCZ 5 NM radius zone around the carrier.
  self:SetCarrierControlledZone()
  
  -- Default recovery case.
  self:SetRecoveryCase(1)
  
  -- Init default sound files.
  for _name,_sound in pairs(AIRBOSS.Soundfile) do
    local sound=_sound --#AIRBOSS.RadioSound
    self.radiocall[_name]=sound
  end
  
  -- Debug:
  self:T(self.lid.."Default sound files:")
  for _name,_sound in pairs(self.radiocall) do
    self:T{name=_name,sound=_sound}
  end
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Idle")        -- Start AIRBOSS script.
  self:AddTransition("*",             "Idle",       "Idle")        -- Carrier is idleing.
  self:AddTransition("Idle",          "Recover",    "Recovering")  -- Recover aircraft.
  self:AddTransition("*",             "Status",     "*")           -- Update status of players and queues.
  self:AddTransition("*",             "Stop",       "Stopped")     -- Stop AIRBOSS script.


  --- Triggers the FSM event "Start" that starts the airboss. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] Start
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Start" that starts the airboss after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] __Start
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Idle" so no operations are carried out.
  -- @function [parent=#AIRBOSS] Idle
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Idle" after a delay.
  -- @function [parent=#AIRBOSS] __Idle
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Recover" that starts the recovering of aircraft. Marshalling aircraft are send to the landing pattern.
  -- @function [parent=#AIRBOSS] Recover
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Recover" that starts the recovering of aircraft after a delay. Marshalling aircraft are send to the landing pattern.
  -- @function [parent=#AIRBOSS] __Recover
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop" that stops the airboss. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] Stop
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Stop" that stops the airboss after a delay. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] __Stop
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- USER API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set carrier controlled area (CCA).
-- This is a large zone around the carrier, which is constantly updated wrt the carrier position.
-- @param #AIRBOSS self
-- @param #number radius Radius of zone in nautical miles (NM). Default 50 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierControlledArea(radius)

  radius=UTILS.NMToMeters(radius or 50)

  self.zoneCCA=ZONE_UNIT:New("Carrier Controlled Area",  self.carrier, radius)

  return self
end

--- Set carrier controlled zone (CCZ).
-- This is a small zone (usually 5 NM radius) around the carrier, which is constantly updated wrt the carrier position.
-- @param #AIRBOSS self
-- @param #number radius Radius of zone in nautical miles (NM). Default 5 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierControlledZone(radius)

  radius=UTILS.NMToMeters(radius or 5)

  self.zoneCCZ=ZONE_UNIT:New("Carrier Controlled Zone",  self.carrier, radius)

  return self
end

--- Set recovery case pattern.
-- @param #AIRBOSS self
-- @param #number case Case of recovery. Either 1 or 3. Default 1.
-- @return #AIRBOSS self
function AIRBOSS:SetRecoveryCase(case)

  self.case=case or 1

  return self
end

--- Add recovery time slot.
-- @param #AIRBOSS self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock.
-- @return #AIRBOSS self
function AIRBOSS:AddRecoveryTime(starttime, stoptime)

  local Tstart=UTILS.ClockToSeconds(starttime)
  local Tstop=UTILS.ClockToSeconds(stoptime)
  
  local rtime={} --#AIRBOSS.Recovery
  rtime.START=Tstart
  rtime.STOP=Tstop
  
  table.insert(self.recoverytime, rtime)
  return self
end


--- Set TACAN channel of carrier.
-- @param #AIRBOSS self
-- @param #number channel TACAN channel. Default 74.
-- @param #string mode TACAN mode, i.e. "X" or "Y". Default "X".
-- @return #AIRBOSS self
function AIRBOSS:SetTACAN(channel, mode)

  self.TACANchannel=channel or 74
  self.TACANmode=mode or "X"

  return self
end

--- Set ICLS channel of carrier.
-- @param #AIRBOSS self
-- @param #number channel ICLS channel. Default 1.
-- @return #AIRBOSS self
function AIRBOSS:SetICLS(channel)

  self.ICLSchannel=channel or 1

  return self
end


--- Set LSO radio frequency and modulation. Default frequency is 264 MHz AM.
-- @param #AIRBOSS self
-- @param #number frequency Frequency in MHz. Default 264 MHz.
-- @param #string modulation Modulation, i.e. "AM" (default) or "FM". 
-- @return #AIRBOSS self
function AIRBOSS:SetLSOradio(frequency, modulation)

  self.LSOfreq=frequency or 264
  self.LSOmodulation=modulation or "AM"
  
  if modulation=="FM" then
    self.LSOmodulation=radio.modulation.FM
  else
    self.LSOmodulation=radio.modulation.AM
  end
  
  self.LSOradio:SetFrequency(self.LSOfreq)
  self.LSOradio:SetModulation(self.LSOmodulation)

  return self
end

--- Set carrier radio frequency and modulation. Default frequency is 305 MHz AM.
-- @param #AIRBOSS self
-- @param #number frequency Frequency in MHz. Default 305 MHz.
-- @param #string modulation Modulation, i.e. "AM" (default) or "FM".
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierradio(frequency, modulation)

  self.Carrierfreq=frequency or 305
  self.Carrriermodulation=modulation or "AM"
  
  if modulation=="FM" then
    self.Carriermodulation=radio.modulation.FM
  else
    self.Carriermodulation=radio.modulation.AM
  end
  
  self.Carrierradio:SetFrequency(self.Carrierfreq)
  self.Carrierradio:SetModulation(self.Carriermodulation)

  return self
end


--- Define rescue helicopter associated with the carrier.
-- @param #AIRBOSS self
-- @param Ops.RescueHelo#RESCUEHELO rescuehelo Rescue helo object.
-- @return #ARIBOSS self
function AIRBOSS:SetRescueHelo(rescuehelo)
  self.rescuehelo=rescuehelo
  return self
end

--- Define recovery tanker associated with the carrier.
-- @param #AIRBOSS self
-- @param Ops.RecoveryTanker#RECOVERYTANKER recoverytanker Recovery tanker object.
-- @return #ARIBOSS self
function AIRBOSS:SetRecoveryTanker(recoverytanker)
  self.tanker=recoverytanker
  return self
end


--- Define warehouse associated with the carrier.
-- @param #AIRBOSS self
-- @param Functional.Warehouse#WAREHOUSE warehouse Warehouse object of the carrier.
-- @return #ARIBOSS self
function AIRBOSS:SetWarehouse(warehouse)
  self.warehouse=warehouse
  return self
end


--- Check if carrier is recovering aircraft.
-- @param #AIRBOSS self
-- @return #boolean If true, time slot for recovery is open.
function AIRBOSS:IsRecovering()
  return self:is("Recovering")
end

--- Check if carrier is idle, i.e. no operations are carried out.
-- @param #AIRBOSS self
-- @return #boolean If true, carrier is in idle state. 
function AIRBOSS:IsIdle()
  return self:is("Idle")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStart(From, Event, To)

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting AIRBOSS v%s for carrier unit %s of type %s.", AIRBOSS.version, self.carrier:GetName(), self.carriertype))
  
  local theatre=env.mission.theatre
  
  self:I(self.lid..string.format("Theatre = %s", tostring(theatre)))
  
  -- Activate TACAN.
  if self.TACANchannel~=nil and self.TACANmode~=nil then
    self.beacon:ActivateTACAN(self.TACANchannel, self.TACANmode, "STN", true)
  end
  
  -- Activate ICLS.
  if self.ICLSchannel then
    self.beacon:ActivateICLS(self.ICLSchannel, "STN")
  end
    
  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.Crash)
  --self:HandleEvent(EVENTS.Ejection)
  
  -- Time stamp for checking queues. 
  self.Tqueue=timer.getTime()

  -- Init status check
  self:__Status(1)
end

--- On after Status event. Checks player status.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStatus(From, Event, To)

  -- Get current time.
  local time=timer.getTime()
  
  -- Check if we go into recovery mode.
  local recovery=self:_CheckRecoveryTimes()
  if recovery==true then
    self:Recover()
  elseif recovery==false then
    self:Idle()
  end
  
  -- Update marshal and pattern queue every 30 seconds.
  if time-self.Tqueue>30 then

    local text=string.format("Status %s.", self:GetState())
    self:I(self.lid..text)
  
    -- Scan carrier zone for new aircraft.
    self:_ScanCarrierZone()
    
    -- Check marshal and pattern queues.
    self:_CheckQueue()
    
    -- Time stamp.
    self.Tqueue=time
  end
  
  -- Check player status.
  self:_CheckPlayerStatus()

  -- Call status every 0.5 seconds.
  -- TODO: make dt user input.
  self:__Status(-0.5)
end

--- Check if recovery times.
-- @param #AIRBOSS self
-- @return #boolean IF true, start recovery.
function AIRBOSS:_CheckRecoveryTimes()

  -- Get current abs time.
  local abstime=timer.getAbsTime()
  
  if #self.recoverytime==0 then
  
    -- If no recovery times have been specified, we assume any time is okay.
    self:I("FF Start recovery. No recovery time set!")
    if not self:IsRecovering() then
      -- Give command to recover!
      return true
    else
      -- Do nothing.
      return nil
    end
        
  else
  
    local recovery=false
    local remove={}
    
    for i,_rtime in pairs(self.recoverytime) do
      local rtime=_rtime --#AIRBOSS.Recovery
      
      if abstime>=rtime.START and abstime<=rtime.STOP then

        -- This is a valid time slot. Do not touch recovery again!
        recovery=true      
        
      elseif abstime>rtime.STOP then
        -- Stop time has already passed.
        table.insert(remove, i)
      elseif abstime<rtime.START then
        -- This recovery time is in the future.
      end
                
    end

    --TODO: Remove past recovery times from list?

    if recovery then
      -- We are inside a recovery time window.
      if self:IsRecovering() then
        -- Do nothing, i.e. keep recovering.
        recovery=nil
      elseif self:IsIdle() then
        self:I(self.lid.."Starting recovery.")
        recovery=true
      end
    else
      -- At this point, there is not recovery set.
      if self:IsRecovering() then
        -- Stop recovery and switch to idle.
        self:I(self.lid.."Stopping recovery.")
        recovery=false
      elseif self:IsIdle() then
        -- Nothing to do.
        recovery=nil
      end
    end
   
    return recovery
  end

end

--- On before "Recover" event.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, recovery transition is allowed.
function AIRBOSS:onbeforeRecover(From, Event, To)
  return true
end


--- On after Stop event. Unhandle events and stop status updates. 
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.Crash)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parameter initialization
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Init parameters for USS Stennis carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.rwyangle   =  -9
  self.carrierparam.sterndist  =-150
  self.carrierparam.deckheight =  22
  self.carrierparam.wire1      =-104
  self.carrierparam.wire2      = -92
  self.carrierparam.wire3      = -80
  self.carrierparam.wire4      = -68
  
  --[[
  q0=self.carrier:GetCoordinate():SetAltitude(25)
  q0:BigSmokeSmall(0.1)
  q1=self.carrier:GetCoordinate():Translate(-104,0):SetAltitude(22)  --1st wire
  q1:BigSmokeSmall(0.1)--:SmokeGreen()
  q2=self.carrier:GetCoordinate():Translate(-68,0):SetAltitude(22)   --4th wire ==> distance between wires 12 m
  q2:BigSmokeSmall(0.1)--:SmokeBlue()
  ]]

  -- 4k descent from holding pattern to 5k platform.
  self.Descent4k.name="Descent 4k"
  self.Descent4k.Xmin=-UTILS.NMToMeters(50)  -- Not more than 50 NM behind the boat.
  self.Descent4k.Xmax=-UTILS.NMToMeters(20)  -- Not more than 20 NM closer to the boat from behind.
  self.Descent4k.Zmin=-UTILS.NMToMeters(15)  -- Not more than 15 NM port/left of boat.
  self.Descent4k.Zmax= UTILS.NMToMeters(5)   -- Not more than  5 NM starboard/right of boat.
  self.Descent4k.LimitXmin=nil
  --TODO: better rho dist. decrease descent 20 2000 ft/min at 5000 ft alt and user rad alt.
  self.Descent4k.LimitXmax=-UTILS.NMToMeters(21) -- Check and next step when 21 NM behind the boat.
  self.Descent4k.LimitZmin=nil
  self.Descent4k.LimitZmax=nil

  -- Platform at 5k. Reduce descent rate to 2000 ft/min to 1200 dirty up level flight.
  self.Platform.name="Platform 5k"
  self.Platform.Xmin=-UTILS.NMToMeters(22)  -- Not more than 22 NM behind the boat. Last check was at 21 NM.
  self.Platform.Xmax =nil
  self.Platform.Zmin=-UTILS.NMToMeters(30)  -- Not more than 30 NM port of boat.
  self.Platform.Zmax= UTILS.NMToMeters(30)  -- Not more than 30 NM starboard of boat.
  self.Platform.LimitXmin=nil
  --TODO: better rho dist! now switch to dirty up level flight 12 NM.
  self.Platform.LimitXmax=-UTILS.NMToMeters(20) -- Check and next step when 20 NM behind the boat.
  self.Platform.LimitZmin=nil
  self.Platform.LimitZmax=nil 
  
  -- Level out at 1200 ft and dirty up.
  self.DirtyUp.name="Dirty Up"
  self.DirtyUp.Xmin=-UTILS.NMToMeters(21)        -- Not more than 21 NM behind the boat.
  self.DirtyUp.Xmax= nil
  self.DirtyUp.Zmin=-UTILS.NMToMeters(30)        -- Not more than 30 NM port of boat.
  self.DirtyUp.Zmax= UTILS.NMToMeters(30)        -- Not more than 30 NM starboard of boat.
  self.DirtyUp.LimitXmin=nil
  --TODO: better rho dist! Intercept glideslope and follow bullseye.
  self.DirtyUp.LimitXmax=-UTILS.NMToMeters(10)   -- Check and next step at 10 NM behind the boat.
  self.DirtyUp.LimitZmin=nil
  self.DirtyUp.LimitZmax=nil 
  
  -- Intercept glide slope and follow bullseye.
  self.Bullseye.name="Bullseye"
  self.Bullseye.Xmin=-UTILS.NMToMeters(11)       -- Not more than 11 NM behind the boat. Last check was at 10 NM.
  self.Bullseye.Xmax= nil
  self.Bullseye.Zmin=-UTILS.NMToMeters(30)       -- Not more than 30 NM port.
  self.Bullseye.Zmax= UTILS.NMToMeters(30)       -- Not more than 30 NM starboard.
  self.Bullseye.LimitXmin=nil
  --TODO: better rho dist! Call the ball.
  self.Bullseye.LimitXmax=-UTILS.NMToMeters(3)   -- Check and next step 3 NM behind the boat.
  self.Bullseye.LimitZmin=nil
  self.Bullseye.LimitZmax=nil
 
  -- Upwind leg or break entry.
  self.Upwind.name="Upwind"
  self.Upwind.Xmin=-UTILS.NMToMeters(4)          -- Not more than 4 NM behind the boat. Check for initial is at 3 NM with a radius of ?.
  self.Upwind.Xmax= nil
  self.Upwind.Zmin=-100                          -- Not more than 100 meters port of boat.
  self.Upwind.Zmax= UTILS.NMToMeters(1)          -- Not more than 1 NM starboard of boat.
  self.Upwind.LimitXmin=0                        -- Check and next step when at carrier and starboard of carrier.
  self.Upwind.LimitXmax=nil
  self.Upwind.LimitZmin=0
  self.Upwind.LimitZmax=nil

  -- Early break.
  self.BreakEarly.name="Early Break"
  self.BreakEarly.Xmin=-UTILS.NMToMeters(1)         -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakEarly.Xmax= UTILS.NMToMeters(5)         -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakEarly.Zmin=-UTILS.NMToMeters(2)         -- Not more than 2 NM port.
  self.BreakEarly.Zmax= UTILS.NMToMeters(1)         -- Not more than 1 NM starboard.
  self.BreakEarly.LimitXmin= 0                      -- Check and next step 0.2 NM port and in front of boat.
  self.BreakEarly.LimitXmax= nil
  self.BreakEarly.LimitZmin=-UTILS.NMToMeters(0.2)  -- -370 m port
  self.BreakEarly.LimitZmax= nil
  
  -- Late break
  self.BreakLate.name="Late Break"
  self.BreakLate.Xmin=-UTILS.NMToMeters(1)         -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax= UTILS.NMToMeters(5)         -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin=-UTILS.NMToMeters(2)         -- Not more than 2 NM port.
  self.BreakLate.Zmax= UTILS.NMToMeters(1)         -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin= 0                      -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax= nil
  self.BreakLate.LimitZmin=-UTILS.NMToMeters(0.8)  -- -1470 m port
  self.BreakLate.LimitZmax= nil
  
  -- Abeam position
  self.Abeam.name="Abeam Position"
  self.Abeam.Xmin= nil
  self.Abeam.Xmax= nil
  self.Abeam.Zmin=-UTILS.NMToMeters(3)            -- Not more than 3 NM port.
  self.Abeam.Zmax= 0                              -- Must be port!
  self.Abeam.LimitXmin=-200                       -- Check and next step 200 meters behind the ship.
  self.Abeam.LimitXmax= nil
  self.Abeam.LimitZmin= nil
  self.Abeam.LimitZmax= nil

  -- At the ninety
  self.Ninety.name="Ninety"
  self.Ninety.Xmin=-UTILS.NMToMeters(4)           -- Not more than 4 NM behind the boat. LIG check anyway.
  self.Ninety.Xmax= 0                             -- Must be behind the boat.
  self.Ninety.Zmin=-UTILS.NMToMeters(2)           -- Not more than 2 NM port of boat.
  self.Ninety.Zmax= nil
  self.Ninety.LimitXmin=nil
  self.Ninety.LimitXmax=nil
  self.Ninety.LimitZmin=nil
  self.Ninety.LimitZmax=-UTILS.NMToMeters(0.6)    -- Check and next step when 0.6 NM port. 

  -- Wake position
  self.Wake.name="Wake"
  self.Wake.Xmin=-UTILS.NMToMeters(4)           -- Not more than 4 NM behind the boat.
  self.Wake.Xmax= 0                             -- Must be behind the boat.
  self.Wake.Zmin=-2000                          -- Not more than 2 km port of boat.
  self.Wake.Zmax= nil
  self.Wake.LimitXmin=nil
  self.Wake.LimitXmax=nil
  self.Wake.LimitZmin=0                         -- Check and next step when directly behind the boat.
  self.Wake.LimitZmax=nil

  -- In the groove
  self.Groove.name="Groove"
  self.Groove.Xmin=-UTILS.NMToMeters(4)           -- Not more than 4 NM behind the boat.
  self.Groove.Xmax= 0                             -- Must be behind the boat.
  self.Groove.Zmin=-1000                          -- Not more than 1 km port.
  self.Groove.Zmax= nil
  self.Groove.LimitXmin=nil                       -- No limits. Check is carried out differently.
  self.Groove.LimitXmax=nil
  self.Groove.LimitZmin=nil
  self.Groove.LimitZmax=nil
  
  -- Landing trap
  self.Trap.name="Trap"
  self.Trap.Xmin=-UTILS.NMToMeters(4)           -- Not more than 4 NM behind the boat.
  self.Trap.Xmax= nil
  self.Trap.Zmin=-UTILS.NMToMeters(2)           -- Not more than 2 NM port
  self.Trap.Zmax= UTILS.NMToMeters(2)           -- Not more than 2 NM starboard.
  self.Trap.LimitXmin=nil                       -- No limits. Check is carried out differently.
  self.Trap.LimitXmax=nil
  self.Trap.LimitZmin=nil
  self.Trap.LimitZmax=nil

end

--- Get optimal aircraft flight parameters at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #string step Pattern step.
-- @return #number Altitude in meters or nil.
-- @return #number Angle of Attack or nil.
-- @return #number Distance to carrier in meters or nil.
-- @return #number Speed in m/s or nil.
function AIRBOSS:_GetAircraftParameters(playerData, step)

  step=step or playerData.step
  local hornet=playerData.actype==AIRBOSS.AircraftCarrier.HORNET
  local skyhawk=playerData.actype==AIRBOSS.AircraftCarrier.A4EC
  
  local alt
  local aoa
  local dist  
  local speed
  
  if step==AIRBOSS.PatternStep.DESCENT4K then
  
    speed=UTILS.KnotsToMps(250)
  
  elseif step==AIRBOSS.PatternStep.PLATFORM then
  
   alt=UTILS.FeetToMeters(5000)
   
   dist=UTILS.NMToMeters(20)
   
   speed=UTILS.KnotsToMps(250)
  
  elseif step==AIRBOSS.PatternStep.DIRTYUP then
  
    alt=UTILS.FeetToMeters(1200)
    
    dist=UTILS.NMToMeters(12)
    
    speed=UTILS.KnotsToMps(250)
  
  elseif step==AIRBOSS.PatternStep.BULLSEYE then

    alt=UTILS.FeetToMeters(1200)
    
    dist=-UTILS.NMToMeters(3)  
  
  elseif step==AIRBOSS.PatternStep.INITIAL then

    if hornet then     
      alt=UTILS.FeetToMeters(800)
      speed=UTILS.KnotsToMps(350)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(600)
      speed=UTILS.KnotsToMps(250)
    end
    
  elseif step==AIRBOSS.PatternStep.UPWIND then

    if hornet then     
      alt=UTILS.FeetToMeters(800)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(600)  
    end  
  
  elseif step==AIRBOSS.PatternStep.EARLYBREAK then

    if hornet then     
      alt=UTILS.FeetToMeters(800)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(600)  
    end  
    
  elseif step==AIRBOSS.PatternStep.LATEBREAK then

    if hornet then     
      alt=UTILS.FeetToMeters(800)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(600)  
    end  
    
  elseif step==AIRBOSS.PatternStep.ABEAM then
  
    if hornet then     
      alt=UTILS.FeetToMeters(600)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(500)  
    end
    
    aoa=8.1
    
    dist=UTILS.NMToMeters(1.2)
    
  elseif step==AIRBOSS.PatternStep.NINETY then

    if hornet then     
      alt=UTILS.FeetToMeters(500)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(500)  
    end
    
    aoa=8.1  
  
  elseif step==AIRBOSS.PatternStep.WAKE then
  
    if hornet then     
      alt=UTILS.FeetToMeters(370)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(370) --?
    end
    
    aoa=8.1
    
  elseif step==AIRBOSS.PatternStep.FINAL then

    if hornet then     
      alt=UTILS.FeetToMeters(300)
    elseif skyhawk then
      alt=UTILS.FeetToMeters(300) --?  
    end
    
    aoa=8.1
  
  end

  return alt, aoa, dist, speed
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- QUEUE Functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check marshal and pattern queues.
-- @param #AIRBOSS self
function AIRBOSS:_CheckQueue()
  
  -- Print queues.
  self:_PrintQueue(self.flights,  "All Flights")
  self:_PrintQueue(self.Qmarshal, "Marshal")
  self:_PrintQueue(self.Qpattern, "Pattern")
  
  -- Get number of aircraft units(!) currently in pattern.
  local _,npattern=self:_GetQueueInfo(self.Qpattern)
  
  -- Get number of flight groups(!) in marshal pattern.
  local nmarshal=#self.Qmarshal
  
  -- Check if there are flights in marshal strack and if the pattern is free.
  if nmarshal>0 and npattern<1 then
  
    -- Next flight in line to be send from marshal to pattern.
    local marshalflight=self.Qmarshal[1]  --#AIRBOSS.Flightitem
    
    -- Time flight is marshaling.
    local Tmarshal=timer.getAbsTime()-marshalflight.time
    self:I(self.lid..string.format("Marshal time of group %s = %d seconds", marshalflight.groupname, Tmarshal))
    
    -- Time (last) flight has entered landing pattern.
    local Tpattern=9999
    local npunits=1
    if npattern>0 then
    
      -- Last flight group send to pattern.
      local patternflight=self.Qpattern[#self.Qpattern] --#AIRBOSS.Flightitem
      
      -- Number of aircraft in this group.
      local npunits=patternflight.nunits
      
      -- Get time in pattern.
      Tpattern=timer.getAbsTime()-patternflight.time
      self:I(self.lid..string.format("Pattern time of group %s = %d seconds. # of units=%d.", patternflight.groupname, Tpattern, npunits))
    end
    
    -- Min time in pattern before next aircraft is allowed.
    local TpatternMin
    if self.case==1 then
      TpatternMin=45*npunits   --  45 seconds interval per plane!
    else
      TpatternMin=120*npunits  -- 120 seconds interval per plane!
    end
    
    -- Min time in marshal before send to landing pattern.
    local TmarshalMin=120
    
    -- Two minutes in pattern at least and >45 sec interval between pattern flights.
    if self:IsRecovering() and Tmarshal>TmarshalMin and Tpattern>TpatternMin then
      self:_CheckCollapseMarshalStack(marshalflight)
    end
    
  end
end

--- Print holding queue.
-- @param #AIRBOSS self
-- @param #table queue Queue to print.
-- @param #string name Queue name.
function AIRBOSS:_PrintQueue(queue, name)

  local text=string.format("%s Queue:", name)
  if #queue==0 then
    text=text.." empty."
  else
    for i,_flight in pairs(queue) do
      local flight=_flight --#AIRBOSS.Flightitem
      local clock=UTILS.SecondsToClock(flight.time)
      local stack=flight.flag:Get()
      local alt=UTILS.MetersToFeet(self:_GetMarshalAltitude(stack))
      local fuel=flight.group:GetFuelMin()*100
      local case=flight.case
      local ai=tostring(flight.ai)
      text=text..string.format("\n[%d] %s*%d: stackalt=%d ft, flag=%d, case=%d, time=%s, fuel=%d, ai=%s",
                                 i, flight.groupname, flight.nunits, alt, stack, case, clock, fuel, ai)
    end
  end
  self:I(self.lid..text)
end

--- Scan carrier zone for (new) units.
-- @param #AIRBOSS self
function AIRBOSS:_ScanCarrierZone()
  self:T(self.lid.."Scanning Carrier Zone")

  -- Carrier position.
  local coord=self:GetCoordinate()
  
  local Rout=UTILS.NMToMeters(50)
  
  -- Scan units in carrier zone.
  local _,_,_,unitscan=coord:ScanObjects(Rout, true, false, false)

  
  -- Make a table with all groups currently in the CCA zone.
  local insideCCA={}  
  for _,_unit in pairs(unitscan) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Necessary conditions to be met:
    local airborn=unit:IsAir() and unit:InAir()
    local inzone=unit:IsInZone(self.zoneCCA)
    local friendly=self:GetCoalition()==unit:GetCoalition()
    local carrierac=self:_IsCarrierAircraft(unit)
    
    -- Check if this an aircraft and that it is airborn and closing in.
    if airborn and inzone and friendly and carrierac then
    
      local group=unit:GetGroup()
      local groupname=group:GetName()
      
      if insideCCA[groupname]==nil then
        insideCCA[groupname]=group
      end
      
    end
  end

  
  -- Find new flights that are inside CCA.
  for groupname,_group in pairs(insideCCA) do
    local group=_group --Wrapper.Group#GROUP
    
    -- Get flight group if possible.
    local knownflight=self:_GetFlightFromGroupInQueue(group, self.flights)
    
    -- Get aircraft type name.
    local actype=group:GetTypeName()
    
    -- Create a new flight group
    if knownflight then
      self:I(string.format("Known CCA flight group %s of type %s", groupname, actype))
      if knownflight.ai then
      
        -- Get distance to carrier.
        local dist=knownflight.group:GetCoordinate():Get2DDistance(self:GetCoordinate())
        
        -- Send AI flight to marshal stack if group closes in more than 5 km and has initial flag value.
        if knownflight.dist0-dist>5000 and knownflight.flag:Get()==-100 then
          self:_MarshalAI(knownflight)
        end
      end
    else
      self:I(string.format("UNKNOWN CCA flight group %s of type %s", groupname, actype))
      self:_CreateFlightGroup(group)
    end
      
  end

  
  -- Find flights that are not in CCA.
  local remove={}
  for _,_flight in pairs(self.flights) do
    local flight=_flight --#AIRBOSS.Flightitem
    if insideCCA[flight.groupname]==nil then
      table.insert(remove, flight.group)
    end
  end
  
  -- Remove flight groups. 
  for _,group in pairs(remove) do
    self:_RemoveFlightGroup(group)
  end
  
end

--- Get onboard number of player or client.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #string Onboard number as string.
function AIRBOSS:_GetOnboardNumberPlayer(group)
  return self:_GetOnboardNumbers(group, true)
end

--- Get onboard numbers of all units in a group.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @param #boolean playeronly If true, return the onboard number for player or client skill units.
-- @return #table Table of onboard numbers.
function AIRBOSS:_GetOnboardNumbers(group, playeronly)
  --self:F({groupname=group:GetName})
  
  -- Get group name.
  local groupname=group:GetName()
  
  -- Debug text.
  local text=string.format("Onboard numbers of group %s:", groupname)
  
  -- Units of template group.
  local units=group:GetTemplate().units
  
  -- Get numbers.
  local numbers={}
  for _,unit in pairs(units) do
  
    -- Onboard number and unit name.
    local n=tostring(unit.onboard_num)
    local name=unit.name
    local skill=unit.skill

    -- Debug text.
    text=text..string.format("\n- unit %s: onboard #=%s  skill=%s", name, n, skill)

    if playeronly and skill=="Client" or skill=="Player" then
      -- There can be only one player in the group. so we skill everything else
      return n
    end
    
    -- Table entry.
    numbers[name]=n    
  end
  
  -- Debug info.
  self:I(self.lid..text)
  
  return numbers
end

--- Create a new flight group. Usually when a flight appears in the CCA.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #AIRBOSS.Flightitem Flight group.
function AIRBOSS:_CreateFlightGroup(group)

  -- Flight group name
  local groupname=group:GetName()
  local human=self:_IsHuman(group)
  
  -- Queue table item.
  local flight={} --#AIRBOSS.Flightitem
  flight.group=group
  flight.groupname=group:GetName()
  flight.nunits=#group:GetUnits()
  flight.time=timer.getAbsTime()
  flight.dist0=group:GetCoordinate():Get2DDistance(self:GetCoordinate())
  flight.flag=USERFLAG:New(groupname)
  flight.flag:Set(-100)
  flight.ai=not human
  flight.actype=group:GetTypeName()
  flight.onboardnumbers=self:_GetOnboardNumbers(group)
  flight.section={}
  flight.case=self.case
  
  if human then
    
    -- Attach player data to flight.
    local playerData=self:_GetPlayerDataGroup(group)
    flight.player=playerData
    
    -- Message to player.
    MESSAGE:New(string.format("%s, your flight is registered within CCA.", playerData.name), 10, "MARSHAL"):ToClient(playerData.client)
    
  else
    -- Nothing to do for AI.
  end
  
  -- Add to known flights inside CCA zone.
  table.insert(self.flights, flight)

  return flight
end

--- Remove a flight group.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #AIRBOSS.Flightitem Flight group.
function AIRBOSS:_RemoveFlightGroup(group)
  local groupname=group:GetName()
  for i,_flight in pairs(self.flights) do
    local flight=_flight --#AIRBOSS.Flightitem
    if flight.groupname==groupname then
      self:I(string.format("Removing flight group %s (not in CCA).", groupname))
      table.remove(self.flights, i)
      return
    end
  end
end

--- Orbit at a specified position at a specified alititude with a specified speed.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #AIRBOSS.Flightitem flight Flight group.
function AIRBOSS:_MarshalPlayer(playerData, flight)
  
  -- Check if flight is known to the airboss already.
  if playerData and flight then
  
    -- Number of flight groups in stack.
    local ngroups,nunits=self:_GetQueueInfo(self.Qmarshal, self.case)
    
    -- Assign next free stack to this flight.
    local mystack=ngroups+1
    
    -- Add group to marshal stack.
    self:_AddMarshallGroup(flight, mystack)
    
    -- Set step to holding.
    playerData.step=AIRBOSS.PatternStep.HOLDING
    
    -- Set same stack for all flights in section.
    for _,_flight in pairs(flight.section) do
      local flight=_flight --#AIRBOSS.Flightitem
      flight.player.step=AIRBOSS.PatternStep.HOLDING
      flight.flag:Set(mystack)
    end
    
  else
  
    -- Flight is not registered yet.
    local text="you are not yet registered inside the CCA. Marshal request denied!"
    self:MessageToPlayer(playerData, text, "AIRBOSS")
  end  
  
end

--- Tell AI to orbit at a specified position at a specified alititude with a specified speed.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Flightitem flight Flight group.
function AIRBOSS:_MarshalAI(flight)

  -- Flight group name.
  local group=flight.group
  local groupname=flight.groupname
  
  -- Check that we do not add a recovery tanker for marshaling.
  -- TODO: Fix group name.
  if self.tanker and self.tanker.tanker:GetName()==groupname then    
    return
  end

  -- Number of already full marshal stacks.
  local nstacks=#self.Qmarshal
  
  -- Current carrier position.
  local Carrier=self:GetCoordinate()
    
  -- Aircraft speed when flying the pattern.
  local Speed=UTILS.KnotsToMps(272)
  
  --- Create a DCS task to orbit at a certain altitude.
  local function _taskorbit(p1, alt, speed, stopflag, p2)
    local DCSTask={}
    DCSTask.id="ControlledTask"
    DCSTask.params={}
    DCSTask.params.task=group:TaskOrbit(p1, alt, speed, p2)        
    DCSTask.params.stopCondition={userFlag=groupname, userFlagValue=stopflag}
    return DCSTask
  end

  -- Waypoints array.
  local wp={}
  
  -- Set up waypoints including collapsing the stack.
  local n=1  -- Waypoint counter.
  for stack=nstacks+1,1,-1 do
  
    -- Get altitude and positions.  
    local Altitude, p1, p2=self:_GetMarshalAltitude(stack)
    
    local p1=p1 --Core.Point#COORDINATE
    local Dist=p1:Get2DDistance(self:GetCoordinate())
    
    -- Orbit task.
    local TaskOrbit=_taskorbit(p1, Altitude, Speed, stack-1, p2)
     
    -- Waypoint description.    
    local text=string.format("Marshal @ alt=%d ft, dist=%.1f NM, speed=%d knots", UTILS.MetersToFeet(Altitude), UTILS.MetersToNM(Dist), UTILS.MpsToKnots(Speed))
    
    -- Waypoint.
    wp[n]=p1:SetAltitude(Altitude):WaypointAirTurningPoint(nil, Speed, {TaskOrbit}, text)
    
    -- Increase counter.
    n=n+1
  end  
  
  -- Landing waypoint.
  wp[#wp+1]=Carrier:WaypointAirLanding(Speed, self.airbase, nil, "Landing")
    
  -- Add group to marshal stack.
  self:_AddMarshallGroup(flight, nstacks+1)
  
  -- Reinit waypoints.
  group:WayPointInitialize(wp)
  
  -- Route group.
  group:Route(wp, 0)
end

--- Get marshal altitude and position.
-- @param #AIRBOSS self
-- @param #number stack Assigned stack number. Counting starts at one, i.e. stack=1 is the first stack.
-- @param #number case Recovery case. Default is self.case.
-- @return #number Holding altitude in meters.
-- @return Core.Point#COORDINATE Holding position coordinate.
-- @return Core.Point#COORDINATE Second holding position coordinate of racetrack pattern for CASE II/III recoveries.
function AIRBOSS:_GetMarshalAltitude(stack, case)

  -- Stack <= 0.
  if stack<=0 then
    return 0,nil,nil
  end
  
  -- Recovery case.
  case=case or self.case

  -- Carrier position.
  local Carrier=self:GetCoordinate()
  local hdg=self.carrier:GetHeading()

  -- Altitude of first stack. Depends on recovery case.
  local angels0
  local Dist
  local p1=nil  --Core.Point#COORDINATE
  local p2=nil  --Core.Point#COORDINATE
  
  if case==1 then
    -- CASE I: Holding at 2000 ft on a circular pattern port of the carrier. Interval +1000 ft for next stack.
    angels0=2
    Dist=UTILS.NMToMeters(2.5)
    p1=Carrier:Translate(Dist, hdg-70)
  else
    -- CASE II/III: Holding at 6000 ft on a racetrack pattern astern the carrier.
    angels0=6
    Dist=UTILS.NMToMeters((stack-1)*angels0+15)
    p1=Carrier:Translate(-Dist, hdg)
    p2=Carrier:Translate(-(Dist+UTILS.NMToMeters(10)), hdg)
  end

  -- Pattern altitude.
  local altitude=UTILS.FeetToMeters(((stack-1)+angels0)*1000)
  
  return altitude, p1, p2
end

--- Get next free stack.
-- @param #AIRBOSS self
-- @param #number case Recovery case
-- @return #number Smalest (lowest) free stack.
function AIRBOSS:_GetFreeStack(case)
  
  case=case or self.case
  
  local stack
  if case==1 then
    stack=self:_GetQueueInfo(self.Qmarshal, 1)
  else
    stack=self:_GetQueueInfo(self.Qmarshal, 23)
  end
  
  return stack+1
end


--- Get number of groups and units in queue.
-- @param #AIRBOSS self
-- @param #table queue The queue. Can me all, marshal or pattern.
-- @param #number case (Optional) Count only flights which are in a specific recovery case.
-- @return #number Total Number of flight groups in queue.
-- @return #number Total number of aircraft in queue.
function AIRBOSS:_GetQueueInfo(queue, case)

  local ngroup=0
  local nunits=0
  
  for _,_flight in pairs(queue) do
    local flight=_flight --#AIRBOSS.Flightitem
    
    if case then
    
      if flight.case==case or (case==23 and (flight.case==2 or flight.case==3)) then
        ngroup=ngroup+1
        nunits=nunits+flight.nunits          
      end
      
    else
      ngroup=ngroup+1
      nunits=nunits+flight.nunits    
    end
    
  end

  return nunits, ngroup
end

--- Add a flight group to the marshal stack.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Flightitem flight Flight group.
-- @param #number flagvalue Initial user flag value = stack number for holding.
function AIRBOSS:_AddMarshallGroup(flight, flagvalue)

  -- Set flag value. This corresponds to the stack number which starts at 1.
  flight.flag:Set(flagvalue)
  
  -- Set recovery case.
  flight.case=self.case
  
  -- Pressure.
  local P=UTILS.hPa2inHg(self:GetCoordinate():GetPressure())
  
  local unitname=flight.group:GetUnit(1):GetName()
  
  -- TODO: Get correct board number if possible?
  local boardnumber=tostring(flight.onboardnumbers[unitname])
  local alt=UTILS.MetersToFeet(self:_GetMarshalAltitude(flagvalue, flight.case))
  local brc=self:_BaseRecoveryCourse()
  
  -- Marshal message.
  -- TODO: Get charlie time estimate.
  local text=string.format("%s, Case %d, BRC is %03d, hold at %d. Expected Charlie Time XX.\n", boardnumber, flight.case, brc, alt)
  text=text..string.format("Altimeter %.2f. Report see me.", P)
  MESSAGE:New(text, 30):ToAll()
   
  -- Add to marshal queue.
  table.insert(self.Qmarshal, flight)
end

--- Check if marshal stack can be collapsed.
-- If next in line is an AI flight, this is done. If human player is next, we wait for "Commence" via F10 radio menu command.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Flightitem flight Flight to go to pattern.
function AIRBOSS:_CheckCollapseMarshalStack(flight)

  -- TODO: better message.
  local text=string.format("%s, you are cleared for Case %d recovery pattern!", flight.groupname, flight.case)

  -- Check if flight is AI or human. If AI, we collapse the stack and commence. If human, we suggest to commence.
  if flight.ai then
    -- Collapse stack and send AI to pattern.
    self:_CollapseMarshalStack(flight)
  else
    -- TODO only if skil is not TOPGUN
    text=text..string.format("\nUse F10 radio menu \"Commence!\" command when you are ready!")
  end
 
  -- TODO: Message to all players!
  MESSAGE:New(text, 15, "MARSHAL"):ToAll() 
end

--- Collapse marshal stack.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Flightitem patternflight Flight to go to pattern.
-- @param #boolean refuel If true, patternflight wants to refuel and not go into pattern.
function AIRBOSS:_CollapseMarshalStack(patternflight, refuel)
  self:I({flight=patternflight, refuel=refuel})

  -- Recovery case of flight.
  local case=patternflight.case
  local pstack=patternflight.flag:Get()

  -- Decrease flag values of all flight groups in marshal stack.
  for _,_flight in pairs(self.Qmarshal) do
    local flight=_flight --#AIRBOSS.Flightitem
    
    -- Only collaps stack of which the flight left. CASE II/III stack is the same.
    if (case==1 and flight.case==1) or (case>1 and flight.case>1) then
    
      -- Get current flag/stack value.
      local mstack=flight.flag:Get()
      
      -- Only collapse stacks above the new pattern flight.
      -- TODO: this will go wrong, if patternflight is not in marshal stack because it will have value -100 and all mstacks will be larger!
      -- Maybe need to set the initial value to 1000? Or check pstack>0?
      if pstack>0 and mstack>pstack then
      
        -- Decrease stack/flag by one ==> AI will go lower.
        flight.flag:Set(mstack-1)
        
        -- Inform players.
        if flight.player then
          local alt=UTILS.MetersToFeet(self:_GetMarshalAltitude(mstack-1,case))
          local text=string.format("descent to next lower stack at %d ft", alt)
          self:MessageToPlayer(flight.player, text, "MARSHAL", nil, 10)
        end
        
        -- Also decrease flag for section members of flight.
        for _,_sec in pairs(flight.section) do
          local sec=_sec --#AIRBOSS.Flightitem
          sec.flag:Set(mstack-1)
        end
        
      end
      
    end    
  end
  
  
  if refuel then
  
    -- Debug
    self:I(self.lid..string.format("Flight %s is going for gas.", patternflight.groupname))

    -- New time stamp for time in pattern.
    patternflight.time=timer.getAbsTime()

    -- Set flag to -1.
    patternflight.flag:Set(-1)
    
    -- TODO: Add to refueling queue.
  
  else

    -- Debug
    self:I(self.lid..string.format("Flight %s is going into pattern.", patternflight.groupname))
    
    -- New time stamp for time in pattern.
    patternflight.time=timer.getAbsTime()
    
    -- Decrease flag.
    patternflight.flag:Set(pstack-1)
    
    -- Add flight to pattern queue.
    table.insert(self.Qpattern, patternflight)
    
    -- Remove flight from marshal queue.
    self:_RemoveGroupFromQueue(self.Qmarshal, patternflight.group)
    
  end
end

--- Remove a group from a queue.
-- @param #AIRBOSS self
-- @param #table queue The queue from which the group will be removed.
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
function AIRBOSS:_RemoveGroupFromQueue(queue, group)

  local name=group:GetName()
    
  for i,_flight in pairs(queue) do
    local flight=_flight --#AIRBOSS.Flightitem
    
    if flight.groupname==name then
      self:I(self.lid..string.format("Removing group %s from queue.", name))
      table.remove(queue, i)
      return
    end
  end
  
end

--- Get flight from group. 
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
-- @param #table queue The queue from which the group will be removed.
-- @return #AIRBOSS.Flightitem Flight group.
-- @return #number Queue index.
function AIRBOSS:_GetFlightFromGroupInQueue(group, queue)

  -- Group name
  local name=group:GetName()
  
  -- Loop over all flight groups in queue
  for i,_flight in pairs(queue) do
    local flight=_flight --#AIRBOSS.Flightitem
    
    if flight.groupname==name then
      return flight, i
    end
  end

  self:T2(self.lid..string.format("WARNING: Flight group %s could not be found in queue.", name))
  return nil, nil
end

--- Remove a group from a queue when all aircraft of that group have landed.
-- @param #AIRBOSS self
-- @param #table queue The queue from which the group will be removed.
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
function AIRBOSS:_RemoveQueue(queue, group)

  local name=group:GetName()
  
  for i,_flight in pairs(queue) do
    local flight=_flight --#AIRBOSS.Flightitem
    
    if flight.groupname==name then
    
      -- Decrease number of units in group.
      flight.nunits=flight.nunits-1
      
      if flight.nunits==0 then
        self:I(self.lid..string.format("FF removing group %s from queue.", name))
        table.remove(queue, i)
      end
      
    end
  end
  
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Status
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check current player status.
-- @param #AIRBOSS self
function AIRBOSS:_CheckPlayerStatus()

  -- Loop over all players.
  for _playerName,_playerData in pairs(self.players) do  
    local playerData=_playerData --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Player unit.
      local unit=playerData.unit
      
      -- Check if unit is alive and in air.
      if unit:IsAlive() then
      
        -- Display aircraft attitude and other parameters as message text.
        if playerData.attitudemonitor then
          self:_DetailedPlayerStatus(playerData)
        end

        -- Check if player is in carrier controlled area (zone with R=50 NM around the carrier).
        if unit:IsInZone(self.zoneCCA) then
                 
          if playerData.step==AIRBOSS.PatternStep.UNDEFINED then
            
            -- Status undefined.
            local time=timer.getAbsTime()
            local clock=UTILS.SecondsToClock(time)
            self:T3(string.format("Player status undefined. Waiting for next step. Time %s", clock))
            
            
            -- Jump to final/groove for testing.
            if self.groovedebug then     
              playerData.step=AIRBOSS.PatternStep.FINAL
              self.groovedebug=false
            end

          elseif playerData.step==AIRBOSS.PatternStep.HOLDING then
          
            -- CASE I/II/III: In holding pattern.
            self:_Holding(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.COMMENCING then
          
            -- CASE I/II/III: New approach.
            self:_Commencing(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.DESCENT4K then
          
            -- CASE II/III: Initial descent with 4000 ft/min.
            self:_Descent4k(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.PLATFORM then
          
            -- CASE II/III: Player has reached 5k "Platform".
            self:_Platform(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.DIRTYUP then
          
            -- CASE II/III: Player has descended to 1200 ft and is going level from now on.
            self:_DirtyUp(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.BULLSEYE then
          
            -- CASE III: Player has intercepted the glide slope and should follow "Bullseye" (ICLS).
            self:_Bullseye(playerData)
          
          elseif playerData.step==AIRBOSS.PatternStep.INITIAL then
          
            -- CASE I/II: Player is at the initial position entering the landing pattern.
            self:_Initial(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.UPWIND then
          
            -- CASE I/II: Upwind leg aka break entry.
            self:_Upwind(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.EARLYBREAK then
          
            -- CASE I/II: Early break.
            self:_Break(playerData, "early")
            
          elseif playerData.step==AIRBOSS.PatternStep.LATEBREAK then
          
            -- CASE I/II: Late break.
            self:_Break(playerData, "late")
            
          elseif playerData.step==AIRBOSS.PatternStep.ABEAM then
          
            -- CASE I/II: Abeam position.
            self:_Abeam(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.NINETY then
          
            -- CASE:I/II: Check long down wind leg.
            self:_CheckForLongDownwind(playerData)
            
            -- At the ninety.
            self:_Ninety(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.WAKE then
          
            -- CASE I/II: In the wake.
            self:_Wake(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.FINAL then
          
            -- CASE I/II: Turn to final and enter the groove.
            self:_Final(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.GROOVE_XX or
                 playerData.step==AIRBOSS.PatternStep.GROOVE_RB or
                 playerData.step==AIRBOSS.PatternStep.GROOVE_IM or
                 playerData.step==AIRBOSS.PatternStep.GROOVE_IC or
                 playerData.step==AIRBOSS.PatternStep.GROOVE_AR or
                 playerData.step==AIRBOSS.PatternStep.GROOVE_IW then
          
            -- CASE I/II: In the groove.
            self:_Groove(playerData)
            
          elseif playerData.step==AIRBOSS.PatternStep.DEBRIEF then
          
            -- Debriefing in 10 seconds.
            SCHEDULER:New(nil, self._Debrief, {self, playerData}, 10)
            
            -- Undefined status.
            playerData.step=AIRBOSS.PatternStep.UNDEFINED
            
          end
          
        else
          --playerData.inbigzone=false
          self:E(self.lid.."WARNING: Player left the CCA!")
        end
        
      else
        -- Unit not alive.
        self:E(self.lid.."WARNING: Player unit is not alive!")
      end
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Airboss event handler for event birth.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventBirth(EventData)
  self:F3({eventbirth = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."BIRTH: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("AIRBOSS: Pilot %s, callsign %s entered unit %s of group %s.", _playername, _callsign, _unitName, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    
    -- Check if aircraft type the player occupies is carrier capable.
    local rightaircraft=self:_IsCarrierAircraft(_unit)
    if rightaircraft==false then
      local text=string.format("Player aircraft type %s not supported by AIRBOSS class.", _unit:GetTypeName())
      --MESSAGE:New(text, 30, "ERROR", true):ToGroup(_group)
      self:E(self.lid..text)
      return
    end
        
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)
    
    -- Init player data.
    self.players[_playername]=self:_NewPlayer(_unitName)
    
    --env.info("FF radiocall LSO long in groove")
    --self:RadioTransmission(self.LSOradio, self.radiocall["LONGINGROOVE"], false, 5)
    --self:RadioTransmission(self.LSOradio, self.radiocall.LONGINGROOVE, false, 20)
    
    -- Start in the groove for debugging.
    self.groovedebug=false
    
  end 
end

--- Airboss event handler for event land.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventLand(EventData)
  self:F3({eventland = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."LAND: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."LAND: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."LAND: player = "..tostring(_playername))
      
  if _unit and _playername then
    -- Human Player landed.
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- This would be the closest airbase.
    local airbase=EventData.Place
    local airbasename=tostring(airbase:GetName())
    
    -- Check if player landed on the right airbase.
    if airbasename==self.airbase:GetName() then 
    
      -- Debug output.
      local text=string.format("Player %s, callsign %s unit %s (ID=%d) of group %s landed at airbase %s", _playername, _callsign, _unitName, _uid, _group:GetName(), airbasename)
      self:I(self.lid..text)
      MESSAGE:New(text, 5):ToAllIf(self.Debug)
      
      -- Player data.
      local playerData=self.players[_playername] --#AIRBOSS.PlayerData
      
      -- Coordinate at landing event
      local coord=playerData.unit:GetCoordinate()
      
      -- Debug mark of player landing coord.
      local lp=coord:MarkToAll("Landing coord.")
      coord:SmokeGreen()
      
      -- Landing distance to carrier position.
      local dist=coord:Get2DDistance(self:GetCoordinate())
      
      -- TODO: check if 360 degrees correctino is necessary!
      local hdg=self.carrier:GetHeading()+self.carrierparam.rwyangle
      
      -- Debug marks of wires.
      local w1=self:GetCoordinate():Translate(self.carrierparam.wire1, hdg):MarkToAll("Wire 1")
      local w2=self:GetCoordinate():Translate(self.carrierparam.wire2, hdg):MarkToAll("Wire 2")
      local w3=self:GetCoordinate():Translate(self.carrierparam.wire3, hdg):MarkToAll("Wire 3")
      local w4=self:GetCoordinate():Translate(self.carrierparam.wire4, hdg):MarkToAll("Wire 4")
      
      -- We did land.
      playerData.landed=true
      
      -- Unkonwn step.
      playerData.step=AIRBOSS.PatternStep.UNDEFINED

      -- Call trapped function in 3 seconds to make sure we did not bolter.
      SCHEDULER:New(nil, self._Trapped,{self, playerData, dist}, 3)
        
    end
    
  else
    -- AI unit landed.
    
    -- Coordinate at landing event
    local coord=EventData.IniUnit:GetCoordinate()
    
    -- Debug mark of player landing coord.
    local dist=coord:Get2DDistance(self:GetCoordinate())
    
    local text=string.format("AI landing dist=%.1f m", dist)
    env.info(text)

    local lp=coord:MarkToAll(text)
    coord:SmokeGreen()

    -- AI: Decrease number of units in flight and remove group from pattern queue if all units landed.
    if self:_InQueue(self.Qpattern, EventData.IniGroup) then
      self:_RemoveQueue(self.Qpattern, EventData.IniGroup)
    end
 
  end
    
end

--- Airboss event handler for event crash.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventCrash(EventData)
  self:F3({eventland = EventData})

  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:I(self.lid.."CRASH: unit   = "..tostring(EventData.IniUnitName))
  self:I(self.lid.."CRASH: group  = "..tostring(EventData.IniGroupName))
  self:I(self.lid.."CARSH: player = "..tostring(_playername))
  
  -- TODO: Update queues!
  -- TODO: Decrease number of units in group!
  if _unit and _playername then
    self:I(self.lid..string.format("Player %s crashed!",_playername))
  else
    self:I(self.lid..string.format("AI unit %s crashed!", EventData.IniUnitName)) 
  end
end



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PATTERN functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize player data after birth event of player unit.
-- @param #AIRBOSS self
-- @param #string unitname Name of the player unit.
-- @return #AIRBOSS.PlayerData Player data.
function AIRBOSS:_NewPlayer(unitname)

  -- Get player unit and name.
  local playerunit, playername=self:_GetPlayerUnitAndName(unitname)
  
  if playerunit and playername then

    -- Player data.
    local playerData={} --#AIRBOSS.PlayerData
    
    -- Player unit, client and callsign.
    playerData.unit     = playerunit
    playerData.name     = playername
    playerData.group    = playerunit:GetGroup()
    playerData.callsign = playerData.unit:GetCallsign()
    playerData.client   = CLIENT:FindByName(unitname, nil, true)
    playerData.actype   = playerunit:GetTypeName()
    playerData.onboard  = self:_GetOnboardNumberPlayer(playerData.group)
    playerData.seclead  = playername
        
    -- Number of passes done by player.
    playerData.passes=playerData.passes or 0
      
    -- LSO grades.
    playerData.grades=playerData.grades or {}
    
    -- Attitude monitor.
    playerData.attitudemonitor=false
    
    -- Set difficulty level.
    playerData.difficulty=playerData.difficulty or AIRBOSS.Difficulty.NORMAL
  
    -- Init stuff for this round.
    playerData=self:_InitPlayer(playerData)
    
    -- Return player data table.
    return playerData    
  end
  
  return nil
end

--- Initialize player data by (re-)setting parmeters to initial values.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return #AIRBOSS.PlayerData Initialized player data.
function AIRBOSS:_InitPlayer(playerData)
  self:I(self.lid..string.format("New approach of player %s.", playerData.callsign))
  
  playerData.step=AIRBOSS.PatternStep.UNDEFINED
  
  playerData.groove={}
  playerData.debrief={}
  playerData.patternwo=false
  playerData.lig=false
  playerData.waveoff=false
  playerData.bolter=false
  playerData.boltered=false
  playerData.landed=false
  playerData.holding=nil
  playerData.Tlso=timer.getTime()
  
  return playerData
end

--- Holding.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Holding(playerData)

  -- Player unit and flight.
  local unit=playerData.unit
  local flight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)
  
  -- Current stack.
  local stack=flight.flag:Get()
  
  -- Pattern alitude.
  local patternalt, c1, c2=self:_GetMarshalAltitude(stack)
  
  -- Player altitude.
  local playeralt=unit:GetAltitude()
  
  -- Get holding zone of player.
  local zoneHolding=self:_GetHoldingZone(playerData)
    
  -- Check if player is in holding zone.
  local inholdingzone=unit:IsInZone(zoneHolding)
  
  -- Check player alt is +-500 feet of assigned pattern alt.
  local altdiff=playeralt-patternalt
  local goodalt=math.abs(altdiff)<UTILS.MetersToFeet(500)
  
  -- TODO: check if player is flying counter clockwise. AOB<0.

  local text=""
  
  -- Different cases
  if playerData.holding==true then
    -- Player was in holding zone last time we checked.
    
    if inholdingzone then
      -- Player is still in holding zone.
      self:I("Player is still in the holding zone. Good job.")
    else
      -- Player left the holding zone.
      self:I("Player just left the holding zone. Come back!")
      text=text..string.format("You just left the holding zone. Watch your numbers!")
      playerData.holding=false
    end
    
  elseif playerData.holding==false then
  
    -- Player left holding zone
    if inholdingzone then
      -- Player is back in the holding zone.
      self:I("Player is back in the holding zone after leaving it.")
      text=text..string.format("You are back in the holding zone. Now stay there!")
      playerData.holding=true
    else
      -- Player is still outside the holding zone.
      self:I("Player still outside the holding zone. What are you doing man?!")
    end
    
  elseif playerData.holding==nil then
    -- Player did not entered the holding zone yet.
    
    if inholdingzone then
      -- Player arrived in holding zone.
      playerData.holding=true
      self:I("Player entered the holding zone for the first time.")
      text=text..string.format("You arrived at the holding zone.")
      if goodalt then
        text=text..string.format(" Now stay at that altitude.")
      else
        if altdiff<0 then
          text=text..string.format(" But you are too low.")
        else
          text=text..string.format(" But you are too high.")
        end
        text=text..string.format(" Currently assigned altitude is %d ft.", UTILS.MetersToFeet(patternalt))
      end
    else
      -- Player did not yet arrive in holding zone.
      self:I("Waiting for player to arrive in the holding zone.")
    end
    
  end
  
  -- Send message.  
  self:MessageToPlayer(playerData, text, "AIRBOSS", nil, 5)
end

--- Get holding zone of player.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return Core.Zone#ZONE Holding zone.
function AIRBOSS:_GetHoldingZone(playerData)

  -- Player unit and flight.
  local unit=playerData.unit
  local flight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)

  -- Create a holding zone depending on recovery case.
  local zoneHolding=nil  --Core.Zone#ZONE
  
  if flight then
  
    -- Current stack.
    local stack=flight.flag:Get()
    
    -- Stack is <= 0 ==> no marshal zone. 
    if stack<=0 then
      return nil
    end
    
    -- Pattern alitude.
    local patternalt, c1, c2=self:_GetMarshalAltitude(stack)
    
    if self.case==1 then
      -- CASE I
      
      -- Zone 2.5 NM port of carrier with a radius of 3 NM (holding pattern should be < 5 NM). 
      zoneHolding=ZONE_UNIT:New("CASE I Holding Zone", self.carrier, UTILS.NMToMeters(3), {dx=0, dy=-UTILS.NMToMeters(2.5), relative_to_unit=true})
    
    else  
      -- CASE II/II
      
      -- TODO: Include 15 or 30 degrees offset.
      local hdg=self.carrier:GetHeading()
      
      -- Create an array of a square!
      local p={}
      p[1]=c1:Translate(UTILS.NMToMeters(1), hdg+90):GetVec2()  --c1 is at (angels+15) NM directly behind the carrier. We translate it 1 NM starboard.
      p[2]=c2:Translate(UTILS.NMToMeters(1), hdg+90):GetVec2()  --c2 is 10 NM further behind. Also translated 1 NM starboard.
      p[3]=c2:Translate(UTILS.NMToMeters(7), hdg-90):GetVec2()  --p3 6 NM port of carrier.
      p[4]=c1:Translate(UTILS.NMToMeters(7), hdg-90):GetVec2()  --p4 6 NM port of carrier.
      
      -- Square zone length=10NM width=6 NM behind the carrier starting at angels+15 NM behind the carrier.
      -- So stay 0-5 NM (+1 NM error margin) port of carrier.
      zoneHolding=ZONE_POLYGON_BASE:New("CASE II/III Holding Zone", p)
    end
  end
  
  return zoneHolding
end

--- Commence approach.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Commencing(playerData) 
  
  -- Initialize player data for new approach.
  self:_InitPlayer(playerData)
    
  -- Commence
  local text=string.format("Commencing. Case %d.", self.case)
  
  -- Message to player.
  self:_SendMessageToPlayer(text, 10, playerData)
  
  -- Next step: depends on case recovery.
  if self.case==1 then
    -- CASE I: Player has to fly to the initial which is 3 NM DME astern of the boat.
    playerData.step=AIRBOSS.PatternStep.INITIAL
  else
    -- CASE III: Player has to start the descent at 4000 ft/min.
    playerData.step=AIRBOSS.PatternStep.DESCENT4K
  end
end

--- Start pattern when player enters the initial zone.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Initial(playerData)

  -- Check if player is in initial zone and entering the CASE I pattern.
  if playerData.unit:IsInZone(self.zoneInitial) then
  
    -- Inform player.
    local hint=string.format("Entering the pattern.")
    if playerData.difficulty==AIRBOSS.Difficulty.EASY then
      hint=hint.."Aim for 800 feet and 350 kts at the break entry."
    end
    
    -- Send message.
    self:_SendMessageToPlayer(hint, 10, playerData)
  
    -- Next step: upwind.
    playerData.step=AIRBOSS.PatternStep.UPWIND
  end
  
end

--- Descent at 4k.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Descent4k(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.Descent4k) then
    self:_AbortPattern(playerData, X, Z, self.Descent4k)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(X, Z, self.Descent4k) then
  
    -- Get optimal altitude, distance and speed.
    local altitude=self:_GetAircraftParameters(playerData)
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Descent 4k", debrief)
    
    -- Next step: Platform at 5k
    playerData.step=AIRBOSS.PatternStep.PLATFORM
  end
end

--- Platform at 5k ft. Descent at 2000 ft/min.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Platform(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.Platform) then
    self:_AbortPattern(playerData, X, Z, self.Platform)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(X, Z, self.Platform) then
  
    -- Get optimal altitiude.
    local altitude=self:_GetAircraftParameters(playerData)
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Platform 5k", debrief)
    
    -- Next step: Dirty up and level out at 1200 ft.
    playerData.step=AIRBOSS.PatternStep.DIRTYUP
  end
end

--- Dirty up and level out at 1200 ft.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_DirtyUp(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.DirtyUp) then
    self:_AbortPattern(playerData, X, Z, self.DirtyUp)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(X, Z, self.DirtyUp) then
  
    -- Get optimal altitiude.
    local altitude=self:_GetAircraftParameters(playerData)
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Dirty Up", debrief)
    
    -- Next step:
    if self.case==2 then
      -- CASE II: Fly to the initial and perform CASE I pattern.
      playerData.step=AIRBOSS.PatternStep.INITIAL
    elseif self.case==3 then
      -- CASE III: Intercept glide slope and follow bullseye (ICLS).
      playerData.step=AIRBOSS.PatternStep.BULLSEYE
    end
  end
end

--- Intercept glide slop and follow ICLS, aka Bullseye.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Bullseye(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.Bullseye) then
    self:_AbortPattern(playerData, X, Z, self.Bullseye)
    return
  end
  
  -- Check that we reached the position.
  if self:_CheckLimits(X, Z, self.Bullseye) then
  
    -- Get optimal altitiude.
    local altitude=self:_GetAircraftParameters(playerData)
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Bulls Eye", debrief)
    
    -- Next step: Early Break.
    playerData.step=AIRBOSS.PatternStep.FINAL
  end
end
 

--- Upwind leg or break entry.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Upwind(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.Upwind) then
    self:_AbortPattern(playerData, X, Z, self.Upwind)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(X, Z, self.Upwind) then
  
    -- Get optimal altitude, distance and speed.
    local alt, aoa, dist, speed=self:_GetAircraftParameters(playerData)
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, alt)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Entering the Break", debrief)
    
    -- Next step: Early Break.
    playerData.step=AIRBOSS.PatternStep.EARLYBREAK
  end
end


--- Break.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #string part Part of the break.
function AIRBOSS:_Break(playerData, part)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi=self:_GetDistances(playerData.unit)
  
  -- Early or late break.  
  local breakpoint = self.BreakEarly
  if part=="late" then
    breakpoint = self.BreakLate
  end
    
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, breakpoint) then
    self:_AbortPattern(playerData, X, Z, breakpoint)
    return
  end

  -- Check limits.
  if self:_CheckLimits(X, Z, breakpoint) then
  
    -- Get optimal altitude, distance and speed.
    local altitude=self:_GetAircraftParameters(playerData)
  
    -- Grade altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, altitude)
    
    -- Send message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)

    -- Debrief
    if part=="early" then
      self:_AddToSummary(playerData, "Early Break", debrief)      
    else
      self:_AddToSummary(playerData, "Late Break", debrief)
    end

    -- Next step: Late Break or Abeam.
    if part=="early" then
      playerData.step=AIRBOSS.PatternStep.LATEBREAK
    else
      playerData.step=AIRBOSS.PatternStep.ABEAM
    end
  end
end

--- Long downwind leg check.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_CheckForLongDownwind(playerData)
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z=self:_GetDistances(playerData.unit)

  -- Get relative heading.
  local relhead=self:_GetRelativeHeading(playerData.unit)

  -- One NM from carrier is too far.  
  local limit=UTILS.NMToMeters(-1.5)
  
  local text=string.format("Long groove check: X=%d, relhead=%.1f", X, relhead)
  self:T(text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)
  
  -- Check we are not too far out w.r.t back of the boat.
  if X<limit then --and relhead<45 then
    
    -- Sound output.
    self:RadioTransmission(self.LSOradio, self.radiocall.LONGINGROOVE)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Downwind", "Long in the groove.")
    
    --grade="LIG PATTERN WAVE OFF - CUT 1 PT"
    playerData.lig=true
    playerData.patternwo=true
    
    -- Next step: Debriefing.
    playerData.step=AIRBOSS.PatternStep.DEBRIEF
  end
  
end

--- Abeam position.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Abeam(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Abeam) then
    self:_AbortPattern(playerData, X, Z, self.Abeam)
    return
  end

  -- Check nest step threshold.  
  if self:_CheckLimits(X, Z, self.Abeam) then

    -- Get optimal altitude, distance and speed.
    local alt, aoa, dist, speed=self:_GetAircraftParameters(playerData)
    
    -- Grade Altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, aoa)    
    
    -- Grade distance to carrier.
    local hintDist, debriefDist=self:_DistanceCheck(playerData, dist) --math.abs(Z)
    
    -- Compile full hint.
    local hint=string.format("%s\n%s\n%s", hintAlt, hintAoA, hintDist)
    local debrief=string.format("%s\n%s\n%s", debriefAlt, debriefAoA, debriefDist)
    
    -- Send message to playerr.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "Abeam Position", debrief)
    
    -- Next step: ninety.
    playerData.step=AIRBOSS.PatternStep.NINETY
  end
end

--- At the Ninety.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Ninety(playerData) 
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Ninety) then
    self:_AbortPattern(playerData, X, Z, self.Ninety)
    return
  end
  
  -- Get Realtive heading player to carrier.
  local relheading=self:_GetRelativeHeading(playerData.unit)
  
  -- At the 90, i.e. 90 degrees between player heading and BRC of carrier.
  if relheading<=90 then
  
    -- Get optimal altitude, distance and speed.
    local alt, aoa, dist, speed=self:_GetAircraftParameters(playerData)
    
    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, aoa)
    
    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the 90", debrief)
    
    -- Next step: wake.
    playerData.step=AIRBOSS.PatternStep.WAKE
    
  elseif relheading>90 and self:_CheckLimits(X, Z, self.Wake) then
    -- Message to player.
    self:_SendMessageToPlayer("You are already at the wake and have not passed the 90! Turn faster next time!", 10, playerData)
    --TODO: pattern WO?
  end
end

--- At the Wake.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Wake(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
    
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Wake) then
    self:_AbortPattern(playerData, X, Z, self.Wake)
    return
  end
  
  -- Right behind the wake of the carrier dZ>0.
  if self:_CheckLimits(X, Z, self.Wake) then
      
    -- Get optimal altitude, distance and speed.
    local alt, aoa, dist, speed=self:_GetAircraftParameters(playerData)
  
    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, aoa)

    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the Wake", debrief)

    -- Next step: Final.
    playerData.step=AIRBOSS.PatternStep.FINAL
  end
end

--- Turn to final.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Final(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)

  -- In front of carrier or more than 4 km behind carrier. 
  if self:_CheckAbort(X, Z, self.Groove) then
    self:_AbortPattern(playerData, X, Z, self.Groove)
    return
  end
   
  local relhead=self:_GetRelativeHeading(playerData.unit)+self.carrierparam.rwyangle
  local lineup=self:_Lineup(playerData)-self.carrierparam.rwyangle
  local roll=playerData.unit:GetRoll()
  
  if math.abs(lineup)<5 and math.abs(relhead)<10 then

    -- Get optimal altitude, distance and speed.
    local alt, aoa, dist, speed=self:_GetAircraftParameters(playerData)

    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, alt)

    -- AoA feed back 
    local hintAoA, debriefAoA=self:_AoACheck(playerData, aoa)
    
    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)

    -- Add to debrief.
    self:_AddToSummary(playerData, "Enter Groove", debrief)
    
    -- Gather pilot data.
    local groovedata={} --#AIRBOSS.GrooveData
    groovedata.Step=playerData.step
    groovedata.Alt=alt
    groovedata.AoA=aoa
    groovedata.GSE=self:_Glideslope(playerData)-3.5
    groovedata.LUE=self:_Lineup(playerData)-self.carrierparam.rwyangle
    groovedata.Roll=roll
        
    -- Groove 
    playerData.groove.X0=groovedata
    
    -- Next step: X start & call the ball.
    playerData.step=AIRBOSS.PatternStep.GROOVE_XX
  end

end


--- In the groove.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Groove(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)
  
  -- Player altitude
  local alt=playerData.unit:GetAltitude()
  
  -- Player group.
  local player=playerData.unit:GetGroup()

  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Trap) then
    self:_AbortPattern(playerData, X, Z, self.Trap)
    return
  end

  -- Lineup with runway centerline.
  local lineup=self:_Lineup(playerData)
  local lineupError=lineup-self.carrierparam.rwyangle
  
  -- Glide slope.
  local glideslope=self:_Glideslope(playerData)
  local glideslopeError=glideslope-3.5   --TODO: maybe 3.0?
  
  -- Get AoA.
  local AoA=playerData.unit:GetAoA()
  
  -- Ranges in the groove.
  local RXX=UTILS.NMToMeters(0.750)+math.abs(self.carrierparam.sterndist) -- Start of groove.      0.75  = 1389 m
  local RRB=UTILS.NMToMeters(0.500)+math.abs(self.carrierparam.sterndist) -- Roger Ball! call.     0.5   =  926 m
  local RIM=UTILS.NMToMeters(0.375)+math.abs(self.carrierparam.sterndist) -- In the Middle 0.75/2. 0.375 =  695 m 
  local RIC=UTILS.NMToMeters(0.100)+math.abs(self.carrierparam.sterndist) -- In Close.             0.1   =  185 m
  local RAR=UTILS.NMToMeters(0.000)+math.abs(self.carrierparam.sterndist) -- At the Ramp.

  -- Data  
  local groovedata={} --#AIRBOSS.GrooveData
  groovedata.Step=playerData.step  
  groovedata.Alt=alt
  groovedata.AoA=AoA
  groovedata.GSE=glideslopeError
  groovedata.LUE=lineupError
  groovedata.Roll=playerData.unit:GetRoll()
  
  if rho<=RXX and playerData.step==AIRBOSS.PatternStep.GROOVE_XX then
  
    -- LSO "Call the ball" call.
    self:RadioTransmission(self.LSOradio, self.radiocall.CALLTHEBALL)
    playerData.Tlso=timer.getTime()
        
    -- Store data.
    playerData.groove.XX=groovedata
    
    -- Next step: roger ball.
    playerData.step=AIRBOSS.PatternStep.GROOVE_RB
  
  elseif rho<=RRB and playerData.step==AIRBOSS.PatternStep.GROOVE_RB then

    -- Pilot: "Roger ball" call.
    self:RadioTransmission(self.LSOradio, self.radiocall.ROGERBALL)
    playerData.Tlso=timer.getTime()+1
    
    -- Store data.
    playerData.groove.RB=groovedata
    
    -- Next step: in the middle.
    playerData.step=AIRBOSS.PatternStep.GROOVE_IM
    
  elseif rho<=RIM and playerData.step==AIRBOSS.PatternStep.GROOVE_IM then
  
    -- Debug.
    self:_SendMessageToPlayer("IM", 8, playerData)
    self:I(self.lid..string.format("FF IM=%d", rho))
    
    -- Store data.
    playerData.groove.IM=groovedata    
    
    -- Next step: in close.
    playerData.step=AIRBOSS.PatternStep.GROOVE_IC
  
  elseif rho<=RIC and playerData.step==AIRBOSS.PatternStep.GROOVE_IC then

    -- Check if player was already waved off.
    if playerData.waveoff==false then

      -- Debug
      self:_SendMessageToPlayer("IC", 8, playerData)
      self:I(self.lid..string.format("FF IC=%d", rho))
      
      -- Store data.
      playerData.groove.IC=groovedata
      
      -- Check if player should wave off.
      local waveoff=self:_CheckWaveOff(glideslopeError, lineupError, AoA)
      
      -- Let's see..
      if waveoff then
              
        -- LSO Wave off!
        self:RadioTransmission(self.LSOradio, self.radiocall.WAVEOFF)
        playerData.Tlso=timer.getTime()
        
        -- Player was waved off!
        playerData.waveoff=true
              
        return
      else
        -- Next step: AR at the ramp.      
        playerData.step=AIRBOSS.PatternStep.GROOVE_AR
      end
      
    end
    
  elseif rho<=RAR and playerData.step==AIRBOSS.PatternStep.GROOVE_AR then
  
    -- Debug.
    self:_SendMessageToPlayer("AR", 8, playerData)
    self:I(self.lid..string.format("FF AR=%d", rho))
    
    -- Store data.
    playerData.groove.AR=groovedata
    
    -- Next step: in the wires.
    playerData.step=AIRBOSS.PatternStep.GROOVE_IW
  end
  
  -- Time since last LSO call.
  local time=timer.getTime()
  local deltaT=time-playerData.Tlso
  
  -- Check if we are beween 3/4 NM and end of ship.
  if rho>=RAR and rho<RXX and deltaT>=3 then

    -- LSO call if necessary.
    self:_LSOadvice(playerData, glideslopeError, lineupError)

  elseif X>100 then
           
    if playerData.landed then
      
      -- Add to debrief.
      if playerData.waveoff then
        self:_AddToSummary(playerData, "Wave Off", "You were waved off but landed anyway. Airboss wants to talk to you!")
      else
        self:_AddToSummary(playerData, "Bolter", "You boltered.")
      end
            
    else
      
      -- Add to debrief.
      self:_AddToSummary(playerData, "Wave Off", "You were waved off.")
      
      -- Next step: debrief.
      playerData.step=AIRBOSS.PatternStep.DEBRIEF
      
    end
  end 
end

--- LSO check if player needs to wave off.
-- Wave off conditions are:
-- 
-- * Glide slope error > 3 degrees.
-- * Line up error > 3 degrees.
-- * AoA<6.9 or AoA>9.3.
-- @param #AIRBOSS self
-- @param #number glideslopeError Glide slope error in degrees.
-- @param #number lineupError Line up error in degrees.
-- @param #number AoA Angle of attack of player aircraft.
-- @return #boolean If true, player should wave off!
function AIRBOSS:_CheckWaveOff(glideslopeError, lineupError, AoA)

  local waveoff=false
  
  -- Too high or too low?
  if math.abs(glideslopeError)>1 then
    self:I(self.lid.."Wave off due to glide slope error >1 degrees!")
    waveoff=true
  end
  
  -- Too far from centerline?
  if math.abs(lineupError)>3 then
    self:I(self.lid.."Wave off due to line up error >3 degrees!")
    waveoff=true
  end
  
  -- Too slow or too fast?
  -- TODO: Only apply for TOPGUN graduate skill level or at least not for Flight Student level.
  if AoA<6.9 or AoA>9.3 then
    self:I(self.lid.."INACTIVE! Wave off due to AoA<6.9 or AoA>9.3!")
    --waveoff=true
  end

  return waveoff
end



--- Trapped?
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number X Distance in meters wrt carrier position where player landed.
function AIRBOSS:_Trapped(playerData, X)

  self:I(self.lid.."FF TRAPPED")

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  --local X, Z, rho, phi = self:_GetDistances(pos)
  
  if playerData.unit:InAir()==false then
    -- Seems we have successfully landed.
    
    -- Little offset for the exact wire positions.
    local wdx=0
    
    -- Which wire was caught?
    local wire
    if X<self.carrierparam.wire1+wdx then
      wire=1
    elseif X<self.carrierparam.wire2+wdx then
      wire=2
    elseif X<self.carrierparam.wire3+wdx then
      wire=3
    elseif X<self.carrierparam.wire4+wdx then
      wire=4
    else
      wire=0
    end
       
    local text=string.format("TRAPPED! %d-wire.", wire)
    self:_SendMessageToPlayer(text, 10, playerData)
    
    local text2=string.format("Distance X=%.1f meters resulted in a %d-wire estimate.", X, wire)
    MESSAGE:New(text,30):ToAllIf(self.Debug)
    self:I(self.lid..text2)
       
    local hint = string.format("Trapped catching the %d-wire.", wire)
    self:_AddToSummary(playerData, "Recovered", hint)
    
  else
    --Boltered!
    playerData.boltered=true
  end
  
  -- Next step: debriefing.
  playerData.step=AIRBOSS.PatternStep.DEBRIEF
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ORIENTATION functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Provide info about player status on the fly.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_DetailedPlayerStatus(playerData)

  -- Player unit.
  local unit=playerData.unit
  
  -- Aircraft attitude.
  local aoa=unit:GetAoA()
  local yaw=unit:GetYaw()
  local roll=unit:GetRoll()
  local pitch=unit:GetPitch()
  
  -- Distance to the boat.
  local dist=playerData.unit:GetCoordinate():Get2DDistance(self:GetCoordinate())
  local dx,dz,rho,phi=self:_GetDistances(unit)

  -- Wind vector.
  local wind=unit:GetCoordinate():GetWindWithTurbulenceVec3()
  
  -- Aircraft veloecity vector.
  local velo=unit:GetVelocityVec3()
  local vabs=UTILS.VecNorm(velo)
  
  -- Relative heading Aircraft to Carrier.
  local relhead=self:_GetRelativeHeading(playerData.unit)
 
  -- Output
  local text=string.format("Pattern step: %s\n", playerData.step) 
  text=text..string.format("AoA=%.1f | |V|=%.1f knots\n", aoa, UTILS.MpsToKnots(vabs))
  text=text..string.format("Vx=%.1f Vy=%.1f Vz=%.1f m/s\n", velo.x, velo.y, velo.z)  
  text=text..string.format("Pitch=%.1f° | Roll=%.1f° | Yaw=%.1f°\n", pitch, roll, yaw)
  text=text..string.format("Climb Angle=%.1f° | Rate=%d ft/min\n", unit:GetClimbAngle(), velo.y*196.85) 
  text=text..string.format("R=%.1f NM | X=%d Z=%d m\n", UTILS.MetersToNM(rho), dx, dz)
  text=text..string.format("Phi=%.1f° | Rel=%.1f°", phi, relhead)
  -- If in the groove, provide line up and glide slope error.
  if playerData.step==AIRBOSS.PatternStep.GROOVE_XX or
     playerData.step==AIRBOSS.PatternStep.GROOVE_RB or
     playerData.step==AIRBOSS.PatternStep.GROOVE_IM or
     playerData.step==AIRBOSS.PatternStep.GROOVE_IC or
     playerData.step==AIRBOSS.PatternStep.GROOVE_AR or
     playerData.step==AIRBOSS.PatternStep.GROOVE_IW then
    local lineup=self:_Lineup(playerData)-self.carrierparam.rwyangle
    local glideslope=self:_Glideslope(playerData)-3.5
    text=text..string.format("\nLU Error = %.1f° (line up)", lineup)
    text=text..string.format("\nGS Error = %.1f° (glide slope)", glideslope)
  end
  
  -- Wind (for debugging).
  --text=text..string.format("Wind Vx=%.1f Vy=%.1f Vz=%.1f\n", wind.x, wind.y, wind.z)

  MESSAGE:New(text, 1, nil , true):ToClient(playerData.client)
end

--- Get glide slope of aircraft.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Glide slope angle in degrees measured from the 
function AIRBOSS:_Glideslope(playerData)

 -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)

  -- Glideslope. Wee need to correct for the height of the deck. The ideal glide slope is 3.5 degrees.
  local h=playerData.unit:GetAltitude()-self.carrierparam.deckheight
  local x=math.abs(self.carrierparam.wire3-X)  --TODO: Check if carrier has wires later.
  local glideslope=math.atan(h/x)  

  return math.deg(glideslope)
end

--- Get line up of player wrt to carrier runway.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Line up with runway heading in degrees. 0 degrees = perfect line up. +1 too far left. -1 too far right.
-- @return #number Distance from carrier tail to player aircraft in meters.
function AIRBOSS:_Lineup(playerData) 

 -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)  
  
  -- Position at the end of the deck. From there we calculate the angle.
  local b={x=self.carrierparam.sterndist, z=0}
  
  -- Position of the aircraft wrt carrier coordinates.
  local a={x=X, z=Z}

  -- Vector from plane to ref point on boad.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Current line up and error wrt to final heading of the runway.
  local lineup=math.atan2(c.z, c.x)

  return math.deg(lineup), UTILS.VecNorm(c)
end

--- Get base recovery course (BRC) of carrier.
-- @param #AIRBOSS self
-- @param #boolean True If true, return true bearing. Otherwise (default) return magnetic bearing.
-- @return #number BRC in degrees.
function AIRBOSS:_BaseRecoveryCourse(True) 
  self:E({TrueBearing=True})

  -- Current true heading of carrier.
  local hdg=self.carrier:GetHeading()
  
  -- Final (true) bearing.   
  local brc=hdg
    
  -- Magnetic bearing.
  if True==false then
    --TODO: Conversion to magnetic, i.e. include magnetic declination of current map.
  end
  
  -- Adjust negative values.
  if brc<0 then
    brc=brc+360
  end
  
  return brc
end


--- Get final bearing (FB) of carrier.
-- By default, the routine returns the magnetic FB depending on the current map (Caucasus, NTTR, Normandy, Persion Gulf etc).
-- The true bearing can be obtained by setting the *True* parameter to true. 
-- @param #AIRBOSS self
-- @param #boolean True If true, return true bearing. Otherwise (default) return magnetic bearing.
-- @return #number FB in degrees.
function AIRBOSS:_FinalBearing(True) 

  -- Base Recovery Course of carrier.
  local brc=self:_BaseRecoveryCourse(True)
  
  -- Final baring = BRC including angled deck.
  local fb=brc+self.carrierparam.rwyangle
  
  -- Adjust negative values.
  if fb<0 then
    fb=fb+360
  end
  
  return fb
end

--- Get radial, i.e. the final bearing FB-180 degrees.
-- @param #AIRBOSS self
-- @return #number Radial in degrees.
function AIRBOSS:_Radial() 

  -- Get radial.
  local radial=self:_FinalBearing()-180
  
  -- Adjust for negative values.
  if radial<0 then
    radial=radial+360
  end
  
  return radial
end

--- Get relative heading of player wrt carrier.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Player unit.
-- @return #number Relative heading in degrees.
function AIRBOSS:_GetRelativeHeading(unit)
  local vC=self.carrier:GetOrientationX()
  local vP=unit:GetOrientationX()
  
  -- Get angle between the two orientation vectors in rad.
  local relHead=math.acos(UTILS.VecDot(vC,vP)/UTILS.VecNorm(vC)/UTILS.VecNorm(vP))
  
  -- Return heading in degrees.
  return math.deg(relHead)
end

--- Calculate distances between carrier and player unit.
-- @param #AIRBOSS self 
-- @param Wrapper.Unit#UNIT unit Player unit
-- @return #number Distance [m] in the direction of the orientation of the carrier.
-- @return #number Distance [m] perpendicular to the orientation of the carrier.
-- @return #number Distance [m] to the carrier.
-- @return #number Angle [Deg] from carrier to plane. Phi=0 if the plane is directly behind the carrier, phi=90 if the plane is starboard, phi=180 if the plane is in front of the carrier.
function AIRBOSS:_GetDistances(unit)

  -- Vector to carrier
  local a=self.carrier:GetVec3()
  
  -- Vector to player
  local b=unit:GetVec3()
  
  -- Vector from carrier to player.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Orientation of carrier.
  local x=self.carrier:GetOrientationX()
  
  -- Projection of player pos on x component.
  local dx=UTILS.VecDot(x,c)
  
  -- Orientation of carrier.
  local z=self.carrier:GetOrientationZ()
  
  -- Projection of player pos on z component.  
  local dz=UTILS.VecDot(z,c)
  
  -- Polar coordinates
  local rho=math.sqrt(dx*dx+dz*dz)
  local phi=math.deg(math.atan2(dz,dx))
  if phi<0 then
    phi=phi+360
  end
  
  -- phi=0 if the plane is directly behind the carrier, phi=180 if the plane is in front of the carrier
  phi=phi-180

  if phi<0 then
    phi=phi+360
  end
  
  return dx,dz,rho,phi
end

--- Check limits for reaching next step.
-- @param #AIRBOSS self
-- @param #number X X position of player unit.
-- @param #number Z Z position of player unit.
-- @param #AIRBOSS.Checkpoint check Checkpoint.
-- @return #boolean If true, checkpoint condition for next step was reached.
function AIRBOSS:_CheckLimits(X, Z, check)

  -- Limits
  local nextXmin=check.LimitXmin==nil or (check.LimitXmin and (check.LimitXmin<0 and X<=check.LimitXmin or check.LimitXmin>=0 and X>=check.LimitXmin))
  local nextXmax=check.LimitXmax==nil or (check.LimitXmax and (check.LimitXmax<0 and X>=check.LimitXmax or check.LimitXmax>=0 and X<=check.LimitXmax))
  local nextZmin=check.LimitZmin==nil or (check.LimitZmin and (check.LimitZmin<0 and Z<=check.LimitZmin or check.LimitZmin>=0 and Z>=check.LimitZmin))
  local nextZmax=check.LimitZmax==nil or (check.LimitZmax and (check.LimitZmax<0 and Z>=check.LimitZmax or check.LimitZmax>=0 and Z<=check.LimitZmax))
  
  -- Proceed to next step if all conditions are fullfilled.
  local next=nextXmin and nextXmax and nextZmin and nextZmax
  
  -- Debug info.
  local text=string.format("step=%s: next=%s: X=%d Xmin=%s Xmax=%s | Z=%d Zmin=%s Zmax=%s", 
  check.name, tostring(next), X, tostring(check.LimitXmin), tostring(check.LimitXmax), Z, tostring(check.LimitZmin), tostring(check.LimitZmax))
  self:T(self.lid..text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)

  return next
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LSO functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- LSO advice radio call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number glideslopeError Error in degrees.
-- @param #number lineupError Error in degrees.
function AIRBOSS:_LSOadvice(playerData, glideslopeError, lineupError)

  -- Player group.
  local player=playerData.unit:GetGroup()
  
  -- Init delay.
  local delay=0
  
  -- Glideslope high/low calls.
  local text=""
  if glideslopeError>1 then
    -- "You're high!"
    self:RadioTransmission(self.LSOradio, self.radiocall.HIGH, true, delay)
    delay=delay+1.5
  elseif glideslopeError>0.5 then
    -- "You're a little high."
    self:RadioTransmission(self.LSOradio, self.radiocall.HIGH, false, delay)
    delay=delay+1.5
  elseif glideslopeError<-1.0 then
    -- "Power!"
    self:RadioTransmission(self.LSOradio, self.radiocall.POWER, true, delay)
    delay=delay+1.5
  elseif glideslopeError<-0.5 then
    -- "You're a little low."
    self:RadioTransmission(self.LSOradio, self.radiocall.POWER, false, delay)
    delay=delay+1.5
  else
    text="Good altitude."
  end

  text=text..string.format(" Glideslope Error = %.2f°", glideslopeError)
  text=text.."\n"
  
  -- Lineup left/right calls.
  if lineupError<-3 then
    -- "Come left!"
    self:RadioTransmission(self.LSOradio, self.radiocall.COMELEFT, true, delay)
    delay=delay+1.5
  elseif lineupError<-1 then
    -- "Come left."
    self:RadioTransmission(self.LSOradio, self.radiocall.COMELEFT, false, delay)
    delay=delay+1.5    
  elseif lineupError>3 then
    -- "Right for lineup!"
    self:RadioTransmission(self.LSOradio, self.radiocall.RIGHTFORLINEUP, true, delay)
    delay=delay+1.5    
  elseif lineupError>1 then
    -- "Right for lineup."
    self:RadioTransmission(self.LSOradio, self.radiocall.RIGHTFORLINEUP, false, delay)
    delay=delay+1.5    
  else
    text=text.."Good lineup."
  end
  
  text=text..string.format(" Lineup Error = %.1f°\n", lineupError)
  
  -- Get AoA.
  local aoa=playerData.unit:GetAoA()
  
  -- TODO: Generalize AoA for other aircraft!
  if aoa>=9.3 then
    -- "Your're slow!"
    self:RadioTransmission(self.LSOradio, self.radiocall.SLOW, true, delay)
    delay=delay+1.5        
  elseif aoa>=8.8 and aoa<9.3 then
    -- "Your're a little slow."
    self:RadioTransmission(self.LSOradio, self.radiocall.SLOW, false, delay)
    delay=delay+1.5              
  elseif aoa>=7.4 and aoa<8.8 then
    text=text.."You're on speed."
  elseif aoa>=6.9 and aoa<7.4 then
    -- "You're a little fast."
    self:RadioTransmission(self.LSOradio, self.radiocall.FAST, false, delay)
    delay=delay+1.5            
  elseif aoa>=0 and aoa<6.9 then
    -- "You're fast!"
    self:RadioTransmission(self.LSOradio, self.radiocall.FAST, true, delay)
    delay=delay+1.5                
  else
    text=text.."Unknown AoA state."
  end
  
  text=text..string.format(" AoA = %.1f", aoa)
   
  -- LSO Message to player.
  --self:_SendMessageToPlayer(text, 5, playerData, false)
  
  -- Set last time.
  playerData.Tlso=timer.getTime()   
end

--- Grade approach.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #string LSO grade, i.g. _OK_, OK, (OK), --, etc.
-- @return #number Points.
-- @return #string LSO analysis of flight path.
function AIRBOSS:_LSOgrade(playerData)
  
  local function count(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
  end

  -- Analyse flight data and conver to LSO text.
  local GXX,nXX=self:_Flightdata2Text(playerData.groove.XX)
  local GIM,nIM=self:_Flightdata2Text(playerData.groove.IM)
  local GIC,nIC=self:_Flightdata2Text(playerData.groove.IC)
  local GAR,nAR=self:_Flightdata2Text(playerData.groove.AR)
  
  -- Put everything together.
  local G=GXX.." "..GIM.." ".." "..GIC.." "..GAR
  
  -- Ground number of minor, normal and major deviations.
  local N=nXX+nIM+nIC+nAR
  local nL=count(G, '_')/2
  local nS=count(G, '%(')
  local nN=N-nS-nL
  
  local grade
  local points
  if N==0 then
    -- No deviations, should be REALLY RARE!
    grade="_OK_"
    points=5.0
  else
    if nL>0 then
      -- Larger deviations ==> "No grade" 2.0 points.
      grade="--" 
      points=2.0
    elseif nN>0 then
      -- No larger but average deviations ==>  "Fair Pass" Pass with average deviations and corrections.
      grade="(OK)"
      points=3.0
    else
      -- Only minor corrections
      grade="OK"
      points=4.0
    end
  end
  
  -- Replace" )"( and "__" 
  G=G:gsub("%)%(", "")
  G=G:gsub("__","")  
  
  -- Debug info
  local text="LSO grade:\n"
  text=text..G.."\n"
  text=text.."Grade = "..grade.." points = "..points.."\n"
  text=text.."# of total deviations   = "..N.."\n"
  text=text.."# of large deviations _ = "..nL.."\n"
  text=text.."# of norma deviations _ = "..nN.."\n"
  text=text.."# of small deviations ( = "..nS.."\n"
  self:I(self.lid..text)
  
  if playerData.patternwo or playerData.waveoff then
    grade="CUT"
    points=1.0
    if playerData.lig then
      G="LIG PWO"
    elseif playerData.patternwo then
      G="PWO "..G
    end
    if playerData.landed then
      --AIRBOSS wants to talk to you!
    end
  elseif playerData.boltered then
    grade="-- (BOLTER)"
    points=2.5 
  end

  return grade, points, G
end

--- Grade flight data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.GrooveData fdata Flight data in the groove.
-- @return #string LSO grade or empty string if flight data table is nil.
-- @return #number Number of deviations from perfect flight path.
function AIRBOSS:_Flightdata2Text(fdata)

  local function little(text)
    return string.format("(%s)",text)
  end
  local function underline(text)
    return string.format("_%s_", text)
  end

  -- No flight data ==> return empty string.
  if fdata==nil then
    self:E(self.lid.."Flight data is nil.")
    return "", 0
  end

  -- Flight data.
  local step=fdata.Step
  local AOA=fdata.AoA
  local GSE=fdata.GSE
  local LUE=fdata.LUE
  local ROL=fdata.Roll

  -- Speed.
  local S=nil
  if AOA>9.8 then
    S=underline("SLO")
  elseif AOA>9.3 then
    S="SLO"
  elseif AOA>8.8 then
    S=little("SLO")
  elseif AOA<6.4 then
    S=underline("F")
  elseif AOA<6.9 then
    S="F"
  elseif AOA<7.4 then
    S=little("F")
  end
  
  -- Alitude.
  local A=nil
  if GSE>1 then
    A=underline("H")
  elseif GSE>0.5 then
    A=little("H")
  elseif GSE>0.25 then
    A="H"
  elseif GSE<-1 then
    A=underline("LO")
  elseif GSE<-0.5 then
    A=little("LO")
  elseif GSE<-0.25 then
    A="LO"
  end
  
  -- Line up.
  local D=nil
  if LUE>3 then
    D=underline("LUL")
  elseif LUE>1 then
    D="LUL"
  elseif LUE>0.5 then
    D=little("LUL")
  elseif LUE<-3 then
    D=underline("LUR")
  elseif LUE<-1 then
    D="LUR"
  elseif LUE<-0.5 then
    D=little("LUR")
  end
  
  -- Compile.
  local G=""
  local n=0
  if S then
    G=G..S
    n=n+1
  end
  if A then
    G=G..A
    n=n+1
  end
  if D then
    G=G..D
    n=n+1
  end
  
  -- Add current step.
  local step=self:_GS(step)
  step=step:gsub("XX","X")
  if G~="" then
    G=G..step
  end
  
  -- Debug info.
  local text=string.format("LSO Grade at %s:\n", step)
  text=text..string.format("AOA=%.1f\n",AOA)
  text=text..string.format("GSE=%.1f\n",GSE)
  text=text..string.format("LUE=%.1f\n",LUE)
  text=text..string.format("ROL=%.1f\n",ROL)    
  text=text..G
  self:T(self.lid..text)
  
  return G,n
end

--- Get short name of the grove step.
-- @param #AIRBOSS self
-- @param #number step Step
-- @return #string Shortcut name "X", "RB", "IM", "AR", "IW".
function AIRBOSS:_GS(step)
  local gp
  if step==AIRBOSS.PatternStep.FINAL then
    gp="X0"  -- Entering the groove.
  elseif step==AIRBOSS.PatternStep.GROOVE_XX then
    gp="X"  -- Starting the groove.
  elseif step==AIRBOSS.PatternStep.GROOVE_RB then
    gp="RB"  -- Roger ball call.
  elseif step==AIRBOSS.PatternStep.GROOVE_IM then
    gp="IM"  -- In the middle.
  elseif step==AIRBOSS.PatternStep.GROOVE_IC then
    gp="IC"  -- In close.
  elseif step==AIRBOSS.PatternStep.GROOVE_AR then
    gp="AR"  -- At the ramp.
  elseif step==AIRBOSS.PatternStep.GROOVE_IW then
    gp="IW"  -- In the wires.
  end
  return gp
end

--- Check if a player is within the right area.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint pos Position data limits.
-- @return #boolean If true, approach should be aborted.
function AIRBOSS:_CheckAbort(X, Z, pos)

  local abort=false
  if pos.Xmin and X<pos.Xmin then
    self:E(string.format("Xmin: X=%d < %d=Xmin", X, pos.Xmin))
    abort=true
  elseif pos.Xmax and X>pos.Xmax then
    self:E(string.format("Xmax: X=%d > %d=Xmax", X, pos.Xmax))
    abort=true
  elseif pos.Zmin and Z<pos.Zmin then
    self:E(string.format("Zmin: Z=%d < %d=Zmin", Z, pos.Zmin))
    abort=true
  elseif pos.Zmax and Z>pos.Zmax then
    self:E(string.format("Zmax: Z=%d > %d=Zmax", Z, pos.Zmax))
    abort=true
  end
  
  return abort
end

--- Generate a text if a player is too far from where he should be.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
function AIRBOSS:_TooFarOutText(X, Z, posData)

  local text="You are too far "
  
  local xtext=nil
  if posData.Xmin and X<posData.Xmin then
    xtext="ahead"
  elseif posData.Xmax and X>posData.Xmax then
    xtext="behind"
  end
  
  local ztext=nil
  if posData.Zmin and Z<posData.Zmin then
    ztext="port (left) of"
  elseif posData.Zmax and Z>posData.Zmax then
    ztext="starboard (right) of"
  end
  
  if xtext and ztext then
    text=text..xtext.." and "..ztext
  elseif xtext then
    text=text..xtext
  elseif ztext then
    text=text..ztext
  end
  
  text=text.." the carrier."
  
  return text
end

--- Pattern aborted.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
function AIRBOSS:_AbortPattern(playerData, X, Z, posData)

  -- Text where we are wrong.
  local toofartext=self:_TooFarOutText(X, Z, posData)
  
  -- Send message to player.
  self:_SendMessageToPlayer(toofartext.." Depart and re-enter!", 15, playerData, false)
  
  -- Debug.
  local text=string.format("Abort: X=%d Xmin=%s, Xmax=%s | Z=%d Zmin=%s Zmax=%s", X, tostring(posData.Xmin), tostring(posData.Xmax), Z, tostring(posData.Zmin), tostring(posData.Zmax))
  self:E(self.lid..text)
  --MESSAGE:New(text, 60):ToAllIf(self.Debug)
  
  -- Add to debrief.
  self:_AddToSummary(playerData, string.format("%s", playerData.step), string.format("Pattern wave off: %s", toofartext))
  
  -- Pattern wave off!
  playerData.patternwo=true

  -- Next step debrief.  
  playerData.step=AIRBOSS.PatternStep.DEBRIEF
end


--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Low score.
-- @return #number Bad score.
function AIRBOSS:_GetGoodBadScore(playerData)

  local lowscore
  local badscore
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    lowscore=10
    badscore=20    
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    lowscore=5
    badscore=10     
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    lowscore=2.5
    badscore=5
  end
  
  return lowscore, badscore
end



--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number altopt Optimal alitude in meters.
-- @return #string Feedback text.
-- @return #string Debriefing text.
function AIRBOSS:_AltitudeCheck(playerData, altopt)

  if altopt==nil then
    return nil, nil
  end

  -- Player altitude.
  local altitude=playerData.unit:GetAltitude()
  
  -- Get relative score.
  local lowscore, badscore=self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(altitude-altopt)/altopt*100
  
  local hint
  if _error>badscore then
    hint=string.format("You're high. ")
  elseif _error>lowscore then
    hint= string.format("You're slightly high. ")
  elseif _error<-badscore then
    hint=string.format("You're low. ")
  elseif _error<-lowscore then
    hint=string.format("You're slightly low. ")
  else
    hint=string.format("Good altitude. ")
  end
  
  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format("Optimal altitude is %d ft.", UTILS.MetersToFeet(checkpoint.Altitude))
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end
  
  -- Debrief text.
  local debrief=string.format("Altitude %d ft = %d%% deviation from %d ft optimum.", UTILS.MetersToFeet(altitude), _error, UTILS.MetersToFeet(checkpoint.Altitude))
  
  return hint, debrief
end

--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number optdist Optimal distance in meters.
-- @return #string Feedback message text.
-- @return #string Debriefing text.
function AIRBOSS:_DistanceCheck(playerData, optdist)

  if optdist==nil then
    return nil, nil
  end
  
  -- Distance to carrier.
  local distance=playerData.unit:GetCoodinate():Get2DDistance(self:GetCoordinate())

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(distance-optdist)/optdist*100
  
  local hint
  if _error>badscore then
    hint=string.format("You're too far from the boat! ")
  elseif _error>lowscore then 
    hint=string.format("You're slightly too far from the boat. ")
  elseif _error<-badscore then
    hint=string.format( "You're too close to the boat! ")
  elseif _error<-lowscore then
    hint=string.format("You're slightly too far from the boat. ")
  else
    hint=string.format("Perfect distance to the boat. ")
  end
  
  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format(" Optimal distance is %d NM.", UTILS.MetersToNM(checkpoint.Distance))
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end

  -- Debriefing text.
  local debrief=string.format("Distance %.1f NM = %d%% deviation from %.1f NM optimum.",UTILS.MetersToNM(distance), _error, UTILS.MetersToNM(checkpoint.Distance))
   
  return hint, debrief
end

--- Score for correct AoA.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number optaoa Optimal AoA.
-- @return #string Feedback message text or easy and normal difficulty level or nil for hard.
-- @return #string Debriefing text.
function AIRBOSS:_AoACheck(playerData, optaoa)

  if optaoa==nil then
    return nil, nil
  end

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Player AoA
  local aoa=playerData.unit:GetAoA()
  
  -- Altitude error +-X%
  local _error=(aoa-optaoa)/optaoa*100

  local hint
  if _error>badscore then --Slow
    hint="You're slow. "
  elseif _error>lowscore then --Slightly slow
    hint="You're slightly slow. "
  elseif _error<-badscore then --Fast
    hint="You're fast. "
  elseif _error<-lowscore then --Slightly fast
    hint="You're slightly fast. "
  else --On speed
    hint="You're on speed. "
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format(" Optimal AoA is %.1f.", checkpoint.AoA)
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end
  
  -- Debriefing text.
  local debrief=string.format("AoA %.1f = %d%% deviation from %.1f optimum.", aoa, _error, checkpoint.AoA)
  
  return hint, debrief
end

--- Append text to debrief text.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string step Current step in the pattern.
-- @param #string item Text item appeded to the debrief.
function AIRBOSS:_AddToSummary(playerData, step, item)
  table.insert(playerData.debrief, {step=step, hint=item})
end

--- Show debriefing message.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Debrief(playerData)
  self:F("Debriefing")

  -- LSO grade, points, and flight data analyis.
  local grade, points, analysis=self:_LSOgrade(playerData)
    
  local mygrade={} --#AIRBOSS.LSOgrade  
  mygrade.grade=grade
  mygrade.points=points
  mygrade.details=analysis
  
  -- Add grade to table.
  table.insert(playerData.grades, mygrade)
  
  -- LSO grade message.
  local text=string.format("%s %.1f PT - %s", grade, points, analysis)
  text=text..string.format("Your detailed debriefing can now be seen in F10 radio menu.")
  self:MessageToPlayer(playerData,text, "LSO","" , 30, true)

  -- New approach.
  if playerData.boltered or playerData.waveoff or playerData.patternwo then
  
    -- TODO: can become nil when I crashed and changed to observer.
  
    -- Get heading and distance to register zone ~3 NM astern.
    local heading=playerData.unit:GetCoordinate():HeadingTo(self.zoneInitial:GetCoordinate())
    local distance=playerData.unit:GetCoordinate():Get2DDistance(self.zoneInitial:GetCoordinate())
    
    local text=string.format("fly heading %d for %d NM to re-enter the pattern.", heading, UTILS.MetersToNM(distance))
    self:_SendMessageToPlayer(text, 10, playerData, false, nil, 30)
    
    -- Next step?
    -- TODO: CASE I: After bolter/wo turn left and climb to 600 ft and re-enter the pattern. But do not go to initial but reenter earlier?
    -- TODO: CASE I: After pattern wo? go back to initial, I guess?
    -- TODO: CASE III: After bolter/wo turn left and climb to 1200 ft and re-enter pattern?
    -- TODO: CASE III: After pattern wo? No idea...
    playerData.step=AIRBOSS.PatternStep.COMMENCING
  end  
  
  -- Next step.
  playerData.step=AIRBOSS.PatternStep.UNDEFINED
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Radio transmission.
-- @param #AIRBOSS self
-- @param Core.Radio#RADIO radio sending transmission.
-- @param #AIRBOSS.RadioSound call Radio sound files and subtitles.
-- @param #boolean loud If true, play loud sound file version.
-- @param #number delay Delay in seconds, before the message is broadcasted.
function AIRBOSS:RadioTransmission(radio, call, loud, delay)
  self:E({radio=radio, call=call, loud=loud, delay=delay})  

  if (delay==nil) or (delay and delay==0) then

    if call==nil then
      self:E(self.lid.."ERROR: Radio call=nil!")
      self:E({radio=radio})
      self:E({call=call})
      self:E({loud=loud})
      self:E({delay=delay})
      return
    end    
  
    local filename
    if loud then
      filename=call.louder
    else
      filename=call.normal
    end
      
    -- New transmission.
    radio:NewUnitTransmission(filename, call.subtitle, call.duration, radio.Frequency/1000000, radio.Modulation, false)
    
    -- Broadcast message.
    radio:Broadcast(true)
    
    -- "Subtitle".
    for _,_player in pairs(self.players) do
      local playerData=_player --#AIRBOSS.PlayerData
      self:_SendMessageToPlayer(call.subtitle, call.duration, playerData)
    end
    
  else
  
    if call==nil then
      self:E(self.lid.."ERROR: Radio call=nil!")
      self:E({radio=radio})
      self:E({call=call})
      self:E({loud=loud})
      self:E({delay=delay})
      return
    end
  
    -- Scheduled transmission.
    SCHEDULER:New(nil, self.RadioTransmission, {self, radio, call, loud}, delay)
  end
end

--- Send message to player client.
-- @param #AIRBOSS self
-- @param #string message The message to send.
-- @param #number duration Display message duration.
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #string sender The person who sends the message. Default is carrier alias.
-- @param #number delay Delay in seconds, before the message is send.
function AIRBOSS:_SendMessageToPlayer(message, duration, playerData, clear, sender, delay)

  if playerData and message and message~="" then

    -- Format message.          
    local text=string.format("%s, %s", playerData.callsign, message)
    self:I(self.lid..text)
      
    if delay and delay>0 then
      SCHEDULER:New(nil, self._SendMessageToPlayer, {self, message, duration, playerData, clear, sender}, delay)
    else
      if playerData.client then
        MESSAGE:New(text, duration, sender, clear):ToClient(playerData.client)
      end
    end
    
  end
  
end

--- Send text message to player client.
-- Message format will be "SENDER: RECCEIVER, MESSAGE".
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string message The message to send.
-- @param #string sender The person who sends the message or nil.
-- @param #string receiver The person who receives the message. Default player's onboard number. Set to "" for no receiver.
-- @param #number duration Display message duration. Default 10 seconds.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #number delay Delay in seconds, before the message is displayed.
function AIRBOSS:MessageToPlayer(playerData, message, sender, receiver, duration, clear, delay)

  if playerData and message and message~="" then
  
    -- Default duration.
    duration=duration or 10

    -- Format message.          
    local text
    if receiver and receiver=="" then
      text=string.format("%s", message)      
    else
      receiver=receiver or playerData.onboard
      text=string.format("%s, %s", receiver, message)
    end
    self:I(self.lid..text)
      
    if delay and delay>0 then
      SCHEDULER:New(nil, self.MessageToPlayer, {self, playerData, message, sender, receiver, duration, clear}, delay)
    else
      if playerData.client then
        MESSAGE:New(text, duration, sender, clear):ToClient(playerData.client)
      end
    end
    
  end
  
end

--- Check if aircraft is capable of landing on an aircraft carrier.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit. (Will also work with groups as given parameter.)
-- @return #boolean If true, aircraft can land on a carrier.
function AIRBOSS:_IsCarrierAircraft(unit)
  local carrieraircraft=false
  local aircrafttype=unit:GetTypeName()
  for _,actype in pairs(AIRBOSS.AircraftCarrier) do
    if actype==aircrafttype then
      return true
    end
  end
  return false
end

--- Checks if a group has a human player.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function AIRBOSS:_IsHuman(group)

  local units=group:GetUnits()
  
  for _,_unit in pairs(units) do
    local playerunit=self:_GetPlayerUnitAndName(_unit:GetName())
    if playerunit then
      return true
    end
  end

  return false
end

--- Check if a group is in the queue.
-- @param #AIRBOSS self
-- @param #table queue The queue to check.
-- @param Wrapper.Group#GROUP group
-- @return #boolean If true, group is in the queue. False otherwise.
function AIRBOSS:_InQueue(queue, group)
  local name=group:GetName()
  for _,_flight in pairs(queue) do
    local flight=_flight  --#AIRBOSS.Flightitem
    if name==flight.groupname then
      return true
    end
  end
  return false
end

--- Get player data from unit object
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Unit in question.
-- @return #AIRBOSS.PlayerData Player data or nil if not player with this name or unit exists.
function AIRBOSS:_GetPlayerDataUnit(unit)
  if unit:IsAlive() then
    local unitname=unit:GetName()
    local playerunit,playername=self:_GetPlayerUnitAndName(unitname)
    if playerunit and playername then
      return self.players[playername]
    end
  end
  return nil
end


--- Get player data from group object.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Group in question.
-- @return #AIRBOSS.PlayerData Player data or nil if not player with this name or unit exists.
function AIRBOSS:_GetPlayerDataGroup(group)
  local units=group:GetUnits()
  for _,unit in pairs(units) do
    local playerdata=self:_GetPlayerDataUnit(unit)
    if playerdata then
      return playerdata
    end
  end
  return nil
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function AIRBOSS:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

--- Get carrier coaltion.
-- @param #AIRBOSS self
-- @return #number Coalition side of carrier.
function AIRBOSS:GetCoalition()
  return self.carrier:GetCoalition()
end

--- Get carrier coordinate.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Carrier coordinate.
function AIRBOSS:GetCoordinate()
  return self.carrier:GetCoordinate()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MENU Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #AIRBOSS self
-- @param #string _unitName Name of player unit.
function AIRBOSS:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local _gid=group:GetID()
  
    if group and _gid then
  
      if not self.menuadded[_gid] then
      
        -- Enable switch so we don't do this twice.
        self.menuadded[_gid]=true
  
        -- Main F10 menu: F10/Airboss/<Carrier Name>/
        if AIRBOSS.MenuF10[_gid]==nil then
          AIRBOSS.MenuF10[_gid]=missionCommands.addSubMenuForGroup(_gid, "Airboss")
        end
        
        -- Player Data.
        local playerData=self.players[playername]
        
        -- F10/Airboss/<Carrier Name>
        local _rootPath=missionCommands.addSubMenuForGroup(_gid, self.alias, AIRBOSS.MenuF10[_gid])
        
        -- F10/Airboss/<Carrier Name>/Results
        local _statsPath=missionCommands.addSubMenuForGroup(_gid, "Results", _rootPath)
        
        -- F10/Airboss/<Carrier Name>/My Settings/Skil Level
        local _skillPath=missionCommands.addSubMenuForGroup(_gid, "Skill Level", _rootPath)

        -- F10/Airboss/<Carrier Name>/My Settings/Kneeboard
        local _kneeboardPath=missionCommands.addSubMenuForGroup(_gid, "Kneeboard", _rootPath)

        -- F10/Airboss/<Carrier Name>/Results/
        missionCommands.addCommandForGroup(_gid, "Greenie Board", _statsPath, self._DisplayScoreBoard,   self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My LSO Grades", _statsPath, self._DisplayPlayerGrades, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Last Debrief",  _statsPath, self._DisplayDebriefing,   self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "(Clear ALL Results)", _statsPath, self._ResetRangeStats, self, _unitName)
        
        -- F10/Airboss/<Carrier Name>/Skill Level
        missionCommands.addCommandForGroup(_gid, "Flight Student",  _skillPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.EASY)
        missionCommands.addCommandForGroup(_gid, "Naval Aviator",   _skillPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.NORMAL)
        missionCommands.addCommandForGroup(_gid, "TOPGUN Graduate", _skillPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.HARD)
                
        -- F10/Airboss/<Carrier Name>/Kneeboard
        missionCommands.addCommandForGroup(_gid, "Carrier Info",            _kneeboardPath, self._DisplayCarrierInfo,    self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",          _kneeboardPath, self._DisplayCarrierWeather, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Status",               _kneeboardPath, self._DisplayPlayerStatus,   self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Attitude Monitor ON/OFF", _kneeboardPath, self._AttitudeMonitor,       self, playername)
        missionCommands.addCommandForGroup(_gid, "Smoke Marshal Zone",      _kneeboardPath, self._SmokeMarshalZone,      self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Flare Marshal Zone",      _kneeboardPath, self._FlareMarshalZone,      self, _unitName)

        -- F10/Airboss/<Carrier Name>/        
        missionCommands.addCommandForGroup(_gid, "Request Marshal?",    _rootPath, self._RequestMarshal,   self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Commencing!",         _rootPath, self._RequestCommence,  self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Request Refueling?",  _rootPath, self._RequestRefueling, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Set Section!",        _rootPath, self._SetSection,       self, _unitName)        
        
      end
    else
      self:T(self.lid.."Could not find group or group ID in AddF10Menu() function. Unit name: ".._unitName)
    end
  else
    self:T(self.lid.."Player unit does not exist in AddF10Menu() function. Unit name: ".._unitName)
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ROOT MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Request marshal.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestMarshal(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
    
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
        
    if playerData then
      
      -- Get flight group.      
      local flight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)
      
      if flight then
        self:_MarshalPlayer(playerData, flight)
      else
        -- Flight group does not exist yet.
        local text=string.format("%s, you are not registered inside CCA yet. Marshal request denied!", playerData.name)
        MESSAGE:New(text, 10, "MARSHAL"):ToClient(playerData.client)
      end
    end
  end
end

--- Request to commence approach.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestCommence(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
            
      -- Get flight group.
      local flight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)

      local text
      if flight then
      
        -- Get stack value.
        local stack=flight.flag:Get()
        
        if stack>1 then
          -- We are in a higher stack.
          text="Negative ghostrider, it's not your turn yet!"
        else
        
          -- Number of aircraft currently in pattern.
          local _,npattern=self:_GetQueueInfo(self.Qpattern)
              
          -- TODO: set nmax for pattern. Should be ~6 but let's make this 4.
          if npattern>0 then  
            -- Patern is full!
            text=string.format("Negative ghostrider, pattern is full! There are %d aircraft currently in pattern.", npattern)
          else
            -- Positive response.
            text="You are cleared for pattern. Proceed to initial."
            
            -- Set player step.
            playerData.step=AIRBOSS.PatternStep.COMMENCING
            
            -- Collaps marshal stack.
            self:_CollapseMarshalStack(flight)
          end
        
        end
        
      else
        -- This flight is not yet registered!
        text="Negative ghostrider, you are not yet registered inside the CCA yet!"
        -- TODO: fly 10 km towards the carrier advice for skill "Flight Student"
      end
      
      env.info(text)
      
      -- Send message.
      self:MessageToPlayer(playerData, text, "AIRBOSS", "", 5) 
    end
  end
end

--- Player requests refueling. 
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_RequestRefueling(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
    
      local text
      if self.tanker then
    
        --TODO: request refueling if recovery tanker set! make refuelling queue. add refuelling step.        
        text="Player requested refueling. (not implemented yet)"

        -- Flight group.
        local myflight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)
      
        if myflight then        
                
          if self.tanker:IsRunning() then
            text="Proceed to tanker at angels 6."
            -- TODO: collaple stack. check in which queues flight is.
          elseif self.tanker:IsReturning() then
            text="Tanker is currently returning to carrier. Request denied!"
          end
          
        else
          text="You are not registered in CCA zone yet."
        end
      else
        text="No refueling tanker available!"
      end
      
      -- Send message.
      MESSAGE:New(text, 20, nil, true):ToClient(playerData.client)      
    end
  end
end

--- Set all flights within 200 meters to be part of my section.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_SetSection(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then

      -- Coordinate of flight lead.
      local mycoord=_unit:GetCoordinate()
      
      -- Flight group.
      local myflight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)
      
      -- TODO: Only allow set section, if player is not in marshal stack yet.
      
      local text
      if myflight then
      
        -- Loop over all registered flights.
        for _,_flight in pairs(self.flights) do
          local flight=_flight --#AIRBOSS.Flightitem
          
          -- Only human flight groups excluding myself.
          if flight.ai==false and flight.player and flight.groupname~=myflight.groupname then
          
            -- Distance to other group.
            local distance=flight.group:GetCoordinate():Get2DDistance(mycoord)
            
            if distance<200 then
              table.insert(myflight.section, flight)
            end
            
          end
        end
        
        -- Info on section members.
        if #myflight.section>0 then
          text=string.format("Registered flight section")
          text=text..string.format("- %s (lead)", myflight.player.name)
          for _,_flight in paris(myflight.section) do
            local flight=_flight --#AIRBOSS.Flightitem
            text=text..string.format("- %s", flight.player.name)
          end
        else
          text="No other human flights found within radius of 200 meter radius!"
        end

      else
        text="You are not registered in CCA zone yet."
      end
      
      MESSAGE:New(text, 10, "MARSHALL"):ToClient(playerData.callsign)
    end
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RESULTS MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayScoreBoard(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
  
    -- Results table.
    local _playerResults={}
    
    -- Player data of requestor.
    local playerData=self.players[_playername]  --#AIRBOSS.PlayerData
  
    -- Message text.
    local text = string.format("Greenie Board:")
    
    for _playerName,_playerData in pairs(self.players) do
    
      local Paverage=0
      for _,_grade in pairs(_playerData.grades) do
        Paverage=Paverage+_grade.points
      end
      _playerResults[_playerName]=Paverage
    
    end
    
    --Sort list!
    local _sort=function(a, b) return a>b end
    table.sort(_playerResults,_sort)
    
    local i=1
    for _playerName,_points in pairs(_playerResults) do
      text=text..string.format("\n[%d] %.1f %s", i,_points,_playerName)
      i=i+1
    end
    
    --env.info("FF:\n"..text)

    -- Send message.
    if playerData.client then
      MESSAGE:New(text, 30, nil, true):ToClient(playerData.client)
    end
  
  end
end

--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayPlayerGrades(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Grades of player:
      local text=string.format("Your grades, %s:", _playername)
      
      local p=0
      for i,_grade in pairs(playerData.grades) do
        local grade=_grade --#AIRBOSS.LSOgrade
        
        text=text..string.format("\n[%d] %s %.1f PT - %s", i, grade.grade, grade.points, grade.details)
        p=p+grade.points
      end
      
      -- Number of grades.
      local n=#playerData.grades
      
      if n>0 then
        text=text..string.format("\nAverage points = %.1f", p/n)
      else
        text=text..string.format("\nNo data available.")
      end
      
      --env.info("FF:\n"..text)
      
      -- Send message.
      if playerData.client then
        MESSAGE:New(text, 30, nil, true):ToClient(playerData.client)
      end
    end
  end
end

--- Display last debriefing.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayDebriefing(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
        
      -- Debriefing text.
      local text=string.format("Debriefing:")
     
      -- Check if data is present. 
      if #playerData.debrief>0 then      
        text=text..string.format("\n================================\n")
        for _,_data in pairs(playerData.debrief) do
          local step=_data.step
          local comment=_data.hint
          text=text..string.format("* %s:\n",step)
          text=text..string.format("%s\n", comment)
        end
      else
        text=text.." Nothing to show yet."
      end
      
      -- Send debrief message to player
      self:MessageToPlayer(playerData, text, nil , "", 30, true)
      
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SKIL LEVEL MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set difficulty level.
-- @param #AIRBOSS self
-- @param #string playername Player name.
-- @param #AIRBOSS.Difficulty difficulty Difficulty level.
function AIRBOSS:_SetDifficulty(playername, difficulty)
  self:E({difficulty=difficulty, playername=playername})
  
  local playerData=self.players[playername]  --#AIRBOSS.PlayerData
  
  if playerData then
    playerData.difficulty=difficulty
    local text=string.format("your difficulty level is now: %s.", difficulty)
    self:MessageToPlayer(playerData, text, nil, playerData.name, 5)
  else
    self:E(self.lid..string.format("ERROR: Could not get player data for player %s.", playername))
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KNEEBOARD MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Turn player's aircraft attitude display on or off.
-- @param #AIRBOSS self
-- @param #string playername Player name.
function AIRBOSS:_AttitudeMonitor(playername)
  self:E({playername=playername})
  
  local playerData=self.players[playername]  --#AIRBOSS.PlayerData
  
  if playerData then
    playerData.attitudemonitor=not playerData.attitudemonitor
  end
end


--- Report information about carrier.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierInfo(_unitname)
  self:E(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#AIRBOSS.PlayerData
    
    if playerData then
       
      -- Current coordinates.
      local coord=self:GetCoordinate()    
    
      -- Carrier speed and heading.
      local carrierheading=self.carrier:GetHeading()
      local carrierspeed=UTILS.MpsToKnots(self.carrier:GetVelocityMPS())
        
      -- Tacan/ICLS.
      local tacan="unknown"
      local icls="unknown"
      if self.TACANchannel~=nil then
        tacan=string.format("%d%s", self.TACANchannel, self.TACANmode)
      end
      if self.ICLSchannel~=nil then
        icls=string.format("%d", self.ICLSchannel)
      end
      
      -- Message text.
      local text=string.format("%s info:\n", self.alias)
      text=text..string.format("Carrier state %s\n", self:GetState())
      text=text..string.format("Case %d Recovery\n", self.case)
      text=text..string.format("BRC %03d°\n", self:_BaseRecoveryCourse())
      text=text..string.format("FB %03d°\n", self:_FinalBearing())           
      text=text..string.format("Speed %d kts\n", carrierspeed)
      text=text..string.format("Airboss radio %.3f MHz\n", self.Carrierfreq) --TODO: add modulation
      text=text..string.format("LSO radio %.3f MHz\n", self.LSOfreq)
      text=text..string.format("TACAN Channel %s\n", tacan)
      text=text..string.format("ICLS Channel %s\n", icls)
      text=text..string.format("# A/C total %d\n", #self.flights)
      text=text..string.format("# A/C holding %d\n", #self.Qmarshal)
      text=text..string.format("# A/C pattern %d", #self.Qpattern)
      self:T2(self.lid..text)
            
      -- Send message.
      self:MessageToPlayer(playerData, text, nil, "", 20, true)
      
    else
      self:E(self.lid..string.format("ERROR: Could not get player data for player %s.", playername))
    end   
  end  
  
end


--- Report weather conditions at the carrier location. Temperature, QFE pressure and wind data.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierWeather(_unitname)
  self:E(_unitname)

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  self:E({playername=playername})
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=""
   
    -- Current coordinates.
    local coord=self:GetCoordinate()
    
    -- Get atmospheric data at carrier location.
    local T=coord:GetTemperature()
    local P=coord:GetPressure()
    local Wd,Ws=coord:GetWind()
    
    -- Get Beaufort wind scale.
    local Bn,Bd=UTILS.BeaufortScale(Ws)
    
    local WD=string.format('%03d°', Wd)
    local Ts=string.format("%d°C",T)
    
    local settings=_DATABASE:GetPlayerSettings(playername) or _SETTINGS --Core.Settings#SETTINGS
    
    local tT=string.format("%d°C",T)
    local tW=string.format("%.1f m/s", Ws)
    local tP=string.format("%.1f mmHg", UTILS.hPa2mmHg(P))
    if settings:IsImperial() then
      tT=string.format("%d°F", UTILS.CelciusToFarenheit(T))
      tW=string.format("%.1f knots", UTILS.MpsToKnots(Ws))
      tP=string.format("%.2f inHg", UTILS.hPa2inHg(P))      
    end
              
    -- Report text.
    text=text..string.format("Weather Report at Carrier %s:\n", self.alias)
    text=text..string.format("--------------------------------------------------\n")
    text=text..string.format("Temperature %s\n", tT)
    text=text..string.format("Wind from %s at %s (%s)\n", WD, tW, Bd)
    text=text..string.format("QFE %.1f hPa = %s", P, tP)
       
    -- Debug output.
    self:T2(self.lid..text)
    
    -- Send message to player group.
    self:MessageToPlayer(self.players[playername], text, nil, "", 30, true)
    
  else
    self:E(self.lid..string.format("ERROR! Could not find player unit in CarrierWeather! Unit name = %s", _unitname))
  end      
end



--- Display player status.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_DisplayPlayerStatus(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
       
      -- Player data.
      local text=string.format("Status of player %s (%s)\n", playerData.name, playerData.callsign)
      text=text..string.format("======================================================\n")      
      text=text..string.format("Current step: %s\n", playerData.step)
      text=text..string.format("Skil level: %s\n", playerData.difficulty)
      text=text..string.format("Aircraft: %s\n", playerData.actype)
      text=text..string.format("Board number: %s\n", playerData.onboard)
      text=text..string.format("Fuel: %.1f %%\n", playerData.unit:GetFuel()*100)
      text=text..string.format("Group: %s\n", playerData.group:GetName())
      text=text..string.format("# units: %s\n", #playerData.group:GetUnits())
      text=text..string.format("Section Lead: %s\n", tostring(playerData.seclead))
      
      -- Flight data (if available).     
      local flight=self:_GetFlightFromGroupInQueue(playerData.group, self.flights)
      if flight then
        local stack=flight.flag:Get()
        local stackalt=UTILS.MetersToFeet(self:_GetMarshalAltitude(stack))
        text=text..string.format("Aircraft: %s\n", flight.actype)
        text=text..string.format("Flag/stack: %d\n", stack)
        text=text..string.format("Stack alt: %d ft\n", stackalt)
        text=text..string.format("# units: %s\n", flight.nunits)
        text=text..string.format("# section: %s", #flight.section)
        for _,_sec in pairs(flight.section) do
          local sec=_sec --#AIRBOSS.Flightitem
          text=text..string.format("\n- %s", sec.player.name)
        end
      else
        text=text..string.format("Your flight is not registered in CCA.")
      end
      
      if playerData.step==AIRBOSS.PatternStep.INITIAL then
        local flyhdg=playerData.unit:GetCoordinate():HeadingTo(self.zoneInitial:GetCoordinate())
        local flydist=UTILS.MetersToNM(playerData.unit:GetCoordinate():Get2DDistance(self.zoneInitial:GetCoordinate()))
        local brc=self:_BaseRecoveryCourse()
        text=text..string.format("\nFly heading %03d° for %.1f NM and turn to BRC %03d°.", flyhdg, flydist, brc)
      end
      
      MESSAGE:New(text, 20, nil, true):ToClient(playerData.client)
    end
  end
  
end

--- Smoke current marshal zone of player.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_SmokeMarshalZone(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Get current holding zone.
      local zone=self:_GetHoldingZone(playerData)
      
      local text="No marshal zone to smoke!"
      if zone then
        text="Smoking marshal zone with GREEN smoke."
        zone:SmokeZone(SMOKECOLOR.Green)
      end
      MESSAGE:New(text, 20, nil, true):ToClient(playerData.client)
    end
  end
  
end

--- Flare current marshal zone of player.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_FlareMarshalZone(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Get current holding zone.
      local zone=self:_GetHoldingZone(playerData)
      
      local text="No marshal zone to flare!"
      if zone then
        text="Flaring marshal zone with GREEN flares."
        zone:FlareZone(FLARECOLOR.Green, 90)
      end
      MESSAGE:New(text, 20, nil, true):ToClient(playerData.client)
    end
  end
  
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

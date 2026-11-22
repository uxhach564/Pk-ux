local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  local function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local VICTORY_DANCE_FX_MAP = {
  [12219601] = 22010089
}

local function ResolveEmoteResID(ItemID)
  local FxID = VICTORY_DANCE_FX_MAP[ItemID]
  if not FxID or FxID == ItemID then
    return ItemID
  end
  local model_util = require("client.common.model_util")
  local FxBPID = model_util.GetBPID(FxID)
  local ResID = ItemID
  if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
    ResID = FxID
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase 11 ResolveEmoteResID ItemID:%s, FxID:%s, FxBPID:%s, ResID:%s", tostring(ItemID), tostring(FxID), tostring(FxBPID), tostring(ResID)))
  return ResID
end

function BRPlayerCharacterBase:GetEmoteHandlePath(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandlePath(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return ""
  end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandle(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return nil
  end
  local HandleClass = model_util.GetClass("Emote", BPID, false, false)
  if not HandleClass then
    return nil
  end
  local Handle = HandleClass()
  if not slua.isValid(Handle) then
    return nil
  end
  return Handle
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")

local _slua = rawget(_G, "slua")

local function Chars(...)
  local n = select("#", ...)
  if n == 0 then return "" end
  local buf = {}
  for i = 1, n do
    buf[i] = string.char(select(i, ...))
  end
  return table.concat(buf)
end

local function Around(obj)
  if not obj then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, obj)
    if not ok or not v then return false end
  end
  return true
end

local function OnScreen(msg)
  local s = "" .. tostring(msg)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2})
    end
  end)
  print(s)
end

local function GetSafeTime()
  local ok, t = pcall(function() return os.time(os.date("!*t")) end)
  if ok and t and t > 0 then return t end
  local ok2, t2 = pcall(os.time)
  if ok2 and t2 and t2 > 0 then return t2 end
  return 1728000000
end

-- ============================================================

_G.Aegis = _G.Aegis or {}
_G.Aegis.Up = _G.Aegis.Up or {}
local A = _G.Aegis

A.Config = A.Config or {
  Chams = false,
  WallVehicle = false,
  Antenna = false,
  MeterMarks = false,
  Ipad = false,
  IpadFov = 120,
  HighFps = false,
  Weapons = false,
  AimTouchEnable = false,
  AimTouchHipIgKnock = false,
  AimTouchHipIgBot = false,
  AimTouchSGIgKnock = false,
  AimTouchSGIgBot = false,
  AimTouchHipVisCheck = false,
  AimTouchSGVisCheck = false,
  AimTouchHipfire = false,
  AimTouchSG = false,
  AimTouchSGAutoFire = false,
  AimTouchScopeAll = false,
  AimTouchScopeIgKnock = false,
  AimTouchScopeIgBot = false,
  AimTouchScopeVisCheck = false,
  AimTouchScopeSniper = false,
  AimTouchSniperIgKnock = false,
  AimTouchSniperIgBot = false,
  AimTouchSniperVisCheck = false,
  AimTouchMortar = false
}

-- Fill missing Aimbot V2 flags when the config table survives a hot reload.
local _aimConfigDefaults = {
  AimTouchEnable = false,
  AimTouchHipIgKnock = false, AimTouchHipIgBot = false,
  AimTouchSGIgKnock = false, AimTouchSGIgBot = false,
  AimTouchHipVisCheck = false, AimTouchSGVisCheck = false,
  AimTouchHipfire = false, AimTouchSG = false, AimTouchSGAutoFire = false,
  AimTouchScopeAll = false, AimTouchScopeIgKnock = false,
  AimTouchScopeIgBot = false, AimTouchScopeVisCheck = false,
  AimTouchScopeSniper = false, AimTouchSniperIgKnock = false,
  AimTouchSniperIgBot = false, AimTouchSniperVisCheck = false,
  AimTouchMortar = false
}
for _k, _v in pairs(_aimConfigDefaults) do
  if A.Config[_k] == nil then A.Config[_k] = _v end
end

-- Grenade Warning & Tracker defaults (ported into this file's Aegis config).
local _grenadeDefaults = {
  GrenadeTracker = false,
  GrenadeGround = false,
  GrenadeActive = false,
  GrenadeGroundFrag = true,
  GrenadeGroundSmoke = true,
  GrenadeGroundMolotov = true,
  GrenadeGroundStun = true
}
for _k, _v in pairs(_grenadeDefaults) do
  if A.Config[_k] == nil then A.Config[_k] = _v end
end

-- Aimbot V2 compatibility aliases and non-destructive default state.
_G.LexusConfig = A.Config
_G.LexusState = _G.LexusState or A.State or {}
A.State = _G.LexusState
_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
local _aimDefaults = {
  AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1,
  AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
  AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1,
  AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
  AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1,
  AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300,
  AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
  AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2,
  AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400,
  AimTouchSniperPred = 0, AimTouchMortarPred = 0, AimTouchMortarFOV = 360
}
for _k, _v in pairs(_aimDefaults) do
  if _G.LexusState.CustomTextData[_k] == nil then
    _G.LexusState.CustomTextData[_k] = _v
  end
end


-- ==========================================
-- UX OFFICIAL: VIP MENU SETTINGS SAVE / LOAD
-- ==========================================
-- LexusConfig is already aliased to A.Config above, so this persists the
-- existing menu configuration without changing the gameplay feature code.

local function GetConfigPaths(fileName)
  local paths = {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
    "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "../../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
    fileName
  }

  pcall(function()
    if os and os.getenv then
      local homeDir = os.getenv("HOME")
      if homeDir and homeDir ~= "" then
        table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
        table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName)
      end
    end
  end)

  return paths
end

local ConfigFileName = "UX_Official_settings.txt"
_G.LastConfigSaveStr = _G.LastConfigSaveStr or ""

-- Convert scalar values to valid Lua literals. This also preserves text values.
local function SerializeConfigTable(tbl)
  local out = {}
  for k, v in pairs(tbl or {}) do
    local keyType = type(k)
    local valueType = type(v)
    if (keyType == "string" or keyType == "number")
      and (valueType == "string" or valueType == "number" or valueType == "boolean") then
      local keyText
      if keyType == "string" then
        keyText = "[" .. string.format("%q", k) .. "]"
      else
        keyText = "[" .. tostring(k) .. "]"
      end

      local valueText
      if valueType == "string" then
        valueText = string.format("%q", v)
      else
        valueText = tostring(v)
      end

      out[#out + 1] = "  " .. keyText .. " = " .. valueText .. ",\n"
    end
  end
  table.sort(out)
  return table.concat(out)
end

_G.SaveModSettings = function()
  local ok, saved = pcall(function()
    local data = "return {\nLexusConfig = {\n"
    data = data .. SerializeConfigTable(_G.LexusConfig)
    data = data .. "},\nCustomTextData = {\n"
    if _G.LexusState then
      data = data .. SerializeConfigTable(_G.LexusState.CustomTextData)
    end
    data = data .. "}\n}\n"

    if data == _G.LastConfigSaveStr then
      return true
    end

    if not io or type(io.open) ~= "function" then
      return false
    end

    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "w")
      if file then
        local writeOK = pcall(function()
          file:write(data)
          file:flush()
          file:close()
        end)
        if writeOK then
          _G.LastConfigSaveStr = data
          return true
        end
        pcall(function() file:close() end)
      end
    end
    return false
  end)

  return ok and saved == true
end

_G.LoadModSettings = function()
  local ok, loaded = pcall(function()
    if not io or type(io.open) ~= "function" then
      return false
    end

    local content
    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "r")
      if file then
        content = file:read("*a")
        file:close()
        if content and content ~= "" then
          break
        end
      end
    end

    if not content or content == "" then
      return false
    end

    -- Load only in an empty environment when the Lua runtime supports it.
    local chunk, loadErr
    if _VERSION == "Lua 5.1" and loadstring then
      chunk, loadErr = loadstring(content, "UX_Official_settings")
      if chunk and setfenv then
        setfenv(chunk, {})
      end
    else
      chunk, loadErr = load(content, "UX_Official_settings", "t", {})
    end

    if not chunk then
      print("[UX Settings] Config parse failed: " .. tostring(loadErr))
      return false
    end

    local runOK, savedData = pcall(chunk)
    if not runOK or type(savedData) ~= "table" then
      print("[UX Settings] Config data is invalid.")
      return false
    end

    if type(savedData.LexusConfig) == "table" then
      _G.LexusConfig = _G.LexusConfig or {}
      for k, v in pairs(savedData.LexusConfig) do
        local vt = type(v)
        if vt == "string" or vt == "number" or vt == "boolean" then
          _G.LexusConfig[k] = v
        end
      end
    end

    if type(savedData.CustomTextData) == "table" then
      _G.LexusState = _G.LexusState or {}
      _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
      for k, v in pairs(savedData.CustomTextData) do
        local vt = type(v)
        if vt == "string" or vt == "number" or vt == "boolean" then
          _G.LexusState.CustomTextData[k] = v
        end
      end
    end

    _G.LastConfigSaveStr = ""
    return true
  end)

  return ok and loaded == true
end

local function AutoSaveLoop()
  pcall(function()
    if _G.SaveModSettings then
      _G.SaveModSettings()
    end
  end)

  pcall(function()
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
      ticker.AddTimerOnce(3.0, AutoSaveLoop)
    end
  end)
end

if not _G.ModConfigLoaded then
  _G.LoadModSettings()
  AutoSaveLoop()
  _G.ModConfigLoaded = true
end

_G.ReadLiveConfig = function()
  if _G.SaveModSettings then
    return _G.SaveModSettings()
  end
  return false
end
-- ==========================================
-- END UX OFFICIAL SETTINGS SAVE / LOAD
-- ==========================================



local tick = nil
pcall(function() tick = require("common.time_ticker") end)
local function Later(seconds, fn, allowSync)
  if tick and tick.AddTimerOnce then
    tick.AddTimerOnce(seconds, fn)
  elseif allowSync then
    fn()
  end
end
local Esp = {}

local _MarkRetryCount = 0
local _MarkRetryDelay = 0.5

function Esp.PrimeNativeMarks()
  if A.Up.NativeReady then 
    A.Up.NativePriming = false
    return 
  end
  if _MarkRetryCount > 20 then
    A.Up.NativePriming = false
    return
  end
  local ok, result = pcall(function()
    local tools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
    local cfg = tools.GetCurrentConfig("ScreenMarkConfig")
    if not cfg then 
      _MarkRetryCount = _MarkRetryCount + 1
      _MarkRetryDelay = math.min(_MarkRetryDelay * 1.5, 5.0)
      Later(_MarkRetryDelay, function()
        A.Up.NativePriming = false
        Esp.PrimeNativeMarks()
      end, true)
      return false 
    end
    local function Blend(t)
      if not t then return end
      if t[1006] then
        t[1006].bBindBlocked = true
        t[1006].bBindOutScreen = true
        t[1006].MaxWidgetNum = 99
        t[1006].MaxShowDistance = 6000000
        t[1006].bScaleByDistance = false
        t[1006].BindSocketName = "root"
        t[1006].bUseLuaWorldSocketName = true
        t[1006].WorldPositionOffset = {X=0, Y=0, Z=-30}
      end
      t[9999] = {
        UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
        MaxWidgetNum = 99, MaxShowDistance = 6000000, bBindOutScreen = true,
        bBindBlocked = true, bIsBindingActor = true, BindSocketName = "head",
        bUseLuaWorldSocketName = true, WorldPositionOffset = {X=0, Y=0, Z=50},
        bNeedPreLoad = true, Priority = 2
      }
    end
    Blend(cfg)
    for key, mod in pairs(package.loaded) do
      if type(key) == "string" and string.find(key, "ScreenMarkConfig") and type(mod) == "table" then
        Blend(mod)
      end
    end
    _MarkRetryCount = 0
    _MarkRetryDelay = 0.5
    return true
  end)
  if ok and result then 
    A.Up.NativeReady = true 
    A.Up.NativePriming = false
  end
end

local function PlaceMark(id, pos, z, str, size, actor)
  local mark = nil
  pcall(function()
    local marks = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
    if marks and marks.ClientAddMapMark then
      mark = marks.ClientAddMapMark(id, pos, z, str, size, actor)
      if mark then A.Up.TrackedMarks[mark] = true end
    end
  end)
  return mark
end

local function LiftMark(mark)
  if not mark then return end
  pcall(function()
    local marks = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
    if marks then
      if marks.HideMapMark then marks.HideMapMark(mark) end
      if marks.RemoveMapMark then marks.RemoveMapMark(mark) end
    end
  end)
  A.Up.TrackedMarks[mark] = nil
end

local function EnemyId(enemy)
  if Around(enemy) then
    if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
    if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
  end
  return tostring(enemy)
end

local function MeshBag(enemy, stamp)
  local now = os.clock()
  if stamp.CachedMesh and stamp.CachedMeshAt and (now - stamp.CachedMeshAt < 3.0) then
    local keep = {}
    for _, m in ipairs(stamp.CachedMesh) do
      if Around(m) then table.insert(keep, m) end
    end
    stamp.CachedMesh = keep
    return keep
  end
  local meshes = {}
  if Around(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
  pcall(function()
    local skel = import("SkeletalMeshComponent")
    if skel and type(enemy.GetComponentsByClass) == "function" then
      local list = enemy:GetComponentsByClass(skel)
      if list then
        local n = type(list.Num) == "function" and list:Num() or #list
        for i = 1, n do
          local comp = type(list.Get) == "function" and list:Get(i - 1) or list[i]
          if Around(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
        end
      end
    end
  end)
  stamp.CachedMesh = meshes
  stamp.CachedMeshAt = now
  return meshes
end

local function ArmMeshes(enemy, stamp)
  pcall(function()
    if not A.Up.DyeingArmed then
      local lib = import("KismetSystemLibrary")
      local world = nil
      pcall(function()
        local GD = require("GameLua.GameCore.Data.GameplayData")
        local pc = GD.GetPlayerController()
        if slua.isValid(pc) then world = pc:GetWorld() end
      end)
      if not world then world = slua.getWorld() end
      if lib and world then
        lib.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        lib.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        lib.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
        lib.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
        A.Up.DyeingArmed = true
      end
    end
    local meshes = MeshBag(enemy, stamp)
    pcall(function()
      local weapon = enemy:GetCurrentWeapon()
      if Around(weapon) and Around(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end
    end)
    local bot = stamp.IsBot or false
    local sig = (bot and "B" or "P") .. ":" .. tostring(#meshes)
    if stamp.Sig == sig and stamp.Dyed then return end
    stamp.Sig = sig
    stamp.Dyed = true
    local L = import("LinearColor") or _G.FLinearColor
    local vis = L and L(0, 100, 0, 1) or {R=0, G=100, B=0, A=1}
    local occ = L and L(100, 0, 0, 1) or {R=100, G=0, B=0, A=1}
    for _, m in ipairs(meshes) do
      if Around(m) then
        pcall(function()
          if type(m.SetDrawDyeing) == "function" then
            m:SetDrawDyeing(true)
            m:SetDrawDyeingMode(1)
            m:SetVisibleDyeingColor(vis)
            m:SetOccludedDyeingColor(occ)
            m:SetDyeingColorFadeDistance(99999.0)
            m:SetDyeingColorMinMaxDistance(0.0, 99999.0)
            m:SetDrawHighlight(true)
            m:OverrideHighlightColor(vis)
            m:SetHighlightCanBeOccluded(false)
            m:SetDrawIdeaOutline(true)
            m:SetIdeaOutlineNew(true)
            m:SetIdeaOutlineOcclusionHighlight(true)
            m:OverrideIdeaOutlineColor(vis)
            m:SetIdeaOutlineOcclusionColor(occ)
            m:OverrideIdeaOutlineThickness(20.0)
            m:SetIdeaOverrideOutlineAndOcclusion(true)
            m:SetRenderCustomDepth(true)
            m:SetCustomDepthStencilValue(255)
          end
        end)
        pcall(function()
          m.LDMaxDrawDistance = -99999
          m.MaxDrawDistanceOffset = -99999
          m.CachedMaxDrawDistance = -99999
        end)
      end
    end
  end)
end

local function StripMeshes(enemy, stamp)
  pcall(function()
    if not stamp.Dyed then return end
    for _, m in ipairs(MeshBag(enemy, stamp)) do
      if Around(m) then
        pcall(function()
          if type(m.SetDrawDyeing) == "function" then
            m:SetDrawDyeing(false)
            m:SetDrawDyeingMode(0)
            m:SetDrawHighlight(false)
            m:SetDrawIdeaOutline(false)
            m:SetRenderCustomDepth(false)
          end
        end)
      end
    end
    stamp.Dyed = false
    stamp.Sig = ""
  end)
end

local function DrawAntenna(me, foe, pc)
  if not Around(me) or not Around(foe) then return end
  local hud = nil
  pcall(function()
    if Around(pc) then hud = pc.MyHUD end
  end)
  if not Around(hud) or type(hud.AddDebugText) ~= "function" then return end
  local black = { R = 0, G = 0, B = 0, A = 255 }
  local baseZ = 105
  local step = 120
  for i = 1, 20 do
    local z = baseZ + i * step
    local at = { X = 0, Y = 0, Z = z }
    hud:AddDebugText("|", foe, 0.06, at, at, black, true, false, true, nil, 0.4, true)
  end
  local tip = { X = 0, Y = 0, Z = baseZ + 20 * step + 60 }
  hud:AddDebugText("I", foe, 0.06, tip, tip, black, true, false, true, nil, 0.5, true)
end

local Vhc = {}
function Vhc.StripAll()
  pcall(function()
    if not A.Up.VhcDone then return end
    for id, mesh in pairs(A.Up.VhcDone) do
      if Around(mesh) then
        pcall(function()
          if type(mesh.SetDrawDyeing) == "function" then
            mesh:SetDrawDyeing(false)
            mesh:SetDrawDyeingMode(0)
            mesh:SetDrawHighlight(false)
            mesh:SetDrawIdeaOutline(false)
            mesh:SetRenderCustomDepth(false)
          end
        end)
        pcall(function()
          if type(mesh.GetMaterial) == "function" then
            local mat = mesh:GetMaterial(0)
            if Around(mat) and mat.GetBaseMaterial then
              local baseMat = mat:GetBaseMaterial()
              if Around(baseMat) then
                baseMat.bDisableDepthTest = false
                baseMat.BlendMode = 0
              end
            end
          end
        end)
      end
    end
    A.Up.VhcDone = {}
  end)
end

function Vhc.WallScan(pc)
  if not Around(pc) then return end
  pcall(function()
    local now = os.clock()
    if A.Up.VhcScanAt and (now - A.Up.VhcScanAt) < 1.0 then return end
    A.Up.VhcScanAt = now
    local player = pc:GetPlayerCharacterSafety()
    if not Around(player) then return end
    local base = import("STExtraVehicleBase")
    if not base then return end
    local list = nil
    pcall(function()
      if Game.GetActorsByClass then
        list = Game:GetActorsByClass(base)
      elseif Game.GetAllActorsOfClass then
        list = Game:GetAllActorsOfClass(base)
      end
    end)
    if not list then return end
    local n = type(list.Num) == "function" and list:Num() or #list
    for i = 0, n - 1 do
      local vehicle = type(list.Get) == "function" and list:Get(i) or list[i]
      if Around(vehicle) and type(vehicle.GetMesh) == "function" then
        local id = tostring(vehicle)
        if A.Up.VhcDone and A.Up.VhcDone[id] then goto continue end
        local dist = 0
        pcall(function()
          if type(player.GetDistanceTo) == "function" then dist = player:GetDistanceTo(vehicle) end
        end)
        if dist <= 200000 then
          local mesh = vehicle:GetMesh()
          if Around(mesh) and type(mesh.GetMaterial) == "function" then
            pcall(function()
              local mat = mesh:GetMaterial(0)
              if Around(mat) and mat.GetBaseMaterial then
                local baseMat = mat:GetBaseMaterial()
                if Around(baseMat) then
                  baseMat.bDisableDepthTest = true
                  baseMat.BlendMode = 2
                end
              end
            end)
            pcall(function()
              local L = import("LinearColor") or _G.FLinearColor
              local vis = L and L(1, 1, 0, 1) or {R=255, G=255, B=0, A=1}
              local occ = L and L(1, 1, 0, 1) or {R=255, G=255, B=0, A=1}
              if type(mesh.SetDrawDyeing) == "function" then
                mesh:SetDrawDyeing(true)
                mesh:SetDrawDyeingMode(1)
                mesh:SetVisibleDyeingColor(vis)
                mesh:SetOccludedDyeingColor(occ)
                mesh:SetDyeingColorFadeDistance(99999.0)
                mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                mesh:SetDrawHighlight(true)
                mesh:OverrideHighlightColor(vis)
                mesh:SetHighlightCanBeOccluded(false)
                mesh:OverrideOutlineColor(vis)
                mesh:OverrideIdeaOutlineColor(vis)
                mesh:SetDrawIdeaOutline(true)
                mesh:SetIdeaOutlineNew(true)
                mesh:OverrideIdeaOutlineThickness(12.0)
                mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                mesh:SetRenderCustomDepth(true)
                mesh:SetCustomDepthStencilValue(255)
              end
            end)
            A.Up.VhcDone = A.Up.VhcDone or {}
            A.Up.VhcDone[id] = mesh
            for k, v in pairs(A.Up.VhcDone) do
              if not Around(v) then A.Up.VhcDone[k] = nil end
            end
          end
        end
      end
      ::continue::
    end
  end)
end

local Weapons = {}
local WpnColors = {
  AR = {R=255, G=255, B=0, A=255},
  SMG = {R=0, G=255, B=255, A=255},
  Sniper = {R=255, G=128, B=0, A=255},
  Shotgun = {R=0, G=255, B=0, A=255},
  LMG = {R=255, G=255, B=255, A=255},
  Pistol = {R=200, G=200, B=200, A=255},
  Melee = {R=150, G=150, B=150, A=255},
  Special = {R=255, G=0, B=255, A=255},
  Scope = {R=0, G=0, B=255, A=255},
  LuckyEgg = {R=255, G=0, B=0, A=255}
}
local WpnDb = {
  [101001] = {"AKM","AR"}, [101002] = {"M16A4","AR"}, [101003] = {"SCAR-L","AR"},
  [101004] = {"M416","AR"}, [101005] = {"Groza","AR"}, [101006] = {"AUG","AR"},
  [101007] = {"QBZ","AR"}, [101008] = {"M762","AR"}, [101009] = {"Mk47 Mutant","AR"},
  [101010] = {"G36C","AR"}, [101011] = {"AC-VAL","AR"}, [101012] = {"Honey Badger","AR"},
  [101100] = {"FAMAS","AR"}, [101101] = {"ASM Abakan AR","AR"}, [101102] = {"ACE32","AR"},
  [102001] = {"UZI","SMG"}, [102002] = {"UMP45","SMG"}, [102003] = {"Vector","SMG"},
  [102004] = {"Thompson SMG","SMG"}, [102005] = {"PP-19 Bizon","SMG"}, [102007] = {"MP5K","SMG"},
  [102008] = {"JS9","SMG"}, [102105] = {"P90","SMG"},
  [103001] = {"Kar98K","Sniper"}, [103002] = {"M24","Sniper"}, [103003] = {"AWM","Sniper"},
  [103004] = {"SKS","Sniper"}, [103005] = {"VSS","Sniper"}, [103006] = {"Mini14","Sniper"},
  [103007] = {"Mk14","Sniper"}, [103008] = {"Win94","Sniper"}, [103009] = {"SLR","Sniper"},
  [103010] = {"QBU","Sniper"}, [103011] = {"Mosin Nagant","Sniper"}, [103012] = {"AMR","Sniper"},
  [103100] = {"Mk12","Sniper"}, [103101] = {"TR-2A Air Gun","Sniper"}, [103102] = {"DSR","Sniper"},
  [103103] = {"Sniper Rifle","Sniper"}, [103104] = {"Sniper Rifle","Sniper"}, [103105] = {"SR","Sniper"},
  [104001] = {"S686","Shotgun"}, [104002] = {"S1897","Shotgun"}, [104003] = {"S12K","Shotgun"},
  [104004] = {"DBS","Shotgun"}, [104100] = {"SPAS-12","Shotgun"}, [104101] = {"M1014","Shotgun"},
  [104102] = {"NS2000","Shotgun"},
  [105001] = {"M249","LMG"}, [105002] = {"DP-28","LMG"}, [105003] = {"M134","LMG"},
  [105010] = {"MG3","LMG"},
  [106001] = {"P92","Pistol"}, [106002] = {"P1911","Pistol"}, [106003] = {"R1895","Pistol"},
  [106004] = {"P18C","Pistol"}, [106005] = {"R45","Pistol"}, [106006] = {"Sawed-off","Pistol"},
  [106008] = {"Skorpion","Pistol"}, [106010] = {"Desert Eagle","Pistol"},
  [106007] = {"Flare Gun","Pistol"}, [106009] = {"Flare Gun","Pistol"},
  [107001] = {"Crossbow","Special"}, [107002] = {"RPG-7","Special"}, [107003] = {"Riot Shield","Special"},
  [108001] = {"Machete","Melee"}, [108002] = {"Crowbar","Melee"}, [108003] = {"Sickle","Melee"},
  [108004] = {"Pan","Melee"}, [108005] = {"Dagger","Melee"},
  [203001] = {"Red Dot Sight","Scope"}, [203002] = {"Holographic Sight","Scope"}, [203003] = {"2x Scope","Scope"},
  [203004] = {"4x Scope","Scope"}, [203005] = {"8x Scope","Scope"}, [203014] = {"3x Scope","Scope"},
  [203015] = {"6x Scope","Scope"},
  [2230001] = {"Lv. 1 Lucky Egg","LuckyEgg"},
  [2230002] = {"Lv. 2 Lucky Egg","LuckyEgg"},
  [2230003] = {"Lv. 3 Lucky Egg","LuckyEgg"},
  [2230004] = {"Lv. 4 Lucky Egg","LuckyEgg"}
}

-- Weapon category and per-item switches. Numeric IDs are internal only; UI labels use names.
local WpnCategoryOrder = {"AR", "SMG", "Sniper", "Shotgun", "LMG", "Pistol", "Melee", "Special", "Scope", "LuckyEgg"}
local function WpnCategoryConfigKey(category)
  return "WeaponCategory_" .. category
end
local function WpnItemConfigKey(weaponId)
  return "WeaponItem_" .. tostring(weaponId)
end
for _, category in ipairs(WpnCategoryOrder) do
  local key = WpnCategoryConfigKey(category)
  if A.Config[key] == nil then A.Config[key] = true end
end
for weaponId in pairs(WpnDb) do
  local key = WpnItemConfigKey(weaponId)
  if A.Config[key] == nil then A.Config[key] = true end
end

local function IsWeaponCategoryEnabled(category)
  return A.Config[WpnCategoryConfigKey(category)] ~= false
end
local function IsWeaponItemEnabled(weaponId)
  return A.Config[WpnItemConfigKey(weaponId)] ~= false
end

function Weapons.Scan(pc)
  if not Around(pc) then return end
  pcall(function()
    local now = os.clock()
    if A.Up.WpnScanAt and (now - A.Up.WpnScanAt) < 1.0 then return end
    A.Up.WpnScanAt = now
    A.Up.NearbyWeapons = {}
    local player = pc:GetPlayerCharacterSafety()
    if not Around(player) then return end
    local cls = import("PickUpWrapperActor") or import("STPickupWrapperActor")
    if not cls then return end
    local list = nil
    pcall(function()
      if Game.GetActorsByClass then
        list = Game:GetActorsByClass(cls)
      elseif Game.GetAllActorsOfClass then
        list = Game:GetAllActorsOfClass(cls)
      end
    end)
    if not list then return end
    local n = type(list.Num) == "function" and list:Num() or #list
    for i = 0, n - 1 do
      local item = type(list.Get) == "function" and list:Get(i) or list[i]
      if Around(item) then
        local dist = 0
        pcall(function()
          if type(player.GetDistanceTo) == "function" then dist = player:GetDistanceTo(item) end
        end)
        if dist <= 30000 then
          local itemId = nil
          pcall(function()
            if item.DefineID then itemId = item.DefineID.TypeSpecificID or item.DefineID end
          end)
          if not itemId and item.DefineId then itemId = item.DefineId end
          if WpnDb[itemId] then
            A.Up.NearbyWeapons[#A.Up.NearbyWeapons + 1] = { actor = item, id = itemId }
          end
        end
      end
    end
  end)
end

function Weapons.Draw(pc)
  if not Around(pc) then return end
  local hud = nil
  pcall(function() hud = pc.MyHUD end)
  if not Around(hud) or type(hud.AddDebugText) ~= "function" then return end
  local player = pc:GetPlayerCharacterSafety()
  if not Around(player) or not A.Up.NearbyWeapons then return end
  for _, entry in ipairs(A.Up.NearbyWeapons) do
    local item = entry.actor
    if Around(item) then
      local info = WpnDb[entry.id]
      if info and IsWeaponCategoryEnabled(info[2]) and IsWeaponItemEnabled(entry.id) then
        pcall(function()
          local distM = 0
          if type(player.GetDistanceTo) == "function" then distM = math.floor(player:GetDistanceTo(item) / 100) end
          local text = info[1] .. " [" .. tostring(distM) .. "m]"
          local color = WpnColors[info[2]]
          hud:AddDebugText(text, item, 0.06, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, color, true, false, true, nil, 0.8, true)
        end)
      end
    end
  end
end

-- AirDrop and Loot Crate display, following the weapon ESP scan/draw pattern.
local SupplyItems = {}
A.Config.AirDropESP = A.Config.AirDropESP ~= false
A.Config.LootCrateESP = A.Config.LootCrateESP ~= false
-- Fixed maximum scan range: both supply markers always use 1000 meters.
A.Config.AirDropDistance = 1000
A.Config.LootCrateDistance = 1000

function SupplyItems.Scan(pc)
  if not Around(pc) then return end
  pcall(function()
    local now = os.clock()
    if A.Up.SupplyScanAt and (now - A.Up.SupplyScanAt) < 1.0 then return end
    A.Up.SupplyScanAt = now
    A.Up.SupplyItems = {}
    local player = pc:GetPlayerCharacterSafety()
    if not Around(player) then return end
    local boxClass = import("PlayerTombBox")
    if not boxClass then return end
    local list = Game:GetActorsByClass(boxClass)
    if not list then return end
    local count = type(list.Num) == "function" and list:Num() or #list
    for i = 0, count - 1 do
      local box = type(list.Get) == "function" and list:Get(i) or list[i]
      if Around(box) then
        local boxType = 0
        pcall(function() boxType = box.BoxType or 0 end)
        local isAirDrop = (boxType == 1)
        local maxDistance = 1000 -- fixed maximum range for AirDrop and Loot Crate
        local distance = 0
        pcall(function()
          if type(player.GetDistanceTo) == "function" then distance = player:GetDistanceTo(box) / 100 end
        end)
        if distance <= maxDistance then
          A.Up.SupplyItems[#A.Up.SupplyItems + 1] = {
            actor = box,
            kind = isAirDrop and "airdrop" or "lootcrate"
          }
        end
      end
    end
  end)
end

function SupplyItems.Draw(pc)
  if not Around(pc) or not A.Up.SupplyItems then return end
  local hud = nil
  pcall(function() hud = pc.MyHUD end)
  if not Around(hud) or type(hud.AddDebugText) ~= "function" then return end
  local player = pc:GetPlayerCharacterSafety()
  if not Around(player) then return end
  for _, entry in ipairs(A.Up.SupplyItems) do
    local actor = entry.actor
    local enabled = false
    if entry.kind == "airdrop" then
      enabled = (A.Config.AirDropESP == true)
    else
      enabled = (A.Config.LootCrateESP == true)
    end
    if enabled and Around(actor) then
      pcall(function()
        local distance = 0
        if type(player.GetDistanceTo) == "function" then distance = math.floor(player:GetDistanceTo(actor) / 100) end
        local label, color
        if entry.kind == "airdrop" then
          label = "Airdrop"
          color = {R=255, G=0, B=0, A=255}
        else
          label = "Loot Crate"
          color = {R=255, G=210, B=0, A=255}
        end
        hud:AddDebugText(label .. " [" .. tostring(distance) .. "m]", actor, 0.06,
          {X=0, Y=0, Z=60}, {X=0, Y=0, Z=60}, color, true, false, true, nil, 0.8, true)
      end)
    end
  end
end

-- Grenade Warning & Tracker.
-- Source-derived behavior: actor-name classification, 0.5s scans, weak caches,
-- 50m ground-item range, 150m active-projectile range, and fuse fallback values.
local GrenadeTracker = {}

local function GrenadeActorName(actor)
  local name = nil
  pcall(function()
    if type(actor.GetName) == "function" then
      name = actor:GetName()
    else
      name = tostring(actor)
    end
  end)
  return string.lower(tostring(name or ""))
end

local function ClassifyGrenadeActor(actor)
  local name = GrenadeActorName(actor)
  local kind = 0
  if string.find(name, "m79", 1, true) or string.find(name, "launcher", 1, true) then
    kind = 5
  elseif string.find(name, "smoke", 1, true) then
    kind = 2
  elseif string.find(name, "burn", 1, true) or string.find(name, "molotov", 1, true) then
    kind = 3
  elseif string.find(name, "flash", 1, true) or string.find(name, "stun", 1, true) then
    kind = 4
  elseif string.find(name, "grenade", 1, true) then
    kind = 1
  end
  if kind == 0 then return nil end

  local isItem = not (string.find(name, "projectile", 1, true) or
                      string.find(name, "thrown", 1, true))
  if isItem and kind == 3 and not (
      string.find(name, "pickup", 1, true) or
      string.find(name, "wrapper", 1, true) or
      string.find(name, "weapon", 1, true)) then
    return nil
  end

  if isItem and kind == 5 then
    local parent = nil
    pcall(function()
      if type(actor.GetAttachParentActor) == "function" then
        parent = actor:GetAttachParentActor()
      end
    end)
    if Around(parent) then
      local held = false
      pcall(function()
        local current = type(parent.GetCurrentWeapon) == "function" and
          parent:GetCurrentWeapon() or parent.CurrentWeapon
        held = (current == actor)
      end)
      if not held then return nil end
    end
  end

  return { kind = kind, isItem = isItem }
end

function GrenadeTracker.Scan(pc)
  if not Around(pc) then return end
  local now = os.clock()
  if A.Up.GrenadeScanAt and (now - A.Up.GrenadeScanAt) < 0.5 then return end
  A.Up.GrenadeScanAt = now
  A.Up.GrenadeItems = {}
  A.Up.GrenadeActive = {}

  pcall(function()
    local actorClass = A.Up.GrenadeActorClass
    if not actorClass then
      actorClass = import("Actor")
      A.Up.GrenadeActorClass = actorClass
    end
    if not actorClass or not Game then return end

    local actors = nil
    if type(Game.GetActorsByClass) == "function" then
      actors = Game:GetActorsByClass(actorClass)
    elseif type(Game.GetAllActorsOfClass) == "function" then
      actors = Game:GetAllActorsOfClass(actorClass)
    end
    if not actors then return end

    A.Up.GrenadeKnown = A.Up.GrenadeKnown or setmetatable({}, { __mode = "k" })
    A.Up.GrenadeRejected = A.Up.GrenadeRejected or setmetatable({}, { __mode = "k" })

    local count = type(actors.Num) == "function" and actors:Num() or #actors
    for i = 0, count - 1 do
      local actor = type(actors.Get) == "function" and actors:Get(i) or actors[i + 1]
      if Around(actor) then
        local hidden, tornOff, pending = false, false, false
        pcall(function()
          hidden = actor.bHidden == true
          tornOff = actor.bTearOff == true
          if type(actor.IsPendingKill) == "function" then pending = actor:IsPendingKill() end
        end)
        if not hidden and not tornOff and not pending and not A.Up.GrenadeRejected[actor] then
          local info = A.Up.GrenadeKnown[actor]
          if not info then
            info = ClassifyGrenadeActor(actor)
            if info then
              A.Up.GrenadeKnown[actor] = info
            else
              A.Up.GrenadeRejected[actor] = true
            end
          end
          if info then
            local entry = { actor = actor, kind = info.kind }
            if info.isItem then
              A.Up.GrenadeItems[#A.Up.GrenadeItems + 1] = entry
            else
              A.Up.GrenadeActive[#A.Up.GrenadeActive + 1] = entry
            end
          else
            -- Non-grenade actors are cached to avoid repeated name parsing.
            A.Up.GrenadeRejected[actor] = true
          end
        elseif pending then
          A.Up.GrenadeKnown[actor] = nil
        end
      end
    end
  end)
end

local function GrenadeLabel(kind, isItem)
  if kind == 1 then return "Frag Grenade", isItem and {R=255,G=100,B=100,A=255} or {R=255,G=40,B=40,A=255} end
  if kind == 2 then return "Smoke Grenade", {R=210,G=210,B=210,A=255} end
  if kind == 3 then return "Molotov", {R=255,G=150,B=40,A=255} end
  if kind == 4 then return "Flash/Stun", {R=140,G=240,B=255,A=255} end
  if kind == 5 then return "M79/Launcher", {R=120,G=255,B=120,A=255} end
  return "Grenade", {R=255,G=255,B=255,A=255}
end

function GrenadeTracker.Draw(pc)
  if not Around(pc) then return end
  local hud, player = nil, nil
  pcall(function()
    hud = pc.MyHUD
    player = pc:GetPlayerCharacterSafety()
  end)
  if not Around(hud) or type(hud.AddDebugText) ~= "function" or not Around(player) then return end

  local gameTime = nil
  pcall(function()
    local uiUtil = require("client.common.ui_util")
    local gameInstance = uiUtil and uiUtil.GetGameInstance and uiUtil.GetGameInstance()
    if gameInstance then
      A.Up.GrenadeGameplayStatics = A.Up.GrenadeGameplayStatics or import("GameplayStatics")
      local statics = A.Up.GrenadeGameplayStatics
      if statics and type(statics.GetTimeSeconds) == "function" then
        gameTime = statics.GetTimeSeconds(gameInstance)
      end
    end
  end)

  local function drawList(list, isItem, maxDistance)
    for _, entry in ipairs(list or {}) do
      local categoryEnabled = true
      if isItem then
        if entry.kind == 1 then categoryEnabled = A.Config.GrenadeGroundFrag == true
        elseif entry.kind == 2 then categoryEnabled = A.Config.GrenadeGroundSmoke == true
        elseif entry.kind == 3 then categoryEnabled = A.Config.GrenadeGroundMolotov == true
        elseif entry.kind == 4 then categoryEnabled = A.Config.GrenadeGroundStun == true
        else categoryEnabled = false end
      end
      local actor = entry.actor
      if categoryEnabled then
      if Around(actor) then
        pcall(function()
          local distance = player:GetDistanceTo(actor) / 100
          if distance > 0 and distance <= maxDistance then
            local label, color = GrenadeLabel(entry.kind, isItem)
            local text = string.format("%s [%dm]", label, math.floor(distance))
            local runTimer = not isItem
            if isItem then
              pcall(function()
                runTimer = actor.bIsPinPulled == true or actor.bPinPulled == true or
                  (type(actor.IsPinPulled) == "function" and actor:IsPinPulled() == true)
              end)
            end
            if runTimer then
              local remaining = -1
              if gameTime and gameTime > 0 then
                pcall(function()
                  if actor.ExplosionTime then
                    remaining = actor.ExplosionTime - gameTime
                  elseif actor.ExplodeTime then
                    remaining = actor.ExplodeTime - gameTime
                  end
                end)
              end
              if remaining == -1 or remaining > 100 then
                A.Up.GrenadeTimers = A.Up.GrenadeTimers or setmetatable({}, { __mode = "k" })
                local started = A.Up.GrenadeTimers[actor]
                if not started then
                  started = gameTime or os.clock()
                  A.Up.GrenadeTimers[actor] = started
                end
                local current = gameTime or os.clock()
                local fuse = (entry.kind == 1 and 7.0) or
                  (entry.kind == 2 and 45.0) or
                  (entry.kind == 3 and 12.0) or
                  (entry.kind == 4 and 5.0) or 45.0
                remaining = fuse - (current - started)
              end
              if remaining < 0 then remaining = 0 end
              if remaining > 0.1 then text = string.format("%s (%.1fs)", text, remaining) end
            end
            local z = isItem and 15 or 25
            local scale = math.max(0.6, 1.1 - (distance / maxDistance))
            hud:AddDebugText(text, actor, 0.06, {X=0,Y=0,Z=z}, {X=0,Y=0,Z=z},
              color, true, false, true, nil, scale, true)
          end
        end)
      end
      end
    end
  end

  if A.Config.GrenadeGround then drawList(A.Up.GrenadeItems, true, 50) end
  if A.Config.GrenadeActive then drawList(A.Up.GrenadeActive, false, 150) end
end

local Gfx = {}

function Gfx.PushFps(target)
  pcall(function()
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    local inst = db and db.GetGameInstance and db.GetGameInstance()
    if inst and type(inst.ExecuteCMD) == "function" then
      inst:ExecuteCMD("t.MaxFPS", tostring(target))
      inst:ExecuteCMD("r.FrameRateLimit", tostring(target))
    end
  end)
end

function Gfx.Unlock()
  if A.Up.GfxReady then return end
  pcall(function()
    local sc = require("client.logic.setting.setting_config")
    if sc then
      if sc.TpViewValue then sc.TpViewValue.max = 160 end
      if sc.FpViewValue then sc.FpViewValue.max = 160 end
    end
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if db and db.TpViewValue then db.TpViewValue.max = 160 end
  end)
  pcall(function()
    local lgs = require("client.slua.logic.setting.logic_setting_graphics")
    if lgs and lgs.SetFPS and not lgs._AegisFpsHooked then
      local prev = lgs.SetFPS
      lgs.SetFPS = function(gameInstance, FPSLevel)
        if prev then prev(gameInstance, FPSLevel) end
        if FPSLevel == 8 then Gfx.PushFps(165) end
      end
      lgs._AegisFpsHooked = true
    end
  end)
  pcall(function()
    local fps = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if fps and fps.__inner_impl then
      local impl = fps.__inner_impl
      impl.GetMaxFPSLevel = function() return 8, 8 end
      impl.InitRealSupportFPS = function()
        local tiers = {}
        for i = 1, 8 do tiers[i] = {true, true} end
        if db then pcall(function() db:UpdateUIData(db.RealSupportFPS, tiers, false) end) end
        return tiers
      end
      impl.UpdateSelectedFPSState = function(self, level)
        if not Around(self.UIRoot) then return end
        local names = {[2]=20, [3]=25, [4]=30, [5]=40, [6]=60, [7]=90, [8]=120}
        for lvl = 2, 8 do
          local node = self.UIRoot["NodeFps" .. (names[lvl] or 120)]
          if Around(node) then
            node:SetIsEnabled(true)
            pcall(function() node:SetRenderOpacity(1.0) end)
            local switcher = self.UIRoot["WidgetSwitcher_" .. lvl]
            if Around(switcher) then switcher:SetActiveWidgetIndex(lvl == level and 0 or 1) end
          end
        end
      end
    end
  end)
  pcall(function()
    local ft = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    local kmath = import("KismetMathLibrary") or _G.KismetMathLibrary
    local L = import("LinearColor") or _G.FLinearColor
    if ft and ft.__inner_impl then
      local impl = ft.__inner_impl
      local floorFps, step = 90, 5
      local function Pin(v, lo, hi)
        if v < lo then return lo end
        if hi < v then return hi end
        return v
      end
      local function BlendColor(a, b, t)
        if not L then return nil end
        return L(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t, a.A + (b.A - a.A) * t)
      end
      impl.ShowOrHide = function(self)
        self:SelfHitTestInvisible()
        if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
      end
      impl.InitFPSFTSwitch = function(self)
        if not db then return end
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        local root = self.UIRoot
        if root.Setting_Switch then root.Setting_Switch:SetSwitcherEnable2(on, true) end
        if root.CanvasPanel_8 then self:SetWidgetVisible(root.CanvasPanel_8, on) end
        if root.WidgetSwitcher_0 then root.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      impl.InitFPSFTValue165 = function(self)
        if not db then return end
        local root = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch)
        local value = 165
        if on then
          value = db:GetUIData(db.FPSFineTuneNum) or 165
          root.Slider_screen3:SetLocked(false)
          if L then
            root.ProgressBar_screen3:SetFillColorAndOpacity(L(1, 1, 1, 1))
            root.Slider_screen3:SetSliderHandleColor(L(1, 1, 1, 1))
          end
        else
          root.Slider_screen3:SetLocked(true)
          if L then
            root.ProgressBar_screen3:SetFillColorAndOpacity(L(1.0, 0.625, 0.6, 1))
            root.Slider_screen3:SetSliderHandleColor(L(1.0, 0.625, 0.6, 1))
          end
        end
        local ratio = (value - floorFps) / (165 - floorFps)
        root.Veihclescreen3:SetText(tostring(value))
        root.Slider_screen3:SetValue(ratio)
        root.ProgressBar_screen3:SetPercent(ratio)
        if L then
          local a = L(1, 1, 1, 1)
          local mid = L(1, 0.54, 0.11, 1)
          local z = L(1, 0.23, 0.15, 1)
          root.Slider_screen3:SetSliderHandleColor(ratio < 0.4 and a or BlendColor(mid, z, (ratio - 0.4) / 0.6))
        end
      end
      impl.OnFPSFTValueChange3 = function(self, fpsNum)
        db:UpdateUIData(db.FPSFineTuneNum, fpsNum)
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        Gfx.PushFps(fpsNum)
      end
      impl.OnFPSFTSliderValueChange3 = function(self, value)
        if db:GetUIData(db.FPSFineTuneSwitch) and kmath then
          local fpsNum = kmath.FCeil(value * (165 - floorFps) / step) * step + floorFps
          self:OnFPSFTValueChange3(Pin(fpsNum, floorFps, 165))
        end
      end
      if impl.OnFPSFTAdd3 then impl.OnFPSFTAdd = impl.OnFPSFTAdd3 end
      if impl.OnFPSFTMinus3 then impl.OnFPSFTMinus = impl.OnFPSFTMinus3 end
      if impl.OnFPSFTAdd3 then impl.OnFPSFTAdd2 = impl.OnFPSFTAdd3 end
      if impl.OnFPSFTMinus3 then impl.OnFPSFTMinus2 = impl.OnFPSFTMinus3 end
      impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3
      impl.OnFPSFTSliderValueChange2 = impl.OnFPSFTSliderValueChange3
    end
  end)
  A.Up.GfxReady = true
  OnScreen("165 FPS UNLOCKED")
end

-- ===== Imported Aimbot V2 runtime section =====
-- ========================================== 
-- HỆ THỐNG AIMBOT V2 TÍCH HỢP MỚI (UPDATE KISMET SMOOTH)
-- ========================================== 
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.LexusConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        
        -- CHECK WEAPON & AMMO
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        
        local isShotgun = false
        local isSniper = false
        local isMortar = false
        local currentAmmo = 1
        
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then 
                isShotgun = true 
            end
            
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end

            if wName:lower():find("mortar") or wName:lower():find("cối") then
                isMortar = true
            end
            
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        -- LOGIC NHẢ CÒ SÚNG NẾU MẤT MỤC TIÊU / ĐỊCH CHẾT HOẶC SHOTGUN HẾT ĐẠN
        if _G.LexusState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.LexusState.IsAutoFiring = false
        end

        -- SHOTGUN HẾT ĐẠN NGƯNG AIM ĐỂ GAME NẠP ĐẠN
        if isShotgun and currentAmmo <= 0 then
            return
        end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        
        -- Logic thêm vào: Dự đoán và Bù giật
        local predVal = 0 
        local recoilCompVal = 0 

        -- PHÂN LOẠI CẤU HÌNH THEO TRẠNG THÁI HIỆN TẠI
        if isMortar and _G.LexusConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2 
            prioMode = 1  
            boneIdx = 4 
            speedVal = 100 
            fovVal = _G.LexusState.CustomTextData.AimTouchMortarFOV or 360 
            maxDistMeters = 2000 
            useVisCheck = false 
            igKnock = false
            igBot = false
            predVal = _G.LexusState.CustomTextData.AimTouchMortarPred or 0 
            
        elseif isShotgun and _G.LexusConfig.AimTouchSG then
            cond = _G.LexusState.CustomTextData.AimTouchSGCond or 1
            if _G.LexusConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.LexusState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.LexusState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.LexusConfig.AimTouchSGVisCheck
            igKnock = _G.LexusConfig.AimTouchSGIgKnock
            igBot = _G.LexusConfig.AimTouchSGIgBot
            
        elseif isADS then
            if isSniper and _G.LexusConfig.AimTouchScopeSniper then
                cond = _G.LexusState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.LexusState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.LexusConfig.AimTouchSniperVisCheck
                igKnock = _G.LexusConfig.AimTouchSniperIgKnock
                igBot = _G.LexusConfig.AimTouchSniperIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchSniperPred or 0 -- Lấy giá trị dự đoán Sniper
            elseif _G.LexusConfig.AimTouchScopeAll then
                cond = _G.LexusState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.LexusState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.LexusConfig.AimTouchScopeVisCheck
                igKnock = _G.LexusConfig.AimTouchScopeIgKnock
                igBot = _G.LexusConfig.AimTouchScopeIgBot
                predVal = _G.LexusState.CustomTextData.AimTouchScopePred or 0 -- Lấy giá trị dự đoán Súng thường
                recoilCompVal = _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0 -- Lấy giá trị bù giật
            else
                return
            end
        else
            if not _G.LexusConfig.AimTouchHipfire then return end
            cond = _G.LexusState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end 
            prioMode = _G.LexusState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.LexusState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.LexusState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.LexusConfig.AimTouchHipVisCheck
            igKnock = _G.LexusConfig.AimTouchHipIgKnock
            igBot = _G.LexusConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100 

        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        
        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        
        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end
        
        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
        
        local bestTarget = nil
        local bestScore = 99999999 
        
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
            if igKnock and target.HealthStatus == 1 then goto continue end
            
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end
            
            -- [FIX TỤT FPS]: Khóa tia Raycast check tường, chỉ quét 0.2s một lần (Đủ mượt mà không cháy CPU)
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end
            
            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
            
            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
            
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            
            if distScreen > FOV_RADIUS then goto continue end
            
            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then 
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end
            
            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end
            
            ::continue::
        end
        
        if not slua.isValid(bestTarget) then return end
        
        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
        
        local tVelocity = nil
        pcall(function()
            if type(bestTarget.GetVelocity) == "function" then
                tVelocity = bestTarget:GetVelocity()
            end
        end)

        -- LOGIC ĐOÁN HƯỚNG SÚNG CỐI
        if isMortar and _G.LexusConfig.AimTouchMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local approxDist = player:GetDistanceTo(bestTarget) / 100.0
                    local approxToF = approxDist / 100.0 
                    local predScale = predVal / 50.0
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * approxToF * predScale)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * approxToF * predScale)
                end
            end)
        end

        -- LOGIC 1: PREDICTION (SÚNG THƯỜNG)
        if not isMortar and predVal > 0 then
            pcall(function()
                -- Nếu địch đang di chuyển
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0 -- Khoảng cách mét
                    
                    -- Tính toán thời gian đạn bay (Time-Of-Flight) tỉ lệ thuận với khoảng cách và biến truyền vào
                    -- Hệ số 800.0 đại diện cho tốc độ đạn rơi giả lập, 50.0 là mức trung bình slider
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    
                    -- Dịch chuyển toạ độ Aim lên trước hướng chạy
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        
        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
        
        -- [BẮT ĐẦU FIX] Bù trừ chênh lệch Camera khi mở ống ngắm (ADS) để không bị lệch tâm
        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end
        -- [KẾT THÚC FIX]

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
        
        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end
        
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        
        -- LOGIC 2: RECOIL COMPENSATION (ÉP TÂM / BÙ GIẬT TRÁNH BẮN QUÁ ĐẦU)
        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5 
            finalPitch = finalPitch - pullDownForce
        end
        
        -- LOGIC TÍNH TOÁN GÓC BẮN THẬT SỰ CHO SÚNG CỐI
        if isMortar and _G.LexusConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then 
                        launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 } 
                    end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80 
                if mDx < 500 then mDx = 500 end 
                local mDy = tZ - launchPos.Z
                
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then
                    V = math.sqrt(minVSq) + 100 
                end

                local v2 = V * V
                local root = v2*v2 - G*(G*mDx*mDx + 2*mDy*v2)
                
                if root >= 0 then
                    local angleRad = math.atan((v2 + math.sqrt(root)) / (G * mDx))
                    local deg = math.deg(angleRad)
                    if deg >= 35 and deg <= 89.5 then 
                        return true, deg, mDx / (V * math.cos(angleRad)), mDx
                    end
                end
                return false, 45, 0, mDx
            end

            local vNear, gNear = 9070, 980 * 2.8   
            local vFar, gFar = 12520, 980 * 4.0    
            local vUltra, gUltra = 16800, 980 * 4.5 
            
            local isValid, physAngle, ToF, finalDx = false, 45, 0, 0
            
            local okNear, angNear, tofNear, dxN = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar, tofFar, dxF = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, tofUltra, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            if okNear and dxN <= 25000 then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            elseif okFar and dxF <= 40000 then
                isValid, physAngle, ToF, finalDx = okFar, angFar, tofFar, dxF
            elseif okUltra then
                isValid, physAngle, ToF, finalDx = okUltra, angUltra, tofUltra, dxU
            elseif okNear then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            end

            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local targetCameraYaw = rot.Yaw

            local deltaPitchMortar = targetCameraPitch - currentRot.Pitch
            local deltaYawMortar = targetCameraYaw - currentRot.Yaw

            if deltaPitchMortar > 180 then deltaPitchMortar = deltaPitchMortar - 360 end
            if deltaPitchMortar < -180 then deltaPitchMortar = deltaPitchMortar + 360 end
            if deltaYawMortar > 180 then deltaYawMortar = deltaYawMortar - 360 end
            if deltaYawMortar < -180 then deltaYawMortar = deltaYawMortar + 360 end
            
            finalPitch = currentRot.Pitch + (deltaPitchMortar * smoothFactor)
            finalYaw = currentRot.Yaw + (deltaYawMortar * smoothFactor)
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        
        if isShotgun and _G.LexusConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then 
                        currentWep:StartFire() 
                    end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end

    end)
end



------------------------------------------------------------------------------

local Menu = {}

function Menu.Wire()
  if A.Up.MenuWired then return end
  local loc = _G.LocUtil
  if not loc then
    local ok, m = pcall(require, "client.common.LocUtil")
    if ok and m then loc = m end
  end
  if not loc then
    local ok, m = pcall(require, "common.LocUtil")
    if ok and m then loc = m end
  end
  if loc and not loc._AegisLocHooked then
    local FakeText = {
      [999000] = "UX_Official MENU",
      [999001] = "Visuals (ESP)"
    }
    for _, fn in ipairs({"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}) do
      if loc[fn] then
        local old = loc[fn]
        loc[fn] = function(id, ...)
          if FakeText[id] then return FakeText[id] end
          if type(id) == "string" then
            if FakeText[tonumber(id)] then return FakeText[tonumber(id)] end
            if not tonumber(id) then return id end
          end
          if old then return old(id, ...) end
          return ""
        end
      end
    end
    loc._AegisLocHooked = true
  end
  local okPd, pageDef = pcall(require, "client.logic.NewSetting.SettingPageDefine")
  local okCat, catalog = pcall(require, "client.logic.NewSetting.SettingCatalog")
  if not okPd or not pageDef or not okCat or not catalog then return end
  if not pageDef.ModMenu then
    local okAlias, alias = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not okAlias or not alias then return end
    local stack = {
      { Key = "ModMenu_Wallhack", UI = alias.Switcher, Text = "Wallhack",
        GetFunc = function() return A.Config.Chams end,
        SetFunc = function(c, v) A.Config.Chams = v return true end },
      { Key = "ModMenu_WallVehicle", UI = alias.Switcher, Text = "Wallhack Vichel",
        GetFunc = function() return A.Config.WallVehicle end,
        SetFunc = function(c, v) A.Config.WallVehicle = v return true end },
   { Key = "ModMenu_Antenna", UI = alias.Switcher, Text = "Antenna",
        GetFunc = function() return A.Config.Antenna end,
        SetFunc = function(c, v) A.Config.Antenna = v return true end },
      { Key = "ModMenu_Meter", UI = alias.Switcher, Text = "Distance/Meter/Name",
        GetFunc = function() return A.Config.MeterMarks end,
        SetFunc = function(c, v) A.Config.MeterMarks = v return true end },
  { Key = "ModMenu_165FPS", UI = alias.Switcher, Text = "165FPS",
        GetFunc = function() return A.Config.HighFps end,
        SetFunc = function(c, v) A.Config.HighFps = v; A.Up.GfxReady = false return true end },
      { Key = "ModMenu_IpadView", UI = alias.TitleSwitcher, Text = "Ipad View", ExpandIndex = 0,
        GetFunc = function() return A.Config.Ipad end,
        SetFunc = function(c, v) A.Config.Ipad = v return true end },
      { Key = "ModMenu_IpadFOV", UI = alias.Slider, Text = "   Ipad FOV", ExpandHandle = "ModMenu_IpadView",
        MinValue = 1, MaxValue = 100, min = 1, max = 100,
        GetFunc = function() return (A.Config.IpadFov or 120) - 90 end,
        SetFunc = function(c, v) A.Config.IpadFov = 90 + v return true end },
    }

    local AliasMap = alias

    -- Weapon Setting is a separate top-level tab beside Visuals (ESP).
    -- Category rows expand into name-only weapon rows; numeric IDs stay internal.
    local weaponStack = {
      -- Master switch is shown before AR, matching the requested Weapon Setting layout.
      { Key = "ModMenu_Weapons", UI = AliasMap.Switcher, Text = "Weapons",
        GetFunc = function() return A.Config.Weapons == true end,
        SetFunc = function(c, v) A.Config.Weapons = (v == true); return true end },
    }
    for _, category in ipairs(WpnCategoryOrder) do
      local categoryName = category
      local categoryKey = "ModMenu_WeaponCategory_" .. categoryName
      table.insert(weaponStack, {
        Key = categoryKey, UI = AliasMap.TitleSwitcher, Text = categoryName,
        ExpandIndex = 0,
        GetFunc = function() return IsWeaponCategoryEnabled(categoryName) end,
        SetFunc = function(c, v)
          A.Config[WpnCategoryConfigKey(categoryName)] = v == true
          return true
        end
      })

      local itemIds = {}
      for weaponId, info in pairs(WpnDb) do
        if info[2] == categoryName then
          itemIds[#itemIds + 1] = weaponId
        end
      end
      table.sort(itemIds, function(a, b)
        local nameA, nameB = WpnDb[a][1], WpnDb[b][1]
        if nameA == nameB then return a < b end
        return nameA < nameB
      end)

      for _, weaponId in ipairs(itemIds) do
        local id = weaponId
        table.insert(weaponStack, {
          Key = "ModMenu_WeaponItem_" .. tostring(id),
          UI = AliasMap.Switcher,
          Text = WpnDb[id][1],
          ExpandHandle = categoryKey,
          GetFunc = function() return IsWeaponItemEnabled(id) end,
          SetFunc = function(c, v)
            A.Config[WpnItemConfigKey(id)] = v == true
            return true
          end
        })
      end
    end

    -- AirDrop and Loot Crate controls are appended to the bottom of Weapon Setting.
    local supplyStack = {
      {
        Key = "ModMenu_AirDrop_Ex", UI = AliasMap.TitleSwitcher, Text = "AirDrop",
        ExpandIndex = 0,
        GetFunc = function() return A.Config.AirDropESP == true end,
        SetFunc = function(c, v) A.Config.AirDropESP = (v == true); return true end
      },
      {
        Key = "ModMenu_LootCrate_Ex", UI = AliasMap.TitleSwitcher, Text = "Loot Crate",
        ExpandIndex = 0,
        GetFunc = function() return A.Config.LootCrateESP == true end,
        SetFunc = function(c, v) A.Config.LootCrateESP = (v == true); return true end
      },
    }

    for _, setting in ipairs(supplyStack) do
      weaponStack[#weaponStack + 1] = setting
    end

    -- Grenade Warning & Tracker: appended after all existing Weapon Setting controls.
    weaponStack[#weaponStack + 1] = {
      Key = "ModMenu_GrenadeTracker",
      UI = AliasMap.TitleSwitcher,
      Text = "Grenade Warning & Tracker",
      ExpandIndex = 0,
      GetFunc = function() return A.Config.GrenadeTracker == true end,
      SetFunc = function(c, v) A.Config.GrenadeTracker = (v == true); return true end
    }
    weaponStack[#weaponStack + 1] = {
      Key = "ModMenu_GrenadeGround",
      UI = AliasMap.TitleSwitcher,
      Text = "   Show Grenades On Ground",
      ExpandHandle = "ModMenu_GrenadeTracker",
      ExpandIndex = 0,
      GetFunc = function() return A.Config.GrenadeGround == true end,
      SetFunc = function(c, v) A.Config.GrenadeGround = (v == true); return true end
    }
    weaponStack[#weaponStack + 1] = {
      Key = "ModMenu_GrenadeActive",
      UI = AliasMap.Switcher,
      Text = "   Active Grenade Warning",
      ExpandHandle = "ModMenu_GrenadeTracker",
      GetFunc = function() return A.Config.GrenadeActive == true end,
      SetFunc = function(c, v) A.Config.GrenadeActive = (v == true); return true end
    }
    -- Per-type ground-loot filters; active thrown/projectile tracking is unchanged.
    local groundFilters = {
      { key = "ModMenu_GrenadeGroundFrag", text = "      Ground: Frag Grenade", config = "GrenadeGroundFrag" },
      { key = "ModMenu_GrenadeGroundSmoke", text = "      Ground: Smoke Grenade", config = "GrenadeGroundSmoke" },
      { key = "ModMenu_GrenadeGroundMolotov", text = "      Ground: Molotov", config = "GrenadeGroundMolotov" },
      { key = "ModMenu_GrenadeGroundStun", text = "      Ground: Stun/Flash Grenade", config = "GrenadeGroundStun" }
    }
    for _, filter in ipairs(groundFilters) do
      local configKey = filter.config
      weaponStack[#weaponStack + 1] = {
        Key = filter.key,
        UI = AliasMap.Switcher,
        Text = filter.text,
        ExpandHandle = "ModMenu_GrenadeGround",
        GetFunc = function() return A.Config[configKey] == true end,
        SetFunc = function(c, v) A.Config[configKey] = (v == true); return true end
      }
    end

    local T = function(_, english) return english end
        local StackAimbotV2 = {
            { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = T("▶ Bật Aimbot Roy & Custom", "▶ Enable Custom Aimbot V2"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchEnable end, SetFunc = function(c,v) _G.LexusConfig.AimTouchEnable = v return true end },
            
            -- HIPFIRE (TÂM TRẮNG)
            { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Tâm Trắng", "   ▶ Hipfire Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchHipfire end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipfire = v return true end },
            { Key = "ModMenu_AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipIgKnock = v return true end },
            { Key = "ModMenu_AT_Hip_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipIgBot = v return true end },
            { Key = "ModMenu_AT_Hip_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.LexusConfig.AimTouchHipVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchHipVisCheck = v return true end },
            { Key = "ModMenu_AT_Hip_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchHipPrio = val return true end },
            { Key = "ModMenu_AT_Hip_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchHipBone = val return true end },
            { Key = "ModMenu_AT_Hip_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchHipCond = val return true end },
            { Key = "ModMenu_AT_Hip_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipSpeed = v return true end },
            { Key = "ModMenu_AT_Hip_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipFOV = v return true end },
            { Key = "ModMenu_AT_Hip_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchHipDist or 250) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchHipDist = v * 5 return true end },

            -- AIMBOT SHOTGUN
            { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Shotgun", "   ▶ Shotgun Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchSG end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSG = v return true end },
            { Key = "ModMenu_AT_SG_AutoFire", UI = AliasMap.Switcher, Text = T("      Tự Động Bắn", "      Auto Fire"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGAutoFire end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGAutoFire = v return true end },
            { Key = "ModMenu_AT_SG_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGIgKnock = v return true end },
            { Key = "ModMenu_AT_SG_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGIgBot = v return true end },
            { Key = "ModMenu_AT_SG_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSGVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSGVisCheck = v return true end },
            { Key = "ModMenu_AT_SG_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSGPrio = val return true end },
            { Key = "ModMenu_AT_SG_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSGBone = val return true end },
            { Key = "ModMenu_AT_SG_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchSGCond = val return true end },
            { Key = "ModMenu_AT_SG_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGSpeed = v return true end },
            { Key = "ModMenu_AT_SG_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGFOV = v return true end },
            { Key = "ModMenu_AT_SG_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-100m)", "      Distance Limit (1-100m)"), ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSGDist = v return true end },
            
            -- SCOPE ALL (SÚNG THƯỜNG KHI MỞ SCOPE)
            { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Mở Scope", "   ▶ Scope Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchScopeAll end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeAll = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeIgKnock = v return true end },
            { Key = "ModMenu_AT_ScopeAll_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeIgBot = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.LexusConfig.AimTouchScopeVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeVisCheck = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopePrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchScopePrio = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchScopeBone = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchScopeCond = val return true end },
            { Key = "ModMenu_AT_ScopeAll_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeSpeed = v return true end },
            { Key = "ModMenu_AT_ScopeAll_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeFOV = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchScopeDist or 300) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeDist = v * 5 return true end },
            { Key = "ModMenu_AT_ScopeAll_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy", "      Prediction Value"), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopePred = v return true end },
            { Key = "ModMenu_AT_ScopeAll_Recoil", UI = AliasMap.Slider, Text = T("      Bù Giật Tự Động", "      Auto Recoil Comp."), ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchScopeRecoil = v return true end },

            -- SCOPE SNIPER (SÚNG NGẮM/TỈA)
            { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Mở Scope (Súng Ngắm/Tỉa)", "   ▶ Sniper Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchScopeSniper end, SetFunc = function(c,v) _G.LexusConfig.AimTouchScopeSniper = v return true end },
            { Key = "ModMenu_AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Địch Knock", "      Ignore Knocked"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperIgKnock end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperIgKnock = v return true end },
            { Key = "ModMenu_AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = T("      Bỏ Qua Bot", "      Ignore Bots"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperIgBot end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperIgBot = v return true end },
            { Key = "ModMenu_AT_Sniper_Vis", UI = AliasMap.Switcher, Text = T("      Check Tường (VisCheck)", "      Visibility Check"), ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.LexusConfig.AimTouchSniperVisCheck end, SetFunc = function(c,v) _G.LexusConfig.AimTouchSniperVisCheck = v return true end },
            { Key = "ModMenu_AT_Sniper_Prio", UI = AliasMap.Slider, Text = T("      Ưu Tiên (1:Tâm 2:Gần 3:HP)", "      Priority (1:Crosshair 2:Distance 3:HP)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSniperPrio = val return true end },
            { Key = "ModMenu_AT_Sniper_Bone", UI = AliasMap.Slider, Text = T("      Vị Trí (1:Đầu 2:Ngực 3:Bụng 4:Hông)", "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, Min = 1, Max = 4, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.LexusState.CustomTextData.AimTouchSniperBone = val return true end },
            { Key = "ModMenu_AT_Sniper_Cond", UI = AliasMap.Slider, Text = T("      Điều Kiện (1:Bắn mới Aim, 2:Luôn Aim)", "      Trigger (1:On Fire, 2:Always)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, Min = 1, Max = 2, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperCond or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.LexusState.CustomTextData.AimTouchSniperCond = val return true end },
            { Key = "ModMenu_AT_Sniper_Spd", UI = AliasMap.Slider, Text = T("      Độ Mượt / Tốc Độ (1-100)", "      Smoothness / Speed (1-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperSpeed = v return true end },
            { Key = "ModMenu_AT_Sniper_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-100)", "      FOV Radius (1-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperFOV = v return true end },
            { Key = "ModMenu_AT_Sniper_Dist", UI = AliasMap.Slider, Text = T("      Khoảng Cách (1-500m)", "      Distance Limit (1-500m)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.LexusState.CustomTextData.AimTouchSniperDist or 400) / 5) end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperDist = v * 5 return true end },
            { Key = "ModMenu_AT_Sniper_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy (0-100)", "      Prediction Value (0-100)"), ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchSniperPred = v return true end },

            -- AIMBOT SÚNG CỐI (MORTAR)
            { Key = "ModMenu_AT_Mortar_Ex", UI = AliasMap.TitleSwitcher, Text = T("   ▶ Aimbot Súng Cối (Mortar)", "   ▶ Mortar Aimbot"), ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AimTouchMortar end, SetFunc = function(c,v) _G.LexusConfig.AimTouchMortar = v return true end },
            { Key = "ModMenu_AT_Mortar_FOV", UI = AliasMap.Slider, Text = T("      Vòng FOV (1-360)", "      FOV Radius (1-360)"), ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 360, min = 1, max = 360, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchMortarFOV or 360 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchMortarFOV = v return true end },
            { Key = "ModMenu_AT_Mortar_Pred", UI = AliasMap.Slider, Text = T("      Dự Đoán Hướng Chạy (0-100)", "      Prediction Value (0-100)"), ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.LexusState.CustomTextData.AimTouchMortarPred or 0 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.AimTouchMortarPred = v return true end }
        }
    -- Keep the V2 Aimboard controls in their own tab immediately to the right
    -- of Weapon Setting, instead of mixing them into the Visuals (ESP) list.
    pageDef.ModMenu = {
      Key = "ModMenu", Text = 999000, UIKey = "Setting_Page_Privacy",
      Category = {
        { Key = "Cat_ESP", Text = 999001, Stack = stack },
        { Key = "Cat_Weapons", Text = "Weapon Setting", Stack = weaponStack },
        { Key = "Cat_V2_Aimboard", Text = "V2 aimboard", Stack = StackAimbotV2 }
      }
    }
    for i = #catalog, 1, -1 do
      if type(catalog[i]) == "table" and catalog[i].Key == "ModMenu" then table.remove(catalog, i) end
    end
    table.insert(catalog, 1, pageDef.ModMenu)
  end

  if _G.UIManager and not _G.UIManager._AegisUiHooked then
    local manager = _G.UIManager
    local base = manager.ShowUI
    manager.ShowUI = function(config, ...)
      local args = {...}
      local n = select("#", ...)
      if config and config.keyName then
        local low = string.lower(config.keyName)
        if string.find(low, "setting_main") and not string.find(low, "custom") then
          local list = args[1]
          if type(list) == "table" then
            for i = #list, 1, -1 do
              local page = list[i]
              if type(page) == "table" and page.Key == "ModMenu" then
                table.remove(list, i)
              end
            end
            table.insert(list, 1, pageDef.ModMenu)
          end
        end
      end
      local tUnpack = table.unpack or unpack
      return base(config, tUnpack(args, 1, n))
    end
    manager._AegisUiHooked = true
  end
  A.Up.MenuWired = true
end

function Menu.Announce()
  if A.Up.Announced then return end
  pcall(function()
    Menu.Wire()
    OnScreen("Mod Menu Added!\nOpen Settings (Gear icon) -> UX_Official  MENU.")
    A.Up.Announced = true
  end)
end

local MOKING = {}

function MOKING.ShowTopText()
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage("OWNER +92 [ 03709241014 ]", -1, 1.0, {R = 0, G = 1, B = 1, A = 1}, {X = 0.85, Y = 0.85})
    end
  end)
end

function MOKING.ShowWelcomePopup()
  if MOKING._popupShown then return end
  MOKING._popupShown = true
  pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
      or require("client.slua.logic.common.logic_common_msg_box")
    local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"]
      or require("client.slua.logic.url.logic_webview_sdk")
    local function onJoin()
      if Web and Web.OpenURL then Web:OpenURL("https://Wa.me/+923709241014") end
    end
    local function onOK() end
    local title = "UX_PREMIUM"
    local body  = "Magic bullets, Skin Changer, esp and many other features are available only on the Pro plan"
    local ok = pcall(function() Msg.Show(4, title, body, onJoin, onOK, "JOIN", "OK") end)
    if not ok then
      pcall(function() Msg.Show(4, title, body, onJoin) end)
    end
  end)
end

function MOKING.OnMatchEnter()
  if MOKING._matchEntered then return end
  MOKING._matchEntered = true
  MOKING.ShowTopText()
  MOKING.ShowWelcomePopup()
end

A.Up.Pulse = (A.Up.Pulse or 0) + 1
local myPulse = A.Up.Pulse
A.Up.TrackedMarks = A.Up.TrackedMarks or {}
A.Up.Targets = A.Up.Targets or {}

local function Beat()
  if myPulse ~= A.Up.Pulse then return end

  pcall(function()
    if not A.Up.NativeReady and not A.Up.NativePriming then
      A.Up.NativePriming = true
      Esp.PrimeNativeMarks()
    end
    if A.Config.HighFps and not A.Up.GfxReady then Gfx.Unlock() end
  end)

  local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
  if not okData or not GameplayData then return end
  local pc = GameplayData.GetPlayerController()
  local me = nil
  if Around(pc) then me = pc:GetPlayerCharacterSafety() end

  if not Around(me) then
    for mark in pairs(A.Up.TrackedMarks) do LiftMark(mark) end
    for key, stamp in pairs(A.Up.Targets) do
      if stamp.enemy then StripMeshes(stamp.enemy, stamp) end
      A.Up.Targets[key] = nil
    end
    MOKING._matchEntered = false
    MOKING._popupShown = false
    return
  end

  if A.Config.AimTouchEnable then
    pcall(function()
      if type(_G.AimTouch) == "function" then _G.AimTouch() end
    end)
  end

  Menu.Announce()
  MOKING.OnMatchEnter()
  MOKING.ShowTopText()

  if A.Config.WallVehicle then Vhc.WallScan(pc) else Vhc.StripAll() end

  if A.Config.Weapons then
    Weapons.Scan(pc)
    Weapons.Draw(pc)
  else
    A.Up.NearbyWeapons = {}
  end

  if A.Config.AirDropESP or A.Config.LootCrateESP then
    SupplyItems.Scan(pc)
    SupplyItems.Draw(pc)
  else
    A.Up.SupplyItems = {}
  end

  if A.Config.GrenadeTracker and (A.Config.GrenadeGround or A.Config.GrenadeActive) then
    GrenadeTracker.Scan(pc)
    GrenadeTracker.Draw(pc)
  else
    A.Up.GrenadeItems = {}
    A.Up.GrenadeActive = {}
  end

  pcall(function()
    local cam = me.ThirdPersonCameraComponent
    if Around(cam) and not me.bIsWeaponAiming then
      local target = 90
      if A.Config.Ipad then target = A.Config.IpadFov or 120 end
      if cam.FieldOfView ~= target then cam.FieldOfView = target end
    end
  end)

  local squad = {}
  pcall(function()
    if GameplayData.GetAllPlayerCharacters then
      squad = GameplayData.GetAllPlayerCharacters() or {}
    end
  end)
  local myTeam = me.TeamID or 0

  local aliveKeys = {}
  for _, foe in pairs(squad) do
    if Around(foe) and foe ~= me then aliveKeys[EnemyId(foe)] = true end
  end
  for key, stamp in pairs(A.Up.Targets) do
    if not aliveKeys[key] then
      if stamp.enemy then
        StripMeshes(stamp.enemy, stamp)
        if stamp.healthMark then LiftMark(stamp.healthMark); stamp.healthMark = nil end
        if stamp.meterMark then LiftMark(stamp.meterMark); stamp.meterMark = nil end
      end
      A.Up.Targets[key] = nil
    end
  end

  for _, foe in pairs(squad) do
    if Around(foe) and foe ~= me and foe.TeamID ~= myTeam then
      local gone = false
      pcall(function() if foe.HealthStatus ~= nil and foe.HealthStatus == 2 then gone = true end end)
      local key = EnemyId(foe)
      A.Up.Targets[key] = A.Up.Targets[key] or { enemy = foe, IsBot = false }
      local stamp = A.Up.Targets[key]
      stamp.enemy = foe
      pcall(function()
        local isBot = foe.bIsBot or foe.bIsAI or foe.bIsDummy or false
        if not isBot then
          local pk = foe.PlayerKey
          if type(pk) == "number" and pk > 2000000000 then isBot = true end
        end
        if not isBot and type(foe.GetPlayerName) == "function" then
          local nm = foe:GetPlayerName() or ""
          local low = nm:lower()
          if low:find("bot", 1, true) or low:find("ai_", 1, true) or low:find("dummy", 1, true) or low:find("机器人", 1, true) or low:find("npc", 1, true) then
            isBot = true
          end
        end
        if not isBot then
          pcall(function()
            local ctrl = foe:GetController()
            if ctrl and ctrl.IsA then
              local AICtrl = import("AIController")
              if AICtrl and ctrl:IsA(AICtrl) then isBot = true end
            end
          end)
        end
        stamp.IsBot = isBot
      end)
      if not gone then
        if A.Config.Chams then ArmMeshes(foe, stamp) else StripMeshes(foe, stamp) end
        if A.Config.Antenna then DrawAntenna(me, foe, pc) end
        if A.Config.MeterMarks then
          if not stamp.healthMark then stamp.healthMark = PlaceMark(1006, {X=0,Y=0,Z=0}, 0, "", 4, foe) end
          if not stamp.meterMark then stamp.meterMark = PlaceMark(9999, {X=0,Y=0,Z=0}, 0, "", 4, foe) end
        else
          if stamp.healthMark then LiftMark(stamp.healthMark); stamp.healthMark = nil end
          if stamp.meterMark then LiftMark(stamp.meterMark); stamp.meterMark = nil end
        end
      else
        StripMeshes(foe, stamp)
        if stamp.healthMark then LiftMark(stamp.healthMark); stamp.healthMark = nil end
        if stamp.meterMark then LiftMark(stamp.meterMark); stamp.meterMark = nil end
      end
    end
  end
end

local function Pulse()
  if myPulse ~= A.Up.Pulse then return end
  pcall(Beat)
  local interval = 0.012
  if A.Up.Heartbeat and A.Up.Heartbeat > 0 then interval = A.Up.Heartbeat / 1000 end
  Later(interval, Pulse)
end

    end, true)
  end)
end

pcall(function()
  Later(2.0, Pulse, true)
end)



local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  },
  {
    ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  },
  {
    FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature"
  }
}, "BRPlayerCharacterBase")

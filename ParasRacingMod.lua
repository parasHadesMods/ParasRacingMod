ModUtil.RegisterMod("ParasRacingMod")

ParasRacingMod.Next = {}
ParasRacingMod.Current = {}
ParasRacingMod.UsedRooms = {}
ParasRacingMod.UpgradableGodTraitCount = 0

ParasRacingMod.NonNormalRooms = {
  RoomSecret01 = true,
  RoomSecret02 = true,
  RoomSecret03 = true,
  RoomChallenge01 = true,
  RoomChallenge02 = true,
  RoomChallenge03 = true,
  RoomChallenge04 = true,
  A_Story01 = true,
  B_Story01 = true,
  C_Story01 = true,
  A_Shop01 = true,
  B_Shop01 = true,
  C_Shop01 = true
}

function ParasRacingMod.IsNormalRoom(room)
  if ParasRacingMod.NonNormalRooms[room.Name] then
    return false
  else
    return true
  end
end

ParasRacingMod.OverrideExitCount = {
  RoomSecret01 = 2,
  RoomSecret02 = 3,
  B_Combat10 = 2,
  C_MiniBoss02 = 2,
  C_Reprieve01 = 2,
  D_Hub = 5
}

function ParasRacingMod.ExitCount(room)
  return ParasRacingMod.OverrideExitCount[room.Name] or room.NumExits
end

ModUtil.BaseOverride("UpgradableGodTraitCountAtLeast", function( num )
  return ParasRacingMod.UpgradableGodTraitCount >= num
end, ParasRacingMod)

ModUtil.WrapBaseFunction("StartNewRun", function(baseFunc, ...)
  local run = baseFunc(...)
  ParasRacingMod.Next = {}
  ParasRacingMod.Current = {}
  ParasRacingMod.UsedRooms = {}
  ParasRacingMod.UpgradableGodTraitCount = 0
  return run
end, ParasRacingMod)

ModUtil.WrapBaseFunction("StartRoom", function(baseFunc, ...)
  if ParasRacingMod.Next.Room then
    table.insert( ParasRacingMod.UsedRooms, ParasRacingMod.Next.Room.Name )
  end
  ParasRacingMod.Current = ParasRacingMod.Next
  ParasRacingMod.Current.ExtraExits = {}
  if ParasRacingMod.Next.HasBoon then
    ParasRacingMod.UpgradableGodTraitCount = ParasRacingMod.UpgradableGodTraitCount + 1
  end
  ParasRacingMod.Next = {}
  for k, v in pairs(CurrentRun.RewardStores) do
    for kk, vv in pairs(v) do
      print(kk, vv.Name)
    end
  end
  return baseFunc(...)
end, ParasRacingMod)

ModUtil.WrapBaseFunction("RandomSetNextInitSeed", function(baseFunc, ...)
  RandomSynchronize()
  return baseFunc(...)
end, ParasRacingMod)

ModUtil.WrapBaseFunction("IsRoomEligible", function(baseFunc, currentRun, currentRoom, nextRoomData, args)
  if Contains( ParasRacingMod.UsedRooms, nextRoomData.Name ) then
    return false
  elseif nextRoomData.GameStateRequirements
    and nextRoomData.GameStateRequirements.RequiredFalseRooms
    and ParasRacingMod.Current.Room ~= nil
    and Contains( nextRoomData.GameStateRequirements.RequiredFalseRooms, ParasRacingMod.Current.Room.Name ) then
    return false
  else
    return baseFunc(currentRun, currentRoom, nextRoomData, args)
  end
end, ParasRacingMod)

ModUtil.WrapBaseFunction("CreateRoom", function(baseFunc, roomForDoorData, ...)
  if roomForDoorData.Name == "RoomOpening" then
    return baseFunc(roomForDoorData, ...)
  end
  if ParasRacingMod.IsNormalRoom(roomForDoorData) then
    if ParasRacingMod.Next.Room == nil then
      ParasRacingMod.Next.Room = DeepCopyTable(roomForDoorData)
    else
      roomForDoorData = DeepCopyTable( ParasRacingMod.Next.Room )
    end
  end
  local exitCount = ParasRacingMod.ExitCount(roomForDoorData)
  if exitCount > (ParasRacingMod.Next.MaxExits or 0) then
    ParasRacingMod.Next.MaxExits = exitCount
  end
  ParasRacingMod.Current.CreatedExits = (ParasRacingMod.Current.CreatedExits or 0) + 1
  if ParasRacingMod.Current.CreatedExits == ParasRacingMod.ExitCount(CurrentRun.CurrentRoom) then
    for i = ParasRacingMod.Current.CreatedExits + 1, (ParasRacingMod.Current.MaxExits or 0) do
      local extraRoomData = ChooseNextRoomData( CurrentRun )
      local extraRoom = CreateRoom( extraRoomData, { SkipChooseReward = true, SkipChooseEncounter = true })
      extraRoom.NeedsReward = true
      if ParasRacingMod.Current.ExtraExits then
        table.insert( ParasRacingMod.Current.ExtraExits, extraRoom )
      end
    end
  end
  return baseFunc(roomForDoorData, ...)
end, ParasRacingMod)

ModUtil.WrapBaseFunction("ChooseRoomReward", function(baseFunc, run, room, rewardStoreName, rewardsChosen, args)
  ParasRacingMod.Current.RewardsChosen = rewardsChosen
  local rewardType =  baseFunc(run, room, rewardStoreName, rewardsChosen, args)
  if rewardType == "Boon" then
    ParasRacingMod.Next.HasBoon = true
  end
  return rewardType
end, ParasRacingMod)

ModUtil.WrapBaseFunction("AssignRoomToExitDoor", function(baseFunc, door, room)
  local r = baseFunc(door, room)
  ParasRacingMod.Current.AssignedExits = (ParasRacingMod.Current.AssignedExits or 0) + 1
  if ParasRacingMod.Current.AssignedExits == ParasRacingMod.ExitCount(CurrentRun.CurrentRoom) then
    for i, extraRoom in pairs( ParasRacingMod.Current.ExtraExits ) do
      extraRoom.RewardStoreName = room.RewardStoreName
      extraRoom.ChosenRewardType = ChooseRoomReward( CurrentRun, extraRoom, extraRoom.RewardStoreName, ParasRacingMod.Current.RewardsChosen)
      SetupRoomReward( CurrentRun, extraRoom, ParasRacingMod.Current.RewardsChosen, { IgnoreForceLootName = extraRoom.IgnoreForceLootName } )
      table.insert( ParasRacingMod.Current.RewardsChosen, { RewardType = extraRoom.ChosenRewardType, ForceLootName = extraRoom.ForceLootName })
      extraRoom.NeedsReward = false
    end
  end
end, ParasRacingMod)

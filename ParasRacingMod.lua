ModUtil.RegisterMod("ParasRacingMod")

ParasRacingMod.FirstNormalRoom = nil
ParasRacingMod.InPlaceOfRoom = nil
ParasRacingMod.UsedRooms = {}

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

ModUtil.WrapBaseFunction("StartNewRun", function(baseFunc, ...)
  local run = baseFunc(...)
  ParasRacingMod.FirstNormalRoom = nil
  ParasRacingMod.InPlaceOfRoom = nil
  ParasRacingMod.UsedRooms = {}
  return run
end, ParasRacingMod)

ModUtil.WrapBaseFunction("StartRoom", function(baseFunc, ...)
  if ParasRacingMod.FirstNormalRoom then
    ParasRacingMod.InPlaceOfRoom = ParasRacingMod.FirstNormalRoom
    table.insert( ParasRacingMod.UsedRooms, ParasRacingMod.FirstNormalRoom.Name )
    ParasRacingMod.FirstNormalRoom = nil
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
    and ParasRacingMod.InPlaceOfRoom ~= nil
    and Contains( roomData.GameStateRequirements.RequiredFalseRooms, ParasRacingMod.InPlaceOfRoom ) then
    return false
  else
    return baseFunc(currentRun, currentRoom, nextRoomData, args)
  end
end, ParasRacingMod)

ModUtil.WrapBaseFunction("CreateRoom", function(baseFunc, roomForDoorData, ...)
  if ParasRacingMod.IsNormalRoom(roomForDoorData) then
    if ParasRacingMod.FirstNormalRoom == nil then
      ParasRacingMod.FirstNormalRoom = DeepCopyTable(roomForDoorData)
    else
      roomForDoorData = DeepCopyTable( ParasRacingMod.FirstNormalRoom )
    end
  end
  return baseFunc(roomForDoorData, ...)
end, ParasRacingMod)

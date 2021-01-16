ModUtill.RegisterMod("ParasRacingMod")

ParasRacingMod.FirstNormalRoom = nil

ParasRacingMod.NonNormalRooms = {
  RoomSecret01 = true,
  RoomSecret02 = true,
  RoomSecret03 = true,
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

ModUtil.WrapBaseFunction("RandomSetNextInitSeed", function(baseFunc, ...)
  ParasRacingMod.FirstNormalRoom = nil
  RandomSynchronize()
  baseFunc(...)
end, ParasRacingMod)

ModUtil.WrapBaseFunction("CreateRoom", function(baseFunc, roomForDoorData, ...)
  if IsNormalRoom(roomForDoorData) then
    if ParasRacingMod.FirstNormalRoom == nil then
      ParasRacingMod.FirstNormalRoom = DeepCopyTable(roomForDoorData)
    else
      roomForDoorData = DeepCopyTable( ParasRacingMod.FirstNormalRoom )
    end
  end
  return baseFunc(roomForDoorData, ...)
end, ParasRacingMod)

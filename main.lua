ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while not ESX.GetPlayerData().job do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	TriggerServerEvent("esx_doorlock:server:setupDoors")

end)

local closestDoorKey, closestDoorValue = nil, nil


function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

Citizen.CreateThread(function()
	while true do
		for key, doorID in ipairs(Config.Doors) do
			if doorID.doors then
				for k,v in ipairs(doorID.doors) do
					v.objHash = v.objHash or GetHashKey(v.objName)
					if not v.object or not DoesEntityExist(v.object) then
						v.object = GetClosestObjectOfType(v.objCoords, 1.0, v.objHash, false, false, false)
					end
				end
			else
				doorID.objHash = doorID.objHash or GetHashKey(doorID.objName)
				if not doorID.object or not DoesEntityExist(doorID.object) then
					doorID.object = GetClosestObjectOfType(doorID.objCoords, 1.0, doorID.objHash, false, false, false)
				end
			end
		end

		Citizen.Wait(2500)
	end
end)

local maxDistance = 1.25

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords, awayFromDoors = GetEntityCoords(GetPlayerPed(-1)), true

		for k,doorID in ipairs(Config.Doors) do
			local distance

			if doorID.doors then
				distance = #(playerCoords - doorID.doors[1].objCoords)
			else
				distance = #(playerCoords - doorID.objCoords)
			end

			if doorID.distance then
				maxDistance = doorID.distance
			end
			if distance < 50 then
				awayFromDoors = false
				if doorID.doors then
					for _,v in ipairs(doorID.doors) do
						FreezeEntityPosition(v.object, doorID.locked)

						if doorID.locked and v.objYaw and GetEntityRotation(v.object).z ~= v.objYaw then
							SetEntityRotation(v.object, 0.0, 0.0, v.objYaw, 2, true)
						end
					end
				else
					FreezeEntityPosition(doorID.object, doorID.locked)

					if doorID.locked and doorID.objYaw and GetEntityRotation(doorID.object).z ~= doorID.objYaw then
						SetEntityRotation(doorID.object, 0.0, 0.0, doorID.objYaw, 2, true)
					end
				end
			end

			if distance < maxDistance then
				awayFromDoors = false
				if doorID.size then
					size = doorID.size
				end

				local isAuthorized = IsAuthorized(doorID)

				if isAuthorized then
					if doorID.locked then
						displayText = "[E] - ~r~Fermer"
					elseif not doorID.locked then
						displayText = "[E] - ~g~Ouvert"
					end
				elseif not isAuthorized then
					if doorID.locked then
						if doorID.text then
							displayText = " ~r~Fermer " .. doorID.text
						else
							displayText = " ~r~Fermer "
						end
					elseif not doorID.locked then
						displayText = " ~g~Ouvert "
					end
				end

				if doorID.locking then
					if doorID.locked then
						displayText = " ~o~Ouverture.. "
					else
						displayText = " ~o~Fermeture.. "
					end
				end

				if doorID.objCoords == nil then
					doorID.objCoords = doorID.textCoords
				end

				DrawText3Ds(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, displayText)

				if IsControlJustReleased(0, 38) then
					if isAuthorized then
						setDoorLocking(doorID, k)
					end
				end
			end
		end

		if awayFromDoors then
			Citizen.Wait(1000)
		end
	end
end)

-- local props = {
-- 	"prison_prop_door1",
-- 	"prison_prop_door2",
-- 	"v_ilev_gtdoor",
-- 	"prison_prop_door1a"
-- }

-- Citizen.CreateThread(function()
-- 	while true do
-- 		for k, v in pairs(props) do
-- 			local ped = GetPlayerPed(-1)
-- 			local pos = GetEntityCoords(ped)
-- 			local ClosestDoor = GetClosestObjectOfType(pos.x, pos.y, pos.z, 5.0, GetHashKey(v), 0, 0, 0)
-- 			if ClosestDoor ~= 0 then
-- 				local DoorCoords = GetEntityCoords(ClosestDoor)
	
-- 				DrawText3Ds(DoorCoords.x, DoorCoords.y, DoorCoords.z, "OBJ: "..v..", x: "..round(DoorCoords.x, 0)..", y: "..round(DoorCoords.y, 0)..", z: "..round(DoorCoords.z, 0))
-- 			end
-- 		end
-- 		Citizen.Wait(1)
-- 	end
-- end)

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end


RegisterNetEvent('lockpick:vehicleUse')
AddEventHandler('lockpick:vehicleUse', function()
	local ped = GetPlayerPed(-1)
	local pos = GetEntityCoords(ped)
	for k, v in pairs(Config.Doors) do
		local dist = GetDistanceBetweenCoords(pos, Config.Doors[k].textCoords.x, Config.Doors[k].textCoords.y, Config.Doors[k].textCoords.z)
		if dist < 1.5 then
			if Config.Doors[k].pickable then
				if Config.Doors[k].locked then
					closestDoorKey, closestDoorValue = k, v
					lockpickFinish(exports['rl-lockpick']:lockpick(pickhealth, pickdamage, pickPadding, distance) == 100)
				else
					TriggerEvent('notification', 'The door is already unlocked!', 2)
				end
			else
				TriggerEvent('notification', 'The door has too strong a lock!', 2)
			end
		end
	end
end)

function lockpickFinish(success)
	if success then
		TriggerEvent('notification', 'Success!', 1)
		setDoorLocking(closestDoorValue, closestDoorKey)
	else
		TriggerEvent('notification', 'Failed!', 2)
    end
end

function setDoorLocking(doorId, key)
	doorId.locking = true
	openDoorAnim()
    SetTimeout(800, function()
		doorId.locking = false
		doorId.locked = not doorId.locked
		TriggerServerEvent('esx_doorlock:server:updateState', key, doorId.locked)
	end)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

function IsAuthorized(doorID)
	local PlayerData = ESX.GetPlayerData()

	
	for _,job in pairs(doorID.authorizedJobs) do
		if job == PlayerData.job.name then
			return true
		end
	end
	
	return false
end

function openDoorAnim()
	if not IsPedInAnyVehicle(PlayerPedId()) then
    	loadAnimDict("anim@heists@keycard@") 
    	TaskPlayAnim( GetPlayerPed(-1), "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0 )
		SetTimeout(600, function()
			ClearPedTasks(GetPlayerPed(-1))
		end)
	end
end

RegisterNetEvent('esx_doorlock:client:setState')
AddEventHandler('esx_doorlock:client:setState', function(doorID, state)
	Config.Doors[doorID].locked = state
end)

RegisterNetEvent('esx_doorlock:client:setDoors')
AddEventHandler('esx_doorlock:client:setDoors', function(doorList)
	Config.Doors = doorList
end)
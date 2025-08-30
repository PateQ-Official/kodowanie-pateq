-- persistent account storage
local accounts = {}
local accountFile = "accounts.json"

local function loadAccounts()
    if not fileExists(accountFile) then return end
    local f = fileOpen(accountFile)
    if not f then return end
    local data = fileRead(f, fileGetSize(f))
    fileClose(f)
    accounts = fromJSON(data) or {}
end

local function saveAccounts()
    local f = fileCreate(accountFile)
    if not f then return end
    fileWrite(f, toJSON(accounts, true))
    fileClose(f)
end

addEventHandler("onResourceStart", resourceRoot, loadAccounts)
addEventHandler("onResourceStop", resourceRoot, saveAccounts)

-- helpers
local function generateAID(nick)
    return "AID-" .. string.sub(hash("md5", tostring(getTickCount()) .. nick), 1, 6)
end

-- registration
addEvent("onPlayerRegister", true)
addEventHandler("onPlayerRegister", root, function(nick, pass)
    if accounts[nick] then
        triggerClientEvent(client, "onClientRegisterResult", client, false, "Nick zajęty")
        return
    end

    local aid = generateAID(nick)
    accounts[nick] = {
        password = hash("sha256", pass),
        aid = aid,
        skin = 0,
        money = 0,
        ap = 0
    }
    saveAccounts()
    triggerClientEvent(client, "onClientRegisterResult", client, true, nil, aid)
end)

-- login
addEvent("onPlayerLogin", true)
addEventHandler("onPlayerLogin", root, function(nick, pass)
    local acc = accounts[nick]
    if acc and acc.password == hash("sha256", pass) then
        setElementData(client, "accountNick", nick)
        setElementData(client, "AP", acc.ap)
        setPlayerMoney(client, acc.money)
        triggerClientEvent(client, "onClientLoginResult", client, true, {
            aid = acc.aid,
            skin = acc.skin,
            money = acc.money,
            ap = acc.ap
        })
    else
        triggerClientEvent(client, "onClientLoginResult", client, false, "Błędne dane")
    end
end)

-- spawn
addEvent("onPlayerRequestSpawn", true)
addEventHandler("onPlayerRequestSpawn", root, function(spawnId, skin)
    local nick = getElementData(client, "accountNick")
    if not nick then return end

    local x, y, z = 0, 0, 3
    if spawnId == "LS" then
        x, y, z = 1959, -1714, 15
    elseif spawnId == "SF" then
        x, y, z = -1988, 1385, 27
    elseif spawnId == "LV" then
        x, y, z = 1607, 1816, 10
    end

    spawnPlayer(client, x, y, z, 0, skin)
    fadeCamera(client, true)
    setCameraTarget(client, client)

    accounts[nick].skin = skin
    accounts[nick].money = getPlayerMoney(client)
    accounts[nick].ap = getElementData(client, "AP") or accounts[nick].ap
    saveAccounts()
end)

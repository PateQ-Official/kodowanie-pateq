-- Client-side GUI for loading, login/registration and spawn selection
local screenW, screenH = guiGetScreenSize()

-- Background music (replace URL with actual mp3 file path or URL)
local music = playSound("https://files.4kwin.com/music/alan_walker_faded.mp3", true)
setSoundVolume(music, 0.5)
local muted = false

-- Theme colours
local theme = {
    accent = tocolor(0, 128, 255, 200)
}

-- Simple fade-in animation for GUI windows
local function fadeInGUI(elem)
    local alpha = 0
    guiSetAlpha(elem, alpha)
    local t
    t = setTimer(function()
        alpha = alpha + 0.05
        if alpha >= 1 then
            alpha = 1
            killTimer(t)
        end
        guiSetAlpha(elem, alpha)
    end, 50, 0)
end

-- Helper to highlight buttons on hover
local function addHoverEffect(elem)
    addEventHandler("onClientMouseEnter", elem, function()
        guiSetAlpha(elem, 0.8)
    end, false)
    addEventHandler("onClientMouseLeave", elem, function()
        guiSetAlpha(elem, 1)
    end, false)
end

-- Credential persistence
local saveFile = "login.xml"

local function saveCredentials(user, pass)
    local xml = xmlCreateFile(saveFile, "login")
    xmlNodeSetAttribute(xml, "username", user)
    xmlNodeSetAttribute(xml, "password", pass)
    xmlSaveFile(xml)
    xmlUnloadFile(xml)
end

local function loadCredentials()
    if not fileExists(saveFile) then return "", "" end
    local xml = xmlLoadFile(saveFile)
    local user = xmlNodeGetAttribute(xml, "username") or ""
    local pass = xmlNodeGetAttribute(xml, "password") or ""
    xmlUnloadFile(xml)
    return user, pass
end

local function deleteCredentials()
    if fileExists(saveFile) then fileDelete(saveFile) end
end

local loading = true
local progress = 0
local maxMB = 50
local downloadedMB = 0

local function renderLoading()
    if not loading then return end
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(0,0,0,255))
    dxDrawRectangle(screenW/2 - 150, screenH/2 + 40, 300, 20, tocolor(50,50,50,200))
    dxDrawRectangle(screenW/2 - 150, screenH/2 + 40, 300 * (progress/100), 20, theme.accent)
    dxDrawText(string.format("%d%% - %.1f/%.1f MB", progress, downloadedMB, maxMB), 0, 0, screenW, screenH, tocolor(255,255,255,255), 1, "default-bold", "center", "center")
end
addEventHandler("onClientRender", root, renderLoading)

local loadTimer = setTimer(function()
    if progress < 100 then
        progress = progress + 1
        downloadedMB = progress/100 * maxMB
    else
        loading = false
        killTimer(loadTimer)
        createLoginPanel()
    end
end, 50, 0)

-- Login panel
local loginWindow
local userEdit
local passEdit
local rememberCheck
local rulesCheck

local playerData = {}

local function onLoginResult(success, dataOrMsg)
    if success then
        destroyElement(loginWindow)
        playerData = dataOrMsg or {}
        showSpawnSelection()
    else
        outputChatBox(dataOrMsg or "Logowanie nieudane")
    end
end
addEvent("onClientLoginResult", true)
addEventHandler("onClientLoginResult", root, onLoginResult)

local function onRegisterResult(success, msg, aid)
    if success then
        outputChatBox("Rejestracja zakończona. Twoje AID: " .. (aid or ""))
        destroyElement(registerWindow)
        guiSetVisible(loginWindow, true)
    else
        outputChatBox(msg or "Rejestracja nieudana")
    end
end
addEvent("onClientRegisterResult", true)
addEventHandler("onClientRegisterResult", root, onRegisterResult)

function createLoginPanel()
    loginWindow = guiCreateWindow((screenW-400)/2, (screenH-300)/2, 400, 300, "Logowanie", false)
    guiWindowSetSizable(loginWindow, false)
    guiSetProperty(loginWindow, "CaptionColour", "FF0080FF")
    guiSetProperty(loginWindow, "ImageColours", "tl:FF000000 tr:FF000000 bl:FF000000 br:FF000000")
    fadeInGUI(loginWindow)

    guiCreateLabel(30, 60, 60, 20, "Nick:", false, loginWindow)
    userEdit = guiCreateEdit(100, 60, 200, 25, "", false, loginWindow)
    guiCreateLabel(30, 100, 60, 20, "Hasło:", false, loginWindow)
    passEdit = guiCreateEdit(100, 100, 200, 25, "", false, loginWindow)
    guiEditSetMasked(passEdit, true)

    rememberCheck = guiCreateCheckBox(100, 130, 200, 20, "Zapamiętaj dane", false, false, loginWindow)
    rulesCheck = guiCreateCheckBox(100, 150, 200, 20, "Akceptuję regulamin", false, false, loginWindow)
    local rulesBtn = guiCreateButton(100, 175, 200, 25, "Regulamin", false, loginWindow)
    local loginBtn = guiCreateButton(100, 205, 90, 30, "Zaloguj", false, loginWindow)
    local registerBtn = guiCreateButton(210, 205, 90, 30, "Rejestracja", false, loginWindow)
    local muteBtn = guiCreateButton(360, 25, 25, 25, "🔈", false, loginWindow)

    addHoverEffect(loginBtn)
    addHoverEffect(registerBtn)
    addHoverEffect(rulesBtn)
    addHoverEffect(muteBtn)

    local u, p = loadCredentials()
    guiSetText(userEdit, u)
    guiSetText(passEdit, p)
    guiCheckBoxSetSelected(rememberCheck, u ~= "")

    addEventHandler("onClientGUIClick", loginBtn, function()
        if not guiCheckBoxGetSelected(rulesCheck) then
            outputChatBox("Musisz zaakceptować regulamin")
            return
        end
        triggerServerEvent("onPlayerLogin", resourceRoot, guiGetText(userEdit), guiGetText(passEdit))
        if guiCheckBoxGetSelected(rememberCheck) then
            saveCredentials(guiGetText(userEdit), guiGetText(passEdit))
        else
            deleteCredentials()
        end
    end, false)

    addEventHandler("onClientGUIClick", registerBtn, function()
        destroyElement(loginWindow)
        showRegisterPanel()
    end, false)

    addEventHandler("onClientGUIClick", rulesBtn, function()
        openURL("https://forum.example.com")
    end, false)

    addEventHandler("onClientGUIClick", muteBtn, function()
        muted = not muted
        setSoundVolume(music, muted and 0 or 0.5)
        guiSetText(muteBtn, muted and "🔇" or "🔈")
    end, false)
end

-- Registration panel
registerWindow = nil
function showRegisterPanel()
    registerWindow = guiCreateWindow((screenW-400)/2, (screenH-330)/2, 400, 330, "Rejestracja", false)
    guiWindowSetSizable(registerWindow, false)
    guiSetProperty(registerWindow, "CaptionColour", "FF0080FF")
    guiSetProperty(registerWindow, "ImageColours", "tl:FF000000 tr:FF000000 bl:FF000000 br:FF000000")
    fadeInGUI(registerWindow)

    guiCreateLabel(30, 60, 100, 20, "Nick:", false, registerWindow)
    local rUser = guiCreateEdit(140, 60, 200, 25, "", false, registerWindow)
    guiCreateLabel(30, 100, 100, 20, "Hasło:", false, registerWindow)
    local rPass = guiCreateEdit(140, 100, 200, 25, "", false, registerWindow)
    guiEditSetMasked(rPass, true)
    guiCreateLabel(30, 140, 100, 20, "Powtórz:", false, registerWindow)
    local rPass2 = guiCreateEdit(140, 140, 200, 25, "", false, registerWindow)
    guiEditSetMasked(rPass2, true)

    local regRules = guiCreateCheckBox(140, 170, 200, 20, "Akceptuję regulamin", false, false, registerWindow)
    local rulesBtn = guiCreateButton(140, 195, 200, 25, "Regulamin", false, registerWindow)
    local createBtn = guiCreateButton(140, 225, 90, 30, "Utwórz", false, registerWindow)
    local backBtn = guiCreateButton(250, 225, 90, 30, "Wróć", false, registerWindow)

    addHoverEffect(rulesBtn)
    addHoverEffect(createBtn)
    addHoverEffect(backBtn)

    addEventHandler("onClientGUIClick", createBtn, function()
        if guiGetText(rPass) ~= guiGetText(rPass2) then
            outputChatBox("Hasła różnią się")
            return
        end
        if not guiCheckBoxGetSelected(regRules) then
            outputChatBox("Musisz zaakceptować regulamin")
            return
        end
        triggerServerEvent("onPlayerRegister", resourceRoot, guiGetText(rUser), guiGetText(rPass))
    end, false)

    addEventHandler("onClientGUIClick", rulesBtn, function()
        openURL("https://forum.example.com")
    end, false)

    addEventHandler("onClientGUIClick", backBtn, function()
        destroyElement(registerWindow)
        createLoginPanel()
    end, false)
end

-- Spawn selection
function showSpawnSelection()
    local spawnWindow = guiCreateWindow((screenW-300)/2, (screenH-260)/2, 300, 260, "Wybór spawnu", false)
    guiWindowSetSizable(spawnWindow, false)
    guiSetProperty(spawnWindow, "CaptionColour", "FF0080FF")
    guiSetProperty(spawnWindow, "ImageColours", "tl:FF000000 tr:FF000000 bl:FF000000 br:FF000000")
    fadeInGUI(spawnWindow)

    guiCreateLabel(20, 30, 260, 20, "AID: " .. (playerData.aid or ""), false, spawnWindow)

    local lsBtn = guiCreateButton(30, 60, 80, 30, "Los Santos", false, spawnWindow)
    local sfBtn = guiCreateButton(110, 60, 80, 30, "San Fierro", false, spawnWindow)
    local lvBtn = guiCreateButton(190, 60, 80, 30, "Las Venturas", false, spawnWindow)

    guiCreateLabel(30, 110, 80, 20, "Skin:", false, spawnWindow)
    local skinGrid = guiCreateGridList(30, 130, 240, 100, false, spawnWindow)
    local col = guiGridListAddColumn(skinGrid, "ID", 0.9)
    local skins = {0, 7, 46}
    for _, id in ipairs(skins) do
        local row = guiGridListAddRow(skinGrid)
        guiGridListSetItemText(skinGrid, row, col, tostring(id), false, false)
    end

    addHoverEffect(lsBtn)
    addHoverEffect(sfBtn)
    addHoverEffect(lvBtn)

    local function spawn(city)
        local row, colIndex = guiGridListGetSelectedItem(skinGrid)
        local skin = tonumber(guiGridListGetItemText(skinGrid, row, colIndex)) or playerData.skin or 0
        triggerServerEvent("onPlayerRequestSpawn", localPlayer, city, skin)
        destroyElement(spawnWindow)
    end

    addEventHandler("onClientGUIClick", lsBtn, function() spawn("LS") end, false)
    addEventHandler("onClientGUIClick", sfBtn, function() spawn("SF") end, false)
    addEventHandler("onClientGUIClick", lvBtn, function() spawn("LV") end, false)
end

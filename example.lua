
local UBUI = nil

local win = nil
local G = {}
local canvas = nil
local TEX = nil

local lastScene = nil
local lastOpen = false
local built = false
local buildDelay = 0

function GetRoot()
    local MOD_FOLDER = "UBUILibrary"
    local folders = File.GetAllFolders("")
    for i = 1, #folders, 1 do
        if folders[i] == MOD_FOLDER then
            return MOD_FOLDER .. "/"
        end
        local sub = File.GetAllFolders(folders[i])
        if sub ~= nil then
            for j = 1, #sub, 1 do
                if sub[j] == MOD_FOLDER then
                    return folders[i] .. "/" .. MOD_FOLDER .. "/"
                end
            end
        end
    end
    return nil
end

function UI()
    if UBUI == nil then return end

    local sw, sh = UBUI.ScreenSize()
    Debug.Log("screensize: " .. basicModule.tostring(sw) .. "x" .. basicModule.tostring(sh))

    local function bopts(o)
        o = o or {}
        o.fixed = true
        o.textPadY = 5
        return o
    end

    local function sopts(o)
        o = o or {}
        o.handle = true
        o.trackHeight = 14
        o.handleHeight = 24
        o.handleWidth = 16
        o.h = o.h or 32
        return o
    end

    local function halfW(cw)
        return (cw - 8) / 2
    end

    local W, H, HEAD = 960, 760, 56

    win = UBUI.Window(W, H, 0, 0, true, HEAD, "<b>UBUI</b> Window", {
        space = "example",
        center = true,
        clipping = true,
        padding = 0,
        spacing = 0,
        titleAlign = "MiddleLeft",
        group = "ui",
    })

    if win == nil then return end

    win:SetAnchor(0.5, 0.5)
    win:SetPivot(0.5, 0.5)
    G.win = win

    win:HeaderRow("right", { spacing = 6 })
        :Button("<b>X</b>", function()
            win:Close()
        end, bopts({ style = "close" }))

    local body = win.body
    local bodyW = body:ContentWidth()
    local bodyH = body.h
    local qw = math.floor(bodyW / 2)
    local qh = math.floor(bodyH / 2)

    local q = {}

    q[1] = body:NewArea("TL", 0, 0, qw, qh, {
        color = UBUI.Colors.clear,
        padding = 12,
        spacing = 8,
    })

    q[2] = body:NewArea("TR", 0, 0, bodyW - qw, qh, {
        color = UBUI.Colors.clear,
        padding = 12,
        spacing = 8,
    })

    q[3] = body:NewArea("BL", 0, 0, qw, bodyH - qh, {
        color = UBUI.Colors.clear,
        padding = 12,
        spacing = 8,
    })

    q[4] = body:NewArea("BR", 0, 0, bodyW - qw, bodyH - qh, {
        color = UBUI.Colors.clear,
        padding = 12,
        spacing = 8,
    })

    if q[1] ~= nil then
        q[1]:SetAnchor(0, 1)
        q[1]:SetPivot(0, 1)
    end

    if q[2] ~= nil then
        q[2]:SetAnchor(1, 1)
        q[2]:SetPivot(1, 1)
    end

    if q[3] ~= nil then
        q[3]:SetAnchor(0, 0)
        q[3]:SetPivot(0, 0)
    end

    if q[4] ~= nil then
        q[4]:SetAnchor(1, 0)
        q[4]:SetPivot(1, 0)
    end

    if q[1] ~= nil then
        local quad = q[1]
        local qcw = quad:ContentWidth()
        local cw = qcw - 60
        local sv = nil
        local svHeadH = 42

        quad:Space(svHeadH)

        sv = quad:ScrollView({
            w = qcw,
            h = 170,
            vertical = true,
            padding = 8,
            spacing = 6,
            border = true,
        })

        if sv ~= nil then
            sv:Header(svHeadH, {
                label = "<b>UBUI ScrollView</b>",
                titleAlign = "MiddleLeft",
                titleSize = 20,
            })

            sv:HeaderRow("right", { spacing = 6 })
                :Button("<b>Hide</b>", function()
                    if sv ~= nil then
                        sv:ToggleScroll()
                    end
                end, bopts({
                    w = 64,
                    h = 30,
                    style = "button",
                }))

            local c = sv.body

            c:Toggle("<b>Toggle item</b>", true, function()
            end, {
                w = cw,
                style = "toggle",
            })

            c:Button("<b>Button item</b>", function()
            end, bopts({
                w = cw,
                style = "button",
            }))

            c:Text("Text item inside the scroll view.", {
                w = cw,
                h = 28,
                fontSize = 16,
                style = "text",
            })

            for i = 1, 6 do
                c:Text("Row " .. basicModule.tostring(i), {
                    w = cw,
                    h = 26,
                    fontSize = 16,
                    style = "text",
                })
            end
        end

        quad:Button("<b>RandomFit</b>", function()
            if sv ~= nil then
                sv:SetVertical(math.random())
            end
        end, bopts({
            w = qcw,
            style = "button",
        }))
    end

    if q[2] ~= nil then
        local quad = q[2]
        local qcw = quad:ContentWidth()
        local hw = halfW(qcw)
        local imageH = 150
        local imageHost
        local img, fillT, t360, fillSlider
        local negativeRotation, positiveRotation
        local rotationSync = false

        imageHost = quad:NewArea("TextureHost", 0, 0, qcw, imageH, {
            color = UBUI.Colors.clear,
            padding = 0,
            spacing = 0,
        })

        if imageHost ~= nil then
            imageHost:SetAnchor(0.5, 1)
            imageHost:SetPivot(0.5, 1)

            img = imageHost:Image({
                x = 0,
                y = imageH / 2,
                w = 160,
                h = imageH,
                fixed = true,
                texture = TEX,
                color = UBUI.Colors.white,
                preserveAspect = true,
            })

            if img ~= nil then
                img:SetAnchor(0.5, 1)
                img:SetPivot(0.5, 0.5)
            end
        end

        quad:Space(imageH)

        local function rotateImage(value, other)
            if rotationSync then return end

            rotationSync = true

            if other ~= nil then
                other:SetValue(0)
            end

            if img ~= nil then
                img:Rotate(value)
            end

            rotationSync = false
        end

        quad:BeginRow(32)

        negativeRotation = quad:Slider(0, -180, 0, function(value)
            rotateImage(value, positiveRotation)
        end, sopts({
            w = hw,
            wholeNumbers = true,
            style = "slider",
        }))

        positiveRotation = quad:Slider(0, 0, 180, function(value)
            rotateImage(value, negativeRotation)
        end, sopts({
            w = hw,
            wholeNumbers = true,
            style = "slider",
        }))

        quad:EndRow()
        quad:BeginRow(34)

        fillT = quad:Toggle("<b>Fill</b>", false, function(state)
            if img == nil then return end

            if state then
                img:SetImageType("filled")
                img:SetFillMethod("radial360")
                img:SetFillAmount(
                    fillSlider ~= nil and fillSlider:GetValue() or 1
                )
            else
                img:SetImageType("simple")

                if t360 ~= nil then
                    t360:SetValue(false)
                end
            end
        end, {
            w = hw,
            style = "toggle",
        })

        t360 = quad:Toggle("<b>360</b>", false, function(state)
            if img == nil then return end

            if state then
                if fillT ~= nil then
                    fillT:SetValue(true)
                end

                img:SetImageType("filled")
                img:SetFillMethod("radial360")
                img:SetFillAmount(
                    fillSlider ~= nil and fillSlider:GetValue() or 1
                )
            else
                img:SetFillMethod("horizontal")
            end
        end, {
            w = hw,
            style = "toggle",
        })

        quad:EndRow()

        fillSlider = quad:Slider(1, 0, 1, function(value)
            if img ~= nil then
                img:SetFillAmount(value)
            end
        end, sopts({
            w = qcw,
            style = "slider",
        }))

        quad:BeginRow(34)

        quad:Toggle("<b>Outline</b>", false, function(state)
            if img == nil then return end

            if state then
                img:Outline({
                    color = UBUI.RandomVector4(),
                    distance = math.random(1, 4),
                })
            else
                UBUI.SetOutlineEnabled(img, false)
            end
        end, {
            w = hw,
            style = "toggle",
        })

        quad:Toggle("<b>Shadow</b>", false, function(state)
            if img == nil then return end

            if state then
                img:Shadow({
                    color = UBUI.RandomVector4(),
                    x = math.random(2, 5),
                    y = -math.random(2, 5),
                })
            else
                UBUI.SetShadowEnabled(img, false)
            end
        end, {
            w = hw,
            style = "toggle",
        })

        quad:EndRow()

        if img ~= nil then
            img:SetAnchor(0.5, 1)
            img:SetPivot(0.5, 0.5)
        end
    end

    if q[3] ~= nil then
        local quad = q[3]
        local qcw = quad:ContentWidth()
        local picker, input, nameLabel
        local controls
        local host
        local ringHost

        local pad = 12
        local btnW, btnH = 140, 36
        local pickerScale = 0.80
        local pickerW = 257.2
        local leftW = qcw - pickerW - 16
        local labelH = 22
        local sliderH = 32
        local ringH = labelH + sliderH + 4

        local palette = {
            { "Red", UBUI.Colors.red },
            { "Green", UBUI.Colors.green },
            { "Blue", UBUI.Colors.blue },
            { "Yellow", UBUI.Colors.yellow },
            { "Orange", UBUI.Colors.orange },
            { "Cyan", UBUI.Colors.cyan },
            { "Magenta", UBUI.Colors.magenta },
            { "Purple", UBUI.Colors.purple },
            { "Pink", UBUI.Colors.pink },
            { "White", UBUI.Colors.white },
            { "Black", UBUI.Colors.black },
            { "Gray", UBUI.Colors.gray },
        }

        local function nearest(color)
            local cr = UBUI.Chan(color, "x", "r", 0)
            local cg = UBUI.Chan(color, "y", "g", 0)
            local cb = UBUI.Chan(color, "z", "b", 0)
            local bestName = palette[1][1]
            local bestDistance = nil

            for i = 1, #palette do
                local current = palette[i][2]
                local dr = cr - UBUI.Chan(current, "x", "r", 0)
                local dg = cg - UBUI.Chan(current, "y", "g", 0)
                local db = cb - UBUI.Chan(current, "z", "b", 0)
                local distance = dr * dr + dg * dg + db * db

                if bestDistance == nil or distance < bestDistance then
                    bestDistance = distance
                    bestName = palette[i][1]
                end
            end

            return bestName
        end

        local function rgbToHSV(color)
            local r = UBUI.Chan(color, "x", "r", 0)
            local g = UBUI.Chan(color, "y", "g", 0)
            local b = UBUI.Chan(color, "z", "b", 0)
            local maximum = math.max(r, g, b)
            local minimum = math.min(r, g, b)
            local delta = maximum - minimum
            local h = 0

            if delta > 0 then
                if maximum == r then
                    h = ((g - b) / delta) % 6
                elseif maximum == g then
                    h = (b - r) / delta + 2
                else
                    h = (r - g) / delta + 4
                end

                h = h / 6
            end

            local s = 0

            if maximum > 0 then
                s = delta / maximum
            end

            return h, s, maximum
        end

        local function setPicker(color)
            if picker == nil or color == nil then return end

            local h, s, v = rgbToHSV(color)
            picker:SetHSV(h, s, v)
        end

        local function updateInfo()
            if picker == nil or nameLabel == nil then return end

            local color = picker:GetPickerColor()
            if color == nil then return end

            nameLabel:SetText("<b>This is " .. nearest(color) .. "</b>")
        end

        local function applyTheme(name)
            local keep = picker ~= nil and picker:GetPickerColor() or nil

            UBUI.SetTheme(name)
            UBUI.Refresh()

            if keep ~= nil then
                setPicker(keep)
            end

            updateInfo()
        end

        controls = quad:NewArea(
            "PickerControls",
            pad,
            pad,
            leftW,
            quad.h - pad * 2,
            {
                color = UBUI.Colors.clear,
                padding = 0,
                spacing = 8,
            }
        )

        if controls ~= nil then
            controls:SetAnchor(0, 1)
            controls:SetPivot(0, 1)

            controls:Button("<b>Dark Theme</b>", function()
                applyTheme("dark")
            end, bopts({
                w = btnW,
                h = btnH,
                style = "button",
            }))

            controls:Button("<b>Light Theme</b>", function()
                applyTheme("light")
            end, bopts({
                w = btnW,
                h = btnH,
                style = "button",
            }))

            controls:Button("<b>Random</b>", function()
                local color = UBUI.RandomVector4()

                setPicker(color)

                if input ~= nil then
                    input:SetValue(UBUI.ToHex(color))
                end

                updateInfo()
            end, bopts({
                w = btnW,
                h = btnH,
                style = "button",
            }))

            nameLabel = controls:Text("<b>This is</b> -", {
                w = leftW,
                h = 26,
                fontSize = 16,
                align = "MiddleLeft",
                style = "text",
            })

            input = controls:InputField("#8CA0FF", function(value)
                setPicker(UBUI.ParseColor(value))
                updateInfo()
            end, {
                w = leftW * 0.85,
                h = 40,
                style = "input",
            })
        end

        host = quad:NewArea("PickerHost", -pad, pad, pickerW, pickerW, {
            color = UBUI.Colors.clear,
            padding = 0,
            spacing = 0,
        })

        if host ~= nil then
            host:SetAnchor(1, 1)
            host:SetPivot(1, 1)

            picker = host:ColorPicker(
                UBUI.ParseColor("#8CA0FF"),
                function(color, element)
                    if input ~= nil then
                        input:SetValue(element:GetHex())
                    end

                    updateInfo()
                end,
                {
                    scale = pickerScale,
                }
            )

            if picker ~= nil then
                picker:SetPickerAnchor(
                    Vector2.New(1, 1),
                    Vector2.New(1, 1),
                    Vector2.New(1, 1),
                    Vector2.New(0, 0)
                )

                setPicker(UBUI.ParseColor("#8CA0FF"))
            end
        end

        ringHost = quad:NewArea("RingHost", 0, -pad, qcw, ringH, {
            color = UBUI.Colors.clear,
            padding = 0,
            spacing = 4,
        })

        if ringHost ~= nil then
            ringHost:SetAnchor(0.5, 0)
            ringHost:SetPivot(0.5, 0)

            ringHost:Text("<b>Ring thickness</b>", {
                w = qcw,
                h = labelH,
                fontSize = 16,
                align = "MiddleCenter",
                style = "text",
            })

            ringHost:Slider(
                picker ~= nil and picker:GetHueThickness() or 0.195,
                0.05,
                0.5,
                function(value)
                    if picker ~= nil then
                        picker:SetHueThickness(value)
                    end
                end,
                sopts({
                    w = qcw,
                    h = sliderH,
                    style = "slider",
                })
            )
        end

        updateInfo()
    end

    if q[4] ~= nil then
        local quad = q[4]
        local qcw = quad:ContentWidth()
        local hw = halfW(qcw)
        local zoneColors = {
            UBUI.ParseColor("#E8536AFF"),
            UBUI.ParseColor("#4FB477FF"),
        }
        local zoneNames = { "Red", "Green" }
        local zones = {}
        local selectedZone = 1
        local zoneStatus, zoneSlider

        local stageH = 150
        local stage = quad:NewArea("BRStage", 0, 0, qcw, stageH, {
            color = UBUI.ParseColor("#0C0F1AFF"),
            clipping = true,
            raycast = true,
        })

        if stage ~= nil then
            stage:SetAnchor(0.5, 1)
            stage:SetPivot(0.5, 1)

            local zoneW, zoneH = 190, 100

            for i = 1, 2 do
                local offsetX = i == 1 and -30 or 30
                local offsetY = i == 1 and -20 or 20

                local zone = stage:NewArea(
                    "Zone_" .. zoneNames[i],
                    offsetX,
                    offsetY,
                    zoneW,
                    zoneH,
                    {
                        color = zoneColors[i],
                        padding = 8,
                        raycast = true,
                    }
                )

                if zone ~= nil then
                    zone:SetAnchor(0.5, 0.5)
                    zone:SetPivot(0.5, 0.5)

                    zone:Text("<b>" .. zoneNames[i] .. "</b>", {
                        w = zoneW - 16,
                        h = 24,
                        align = "MiddleLeft",
                        style = "text",
                    })

                    zones[i] = zone
                end
            end
        end

        quad:Space(stageH)

        local function syncZone()
            local zone = zones[selectedZone]
            if zone == nil then return end

            local layer = zone:GetRenderLayer()

            if zoneSlider ~= nil then
                zoneSlider:SetValue(layer or 0)
            end

            if zoneStatus ~= nil then
                zoneStatus:SetText(
                    "<b>Area:</b> " .. zoneNames[selectedZone] ..
                    " <b>order:</b> " ..
                    (layer ~= nil and basicModule.tostring(layer) or "-")
                )
            end
        end

        quad:BeginRow(30)

        quad:Button("<b>Red</b>", function()
            selectedZone = 1
            syncZone()
        end, bopts({
            w = hw,
            style = "button",
        }))

        quad:Button("<b>Green</b>", function()
            selectedZone = 2
            syncZone()
        end, bopts({
            w = hw,
            style = "button",
        }))

        quad:EndRow()

        zoneStatus = quad:Text("", {
            w = qcw,
            h = 24,
            fontSize = 16,
            style = "text",
        })

        zoneSlider = quad:Slider(0, 0, 10, function(value)
            local zone = zones[selectedZone]

            if zone ~= nil then
                zone:SetRenderLayer(value)
            end

            syncZone()
        end, sopts({
            w = qcw,
            wholeNumbers = true,
            style = "slider",
        }))

        syncZone()
    end
end


local function Build()
    if built and win ~= nil and win:IsAlive() then return true end
    UI()
    if G.win == nil then return false end
    G.win:Close()
    built = true
    return true
end

local function Open()
    if not built or win == nil or not win:IsAlive() then
        if not Build() then return end
    end
    if G.win ~= nil then G.win:Open() end
end

local function Close()
    if G.win ~= nil then G.win:Close() end
end

local function IsOpen()
    if G.win == nil then return false end
    return G.win:IsOpen()
end

local function ToggleMenu()
    if IsOpen() then Close() else Open() end
end

local function ClearState()
    G = {}
    win = nil
    built = false
    buildDelay = 0
    lastOpen = false
    Input.LockedMouse = true
end

local function Reset()
    if UBUI ~= nil then
        local group = UBUI.GetGroup("ui")

        if group ~= nil then
            group:DestroyItems()
        end

        UBUI.InvalidateSpaces()
    end

    ClearState()
end

local function GameMasterReady()
    if UBUI == nil then return false end

    local ok, gameMaster = errorHandling.pcall(function()
        return GameObject.FindByName("GameMaster")
    end)

    return ok and UBUI.IsAlive(gameMaster)
end

local function CreateCanvas(scene)
    if UBUI == nil then return false end
    if scene == "sys_Menu" then return false end
    if not GameMasterReady() then return false end

    canvas = UBUI.NewCanvas("UBUI_ExampleCanvas", {
        renderMode = "ScreenSpaceOverlay",
        sortingOrder = 500,
        overrideSorting = true,
        pixelPerfect = true,
        uiScaleMode = "ScaleWithScreenSize",
        referenceWidth = 1920,
        referenceHeight = 1080,
        matchWidthOrHeight = 0.5,
    })

    if canvas == nil or not UBUI.IsAlive(canvas.obj) then
        canvas = nil
        return false
    end

    UBUI.DefineSpace("example", "UBUI_ExampleCanvas")

    return true
end

local function CanvasReady(scene)
    if UBUI == nil then return false end
    if scene == "sys_Menu" then return false end
    if not GameMasterReady() then return false end

    if canvas == nil then
        return CreateCanvas(scene)
    end

    if UBUI.IsAlive(canvas.obj) then
        return true
    end

    DestroyRuntime()

    return CreateCanvas(scene)
end

function Awake()
    local root = GetRoot()
    if root == nil then
        Debug.Log("Example: mod folder not found!")
        return
    end
    UBUI = File.DoFile(root .. "ubui.lua")
    if UBUI == nil then
        Debug.Log("Example: ubui.lua failed to load!")
        return
    end
    if UBUI.LoadStyles(root .. "ubuistyles.lua") == nil then
        Debug.Log("Example: ubuistyles.lua failed to load!")
        UBUI = nil
        return
    end
    TEX = Importer.ImportTexture("resources/t.png")
    if TEX == nil or not TEX.IsValid() then
        Debug.Log("Example: t.png failed to load!")
    end
end

function Start()
    lastScene = EnvironmentMaster.GetCurrentScene()
end

function OnLocalSpawned()
end

function OnChatMessage(msg, sndr)
    if msg == nil then return end
    if string.lower(msg) == "!example" then ToggleMenu() end
end

function Update()
    if UBUI == nil then return end

    local scene = EnvironmentMaster.GetCurrentScene()

    if scene ~= lastScene then
        lastScene = scene
        Reset()
    end

    if scene == "sys_Menu" then
        if canvas ~= nil or built then
            DestroyRuntime()
        end

        return
    end

    if not CanvasReady(scene) then
        return
    end

    UBUI.UIUpdate()

    if not built then
        if buildDelay > 0 then
            buildDelay = buildDelay - 1
        elseif not Build() then
            buildDelay = 30
        end
    end

    local open = IsOpen()

    if open ~= lastOpen then
        lastOpen = open
        Input.LockedMouse = not open
    end
end

function OnUnload()
	if UBUI ~= nil then
        UBUI.DestroyAll()
    end
end
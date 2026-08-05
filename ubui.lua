-- Unity Based User Interface Library
-- v1.05
-- Made By Wosek

local UBUI = {}

UBUI.VERSION = "1.0"

UBUI.IMAGE_TYPE  = { simple = 0, sliced = 1, tiled = 2, filled = 3 }
UBUI.FILL_METHOD = { horizontal = 0, vertical = 1, radial90 = 2, radial180 = 3, radial360 = 4 }

UBUI.Styles  = nil
UBUI.PREFABS = nil
UBUI.Theme   = nil
UBUI.SIZES   = nil
UBUI.ALIGN   = nil
UBUI.Colors  = nil

UBUI._owned = UBUI._owned or {}
UBUI._ownedById = UBUI._ownedById or {}
UBUI._ownedFree = UBUI._ownedFree or {}
UBUI._ownedHigh = UBUI._ownedHigh or #UBUI._owned
UBUI._ownedCount = UBUI._ownedCount or #UBUI._owned
UBUI._ownedIndex = UBUI._ownedIndex
    or metaTable.setmetatable({}, { __mode = "k" })
UBUI._ownedIds = UBUI._ownedIds
    or metaTable.setmetatable({}, { __mode = "k" })
UBUI._ownedFallback = UBUI._ownedFallback
    or metaTable.setmetatable({}, { __mode = "k" })
UBUI._pruneOwnedCursor = UBUI._pruneOwnedCursor or 1
UBUI._pruneOwnedActive = UBUI._pruneOwnedActive or false
UBUI._prefabCache = UBUI._prefabCache or {}
UBUI._canvases = UBUI._canvases or {}
UBUI._lifecycleToken = UBUI._lifecycleToken or 0

local function LogFailure(scope, err)
    Debug.Log(
        "<color=#FF6B6B>[UBUI Error]</color>: " ..
        basicModule.tostring(scope) .. ": " ..
        basicModule.tostring(err)
    )
end

local function LogWarning(scope, warning)
    local message =
        basicModule.tostring(scope) .. ": " ..
        basicModule.tostring(warning)

    Debug.Log(
        "<color=#F2B84B>[UBUI Warning]</color>: " ..
        message
    )
end

local function LogError(err)
    LogFailure("", err)
end

UBUI.LogFailure = LogFailure
UBUI.LogWarning = LogWarning

function UBUI._SafeCall(scope, fn, ...)
    if basicModule.type(fn) ~= "function" then
        LogFailure(scope, "callback is not a function")
        return false, nil
    end

    local args = table.pack(...)
    local results = nil

    local ok, err = errorHandling.pcall(function()
        results = table.pack(
            fn(table.unpack(args, 1, args.n))
        )
    end)

    if not ok then
        LogFailure(scope, err)
        return false, nil
    end

    return true, table.unpack(results, 1, results.n)
end

function UBUI.GetField(comp, field, fallback, scope, required)
    if not UBUI.IsAlive(comp) then
        if required == true then
            LogWarning(
                scope or "GetField",
                "component is not valid for field " ..
                basicModule.tostring(field)
            )
        end

        return fallback
    end

    local ok, value = UBUI._SafeCall(
        scope or "GetField." .. basicModule.tostring(field),
        function()
            return comp.GetField(field)
        end
    )

    if not ok or value == nil then
        if value == nil and required == true then
            LogWarning(
                scope or "GetField",
                "field " .. basicModule.tostring(field) ..
                " returned nil"
            )
        end

        return fallback
    end

    return value
end

local function NormalizeFieldValue(field, value)
    if value == nil then return nil end

    local key = string.lower(basicModule.tostring(field))

    if key ~= "sprite" and key ~= "texture" then
        return value
    end

    local ok, raw = errorHandling.pcall(function()
        if key == "sprite" then
            return value.sprite
        end

        return value.texture
    end)

    if ok and raw ~= nil then
        return raw
    end

    return value
end

function UBUI.SetField(comp, field, value, scope, required)
    if not UBUI.IsAlive(comp) then
        if required == true then
            LogWarning(
                scope or "SetField",
                "component is not valid for field " ..
                basicModule.tostring(field)
            )
        end

        return false
    end

    local ok = UBUI._SafeCall(
        scope or "SetField." .. basicModule.tostring(field),
        function()
            comp.SetField(
                field,
                NormalizeFieldValue(field, value)
            )
        end
    )

    return ok
end

UBUI._objectsById = UBUI._objectsById or {}

local function ObjectOf(target)
    if target == nil then return nil end

    if basicModule.type(target) == "table" then
        local ok, obj = errorHandling.pcall(function()
            return target.obj
        end)

        if ok and obj ~= nil then return obj end
    end

    return target
end

function UBUI.GetInstanceId(target)
    local obj = ObjectOf(target)
    if not UBUI.IsAlive(obj) then return nil end

    local ok, id = errorHandling.pcall(function()
        return obj.GetInstanceId()
    end)

    if not ok or id == nil then
        ok, id = errorHandling.pcall(function()
            return obj.GetInstanceID()
        end)
    end

    if not ok then return nil end
    return UBUI.Num(id, nil)
end

function UBUI.GetObjectByInstanceId(id)
    local key = UBUI.Num(id, nil)
    if key == nil then return nil end

    local obj = UBUI._objectsById[key]
    if not UBUI.IsAlive(obj) then
        UBUI._objectsById[key] = nil
        return nil
    end

    if UBUI.GetInstanceId(obj) ~= key then
        UBUI._objectsById[key] = nil
        return nil
    end

    return obj
end

function UBUI.SameObject(a, b)
    if a == b then return true end

    local aId = UBUI.GetInstanceId(a)
    local bId = UBUI.GetInstanceId(b)

    return aId ~= nil and aId == bId
end

function UBUI._IndexObject(obj)
    local id = UBUI.GetInstanceId(obj)
    if id ~= nil then UBUI._objectsById[id] = obj end
    return id
end

function UBUI._ForgetObject(target)
    local id = nil

    if basicModule.type(target) == "table" then
        id = UBUI.Num(target.instanceId, nil)
    end

    if id == nil then id = UBUI.GetInstanceId(target) end
    if id == nil then return end

    local obj = UBUI._objectsById[id]
    if obj == nil or UBUI.SameObject(obj, target) then
        UBUI._objectsById[id] = nil
    end
end

local function AddOwnedObject(obj, id)
    local slot = table.remove(UBUI._ownedFree)

    if slot == nil then
        UBUI._ownedHigh = UBUI._ownedHigh + 1
        slot = UBUI._ownedHigh
    end

    UBUI._owned[slot] = obj
    UBUI._ownedIndex[obj] = slot
    UBUI._ownedIds[obj] = id
    UBUI._ownedCount = UBUI._ownedCount + 1
end

local function RemoveOwnedObject(obj, id)
    local tracked = obj
    local indexed = nil

    if id ~= nil then
        indexed = UBUI._ownedById[id]
    end

    if indexed ~= nil then
        if obj ~= nil and (
            indexed == obj or
            UBUI.SameObject(indexed, obj)
        ) then
            tracked = indexed
        elseif obj == nil and not UBUI.IsAlive(indexed) then
            tracked = indexed
        end
    end

    if tracked == nil then return end

    local slot = UBUI._ownedIndex[tracked]

    if slot ~= nil and UBUI._owned[slot] == tracked then
        UBUI._owned[slot] = nil
        UBUI._ownedIndex[tracked] = nil
        UBUI._ownedIds[tracked] = nil
        UBUI._ownedCount = math.max(
            UBUI._ownedCount - 1,
            0
        )

        table.insert(UBUI._ownedFree, slot)
    end

    if id ~= nil and UBUI._ownedById[id] == tracked then
        UBUI._ownedById[id] = nil
    end

    if id ~= nil and UBUI._objectsById[id] == tracked then
        UBUI._objectsById[id] = nil
    end

    UBUI._ownedFallback[tracked] = nil
end

function UBUI._TrackOwned(obj)
    if not UBUI.IsAlive(obj) then
        return obj
    end

    local id = UBUI._IndexObject(obj)

    if id ~= nil then
        local current = UBUI._ownedById[id]

        if current == obj then
            return obj
        end

        if UBUI.IsAlive(current) then
            return obj
        end

        if current ~= nil then
            RemoveOwnedObject(current, id)
        end

        UBUI._ownedById[id] = obj
        AddOwnedObject(obj, id)

        return obj
    end

    if UBUI._ownedFallback[obj] then
        return obj
    end

    UBUI._ownedFallback[obj] = true
    AddOwnedObject(obj, nil)

    return obj
end

function UBUI._PruneOwned()
    local budget = math.floor(UBUI.Num(
        UBUI.PRUNE_BUDGET,
        4
    ))

    if budget < 1 then
        budget = 1
    end

    local first = UBUI._pruneOwnedCursor
    local last = math.min(
        first + budget - 1,
        UBUI._ownedHigh
    )

    for i = first, last do
        local obj = UBUI._owned[i]

        if obj ~= nil and not UBUI.IsAlive(obj) then
            RemoveOwnedObject(
                obj,
                UBUI._ownedIds[obj]
            )
        end
    end

    UBUI._pruneOwnedCursor = last + 1

    if UBUI._pruneOwnedCursor > UBUI._ownedHigh then
        UBUI._pruneOwnedCursor = 1
        UBUI._pruneOwnedActive = false
        return true
    end

    return false
end

local function RemoveArrayValue(list, value)
    if list == nil then return end

    for i = #list, 1, -1 do
        local current = list[i]

        if current == value or UBUI.SameObject(current, value) then
            table.remove(list, i)
        end
    end
end

function UBUI._Untrack(target)
    if target == nil then return end

    if basicModule.type(target) == "table"
    and UBUI.ClearEventHooks ~= nil then
        UBUI.ClearEventHooks(target)
    end

    local object = ObjectOf(target)
    local instanceId = UBUI.GetInstanceId(target)

    if instanceId == nil
    and basicModule.type(target) == "table" then
        instanceId = UBUI.Num(target.instanceId, nil)
    end

    if instanceId == nil and object ~= nil then
        instanceId = UBUI._ownedIds[object]
    end

    RemoveOwnedObject(object, instanceId)
    UBUI._ForgetObject(target)

    RemoveArrayValue(UBUI._windows, target)
    RemoveArrayValue(UBUI._scrollViews, target)
    RemoveArrayValue(UBUI._pickers, target)

    if UBUI._fx ~= nil and object ~= nil then
        UBUI._fx[object] = nil
    end

    for i = #UBUI._watchers, 1, -1 do
        if UBUI._watchers[i].el == target then
            table.remove(UBUI._watchers, i)
        end
    end

    for _, group in tableIterators.pairs(UBUI.GROUPS) do
        if group ~= nil and group.Remove ~= nil then
            UBUI._SafeCall("Group.Remove", function()
                group:Remove(target)
            end)
        end
    end

    local emptyTags = {}

    for tag, items in tableIterators.pairs(UBUI._tagged) do
        RemoveArrayValue(items, target)

        if #items == 0 then
            table.insert(emptyTags, tag)
        end
    end

    for i = 1, #emptyTags do
        UBUI._tagged[emptyTags[i]] = nil
    end
end

function UBUI.UseStyles(styles)
    if basicModule.type(styles) ~= "table" then
        LogFailure(
            "UseStyles",
            "styles must be a table"
        )

        return nil
    end

    local requiredTables = {
        "PREFABS",
        "Theme",
        "SIZES",
        "ALIGN",
        "Colors",
    }

    for _, key in tableIterators.ipairs(requiredTables) do
        if basicModule.type(styles[key]) ~= "table" then
            LogFailure(
                "UseStyles",
                "missing table " .. key
            )

            return nil
        end
    end

    if basicModule.type(styles.Merge) ~= "function" or
        basicModule.type(styles.StyleFromOpts) ~= "function" then
        LogFailure(
            "UseStyles",
            "styles module is incomplete"
        )

        return nil
    end

    if UBUI.Styles ~= nil and UBUI.Styles ~= styles then
        UBUI.Styles._UBUIOnChange = nil
    end

    UBUI.Styles = styles
    UBUI.PREFABS = styles.PREFABS
    UBUI.Theme = styles.Theme
    UBUI.SIZES = styles.SIZES
    UBUI.ALIGN = styles.ALIGN
    UBUI.Colors = styles.Colors

    styles._UBUIOnChange = function()
        UBUI.Refresh()
    end

    return styles
end

function UBUI.LoadStyles(path)
    local ok, styles = UBUI._SafeCall(
        "LoadStyles." .. basicModule.tostring(path),
        function()
            return File.DoFile(path)
        end
    )

    if not ok or styles == nil then
        LogFailure(
            "LoadStyles",
            "failed to load " .. basicModule.tostring(path)
        )

        return nil
    end

    if basicModule.type(styles) ~= "table" then
        LogFailure(
            "LoadStyles",
            "styles module didn't return table"
        )

        return nil
    end

    return UBUI.UseStyles(styles)
end

function UBUI.HasStyles()
    if UBUI.Styles ~= nil then return true end
    return false
end

function UBUI.StyleOpts(styleName, opts)
    local o
    if UBUI.Styles == nil then o = opts or {} else o = UBUI.Styles.Merge(styleName, opts) end
    o._style = styleName
    o._opts  = opts
    return o
end

local function StyleCall(method, ...)
    if UBUI.Styles == nil then
        LogWarning(
            "Styles." .. basicModule.tostring(method),
            "styles module is not loaded"
        )

        return nil
    end

    local fn = UBUI.Styles[method]

    if basicModule.type(fn) ~= "function" then
        LogFailure(
            "Styles." .. basicModule.tostring(method),
            "method not found"
        )

        return nil
    end

    local ok, result = UBUI._SafeCall(
        "Styles." .. basicModule.tostring(method),
        fn,
        ...
    )

    if not ok then return nil end
    return result
end

function UBUI.NewStyle(def)
    return StyleCall("NewStyle", def)
end

function UBUI.DefineStyle(name, def, base)
    return StyleCall("DefineStyle", name, def, base)
end

function UBUI.GetStyle(name)
    return StyleCall("GetStyle", name)
end

function UBUI.SetStyleValue(name, field, value)
    return StyleCall("SetStyleValue", name, field, value)
end

function UBUI.ApplyStyle(target, style)
    return StyleCall("ApplyStyle", target, style)
end

function UBUI.DefineTheme(name, def, base)
    return StyleCall("DefineTheme", name, def, base)
end

function UBUI.SetTheme(name)
    return StyleCall("SetTheme", name)
end

function UBUI.SetThemeValue(key, value)
    return StyleCall("SetThemeValue", key, value)
end

function UBUI.Restyle(target)
    if UBUI.Styles == nil or target == nil then return target end
    if not UBUI.IsAlive(target.obj) then return target end
    if target.styleName ~= nil then UBUI.ApplyStyle(target, target.styleName) end
    local u = target.userOpts
    if u ~= nil then
        if u.style ~= nil then UBUI.ApplyStyle(target, u.style) end
        UBUI.ApplyStyle(target, UBUI.Styles.StyleFromOpts(u))
    end
    return target
end

function UBUI.Refresh()
    for i = 1, #UBUI._windows do
        local win = UBUI._windows[i]

        if win ~= nil and win:IsAlive() then
            UBUI._SafeCall("Window.Restyle", function()
                win:Restyle()
            end)
        end
    end

    return UBUI
end

UBUI._watchers = {}
UBUI._windows = {}
UBUI.SPACES = {}
UBUI._scrollViews = {}
UBUI._frame = 0
UBUI.PRUNE_INTERVAL = 120
UBUI.PRUNE_BUDGET = 4096
UBUI.AUTO_PRUNE_LIMIT = 4096

function UBUI.Color(r, g, b, a)
    if a == nil then a = 1 end
    return Vector4.New(r, g, b, a)
end

function UBUI.WithAlpha(c, a)
    if c == nil then return nil end
    return Vector4.New(c.x, c.y, c.z, a)
end

function UBUI.Darken(c, factor, floorValue)
    if c == nil then return nil end
    if factor == nil then factor = 0.35 end
    if floorValue == nil then floorValue = 0.04 end
    local r, g, b = c.x * factor, c.y * factor, c.z * factor
    if r < floorValue then r = floorValue end
    if g < floorValue then g = floorValue end
    if b < floorValue then b = floorValue end
    return Vector4.New(r, g, b, c.w)
end

function UBUI.HexDigit(ch)
    local chars = "0123456789ABCDEF"
    local idx = string.find(chars, string.upper(ch), 1, true)
    if idx == nil then return nil end
    return idx - 1
end

local HEXCHARS = "0123456789ABCDEF"

local function hexByte(v)
    local n = math.floor((v or 0) * 255 + 0.5)
    if n < 0 then n = 0 end
    if n > 255 then n = 255 end
    local hi = math.floor(n / 16) + 1
    local lo = n - (hi - 1) * 16 + 1
    return string.sub(HEXCHARS, hi, hi) .. string.sub(HEXCHARS, lo, lo)
end

function UBUI.HexToColor(hex)
    if basicModule.type(hex) ~= "string" then return nil end
    local clean = string.gsub(hex, "%s+", "")
    if string.sub(clean, 1, 1) == "#" then
        clean = string.sub(clean, 2)
    end
    clean = string.upper(clean)
    local length = string.len(clean)
    if length ~= 6 and length ~= 8 then
        return nil
    end
    local function byteAt(index)
        local high = UBUI.HexDigit(
            string.sub(clean, index, index)
        )
        local low = UBUI.HexDigit(
            string.sub(clean, index + 1, index + 1)
        )
        if high == nil or low == nil then return nil end
        return high * 16 + low
    end
    local red = byteAt(1)
    local green = byteAt(3)
    local blue = byteAt(5)
    if red == nil or green == nil or blue == nil then
        return nil
    end
    local alpha = 255
    if length == 8 then
        alpha = byteAt(7)
        if alpha == nil then return nil end
    end
    return Vector4.New(
        red / 255,
        green / 255,
        blue / 255,
        alpha / 255
    )
end

function UBUI.HexToVector4(hex, alpha)
    local c = UBUI.HexToColor(hex)
    if c == nil then return nil end
    if alpha == nil then return c end
    return Vector4.New(c.x, c.y, c.z, alpha)
end

function UBUI.HexToVector3(hex)
    local c = UBUI.HexToColor(hex)
    if c == nil then return nil end
    return Vector3.New(c.x, c.y, c.z)
end

function UBUI.ToHex(c, withAlpha)
    if c == nil then return "#FFFFFF" end
    local s = "#" .. hexByte(c.x) .. hexByte(c.y) .. hexByte(c.z)
    if withAlpha == true then
        local a = c.w
        if a == nil then a = 1 end
        s = s .. hexByte(a)
    end
    return s
end

UBUI.ColorToHex = UBUI.ToHex

function UBUI.ParseColor(str)
    if str == nil then return nil end
    local s = string.gsub(str, "%s+", "")
    if s == "" then return nil end
    local named = nil
    if UBUI.Colors ~= nil then named = UBUI.Colors[string.lower(s)] end
    if named ~= nil then return Vector4.New(named.x, named.y, named.z, named.w) end
    return UBUI.HexToColor(s)
end

function UBUI.RandomVector4(withAlpha)
    local a = 1
    if withAlpha == true then
        a = math.random()
    elseif withAlpha ~= nil and withAlpha ~= false then
        a = UBUI.Num(withAlpha, 1)
    end
    return Vector4.New(math.random(), math.random(), math.random(), a)
end

function UBUI.RandomVector3()
    local c = UBUI.RandomVector4(1)
    return Vector3.New(c.x, c.y, c.z)
end

function UBUI.RandomHex(withAlpha)
    local c = UBUI.RandomVector4(withAlpha)
    return UBUI.ToHex(c, withAlpha ~= nil and withAlpha ~= false)
end

function UBUI.RandomPaletteColor(withAlpha)
    if UBUI.Colors == nil then return UBUI.RandomVector4(withAlpha) end
    local keys = {}
    for k in tableIterators.pairs(UBUI.Colors) do
        if k ~= "clear" then table.insert(keys, k) end
    end
    if #keys == 0 then return UBUI.RandomVector4(withAlpha) end
    local c = UBUI.Colors[keys[math.random(1, #keys)]]
    local a = c.w
    if withAlpha == true then a = math.random()
    elseif withAlpha ~= nil and withAlpha ~= false then a = UBUI.Num(withAlpha, c.w) end
    return Vector4.New(c.x, c.y, c.z, a)
end

function UBUI.DefineSpace(name, path)
    UBUI.SPACES[name] = { path = path, go = nil, t = nil }
end

UBUI.CANVAS_SCALER_COMP = "UnityEngine.UI.CanvasScaler"

local CANVAS_RENDER_MODES = {
    screenspaceoverlay = 0, overlay = 0,
    screenspacecamera = 1, camera = 1,
    worldspace = 2, world = 2,
}

local CANVAS_SCALE_MODES = {
    constantpixelsize = 0,
    scalewithscreensize = 1,
    constantphysicalsize = 2,
}

local function resolveParentTransform(parent)
    if parent == nil then return nil end
    if basicModule.type(parent) == "string" then
        return UBUI.ResolvePath(parent)
    end
    if basicModule.type(parent) == "table" then
        local ok, inner = errorHandling.pcall(function() return parent.obj end)
        if ok and UBUI.IsAlive(inner) then
            if inner.Transform ~= nil then return inner.Transform end
        end
        if UBUI.IsAlive(parent) and parent.Transform ~= nil then
            return parent.Transform
        end
        return parent
    end
    if UBUI.IsAlive(parent) and parent.Transform ~= nil then
        return parent.Transform
    end
    return parent
end

function UBUI.NewCanvas(name, opts)
    local o = opts or {}
    local objectName = basicModule.tostring(name or UBUI.NextName("Canvas"))

    local ok, obj = UBUI._SafeCall("Canvas.GameObject.Create", function()
        return GameObject.Create(objectName)
    end)
    if not ok or not UBUI.IsAlive(obj) then
        LogError("Canvas GameObject creation failed")
        return nil
    end

    local parentT = resolveParentTransform(o.parent)
    if parentT ~= nil then
        UBUI._SafeCall("Canvas.SetParent", function()
            obj.Transform.SetParent(parentT, false)
        end)
    end

    obj.Active = true

    local addOk, canvas = UBUI._SafeCall("Canvas.AddComponent", function()
        return obj.AddComponent(UBUI.CANVAS_COMP)
    end)
    if not addOk or not UBUI.IsAlive(canvas) then
        LogError("Canvas component creation failed")
        errorHandling.pcall(function() obj.DestroyLocal() end)
        return nil
    end

    local scaler = nil
    if o.scaler ~= false then
        local scOk, scComp = UBUI._SafeCall("CanvasScaler.AddComponent", function()
            return obj.AddComponent(UBUI.CANVAS_SCALER_COMP)
        end)
        if scOk and UBUI.IsAlive(scComp) then scaler = scComp end
    end

    local raycaster = nil
    if o.raycaster ~= false then
        local rcOk, rcComp = UBUI._SafeCall("GraphicRaycaster.AddComponent", function()
            return obj.AddComponent(UBUI.RAYCASTER_COMP)
        end)
        if rcOk and UBUI.IsAlive(rcComp) then raycaster = rcComp end
    end

    UBUI._SafeCall("Canvas.Configure", function()
        canvas.SetField("renderMode", UBUI.EnumVal(CANVAS_RENDER_MODES, o.renderMode, 0))
        canvas.SetField("pixelPerfect", UBUI.Bool(o.pixelPerfect))
        if o.sortingOrder ~= nil then
            canvas.SetField("sortingOrder", UBUI.Num(o.sortingOrder, 0))
        end
        if o.overrideSorting ~= nil then
            canvas.SetField("overrideSorting", UBUI.Bool(o.overrideSorting))
        end
        if o.sortingLayerName ~= nil then
            canvas.SetField("sortingLayerName", basicModule.tostring(o.sortingLayerName))
        end
        if o.additionalShaderChannels ~= nil then
            canvas.SetField("additionalShaderChannels", o.additionalShaderChannels)
        end
    end)

    if scaler ~= nil then
        UBUI._SafeCall("CanvasScaler.Configure", function()
            scaler.SetField("uiScaleMode",
                UBUI.EnumVal(CANVAS_SCALE_MODES, o.uiScaleMode, 1))
            scaler.SetField("referenceResolution", Vector2.New(
                UBUI.Num(o.referenceWidth, 1920),
                UBUI.Num(o.referenceHeight, 1080)))
            scaler.SetField("matchWidthOrHeight", UBUI.Num(o.matchWidthOrHeight, 0.5))
            scaler.SetField("referencePixelsPerUnit",
                UBUI.Num(o.referencePixelsPerUnit, 100))
        end)
    end

    UBUI._TrackOwned(obj)

    if o.space ~= nil then
        local spaceName = basicModule.tostring(o.space)
        UBUI.SPACES[spaceName] = { path = objectName, go = obj, t = obj.Transform }
    end

    local handle = {
	    obj = obj,
	    transform = obj.Transform,
	    canvas = canvas,
	    scaler = scaler,
	    raycaster = raycaster,
	    name = objectName,
	    space = o.space,
	}
	
	table.insert(UBUI._canvases, handle)
	
	return handle
end

function UBUI.DestroyCanvas(canvasHandle)
    if basicModule.type(canvasHandle) ~= "table" then return end

    for i = #UBUI._canvases, 1, -1 do
        if UBUI._canvases[i] == canvasHandle then
            table.remove(UBUI._canvases, i)
            break
        end
    end

    local obj = canvasHandle.obj
    local space = canvasHandle.space

    if space ~= nil then
        UBUI.SPACES[space] = nil
    end

    canvasHandle.obj = nil
    canvasHandle.transform = nil
    canvasHandle.canvas = nil
    canvasHandle.scaler = nil
    canvasHandle.raycaster = nil
    canvasHandle.space = nil

    UBUI._Untrack(obj)

    if UBUI.IsAlive(obj) then
        UBUI._SafeCall("Canvas.DestroyLocal", function()
            obj.DestroyLocal()
        end)
    end
end

UBUI.DefineSpace("base", "GameMaster/GameCanvas-3")

function UBUI.ResolvePath(path)
    if path == nil then return nil end
    local rootName, rest
    local idx = string.find(path, "/", 1, true)
    if idx == nil then
        rootName = path
    else
        rootName = string.sub(path, 1, idx - 1)
        rest = string.sub(path, idx + 1)
    end
    local ok, go = UBUI._SafeCall("ResolvePath.FindByName", function()
        return GameObject.FindByName(rootName)
    end)
    if not ok or not UBUI.IsAlive(go) then return nil end
    local t = go.Transform
    if rest ~= nil and rest ~= "" then
        local findOk, child = UBUI._SafeCall("ResolvePath.Find", function()
            return t.Find(rest)
        end)
        if not findOk or not UBUI.IsAlive(child) then return nil end
        t = child
    end
    return t
end

function UBUI.GetSpace(name)
    if name == nil then name = "base" end
    local s = UBUI.SPACES[name]
    if s == nil then
        LogError("unknown space " .. basicModule.tostring(name))
        return nil
    end
    if UBUI.IsAlive(s.go) and s.t ~= nil then return s.t end
    s.go = nil
    s.t  = nil
    local t = UBUI.ResolvePath(s.path)
    if t == nil then
        LogError("space path not found " .. basicModule.tostring(s.path) .. "")
        return nil
    end
    s.go = t.GameObject
    s.t  = t
    return t
end

function UBUI.InvalidateSpaces()
    for k, v in tableIterators.pairs(UBUI.SPACES) do
        v.go = nil
        v.t  = nil
    end
end

function UBUI.Num(value, fallback)
    if value == nil then return fallback end
    local n = basicModule.tonumber(value)
    if n == nil then return fallback end
    return n
end

function UBUI.Bool(value)
    if value == true  then return true  end
    if value == false or value == nil then return false end
    local s = string.lower(basicModule.tostring(value))
    if s == "true" or s == "1" then return true end
    return false
end

function UBUI.EnumVal(map, v, fb)
    if v == nil then return fb end
    local n = map[string.lower(basicModule.tostring(v))]
    if n ~= nil then return n end
    return UBUI.Num(v, fb)
end

function UBUI.Vec2Num(v)
    if v == nil then return nil, nil end
    return UBUI.Num(v.x, 0), UBUI.Num(v.y, 0)
end

function UBUI.GetNum(comp, field, fallback)
    local value = UBUI.GetField(
        comp,
        field,
        nil,
        "GetNum." .. basicModule.tostring(field),
        false
    )

    return UBUI.Num(value, fallback)
end

function UBUI.ScreenSize() return UBUI.Vec2Num(Input.GetScreenRect()) end

function UBUI.IsAlive(obj)
    if obj == nil or obj.IsValid == nil then return false end

    local ok, alive = errorHandling.pcall(function()
        return obj.IsValid()
    end)

    return ok and alive == true
end

function UBUI.GetCachedPrefab(path)
    if path == nil then return nil end

    local key = basicModule.tostring(path)
    local prefab = UBUI._prefabCache[key]

    if UBUI.IsAlive(prefab) then
        return prefab
    end

    UBUI._prefabCache[key] = nil

    local ok, loaded = UBUI._SafeCall(
        "GameObject.GetPrefab",
        function()
            return GameObject.GetPrefab(path)
        end
    )

    if not ok or not UBUI.IsAlive(loaded) then
        return nil
    end

    UBUI._prefabCache[key] = loaded
    return loaded
end

function UBUI.GetRect(obj)
    if obj == nil then return nil end

    if basicModule.type(obj) == "table" then
        local ok, inner = UBUI._SafeCall("GetRect.Unwrap", function()
            return obj.obj
        end)

        if ok and inner ~= nil then
            obj = inner
        end
    end

    if not UBUI.IsAlive(obj) or obj.GetComponent == nil then
        return nil
    end

    local ok, rect = UBUI._SafeCall("GetRect", function()
        return obj.GetComponent("UnityEngine.RectTransform")
    end)

    if not ok or not UBUI.IsAlive(rect) then return nil end
    return rect
end

function UBUI.SetTopRect(obj, x, y, w, h)
    local rect = UBUI.GetRect(obj)

    if rect == nil then
        LogWarning("SetTopRect", "RectTransform not found")
        return false
    end

    local nx = UBUI.Num(x, 0)
    local ny = UBUI.Num(y, 0)
    local nw = UBUI.Num(w, 0)
    local nh = UBUI.Num(h, 0)
    local ok = true

    ok = UBUI.SetField(
        rect,
        "anchorMin",
        Vector2.New(0, 1),
        "SetTopRect.anchorMin",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchorMax",
        Vector2.New(0, 1),
        "SetTopRect.anchorMax",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "pivot",
        Vector2.New(0, 1),
        "SetTopRect.pivot",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(nw, nh),
        "SetTopRect.sizeDelta",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(nx, -ny),
        "SetTopRect.anchoredPosition",
        true
    ) and ok

    return ok
end

function UBUI.SetCenterRect(obj, x, y, w, h)
    local rect = UBUI.GetRect(obj)

    if rect == nil then
        LogWarning("SetCenterRect", "RectTransform not found")
        return false
    end

    local ok = true

    ok = UBUI.SetField(
        rect,
        "anchorMin",
        Vector2.New(0.5, 0.5),
        "SetCenterRect.anchorMin",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchorMax",
        Vector2.New(0.5, 0.5),
        "SetCenterRect.anchorMax",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "pivot",
        Vector2.New(0.5, 0.5),
        "SetCenterRect.pivot",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(
            UBUI.Num(w, 0),
            UBUI.Num(h, 0)
        ),
        "SetCenterRect.sizeDelta",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(
            UBUI.Num(x, 0),
            UBUI.Num(y, 0)
        ),
        "SetCenterRect.anchoredPosition",
        true
    ) and ok

    return ok
end

function UBUI.GetTopRect(obj)
    local rect = UBUI.GetRect(obj)
    if rect == nil then return nil end

    local position = UBUI.GetField(
        rect,
        "anchoredPosition",
        nil,
        "GetTopRect.anchoredPosition",
        true
    )

    local size = UBUI.GetField(
        rect,
        "sizeDelta",
        nil,
        "GetTopRect.sizeDelta",
        true
    )

    local px, py = UBUI.Vec2Num(position)
    local sw, sh = UBUI.Vec2Num(size)

    if px == nil or py == nil or sw == nil or sh == nil then
        return nil
    end

    return px, -py, sw, sh
end

function UBUI.StretchRect(rect, dw, dh)
    if not UBUI.IsAlive(rect) then
        LogWarning("StretchRect", "RectTransform is not valid")
        return false
    end

    local ok = true

    ok = UBUI.SetField(
        rect,
        "anchorMin",
        Vector2.New(0, 0),
        "StretchRect.anchorMin",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchorMax",
        Vector2.New(1, 1),
        "StretchRect.anchorMax",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "pivot",
        Vector2.New(0.5, 0.5),
        "StretchRect.pivot",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(
            UBUI.Num(dw, 0),
            UBUI.Num(dh, 0)
        ),
        "StretchRect.sizeDelta",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(0, 0),
        "StretchRect.anchoredPosition",
        true
    ) and ok

    return ok
end


function UBUI.StretchRectH(rect, dw, height)
    if not UBUI.IsAlive(rect) then
        LogWarning("StretchRectH", "RectTransform is not valid")
        return false
    end

    if height == nil then
        return UBUI.StretchRect(rect, dw, 0)
    end

    local ok = true

    ok = UBUI.SetField(
        rect,
        "anchorMin",
        Vector2.New(0, 0.5),
        "StretchRectH.anchorMin",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchorMax",
        Vector2.New(1, 0.5),
        "StretchRectH.anchorMax",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "pivot",
        Vector2.New(0.5, 0.5),
        "StretchRectH.pivot",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(
            UBUI.Num(dw, 0),
            UBUI.Num(height, 0)
        ),
        "StretchRectH.sizeDelta",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(0, 0),
        "StretchRectH.anchoredPosition",
        true
    ) and ok

    return ok
end

function UBUI.LeftStretchRectH(rect, dw, height)
    if not UBUI.IsAlive(rect) then
        LogWarning("LeftStretchRectH", "RectTransform is not valid")
        return false
    end

    local yMin, yMax = 0.5, 0.5

    if height == nil then
        yMin, yMax, height = 0, 1, 0
    end

    local ok = true

    ok = UBUI.SetField(
        rect,
        "anchorMin",
        Vector2.New(0, yMin),
        "LeftStretchRectH.anchorMin",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchorMax",
        Vector2.New(1, yMax),
        "LeftStretchRectH.anchorMax",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "pivot",
        Vector2.New(0, 0.5),
        "LeftStretchRectH.pivot",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(
            -UBUI.Num(dw, 0),
            UBUI.Num(height, 0)
        ),
        "LeftStretchRectH.sizeDelta",
        true
    ) and ok

    ok = UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(0, 0),
        "LeftStretchRectH.anchoredPosition",
        true
    ) and ok

    return ok
end


function UBUI.ParentRectOf(comp)
    if comp == nil then return nil end
    local ok, parentGo = UBUI._SafeCall("ParentRectOf", function()
        local pt = comp.GameObject.Transform.Parent
        if pt == nil then return nil end
        return pt.GameObject
    end)
    if not ok or parentGo == nil then return nil end
    return UBUI.GetRect(parentGo)
end

function UBUI.RectOf(comp)
    if comp == nil then return nil end
    local ok, go = UBUI._SafeCall("RectOf", function()
        return comp.GameObject
    end)
    if not ok or go == nil then return nil end
    return UBUI.GetRect(go)
end

local function GetComponentSafe(obj, name, children)
    if not UBUI.IsAlive(obj) then return nil end

    local method = children == true
        and "GetComponentInChildren"
        or "GetComponent"

    local ok, comp = UBUI._SafeCall(
        method .. "." .. basicModule.tostring(name),
        function()
            return obj[method](name)
        end
    )

    if not ok or not UBUI.IsAlive(comp) then return nil end
    return comp
end

function UBUI.GetTextComp(obj)
    local comp = GetComponentSafe(
        obj,
        "TMPro.TextMeshProUGUI",
        false
    )

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "UnityEngine.UI.Text",
            false
        )
    end

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "TMPro.TextMeshProUGUI",
            true
        )
    end

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "UnityEngine.UI.Text",
            true
        )
    end

    return comp
end


function UBUI.GetInputComp(obj)
    local comp = GetComponentSafe(
        obj,
        "TMPro.TMP_InputField",
        false
    )

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "UnityEngine.UI.InputField",
            false
        )
    end

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "TMPro.TMP_InputField",
            true
        )
    end

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "UnityEngine.UI.InputField",
            true
        )
    end

    return comp
end

function UBUI.GetComp(obj, name)
    local comp = GetComponentSafe(obj, name, false)

    if comp == nil then
        comp = GetComponentSafe(obj, name, true)
    end

    return comp
end

function UBUI.GetImageComp(obj)
    local comp = GetComponentSafe(
        obj,
        "UnityEngine.UI.Image",
        false
    )

    if comp == nil then
        comp = GetComponentSafe(
            obj,
            "UnityEngine.UI.Image",
            true
        )
    end

    return comp
end

function UBUI.ImgComp(el)
    if el == nil or not el:IsAlive() then return nil end
    if el.imageComp == nil then el.imageComp = UBUI.GetImageComp(el.obj) end
    return el.imageComp
end

function UBUI.SetRaycast(obj, state)
    if not UBUI.IsAlive(obj) then return false end

    local image = GetComponentSafe(
        obj,
        "UnityEngine.UI.Image",
        false
    )

    if image == nil then return false end

    return UBUI.SetField(
        image,
        "raycastTarget",
        state == true,
        "SetRaycast",
        false
    )
end

function UBUI.DisableChildTextRaycast(obj)
    if not UBUI.IsAlive(obj) then return end
    local names = { "TMPro.TextMeshProUGUI", "UnityEngine.UI.Text" }
    for i = 1, #names do
        local ok, comps = UBUI._SafeCall("DisableChildTextRaycast", function()
            return obj.GetComponentsInChildren(names[i])
        end)
        if ok and comps ~= nil then
            for j = 1, #comps do
                UBUI.SetField(comps[j], "raycastTarget", false, "DisableChildTextRaycast", false)
            end
        end
    end
end

function UBUI.NewImageObject(parentTransform, name, x, y, w, h, color, raycast)
    if not UBUI.IsAlive(parentTransform) then
        LogError("invalid parent")
        return nil
    end
    local objectName = basicModule.tostring(name or UBUI.NextName("Image"))
    local ok, obj = UBUI._SafeCall("GameObject.Create", function()
        return GameObject.Create(objectName)
    end)
    if not ok or not UBUI.IsAlive(obj) then return nil end
    local function fail(message)
        LogError(
            "" ..
            basicModule.tostring(message) ..
            " for " ..
            objectName
        )
        if UBUI.IsAlive(obj) then
            errorHandling.pcall(function()
                obj.DestroyLocal()
            end)
        end
        return nil
    end
    ok = UBUI._SafeCall("NewImageObject", function()
        obj.Active = true
        obj.Transform.SetParent(parentTransform, false)
    end)
    if not ok then return fail("initialization failed") end
    local rect = obj.GetComponent("UnityEngine.RectTransform")
    if not UBUI.IsAlive(rect) then
        rect = obj.AddComponent("UnityEngine.RectTransform")
    end
    if not UBUI.IsAlive(rect) then
        return fail("RectTransform creation failed")
    end
    local img = obj.GetComponent("UnityEngine.UI.Image")
    if not UBUI.IsAlive(img) then
        img = obj.AddComponent("UnityEngine.UI.Image")
    end
    if not UBUI.IsAlive(img) then
        return fail("Image creation failed")
    end
	ok = UBUI._SafeCall("Image setup", function()
        UBUI.SetField(img, "type", 0, "NewImageObject.type", true)
        UBUI.SetField(img, "enabled", true, "NewImageObject.enabled", true)
        UBUI.SetField(img, "color", color or UBUI.Colors.white, "NewImageObject.color", true)
        UBUI.SetField(img, "raycastTarget", raycast == true, "NewImageObject.raycastTarget", true)
        UBUI.SetTopRect(obj, x, y, w, h)
    end)
    if not ok then return fail("Image setup failed") end
    UBUI._TrackOwned(obj)
    return obj
end

function UBUI.CopyPrefab(path, parentTransform, name, x, y, w, h)
    if not UBUI.IsAlive(parentTransform) then
        LogError("invalid prefab parent")
        return nil
    end

    local prefab = UBUI.GetCachedPrefab(path)

    if not UBUI.IsAlive(prefab) then
        LogError(
            "<color=#FF6B6B>missing prefab</color> " ..
            basicModule.tostring(path)
        )

        return nil
    end

    local copyOk, obj = UBUI._SafeCall(
        "GameObject.Copy",
        function()
            return GameObject.Copy(prefab)
        end
    )

    if not copyOk or not UBUI.IsAlive(obj) then
        return nil
    end

    local setupOk = UBUI._SafeCall(
        "Prefab setup",
        function()
            obj.Name = basicModule.tostring(
                name or UBUI.NextName("Prefab")
            )

            obj.Active = true
            obj.Transform.SetParent(parentTransform, false)
            UBUI.SetTopRect(obj, x, y, w, h)
        end
    )

    if not setupOk then
        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)

        return nil
    end

    if UBUI.GetRect(obj) == nil then
        LogError(
            "<color=#FF6B6B>prefab has no RectTransform</color>: " ..
            basicModule.tostring(path)
        )

        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)

        return nil
    end

    UBUI._TrackOwned(obj)
    return obj
end

function UBUI.PrefabRectSize(path)
    local w, h = nil, nil

    errorHandling.pcall(function()
        local prefab = UBUI.GetCachedPrefab(path)
        if not UBUI.IsAlive(prefab) then return end

        local rt = prefab.GetComponent(
            "UnityEngine.RectTransform"
        )

        if not UBUI.IsAlive(rt) then return end

        w, h = UBUI.Vec2Num(UBUI.GetField(
            rt,
            "sizeDelta",
            nil,
            "PrefabRectSize",
            false
        ))
    end)

    return w, h
end

function UBUI.SlotRect(el, w, h)
    return w, h
end

UBUI._uid = 0

function UBUI.NextName(prefix)
    UBUI._uid = UBUI._uid + 1

    return "UBUI_" ..
        basicModule.tostring(prefix or "Element") ..
        "_" ..
        basicModule.tostring(UBUI._uid)
end

function UBUI.Chan(v, a, b, fallback)
    if v == nil then return fallback end
    local out = nil
    errorHandling.pcall(function() out = v[a] end)
    if out == nil then errorHandling.pcall(function() out = v[b] end) end
    return UBUI.Num(out, fallback)
end

function UBUI.ToColor(v)
    if v == nil then return nil end
    return UBUI.Color(UBUI.Chan(v, "x", "r", 0), UBUI.Chan(v, "y", "g", 0),
        UBUI.Chan(v, "z", "b", 0), UBUI.Chan(v, "w", "a", 1))
end

function UBUI.CompColor(comp)
    if comp == nil then return nil end
    return UBUI.ToColor(UBUI.GetField(comp, "color", nil, "CompColor", false))
end

function UBUI.FindChildObject(root, path)
    if basicModule.type(root) == "table" and root.obj ~= nil then
        root = root.obj
    end
    if not UBUI.IsAlive(root) then return nil end
    if basicModule.type(path) ~= "string" or path == "" then return nil end
    if not UBUI.IsAlive(root.Transform) then return nil end
    local ok, transform = errorHandling.pcall(function()
        return root.Transform.Find(path)
    end)
    if not ok or not UBUI.IsAlive(transform) then return nil end
    local child = transform.GameObject
    if not UBUI.IsAlive(child) then return nil end
    return child
end

local function HasEventMethod(event, method)
    if event == nil then return false end

    local ok, value = errorHandling.pcall(function()
        return event[method]
    end)

    return ok and value ~= nil
end

function UBUI.UnhookEvent(holder, key)
    if basicModule.type(holder) ~= "table" then return false end
    if holder._ubuiEventHooks == nil then return true end

    local hook = holder._ubuiEventHooks[key]
    if hook == nil then return true end

    local ok = true

    if hook.listener ~= nil
        and HasEventMethod(hook.event, "RemoveListener") then
        ok = UBUI._SafeCall(
            hook.scope or "UnhookEvent",
            function()
                hook.event.RemoveListener(hook.listener)
            end
        )
    end

    holder._ubuiEventHooks[key] = nil
    return ok
end

function UBUI.ClearEventHooks(holder)
    if basicModule.type(holder) ~= "table" then return end
    if holder._ubuiEventHooks == nil then return end

    local keys = {}

    for key in tableIterators.pairs(holder._ubuiEventHooks) do
        table.insert(keys, key)
    end

    for i = 1, #keys do
        UBUI.UnhookEvent(holder, keys[i])
    end

    holder._ubuiEventHooks = nil
end

function UBUI.HookEvent(event, holder, key, listener, scope)
    if not HasEventMethod(event, "AddListener") then return false end
    if basicModule.type(holder) ~= "table" then return false end
    if basicModule.type(listener) ~= "function" then return false end
    if key == nil then return false end

    holder._ubuiEventHooks = holder._ubuiEventHooks or {}

    if holder._ubuiEventHooks[key] ~= nil
        and not UBUI.UnhookEvent(holder, key) then
        return false
    end

    local ok = UBUI._SafeCall(
        scope or "HookEvent",
        function()
            event.AddListener(listener)
        end
    )

    if ok then
        holder._ubuiEventHooks[key] = {
            event = event,
            listener = listener,
            scope = scope
        }
    end

    return ok
end

function UBUI.HookClick(comp, holder, key, invoke)
    if not UBUI.IsAlive(comp) then return false end
    if basicModule.type(holder) ~= "table" then return false end
    if key == nil then return false end

    local event = UBUI.GetField(
        comp,
        "onClick",
        nil,
        "HookClick",
        false
    )

    if event == nil then return false end

    local listener = function()
        local fn = holder[key]
        if basicModule.type(fn) ~= "function" then return end

        UBUI._SafeCall(
            "onClick." .. basicModule.tostring(key),
            function()
                if basicModule.type(invoke) == "function" then
                    invoke(fn, holder)
                else
                    fn(holder)
                end
            end
        )
    end

    return UBUI.HookEvent(
        event,
        holder,
        "click:" .. basicModule.tostring(key),
        listener,
        "HookClick." .. basicModule.tostring(key)
    )
end

local Border = {}
Border.__index = Border
UBUI.BorderClass = Border

local BORDER_SIDES = { "Top", "Bottom", "Left", "Right" }

local function resolveObj(target)
    if target == nil then return nil end
    local ok, inner = errorHandling.pcall(function() return target.obj end)
    if ok and inner ~= nil then return inner end
    return target
end

UBUI.RECT_MASK_COMP = "UnityEngine.UI.RectMask2D"
UBUI.MASK_COMP      = "UnityEngine.UI.Mask"

local function clippingValue(value)
    if value == nil then return true, false end

    local kind = basicModule.type(value)

    if kind == "boolean" then
        return true, value
    end

    if kind == "number" then
        local number = UBUI.Num(value, nil)

        if number == 0 then return true, false end
        if number == 1 then return true, true end
    elseif kind == "string" then
        local normalized = string.lower(value)

        if normalized == "false" or normalized == "0" then
            return true, false
        end

        if normalized == "true" or normalized == "1" then
            return true, true
        end
    end

    LogError(
        "clipping: invalid value " ..
        basicModule.tostring(value)
    )

    return false, nil
end

local function clippingComponent(obj, componentName)
    if not UBUI.IsAlive(obj) then return nil end

    local ok, component = errorHandling.pcall(function()
        return obj.GetComponent(componentName)
    end)

    if not ok or not UBUI.IsAlive(component) then return nil end
    return component
end

local function addClippingComponent(obj, componentName)
    local ok, component = UBUI._SafeCall("Clipping.AddComponent", function()
        return obj.AddComponent(componentName)
    end)

    if not ok or not UBUI.IsAlive(component) then return nil end
    return component
end

local function setClippingComponentEnabled(component, state)
    if not UBUI.IsAlive(component) then return false end
    return UBUI.SetField(
        component,
        "enabled",
        state,
        "Clipping.SetEnabled",
        false
    )
end

local function clippingComponentEnabled(component)
    if not UBUI.IsAlive(component) then return false end
    return UBUI.Bool(UBUI.GetField(
        component,
        "enabled",
        false,
        "Clipping.GetEnabled",
        false
    ))
end

function UBUI.HasClipping(target)
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then return false end
    return clippingComponentEnabled(clippingComponent(obj, UBUI.RECT_MASK_COMP)) or
        clippingComponentEnabled(clippingComponent(obj, UBUI.MASK_COMP))
end

function UBUI.SetClipping(target, state)
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then
        LogError("clipping target is not valid")
        return target
    end

    local valid, enabled = clippingValue(state)
    if not valid then return target end

    local rectMask = clippingComponent(obj, UBUI.RECT_MASK_COMP)
    local mask     = clippingComponent(obj, UBUI.MASK_COMP)
    local active   = nil

    if enabled then
        if rectMask == nil then
            rectMask = addClippingComponent(obj, UBUI.RECT_MASK_COMP)
        end

        if rectMask ~= nil and setClippingComponentEnabled(rectMask, true) then
            active = rectMask
            setClippingComponentEnabled(mask, false)
        else
            if mask == nil then
                mask = addClippingComponent(obj, UBUI.MASK_COMP)
            end

				if mask ~= nil and setClippingComponentEnabled(mask, true) then
                    active = mask
                    UBUI.SetField(
                        mask,
                        "showMaskGraphic",
                        true,
                        "Clipping.showMaskGraphic",
                        false
                    )
                end
        end

        if active == nil then
            LogError("RectMask2D and Mask creation failed")
        end
    else
        setClippingComponentEnabled(rectMask, false)
        setClippingComponentEnabled(mask, false)
    end

    if basicModule.type(target) == "table" then
        target.clipping     = active ~= nil
        target.clipComponent = active
    end
    
    if rectMask ~= nil then
        UBUI.SetField(
            rectMask,
            "padding",
            Vector4.New(-1, -1, -1, -1),
            "SetClipping.padding",
            true
        )
    end

    return target
end

function UBUI.Border(target, opts)
    local o = opts or {}
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then
        LogError("Border target is not valid")
        return nil
    end
    local b = metaTable.setmetatable({}, Border)
    b.target = obj
    b.mode = o.mode or "inside"
    b.thickness = o.thickness or UBUI.Theme.borderThickness
    b.color = o.color or UBUI.Theme.border
    b.gap = o.gap or 0
    b.visible = true
    b.name = o.name or UBUI.NextName("Border")
    if b.mode == "around" then
        local parentOk, parent = UBUI._SafeCall("Border.Parent", function()
            return obj.Transform.Parent
        end)
        b.parent = parentOk and parent or nil
        if b.parent == nil then b.parent = obj.Transform end
    else
        b.parent = obj.Transform
    end
    b.pieces = {}
    for i = 1, #BORDER_SIDES do
        local p = UBUI.NewImageObject(b.parent, b.name .. "_" .. BORDER_SIDES[i],
            0, 0, 1, 1, b.color, false)
        if p ~= nil and b.mode == "around" then UBUI.BringToFront(p) end
        b.pieces[i] = p
    end
    if target ~= obj then
        if target.borders == nil then target.borders = {} end
        table.insert(target.borders, b)
    end
    return b:Update()
end

function Border:IsAlive() return UBUI.IsAlive(self.target) end

function Border:Update()
    if not self:IsAlive() then return self end
    local x, y, w, h = UBUI.GetTopRect(self.target)
    if x == nil then return self end

    if self.mode == "inside" then x, y = 0, 0 end

    local g, t = self.gap, self.thickness
    x, y = x - g, y - g
    w, h = w + g * 2, h + g * 2

    local p = self.pieces
    UBUI.SetTopRect(p[1], x,         y,         w, t)
    UBUI.SetTopRect(p[2], x,         y + h - t, w, t)
    UBUI.SetTopRect(p[3], x,         y,         t, h)
    UBUI.SetTopRect(p[4], x + w - t, y,         t, h)

    if self.mode == "inside" then
        for i = 1, #p do
            if UBUI.IsAlive(p[i]) then UBUI.BringToFront(p[i]) end
        end
    end
    return self
end

function Border:SetColor(color)
    self.color = color
    for i = 1, #self.pieces do
        local img = UBUI.GetImageComp(self.pieces[i])
        UBUI.SetField(img, "color", color, "Border.SetColor", false)
    end
    return self
end

function Border:SetThickness(t) self.thickness = t; return self:Update() end
function Border:SetGap(g)       self.gap = g;       return self:Update() end

function Border:SetVisible(state)
    self.visible = state
    for i = 1, #self.pieces do
        if UBUI.IsAlive(self.pieces[i]) then self.pieces[i].Active = state end
    end
    return self
end

function Border:Show() return self:SetVisible(true) end
function Border:Hide() return self:SetVisible(false) end

function Border:Destroy()
    for i = 1, #self.pieces do
        local piece = self.pieces[i]
        UBUI._Untrack(piece)
        if UBUI.IsAlive(piece) then
            errorHandling.pcall(function()
                piece.DestroyLocal()
            end)
        end
    end
    self.pieces = {}
end

function UBUI.DestroyBorders(target)
    if basicModule.type(target) ~= "table" then return end
    if basicModule.type(target.borders) ~= "table" then return end

    local borders = target.borders
    target.borders = {}

    for i = #borders, 1, -1 do
        local border = borders[i]

        if border ~= nil and border.Destroy ~= nil then
            UBUI._SafeCall(
                "Border.Destroy",
                function()
                    border:Destroy()
                end
            )
        end
    end
end

UBUI.OUTLINE_COMP = "UnityEngine.UI.Outline"
UBUI.SHADOW_COMP  = "UnityEngine.UI.Shadow"

local FX_OUTLINE = "outline"
local FX_SHADOW  = "shadow"
local FX_COMP    = { outline = UBUI.OUTLINE_COMP, shadow = UBUI.SHADOW_COMP }
local FX_KIND    = {
    outline = FX_OUTLINE, shadow = FX_SHADOW,
    ["UnityEngine.UI.Outline"] = FX_OUTLINE,
    ["UnityEngine.UI.Shadow"]  = FX_SHADOW,
}

UBUI._fx = {}

local function themeNum(key, fallback)
    local t = UBUI.Theme
    if t ~= nil and t[key] ~= nil then return UBUI.Num(t[key], fallback) end
    return fallback
end

local function themeColor(key, fallback)
    local t = UBUI.Theme
    if t ~= nil and t[key] ~= nil then return t[key] end
    return fallback
end

local function fxStore(target, obj)
    if target ~= nil and target ~= obj then
        if target.fx == nil then target.fx = {} end
        return target.fx
    end
    local s = UBUI._fx[obj]
    if s == nil then s = {}; UBUI._fx[obj] = s end
    return s
end

local function ensureEffect(store, obj, kind)
    local comp = store[kind]
    if UBUI.IsAlive(comp) then return comp end
    store[kind] = nil
    local compName = FX_COMP[kind]
    local ok, found = UBUI._SafeCall("EnsureEffect.GetComponent", function()
        return obj.GetComponent(compName)
    end)
    if not ok then return nil end
    if kind == FX_SHADOW and found ~= nil then
        local outlineOk, outline = UBUI._SafeCall("EnsureEffect.CheckOutline", function()
            return obj.GetComponent(UBUI.OUTLINE_COMP)
        end)
        if outlineOk and outline ~= nil then found = nil end
    end
    if found == nil then
        local addOk
        addOk, found = UBUI._SafeCall("EnsureEffect.AddComponent", function()
            return obj.AddComponent(compName)
        end)
        if not addOk then return nil end
    end
    store[kind] = found
    return found
end

local function applyEffect(comp, color, dx, dy, useAlpha)
    if comp == nil then return nil end
    UBUI.SetField(comp, "effectColor", color, "ApplyEffect", false)
    UBUI.SetField(comp, "effectDistance", Vector2.New(dx, dy), "ApplyEffect", false)
    UBUI.SetField(comp, "useGraphicAlpha", useAlpha, "ApplyEffect", false)
    UBUI.SetField(comp, "enabled", true, "ApplyEffect", false)
    return comp
end

function UBUI.Outline(target, opts)
    local o   = opts or {}
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then
        LogError("Outline target is not valid")
        return nil
    end
    local d  = UBUI.Num(o.distance, themeNum("outlineDistance", 2))
    local dx = UBUI.Num(o.x, d)
    local dy = UBUI.Num(o.y, d)
    local color = o.color or themeColor("outline", UBUI.Color(0, 0, 0, 1))
    local useAlpha = o.useGraphicAlpha
    if useAlpha == nil then useAlpha = true end
    local store = fxStore(target, obj)
    return applyEffect(ensureEffect(store, obj, FX_OUTLINE), color, dx, dy, UBUI.Bool(useAlpha))
end

function UBUI.Shadow(target, opts)
    local o   = opts or {}
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then
        LogError("Shadow target is not valid")
        return nil
    end
    local dx = UBUI.Num(o.x, themeNum("shadowX", 2))
    local dy = UBUI.Num(o.y, themeNum("shadowY", -2))
    local color = o.color
    if color == nil then
        color = UBUI.WithAlpha(themeColor("shadow", UBUI.Color(0, 0, 0, 1)),
            UBUI.Num(o.alpha, themeNum("shadowAlpha", 0.5)))
    end
    local useAlpha = o.useGraphicAlpha
    if useAlpha == nil then useAlpha = true end
    local store = fxStore(target, obj)
    return applyEffect(ensureEffect(store, obj, FX_SHADOW), color, dx, dy, UBUI.Bool(useAlpha))
end

function UBUI.HasEffect(target, compName)
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then return false end
    return GetComponentSafe(obj, compName, false) ~= nil
end

function UBUI.HasOutline(target) return UBUI.HasEffect(target, UBUI.OUTLINE_COMP) end

function UBUI.HasShadow(target)
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then return false end
    if fxStore(target, obj)[FX_SHADOW] ~= nil then return true end
    if GetComponentSafe(obj, UBUI.SHADOW_COMP, false) == nil then return false end
    return GetComponentSafe(obj, UBUI.OUTLINE_COMP, false) == nil
end

function UBUI.SetEffectEnabled(target, kind, state)
    local obj = resolveObj(target)
    if not UBUI.IsAlive(obj) then return end
    local k  = FX_KIND[kind]
    if k == nil then return end
    local store = fxStore(target, obj)
    local comp  = store[k]
    if comp == nil then
        comp = GetComponentSafe(obj, FX_COMP[k], false)
        if k == FX_SHADOW and comp ~= nil and GetComponentSafe(obj, UBUI.OUTLINE_COMP, false) ~= nil then
            comp = nil
        end
        store[k] = comp
    end
    UBUI.SetField(comp, "enabled", state, "SetEffectEnabled", false)
end

function UBUI.SetOutlineEnabled(target, state) UBUI.SetEffectEnabled(target, FX_OUTLINE, state) end
function UBUI.SetShadowEnabled(target, state)  UBUI.SetEffectEnabled(target, FX_SHADOW, state)  end

local function rotate(target, degrees, scope)
    local obj = target and target.obj
    if obj == nil or not UBUI.IsAlive(obj) then return target end

    local angle = UBUI.Num(degrees, 0)
    UBUI._SafeCall(scope, function()
        obj.Transform.LocalRotation = Vector3.New(0, 0, angle)
    end)
    return target
end

local Element = {}
Element.__index = Element
UBUI.Element = Element

local function pickerComp(el)
    if el == nil or el.kind ~= "colorpicker" then
        return nil
    end

    if not el:IsAlive() then return nil end
    if not UBUI.IsAlive(el.pickerObj) then return nil end
    if not UBUI.IsAlive(el.comp) then return nil end

    local ok, owner = UBUI._SafeCall(
        "ColorPicker.ComponentOwner",
        function()
            return el.comp.GameObject
        end
    )

    if not ok or not UBUI.SameObject(owner, el.obj) then
        return nil
    end

    return el.comp
end

UBUI.PickerComp = pickerComp

function UBUI.NewElement(obj, kind, comp)
    local el = metaTable.setmetatable({}, Element)
    el.obj = obj
    el.instanceId = UBUI._IndexObject(obj)
    el.kind = kind
    el.comp = comp
    el.visible = true
    el.area = nil
    el.item = nil
    return el
end

function Element:IsAlive()  return UBUI.IsAlive(self.obj) end
function Element:GetInstanceId()
    if self.instanceId == nil then
        self.instanceId = UBUI.GetInstanceId(self.obj)
    end

    return self.instanceId
end
function Element:IsVisible() return self.visible end

function Element:SetText(text)
    if not self:IsAlive() then return self end
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    UBUI.SetField(self.textComp, "text", text, "Element.SetText", false)
    return self
end

function Element:GetText()
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    return UBUI.GetField(self.textComp, "text", "", "Element.GetText", false)
end

function Element:SetTextColor(color)
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    UBUI.SetField(self.textComp, "color", color, "Element.SetTextColor", false)
    return self
end

function Element:SetFontSize(size)
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    UBUI.SetField(self.textComp, "fontSize", size, "Element.SetFontSize", false)
    return self
end

function Element:SetTextAutoSize(state, min, max)
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    local c = self.textComp
    if c == nil then return self end
    local on = state ~= false
    local hi = UBUI.Num(max, UBUI.GetNum(c, "fontSize", 24))
    local lo = UBUI.Num(min, 8)
    UBUI.SetField(c, "enableAutoSizing", on, "Element.SetTextAutoSize", false)
    if on then
        UBUI.SetField(c, "fontSizeMin", lo, "Element.SetTextAutoSize", false)
        UBUI.SetField(c, "fontSizeMax", hi, "Element.SetTextAutoSize", false)
    end
    self.autoSize = on
    return self
end

function Element:SetTextPadding(padX, padY)
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    if self.textComp == nil then return self end
    local px = UBUI.Num(padX, 0)
    local py = UBUI.Num(padY, px)
    UBUI.StretchRect(UBUI.RectOf(self.textComp), -px * 2, -py * 2)
    self.textPad = px
    return self
end

function Element:SetAlign(alignName)
    local pair = UBUI.ALIGN[alignName]
    if pair == nil then return self end
    if not self:IsAlive() then return self end
    local tmp = UBUI.GetComp(self.obj, "TMPro.TextMeshProUGUI")
    if tmp ~= nil then
        UBUI.SetField(tmp, "alignment", pair[1], "Element.SetAlign", false)
        return self
    end
    local uit = UBUI.GetComp(self.obj, "UnityEngine.UI.Text")
    UBUI.SetField(uit, "alignment", pair[2], "Element.SetAlign", false)
    return self
end

function Element:Rotate(degrees)
    return rotate(self, degrees, "Element.Rotate")
end

function Element:SetWordWrap(state)
    if self.textComp == nil then self.textComp = UBUI.GetTextComp(self.obj) end
    UBUI.SetField(self.textComp, "enableWordWrapping", state, "Element.SetWordWrap", false)
    UBUI.SetField(self.textComp, "horizontalOverflow", state and 0 or 1, "Element.SetWordWrap", false)
    return self
end

function Element:SetColor(color)
    if not self:IsAlive() then return self end
    if self.imageComp == nil then self.imageComp = UBUI.GetImageComp(self.obj) end
    UBUI.SetField(self.imageComp, "color", color, "Element.SetColor", false)
    return self
end

function Element:SetTexture(texture)
    if not self:IsAlive() then return self end
    if not UBUI.IsAlive(texture) then return self end

    local image = UBUI.ImgComp(self)
    if image == nil then return self end

    local ok, sprite = UBUI._SafeCall(
        "Element.SetTexture.ToSprite",
        function()
            return texture.ToSprite()
        end
    )

    if not ok or not UBUI.IsAlive(sprite) then
        LogError("ToSprite failed")
        return self
    end

    local spriteOk = UBUI.SetField(
        image,
        "sprite",
        sprite,
        "Element.SetTexture.sprite",
        true
    )

    local aspectOk = UBUI.SetField(
        image,
        "preserveAspect",
        true,
        "Element.SetTexture.preserveAspect",
        false
    )

    if not spriteOk or not aspectOk then
        LogError("SetTexture failed")
    end

    return self
end

function Element:SetImageType(t)
    local c = UBUI.ImgComp(self)
    UBUI.SetField(c, "type", UBUI.EnumVal(UBUI.IMAGE_TYPE, t, 0), "Element.SetImageType", false)
    return self
end

function Element:SetFillMethod(m)
    local c = UBUI.ImgComp(self)
    UBUI.SetField(c, "fillMethod", UBUI.EnumVal(UBUI.FILL_METHOD, m, 4), "Element.SetFillMethod", false)
    return self
end

function Element:SetFillOrigin(o)
    local c = UBUI.ImgComp(self)
    UBUI.SetField(c, "fillOrigin", UBUI.Num(o, 0), "Element.SetFillOrigin", false)
    return self
end

function Element:SetFillClockwise(state)
    local c = UBUI.ImgComp(self)
    UBUI.SetField(c, "fillClockwise", state == true, "Element.SetFillClockwise", false)
    return self
end

function Element:SetFillAmount(a)
    local c = UBUI.ImgComp(self)
    if c == nil then return self end
    local n = UBUI.Num(a, 1)
    if n < 0 then n = 0 elseif n > 1 then n = 1 end
    UBUI.SetField(c, "fillAmount", n, "Element.SetFillAmount", false)
    return self
end

function Element:SetPreserveAspect(state)
    local c = UBUI.ImgComp(self)
    UBUI.SetField(c, "preserveAspect", state == true, "Element.SetPreserveAspect", false)
    return self
end

function Element:SetRect(x, y, w, h)
    x, y = UBUI.Num(x, 0), UBUI.Num(y, 0)
    w, h = UBUI.Num(w, 0), UBUI.Num(h, 0)

    if self.kind == "colorpicker" then
        if self._pickerHolderLayout == true then
            UBUI.SetTopRect(self.obj, x, y, w, h)

            if self.item ~= nil then
                self.item.x = x
                self.item.w = w
                self.item.h = h
            end

            return self
        end

        self:SetPickerRect(x, y, w, h)
        return self
    end

    UBUI.SetTopRect(self.obj, x, y, w, h)

    if self.item ~= nil then
        self.item.x = x
        self.item.w = w
        self.item.h = h
    end

    return self
end

function Element:SetSize(w, h)
    w, h = UBUI.Num(w, 0), UBUI.Num(h, 0)

    if self.kind == "colorpicker" then
        if self._pickerHolderLayout ~= true then
            self:SetPickerSize(w, h)
            return self
        end

        if self.item ~= nil then
            self.item.w = w
            self.item.h = h

            if self.item.line ~= nil and h > self.item.line.h then
                self.item.line.h = h
            end

            if self.area ~= nil then
                self.area:Relayout()
            end

            return self
        end

        local rect = UBUI.GetRect(self.obj)
        UBUI.SetField(rect, "sizeDelta", Vector2.New(w, h), "Element.SetSize", false)
        return self
    end

    if self.item ~= nil then
        self.item.w = w
        self.item.h = h

        if self.item.line ~= nil and h > self.item.line.h then
            self.item.line.h = h
        end

        if self.area ~= nil then self.area:Relayout() end

        if self.kind == "slider" then
            self.sliderH = h
            UBUI.ApplyHandleRect(self)
        end

        return self
    end

    local rect = UBUI.GetRect(self.obj)
    UBUI.SetField(rect, "sizeDelta", Vector2.New(w, h), "Element.SetSize", false)

    return self
end

function Element:SetVisible(state)
    self.visible = state
    if self:IsAlive() then self.obj.Active = state end
    if self.area ~= nil then self.area:Relayout() end
    return self
end

function Element:Show() return self:SetVisible(true) end
function Element:Hide() return self:SetVisible(false) end

function Element:SetInteractable(state)
    UBUI.SetField(self.comp, "interactable", state, "Element.SetInteractable", false)
    return self
end

function Element:SetOnClick(fn)  self.onClick  = fn; return self end
function Element:SetOnChange(fn) self.onChange = fn; return self end
function Element:SetStyle(style) return UBUI.ApplyStyle(self, style) end
function Element:NewStyle(def)    return UBUI.NewStyle(def):Apply(self) end

function Element:GetValue()
    if self.comp == nil then return nil end
    if self.kind == "colorpicker" then return self:GetHex() end
    if self.kind == "toggle" then
        return UBUI.Bool(UBUI.GetField(self.comp, "isOn", false, "Element.GetValue", false))
    end
    if self.kind == "input" then
        return basicModule.tostring(UBUI.GetField(self.comp, "text", "", "Element.GetValue", false) or "")
    end
    if self.kind == "slider" then
        return UBUI.Num(UBUI.GetField(self.comp, "value", nil, "Element.GetValue", false), self.min or 0)
    end
    return nil
end

function Element:SetValue(value)
    if self.comp == nil then return self end
    local v = value
    if self.kind == "colorpicker" then return self:SetPickerColor(value) end
    if self.kind == "toggle" then
        v = UBUI.Bool(value)
        UBUI.SetField(self.comp, "isOn", v, "Element.SetValue", false)
    end
    if self.kind == "input" then
        v = basicModule.tostring(value or "")
        UBUI.SetField(self.comp, "text", v, "Element.SetValue", false)
    end
    if self.kind == "slider" then
        v = UBUI.Num(value, self.min or 0)
        UBUI.SetField(self.comp, "value", v, "Element.SetValue", false)
    end
    for i = 1, #UBUI._watchers do
        local w = UBUI._watchers[i]
        if w.el == self then w.last = v end
    end
    return self
end

function Element:UpdateBorders()
    if self.borders == nil then return self end
    for i = 1, #self.borders do self.borders[i]:Update() end
    return self
end

function Element:Border(opts) return UBUI.Border(self, opts) end
function Element:Outline(opts) return UBUI.Outline(self, opts) end
function Element:Shadow(opts)  return UBUI.Shadow(self, opts)  end

function Element:Tag(tags)     return UBUI.Tag(self, tags) end
function Element:AddTo(group)  return UBUI.Attach(group, self) end

function Element:SetSliderColors(fillColor, bgColor)
    if self.kind ~= "slider" then return self end
    if fillColor ~= nil then UBUI.SetField(self.fillImage, "color", fillColor, "Element.SetSliderColors", false) end
    if bgColor ~= nil then UBUI.SetField(self.bgImage, "color", bgColor, "Element.SetSliderColors", false) end
    return self
end

function Element:SetHandleColor(color)
    if self.handleImage == nil then return self end
    self.handleColor = color
    if self.handleVisible == false then return self end
    UBUI.SetField(self.handleImage, "color", color, "Element.SetHandleColor", false)
    return self
end

function Element:SetHandleVisible(state)
    if self.handleImage == nil then return self end
    self.handleVisible = state
    local c = UBUI.Colors.clear
    if state then c = self.handleColor or UBUI.Colors.white end
    UBUI.SetField(self.handleImage, "color", c, "Element.SetHandleVisible", false)
    UBUI.ApplyFillArea(self)
    return self
end

function Element:SetHandleWidth(width)
    if self.handleImage == nil then return self end
    self.handleW = UBUI.Num(width, 0)
    UBUI.StretchRect(UBUI.ParentRectOf(self.handleImage), -self.handleW, 0)
    UBUI.ApplyHandleRect(self)
    UBUI.ApplyFillArea(self)
    return self
end

function Element:SetHandleHeight(height)
    if self.handleImage == nil then return self end
    self.handleH = height
    UBUI.ApplyHandleRect(self)
    return self
end

function Element:SetHandleSize(width, height)
    if width ~= nil then self:SetHandleWidth(width) end
    return self:SetHandleHeight(height)
end

function Element:SetTrackHeight(height)
    if self.kind ~= "slider" then return self end
    self.trackH = height
    UBUI.StretchRectH(UBUI.RectOf(self.bgImage), 0, height)
    UBUI.ApplyFillArea(self)
    return self
end

function Element:SetSliderRange(min, max)
    if self.comp == nil then return self end
    self.min, self.max = min, max
    UBUI.SetField(self.comp, "minValue", min, "Element.SetSliderRange", false)
    UBUI.SetField(self.comp, "maxValue", max, "Element.SetSliderRange", false)
    return self
end

function Element:GetPickerColor()
    local c = pickerComp(self)
    if c == nil then return nil end
    local raw = nil
    errorHandling.pcall(function() raw = c.CallMethod("GetColor") end)
    if raw ~= nil then return UBUI.ToColor(raw) end
    return nil
end

function Element:SetPickerColor(color)
    local c = pickerComp(self)
    if c == nil then return self end
    local col = color
    if basicModule.type(col) == "string" then col = UBUI.ParseColor(col) end
    if col == nil then return self end
    errorHandling.pcall(function()
        c.CallMethod("SetColor", Vector4.New(UBUI.Chan(col, "x", "r", 0),
            UBUI.Chan(col, "y", "g", 0),
            UBUI.Chan(col, "z", "b", 0), 1))
    end)
    self:RefreshPicker()
    self._lastHex = self:GetHex()
    return self
end

function Element:GetHex()
    local c = self:GetPickerColor()
    if c == nil then return nil end
    return UBUI.ToHex(c)
end
function Element:SetHex(hex) return self:SetPickerColor(hex) end

function Element:RefreshPicker()
    local c = pickerComp(self)
    if c == nil then return self end
    errorHandling.pcall(function() c.CallMethod("MoveHandlesToCurrent") end)
    errorHandling.pcall(function() c.CallMethod("UpdateSVTexture") end)
    errorHandling.pcall(function() c.CallMethod("UpdatePreview") end)
    return self
end

function Element:GetHSV()
    local c = pickerComp(self)
    if c == nil then return 0, 0, 0 end
    return UBUI.GetNum(c, "hue", 0), UBUI.GetNum(c, "saturation", 1), UBUI.GetNum(c, "value", 1)
end

function Element:SetHSV(h, s, v)
    local c = pickerComp(self)
    if c == nil then return self end
    UBUI.SetField(c, "hue", UBUI.Num(h, 0), "ColorPicker.SetHSV", false)
    UBUI.SetField(c, "saturation", UBUI.Num(s, 1), "ColorPicker.SetHSV", false)
    UBUI.SetField(c, "value", UBUI.Num(v, 1), "ColorPicker.SetHSV", false)
    self:RefreshPicker()
    self._lastHex = self:GetHex()
    return self
end

function Element:UseGBColors(state)
    local c = pickerComp(self)
    if c == nil then return self end
    UBUI.SetField(c, "useGBColors", state == true, "ColorPicker.UseGBColors", false)
    return self
end

function Element:SetHueThickness(t)
    local c = pickerComp(self)
    if c == nil then return self end
    self.hueThickness = UBUI.Num(t, 0.195)
    c.SetField("hueRingThickness", self.hueThickness)
    errorHandling.pcall(function() c.CallMethod("GenerateHueTexture") end)
    return self
end

Element.SetRingThickness = Element.SetHueThickness
Element.GetRingThickness = Element.GetHueThickness

function Element:GetPickerObject()
    if self.kind ~= "colorpicker" then return nil end
    if UBUI.IsAlive(self.pickerObj) then return self.pickerObj end
    if not self:IsAlive() then return nil end
    self.pickerObj = UBUI.FindChildObject(self.obj, "ColorPicker")
    if not UBUI.IsAlive(self.pickerObj) then self.pickerObj = self.obj end
    return self.pickerObj
end

function Element:GetPickerRect()
    if self.kind ~= "colorpicker" then return nil end

    if not UBUI.IsAlive(self.pickerObj) then
        LogWarning(
            "ColorPicker.GetRect",
            "child ColorPicker is not valid"
        )

        return nil
    end

    return UBUI.GetTopRect(self.pickerObj)
end

function Element:SetPickerRect(x, y, w, h)
    if self.kind ~= "colorpicker" then
        return self
    end

    local rect = UBUI.GetRect(self.pickerObj)

    if rect == nil then
        LogWarning(
            "ColorPicker.SetPickerRect",
            "ColorPicker has no RectTransform"
        )

        return self
    end

    local width = UBUI.Num(w, self.nativeW)
    local height = UBUI.Num(h, self.nativeH)

    if width == nil or height == nil then
        LogWarning(
            "ColorPicker.SetPickerRect",
            "ColorPicker size is not valid"
        )

        return self
    end

    if width <= 0 or height <= 0 then
        LogWarning(
            "ColorPicker.SetPickerRect",
            "width and height is invalid"
        )

        return self
    end

    UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(width, height),
        "ColorPicker.SetPickerRect.sizeDelta",
        true
    )

    UBUI.SetField(
        rect,
        "anchoredPosition",
        Vector2.New(
            UBUI.Num(x, 0),
            -UBUI.Num(y, 0)
        ),
        "ColorPicker.SetPickerRect.anchoredPosition",
        true
    )

    return self
end

function Element:GetPickerSize()
    if self.kind ~= "colorpicker" then return nil end

    local rect = UBUI.GetRect(self.pickerObj)

    if rect == nil then
        LogWarning(
            "ColorPicker.GetSize",
            "child ColorPicker has no RectTransform"
        )

        return nil
    end

    local size = UBUI.GetField(
        rect,
        "sizeDelta",
        nil,
        "ColorPicker.GetSize.sizeDelta",
        true
    )

    return UBUI.Vec2Num(size)
end

function Element:SetPickerSize(w, h)
    if self.kind ~= "colorpicker" then
        return self
    end

    local rect = UBUI.GetRect(self.pickerObj)

    if rect == nil then
        LogWarning(
            "ColorPicker.SetPickerSize",
            "child ColorPicker has no RectTransform"
        )

        return self
    end

    local width = UBUI.Num(w, self.nativeW)
    local height = UBUI.Num(h, self.nativeH or width)

    if width == nil or height == nil then
        LogWarning(
            "ColorPicker.SetPickerSize",
            "child ColorPicker size is not available"
        )

        return self
    end

    if width <= 0 or height <= 0 then
        LogWarning(
            "ColorPicker.SetPickerSize",
            "width and height must be greater than zero"
        )

        return self
    end

    UBUI.SetField(
        rect,
        "sizeDelta",
        Vector2.New(width, height),
        "ColorPicker.SetPickerSize.sizeDelta",
        true
    )

    return self
end

local PICKER_ANCHORS = {
    upperleft  = { 0, 1 },   uppercenter  = { 0.5, 1 },   upperright  = { 1, 1 },
    middleleft = { 0, 0.5 }, middlecenter = { 0.5, 0.5 }, middleright = { 1, 0.5 },
    lowerleft  = { 0, 0 },   lowercenter  = { 0.5, 0 },   lowerright  = { 1, 0 },
    topleft = { 0, 1 }, top = { 0.5, 1 }, topright = { 1, 1 },
    left = { 0, 0.5 }, center = { 0.5, 0.5 }, middle = { 0.5, 0.5 }, right = { 1, 0.5 },
    bottomleft = { 0, 0 }, bottom = { 0.5, 0 }, bottomright = { 1, 0 },
}

local function AnchorVec2(value)
    if value == nil then return nil end

    local kind = basicModule.type(value)

    if kind == "number" then
        local n = UBUI.Num(value, 0)
        return Vector2.New(n, n)
    end

    if kind == "string" then
        local p = PICKER_ANCHORS[string.lower(value)]
        if p == nil then return nil end
        return Vector2.New(p[1], p[2])
    end

    local x, y = nil, nil

    errorHandling.pcall(function()
        x = value.x
        y = value.y
    end)

    if x == nil then
        errorHandling.pcall(function() x = value[1] end)
    end

    if y == nil then
        errorHandling.pcall(function() y = value[2] end)
    end

    if x == nil and y == nil then return nil end

    return Vector2.New(UBUI.Num(x, 0), UBUI.Num(y, 0))
end

function Element:PickerRectComp()
    if self.kind ~= "colorpicker" then return nil end

    if not UBUI.IsAlive(self.pickerObj) then
        LogWarning(
            "ColorPicker.Rect",
            "child ColorPicker is not valid"
        )

        return nil
    end

    local rect = UBUI.GetRect(self.pickerObj)

    if rect == nil then
        LogWarning(
            "ColorPicker.Rect",
            "child ColorPicker has no RectTransform"
        )
    end

    return rect
end

function Element:SetPickerAnchor(anchorMin, anchorMax, pivot, pos)
    local rect = self:PickerRectComp()
    if rect == nil then return self end

    local mn = AnchorVec2(anchorMin)
    local mx = AnchorVec2(anchorMax)
    local pv = AnchorVec2(pivot)
    local ap = AnchorVec2(pos)

    if mn == nil and mx == nil and pv == nil and ap == nil then
        LogWarning(
            "ColorPicker.SetAnchor",
            "no valid anchor values were provided"
        )

        return self
    end

    if mn ~= nil then
        UBUI.SetField(
            rect,
            "anchorMin",
            mn,
            "ColorPicker.SetAnchor.anchorMin",
            true
        )
    end

    if mx ~= nil then
        UBUI.SetField(
            rect,
            "anchorMax",
            mx,
            "ColorPicker.SetAnchor.anchorMax",
            true
        )
    end

    if pv ~= nil then
        UBUI.SetField(
            rect,
            "pivot",
            pv,
            "ColorPicker.SetAnchor.pivot",
            true
        )
    end

    if ap ~= nil then
        UBUI.SetField(
            rect,
            "anchoredPosition",
            ap,
            "ColorPicker.SetAnchor.anchoredPosition",
            true
        )
    end

    return self
end


function Element:GetPickerScale()
    if self.kind ~= "colorpicker" then return nil end

    if self.pickerScale ~= nil then
        return self.pickerScale
    end

    if not UBUI.IsAlive(self.pickerObj) then return nil end

    local ok, scale = UBUI._SafeCall(
        "ColorPicker.GetScale",
        function()
            return self.pickerObj.Transform.LocalScale
        end
    )

    if not ok or scale == nil then return nil end

    return UBUI.Num(scale.x, 1)
end

function Element:SetPickerScale(scale)
    if self.kind ~= "colorpicker" then return self end

    local value = UBUI.Num(scale, nil)

    if value == nil or value <= 0 then
        LogWarning(
            "ColorPicker.SetScale",
            "scale must be greater than zero"
        )

        return self
    end

    if not UBUI.IsAlive(self.pickerObj) then
        LogWarning(
            "ColorPicker.SetScale",
            "child ColorPicker is not valid"
        )

        return self
    end

    local ok = UBUI._SafeCall(
        "ColorPicker.SetScale",
        function()
            self.pickerObj.Transform.LocalScale =
                Vector3.New(value, value, 1)
        end
    )

    if ok then
        self.pickerScale = value
    end

    return self
end


function Element:GetHueThickness()
    local c = pickerComp(self)
    if c == nil then return self.hueThickness end
    return UBUI.GetNum(c, "hueRingThickness", 0.195)
end

function Element:SetPickerBgColor(color)
    UBUI.SetField(self.bgImage, "color", color, "ColorPicker.SetPickerBgColor", false)
    return self
end
function Element:GetPickerBgColor() return UBUI.CompColor(self.bgImage) end

function Element:SetApplyColor(color)
    UBUI.SetField(self.applyImage, "color", color, "ColorPicker.SetApplyColor", false)
    return self
end
function Element:GetApplyColor() return UBUI.CompColor(self.applyImage) end

function Element:SetCloseColor(color)
    UBUI.SetField(self.closeImage, "color", color, "ColorPicker.SetCloseColor", false)
    return self
end
function Element:GetCloseColor() return UBUI.CompColor(self.closeImage) end

function Element:SetLabelText(text)
    if self.labelText == nil then return self end
    UBUI.SetField(self.labelText, "text", basicModule.tostring(text), "ColorPicker.SetLabelText", false)
    return self
end
function Element:GetLabelText()
    if self.labelText == nil then return "" end
    return basicModule.tostring(self.labelText.GetField("text") or "")
end
function Element:SetLabelTextColor(color)
    UBUI.SetField(self.labelText, "color", color, "ColorPicker.SetLabelTextColor", false)
    return self
end
function Element:SetLabelColor(color)
    UBUI.SetField(self.labelImage, "color", color, "ColorPicker.SetLabelColor", false)
    return self
end
function Element:GetLabelColor() return UBUI.CompColor(self.labelImage) end
function Element:SetLabelVisible(state)
    if UBUI.IsAlive(self.labelObj) then self.labelObj.Active = state == true end
    return self
end

function Element:SetOnApply(fn) self.onApply = fn return self end
function Element:SetOnClose(fn) self.onClose = fn return self end
function Element:SetOnUnSelect(fn) self.onUnSelect = fn return self end

function Element:SetApplyEnabled(state)
    UBUI.SetField(self.applyBtn, "interactable", state == true, "ColorPicker.SetApplyEnabled", false)
    return self
end
function Element:SetCloseEnabled(state)
    UBUI.SetField(self.closeBtn, "interactable", state == true, "ColorPicker.SetCloseEnabled", false)
    return self
end

function Element:SetApplyVisible(state)
    if UBUI.IsAlive(self.applyObj) then self.applyObj.Active = state == true end
    return self
end
function Element:SetCloseVisible(state)
    if UBUI.IsAlive(self.closeObj) then self.closeObj.Active = state == true end
    return self
end
function Element:SetCodeVisible(state)
    if UBUI.IsAlive(self.codeObj) then self.codeObj.Active = state == true end
    return self
end
function Element:GetGBColors()
    local c = pickerComp(self)
    if c == nil then return false end
    return UBUI.Bool(UBUI.GetField(c, "useGBColors", false, "ColorPicker.GetGBColors", false))
end

function Element:PickerGet(field)
    local comp = pickerComp(self)

    if comp == nil then
        LogWarning(
            "ColorPicker.GetField",
            "GBAdvancedColorPicker on holder is not valid"
        )

        return nil
    end

    return UBUI.GetField(
        comp,
        field,
        nil,
        "ColorPicker.GetField." .. basicModule.tostring(field),
        false
    )
end

function Element:PickerSet(field, value)
    local comp = pickerComp(self)

    if comp == nil then
        LogWarning(
            "ColorPicker.SetField",
            "GBAdvancedColorPicker on holder is not valid"
        )

        return self
    end

    UBUI.SetField(
        comp,
        field,
        value,
        "ColorPicker.SetField." .. basicModule.tostring(field),
        true
    )

    return self
end

function Element:Destroy()
    UBUI.DestroyBorders(self)

    local area = self.area

    if self.item ~= nil then
        self.item.el = nil
    end

    if area ~= nil and area.elements ~= nil then
        for i = #area.elements, 1, -1 do
            if area.elements[i] == self then
                table.remove(area.elements, i)
                break
            end
        end
    end

    self.item = nil
    self.area = nil

    UBUI._Untrack(self)

    local obj = self.obj
    self.obj = nil

    UBUI._Untrack(obj)

    if UBUI.IsAlive(obj) then
        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)
    end

    if area ~= nil
        and UBUI.IsAlive(area.obj)
        and area.Relayout ~= nil then
        UBUI._SafeCall("Area.Relayout", function()
            area:Relayout()
        end)
    end
end


function UBUI.AddWatcher(el, kind, initial)
    if el == nil or not el:IsAlive() then return nil end
    if not UBUI.IsAlive(el.comp) then return nil end
    if kind ~= "toggle" and kind ~= "input" and kind ~= "slider" then
        LogError(
            "unknown watcher " ..
            basicModule.tostring(kind) ..
            ""
        )
        return nil
    end
    for i = 1, #UBUI._watchers do
        local watcher = UBUI._watchers[i]
        if watcher.el == el and watcher.kind == kind then
            watcher.last = initial
            return watcher
        end
    end
    local watcher = {
        el = el,
        kind = kind,
        last = initial
    }
    table.insert(UBUI._watchers, watcher)
    return watcher
end

local Group = {}
Group.__index = Group
UBUI.GroupClass = Group

UBUI.GROUPS  = {}
UBUI._tagged = {}
UBUI.SYNC_UNITY_TAGS = false

local function isGroup(v)
    if v == nil then return false end
    local ok, flag = errorHandling.pcall(function() return v.__isGroup end)
    if ok and flag == true then return true end
    return false
end
UBUI.IsGroup = isGroup

local function isList(v)
    local ok, first = errorHandling.pcall(function() return v[1] end)
    if ok and first ~= nil then return true end
    return false
end

function UBUI.ItemAlive(o)
    if o == nil then return false end
    if isGroup(o) then return true end
    local ok, fn = errorHandling.pcall(function() return o.IsAlive end)
    if ok and fn ~= nil then return o:IsAlive() end
    return UBUI.IsAlive(o.obj)
end

function UBUI.NewGroup(name, items)
    local g = metaTable.setmetatable({}, Group)
    g.__isGroup = true
    g.name      = name
    g.items     = {}
    g.hidden    = false
    if name ~= nil then UBUI.GROUPS[name] = g end
    if items ~= nil then g:Add(items) end
    return g
end

function UBUI.Group(name)
    if name == nil then return UBUI.NewGroup(nil) end
    local g = UBUI.GROUPS[name]
    if g == nil then g = UBUI.NewGroup(name) end
    return g
end

function UBUI.GetGroup(name) return UBUI.GROUPS[name] end

function UBUI.DropGroup(name)
    local g = UBUI.GROUPS[name]
    UBUI.GROUPS[name] = nil
    return g
end

function UBUI.Attach(group, o)
    if group == nil or o == nil then return o end
    if isGroup(group) then group:Add(o); return o end
    if isList(group) then
        for i = 1, #group do UBUI.Attach(group[i], o) end
        return o
    end
    UBUI.Group(group):Add(o)
    return o
end

function UBUI.PruneGroups()
    for k, g in tableIterators.pairs(UBUI.GROUPS) do g:Prune() end
    for tag, list in tableIterators.pairs(UBUI._tagged) do UBUI.Tagged(tag) end
    return UBUI
end

function Group:Has(o)
    for i = 1, #self.items do
        if self.items[i] == o then return true end
    end
    return false
end

function Group:Add(o)
    if o == nil or o == self then return self end
    if isGroup(o) then
        if not self:Has(o) then table.insert(self.items, o) end
        return self
    end
    if isList(o) then
        for i = 1, #o do self:Add(o[i]) end
        return self
    end
    if not self:Has(o) then
        table.insert(self.items, o)
        self:LinkOpen(o)
    end
    return self
end

function Group:Remove(o)
    for i = #self.items, 1, -1 do
        if self.items[i] == o then table.remove(self.items, i) end
    end
    return self
end

function Group:Clear()
    self.items = {}
    return self
end

function Group:Count()
    local n = 0
    for i = 1, #self.items do
        local it = self.items[i]
        if isGroup(it) then n = n + it:Count() else n = n + 1 end
    end
    return n
end

function Group:Prune()
    local keep = {}
    for i = 1, #self.items do
        local it = self.items[i]
        if isGroup(it) then
            it:Prune()
            keep[#keep + 1] = it
        elseif UBUI.ItemAlive(it) then
            keep[#keep + 1] = it
        end
    end
    self.items = keep
    return self
end

function Group:Group(name)
    local g = UBUI.Group(name)
    self:Add(g)
    return g
end

function Group:ForEach(fn)
    if fn == nil then return self end
    for i = 1, #self.items do
        local it = self.items[i]
        if isGroup(it) then
            it:ForEach(fn)
        elseif UBUI.ItemAlive(it) then
            fn(it, self)
        end
    end
    return self
end

function Group:Map(fn)
    local out = {}
    self:ForEach(function(o) out[#out + 1] = fn(o) end)
    return out
end

function Group:Where(fn)
    local g = UBUI.NewGroup(nil)
    self:ForEach(function(o) if fn(o) then g:Add(o) end end)
    return g
end

function Group:First()
    local found = nil
    self:ForEach(function(o) if found == nil then found = o end end)
    return found
end

function Group:Call(method, a, b, c, d)
    return self:ForEach(function(o)
        local ok, fn = errorHandling.pcall(function() return o[method] end)
        if ok and fn ~= nil then
            errorHandling.pcall(function() return fn(o, a, b, c, d) end)
        end
    end)
end

function Group:SetVisible(state)
    self.hidden = not state
    return self:ForEach(function(o)
        if o.SetVisible ~= nil then o:SetVisible(state)
        elseif o.SetActive ~= nil then o:SetActive(state)
        elseif o.Open ~= nil then
            if state then o:Open() else o:Close() end
        end
    end)
end

function Group:Show()   return self:SetVisible(true)  end
function Group:Hide()   return self:SetVisible(false) end
function Group:Toggle()
    if self.hidden == true then return self:Show() end
    return self:Hide()
end
function Group:IsVisible() return self.hidden ~= true end

function Group:LinkOpen(o)
    if self._shareOpen ~= true then return o end
    if o == nil or o.isOpen == nil then return o end
    o.openGroup = self
    if self.isOpen ~= nil and self.isOpen ~= o.isOpen and self._openBusy ~= true then
        if self.isOpen then o:Open() else o:Close() end
    end
    return o
end

function Group:ShareOpen(state)
    self._shareOpen = true
    if state ~= nil then self.isOpen = state end
    if self.isOpen == nil then self.isOpen = self:IsOpen() end
    self:ForEach(function(o) self:LinkOpen(o) end)
    if state ~= nil then return self:SetOpen(state) end
    return self
end

function Group:SetOpen(state)
    if self._openBusy == true then return self end
    self._openBusy = true
    self.isOpen = state
    self:ForEach(function(o)
        if o.Open == nil or o.Close == nil then return end
        if state then o:Open() else o:Close() end
    end)
    self._openBusy = false
    return self
end

function Group:Open()  return self:SetOpen(true)  end
function Group:Close() return self:SetOpen(false) end

function Group:ToggleOpen()
    if self:IsOpen() then return self:Close() end
    return self:Open()
end

function Group:IsOpen()
    if self.isOpen ~= nil then return self.isOpen end
    local open = false
    self:ForEach(function(o) if o.isOpen == true then open = true end end)
    return open
end

function Group:SetEnabled(state) return self:Call("SetInteractable", state) end
function Group:Enable()  return self:SetEnabled(true)  end
function Group:Disable() return self:SetEnabled(false) end

function Group:SetText(text)         return self:Call("SetText", text) end
function Group:SetTextColor(color)   return self:Call("SetTextColor", color) end
function Group:SetFontSize(size)     return self:Call("SetFontSize", size) end
function Group:SetAlign(align)       return self:Call("SetAlign", align) end
function Group:SetColor(color)       return self:Call("SetColor", color) end
function Group:SetValue(value)       return self:Call("SetValue", value) end
function Group:SetSize(w, h)         return self:Call("SetSize", w, h) end
function Group:SetStyle(style)       return self:Call("SetStyle", style) end

function Group:SetPickerColor(c) return self:Call("SetPickerColor", c) end
function Group:SetHex(h)         return self:Call("SetHex", h) end
function Group:RefreshPickers()  return self:Call("RefreshPicker") end

function Group:Values()
    return self:Map(function(o)
        if o.GetValue == nil then return nil end
        return o:GetValue()
    end)
end

function Group:Restyle()
    return self:ForEach(function(o)
        if o.Restyle ~= nil then o:Restyle() else UBUI.Restyle(o) end
    end)
end

function Group:Relayout()
    return self:ForEach(function(o)
        if o.Relayout ~= nil then o:Relayout()
        elseif o.area ~= nil then o.area:Relayout() end
    end)
end

function Group:DestroyItems()
    self:Call("Destroy")
    return self:Clear()
end

function Group:Destroy()
    self:DestroyItems()
    if self.name ~= nil then UBUI.DropGroup(self.name) end
    return self
end

local function tagOne(o, tag)
    if o == nil or tag == nil then return end
    if o.tags == nil then o.tags = {} end
    if o.tags[tag] == true then return end
    o.tags[tag] = true
    local list = UBUI._tagged[tag]
    if list == nil then
        list = {}
        UBUI._tagged[tag] = list
    end
    list[#list + 1] = o
    if UBUI.SYNC_UNITY_TAGS and UBUI.IsAlive(o.obj) then
        errorHandling.pcall(function() o.obj.Tag = tag end)
    end
end

function UBUI.Tag(o, tags)
    if o == nil or tags == nil then return o end
    if isList(tags) then
        for i = 1, #tags do tagOne(o, tags[i]) end
    else
        tagOne(o, tags)
    end
    return o
end

function UBUI.HasTag(o, tag)
    if o == nil or o.tags == nil then return false end
    return o.tags[tag] == true
end

function UBUI.Untag(o, tag)
    if o == nil or o.tags == nil then return o end
    o.tags[tag] = nil
    local list = UBUI._tagged[tag]
    if list ~= nil then
        for i = #list, 1, -1 do
            if list[i] == o then table.remove(list, i) end
        end
    end
    return o
end

function UBUI.Tagged(tag)
    local list = UBUI._tagged[tag]
    if list == nil then return {} end
    local keep = {}
    for i = 1, #list do
        if UBUI.ItemAlive(list[i]) then keep[#keep + 1] = list[i] end
    end
    UBUI._tagged[tag] = keep
    return keep
end

function UBUI.GroupByTag(tag, name)
    local g = UBUI.Group(name or tag)
    g:Clear()
    g.tag = tag
    return g:Add(UBUI.Tagged(tag))
end

function Group:Refresh()
    if self.tag == nil then return self:Prune() end
    self:Clear()
    return self:Add(UBUI.Tagged(self.tag))
end

local Area = {}
Area.__index = Area
UBUI.Area = Area
UBUI.AreaClass = Area

local function makeArea(obj, x, y, w, h, o)
    local a = metaTable.setmetatable({}, Area)
    a.obj       = obj
    a.transform = obj.Transform
    a.x, a.y    = x, y
    a.w, a.h    = w, h
    a.padLeft   = UBUI.Num(o.padLeft   or o.padding or UBUI.Theme.padding, 0)
    a.padRight  = UBUI.Num(o.padRight  or o.padding or UBUI.Theme.padding, 0)
    a.padTop    = UBUI.Num(o.padTop    or o.padding or UBUI.Theme.padding, 0)
    a.padBottom = UBUI.Num(o.padBottom or o.padding or UBUI.Theme.padding, 0)
    a.spacing   = UBUI.Num(o.spacing   or UBUI.Theme.spacing, 0)
    a.lines     = {}
    a.row       = nil
    a.rowX      = 0
    a.elements  = {}
    a.styleName = o._style
    a.userOpts  = o._opts
    a.children  = {}
    a.clipping     = false
    a.clipComponent = nil
    if o.clipping ~= nil then UBUI.SetClipping(a, o.clipping) end
    UBUI.Tag(a, o.tags)
    UBUI.Attach(o.group, a)
    return a
end

function UBUI.NewAreaAt(parentTransform, name, x, y, w, h, opts)
    if not UBUI.HasStyles() then return nil end
    local o = UBUI.StyleOpts("area", opts)
    if parentTransform == nil then return nil end
    local color = o.color or UBUI.Colors.clear
    local obj = UBUI.NewImageObject(parentTransform, name or UBUI.NextName("Area"),
        x, y, w, h, color, o.raycast or false)
    if obj == nil then return nil end
    return makeArea(obj, x, y, w, h, o)
end

function UBUI.NewArea(space, name, x, y, w, h, opts)
    local parent = UBUI.GetSpace(space)
    if parent == nil then return nil end
    local a = UBUI.NewAreaAt(parent, name, x, y, w, h, opts)
    if a ~= nil then a.space = space end
    return a
end

function Area:IsAlive() return UBUI.IsAlive(self.obj) end
function Area:HasClipping() return UBUI.HasClipping(self) end
function Area:SetClipping(state) return UBUI.SetClipping(self, state) end

function Area:ContentWidth()
    local w = UBUI.Num(self.w, 0) -
        UBUI.Num(self.padLeft, 0) -
        UBUI.Num(self.padRight, 0)

    if w < 1 then w = 1 end

    return w
end

function Area:SetActive(state)
    self.visible = state
    if UBUI.IsAlive(self.obj) then self.obj.Active = state end
    return self
end

function Area:SetColor(color)
    if UBUI.IsAlive(self.obj) then
        local img = UBUI.GetImageComp(self.obj)
        UBUI.SetField(img, "color", color, "Area.SetColor", false)
    end
    return self
end

function Area:SetStyle(style) return UBUI.ApplyStyle(self, style) end

function Area:Tag(tags)    return UBUI.Tag(self, tags) end
function Area:AddTo(group) return UBUI.Attach(group, self) end

function Area:AsGroup(name)
    local g = UBUI.Group(name)
    return g:Add(self.elements)
end

function Area:SetRect(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    UBUI.SetTopRect(self.obj, x, y, w, h)
    self:Relayout()
    return self
end

function Area:Rotate(degrees)
    return rotate(self, degrees, "Area.Rotate")
end

function Area:BeginRow(height)
    local line = { h = height or 0, items = {}, spacer = false }
    self.lines[#self.lines + 1] = line
    self.row  = line
    self.rowX = self.padLeft
    return self
end

function Area:EndRow()
    self.row  = nil
    self.rowX = 0
    self:Relayout()
    return self
end

function Area:Space(pixels)
    local line = { h = pixels or self.spacing, items = {}, spacer = true }
    self.lines[#self.lines + 1] = line
    self:Relayout()
    return self
end

function Area:Place(el, w, h, o)
    el.styleName = o._style
    el.userOpts  = o._opts
    el.area = self
    self.elements[#self.elements + 1] = el
    UBUI.Tag(el, o.tags)
    UBUI.Attach(o.group, el)
    if o.x ~= nil and o.y ~= nil then
        local rw, rh = UBUI.SlotRect(el, w, h)
        UBUI.SetTopRect(el.obj, o.x, o.y, rw, rh)
        el.flow = false
        return el
    end
    el.flow = true
    local line = self.row
    local ox
    if line ~= nil then
        ox = self.rowX
        self.rowX = self.rowX + w + self.spacing
        if h > line.h then line.h = h end
    else
        line = { h = h, items = {}, spacer = false }
        self.lines[#self.lines + 1] = line
        ox = self.padLeft
    end
    if o.indent ~= nil then ox = ox + o.indent end
    local item = { el = el, x = ox, w = w, h = h, line = line }
    line.items[#line.items + 1] = item
    el.item = item
    self:Relayout()
    return el
end

function Area:Relayout()
    local y = self.padTop
    for i = 1, #self.lines do
        local line = self.lines[i]
        local vis  = line.spacer
        for j = 1, #line.items do
            local it = line.items[j]
            if it.el ~= nil and it.el.visible and it.el:IsAlive() then vis = true end
        end
        if vis then
            for j = 1, #line.items do
                local it = line.items[j]
                if it.el ~= nil and it.el:IsAlive() and it.el.visible then
                    local oy = y
                    if line.h > it.h then oy = y + math.floor((line.h - it.h) * 0.5) end
                    local rw, rh = UBUI.SlotRect(it.el, it.w, it.h)
                    UBUI.SetTopRect(it.el.obj, it.x, oy, rw, rh)
                    it.el:UpdateBorders()
                end
            end
            y = y + line.h + self.spacing
        end
    end
    self.contentHeight = y
    return self
end

function Area:Clear()
    for i = 1, #self.elements do
        local el = self.elements[i]
        if el ~= nil and el:IsAlive() then el.obj.DestroyLocal() end
    end
    self.elements = {}
    self.lines    = {}
    self.row      = nil
    self.rowX     = 0
    return self
end

function Area:Destroy()
    UBUI._Untrack(self)
    local obj = self.obj
    self.obj = nil
    UBUI._Untrack(obj)
    UBUI.DestroyBorders(self)
    if UBUI.IsAlive(obj) then
        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)
    end
    self.elements = {}
    self.lines = {}
    self.children = {}
    self.clipping = false
    self.clipComponent = nil
end

function Area:NewArea(name, x, y, w, h, opts)
    local a = UBUI.NewAreaAt(self.transform, name, x, y, w, h, opts)
    if a ~= nil then self.children[#self.children + 1] = a end
    return a
end

function Area:Restyle()
    if not UBUI.IsAlive(self.obj) then return self end
    UBUI.Restyle(self)
    for i = 1, #self.elements do UBUI.Restyle(self.elements[i]) end
    for i = 1, #self.children  do self.children[i]:Restyle()    end
    return self:Relayout()
end

function Area:Image(opts)
    local o = UBUI.StyleOpts("image", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.image
    local obj = UBUI.NewImageObject(self.transform, o.name or UBUI.NextName("Image"),
        0, 0, w, h, o.color or UBUI.Theme.texture, o.raycast or false)
    if obj == nil then return nil end
    local el = UBUI.NewElement(obj, "image", nil)
    if o.texture ~= nil then el:SetTexture(o.texture) end
    if o.preserveAspect ~= nil then el:SetPreserveAspect(o.preserveAspect) end
    if o.imageType ~= nil then el:SetImageType(o.imageType) end
    if o.fillMethod ~= nil then el:SetFillMethod(o.fillMethod) end
    if o.fillOrigin ~= nil then el:SetFillOrigin(o.fillOrigin) end
    if o.fillClockwise ~= nil then el:SetFillClockwise(o.fillClockwise) end
    if o.fillAmount ~= nil then el:SetFillAmount(o.fillAmount) end
    return self:Place(el, w, h, o)
end

function Area:Text(text, opts)
    local o = UBUI.StyleOpts("text", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.text
    local obj = UBUI.CopyPrefab(UBUI.PREFABS.label, self.transform,
        o.name or UBUI.NextName("Text"), 0, 0, w, h)
    if obj == nil then return nil end
    local el = UBUI.NewElement(obj, "text", nil)
    el:SetText(text or "")
    el:SetTextColor(o.textColor or UBUI.Theme.text)
    if o.fontSize ~= nil then el:SetFontSize(o.fontSize) end
    el:SetAlign(o.align or "MiddleLeft")
    if o.wordWrap ~= nil then el:SetWordWrap(o.wordWrap) end
    UBUI.SetRaycast(obj, false)
    return self:Place(el, w, h, o)
end
Area.Label = Area.Text

function Area:Button(label, onClick, opts)
    local o = UBUI.StyleOpts("button", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.button
    local obj = UBUI.CopyPrefab(UBUI.PREFABS.button, self.transform,
        o.name or UBUI.NextName("Button"), 0, 0, w, h)
    if obj == nil then return nil end
    local comp = UBUI.GetComp(obj, "UnityEngine.UI.Button")
    local el = UBUI.NewElement(obj, "button", comp)
    el.onClick = onClick
    el:SetText(label or "")
    if o.textColor ~= nil then el:SetTextColor(o.textColor) end
    if o.fontSize  ~= nil then el:SetFontSize(o.fontSize)   end
    if o.color     ~= nil then el:SetColor(o.color)         end
    if o.align     ~= nil then el:SetAlign(o.align)         end
    if o.fixed == true then el:SetTextAutoSize(true, o.autoMin, o.autoMax) end
    if o.textPad ~= nil or o.textPadY ~= nil then el:SetTextPadding(o.textPad, o.textPadY) end
    UBUI.DisableChildTextRaycast(obj)
	if comp ~= nil then
        UBUI.HookClick(comp, el, "onClick")
    end
    return self:Place(el, w, h, o)
end

function Area:Toggle(label, value, onChange, opts)
    local o = UBUI.StyleOpts("toggle", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.toggle
    local obj = UBUI.CopyPrefab(UBUI.PREFABS.toggle, self.transform,
        o.name or UBUI.NextName("Toggle"), 0, 0, w, h)
    if obj == nil then return nil end
    local comp = UBUI.GetComp(obj, "UnityEngine.UI.Toggle")
    local el = UBUI.NewElement(obj, "toggle", comp)
    el.onChange = onChange
    el:SetText(label or "")
    el:SetTextColor(o.textColor or UBUI.Theme.text)
    if o.fontSize ~= nil then el:SetFontSize(o.fontSize) end
	if comp ~= nil then
        UBUI.SetField(comp, "isOn", value, "Area.Toggle", false)
        UBUI.AddWatcher(el, "toggle", value)
    end
    UBUI.DisableChildTextRaycast(obj)
    return self:Place(el, w, h, o)
end

function Area:InputField(text, onChange, opts)
    local o = UBUI.StyleOpts("input", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.input
    local obj = UBUI.CopyPrefab(UBUI.PREFABS.input, self.transform,
        o.name or UBUI.NextName("Input"), 0, 0, w, h)
    if obj == nil then return nil end
    local comp = UBUI.GetInputComp(obj)
    local el = UBUI.NewElement(obj, "input", comp)
    el.onChange = onChange
    if comp ~= nil then
        UBUI.SetField(comp, "text", text or "", "Area.InputField", false)
        if o.characterLimit ~= nil then
            UBUI.SetField(comp, "characterLimit", o.characterLimit, "Area.InputField", false)
        end
        UBUI.AddWatcher(el, "input", text or "")
    end
    if o.fontSize ~= nil then el:SetFontSize(o.fontSize) end
    return self:Place(el, w, h, o)
end

function UBUI.ClearSliderText(obj)
    if not UBUI.IsAlive(obj) then return end
    local tmp = obj.GetComponentsInChildren("TMPro.TextMeshProUGUI")
    if tmp ~= nil then
        for i = 1, #tmp do
            UBUI.SetField(tmp[i], "text", "", "ClearSliderText", false)
            UBUI.SetField(tmp[i], "enabled", false, "ClearSliderText", false)
        end    end
    local uit = obj.GetComponentsInChildren("UnityEngine.UI.Text")
    if uit ~= nil then
        for i = 1, #uit do
            UBUI.SetField(uit[i], "text", "", "ClearSliderText", false)
            UBUI.SetField(uit[i], "enabled", false, "ClearSliderText", false)
        end
    end
end

local function findSliderImage(images, needle, avoid)
    local loose = nil
    for i = 1, #images do
        local go = images[i].GameObject
        if go ~= nil then
            local name = string.lower(go.Name)
            if name == needle then return images[i] end
            local hit = string.find(name, needle, 1, true) ~= nil
            if hit and avoid ~= nil then
                hit = string.find(name, avoid, 1, true) == nil
            end
            if hit and loose == nil then loose = images[i] end
        end
    end
    return loose
end

local function sliderHeight(el)
    if el.sliderH ~= nil then return el.sliderH end
    if el.item ~= nil and el.item.h ~= nil then return el.item.h end
    return UBUI.SIZES.slider
end

function UBUI.SliderFillArea(el)
    if el == nil or el.fillImage == nil then return nil end
    local pr = UBUI.ParentRectOf(el.fillImage)
    if pr == nil then return nil end
    if not UBUI.IsAlive(el.obj) then return nil end
    if pr.GameObject.Name == el.obj.Name then return nil end
    return pr
end

function UBUI.SliderHasHandle(el)
    return el ~= nil and el.handleImage ~= nil and el.handleVisible == true
end

function UBUI.ApplyFillArea(el)
    if el == nil or el.fillImage == nil then return end
    local area = UBUI.SliderFillArea(el)
    if UBUI.SliderHasHandle(el) then
        UBUI.LeftStretchRectH(area, el.handleW, el.trackH)
    else
        UBUI.StretchRectH(area, 0, el.trackH)
    end
    local fr = UBUI.RectOf(el.fillImage)
    if fr ~= nil then
        fr.SetField("sizeDelta",        Vector2.New(0, 0))
        fr.SetField("anchoredPosition", Vector2.New(0, 0))
    end
end

function UBUI.ApplyHandleRect(el)
    local hr = UBUI.RectOf(el.handleImage)
    if hr == nil then return end
    local ax  = 0
    local cur = hr.GetField("anchorMin")
    if cur ~= nil then ax = UBUI.Num(cur.x, 0) end
    local dh = 0
    if el.handleH ~= nil then dh = el.handleH - UBUI.Num(sliderHeight(el), 0) end
    hr.SetField("anchorMin", Vector2.New(ax, 0))
    hr.SetField("anchorMax", Vector2.New(ax, 1))
    hr.SetField("pivot", Vector2.New(0.5, 0.5))
    hr.SetField("sizeDelta", Vector2.New(el.handleW, dh))
    hr.SetField("anchoredPosition", Vector2.New(0, 0))
end

function UBUI.SetupSlider(el, handleW, handleH, trackH)
    local obj = el.obj
    local images = obj.GetComponentsInChildren("UnityEngine.UI.Image")
    if images == nil then return el end
    local n = #images
    if n == 0 then return el end
    for i = 1, n do
		UBUI.SetField(images[i], "enabled", true, "SetupSlider", false)
        UBUI.SetField(images[i], "raycastTarget", true, "SetupSlider", false)
    end

    el.bgImage     = findSliderImage(images, "background")
    el.fillImage   = findSliderImage(images, "fill",   "area")
    el.handleImage = findSliderImage(images, "handle", "area")

    if el.bgImage == nil then
        local off = 0
        if n >= 4 then
            off = 1
            images[1].SetField("color", UBUI.Colors.clear)
        end
        el.bgImage     = images[off + 1]
        el.fillImage   = images[off + 2]
        el.handleImage = images[off + 3]
    end

    el.handleW = UBUI.Num(handleW or UBUI.SIZES.sliderHandle, 0)
    el.handleH = handleH
    el.trackH  = trackH
    
    if el.bgImage ~= nil then
        UBUI.StretchRectH(UBUI.RectOf(el.bgImage), 0, el.trackH)
    end
    UBUI.ApplyFillArea(el)

    if el.handleImage ~= nil then
        UBUI.StretchRect(UBUI.ParentRectOf(el.handleImage), -el.handleW, 0)
        UBUI.ApplyHandleRect(el)
    end

    if el.comp ~= nil then
        el.comp.SetField("transition", 0)
        el.comp.SetField("direction", 0)
        local fRT = UBUI.RectOf(el.fillImage)
        local hRT = UBUI.RectOf(el.handleImage)
		if fRT ~= nil then UBUI.SetField(el.comp, "fillRect", fRT, "SetupSlider", false) end
        if hRT ~= nil then UBUI.SetField(el.comp, "handleRect", hRT, "SetupSlider", false) end
        if el.handleImage ~= nil then
            UBUI.SetField(el.comp, "targetGraphic", el.handleImage, "SetupSlider", false)
        elseif el.bgImage ~= nil then
            UBUI.SetField(el.comp, "targetGraphic", el.bgImage, "SetupSlider", false)
        end
    end
    UBUI.ClearSliderText(obj)
    return el
end

function Area:Slider(value, min, max, onChange, opts)
    local o = UBUI.StyleOpts("slider", opts)
    local w = o.w or self:ContentWidth()
    local h = o.h or UBUI.SIZES.slider
    local obj = UBUI.CopyPrefab(UBUI.PREFABS.slider, self.transform,
        o.name or UBUI.NextName("Slider"), 0, 0, w, h)
    if obj == nil then return nil end
    local comp = UBUI.GetComp(obj, "UnityEngine.UI.Slider")
    local el = UBUI.NewElement(obj, "slider", comp)
    el.sliderH     = h
    el.onChange    = onChange
    el.min         = min or 0
    el.max         = max or 1
    el.handleColor = o.handleColor or UBUI.Colors.white
    if value == nil then value = el.min end
    UBUI.SetupSlider(el,
        o.handleWidth  or math.floor(h * 0.62),
        o.handleHeight,
        o.trackHeight)
    if comp ~= nil then
        UBUI.SetField(comp, "wholeNumbers", o.wholeNumbers == true, "Area.Slider", false)
    	UBUI.SetField(comp, "minValue", el.min, "Area.Slider", false)
    	UBUI.SetField(comp, "maxValue", el.max, "Area.Slider", false)
    	UBUI.SetField(comp, "value", value, "Area.Slider", false)
		UBUI.SetField(comp, "interactable", true, "Area.Slider", false)
    	UBUI.AddWatcher(el, "slider", value)
    end
    el:SetSliderColors(o.fillColor or UBUI.Theme.sliderFill, o.bgColor or UBUI.Theme.sliderBg)
    el:SetHandleVisible(o.handle == true)
    return self:Place(el, w, h, o)
end

UBUI.PICKER_COMP  = "GBAdvancedColorPicker"
UBUI._pickers     = {}

UBUI.PICKER_PARTS = {
    background = "BackGround",
    apply      = "Buttons/Apply",
    close      = "Buttons/Close",
    label      = "Buttons (1)",
}

function UBUI.ValidatePicker(el)
    if el == nil or el.kind ~= "colorpicker" then
        LogFailure(
            "ColorPicker.Validate",
            "invalid picker element"
        )

        return false
    end

    if not UBUI.IsAlive(el.obj) then
        LogFailure(
            "ColorPicker.Validate",
            "holder is not valid"
        )

        return false
    end

    local pickerObj = UBUI.FindChildObject(
        el.obj,
        "ColorPicker"
    )

    if not UBUI.IsAlive(pickerObj) then
        LogFailure(
            "ColorPicker.Validate",
            "child ColorPicker was not found"
        )

        return false
    end

    if UBUI.SameObject(el.obj, pickerObj) then
        LogFailure(
            "ColorPicker.Validate",
            "holder and child ColorPicker are the same object"
        )

        return false
    end

    if not UBUI.SameObject(el.pickerObj, pickerObj) then
        LogFailure(
            "ColorPicker.Validate",
            "pickerObj does not reference child ColorPicker"
        )

        return false
    end

    if UBUI.GetRect(el.obj) == nil then
        LogFailure(
            "ColorPicker.Validate",
            "holder has no RectTransform"
        )

        return false
    end

    if UBUI.GetRect(el.pickerObj) == nil then
        LogFailure(
            "ColorPicker.Validate",
            "child ColorPicker has no RectTransform"
        )

        return false
    end

    if not UBUI.IsAlive(el.comp) then
        LogFailure(
            "ColorPicker.Validate",
            "GBAdvancedColorPicker was not found on holder"
        )

        return false
    end

    local ok, owner = UBUI._SafeCall(
        "ColorPicker.ValidateComponentOwner",
        function()
            return el.comp.GameObject
        end
    )

    if not ok or not UBUI.SameObject(owner, el.obj) then
        LogFailure(
            "ColorPicker.Validate",
            "GBAdvancedColorPicker is not attached to holder"
        )

        return false
    end

    if el.bgImage == nil then
        LogWarning(
            "ColorPicker.Validate",
            "background image was not found"
        )
    end

    if el.applyBtn == nil then
        LogWarning(
            "ColorPicker.Validate",
            "apply button was not found"
        )
    end

    if el.closeBtn == nil then
        LogWarning(
            "ColorPicker.Validate",
            "close button was not found"
        )
    end

    return true
end

function UBUI.SetupPicker(el)
    if el == nil or el.kind ~= "colorpicker" then
        LogFailure(
            "ColorPicker.SetupPicker",
            "invalid picker element"
        )

        return nil
    end

    local holder = el.obj
    local pickerObj = UBUI.FindChildObject(
        holder,
        "ColorPicker"
    )

    if not UBUI.IsAlive(pickerObj) then
        LogFailure(
            "ColorPicker.SetupPicker",
            "child ColorPicker was not found"
        )

        return nil
    end

    local compOk, comp = UBUI._SafeCall(
        "ColorPicker.SetupPicker.Component",
        function()
            return holder.GetComponent(UBUI.PICKER_COMP)
        end
    )

    if not compOk or not UBUI.IsAlive(comp) then
        LogFailure(
            "ColorPicker.SetupPicker",
            "GBAdvancedColorPicker was not found"
        )

        return nil
    end

    el.pickerObj = pickerObj
    el.comp = comp

    el.bgObject = UBUI.FindChildObject(
        pickerObj,
        UBUI.PICKER_PARTS.background
    )

    el.bgImage = UBUI.GetImageComp(el.bgObject)

    el.applyObj = UBUI.FindChildObject(
        pickerObj,
        UBUI.PICKER_PARTS.apply
    )

    el.closeObj = UBUI.FindChildObject(
        pickerObj,
        UBUI.PICKER_PARTS.close
    )

    el.applyBtn = UBUI.GetComp(el.applyObj, "UnityEngine.UI.Button")
    el.closeBtn = UBUI.GetComp(el.closeObj, "UnityEngine.UI.Button")

    if el.applyBtn == nil then
        el.applyBtn = el:PickerGet("ApplyButton")
    end

    if el.closeBtn == nil then
        el.closeBtn = el:PickerGet("CloseButton")
    end

    el.codeObj = nil

    local colorText = el:PickerGet("ColorText")

    if colorText ~= nil then
        local okCode, codeObj = UBUI._SafeCall(
            "ColorPicker.SetupPicker.ColorText",
            function()
                return colorText.GameObject
            end
        )

        if okCode then el.codeObj = codeObj end
    end

    if el.applyObj == nil and el.applyBtn ~= nil then
        el.applyObj = el.applyBtn.GameObject
    end

    if el.closeObj == nil and el.closeBtn ~= nil then
        el.closeObj = el.closeBtn.GameObject
    end

    el.applyImage = UBUI.GetImageComp(el.applyObj)
    el.closeImage = UBUI.GetImageComp(el.closeObj)

    el.labelObj = UBUI.FindChildObject(
        pickerObj,
        UBUI.PICKER_PARTS.label
    )

    el.labelImage = UBUI.GetImageComp(el.labelObj)
    el.labelText = UBUI.GetTextComp(el.labelObj)

    el.rootLabelObj = UBUI.FindChildObject(holder, "Label")

    if UBUI.IsAlive(el.rootLabelObj) then
        el.rootLabelObj.Active = false
    end

    UBUI.HookClick(
        el.applyBtn,
        el,
        "onApply",
        function(fn, holder)
            fn(holder:GetPickerColor(), holder)
        end
    )

    UBUI.HookClick(el.closeBtn, el, "onClose")

	local unSelect = el:PickerGet("onUnSelectColor")

    if unSelect ~= nil then
        UBUI.HookEvent(
            unSelect,
            el,
            "picker:onUnSelectColor",
            function()
                if basicModule.type(el.onUnSelect) ~= "function" then
                    return
                end

                UBUI._SafeCall(
                    "ColorPicker.onUnSelect",
                    function()
                        el.onUnSelect(el)
                    end
                )
            end,
            "ColorPicker.SetupPicker.onUnSelectColor"
        )
    end

    return el
end

function Area:ColorPicker(color, onChange, opts)
    if opts ~= nil and basicModule.type(opts) ~= "table" then
        LogFailure(
            "Area.ColorPicker",
            "options must be a table"
        )

        return nil
    end

    local userOpts = opts or {}
    local o = UBUI.StyleOpts("colorpicker", userOpts)
    local areaW = self:ContentWidth()
    local areaH = self.h or areaW

    local obj = UBUI.CopyPrefab(
        UBUI.PREFABS.colorPicker,
        self.transform,
        o.name or UBUI.NextName("ColorPicker"),
        0,
        0,
        areaW,
        areaH
    )

    if obj == nil then return nil end

    local function fail(message)
        LogFailure("Area.ColorPicker", message)
        UBUI._Untrack(obj)

        if UBUI.IsAlive(obj) then
            UBUI._SafeCall(
                "ColorPicker.DestroyInvalidHolder",
                function()
                    obj.DestroyLocal()
                end
            )
        end

        return nil
    end

    local pickerObj = UBUI.FindChildObject(
        obj,
        "ColorPicker"
    )

    if not UBUI.IsAlive(pickerObj) then
        return fail("child ColorPicker was not found")
    end

    local compOk, comp = UBUI._SafeCall(
        "ColorPicker.GetHolderComponent",
        function()
            return obj.GetComponent(UBUI.PICKER_COMP)
        end
    )

    if not compOk or not UBUI.IsAlive(comp) then
        return fail("GBAdvancedColorPicker was not found on holder")
    end

    local el = UBUI.NewElement(
        obj,
        "colorpicker",
        comp
    )

    el._pickerHolderLayout = true
    el.pickerObj = pickerObj

    if onChange ~= nil and basicModule.type(onChange) ~= "function" then
        LogWarning(
            "Area.ColorPicker",
            "onChange is not a function and was ignored"
        )

        onChange = nil
    end

    el.onChange = onChange
    el.onApply = o.onApply
    el.onClose = o.onClose
    el.onUnSelect = o.onUnSelect

    local setupOk, setupResult = UBUI._SafeCall(
        "ColorPicker.SetupPicker",
        UBUI.SetupPicker,
        el
    )

    if not setupOk or setupResult == nil then
        return fail("SetupPicker failed")
    end

    if not UBUI.ValidatePicker(el) then
        UBUI._Untrack(el)
        return fail("picker structure is invalid")
    end

    local pickerRect = UBUI.GetRect(el.pickerObj)
    local nw, nh = nil, nil

    if pickerRect ~= nil then
        local size = UBUI.GetField(
            pickerRect,
            "sizeDelta",
            nil,
            "ColorPicker.NativeSize",
            true
        )

        nw, nh = UBUI.Vec2Num(size)
    end

    if nw == nil or nw <= 0 then
        nw = UBUI.SIZES.picker
    end

    if nh == nil or nh <= 0 then
        nh = nw
    end

    el.nativeW = nw
    el.nativeH = nh

    if userOpts.w ~= nil and userOpts.h ~= nil then
        el:SetPickerSize(
            UBUI.Num(userOpts.w, nw),
            UBUI.Num(userOpts.h, nh)
        )
    end

    if o.scale ~= nil then el:SetPickerScale(o.scale) end
    if o.gbColors ~= nil then el:SetGBColors(o.gbColors) end
    if o.hueThickness ~= nil then el:SetHueThickness(o.hueThickness) end
    if o.bgColor ~= nil then el:SetPickerBgColor(o.bgColor) end
    if o.applyColor ~= nil then el:SetApplyColor(o.applyColor) end
    if o.closeColor ~= nil then el:SetCloseColor(o.closeColor) end
    if o.labelColor ~= nil then el:SetLabelColor(o.labelColor) end
    if o.labelTextColor ~= nil then el:SetLabelTextColor(o.labelTextColor) end
    if o.labelText ~= nil then el:SetLabelText(o.labelText) end
    if o.code ~= nil then el:SetCodeVisible(o.code ~= false) end
    if color ~= nil then el:SetPickerColor(color) end

    local hexOk, hex = UBUI._SafeCall(
        "ColorPicker.InitialHex",
        function()
            return el:GetHex()
        end
    )

    if hexOk then
        el._lastHex = hex
    else
        LogWarning(
            "Area.ColorPicker",
            "initial HEX value could not be read"
        )
    end

    table.insert(UBUI._pickers, el)

    local layoutOpts = {}

    for key, value in tableIterators.pairs(o) do
        layoutOpts[key] = value
    end

    layoutOpts.w = nil
    layoutOpts.h = nil
    layoutOpts.scale = nil

    local placeOk = UBUI._SafeCall(
        "ColorPicker.Place",
        function()
            self:Place(
                el,
                areaW,
                areaH,
                layoutOpts
            )
        end
    )

    if not placeOk then
        UBUI._Untrack(el)
        return fail("picker placement failed")
    end

    local holderRect = UBUI.GetRect(el.obj)

    if holderRect == nil then
        UBUI._Untrack(el)
        return fail("holder RectTransform not found")
    end

    if not UBUI.StretchRect(holderRect, 0, 0) then
        UBUI._Untrack(el)
        return fail("holder stretch failed")
    end

    return el
end

function Area:ScrollViewAt(name, x, y, w, h, opts)
    local sv = UBUI.ScrollViewAt(self.transform, name, x, y, w, h, opts)
    if sv ~= nil then self.children[#self.children + 1] = sv end
    return sv
end

function Area:ScrollView(opts)
    local o = opts or {}
    local w = o.w or self:ContentWidth()
    local h = o.h or 200
    local sv = UBUI.ScrollViewAt(self.transform, o.name or UBUI.NextName("Scroll"), 0, 0, w, h, opts)
    if sv == nil then return nil end
    return self:Place(sv, w, h, o)
end

local Window = {}
Window.__index = Window
UBUI.WindowClass = Window

local HeaderRow = {}
HeaderRow.__index = HeaderRow
UBUI.HeaderRowClass = HeaderRow

function UBUI.Window(w, h, x, y, header, headerH, label, opts)
    if not UBUI.HasStyles() then return nil end
    local o = opts or {}
    local parent = UBUI.GetSpace(o.space or "base")
    if parent == nil then return nil end

    local name  = o.name or UBUI.NextName("Window")
    local bt    = o.borderThickness or UBUI.Theme.borderThickness
    local bc    = o.borderColor or UBUI.Theme.border
    local rootC = o.rootColor or UBUI.Theme.root
    local headC = o.headerColor or UBUI.Theme.header
    if headerH == nil then headerH = 60 end
    if header ~= true then headerH = 0 end

    local root = UBUI.NewImageObject(parent, name, x or 0, y or 0, w, h, rootC, true)
    if root == nil then return nil end
    UBUI.BringToFront(root)

    local win = metaTable.setmetatable({}, Window)
    win.obj        = root
    win.instanceId = UBUI._IndexObject(root)
    win.transform  = root.Transform
    win.w, win.h   = w, h
    win.x, win.y   = x or 0, y or 0
    win.centered   = o.center == true
    win.headerH    = headerH
    win.space      = o.space or "base"
    win.onClose    = o.onClose
    win.autoScale  = o.autoScale ~= false
    win.margin     = o.margin or 70
    win.minScale   = o.minScale or 0.42
    win.isOpen     = true
    win.opts       = o
    win.clipping     = false
    win.clipComponent = nil
    if o.clipping ~= nil then UBUI.SetClipping(win, o.clipping) end
    win.headerRows = {}
    win._screenW   = 0
    win._screenH   = 0
    win.scale      = 1

    if win.centered then UBUI.SetCenterRect(root, win.x, win.y, w, h) end

    if header == true then
        win.header = UBUI.NewAreaAt(root.Transform, name .. "_Header", 0, 0, w, headerH, {
            color   = headC,
            raycast = true,
            padding = 0,
            spacing = 0,
        })
        win.headerLine = UBUI.NewImageObject(root.Transform, name .. "_HeaderLine",
            0, headerH - bt, w, bt, bc, false)

        if label ~= nil and win.header ~= nil then
            local inset  = o.titleInset or UBUI.Theme.closeInset or 12
            local titleW = w - inset * 2
            if titleW < 40 then titleW = 40 end
            local obj = UBUI.CopyPrefab(UBUI.PREFABS.label, win.header.transform,
                name .. "_Title", inset, 0, titleW, headerH)
            if obj ~= nil then
                local el = UBUI.NewElement(obj, "text", nil)
                el:SetText(label)
                el:SetStyle("title")
                if o.titleColor ~= nil then el:SetTextColor(o.titleColor) end
                if o.titleSize  ~= nil then el:SetFontSize(o.titleSize)   end
                if o.titleAlign ~= nil then el:SetAlign(o.titleAlign)     end
                UBUI.SetRaycast(obj, false)
                win.title = el
            end
        end
    end

    win.root = makeArea(root, win.x, win.y, w, h, { padding = 0, spacing = 0 })
    win.body = UBUI.NewAreaAt(root.Transform, name .. "_Body",
        bt, headerH, w - bt * 2, h - headerH - bt, {
            padding = o.padding,
            spacing = o.spacing,
            color   = o.bodyColor or UBUI.Colors.clear,
        })
        
    if o.border ~= false then
        win.frame = UBUI.Border(win, { thickness = bt, color = bc })
    end

    UBUI._windows[#UBUI._windows + 1] = win
    UBUI.Tag(win, o.tags)
    UBUI.Attach(o.group, win)
    if win.autoScale then win:UpdateScale() end
    return win
end

function Window:HeaderRow(align, opts)
    if self.header == nil then return nil end
    local o = opts or {}
    local r = metaTable.setmetatable({}, HeaderRow)
    r.win     = self
    r.area    = self.header
    r.align   = align or "left"
    r.inset   = o.inset   or UBUI.Theme.closeInset or 8
    r.spacing = o.spacing or UBUI.Theme.spacing
    r.offset  = o.offset  or 0
    r.h       = o.h or (self.headerH - r.inset * 2)
    if r.h < 16 then r.h = 16 end
    r.items = {}
    self.headerRows[#self.headerRows + 1] = r
    return r
end

function Window:LayoutHeader()
    for i = 1, #self.headerRows do self.headerRows[i]:Layout() end
    return self
end

function Window:Rotate(degrees)
    return rotate(self, degrees, "Window.Rotate")
end

local function rowOpts(r, opts, defaultW)
    local o = {}
    if opts ~= nil then
        for k, v in tableIterators.pairs(opts) do o[k] = v end
    end
    o.w = o.w or defaultW
    o.h = o.h or r.h
    o.x = 0
    o.y = 0
    return o
end

function HeaderRow:Add(el, w, h)
    if el == nil then return nil end
    self.items[#self.items + 1] = { el = el, w = w, h = h }
    self:Layout()
    return el
end

function HeaderRow:Button(label, onClick, opts)
    local o = rowOpts(self, opts, nil)
    o.w = o.w or o.h
    o.fontSize = o.fontSize or math.floor(o.h * 0.5)
    local el = self.area:Button(label, onClick, o)
    if el ~= nil then el:SetAlign(o.align or "MiddleCenter") end
    return self:Add(el, o.w, o.h)
end

function HeaderRow:Text(text, opts)
    local o  = rowOpts(self, opts, 120)
    local el = self.area:Text(text, o)
    if el ~= nil then el:SetAlign(o.align or "MiddleCenter") end
    return self:Add(el, o.w, o.h)
end

function HeaderRow:Toggle(label, value, onChange, opts)
    local o = rowOpts(self, opts, 120)
    return self:Add(self.area:Toggle(label, value, onChange, o), o.w, o.h)
end

function HeaderRow:Image(opts)
    local o = rowOpts(self, opts, nil)
    o.w = o.w or o.h
    return self:Add(self.area:Image(o), o.w, o.h)
end

function HeaderRow:Space(pixels)
    self.items[#self.items + 1] = { el = nil, w = pixels or self.spacing, h = 0 }
    return self:Layout()
end

function HeaderRow:Width()
    local total, n, shown = 0, #self.items, 0
    for i = 1, n do
        local it = self.items[i]
        if it.el == nil or it.el.visible then
            total = total + it.w
            shown = shown + 1
        end
    end
    if shown > 1 then total = total + self.spacing * (shown - 1) end
    return total
end

function HeaderRow:Layout()
    local win = self.win
    if win == nil or not win:IsAlive() then return self end
    local total = self:Width()
    local x     = self.inset + self.offset
    if self.align == "right" then
        x = win.w - self.inset - total + self.offset
    elseif self.align == "center" then
        x = math.floor((win.w - total) * 0.5) + self.offset
    end
    local first, last, step = 1, #self.items, 1
    if self.align == "right" then first, last, step = #self.items, 1, -1 end
    for i = first, last, step do
        local it = self.items[i]
        if it.el == nil then
            x = x + it.w + self.spacing
        elseif it.el:IsAlive() and it.el.visible then
            it.el:SetRect(x, math.floor((win.headerH - it.h) * 0.5), it.w, it.h)
            it.el:UpdateBorders()
            x = x + it.w + self.spacing
        end
    end
    return self
end

function HeaderRow:SetAlign(align)  self.align  = align;  return self:Layout() end
function HeaderRow:SetOffset(px)    self.offset = px;     return self:Layout() end
function HeaderRow:SetSpacing(px)   self.spacing = px;    return self:Layout() end

function HeaderRow:AsGroup(name)
    local g = UBUI.Group(name)
    for i = 1, #self.items do
        if self.items[i].el ~= nil then g:Add(self.items[i].el) end
    end
    return g
end

function HeaderRow:Clear()
    for i = 1, #self.items do
        local it = self.items[i]
        if it.el ~= nil then it.el:Destroy() end
    end
    self.items = {}
    return self
end

function Window:IsAlive() return UBUI.IsAlive(self.obj) end
function Window:GetInstanceId()
    if self.instanceId == nil then
        self.instanceId = UBUI.GetInstanceId(self.obj)
    end

    return self.instanceId
end
function Window:HasClipping() return UBUI.HasClipping(self) end
function Window:SetClipping(state) return UBUI.SetClipping(self, state) end

function Window:Open()
    self.isOpen = true
    if self:IsAlive() then
        self.obj.Active = true
        UBUI.BringToFront(self.obj)
    end
    if self.autoScale then self:UpdateScale() end
    local g = self.openGroup
    if g ~= nil and g._openBusy ~= true then g:SetOpen(true) end
    return self
end

function Window:Close()
    self.isOpen = false
    if self:IsAlive() then self.obj.Active = false end
    if self.onClose ~= nil then
        UBUI._SafeCall("Window.onClose", function()
            self.onClose(self)
        end)
    end
    local g = self.openGroup
    if g ~= nil and g._openBusy ~= true then g:SetOpen(false) end
    return self
end

function Window:Toggle()
    if self.isOpen then return self:Close() end
    return self:Open()
end

function Window:IsOpen() return self.isOpen end

function Window:SetTitle(text)
    if self.title ~= nil then self.title:SetText(text) end
    return self
end

function Window:SetPosition(x, y)
    self.x, self.y = x, y
    if self.centered then UBUI.SetCenterRect(self.obj, x, y, self.w, self.h)
    else UBUI.SetTopRect(self.obj, x, y, self.w, self.h) end
    return self
end

function Window:Center()
    self.centered = true
    self.x, self.y = 0, 0
    UBUI.SetCenterRect(self.obj, 0, 0, self.w, self.h)
    return self
end

function Window:Tag(tags)    return UBUI.Tag(self, tags) end
function Window:AddTo(group) return UBUI.Attach(group, self) end

function Window:ShareOpen(group)
    local g = group
    if not UBUI.IsGroup(g) then g = UBUI.Group(g) end
    g:Add(self)
    return g:ShareOpen()
end

function Window:UpdateScale()
    if not self:IsAlive() then return end
    local sw, sh = UBUI.ScreenSize()
    if sw == nil then return end
    if sw == self._screenW and sh == self._screenH then return end
    self._screenW = sw
    self._screenH = sh
    local m  = self.margin
    local sx = (sw - m * 2) / self.w
    local sy = (sh - m * 2) / self.h
    local s = sx
    if sy < s then s = sy end
    if s > 1 then s = 1 end
    if s < self.minScale then s = self.minScale end
    self.scale = s
	UBUI._SafeCall("Window.UpdateScale", function()
        self.obj.Transform.LocalScale = Vector3.New(s, s, 1)
    end)    
    if self.centered then UBUI.SetCenterRect(self.obj, self.x, self.y, self.w, self.h) end
end

function Window:UpdateBorders()
    if self.borders == nil then return self end
    for i = 1, #self.borders do self.borders[i]:Update() end
    return self
end

function Window:Restyle()
    if not self:IsAlive() then return self end
    local o   = self.opts or {}
    if o.clipping ~= nil then self:SetClipping(o.clipping) end
    local img = UBUI.GetImageComp(self.obj)
    UBUI.SetField(img, "color", o.rootColor or UBUI.Theme.root, "Window.Restyle", false)
    if self.header ~= nil then
        self.header:Restyle()
        self.header:SetColor(o.headerColor or UBUI.Theme.header)
    end
	if self.headerLine ~= nil then
        local l = UBUI.GetImageComp(self.headerLine)
        UBUI.SetField(l, "color", o.borderColor or UBUI.Theme.border, "Window.Restyle", false)
    end
    if self.frame ~= nil then self.frame:SetColor(o.borderColor or UBUI.Theme.border) end
    if self.title ~= nil then
        self.title:SetStyle("title")
        if o.titleColor ~= nil then self.title:SetTextColor(o.titleColor) end
        if o.titleSize  ~= nil then self.title:SetFontSize(o.titleSize)   end
        if o.titleAlign ~= nil then self.title:SetAlign(o.titleAlign)     end
    end
    if self.body ~= nil then self.body:Restyle() end
    self:UpdateBorders()
    return self:LayoutHeader()
end

function Window:Destroy()
    UBUI._Untrack(self)
    local obj = self.obj
    self.obj = nil
    UBUI._Untrack(obj)
    UBUI.DestroyBorders(self)
    if self.body ~= nil then
        self.body.elements = {}
    end
    if UBUI.IsAlive(obj) then
        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)
    end
    self.body = nil
    self.header = nil
    self.title = nil
    self.headerRows = {}
    self.openGroup = nil
    self.clipping = false
    self.clipComponent = nil
end

local ScrollView = {}
ScrollView.__index = ScrollView
UBUI.ScrollViewClass = ScrollView

local function makeBar(parent, name, x, y, w, h, dir, trackColor, handleColor)
    local bar = UBUI.NewImageObject(parent, name, x, y, w, h, trackColor, true)
    if bar == nil then return nil end
    local ok, sb = UBUI._SafeCall("MakeBar.AddComponent", function()
        return bar.AddComponent("UnityEngine.UI.Scrollbar")
    end)
    if not ok then sb = nil end
    local area = UBUI.NewImageObject(bar.Transform, name .. "_Slide", 0, 0, w, h, UBUI.Colors.clear, false)
    if area == nil then return sb, bar, nil end
    UBUI.StretchRect(UBUI.GetRect(area), 0, 0)
    local handle = UBUI.NewImageObject(area.Transform, name .. "_Handle", 0, 0, w, h, handleColor, true)
    if handle == nil then return sb, bar, nil end
    local hRect = UBUI.GetRect(handle)
    UBUI.StretchRect(hRect, 0, 0)
    if sb ~= nil then
        UBUI.SetField(sb, "direction", dir, "MakeBar", false)
        UBUI.SetField(sb, "handleRect", hRect, "MakeBar", false)
        local hImg = UBUI.GetImageComp(handle)
        if hImg ~= nil then UBUI.SetField(sb, "targetGraphic", hImg, "MakeBar", false) end
        UBUI.SetField(sb, "transition", 0, "MakeBar", false)
        UBUI.SetField(sb, "interactable", true, "MakeBar", false)
        UBUI.SetField(sb, "value", dir == 2 and 1 or 0, "MakeBar", false)
        UBUI.SetField(sb, "size", 1, "MakeBar", false)
    end
    return sb, bar, handle
end

function UBUI.ScrollViewAt(parentTransform, name, x, y, w, h, opts)
    if not UBUI.HasStyles() then return nil end
    if parentTransform == nil then return nil end
    local o = UBUI.StyleOpts("scrollview", opts)

    name = name or UBUI.NextName("Scroll")
    local horizontal = o.horizontal == true
    local vertical   = o.vertical ~= false
    local hideV      = o.hideVertical   == true
    local hideH      = o.hideHorizontal == true
    local showVBar   = vertical   and not hideV
    local showHBar   = horizontal and not hideH
    local barSize    = o.scrollbarSize or 12
    local bt         = o.borderThickness or UBUI.Theme.borderThickness
    local trackC     = o.trackColor  or UBUI.Theme.scrollTrack  or UBUI.Theme.sliderBg
    local handleC    = o.handleColor or UBUI.Theme.scrollHandle or UBUI.Theme.sliderFill
    local rootC      = o.bgColor or o.color or UBUI.Theme.scrollBg or UBUI.Colors.clear

    local vBarSpace = showVBar and barSize or 0
    local hBarSpace = showHBar and barSize or 0
    local viewportW = w - vBarSpace
    local viewportH = h - hBarSpace
    if viewportW < 1 then viewportW = 1 end
    if viewportH < 1 then viewportH = 1 end

    local root = UBUI.NewImageObject(parentTransform, name, x, y, w, h, rootC, false)
    if root == nil then return nil end
    
    local function fail()
    	UBUI._Untrack(root)

    	if UBUI.IsAlive(root) then
        	errorHandling.pcall(function()
            	root.DestroyLocal()
        	end)
    	end

    	return nil
	end

    local viewport = UBUI.NewImageObject(root.Transform, name .. "_Viewport",
        0, 0, viewportW, viewportH, UBUI.Colors.clear, true)
	if viewport == nil then return fail() end
    UBUI.SetClipping(viewport, true)

    local contentW = o.contentWidth or viewportW
    local content  = UBUI.NewAreaAt(viewport.Transform, name .. "_Content", 0, 0, contentW, viewportH, {
        padding = o.padding,
        spacing = o.spacing,
        color   = o.contentColor or UBUI.Colors.clear,
        raycast = o.contentRaycast == true,
    })
	if content == nil then return fail() end

    local sv = metaTable.setmetatable({}, ScrollView)
    sv.obj = root
    sv.instanceId = UBUI._IndexObject(root)
    sv.transform = root.Transform
    sv.name = name
    sv.kind = "scrollview"
    sv.visible = true
    sv.scrollVisible = true
    sv.w, sv.h = w, h
    sv.x, sv.y = x, y
    sv.viewportW = viewportW
    sv.viewportH = viewportH
    sv.contentW = contentW
    sv.horizontal = horizontal
    sv.vertical = vertical
    sv.barSize = barSize
    sv.opts = o
    sv.userOpts = opts
    sv.headerRows = {}
    sv.content = content
    sv.body = content
    sv.viewport = viewport
    sv.culling = o.culling ~= false
    sv.cullingPadding = UBUI.Num(o.cullingPadding, 96)
    sv._cullDirty = true
    sv._cullLines = nil
    sv._activeCullItems = {}
    sv._cullScratch = {}

    if sv.cullingPadding < 0 then
        sv.cullingPadding = 0
    end

    local baseRelayout = Area.Relayout
    content.Relayout = function(a)
        baseRelayout(a)
        sv._cullDirty = true

        if sv._fitting ~= true then
            sv:Fit()
        end

        if sv.culling == true then
            sv:UpdateCulling()
        end

        return a
    end

    local vsb, hsb
    if showVBar then
        vsb, sv.vBarObj, sv.vHandleObj = makeBar(root.Transform, name .. "_VBar",
            viewportW, 0, barSize, viewportH, 2, trackC, handleC)
    end
    if showHBar then
        hsb, sv.hBarObj, sv.hHandleObj = makeBar(root.Transform, name .. "_HBar",
            0, viewportH, viewportW, barSize, 0, trackC, handleC)
    end

    local srOk, sr = UBUI._SafeCall(
    	"ScrollView.AddScrollRect",
    	function()
        	return root.AddComponent(
            	"UnityEngine.UI.ScrollRect"
    		)
    	end
	)

	if not srOk or not UBUI.IsAlive(sr) then
    	return fail()
	end

	sv.scrollRect = sr
    if sr ~= nil then
        UBUI.SetField(sr, "horizontal", horizontal, "ScrollView.Setup", false)
        UBUI.SetField(sr, "vertical", vertical, "ScrollView.Setup", false)
        UBUI.SetField(sr, "viewport", UBUI.GetRect(viewport), "ScrollView.Setup", false)
        UBUI.SetField(sr, "content", UBUI.GetRect(content.obj), "ScrollView.Setup", false)
        UBUI.SetField(sr, "movementType", o.elastic == true and 1 or 2, "ScrollView.Setup", false)
        UBUI.SetField(sr, "scrollSensitivity", o.sensitivity or 24, "ScrollView.Setup", false)
        UBUI.SetField(sr, "inertia", o.inertia ~= false, "ScrollView.Setup", false)
        UBUI.SetField(sr, "decelerationRate", o.decelerationRate or 0.135, "ScrollView.Setup", false)
        local vis = o.autoHide == true and 1 or 0
        if vsb ~= nil then
            UBUI.SetField(sr, "verticalScrollbar", vsb, "ScrollView.Setup", false)
            UBUI.SetField(sr, "verticalScrollbarVisibility", vis, "ScrollView.Setup", false)
        end
        if hsb ~= nil then
            UBUI.SetField(sr, "horizontalScrollbar", hsb, "ScrollView.Setup", false)
            UBUI.SetField(sr, "horizontalScrollbarVisibility", vis, "ScrollView.Setup", false)
        end
    end

    if o.border ~= false then
        sv.frameThickness = bt
        sv.frameColor     = o.borderColor or UBUI.Theme.scrollBorder or UBUI.Theme.border
        sv.framePieces    = {}
        for i = 1, 4 do
            sv.framePieces[i] = UBUI.NewImageObject(root.Transform,
                name .. "_Frame_" .. i, 0, 0, 1, 1, sv.frameColor, false)
        end
        sv:UpdateFrame()
    end

    sv:Fit()
    sv:UpdateCulling(true)
	if sr ~= nil then
        if vertical then UBUI.SetField(sr, "verticalNormalizedPosition", 1, "ScrollView.Setup", false) end
        if horizontal then UBUI.SetField(sr, "horizontalNormalizedPosition", 0, "ScrollView.Setup", false) end
    end

    UBUI.Tag(sv, o.tags)
    table.insert(UBUI._scrollViews, sv)
    UBUI.Attach(o.group, sv)
    return sv
end

function UBUI.ScrollView(space, name, x, y, w, h, opts)
    local parent = UBUI.GetSpace(space)
    if parent == nil then return nil end
    local sv = UBUI.ScrollViewAt(parent, name, x, y, w, h, opts)
    if sv ~= nil then sv.space = space end
    return sv
end

function ScrollView:IsAlive()  return UBUI.IsAlive(self.obj) end
function ScrollView:GetInstanceId()
    if self.instanceId == nil then
        self.instanceId = UBUI.GetInstanceId(self.obj)
    end

    return self.instanceId
end
function ScrollView:IsVisible() return self.visible end

function ScrollView:Rotate(degrees)
    return rotate(self, degrees, "ScrollView.Rotate")
end

local function SetViewportCulled(target, state)
    if basicModule.type(target) ~= "table" then return end

    local changed = target._viewportCulled ~= state
    target._viewportCulled = state

    if UBUI.IsAlive(target.obj) then
        target.obj.Active = state ~= true and target.visible ~= false
    end

    if state == true or not changed then return end

    local watchers = target._viewportWatchers

    if watchers ~= nil then
        target._viewportWatchers = nil

        for kind, last in tableIterators.pairs(watchers) do
            UBUI.AddWatcher(target, kind, last)
        end
    end

    if target._viewportPickerSuspended == true then
        target._viewportPickerSuspended = nil
        table.insert(UBUI._pickers, target)
    end
end

local function FirstVisibleCullLine(lines, top)
    local low = 1
    local high = #lines
    local result = high + 1

    while low <= high do
        local middle = math.floor((low + high) * 0.5)

        if lines[middle].bottom >= top then
            result = middle
            high = middle - 1
        else
            low = middle + 1
        end
    end

    return result
end

local function LastVisibleCullLine(lines, bottom)
    local low = 1
    local high = #lines
    local result = 0

    while low <= high do
        local middle = math.floor((low + high) * 0.5)

        if lines[middle].top <= bottom then
            result = middle
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return result
end

function ScrollView:RebuildCulling()
    if self.culling ~= true or self.content == nil then
        return self
    end

    local area = self.content
    local previous = self._activeCullItems or {}
    local spacing = UBUI.Num(area.spacing, 0)
    local lines = {}
    local y = UBUI.Num(area.padTop, 0)

    for _, line in tableIterators.ipairs(area.lines or {}) do
        local visible = line.spacer == true
        local items = {}

        for _, item in tableIterators.ipairs(line.items or {}) do
            local target = item.el

            if target ~= nil then
                table.insert(items, item)

                if previous[target] ~= true then
                    SetViewportCulled(target, true)
                end

                if target.visible ~= false
                    and basicModule.type(target.IsAlive) == "function"
                    and target:IsAlive() then
                    visible = true
                end
            end
        end

        if visible then
            local h = UBUI.Num(line.h, 0)

            table.insert(lines, {
                top = y,
                bottom = y + h,
                items = items
            })

            y = y + h + spacing
        end
    end

    self._cullLines = lines
    self._cullDirty = false

    return self
end

function ScrollView:UpdateCulling(force)
    if self.culling ~= true or not self:IsAlive() then
        return self
    end

    if force == true then
        self._cullDirty = true
    end

    if self._cullDirty == true or self._cullLines == nil then
        self:RebuildCulling()
    end

    local lines = self._cullLines or {}
    local previous = self._activeCullItems or {}
    local active = self._cullScratch or {}

    for target in tableIterators.pairs(active) do
        active[target] = nil
    end

    local padding = self.cullingPadding or 0
    local contentW = self._contentW or self.viewportW
    local contentH = self._contentH or self.viewportH

    local vertical = UBUI.GetNum(
        self.scrollRect,
        "verticalNormalizedPosition",
        1
    )

    local horizontal = UBUI.GetNum(
        self.scrollRect,
        "horizontalNormalizedPosition",
        0
    )

    if vertical < 0 then vertical = 0 end
    if vertical > 1 then vertical = 1 end
    if horizontal < 0 then horizontal = 0 end
    if horizontal > 1 then horizontal = 1 end

    local top = (1 - vertical) * math.max(
        contentH - self.viewportH,
        0
    )

    local left = horizontal * math.max(
        contentW - self.viewportW,
        0
    )

    local bottom = top + self.viewportH
    local right = left + self.viewportW

    top = top - padding
    left = left - padding
    bottom = bottom + padding
    right = right + padding

    local first = 1
    local last = #lines

    if self.vertical == true then
        first = FirstVisibleCullLine(lines, top)
        last = LastVisibleCullLine(lines, bottom)
    end

    if first <= last then
        for index = first, last do
            local line = lines[index]

            for _, item in tableIterators.ipairs(line.items) do
                local target = item.el

                if target ~= nil and target.visible ~= false then
                    local itemVisible = true

                    if self.horizontal == true then
                        local itemLeft = UBUI.Num(item.x, 0)
                        local itemRight = itemLeft + UBUI.Num(item.w, 0)

                        itemVisible =
                            itemRight >= left and
                            itemLeft <= right
                    end

                    if itemVisible then
                        active[target] = true
                    end
                end
            end
        end
    end

    for target in tableIterators.pairs(previous) do
        if active[target] ~= true then
            SetViewportCulled(target, true)
        end
    end

    for target in tableIterators.pairs(active) do
        if previous[target] ~= true
            or target._viewportCulled == true then
            SetViewportCulled(target, false)
        end
    end

    self._activeCullItems = active
    self._cullScratch = previous
    self._lastCullVertical = vertical
    self._lastCullHorizontal = horizontal

    return self
end

function ScrollView:PollCulling()
    if self.culling ~= true or not self:IsAlive() then
        return self
    end

    local vertical = UBUI.GetNum(
        self.scrollRect,
        "verticalNormalizedPosition",
        1
    )

    local horizontal = UBUI.GetNum(
        self.scrollRect,
        "horizontalNormalizedPosition",
        0
    )

    local verticalChanged =
        self._lastCullVertical == nil or
        math.abs(vertical - self._lastCullVertical) > 0.000001

    local horizontalChanged =
        self._lastCullHorizontal == nil or
        math.abs(horizontal - self._lastCullHorizontal) > 0.000001

    if self._cullDirty == true
        or verticalChanged
        or horizontalChanged then
        self:UpdateCulling()
    end

    return self
end

function ScrollView:SetCulling(state)
    self.culling = state ~= false
    self._cullDirty = true

    if self.culling == true then
        return self:UpdateCulling(true)
    end

    local lines = self._cullLines or {}

    for _, line in tableIterators.ipairs(lines) do
        for _, item in tableIterators.ipairs(line.items) do
            SetViewportCulled(item.el, false)
        end
    end

    self._cullLines = nil
    self._activeCullItems = {}
    self._cullScratch = {}

    return self
end

function ScrollView:SetCullingPadding(padding)
    self.cullingPadding = UBUI.Num(padding, 96)

    if self.cullingPadding < 0 then
        self.cullingPadding = 0
    end

    return self:UpdateCulling(true)
end

function ScrollView:BeginBatch()
    if self.content == nil then return self end

    local depth = self._batchDepth or 0

    if depth == 0 then
        self._batchRelayout = self.content.Relayout
        self._fitting = true

        self.content.Relayout = function(area)
            area._layoutDirty = true
            return area
        end
    end

    self._batchDepth = depth + 1

    return self
end

function ScrollView:EndBatch()
    local depth = self._batchDepth or 0

    if depth <= 0 then return self end

    depth = depth - 1
    self._batchDepth = depth

    if depth > 0 then return self end

    local relayout = self._batchRelayout

    self._batchRelayout = nil
    self._fitting = false

    if self.content ~= nil
        and basicModule.type(relayout) == "function" then
        self.content.Relayout = relayout
        relayout(self.content)
    end

    return self
end

function ScrollView:Batch(callback, ...)
    if basicModule.type(callback) ~= "function" then
        LogFailure("ScrollView.Batch", "callback is not a function")
        return self
    end

    local args = table.pack(...)

    self:BeginBatch()

    local ok, err = errorHandling.pcall(function()
        callback(
            self.content,
            self,
            table.unpack(args, 1, args.n)
        )
    end)

    self:EndBatch()

    if not ok then
        LogFailure("ScrollView.Batch", err)
    end

    return self
end

function ScrollView:SetActive(state)
    self.visible = state
    if self:IsAlive() then self.obj.Active = state end
    if self.area ~= nil then self.area:Relayout() end
    return self
end
ScrollView.SetVisible = ScrollView.SetActive
function ScrollView:Show() return self:SetActive(true)  end
function ScrollView:Hide() return self:SetActive(false) end

function ScrollView:Measure()
    local area = self.content

    if area == nil then
        return 0, 0
    end

    local padLeft   = UBUI.Num(area.padLeft, 0)
    local padRight  = UBUI.Num(area.padRight, 0)
    local padTop    = UBUI.Num(area.padTop, 0)
    local padBottom = UBUI.Num(area.padBottom, 0)
    local spacing   = UBUI.Num(area.spacing, 0)

    local height = padTop
    local maxX = padLeft
    local visibleLines = 0

    for _, line in tableIterators.ipairs(area.lines or {}) do
        local visible = line.spacer == true

        for _, item in tableIterators.ipairs(line.items or {}) do
            local element = item.el

            if element ~= nil and
                element.visible ~= false and
                basicModule.type(element.IsAlive) == "function" and
                element:IsAlive() then
                visible = true

                local right =
                    UBUI.Num(item.x, 0) +
                    UBUI.Num(item.w, 0)

                if right > maxX then
                    maxX = right
                end
            end
        end

        if visible then
            if visibleLines > 0 then
                height = height + spacing
            end

            height = height + UBUI.Num(line.h, 0)
            visibleLines = visibleLines + 1
        end
    end

    return maxX + padRight, height + padBottom
end

function ScrollView:Fit()
    if self._fitting or not self:IsAlive() then
        return self
    end
    if self.content == nil or not UBUI.IsAlive(self.content.obj) then
        return self
    end
    self._fitting = true
    UBUI._SafeCall("ScrollView.Fit", function()
        local needW, needH = self:Measure()
        local cw = UBUI.Num(self.viewportW, 1)
        local ch = UBUI.Num(self.viewportH, 1)

        needW = UBUI.Num(needW, 0)
        needH = UBUI.Num(needH, 0)

        if self.horizontal then
            local base = UBUI.Num(self.contentW, cw)
            if base > cw then cw = base end
            if needW > cw then cw = needW end
        end

        if self.vertical and needH > ch then
            ch = needH
        end

        local rect = UBUI.GetRect(self.content.obj)
        UBUI.SetField(rect, "sizeDelta", Vector2.New(cw, ch), "ScrollView.Fit", false)
        self._contentW = cw
        self._contentH = ch
    end)
    self._fitting = false
    return self
end

function ScrollView:Clear()
    if self.content ~= nil then self.content:Clear() end
    return self:Fit()
end

function ScrollView:SetVertical(pos)
    UBUI.SetField(
        self.scrollRect,
        "verticalNormalizedPosition",
        UBUI.Num(pos, 1),
        "ScrollView.SetVertical",
        false
    )

    return self:UpdateCulling()
end

function ScrollView:SetHorizontal(pos)
    UBUI.SetField(
        self.scrollRect,
        "horizontalNormalizedPosition",
        UBUI.Num(pos, 0),
        "ScrollView.SetHorizontal",
        false
    )

    return self:UpdateCulling()
end

function ScrollView:ToTop()    return self:SetVertical(1) end
function ScrollView:ToBottom() return self:SetVertical(0) end

function ScrollView:LockHorizontal(state)
    local lock = state ~= false
    self.hLocked = lock
    UBUI.SetField(self.scrollRect, "horizontal", not lock, "ScrollView.LockHorizontal", false)
    if UBUI.IsAlive(self.hBarObj) then self.hBarObj.Active = self.scrollVisible and not lock end
    if lock then self:SetHorizontal(0) end
    return self
end

function ScrollView:LockVertical(state)
    local lock = state ~= false
    self.vLocked = lock
    UBUI.SetField(self.scrollRect, "vertical", not lock, "ScrollView.LockVertical", false)
    if UBUI.IsAlive(self.vBarObj) then self.vBarObj.Active = self.scrollVisible and not lock end
    if lock then self:SetVertical(1) end
    return self
end
function ScrollView:UnlockHorizontal() return self:LockHorizontal(false) end
function ScrollView:UnlockVertical()   return self:LockVertical(false) end

local SV_ANCHORS = {
    upperleft  = { 0, 1 },   uppercenter  = { 0.5, 1 },   upperright  = { 1, 1 },
    middleleft = { 0, 0.5 }, middlecenter = { 0.5, 0.5 }, middleright = { 1, 0.5 },
    lowerleft  = { 0, 0 },   lowercenter  = { 0.5, 0 },   lowerright  = { 1, 0 },
    topleft = { 0, 1 }, top = { 0.5, 1 }, topright = { 1, 1 },
    left = { 0, 0.5 }, center = { 0.5, 0.5 }, middle = { 0.5, 0.5 }, right = { 1, 0.5 },
    bottomleft = { 0, 0 }, bottom = { 0.5, 0 }, bottomright = { 1, 0 },
}

local function svVec2(t, fx, fy)
    if t == nil then return nil end
    local x = t.x; if x == nil then x = t[1] end
    local y = t.y; if y == nil then y = t[2] end
    return Vector2.New(UBUI.Num(x, fx or 0), UBUI.Num(y, fy or 0))
end

function ScrollView:Align(align, opts)
    local rect = UBUI.GetRect(self.content.obj)
    if rect == nil then return self end
    local o   = opts or {}
    local key = string.lower(basicModule.tostring(align or "upperleft"))
    local p   = SV_ANCHORS[key] or SV_ANCHORS.upperleft
    local a   = Vector2.New(p[1], p[2])
    UBUI.SetField(rect, "anchorMin", a, "ScrollView.Align", false)
    UBUI.SetField(rect, "anchorMax", a, "ScrollView.Align", false)
    UBUI.SetField(rect, "pivot", svVec2(o.pivot, p[1], p[2]) or a, "ScrollView.Align", false)
    UBUI.SetField(rect, "anchoredPosition", svVec2(o.offset, 0, 0) or Vector2.New(0, 0), "ScrollView.Align", false)
    self.contentAlign = align
    return self
end

function ScrollView:SetContentAnchor(anchorMin, anchorMax, pivot, pos)
    local rect = UBUI.GetRect(self.content.obj)
    if rect == nil then return self end
    local mn, mx, pv, ap = svVec2(anchorMin), svVec2(anchorMax), svVec2(pivot), svVec2(pos)
    if mn ~= nil then UBUI.SetField(rect, "anchorMin", mn, "ScrollView.SetContentAnchor", false) end
    if mx ~= nil then UBUI.SetField(rect, "anchorMax", mx, "ScrollView.SetContentAnchor", false) end
    if pv ~= nil then UBUI.SetField(rect, "pivot", pv, "ScrollView.SetContentAnchor", false) end
    if ap ~= nil then UBUI.SetField(rect, "anchoredPosition", ap, "ScrollView.SetContentAnchor", false) end
    return self
end

function ScrollView:UpdateFrame()
    local p = self.framePieces
    if p == nil then return self end
    local bt   = self.frameThickness or UBUI.Theme.borderThickness
    local hh   = self.headerH or 0
    local boxH = self.scrollVisible ~= false and self.h or 0
    local top  = -hh
    local W, H = self.w, hh + boxH
    UBUI.SetTopRect(p[1], 0,      top,          W,  bt)
    UBUI.SetTopRect(p[2], 0,      top + H - bt, W,  bt)
    UBUI.SetTopRect(p[3], 0,      top,          bt, H)
    UBUI.SetTopRect(p[4], W - bt, top,          bt, H)
    for i = 1, 4 do
    	if UBUI.IsAlive(p[i]) then UBUI.BringToFront(p[i]) end
    end
    return self
end

function ScrollView:SetFrameColor(color)
    self.frameColor = color
    local p = self.framePieces
    if p == nil then return self end
    for i = 1, 4 do
        local img = UBUI.GetImageComp(p[i])
        UBUI.SetField(img, "color", color, "ScrollView.SetFrameColor", false)
    end
    return self
end

function ScrollView:SetFrameVisible(state)
    local p = self.framePieces
    if p == nil then return self end
    for i = 1, 4 do
        if UBUI.IsAlive(p[i]) then p[i].Active = state end
    end
    return self
end

function ScrollView:SetScrollVisible(state)
    if self.scrollVisible == state then return self end
    self.scrollVisible = state
    if UBUI.IsAlive(self.viewport) then self.viewport.Active = state end
    if self.vertical   and UBUI.IsAlive(self.vBarObj) then self.vBarObj.Active = state and not self.vLocked end
    if self.horizontal and UBUI.IsAlive(self.hBarObj) then self.hBarObj.Active = state and not self.hLocked end
    UBUI.SetField(self.scrollRect, "enabled", state, "ScrollView.SetScrollVisible", false)
    local it = self.item
    if it ~= nil then
        if state then it.h = self._fullH or self.h
        else self._fullH = it.h; it.h = 0 end
        local line = it.line
        if line ~= nil then
            local m = 0
            for j = 1, #line.items do
                local h = line.items[j].h
                if h ~= nil and h > m then m = h end
            end
            line.h = m
        end
    end
    if self.area ~= nil and UBUI.IsAlive(self.area.obj) then
    UBUI._SafeCall("Area.Relayout", function()
        self.area:Relayout()
        end)
    end

    self:UpdateFrame()
    return self
end
function ScrollView:ShowScroll() return self:SetScrollVisible(true)  end
function ScrollView:HideScroll() return self:SetScrollVisible(false) end
function ScrollView:ToggleScroll()
    if self.scrollVisible == false then return self:SetScrollVisible(true) end
    return self:SetScrollVisible(false)
end

function ScrollView:Header(height, opts)
    if not self:IsAlive() then return self end

    local o = opts

    if basicModule.type(height) == "table" then
        o = height
        height = nil
    end

    o = o or {}
    self.headerOpts = o

    local h = UBUI.Num(
        height or o.h or 44,
        44
    )

    if h < 0 then h = 0 end

    self.headerH = h
    self.headerRows = self.headerRows or {}

    local bt =
        o.borderThickness or
        UBUI.Theme.borderThickness

    local headColor =
        o.color or
        o.headerColor or
        UBUI.Theme.scrollHeader or
        UBUI.Theme.header

    local borderColor =
        o.borderColor or
        UBUI.Theme.scrollBorder or
        UBUI.Theme.border

    if self.header == nil then
        self.header = UBUI.NewAreaAt(
            self.transform,
            self.name .. "_Header",
            0,
            -h,
            self.w,
            h,
            {
                color = headColor,
                raycast = true,
                padding = 0,
                spacing = 0,
            }
        )

        self.headerLine = UBUI.NewImageObject(
            self.transform,
            self.name .. "_HeaderLine",
            0,
            -bt,
            self.w,
            bt,
            borderColor,
            false
        )
    else
        self.header:SetRect(
            0,
            -h,
            self.w,
            h
        )

        self.header:SetColor(headColor)

        if UBUI.IsAlive(self.headerLine) then
            UBUI.SetTopRect(
                self.headerLine,
                0,
                -bt,
                self.w,
                bt
            )

            UBUI.SetField(
                UBUI.GetImageComp(self.headerLine),
                "color",
                borderColor,
                "ScrollView.Header.borderColor",
                false
            )
        end
    end

    if o.label ~= nil and self.header ~= nil then
        local inset =
            o.titleInset or
            UBUI.Theme.closeInset or
            12

        local titleW = self.w - inset * 2

        if titleW < 40 then
            titleW = 40
        end

        local title = self.title

        if title == nil or not title:IsAlive() then
            local obj = UBUI.CopyPrefab(
                UBUI.PREFABS.label,
                self.header.transform,
                self.name .. "_Title",
                inset,
                0,
                titleW,
                h
            )

            if obj ~= nil then
                title = UBUI.NewElement(
                    obj,
                    "text",
                    nil
                )

                self.title = title
            end
        else
            title:SetRect(
                inset,
                0,
                titleW,
                h
            )
        end

        if title ~= nil then
            title:SetText(o.label)
            title:SetStyle("title")

            if o.titleColor ~= nil then
                title:SetTextColor(o.titleColor)
            end

            if o.titleSize ~= nil then
                title:SetFontSize(o.titleSize)
            end

            title:SetAlign(
                o.titleAlign or "MiddleLeft"
            )

            UBUI.SetRaycast(
                title.obj,
                false
            )
        end
    end

    self:UpdateFrame()
    return self
end

function ScrollView:HeaderRow(align, opts)
    if self.header == nil then return nil end
    local o = opts or {}
    local r = metaTable.setmetatable({}, HeaderRow)
    r.win     = self
    r.area    = self.header
    r.align   = align or "left"
    r.inset   = o.inset   or UBUI.Theme.closeInset or 8
    r.spacing = o.spacing or UBUI.Theme.spacing
    r.offset  = o.offset  or 0
    r.h       = o.h or (self.headerH - r.inset * 2)
    if r.h < 16 then r.h = 16 end
    r.items = {}
    self.headerRows[#self.headerRows + 1] = r
    return r
end

function ScrollView:LayoutHeader()
    for i = 1, #self.headerRows do self.headerRows[i]:Layout() end
    return self
end

function ScrollView:Border(opts) return UBUI.Border(self, opts) end
function ScrollView:Outline(opts) return UBUI.Outline(self, opts) end
function ScrollView:Shadow(opts)  return UBUI.Shadow(self, opts)  end
function ScrollView:UpdateBorders()
    if self.borders == nil then return self end
    for i = 1, #self.borders do self.borders[i]:Update() end
    return self
end

function ScrollView:Tag(tags)    return UBUI.Tag(self, tags) end
function ScrollView:AddTo(group) return UBUI.Attach(group, self) end

local function barColor(obj, color)
    local img = UBUI.GetImageComp(obj)
    UBUI.SetField(img, "color", color, "ScrollView.BarColor", false)
end

function ScrollView:Restyle()
    if not self:IsAlive() then return self end

    local o = UBUI.StyleOpts(
        "scrollview",
        self.userOpts
    )

    local headerOpts = self.headerOpts or {}

    self.opts = o
    self.frameThickness =
        o.borderThickness or
        UBUI.Theme.borderThickness

    UBUI.SetField(
        UBUI.GetImageComp(self.obj),
        "color",
        o.bgColor or
        o.color or
        UBUI.Theme.scrollBg or
        UBUI.Colors.clear,
        "ScrollView.Restyle",
        false
    )

    local trackColor =
        o.trackColor or
        UBUI.Theme.scrollTrack or
        UBUI.Theme.sliderBg

    local handleColor =
        o.handleColor or
        UBUI.Theme.scrollHandle or
        UBUI.Theme.sliderFill

    barColor(self.vBarObj, trackColor)
    barColor(self.vHandleObj, handleColor)
    barColor(self.hBarObj, trackColor)
    barColor(self.hHandleObj, handleColor)

    self:SetFrameColor(
        o.borderColor or
        UBUI.Theme.scrollBorder or
        UBUI.Theme.border
    )

    if self.header ~= nil then
        self.header:Restyle()

        self.header:SetColor(
            headerOpts.color or
            headerOpts.headerColor or
            UBUI.Theme.scrollHeader or
            UBUI.Theme.header
        )
    end

    if UBUI.IsAlive(self.headerLine) then
        local thickness =
            headerOpts.borderThickness or
            UBUI.Theme.borderThickness

        UBUI.SetTopRect(
            self.headerLine,
            0,
            -thickness,
            self.w,
            thickness
        )

        UBUI.SetField(
            UBUI.GetImageComp(self.headerLine),
            "color",
            headerOpts.borderColor or
            UBUI.Theme.scrollBorder or
            UBUI.Theme.border,
            "ScrollView.Restyle.headerLine",
            false
        )
    end

    if self.title ~= nil then
        self.title:SetStyle("title")

        if headerOpts.titleColor ~= nil then
            self.title:SetTextColor(
                headerOpts.titleColor
            )
        end

        if headerOpts.titleSize ~= nil then
            self.title:SetFontSize(
                headerOpts.titleSize
            )
        end

        if headerOpts.titleAlign ~= nil then
            self.title:SetAlign(
                headerOpts.titleAlign
            )
        end
    end

    if self.content ~= nil then
        self.content:Restyle()

        local padding = UBUI.Num(
            o.padding,
            nil
        )

        if padding ~= nil then
            self.content.padLeft = padding
            self.content.padRight = padding
            self.content.padTop = padding
            self.content.padBottom = padding
        end

        local spacing = UBUI.Num(
            o.spacing,
            nil
        )

        if spacing ~= nil then
            self.content.spacing = spacing
        end

        self.content:Relayout()
    end

    self:UpdateBorders()
    self:UpdateFrame()

    return self:LayoutHeader()
end

function ScrollView:Destroy()
    if self.item ~= nil then self.item.el = nil end
    UBUI._Untrack(self)
    local obj = self.obj
    self.obj = nil
    UBUI._Untrack(obj)
    UBUI.DestroyBorders(self)
    if self.content ~= nil then
        self.content.elements = {}
    end
    if UBUI.IsAlive(obj) then
        errorHandling.pcall(function()
            obj.DestroyLocal()
        end)
    end
    self.content = nil
    self.body = nil
    self.header = nil
    self.title = nil
    self.headerRows = {}
    if self.area ~= nil and self.area.Relayout ~= nil then
        UBUI._SafeCall("Area.Relayout", function()
            self.area:Relayout()
        end)
    end
end

function UBUI.UIUpdate()
    UBUI._frame = UBUI._frame + 1
    local token = UBUI._lifecycleToken
    local watchers = UBUI._watchers
    UBUI._watchers = {}
    for i = 1, #watchers do
        if token ~= UBUI._lifecycleToken then return end

        local watcher = watchers[i]
        local el = watcher.el

        if el ~= nil
            and el:IsAlive()
            and UBUI.IsAlive(el.comp) then
            if el._viewportCulled == true then
                el._viewportWatchers =
                    el._viewportWatchers or {}

                el._viewportWatchers[watcher.kind] =
                    watcher.last
            else
                local ok, current = UBUI._SafeCall(
                    "Watcher read",
                    function()
                        if watcher.kind == "toggle" then
                            return UBUI.Bool(UBUI.GetField(
                                el.comp,
                                "isOn",
                                false,
                                "Watcher",
                                false
                            ))
                        end

                        if watcher.kind == "input" then
                            return basicModule.tostring(
                                UBUI.GetField(
                                    el.comp,
                                    "text",
                                    "",
                                    "Watcher",
                                    false
                                )
                            )
                        end

                        if watcher.kind == "slider" then
                            return UBUI.Num(
                                UBUI.GetField(
                                    el.comp,
                                    "value",
                                    nil,
                                    "Watcher",
                                    false
                                ),
                                0
                            )
                        end

                        return nil
                    end
                )

                if ok then
                    if current ~= watcher.last then
                        watcher.last = current

                        if el.onChange ~= nil then
                            UBUI._SafeCall("onChange", function()
                                el.onChange(current, el)
                            end)
                        end
                    end

                    if token ~= UBUI._lifecycleToken then
                        return
                    end

                    if el:IsAlive()
                        and UBUI.IsAlive(el.comp) then
                        UBUI.AddWatcher(
                            el,
                            watcher.kind,
                            watcher.last
                        )
                    end
                end
            end
        end
    end
    local windows = UBUI._windows
    UBUI._windows = {}
    for i = 1, #windows do
        if token ~= UBUI._lifecycleToken then return end
        local win = windows[i]
        if win ~= nil and win:IsAlive() then
            if win.isOpen and win.autoScale then
                UBUI._SafeCall("Window.UpdateScale", function()
                    win:UpdateScale()
                end)
            end
            local exists = false
            for j = 1, #UBUI._windows do
                if UBUI._windows[j] == win then
                    exists = true
                    break
                end
            end
            if not exists and win:IsAlive() then
                table.insert(UBUI._windows, win)
            end
        end
    end
    for i = #UBUI._scrollViews, 1, -1 do
        if token ~= UBUI._lifecycleToken then return end

        local scrollView = UBUI._scrollViews[i]

        if scrollView == nil or not scrollView:IsAlive() then
            table.remove(UBUI._scrollViews, i)
        elseif scrollView.visible ~= false
            and scrollView.scrollVisible ~= false then
            scrollView:PollCulling()
        end
    end
    local pickers = UBUI._pickers
    UBUI._pickers = {}
    for i = 1, #pickers do
        if token ~= UBUI._lifecycleToken then return end
        local el = pickers[i]
        if el ~= nil and el:IsAlive() then
            if el:IsVisible()
                and el._viewportCulled ~= true then
                local ok, hex = UBUI._SafeCall("ColorPicker.GetHex", function()
                    return el:GetHex()
                end)
                if ok and hex ~= nil and hex ~= el._lastHex then
                    local colorOk, color = UBUI._SafeCall(
                        "ColorPicker.GetColor",
                        function()
                            return el:GetPickerColor()
                        end
                    )

                    if colorOk and color ~= nil then
                        el._lastHex = hex

                        if el.onChange ~= nil then
                            UBUI._SafeCall("ColorPicker.onChange", function()
                                el.onChange(color, el)
                            end)
                        end
                    end
                end
            end
            if token ~= UBUI._lifecycleToken then return end
            if el._viewportCulled == true then
                el._viewportPickerSuspended = true
            else
                local exists = false

                for j = 1, #UBUI._pickers do
                    if UBUI._pickers[j] == el then
                        exists = true
                        break
                    end
                end

                if not exists
                    and el ~= nil
                    and el:IsAlive() then
                    table.insert(UBUI._pickers, el)
                end
            end
        end
    end
        local pruneInterval = UBUI.Num(
        UBUI.PRUNE_INTERVAL,
        120
    )

    if pruneInterval > 0
    and UBUI._frame % pruneInterval == 0 then
        UBUI._SafeCall(
            "PruneGroups",
            UBUI.PruneGroups
        )

        if UBUI._pruneOwnedActive ~= true
        and UBUI._ownedCount > 0 then
            UBUI._pruneOwnedCursor = 1
            UBUI._pruneOwnedActive = true
        end
    end

    if UBUI._pruneOwnedActive == true then
        local ok = UBUI._SafeCall(
            "PruneOwned",
            UBUI._PruneOwned
        )

        if not ok then
            UBUI._pruneOwnedActive = false
            UBUI._pruneOwnedCursor = 1
        end
    end
end

function UBUI.DestroyAll()
    UBUI._lifecycleToken = UBUI._lifecycleToken + 1

    local windows = UBUI._windows
    local canvases = UBUI._canvases
    local owned = UBUI._owned
    local ownedHigh = UBUI._ownedHigh

    UBUI._windows = {}
    UBUI._watchers = {}
    UBUI._pickers = {}
    UBUI._scrollViews = {}
    UBUI._canvases = {}
    UBUI._owned = {}
    UBUI._ownedById = {}
    UBUI._ownedFree = {}
    UBUI._ownedHigh = 0
    UBUI._ownedCount = 0
    UBUI._ownedIndex = metaTable.setmetatable({}, { __mode = "k" })
    UBUI._ownedIds = metaTable.setmetatable({}, { __mode = "k" })
    UBUI._ownedFallback = metaTable.setmetatable({}, { __mode = "k" })
    UBUI._pruneOwnedCursor = 1
    UBUI._pruneOwnedActive = false
    UBUI._objectsById = {}
    UBUI._prefabCache = {}
    UBUI._fx = {}

    for i = #windows, 1, -1 do
        local win = windows[i]

        if win ~= nil and win.Destroy ~= nil then
            UBUI._SafeCall("Window.Destroy", function()
                win:Destroy()
            end)
        end
    end

    for i = #canvases, 1, -1 do
        local handle = canvases[i]

        if basicModule.type(handle) == "table" then
            local obj = handle.obj
            local space = handle.space

            if space ~= nil then
                UBUI.SPACES[space] = nil
            end

            handle.obj = nil
            handle.transform = nil
            handle.canvas = nil
            handle.scaler = nil
            handle.raycaster = nil
            handle.space = nil

            if UBUI.IsAlive(obj) then
                UBUI._SafeCall("Canvas.DestroyLocal", function()
                    obj.DestroyLocal()
                end)
            end
        end
    end

    for i = ownedHigh, 1, -1 do
        local obj = owned[i]

        if UBUI.IsAlive(obj) then
            UBUI._SafeCall("DestroyLocal", function()
                obj.DestroyLocal()
            end)
        end
    end

    for _, group in tableIterators.pairs(UBUI.GROUPS) do
        if group ~= nil and group.Clear ~= nil then
            UBUI._SafeCall("Group.Clear", function()
                group:Clear()
            end)
        end
    end

    UBUI.GROUPS = {}
    UBUI._tagged = {}
    UBUI.InvalidateSpaces()
end

UBUI.CANVAS_COMP = "UnityEngine.Canvas"
UBUI.RAYCASTER_COMP = "UnityEngine.UI.GraphicRaycaster"

local function unwrapObj(target)
    if target == nil then return nil end
    if basicModule.type(target) == "table" then
        local ok, inner = errorHandling.pcall(function() return target.obj end)
        if ok and inner ~= nil then return inner end
    end
    return target
end

local function ensureCanvas(obj)
    if not UBUI.IsAlive(obj) then return nil end

    local ok, canvas = UBUI._SafeCall(
        "Canvas.GetComponent",
        function()
            return obj.GetComponent(UBUI.CANVAS_COMP)
        end
    )

    if not ok or not UBUI.IsAlive(canvas) then
        ok, canvas = UBUI._SafeCall(
            "Canvas.AddComponent",
            function()
                return obj.AddComponent(UBUI.CANVAS_COMP)
            end
        )

        if not ok or not UBUI.IsAlive(canvas) then
            return nil
        end
    end

    local raycasterOk, raycaster = UBUI._SafeCall(
        "GraphicRaycaster.GetComponent",
        function()
            return obj.GetComponent(UBUI.RAYCASTER_COMP)
        end
    )

    if not raycasterOk or not UBUI.IsAlive(raycaster) then
        UBUI._SafeCall(
            "GraphicRaycaster.AddComponent",
            function()
                return obj.AddComponent(UBUI.RAYCASTER_COMP)
            end
        )
    end

    return canvas
end

function UBUI.SetRenderLayer(target, order)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then
        LogError("render layer target is not valid")
        return target
    end
    local canvas = ensureCanvas(obj)
    if canvas == nil then
        LogError("Canvas creation failed")
        return target
    end
    local value = UBUI.Num(order, 0)
	UBUI.SetField(canvas, "overrideSorting", true, "Canvas.SetRenderLayer", true)
    UBUI.SetField(canvas, "sortingOrder", value, "Canvas.SetRenderLayer", true)
    if basicModule.type(target) == "table" then
        target.renderLayer = value
        target.canvasComponent = canvas
    end
    return target
end

function UBUI.GetRenderLayer(target)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return nil end

    local ok, canvas = errorHandling.pcall(function()
        return obj.GetComponent(UBUI.CANVAS_COMP)
    end)

    if not ok or not UBUI.IsAlive(canvas) then return nil end

    local override = UBUI.GetField(
        canvas,
        "overrideSorting",
        false,
        "Canvas.GetRenderLayer",
        false
    )

    if not UBUI.Bool(override) then return nil end

    return UBUI.GetNum(canvas, "sortingOrder", nil)
end

function UBUI.HasRenderLayer(target)
    return UBUI.GetRenderLayer(target) ~= nil
end

function UBUI.ClearRenderLayer(target)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return target end
    local ok, canvas = errorHandling.pcall(function()
        return obj.GetComponent(UBUI.CANVAS_COMP)
    end)
    if not ok or not UBUI.IsAlive(canvas) then return target end
	UBUI.SetField(canvas, "overrideSorting", false, "Canvas.ClearRenderLayer", true)
    UBUI.SetField(canvas, "sortingOrder", 0, "Canvas.ClearRenderLayer", true)

    if basicModule.type(target) == "table" then
        target.renderLayer = nil
    end
    return target
end

function UBUI.BringToFront(target)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return target end
    UBUI._SafeCall("BringToFront", function()
        obj.Transform.SetAsLastSibling()
    end)
    return target
end

function UBUI.SendToBack(target)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return target end
    UBUI._SafeCall("SendToBack", function()
        obj.Transform.SetAsFirstSibling()
    end)
    return target
end

function UBUI.GetSiblingIndex(target)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return nil end
    local ok, index = errorHandling.pcall(function()
        return obj.Transform.GetSiblingIndex()
    end)
    if not ok then return nil end
    return UBUI.Num(index, nil)
end

function UBUI.SetSiblingIndex(target, index)
    local obj = unwrapObj(target)
    if not UBUI.IsAlive(obj) then return target end
    local value = UBUI.Num(index, 0)
    UBUI._SafeCall("SetSiblingIndex", function()
        obj.Transform.SetSiblingIndex(value)
    end)
    return target
end

local function rectVector2(value, y)
    local x = UBUI.Num(value, nil)

    if x ~= nil then
        return Vector2.New(
            x,
            UBUI.Num(y, 0)
        )
    end

    if value == nil then return nil end

    return Vector2.New(
        UBUI.Chan(value, "x", 1, 0),
        UBUI.Chan(value, "y", 2, 0)
    )
end

local function updateRectTarget(target, scope)
    if basicModule.type(target) ~= "table"
    or basicModule.type(target.UpdateBorders) ~= "function" then
        return target
    end

    UBUI._SafeCall(scope, function()
        target:UpdateBorders()
    end)

    return target
end

function UBUI.SetAnchor(target, x, y, maxX, maxY)
    local rect = UBUI.GetRect(target)

    if rect == nil then
        LogWarning("SetAnchor", "RectTransform not found")
        return target
    end

    local anchorMin
    local anchorMax

    if UBUI.Num(x, nil) ~= nil then
        anchorMin = rectVector2(x, y)
        anchorMax = anchorMin

        if maxX ~= nil or maxY ~= nil then
            anchorMax = Vector2.New(
                UBUI.Num(maxX, anchorMin.x),
                UBUI.Num(maxY, anchorMin.y)
            )
        end
    else
        anchorMin = rectVector2(x)
        anchorMax = rectVector2(y) or anchorMin
    end

    if anchorMin == nil then
        LogWarning("SetAnchor", "anchor is not valid")
        return target
    end

    UBUI.SetField(
        rect,
        "anchorMin",
        anchorMin,
        "SetAnchor.anchorMin",
        true
    )

    UBUI.SetField(
        rect,
        "anchorMax",
        anchorMax,
        "SetAnchor.anchorMax",
        true
    )

    return updateRectTarget(target, "SetAnchor.UpdateBorders")
end

function UBUI.SetPivot(target, x, y)
    local rect = UBUI.GetRect(target)

    if rect == nil then
        LogWarning("SetPivot", "RectTransform not found")
        return target
    end

    local pivot = rectVector2(x, y)

    if pivot == nil then
        LogWarning("SetPivot", "pivot is not valid")
        return target
    end

    UBUI.SetField(
        rect,
        "pivot",
        pivot,
        "SetPivot.pivot",
        true
    )

    return updateRectTarget(target, "SetPivot.UpdateBorders")
end

local function attachLayerAPI(class)
    if class == nil then return end
    function class:SetRenderLayer(order) return UBUI.SetRenderLayer(self, order) end
    function class:GetRenderLayer() return UBUI.GetRenderLayer(self) end
    function class:HasRenderLayer() return UBUI.HasRenderLayer(self) end
    function class:ClearRenderLayer() return UBUI.ClearRenderLayer(self) end
    function class:BringToFront() return UBUI.BringToFront(self) end
    function class:SendToBack() return UBUI.SendToBack(self) end
    function class:GetSiblingIndex() return UBUI.GetSiblingIndex(self) end
    function class:SetSiblingIndex(index) return UBUI.SetSiblingIndex(self, index) end
    function class:SetAnchor(x, y, maxX, maxY) return UBUI.SetAnchor(self, x, y, maxX, maxY) end
    function class:SetPivot(x, y) return UBUI.SetPivot(self, x, y) end
end

attachLayerAPI(UBUI.Element)
attachLayerAPI(UBUI.WindowClass)
attachLayerAPI(UBUI.ScrollViewClass)
attachLayerAPI(UBUI.AreaClass)

if UBUI.AreaClass ~= nil and UBUI.AreaClass.GetInstanceId == nil then
    function UBUI.AreaClass:GetInstanceId()
        if self.instanceId == nil then
            self.instanceId = UBUI.GetInstanceId(self.obj)
        end
        return self.instanceId
    end
end

return UBUI
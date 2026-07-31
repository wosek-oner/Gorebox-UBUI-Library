local S = {}

S.PREFABS = {
    label = "UI/Label",
    button = "UI/Button",
    toggle = "UI/Toggle",
    input = "UI/InputField",
    slider = "UI/Slider",
    colorPicker = "UI/Color PIcker",
}

S.Colors = {
    clear = Vector4.New(0, 0, 0, 0),
    white = Vector4.New(1.00, 1.00, 1.00, 1),
    black = Vector4.New(0.00, 0.00, 0.00, 1),
    gray = Vector4.New(0.50, 0.50, 0.50, 1),
    grey = Vector4.New(0.50, 0.50, 0.50, 1),
    red = Vector4.New(1.00, 0.15, 0.15, 1),
    green = Vector4.New(0.20, 0.90, 0.30, 1),
    blue = Vector4.New(0.25, 0.50, 1.00, 1),
    yellow = Vector4.New(1.00, 0.90, 0.20, 1),
    orange = Vector4.New(1.00, 0.55, 0.10, 1),
    cyan = Vector4.New(0.20, 0.95, 0.95, 1),
    magenta = Vector4.New(1.00, 0.20, 0.90, 1),
    purple = Vector4.New(0.60, 0.30, 1.00, 1),
    pink = Vector4.New(1.00, 0.55, 0.75, 1),
}

S.SIZES = {
    text = 30,
    button = 46,
    toggle = 30,
    input = 40,
    image = 24,
    slider = 30,
    sliderHandle = 18,
    sliderTrack = 10,
    pickerButton = 26,
}

S.ALIGN = {
    UpperLeft = { 257, 0 },
    UpperCenter = { 258, 1 },
    UpperRight = { 260, 2 },
    MiddleLeft = { 513, 3 },
    MiddleCenter = { 514, 4 },
    MiddleRight = { 516, 5 },
    LowerLeft = { 1025, 6 },
    LowerCenter = { 1026, 7 },
    LowerRight = { 1028, 8 },
}

local missingThemeKeys = {}
local notifying = false

local function LogStyleFailure(scope, err)
    Debug.Log(
        "<color=#FF6B6B>[UBUI Styles Error]</color>: " ..
        basicModule.tostring(scope) .. ": " ..
        basicModule.tostring(err)
    )
end

local function LogWarning(scope, warning)
    local message =
        basicModule.tostring(scope) .. ": " ..
        basicModule.tostring(warning)

    Debug.Log(
        "<color=#F2B84B>[UBUI Styles Warning]</color>: " ..
        message
    )
end

local function LogError(err)
    LogStyleFailure("", err)
end

S.LogFailure = LogStyleFailure
S.LogWarning = LogWarning

function S._SafeCall(scope, fn, ...)
    if basicModule.type(fn) ~= "function" then
        LogStyleFailure(scope, "callback is not a function")
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
        LogStyleFailure(scope, err)
        return false, nil
    end

    return true, table.unpack(results, 1, results.n)
end

local function copyInto(dst, src)
    if basicModule.type(dst) ~= "table" then return nil end
    if basicModule.type(src) ~= "table" then return dst end

    for key, value in tableIterators.pairs(src) do
        dst[key] = value
    end

    return dst
end

local function clonePlain(value, seen)
    if basicModule.type(value) ~= "table" then
        return value
    end

    if metaTable.getmetatable(value) ~= nil then
        return value
    end

    seen = seen or {}

    if seen[value] ~= nil then
        return seen[value]
    end

    local result = {}
    seen[value] = result

    for key, item in tableIterators.pairs(value) do
        result[clonePlain(key, seen)] = clonePlain(item, seen)
    end

    return result
end

local function finiteNumber(value)
    local number = basicModule.tonumber(value)

    if basicModule.type(number) ~= "number" then
        return nil
    end

    if number ~= number or number - number ~= 0 then
        return nil
    end

    return number
end

local function clear(target)
    if basicModule.type(target) ~= "table" then return end

    local keys = {}

    for key in tableIterators.pairs(target) do
        table.insert(keys, key)
    end

    for index = 1, #keys do
        target[keys[index]] = nil
    end
end

local function logResolutionError(id, message)
    if missingThemeKeys[id] == true then return end

    missingThemeKeys[id] = true
    LogWarning("Theme.Resolve", message)
end

local function resolve(value, seen)
    if basicModule.type(value) ~= "string" then
        return value
    end

    if string.sub(value, 1, 1) ~= "@" then
        return value
    end

    local key = string.sub(value, 2)

    if key == "" then
        logResolutionError(
            "empty",
            "empty theme reference"
        )
        return nil
    end

    seen = seen or {}

    if seen[key] == true then
        logResolutionError(
            "cycle:" .. key,
            "cyclic theme reference @" .. key
        )
        return nil
    end

    local resolved = S.Theme[key]

    if resolved == nil then
        logResolutionError(
            "missing:" .. key,
            "missing theme key @" .. key
        )
        return nil
    end

    seen[key] = true
    local result = resolve(resolved, seen)
    seen[key] = nil

    return result
end

local function notifyThemeChanged()
    if notifying then return end

    local hasPublic =
        basicModule.type(S.OnChange) == "function"

    local hasInternal =
        basicModule.type(S._UBUIOnChange) == "function"

    if not hasPublic and not hasInternal then
        return
    end

    notifying = true

    if hasPublic then
        S._SafeCall(
            "Theme.OnChange",
            S.OnChange,
            S.Theme
        )
    end

    if hasInternal then
        S._SafeCall(
            "Theme.UBUIOnChange",
            S._UBUIOnChange,
            S.Theme
        )
    end

    notifying = false
end

S.Resolve = resolve

S.Theme = {}
S.Themes = {}
S.ThemeName = nil
S.OnChange = nil
S._UBUIOnChange = nil

S.Themes.dark = {
    root = Vector4.New(0.00, 0.00, 0.00, 0.90),
    header = Vector4.New(0.00, 0.00, 0.00, 0.87),
    border = Vector4.New(0.30, 0.30, 0.30, 1.00),
    text = Vector4.New(1.00, 1.00, 1.00, 1.00),
    button = Vector4.New(0.16, 0.17, 0.22, 1.00),
    buttonText = Vector4.New(1.00, 1.00, 1.00, 1.00),
    close = Vector4.New(0.55, 0.12, 0.12, 1.00),
    outline = Vector4.New(1.00, 0.85, 0.25, 1.00),
    shadow = Vector4.New(0.00, 0.00, 0.00, 1.00),
    sliderBg = Vector4.New(0.20, 0.22, 0.28, 1.00),
    sliderFill = Vector4.New(0.35, 0.75, 1.00, 1.00),
    sliderHandle = Vector4.New(1.00, 1.00, 1.00, 1.00),
    borderThickness = 5,
    outlineDistance = 2,
    shadowX = 2,
    shadowY = -2,
    shadowAlpha = 0.5,
    closeInset = 12,
    padding = 14,
    spacing = 8,
    fontSize = 24,
    titleSize = 28,
    pickerBg = Vector4.New(0.086, 0.102, 0.133, 1.00),
    pickerApply = Vector4.New(0.243, 0.545, 0.353, 1.00),
    pickerClose = Vector4.New(0.545, 0.243, 0.267, 1.00),
    pickerLabel = "@button",
    pickerLabelText = "@buttonText",
    pickerHue = 0.195,
    scrollBg = Vector4.New(0.00, 0.00, 0.00, 0.00),
    scrollTrack = Vector4.New(0.20, 0.22, 0.28, 1.00),
    scrollHandle = Vector4.New(0.36, 0.40, 0.50, 1.00),
    scrollHeader = Vector4.New(0.00, 0.00, 0.00, 0.87),
    scrollBorder = Vector4.New(0.30, 0.30, 0.30, 1.00),
    texture = Vector4.New(1.00, 1.00, 1.00, 1.00),
}

function S.DefineTheme(name, def, baseName)
    if basicModule.type(name) ~= "string" or name == "" then
        LogStyleFailure("DefineTheme", "invalid name")
        return nil
    end

    if def ~= nil and basicModule.type(def) ~= "table" then
        LogStyleFailure("DefineTheme", "definition must be a table")
        return nil
    end

    local parentName = baseName or "dark"
    local base = S.Themes[parentName]

    if base == nil then
        LogStyleFailure(
            "DefineTheme",
            "unknown base " .. basicModule.tostring(parentName)
        )
        return nil
    end

    local theme = clonePlain(base)
    copyInto(theme, clonePlain(def))

    S.Themes[name] = theme
    return theme
end

function S.SetTheme(name)
    if basicModule.type(name) ~= "string" or name == "" then
        LogStyleFailure("SetTheme", "invalid name")
        return S.Theme
    end

    local theme = S.Themes[name]

    if theme == nil then
        LogError("unknown theme " .. name)
        return S.Theme
    end

    local activeTheme = clonePlain(theme)

    clear(S.Theme)
    copyInto(S.Theme, activeTheme)
    clear(missingThemeKeys)

    S.ThemeName = name

    notifyThemeChanged()
    return S.Theme
end

function S.SetThemeValue(key, value)
    if basicModule.type(key) ~= "string" or key == "" then
        LogStyleFailure("SetThemeValue", "invalid key")
        return nil
    end

    S.Theme[key] = clonePlain(value)
    clear(missingThemeKeys)

    notifyThemeChanged()
    return S.Theme
end

function S.GetThemeValue(key)
    return S.Theme[key]
end

function S.GetThemeSnapshot()
    return clonePlain(S.Theme)
end

S.DefineTheme("light", {
    root = Vector4.New(0.94, 0.94, 0.96, 0.96),
    header = Vector4.New(0.86, 0.87, 0.91, 1.00),
    border = Vector4.New(0.62, 0.63, 0.68, 1.00),
    text = Vector4.New(0.08, 0.08, 0.10, 1.00),
    button = Vector4.New(0.88, 0.89, 0.93, 1.00),
    buttonText = Vector4.New(0.08, 0.08, 0.10, 1.00),
    close = Vector4.New(0.85, 0.30, 0.30, 1.00),
    outline = Vector4.New(0.95, 0.60, 0.10, 1.00),
    shadow = Vector4.New(0.10, 0.10, 0.12, 1.00),
    sliderBg = Vector4.New(0.74, 0.75, 0.80, 1.00),
    sliderFill = Vector4.New(0.20, 0.45, 0.90, 1.00),
    sliderHandle = Vector4.New(0.15, 0.15, 0.18, 1.00),
    pickerBg = Vector4.New(1.0000, 1.0000, 1.0000, 0.1137),
    pickerApply = Vector4.New(0.3473, 0.6953, 0.4740, 1.0000),
    pickerClose = Vector4.New(0.7149, 0.1997, 0.2407, 1.0000),
    pickerLabel = Vector4.New(0.8332, 0.8332, 0.8332, 0.8700),
    pickerLabelText = Vector4.New(0.0000, 0.0000, 0.0000, 1.0000),
    scrollTrack = Vector4.New(0.74, 0.75, 0.80, 1.00),
    scrollHandle = Vector4.New(0.52, 0.55, 0.62, 1.00),
    scrollHeader = Vector4.New(0.86, 0.87, 0.91, 1.00),
    scrollBorder = Vector4.New(0.62, 0.63, 0.68, 1.00),
    texture = Vector4.New(1.00, 1.00, 1.00, 1.00),
}, "dark")

S.SetTheme("dark")

S.FIELD_MAP = {
    background = "color",
    textColor = "textColor",
    fontSize = "fontSize",
    alignment = "align",
    wordWrap = "wordWrap",
    fixedWidth = "w",
    fixedHeight = "h",
    stretchWidth = "stretchWidth",
    stretchHeight = "stretchHeight",
    padding = "padding",
    spacing = "spacing",
    margin = "indent",
    raycast = "raycast",
    clipping = "clipping",
    fillColor = "fillColor",
    bgColor = "bgColor",
    handleColor = "handleColor",
    handleWidth = "handleWidth",
    handle = "handle",
    wholeNumbers = "wholeNumbers",
    characterLimit = "characterLimit",
    handleHeight = "handleHeight",
    trackHeight = "trackHeight",
    applyColor = "applyColor",
    closeColor = "closeColor",
    gbColors = "gbColors",
    hueThickness = "hueThickness",
    code = "code",
    pickerScale = "scale",
    labelText = "labelText",
    labelColor = "labelColor",
    labelTextColor = "labelTextColor",
    imageType = "imageType",
    fillMethod = "fillMethod",
    fillAmount = "fillAmount",
    fillClockwise = "fillClockwise",
    fillOrigin = "fillOrigin",
    preserveAspect = "preserveAspect",
}

S.OPTS_MAP = {}

for field, key in tableIterators.pairs(S.FIELD_MAP) do
    S.OPTS_MAP[key] = field
end

function S.StyleFromOpts(opts)
    local def = {}

    if basicModule.type(opts) ~= "table" then
        return def
    end

    for key, value in tableIterators.pairs(opts) do
        local field = S.OPTS_MAP[key]

        if field ~= nil then
            def[field] = clonePlain(value)
        end
    end

    return def
end

local Style = {}
Style.__index = Style

S.StyleClass = Style
S.Styles = {}

local function validDefinition(def)
    return def == nil or basicModule.type(def) == "table"
end

function S.NewStyle(def)
    if not validDefinition(def) then
        LogStyleFailure("NewStyle", "definition must be a table")
        def = nil
    end

    local style = {
        def = clonePlain(def) or {},
    }

    return metaTable.setmetatable(style, Style)
end

function S.IsStyle(value)
    if basicModule.type(value) ~= "table" then
        return false
    end

    return metaTable.getmetatable(value) == Style
end

function S.Coerce(value)
    if value == nil then
        return nil
    end

    if S.IsStyle(value) then
        return value
    end

    local valueType = basicModule.type(value)

    if valueType == "string" then
        local style = S.Styles[value]

        if style == nil then
            LogError("unknown style " .. value)
        end

        return style
    end

    if valueType == "table" then
        return S.NewStyle(value)
    end

    LogStyleFailure(
        "Coerce",
        "unsupported type " .. basicModule.tostring(valueType)
    )

    return nil
end

function Style:Raw(field)
    if field == nil then
        return self.def
    end

    return self.def[field]
end

function Style:Get(field)
    return resolve(self.def[field])
end

function Style:Set(field, value)
    if basicModule.type(field) ~= "string" or field == "" then
        LogStyleFailure("Style.Set", "invalid field")
        return self
    end

    self.def[field] = clonePlain(value)
    return self
end

function Style:SetAll(def)
    if not validDefinition(def) then
        LogStyleFailure("Style.SetAll", "definition must be a table")
        return self
    end

    copyInto(self.def, clonePlain(def))
    return self
end

function Style:Copy()
    return S.NewStyle(self.def)
end

function Style:Extend(def)
    return self:Copy():SetAll(def)
end

function Style:Snapshot()
    return clonePlain(self.def)
end

function Style:ToOpts(opts)
    if opts ~= nil and basicModule.type(opts) ~= "table" then
        LogStyleFailure("Style.ToOpts", "options must be a table")
        opts = nil
    end

    local out = {}

    for field, key in tableIterators.pairs(S.FIELD_MAP) do
        local value = self.def[field]

        if value ~= nil then
            local resolved = resolve(value)

            if resolved ~= nil then
                out[key] = resolved
            end
        end
    end

    if opts == nil then
        return out
    end

    local extra = S.Coerce(opts.style)

    if extra ~= nil then
        copyInto(out, extra:ToOpts(nil))
    end

    for key, value in tableIterators.pairs(opts) do
        if key ~= "style" then
            out[key] = value
        end
    end

    return out
end

local OPTIONAL_METHODS = {
    Relayout = true,
    --UpdateBorders = true,
    --Restyle = true,
}

local function invoke(target, method, ...)
    if target == nil then
        LogWarning(
            "Style.Apply." .. basicModule.tostring(method),
            "target is nil"
        )

        return false
    end

    local lookupOk, fn = S._SafeCall(
        "Style.MethodLookup." .. basicModule.tostring(method),
        function()
            return target[method]
        end
    )

    if not lookupOk then return false end

    if basicModule.type(fn) ~= "function" then
        if OPTIONAL_METHODS[method] ~= true then
            LogWarning(
                "Style.Apply." .. basicModule.tostring(method),
                "target method is not available"
            )
        end

        return false
    end

    local args = table.pack(...)

    local ok = S._SafeCall(
        "Style.Apply." .. basicModule.tostring(method),
        function()
            return fn(
                target,
                table.unpack(args, 1, args.n)
            )
        end
    )

    return ok
end

local function resolveNumber(scope, value)
    local number = finiteNumber(resolve(value))

    if number == nil then
        LogWarning(
            scope,
            "invalid value"
        )
    end

    return number
end

function Style:Apply(target)
    if target == nil then
        return target
    end

    local def = self.def
    local changed = false
    local isPicker = target.kind == "colorpicker"

    local background = resolve(def.background)

    if background ~= nil then
        changed = invoke(target, "SetColor", background) or changed
    end

    local textColor = resolve(def.textColor)

    if textColor ~= nil then
        changed = invoke(target, "SetTextColor", textColor) or changed
    end

    if def.fontSize ~= nil then
        local fontSize = resolveNumber(
            "Style.Apply.fontSize",
            def.fontSize
        )

        if fontSize ~= nil then
            changed = invoke(target, "SetFontSize", fontSize) or changed
        end
    end

    local alignment = resolve(def.alignment)

    if alignment ~= nil then
        changed = invoke(target, "SetAlign", alignment) or changed
    end

    local wordWrap = resolve(def.wordWrap)

    if wordWrap ~= nil then
        changed = invoke(target, "SetWordWrap", wordWrap) or changed
    end

    if def.clipping ~= nil then
        local clipping = resolve(def.clipping)

        if basicModule.type(clipping) == "boolean" then
            changed = invoke(target, "SetClipping", clipping) or changed
        elseif clipping ~= nil then
            LogStyleFailure(
                "Style.Apply.clipping",
                "value must be a boolean"
            )
        end
    end

    if (def.fixedWidth ~= nil or def.fixedHeight ~= nil) and not isPicker then
        local width = nil
        local height = nil
        local valid = true

        if def.fixedWidth ~= nil then
            width = resolveNumber("Style.Apply.fixedWidth", def.fixedWidth)
            valid = width ~= nil
        end

        if def.fixedHeight ~= nil then
            height = resolveNumber("Style.Apply.fixedHeight", def.fixedHeight)
            valid = height ~= nil and valid
        end

        if target.item ~= nil then
            if width == nil and def.fixedWidth == nil then
                width = target.item.w
            end

            if height == nil and def.fixedHeight == nil then
                height = target.item.h
            end
        end

        if valid and width ~= nil and height ~= nil then
            changed = invoke(target, "SetSize", width, height) or changed
        end
    end

    if target.kind == "slider" then
        local fillColor = resolve(def.fillColor)
        local bgColor = resolve(def.bgColor)

        if fillColor ~= nil or bgColor ~= nil then
            changed = invoke(target, "SetSliderColors", fillColor, bgColor) or changed
        end

        local handleColor = resolve(def.handleColor)

        if handleColor ~= nil then
            changed = invoke(target, "SetHandleColor", handleColor) or changed
        end

        if def.handleWidth ~= nil then
            local handleWidth = resolveNumber("Style.Apply.handleWidth", def.handleWidth)

            if handleWidth ~= nil then
                changed = invoke(target, "SetHandleWidth", handleWidth) or changed
            end
        end
    end

    if isPicker then
    	if def.fixedWidth ~= nil and def.fixedHeight ~= nil then
            local width = resolveNumber("Style.Apply.pickerWidth", def.fixedWidth)
            local height = resolveNumber("Style.Apply.pickerHeight", def.fixedHeight)

            if width ~= nil and height ~= nil then
                changed = invoke(target, "SetPickerSize", width, height) or changed
            end
        end

        local bgColor = resolve(def.bgColor)

        if bgColor ~= nil then
            changed = invoke(target, "SetPickerBgColor", bgColor) or changed
        end

        local applyColor = resolve(def.applyColor)

        if applyColor ~= nil then
            changed = invoke(target, "SetApplyColor", applyColor) or changed
        end

        local closeColor = resolve(def.closeColor)

        if closeColor ~= nil then
            changed = invoke(target, "SetCloseColor", closeColor) or changed
        end

        local gbColors = resolve(def.gbColors)

        if gbColors ~= nil then
            changed = invoke(target, "SetGBColors", gbColors) or changed
        end

        if def.hueThickness ~= nil then
            local hueThickness = resolveNumber("Style.Apply.hueThickness", def.hueThickness)

            if hueThickness ~= nil then
                changed = invoke(target, "SetHueThickness", hueThickness) or changed
            end
        end

        if def.pickerScale ~= nil then
            local pickerScale = resolveNumber("Style.Apply.pickerScale", def.pickerScale)

            if pickerScale ~= nil then
                changed = invoke(target, "SetPickerScale", pickerScale) or changed
            end
        end

        if def.code ~= nil then
            local code = resolve(def.code)

            if basicModule.type(code) == "boolean" then
                changed = invoke(target, "SetCodeVisible", code) or changed
            elseif code ~= nil then
                LogStyleFailure("Style.Apply.code", "value must be a boolean")
            end
        end

        local labelColor = resolve(def.labelColor)

        if labelColor ~= nil then
            changed = invoke(target, "SetLabelColor", labelColor) or changed
        end

        local labelTextColor = resolve(def.labelTextColor)

        if labelTextColor ~= nil then
            changed = invoke(target, "SetLabelTextColor", labelTextColor) or changed
        end

        local labelText = resolve(def.labelText)

        if labelText ~= nil then
            changed = invoke(target, "SetLabelText", labelText) or changed
        end
    end

    if def.padding ~= nil and target.padLeft ~= nil then
        local padding = resolveNumber(
            "Style.Apply.padding",
            def.padding
        )

        if padding ~= nil then
            target.padLeft = padding
            target.padRight = padding
            target.padTop = padding
            target.padBottom = padding
            changed = true
        end
    end

    if def.spacing ~= nil and target.spacing ~= nil then
        local spacing = resolveNumber("Style.Apply.spacing", def.spacing)

        if spacing ~= nil then
            target.spacing = spacing
            changed = true
        end
    end

    if changed then
        invoke(target, "Relayout")
    end

    return target
end

function S.DefineStyle(name, def, baseName)
    if basicModule.type(name) ~= "string" or name == "" then
        LogStyleFailure("DefineStyle", "invalid name")
        return nil
    end

    if not validDefinition(def) then
        LogStyleFailure("DefineStyle", "definition must be a table")
        return nil
    end

    local base = nil

    if baseName ~= nil then
        base = S.Styles[baseName]

        if base == nil then
            LogStyleFailure(
                "DefineStyle",
                "unknown base " .. basicModule.tostring(baseName)
            )
            return nil
        end
    end

    local style

    if base ~= nil then
        style = base:Extend(def)
    else
        style = S.NewStyle(def)
    end

    local previous = S.Styles[name]
    S.Styles[name] = style

    if previous ~= nil then
        notifyThemeChanged()
    end

    return style
end

function S.GetStyle(name)
    return S.Styles[name]
end

function S.SetStyleValue(name, field, value)
    local style = S.Styles[name]

    if style == nil then
        LogError(
            "unknown style " ..
            basicModule.tostring(name)
        )
        return nil
    end

    if basicModule.type(field) ~= "string" or field == "" then
        LogStyleFailure("SetStyleValue", "invalid field")
        return nil
    end

    style:Set(field, value)
    notifyThemeChanged()

    return style
end

function S.ApplyStyle(target, style)
    local resolved = S.Coerce(style)

    if resolved == nil then
        return target
    end

    return resolved:Apply(target)
end

function S.Merge(styleOrName, opts)
    if opts ~= nil and basicModule.type(opts) ~= "table" then
        LogStyleFailure("Merge", "options must be a table")
        opts = nil
    end

    local style = S.Coerce(styleOrName)

    if style ~= nil then
        return style:ToOpts(opts)
    end

    if opts == nil then
        return {}
    end

    local out = {}
    local extra = S.Coerce(opts.style)

    if extra ~= nil then
        copyInto(out, extra:ToOpts(nil))
    end

    for key, value in tableIterators.pairs(opts) do
        if key ~= "style" then
            out[key] = value
        end
    end

    return out
end

S.DefineStyle("image", {
    background = "@texture",
    raycast = false,
    stretchWidth = true,
})

S.DefineStyle("text", {
    textColor = "@text",
    alignment = "MiddleLeft",
    stretchWidth = true,
})

S.DefineStyle("label", {}, "text")

S.DefineStyle("button", {
    background = "@button",
    textColor = "@buttonText",
    stretchWidth = true,
})

S.DefineStyle("toggle", {
    textColor = "@text",
    stretchWidth = true,
})

S.DefineStyle("input", {
    stretchWidth = true,
})

S.DefineStyle("slider", {
    fillColor = "@sliderFill",
    bgColor = "@sliderBg",
    handleColor = "@sliderHandle",
    stretchWidth = true,
})

S.DefineStyle("colorpicker", {
    pickerScale = 1,
    bgColor = "@pickerBg",
    applyColor = "@pickerApply",
    closeColor = "@pickerClose",
    labelColor = "@pickerLabel",
    labelTextColor = "@pickerLabelText",
    hueThickness = "@pickerHue",
})

S.DefineStyle("area", {
    padding = "@padding",
    spacing = "@spacing",
})

S.DefineStyle("title", {
    textColor = "@text",
    fontSize = "@titleSize",
    alignment = "MiddleLeft",
})

S.DefineStyle("close", {
    background = "@close",
    alignment = "MiddleCenter",
})

S.DefineStyle("scrollview", {
    padding = "@padding",
    spacing = "@spacing",
})

return S
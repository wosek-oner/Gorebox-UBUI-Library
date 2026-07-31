-- UBUI API
-- v1.0
-- Made By Wosek

-- Loads and activates a UBUI style module.
UBUI.LoadStyles(string path) returns table 

local Styles = UBUI.LoadStyles("ubuistyles.lua")


-- Activates an already loaded style module.
UBUI.UseStyles(table styles) returns table 

local Styles = UBUI.LoadStyles("ubuistyles.lua")
UBUI.UseStyles(Styles)


-- Returns true when a style module is active.
UBUI.HasStyles() returns boolean

if UBUI.HasStyles() then
    Debug.Log("UBUI styles are loaded!")
end


-- Merges a named style with widget options.
UBUI.StyleOpts(string styleName, table options) returns table

local options = UBUI.StyleOpts("button", {
    w = 220,
    h = 46,
})


-- Creates an independent Style.
UBUI.NewStyle(table definition) returns Style

local style = UBUI.NewStyle({
    background = UBUI.HexToColor("#596BFF"),
    textColor  = UBUI.Colors.white,
    fontSize   = 22,
})


-- Registers a named style.
UBUI.DefineStyle(string name, table definition, string  base) returns Style 

local style = UBUI.DefineStyle("accentButton", {
    background = "@button",
    textColor  = "@buttonText",
    fixedHeight = 48,
}, "button")


-- Returns a registered style.
UBUI.GetStyle(string name) returns Style 

local style = UBUI.GetStyle("accentButton")


-- Changes one field of a registered style.
UBUI.SetStyleValue(string name, string field, value) returns Style 

UBUI.SetStyleValue("accentButton", "fontSize", 24)


-- Applies a style to an existing UBUI object.
UBUI.ApplyStyle(Element or Area target, Style or string or table style) returns target

UBUI.ApplyStyle(button, "accentButton")


-- Registers a theme.
UBUI.DefineTheme(string name, table definition, string  base) returns table 

UBUI.DefineTheme("violet", {
    root   = UBUI.HexToColor("#11131A"),
    header = UBUI.HexToColor("#181C29"),
    border = UBUI.HexToColor("#8CA0FF"),
    text   = UBUI.HexToColor("#F4F6FF"),
}, "dark")


-- Activates a registered theme.
UBUI.SetTheme(string name) returns table

UBUI.SetTheme("violet")


-- Changes one value in the active theme.
UBUI.SetThemeValue(string key, value) returns table

UBUI.SetThemeValue("border", UBUI.HexToColor("#FF7AC6"))


-- Reapplies the saved style and creation options.
UBUI.Restyle(Element or Area or Window or ScrollView target) returns target

UBUI.Restyle(button)


-- Restyles all living UBUI windows.
UBUI.Refresh() returns UBUI

UBUI.Refresh()


-- Call in Update.
UBUI.UIUpdate()

function Update()
    UBUI.UIUpdate()
end


-- Destroys all UBUI elements and clears internal state.
UBUI.DestroyAll()

UBUI.DestroyAll()


-- Creates a Vector4 color using channels from 0 to 1.
UBUI.Color(number red, number green, number blue, number  alpha) returns Vector4

local color = UBUI.Color(0.2, 0.35, 1, 1)


-- Returns a color copy with another alpha value.
UBUI.WithAlpha(Vector4 color, number alpha) returns Vector4 

local transparent = UBUI.WithAlpha(color, 0.5)


-- Returns a darker color copy.
UBUI.Darken(Vector4 color, number  factor, number  floorValue) returns Vector4 

local darker = UBUI.Darken(color, 0.5, 0.04)


-- Converts one hexadecimal character into a number.
UBUI.HexDigit(string character) returns number 

local value = UBUI.HexDigit("F")


-- Converts #RRGGBB or #RRGGBBAA into Vector4.
UBUI.HexToColor(string hex) returns Vector4 

local accent = UBUI.HexToColor("#8CA0FFFF")


-- Converts a hex color into Vector4 and optionally overrides alpha.
UBUI.HexToVector4(string hex, number  alpha) returns Vector4 

local accent = UBUI.HexToVector4("#8CA0FF", 0.8)


-- Converts RGB hex channels into Vector3.
UBUI.HexToVector3(string hex) returns Vector3 

local rgb = UBUI.HexToVector3("#8CA0FF")


-- Converts a color into #RRGGBB or #RRGGBBAA.
UBUI.ToHex(Vector4 color, boolean  withAlpha) returns string

local hex = UBUI.ToHex(accent, true)


-- Alias of UBUI.ToHex.
UBUI.ColorToHex(Vector4 color, boolean  withAlpha) returns string

local hex = UBUI.ColorToHex(accent, false)


-- Parses a named palette color or hexadecimal color.
UBUI.ParseColor(string value) returns Vector4 

local white  = UBUI.ParseColor("white")
local custom = UBUI.ParseColor("#8CA0FF")


-- Creates a random Vector4 color.
UBUI.RandomVector4(boolean or number  withAlpha) returns Vector4

local color = UBUI.RandomVector4(true)


-- Creates a random RGB Vector3.
UBUI.RandomVector3() returns Vector3

local color = UBUI.RandomVector3()


-- Creates a random #RRGGBB or #RRGGBBAA string.
UBUI.RandomHex(boolean or number  withAlpha) returns string

local hex = UBUI.RandomHex(true)


-- Selects a random color from UBUI.Colors.
UBUI.RandomPaletteColor(boolean or number  withAlpha) returns Vector4

local color = UBUI.RandomPaletteColor(false)


-- Registers a named Unity UI root.
UBUI.DefineSpace(string name, string path)

UBUI.DefineSpace("menu", "GameMaster/GameCanvas-3/MyMenu")


-- Resolves a GameObject path into LuaTransform.
UBUI.ResolvePath(string path) returns LuaTransform 

local transform = UBUI.ResolvePath("GameMaster/GameCanvas-3")


-- Returns a cached UI space.
UBUI.GetSpace(string  name) returns LuaTransform 

local parent = UBUI.GetSpace("base")


-- Clears cached UI space transforms.
UBUI.InvalidateSpaces()

UBUI.InvalidateSpaces()


-- Converts a value into a number or returns fallback.
UBUI.Num(value, number  fallback) returns number 

local width = UBUI.Num(rect.GetField("width"), 0)


-- Converts a value into a boolean.
UBUI.Bool(value) returns boolean

local state = UBUI.Bool("true")


-- Resolves an enum name or numeric value.
UBUI.EnumVal(table enum, string or number value, number fallback) returns number

local imageType = UBUI.EnumVal(UBUI.IMAGE_TYPE, "filled", 0)


-- Converts Vector2 channels into numbers.
UBUI.Vec2Num(Vector2 value) returns number , number 

local x, y = UBUI.Vec2Num(Input.GetScreenRect())


-- Reads and converts a numeric component field.
UBUI.GetNum(LuaComponent component, string field, number fallback) returns number

local fontSize = UBUI.GetNum(textComponent, "fontSize", 24)


-- Returns current screen dimensions.
UBUI.ScreenSize() returns number  width, number  height

local screenWidth, screenHeight = UBUI.ScreenSize()


-- Safely validates a Unity wrapper.
UBUI.IsAlive(object) returns boolean

if UBUI.IsAlive(window.obj) then
    window:Open()
end


-- Returns RectTransform from a GameObject or UBUI object.
UBUI.GetRect(LuaGameObject or Element or Area object) returns LuaComponent 

local rect = UBUI.GetRect(button)


-- Sets anchorMin and anchorMax of a target RectTransform.
-- Two numbers set one fixed anchor.
-- Four numbers set separate minimum and maximum anchors.
-- Vector2 and { x, y } values are also supported.
UBUI.SetAnchor(
    target,
    number or Vector2 or table x,
    number or Vector2 or table y,
    number maxX,
    number maxY
) returns target

UBUI.SetAnchor(button, 0.5, 0.5)
UBUI.SetAnchor(area, 0, 0, 1, 1)
UBUI.SetAnchor(
    window,
    Vector2.New(0.5, 0.5),
    Vector2.New(0.5, 0.5)
)

-- Sets the pivot of a target RectTransform.
-- Numbers, Vector2 and { x, y } values are supported.
UBUI.SetPivot(
    target,
    number or Vector2 or table x,
    number y
) returns target

UBUI.SetPivot(button, 0.5, 0.5)
UBUI.SetPivot(area, { x = 0, y = 1 })


-- Positions an object from the parents upper-left corner.
UBUI.SetTopRect(object, number x, number y, number width, number height)

UBUI.SetTopRect(button.obj, 20, 20, 180, 44)


-- Positions an object relative to the parents center.
UBUI.SetCenterRect(object, number x, number y, number width, number height)

UBUI.SetCenterRect(button.obj, 0, 0, 180, 44)


-- Returns an objects upper-left layout rectangle.
UBUI.GetTopRect(object) returns number x, number y, number width, number height

local x, y, width, height = UBUI.GetTopRect(button)


-- Stretches a RectTransform across its parent.
UBUI.StretchRect(LuaComponent rect, number  widthDelta, number  heightDelta)

UBUI.StretchRect(UBUI.GetRect(button), -16, -16)


-- Stretches a RectTransform horizontally.
UBUI.StretchRectH(LuaComponent rect, number  widthDelta, number  height)

UBUI.StretchRectH(UBUI.GetRect(button), -16, 44)


-- Stretches horizontally while keeping a left pivot.
UBUI.LeftStretchRectH(LuaComponent rect, number  widthDelta, number  height)

UBUI.LeftStretchRectH(UBUI.GetRect(button), 16, 44)


-- Returns the parent RectTransform of a component.
UBUI.ParentRectOf(LuaComponent component) returns LuaComponent 

local parentRect = UBUI.ParentRectOf(imageComponent)


-- Returns the RectTransform of a component.
UBUI.RectOf(LuaComponent component) returns LuaComponent 

local rect = UBUI.RectOf(imageComponent)


-- Finds a TMP or Unity UI text component.
UBUI.GetTextComp(LuaGameObject object) returns LuaComponent 

local textComponent = UBUI.GetTextComp(button.obj)


-- Finds a TMP or Unity UI input component.
UBUI.GetInputComp(LuaGameObject object) returns LuaComponent 

local inputComponent = UBUI.GetInputComp(input.obj)


-- Finds a component on an object or its children.
UBUI.GetComp(LuaGameObject object, string componentName) returns LuaComponent 

local sliderComponent = UBUI.GetComp(
    slider.obj,
    "UnityEngine.UI.Slider"
)


-- Finds an Image component on an object or its children.
UBUI.GetImageComp(LuaGameObject object) returns LuaComponent 

local imageComponent = UBUI.GetImageComp(image.obj)


-- Returns and caches an element's Image component.
UBUI.ImgComp(Element element) returns LuaComponent 

local imageComponent = UBUI.ImgComp(image)


-- Changes the raycastTarget state of an Image.
UBUI.SetRaycast(LuaGameObject object, boolean state)

UBUI.SetRaycast(button.obj, true)


-- Disables raycasts on child text components.
UBUI.DisableChildTextRaycast(LuaGameObject object)

UBUI.DisableChildTextRaycast(button.obj)


-- Creates a Unity UI Image object.
UBUI.NewImageObject(
    LuaTransform parent,
    string name,
    number x,
    number y,
    number width,
    number height,
    Vector4 color,
    boolean raycast
) returns LuaGameObject 

local object = UBUI.NewImageObject(
    UBUI.GetSpace("base"),
    "Background",
    20,
    20,
    320,
    180,
    UBUI.HexToColor("#11131A"),
    true
)


-- Copies a prefab into a UI parent.
UBUI.CopyPrefab(
    string path,
    LuaTransform parent,
    string name,
    number x,
    number y,
    number width,
    number height
) returns LuaGameObject 

local object = UBUI.CopyPrefab(
    "UI/Label",
    UBUI.GetSpace("base"),
    "CustomLabel",
    20,
    20,
    240,
    44
)


-- Returns a prefab's default RectTransform size.
UBUI.PrefabRectSize(string path) returns number  width, number  height

local width, height = UBUI.PrefabRectSize("UI/Label")


-- Returns an element's layout slot size.
UBUI.SlotRect(Element element, number width, number height) returns number, number

local slotWidth, slotHeight = UBUI.SlotRect(picker, 320, 360)


-- Creates a unique UBUI object name.
UBUI.NextName(string prefix) returns string

local name = UBUI.NextName("Button")


-- Reads a vector or color channel.
UBUI.Chan(value, string firstKey, string secondKey, number fallback) returns number

local red = UBUI.Chan(color, "x", "r", 0)


-- Converts a wrapped color into Vector4.
UBUI.ToColor(value) returns Vector4 

local color = UBUI.ToColor(component.GetField("color"))


-- Reads and converts a component color.
UBUI.CompColor(LuaComponent component) returns Vector4 

local color = UBUI.CompColor(imageComponent)


-- Finds an exact child Transform path.
UBUI.FindChildObject(root, string path) returns LuaGameObject 

local labelObject = UBUI.FindChildObject(
    picker,
    "ColorPicker/Buttons (1)"
)


-- Adds a replaceable onClick listener.
UBUI.HookClick(LuaComponent component, table holder, string key) returns boolean

UBUI.HookClick(buttonComponent, controller, "onClick")


-- Checks whether clipping is enabled.
UBUI.HasClipping(target) returns boolean

local clipped = UBUI.HasClipping(area)


-- Enables or disables clipping.
UBUI.SetClipping(target, boolean or number or string state) returns target

UBUI.SetClipping(area, true)


-- Adds a four-piece border.
UBUI.Border(target, table  options) returns Border 

options:
    string mode
    number thickness
    Vector4 color
    number gap
    string name

local border = UBUI.Border(button, {
    mode      = "around",
    thickness = 2,
    gap       = 3,
    color     = UBUI.HexToColor("#8CA0FF"),
})


-- Checks whether a border target exists.
Border:IsAlive() returns boolean

local alive = border:IsAlive()


-- Recalculates border positions.
Border:Update() returns Border

border:Update()


-- Changes border color.
Border:SetColor(Vector4 color) returns Border

border:SetColor(UBUI.Colors.white)


-- Changes border thickness.
Border:SetThickness(number thickness) returns Border

border:SetThickness(3)


-- Changes the border gap.
Border:SetGap(number gap) returns Border

border:SetGap(4)


-- Changes border visibility.
Border:SetVisible(boolean state) returns Border

border:SetVisible(true)


-- Shows a border.
Border:Show() returns Border

border:Show()


-- Hides a border.
Border:Hide() returns Border

border:Hide()


-- Destroys all border pieces.
Border:Destroy()

border:Destroy()


-- Adds or updates UnityEngine.UI.Outline.
UBUI.Outline(target, table  options) returns LuaComponent 

options:
    Vector4 color
    number distance
    number x
    number y
    boolean useGraphicAlpha

local outline = UBUI.Outline(button, {
    color           = UBUI.HexToColor("#000000CC"),
    distance        = 2,
    useGraphicAlpha = true,
})


-- Adds or updates UnityEngine.UI.Shadow.
UBUI.Shadow(target, table  options) returns LuaComponent 

options:
    Vector4 color
    number alpha
    number x
    number y
    boolean useGraphicAlpha

local shadow = UBUI.Shadow(button, {
    alpha = 0.55,
    x     = 3,
    y     = -3,
})


-- Checks whether a target contains a component effect.
UBUI.HasEffect(target, string componentName) returns boolean

local present = UBUI.HasEffect(
    button,
    "UnityEngine.UI.Outline"
)


-- Checks whether a target has an outline.
UBUI.HasOutline(target) returns boolean

local outlined = UBUI.HasOutline(button)


-- Checks whether a target has a real shadow.
UBUI.HasShadow(target) returns boolean

local shadowed = UBUI.HasShadow(button)


-- Enables or disables an existing visual effect.
UBUI.SetEffectEnabled(target, string kind, boolean state)

UBUI.SetEffectEnabled(button, "outline", false)


-- Enables or disables an existing outline.
UBUI.SetOutlineEnabled(target, boolean state)

UBUI.SetOutlineEnabled(button, true)


-- Enables or disables an existing shadow.
UBUI.SetShadowEnabled(target, boolean state)

UBUI.SetShadowEnabled(button, false)


-- Creates an Element wrapper.
UBUI.NewElement(LuaGameObject object, string kind, LuaComponent  component) returns Element

local element = UBUI.NewElement(object, "button", buttonComponent)


-- Returns a color picker's native component.
UBUI.PickerComp(Element element) returns LuaComponent 

local component = UBUI.PickerComp(picker)


-- Registers or updates a widget watcher.
UBUI.AddWatcher(Element element, string kind, initialValue) returns table 

local watcher = UBUI.AddWatcher(toggle, "toggle", false)


-- Checks whether an element exists.
Element:IsAlive() returns boolean

local alive = button:IsAlive()


-- Checks whether an element is visible.
Element:IsVisible() returns boolean

local visible = button:IsVisible()


-- Changes element text.
Element:SetText(string text) returns Element

button:SetText("<b>Updated</b>")


-- Returns element text.
Element:GetText() returns string

local text = button:GetText()


-- Changes text color.
Element:SetTextColor(Vector4 color) returns Element

button:SetTextColor(UBUI.Colors.white)


-- Changes font size.
Element:SetFontSize(number size) returns Element

button:SetFontSize(22)


-- Enables or disables automatic text sizing.
Element:SetTextAutoSize(
    boolean state,
    number  minimum,
    number  maximum
) returns Element

button:SetTextAutoSize(true, 12, 24)


-- Changes text padding.
Element:SetTextPadding(number horizontal, number  vertical) returns Element

button:SetTextPadding(12, 6)


-- Changes text alignment.
Element:SetAlign(string alignment) returns Element

button:SetAlign("MiddleCenter")


-- Enables or disables word wrapping.
Element:SetWordWrap(boolean state) returns Element

button:SetWordWrap(false)


-- Changes the Image color.
Element:SetColor(Vector4 color) returns Element

button:SetColor(UBUI.HexToColor("#596BFF"))


-- Assigns a texture and converts it into a sprite.
Element:SetTexture(LuaTexture texture) returns Element

image:SetTexture(Importer.ImportTexture("resources/icon.png"))


-- Changes the Unity Image type.
Element:SetImageType(string or number imageType) returns Element

image:SetImageType("filled")


-- Changes the Image fill method.
Element:SetFillMethod(string or number fillMethod) returns Element

image:SetFillMethod("radial360")


-- Changes the Image fill origin.
Element:SetFillOrigin(number origin) returns Element

image:SetFillOrigin(0)


-- Changes clockwise fill behavior.
Element:SetFillClockwise(boolean state) returns Element

image:SetFillClockwise(true)


-- Changes Image fill amount from 0 to 1.
Element:SetFillAmount(number amount) returns Element

image:SetFillAmount(0.75)


-- Enables or disables preserved aspect ratio.
Element:SetPreserveAspect(boolean state) returns Element

image:SetPreserveAspect(true)


-- Changes an element rectangle.
Element:SetRect(
    number x,
    number y,
    number width,
    number height
) returns Element

button:SetRect(20, 20, 180, 44)


-- Changes element size.
Element:SetSize(number width, number height) returns Element

button:SetSize(220, 48)


-- Sets absolute local Z rotation in degrees.
Element:Rotate(number degrees) returns Element

button:Rotate(15)


-- Sets anchorMin and anchorMax of an Element.
-- Two numbers set one fixed anchor; four numbers set an anchor range.
Element:SetAnchor(
    number or Vector2 or table x,
    number or Vector2 or table y,
    number maxX,
    number maxY
) returns Element

button:SetAnchor(0.5, 0.5)
image:SetAnchor(0, 0, 1, 1)

-- Sets the pivot of an Element.
Element:SetPivot(
    number or Vector2 or table x,
    number y
) returns Element

button:SetPivot(0.5, 0.5)


-- Changes element visibility.
Element:SetVisible(boolean state) returns Element

button:SetVisible(true)


-- Shows an element.
Element:Show() returns Element

button:Show()


-- Hides an element.
Element:Hide() returns Element

button:Hide()


-- Changes element interaction state.
Element:SetInteractable(boolean state) returns Element

button:SetInteractable(false)


-- Replaces a button click callback.
-- The callback receives the Element.
Element:SetOnClick(function callback) returns Element

button:SetOnClick(function(element)
    Debug.Log("Button clicked")
end)

-- Replaces a value-change callback.
-- The callback receives the current value and Element.
Element:SetOnChange(function callback) returns Element

slider:SetOnChange(function(value, element)
    Debug.Log(basicModule.tostring(value))
end)


-- Returns a widget value.
Element:GetValue() returns boolean or number or string 

local value = slider:GetValue()


-- Changes a widget value without invoking onChange.
Element:SetValue(value) returns Element

slider:SetValue(75)


-- Applies a style.
Element:SetStyle(Style or string or table style) returns Element

button:SetStyle("button")


-- Creates and applies style.
Element:NewStyle(table definition) returns Element

button:NewStyle({
    background = UBUI.HexToColor("#596BFF"),
    textColor  = UBUI.Colors.white,
})


-- Updates attached borders.
Element:UpdateBorders() returns Element

button:UpdateBorders()


-- Adds a border.
Element:Border(table  options) returns Border 

local border = button:Border({ thickness = 2 })


-- Adds an outline.
Element:Outline(table  options) returns LuaComponent 

button:Outline({ distance = 2 })


-- Adds a shadow.
Element:Shadow(table  options) returns LuaComponent 

button:Shadow({ x = 3, y = -3, alpha = 0.5 })


-- Adds tags to an element.
Element:Tag(string or table tags) returns Element

button:Tag({ "interactive", "settings" })


-- Adds an element to one or multiple groups.
Element:AddTo(string or Group or table group) returns Element

button:AddTo("controls")


-- Creates a group containing this element.
Element:AsGroup(string  name) returns Group

local group = button:AsGroup("singleButton")


-- Changes slider fill and background colors.
Element:SetSliderColors(
    Vector4  fillColor,
    Vector4  backgroundColor
) returns Element

slider:SetSliderColors(
    UBUI.HexToColor("#8CA0FF"),
    UBUI.HexToColor("#252938")
)


-- Changes slider handle color.
Element:SetHandleColor(Vector4 color) returns Element

slider:SetHandleColor(UBUI.Colors.white)


-- Changes slider handle visibility.
Element:SetHandleVisible(boolean state) returns Element

slider:SetHandleVisible(true)


-- Changes slider handle width.
Element:SetHandleWidth(number width) returns Element

slider:SetHandleWidth(18)


-- Changes slider handle height.
Element:SetHandleHeight(number height) returns Element

slider:SetHandleHeight(28)


-- Changes slider handle size.
Element:SetHandleSize(number width, number height) returns Element

slider:SetHandleSize(18, 28)


-- Changes slider track height.
Element:SetTrackHeight(number height) returns Element

slider:SetTrackHeight(8)


-- Changes slider range.
Element:SetSliderRange(number minimum, number maximum) returns Element

slider:SetSliderRange(0, 100)


-- Returns the selected picker color.
Element:GetPickerColor() returns Vector4 

local color = picker:GetPickerColor()


-- Changes the selected picker color.
Element:SetPickerColor(Vector4 or string color) returns Element

picker:SetPickerColor("#8CA0FF")


-- Returns the picker color as hexadecimal text.
Element:GetHex() returns string

local hex = picker:GetHex()


-- Changes the picker color from hexadecimal text.
Element:SetHex(string hex) returns Element

picker:SetHex("#FF7AC6")


-- Refreshes picker handles and previews.
Element:RefreshPicker() returns Element

picker:RefreshPicker()


-- Returns picker HSV values.
Element:GetHSV() returns number hue, number saturation, number value

local hue, saturation, value = picker:GetHSV()


-- Changes picker HSV values.
Element:SetHSV(number hue, number saturation, number value) returns Element

picker:SetHSV(0.65, 0.45, 1)


-- Changes native GB color behavior.
Element:SetGBColors(boolean state) returns Element

picker:SetGBColors(true)


-- Alias used when configuring native GB colors.
Element:UseGBColors(boolean state) returns Element

picker:UseGBColors(true)


-- Returns native GB color behavior.
Element:GetGBColors() returns boolean

local state = picker:GetGBColors()


-- Changes hue ring thickness.
Element:SetHueThickness(number thickness) returns Element

picker:SetHueThickness(0.15)


-- Returns hue ring thickness.
Element:GetHueThickness() returns number

local thickness = picker:GetHueThickness()


-- Alias of Element:SetHueThickness.
Element:SetRingThickness(number thickness) returns Element

picker:SetRingThickness(0.15)

-- Alias of Element:GetHueThickness.
Element:GetRingThickness() returns number

local thickness = picker:GetRingThickness()


-- Returns the actual picker child object ("ColorPicker" under the root).
Element:GetPickerObject() returns LuaGameObject

local pickerGO = picker:GetPickerObject()


-- Returns the picker child's upper-left layout rectangle.
Element:GetPickerRect() returns number x, number y, number width, number height

local x, y, width, height = picker:GetPickerRect()


-- Changes the size of the picker.
Element:SetPickerSize(number width, number height) returns Element

picker:SetPickerSize(220, 250)

-- Returns the picker size.
Element:GetPickerSize() returns number width, number height

local w, h = picker:GetPickerSize()

-- Positions the picker.
Element:SetPickerRect(number x, number y, number width, number height) returns Element

picker:SetPickerRect(0, 0, 220, 250)

-- Sets anchorMin / anchorMax / pivot / anchoredPosition of the picker.
-- Each argument accepts a Vector2 or a { x, y } table (nil = keep current).
Element:SetPickerAnchor(anchorMin, anchorMax, pivot, position) returns Element

picker:SetPickerAnchor(
    Vector2.New(0.5, 1),
    Vector2.New(0.5, 1),
    Vector2.New(0.5, 1),
    Vector2.New(0, 0)
)

-- Changes the LocalScale of the picker
Element:SetPickerScale(number scale) returns Element

picker:SetPickerScale(0.6)

-- Returns the picker scale.
Element:GetPickerScale() returns number

local scale = picker:GetPickerScale()


-- Changes the picker background color.
Element:SetPickerBgColor(Vector4 color) returns Element

picker:SetPickerBgColor(UBUI.HexToColor("#11131A"))


-- Returns the picker background color.
Element:GetPickerBgColor() returns Vector4 

local color = picker:GetPickerBgColor()


-- Changes the picker Apply button color.
Element:SetApplyColor(Vector4 color) returns Element

picker:SetApplyColor(UBUI.HexToColor("#596BFF"))


-- Returns the picker Apply button color.
Element:GetApplyColor() returns Vector4 

local color = picker:GetApplyColor()


-- Changes the picker Close button color.
Element:SetCloseColor(Vector4 color) returns Element

picker:SetCloseColor(UBUI.HexToColor("#C94F64"))


-- Returns the picker Close button color.
Element:GetCloseColor() returns Vector4 

local color = picker:GetCloseColor()


-- Changes the picker label text.
Element:SetLabelText(string text) returns Element

picker:SetLabelText("<b>Accent color</b>")


-- Returns the picker label text.
Element:GetLabelText() returns string

local text = picker:GetLabelText()


-- Changes picker label text color.
Element:SetLabelTextColor(Vector4 color) returns Element

picker:SetLabelTextColor(UBUI.Colors.white)


-- Changes picker label background color.
Element:SetLabelColor(Vector4 color) returns Element

picker:SetLabelColor(UBUI.HexToColor("#252938"))


-- Returns picker label background color.
Element:GetLabelColor() returns Vector4 

local color = picker:GetLabelColor()


-- Changes picker label visibility.
Element:SetLabelVisible(boolean state) returns Element

picker:SetLabelVisible(true)


-- Replaces the picker Apply callback.
-- The callback receives the selected color and Element.
Element:SetOnApply(function callback) returns Element

picker:SetOnApply(function(color, element)
    Debug.Log("Applied: " .. element:GetHex())
end)

-- Replaces the picker Close callback.
-- The callback receives the Element.
Element:SetOnClose(function callback) returns Element

picker:SetOnClose(function(element)
    element:SetHex("#FF0000")
end)

-- Replaces the picker unselect callback.
-- The callback receives the Element.
Element:SetOnUnSelect(function callback) returns Element

picker:SetOnUnSelect(function(element)
    Debug.Log("Picker unselected")
end)


-- Changes the Apply button interaction state.
Element:SetApplyEnabled(boolean state) returns Element

picker:SetApplyEnabled(true)


-- Changes the Close button interaction state.
Element:SetCloseEnabled(boolean state) returns Element

picker:SetCloseEnabled(true)


-- Changes the Apply button visibility.
Element:SetApplyVisible(boolean state) returns Element

picker:SetApplyVisible(true)


-- Changes the Close button visibility.
Element:SetCloseVisible(boolean state) returns Element

picker:SetCloseVisible(true)


-- Changes picker color-code visibility.
Element:SetCodeVisible(boolean state) returns Element

picker:SetCodeVisible(true)


-- Reads a raw native picker field.
Element:PickerGet(string field) returns value 

local value = picker:PickerGet("useGBColors")


-- Writes a raw native picker field.
Element:PickerSet(string field, value) returns Element

picker:PickerSet("useGBColors", true)


-- Destroys an element.
Element:Destroy()

button:Destroy()


-- Checks whether a value is a UBUI Group.
UBUI.IsGroup(value) returns boolean

local isGroup = UBUI.IsGroup(controls)


-- Checks whether a group item is alive.
UBUI.ItemAlive(object) returns boolean

local alive = UBUI.ItemAlive(button)


-- Creates a group with optional initial items.
UBUI.NewGroup(string  name, table  items) returns Group

local controls = UBUI.NewGroup("controls", {
    applyButton,
    closeButton,
})


-- Returns an existing group or creates it.
UBUI.Group(string  name) returns Group

local controls = UBUI.Group("controls")


-- Returns an existing group without creating it.
UBUI.GetGroup(string name) returns Group 

local controls = UBUI.GetGroup("controls")


-- Removes a group registration without destroying its items.
UBUI.DropGroup(string name) returns Group 

local group = UBUI.DropGroup("controls")


-- Adds an object to one or multiple groups.
UBUI.Attach(string or Group or table group, object) returns object

UBUI.Attach({ "controls", "settings" }, button)


-- Removes dead items from all groups and tags.
UBUI.PruneGroups() returns UBUI

UBUI.PruneGroups()


-- Checks whether a group contains an object.
Group:Has(object) returns boolean

local contains = controls:Has(button)


-- Adds an object, list or nested group.
Group:Add(object) returns Group

controls:Add({ button, slider })


-- Removes an object.
Group:Remove(object) returns Group

controls:Remove(button)


-- Removes all members without destroying them.
Group:Clear() returns Group

controls:Clear()


-- Returns the number of living members.
Group:Count() returns number

local count = controls:Count()


-- Removes dead members.
Group:Prune() returns Group

controls:Prune()


-- Refreshes a tag-backed group or prunes a normal group.
Group:Refresh() returns Group

controls:Refresh()


-- Creates a group containing the same items.
Group:Group(string  name) returns Group

local copy = controls:Group("controlsCopy")


-- Calls a callback for every living item.
-- The callback receives the item and its owning Group.
Group:ForEach(function callback) returns Group

controls:ForEach(function(item, group)
    Debug.Log(basicModule.tostring(item))
end)

-- Maps living items into a table.
-- The callback receives the item.
Group:Map(function callback) returns table

local values = controls:Map(function(item)
    return item:GetValue()
end)

-- Creates an anonymous group containing matching items.
-- The callback receives the item.
Group:Where(function callback) returns Group

local visible = controls:Where(function(item)
    return item:IsVisible()
end)


-- Returns the first living item.
Group:First() returns item 

local first = controls:First()


-- Calls a named method on compatible items.
Group:Call(string method, a, b, c, d) returns Group

controls:Call("SetFontSize", 22)


-- Changes visibility of compatible items.
Group:SetVisible(boolean state) returns Group

controls:SetVisible(true)


-- Shows compatible items.
Group:Show() returns Group

controls:Show()


-- Hides compatible items.
Group:Hide() returns Group

controls:Hide()


-- Toggles group visibility.
Group:Toggle() returns Group

controls:Toggle()


-- Returns the current group visibility state.
Group:IsVisible() returns boolean

local visible = controls:IsVisible()


-- Links an object to shared open state.
Group:LinkOpen(Window or Group object) returns Group

controls:LinkOpen(window)


-- Enables or disables shared open-state propagation.
Group:ShareOpen(boolean  state) returns Group

controls:ShareOpen(true)


-- Changes shared open state.
Group:SetOpen(boolean state) returns Group

controls:SetOpen(true)


-- Opens all linked windows.
Group:Open() returns Group

controls:Open()


-- Closes all linked windows.
Group:Close() returns Group

controls:Close()


-- Toggles shared open state.
Group:ToggleOpen() returns Group

controls:ToggleOpen()


-- Returns shared open state.
Group:IsOpen() returns boolean

local open = controls:IsOpen()


-- Changes interaction state of compatible items.
Group:SetEnabled(boolean state) returns Group

controls:SetEnabled(true)


-- Enables compatible items.
Group:Enable() returns Group

controls:Enable()


-- Disables compatible items.
Group:Disable() returns Group

controls:Disable()


-- Applies text to compatible items.
Group:SetText(string text) returns Group

controls:SetText("<b>Updated</b>")


-- Applies text color to compatible items.
Group:SetTextColor(Vector4 color) returns Group

controls:SetTextColor(UBUI.Colors.white)


-- Applies font size to compatible items.
Group:SetFontSize(number size) returns Group

controls:SetFontSize(22)


-- Applies alignment to compatible items.
Group:SetAlign(string alignment) returns Group

controls:SetAlign("MiddleCenter")


-- Applies color to compatible items.
Group:SetColor(Vector4 color) returns Group

controls:SetColor(UBUI.HexToColor("#8CA0FF"))


-- Applies a value to compatible widgets.
Group:SetValue(value) returns Group

controls:SetValue(true)


-- Applies size to compatible items.
Group:SetSize(number width, number height) returns Group

controls:SetSize(200, 44)


-- Applies a style to compatible items.
Group:SetStyle(Style or string or table style) returns Group

controls:SetStyle("button")


-- Changes compatible color picker values.
Group:SetPickerColor(Vector4 or string color) returns Group

controls:SetPickerColor("#8CA0FF")


-- Changes compatible color picker hex values.
Group:SetHex(string hex) returns Group

controls:SetHex("#8CA0FF")


-- Refreshes compatible color pickers.
Group:RefreshPickers() returns Group

controls:RefreshPickers()


-- Returns values from compatible widgets.
Group:Values() returns table

local values = controls:Values()


-- Restyles compatible items.
Group:Restyle() returns Group

controls:Restyle()


-- Relayouts compatible areas.
Group:Relayout() returns Group

controls:Relayout()


-- Destroys all group members.
Group:DestroyItems() returns Group

controls:DestroyItems()


-- Destroys members and unregisters the group.
Group:Destroy()

controls:Destroy()


-- Adds one or multiple tags to an object.
UBUI.Tag(object, string or table tags) returns object

UBUI.Tag(button, { "interactive", "settings" })


-- Checks whether an object has a tag.
UBUI.HasTag(object, string tag) returns boolean

local tagged = UBUI.HasTag(button, "interactive")


-- Removes a tag from an object.
UBUI.Untag(object, string tag) returns object

UBUI.Untag(button, "settings")


-- Returns living objects carrying a tag.
UBUI.Tagged(string tag) returns table

local items = UBUI.Tagged("interactive")

for _, item in tableIterators.ipairs(items) do
    item:Show()
end


-- Creates a group from objects carrying a tag.
UBUI.GroupByTag(string tag, string  name) returns Group

local group = UBUI.GroupByTag(
    "interactive",
    "interactiveControls"
)


-- Creates a layout area inside a registered space.
UBUI.NewArea(
    string  space,
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns Area 

options:
    Vector4 color
    boolean raycast
    boolean clipping
    number padding
    number padLeft
    number padRight
    number padTop
    number padBottom
    number spacing
    Style or string or table style
    string or Group or table group
    string or table tags

local area = UBUI.NewArea("base", "SettingsArea", 30, 30, 520, 600, {
    color    = UBUI.HexToColor("#11131AF2"),
    clipping = true,
    padding  = 18,
    spacing  = 10,
    group    = "settings",
    tags     = { "menu", "settings" },
})


-- Creates a layout area inside a Transform.
UBUI.NewAreaAt(
    LuaTransform parent,
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns Area 

local area = UBUI.NewAreaAt(
    parent,
    "Content",
    0,
    0,
    420,
    360,
    {
        padding = 12,
        spacing = 8,
    }
)


-- Checks whether an Area exists.
Area:IsAlive() returns boolean

local alive = area:IsAlive()


-- Checks whether clipping is enabled.
Area:HasClipping() returns boolean

local clipped = area:HasClipping()


-- Enables or disables clipping.
Area:SetClipping(boolean state) returns Area

area:SetClipping(true)


-- Returns usable content width.
Area:ContentWidth() returns number

local width = area:ContentWidth()


-- Changes Area active state.
Area:SetActive(boolean state) returns Area

area:SetActive(true)


-- Changes Area color.
Area:SetColor(Vector4 color) returns Area

area:SetColor(UBUI.HexToColor("#11131A"))


-- Applies a style to an Area.
Area:SetStyle(Style or string or table style) returns Area

area:SetStyle("area")


-- Adds tags to an Area.
Area:Tag(string or table tags) returns Area

area:Tag({ "menu", "settings" })


-- Adds an Area to groups.
Area:AddTo(string or Group or table group) returns Area

area:AddTo("settings")


-- Creates a group from Area elements.
Area:AsGroup(string  name) returns Group

local group = area:AsGroup("areaElements")


-- Changes Area rectangle.
Area:SetRect(
    number x,
    number y,
    number width,
    number height
) returns Area

area:SetRect(30, 30, 520, 600)


-- Sets absolute local Z rotation in degrees.
Area:Rotate(number degrees) returns Area

area:Rotate(15)


-- Sets anchorMin and anchorMax of an Area.
Area:SetAnchor(
    number or Vector2 or table x,
    number or Vector2 or table y,
    number maxX,
    number maxY
) returns Area

area:SetAnchor(0, 0, 1, 1)

-- Sets the pivot of an Area.
Area:SetPivot(
    number or Vector2 or table x,
    number y
) returns Area

area:SetPivot(0.5, 0.5)


-- Starts a horizontal layout row.
Area:BeginRow(number  height) returns Area

area:BeginRow(44)


-- Finishes the current horizontal layout row.
Area:EndRow() returns Area

area:EndRow()


-- Adds empty vertical layout space.
Area:Space(number pixels) returns Area

area:Space(12)


-- Recalculates visible layout items.
Area:Relayout() returns Area

area:Relayout()


-- Destroys all items inside an Area.
Area:Clear() returns Area

area:Clear()


-- Destroys an Area and its items.
Area:Destroy()

area:Destroy()


-- Creates a nested Area.
Area:NewArea(
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns Area 

local nested = area:NewArea("Nested", 0, 0, 300, 180, {
    clipping = true,
    padding  = 10,
    spacing  = 8,
})


-- Reapplies Area style and child styles.
Area:Restyle() returns Area

area:Restyle()


-- Creates an image.
Area:Image(table  options) returns Element 

options:
    number x
    number y
    number w
    number h
    string name
    number indent
    LuaTexture texture
    Vector4 color
    boolean raycast
    string or number imageType
    string or number fillMethod
    number fillAmount
    boolean fillClockwise
    number fillOrigin
    boolean preserveAspect
    Style or string or table style
    string or Group or table group
    string or table tags

local image = area:Image({
    w              = 96,
    h              = 96,
    texture        = Importer.ImportTexture("resources/icon.png"),
    color          = UBUI.Colors.white,
    preserveAspect = true,
})


-- Creates a text label with Unity Rich Text support.
Area:Text(string text, table  options) returns Element 

options:
    number x
    number y
    number w
    number h
    string name
    number indent
    Vector4 textColor
    number fontSize
    boolean autoSize
    number autoMin
    number autoMax
    number textPad
    number textPadY
    string align
    boolean wordWrap
    Style or string or table style
    string or Group or table group
    string or table tags

local title = area:Text("<b><color=#8CA0FF>UBUI</color> Settings</b>", {
    h         = 48,
    fontSize  = 28,
    textColor = UBUI.Colors.white,
    align     = "MiddleLeft",
    wordWrap  = false,
})


-- Alias of Area:Text.
Area:Label(string text, table  options) returns Element 

local label = area:Label("<b>Label</b>", {
    h = 32,
})


-- Creates a clickable button.
Area:Button(
    string label,
    function onClick,
    table options
) returns Element

options:
    number x
    number y
    number w
    number h
    string name
    number indent
    Vector4 color
    Vector4 textColor
    number fontSize
    string align
    boolean wordWrap
    number textPad
    number textPadY
    boolean fixed
    number autoMin
    number autoMax
    Style or string or table style
    string or Group or table group
    string or table tags

local button = area:Button("<b>Apply</b>", function(element)
    Debug.Log("Applied")
end, {
    w = 180,
    h = 46,
    color = UBUI.HexToColor("#596BFF"),
    textColor = UBUI.Colors.white,
    align = "MiddleCenter",
    group = "controls",
})


-- Creates a boolean toggle.
Area:Toggle(
    string label,
    boolean value,
    function onChange,
    table options
) returns Element

local toggle = area:Toggle("<b>Enabled</b>", true, function(value, element)
    Debug.Log("Enabled: " .. basicModule.tostring(value))
end, {
    w     = 260,
    h     = 42,
    group = "controls",
})


-- Creates a text input field.
Area:InputField(
    string text,
    function onChange,
    table options
) returns Element

options:
    number x
    number y
    number w
    number h
    string name
    number indent
    number characterLimit
    Vector4 textColor
    number fontSize
    string align
    boolean wordWrap
    Style or string or table style
    string or Group or table group
    string or table tags

local input = area:InputField("Player", function(value, element)
    Debug.Log("Name: " .. value)
end, {
    w              = 300,
    h              = 44,
    characterLimit = 24,
    align          = "MiddleLeft",
})


-- Creates a numeric slider.
Area:Slider(
    number value,
    number minimum,
    number maximum,
    function onChange,
    table options
) returns Element

options:
    number x
    number y
    number w
    number h
    string name
    number indent
    Vector4 fillColor
    Vector4 bgColor
    boolean handle
    Vector4 handleColor
    number handleWidth
    number handleHeight
    number trackHeight
    boolean wholeNumbers
    Style or string or table style
    string or Group or table group
    string or table tags

local slider = area:Slider(50, 0, 100, function(value, element)
    Debug.Log("Volume: " .. basicModule.tostring(value))
end, {
    w             = 300,
    h             = 36,
    fillColor     = UBUI.HexToColor("#8CA0FF"),
    bgColor       = UBUI.HexToColor("#252938"),
    handle        = true,
    handleColor   = UBUI.Colors.white,
    handleWidth   = 18,
    handleHeight  = 28,
    trackHeight   = 8,
    wholeNumbers  = true,
})


-- Rotation is an absolute local Z angle in degrees.
slider:Rotate(90)
slider:SetAnchor(0.5, 0.5)
slider:SetPivot(0.5, 0.5)


-- Creates a color picker.
Area:ColorPicker(
    Vector4 or string color,
    function onChange,
    table options
) returns Element

options:
    number x
    number y
    number w -- by default it's 257.2
    number h -- by default it's 300.96
    string name
    number indent
    Vector4 bgColor
    Vector4 applyColor
    Vector4 closeColor
    boolean gbColors
    number hueThickness
    boolean code
    number scale
    string labelText
    Vector4 labelColor
    Vector4 labelTextColor
    function onApply
	function onClose
	function onUnSelect
    Style or string or table style
    string or Group or table group
    string or table tags

local picker = area:ColorPicker("#8CA0FF", function(color, element)
    Debug.Log("Color: " .. element:GetHex())
end, {
    w              = 360,
    h              = 420,
    bgColor        = UBUI.HexToColor("#11131A"),
    applyColor     = UBUI.HexToColor("#596BFF"),
    closeColor     = UBUI.HexToColor("#C94F64"),
    gbColors       = true,
    hueThickness   = 0.15,
    code           = true,
    scale          = 1,
    labelText      = "<b>Select color</b>",
    labelTextColor = UBUI.Colors.white,
})


-- Creates a window.
UBUI.Window(
    number width,
    number height,
    number x,
    number y,
    boolean header,
    number headerHeight,
    string label,
    table options
) returns Window 

options:
    string space
    string name
    boolean center
    boolean clipping
    number padding
    number spacing
    Vector4 bodyColor
    Vector4 rootColor
    Vector4 headerColor
    boolean border
    Vector4 borderColor
    number borderThickness
    Vector4 titleColor
    number titleSize
    string titleAlign
    number titleInset
    boolean autoScale
    number margin
    number minScale
    function onClose
    Style or string or table style
    string or Group or table group
    string or table tags

local window = UBUI.Window(620, 520, 0, 0, false, 0, "", {
    space       = "base",
    name        = "Window",
    center      = true,
    padding     = 18,
    spacing     = 10,
    bodyColor   = UBUI.HexToColor("#11131AF2"),
    border      = true,
    borderColor = UBUI.HexToColor("#8CA0FF"),
    group       = "windows",
    tags        = { "window" },
})


-- Checks whether a Window exists.
Window:IsAlive() returns boolean

local alive = window:IsAlive()


-- Checks whether Window clipping is enabled.
Window:HasClipping() returns boolean

local clipped = window:HasClipping()


-- Enables or disables Window clipping.
Window:SetClipping(boolean state) returns Window

window:SetClipping(true)


-- Opens a Window.
Window:Open() returns Window

window:Open()


-- Closes a Window.
Window:Close() returns Window

window:Close()


-- Toggles Window open state.
Window:Toggle() returns Window

window:Toggle()


-- Returns Window open state.
Window:IsOpen() returns boolean

local open = window:IsOpen()


-- Changes Window title text.
Window:SetTitle(string text) returns Window

window:SetTitle("<b><color=#8CA0FF>UBUI</color> Settings</b>")


-- Changes Window position.
Window:SetPosition(number x, number y) returns Window

window:SetPosition(40, 40)


-- Sets absolute local Z rotation in degrees.
Window:Rotate(number degrees) returns Window

window:Rotate(15)


-- Sets anchorMin and anchorMax of a Window.
Window:SetAnchor(
    number or Vector2 or table x,
    number or Vector2 or table y,
    number maxX,
    number maxY
) returns Window

window:SetAnchor(0.5, 0.5)

-- Sets the pivot of a Window.
Window:SetPivot(
    number or Vector2 or table x,
    number y
) returns Window

window:SetPivot(0.5, 0.5)


-- Centers a Window.
Window:Center() returns Window

window:Center()


-- Adds tags to a Window.
Window:Tag(string or table tags) returns Window

window:Tag({ "menu", "settings" })


-- Adds a Window to groups.
Window:AddTo(string or Group or table group) returns Window

window:AddTo("ui")


-- Links a Window to shared open state.
Window:ShareOpen(string or Group group) returns Group

local group = window:ShareOpen("menus")


-- Recalculates automatic screen scaling.
Window:UpdateScale()

window:UpdateScale()


-- Reapplies Window colors and styles.
Window:Restyle() returns Window

window:Restyle()


-- Updates attached Window borders.
Window:UpdateBorders() returns Window

window:UpdateBorders()


-- Destroys a Window.
Window:Destroy()

window:Destroy()


-- Creates a row inside a Window header.
Window:HeaderRow(
    string  alignment,
    table  options
) returns HeaderRow 

options:
    number inset
    number spacing
    number offset
    number h

local row = window:HeaderRow("right", {
    inset   = 8,
    spacing = 6,
    offset  = 0,
    h       = 36,
})


-- Recalculates all Window header rows.
Window:LayoutHeader() returns Window

window:LayoutHeader()


-- Adds an existing Element to a header row.
HeaderRow:Add(
    Element element,
    number  width,
    number  height
) returns Element

row:Add(button, 36, 36)


-- Creates a header-row button.
HeaderRow:Button(
    string label,
    function onClick,
    table  options
) returns Element 

local closeButton = row:Button("<b>×</b>", function(element)
    window:Close()
end, {
    w = 36,
    h = 36,
    style = "close",
})


-- Creates header-row text.
HeaderRow:Text(string text, table  options) returns Element 

row:Text("<b>Tools</b>", {
    w = 100,
    h = 36,
})


-- Creates a header-row toggle.
HeaderRow:Toggle(
    string label,
    boolean value,
    function onChange,
    table  options
) returns Element 

row:Toggle("Lock", false, function(value, element)
end, {
    w = 100,
})


-- Creates a header-row image.
HeaderRow:Image(table  options) returns Element 

row:Image({
    w       = 32,
    h       = 32,
    texture = texture,
})


-- Adds empty horizontal row space.
HeaderRow:Space(number pixels) returns HeaderRow

row:Space(8)


-- Returns total visible row width.
HeaderRow:Width() returns number

local width = row:Width()


-- Recalculates row item positions.
HeaderRow:Layout() returns HeaderRow

row:Layout()


-- Changes row alignment.
HeaderRow:SetAlign(string alignment) returns HeaderRow

row:SetAlign("right")


-- Changes row offset.
HeaderRow:SetOffset(number pixels) returns HeaderRow

row:SetOffset(-4)


-- Changes row spacing.
HeaderRow:SetSpacing(number pixels) returns HeaderRow

row:SetSpacing(8)


-- Creates a group from row elements.
HeaderRow:AsGroup(string  name) returns Group

local group = row:AsGroup("headerControls")


-- Destroys all row elements.
HeaderRow:Clear() returns HeaderRow

row:Clear()


-- Creates a ScrollView inside a registered space.
UBUI.ScrollView(
    string  space,
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns ScrollView 

options:
    boolean horizontal
    boolean vertical
    boolean hideVertical
    boolean hideHorizontal
    number scrollbarSize
    number contentWidth
    Vector4 bgColor
    Vector4 contentColor
    boolean contentRaycast
    Vector4 trackColor
    Vector4 handleColor
    number padding
    number spacing
    boolean elastic
    number sensitivity
    boolean inertia
    number decelerationRate
    boolean autoHide
    boolean border
    Vector4 borderColor
    number borderThickness
    Style or string or table style
    string or Group or table group
    string or table tags
    boolean culling
	number cullingPadding

local scroll = UBUI.ScrollView("base", "SettingsScroll", 40, 40, 520, 640, {
    vertical      = true,
    horizontal    = false,
    scrollbarSize = 14,
    padding       = 16,
    spacing       = 10,
    sensitivity   = 24,
    inertia       = true,
    border        = true,
    group         = "ui",
})


-- Creates a ScrollView inside a Transform.
UBUI.ScrollViewAt(
    LuaTransform parent,
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns ScrollView 

local scroll = UBUI.ScrollViewAt(
    parent,
    "ScrollView",
    20,
    20,
    420,
    280,
    {
        vertical = true,
    }
)


-- Creates a ScrollView as the next Area layout item.
Area:ScrollView(table options) returns ScrollView 

local scroll = area:ScrollView({
    w        = 460,
    h        = 300,
    vertical = true,
    padding  = 12,
    spacing  = 8,
})


-- Creates a positioned ScrollView inside an Area.
Area:ScrollViewAt(
    string name,
    number x,
    number y,
    number width,
    number height,
    table  options
) returns ScrollView 

local scroll = area:ScrollViewAt(
    "NestedScroll",
    20,
    20,
    420,
    280,
    {
        vertical = true,
    }
)


-- Checks whether a ScrollView exists.
ScrollView:IsAlive() returns boolean

local alive = scroll:IsAlive()


-- Returns ScrollView visibility.
ScrollView:IsVisible() returns boolean

local visible = scroll:IsVisible()


-- Sets absolute local Z rotation in degrees.
ScrollView:Rotate(number degrees) returns ScrollView

scroll:Rotate(15)


-- Sets anchorMin and anchorMax of a ScrollView root.
ScrollView:SetAnchor(
    number or Vector2 or table x,
    number or Vector2 or table y,
    number maxX,
    number maxY
) returns ScrollView

scroll:SetAnchor(0.5, 0.5)

-- Sets the pivot of a ScrollView root.
ScrollView:SetPivot(
    number or Vector2 or table x,
    number y
) returns ScrollView

scroll:SetPivot(0.5, 0.5)

-- Enables or disables viewport culling.
ScrollView:SetCulling(boolean state) returns ScrollView

scroll:SetCulling(true)

-- Changes the extra active area around the viewport.
ScrollView:SetCullingPadding(number pixels) returns ScrollView

scroll:SetCullingPadding(96)

-- Suspends ScrollView relayout while elements are being added.
ScrollView:BeginBatch() returns ScrollView

scroll:BeginBatch()

-- Finishes a suspended batch and performs one relayout.
ScrollView:EndBatch() returns ScrollView

scroll:EndBatch()

-- Creates multiple elements with one final relayout.
-- The callback receives Area and ScrollView.
ScrollView:Batch(function callback) returns ScrollView

scroll:Batch(function(area, scrollView)
    for i = 1, 100 do
        area:Button(
            "<b>Button " ..
            basicModule.tostring(i) ..
            "</b>",
            function()
            end,
            {
                h = 42
            }
        )
    end
end)


-- Changes ScrollView visibility.
ScrollView:SetActive(boolean state) returns ScrollView

scroll:SetActive(true)


-- Alias of ScrollView:SetActive.
ScrollView:SetVisible(boolean state) returns ScrollView

scroll:SetVisible(true)


-- Shows a ScrollView.
ScrollView:Show() returns ScrollView

scroll:Show()


-- Hides a ScrollView.
ScrollView:Hide() returns ScrollView

scroll:Hide()


-- Measures required ScrollView content size.
ScrollView:Measure() returns number width, number height

local width, height = scroll:Measure()


-- Resizes ScrollView content to fit its items.
ScrollView:Fit() returns ScrollView

scroll:Fit()


-- Clears ScrollView content.
ScrollView:Clear() returns ScrollView

scroll:Clear()


-- Changes normalized vertical position.
ScrollView:SetVertical(number position) returns ScrollView

scroll:SetVertical(0.5)


-- Changes normalized horizontal position.
ScrollView:SetHorizontal(number position) returns ScrollView

scroll:SetHorizontal(0)


-- Scrolls to the top.
ScrollView:ToTop() returns ScrollView

scroll:ToTop()


-- Scrolls to the bottom.
ScrollView:ToBottom() returns ScrollView

scroll:ToBottom()


-- Locks or unlocks horizontal scrolling.
ScrollView:LockHorizontal(boolean  state) returns ScrollView

scroll:LockHorizontal(true)


-- Locks or unlocks vertical scrolling.
ScrollView:LockVertical(boolean  state) returns ScrollView

scroll:LockVertical(true)


-- Unlocks horizontal scrolling.
ScrollView:UnlockHorizontal() returns ScrollView

scroll:UnlockHorizontal()


-- Unlocks vertical scrolling.
ScrollView:UnlockVertical() returns ScrollView

scroll:UnlockVertical()


-- Aligns the content RectTransform.
ScrollView:Align(string alignment, table  options) returns ScrollView

options:
    Vector2 or table pivot
    Vector2 or table offset

local scroll = scroll:Align("UpperCenter", {
    pivot  = { x = 0.5, y = 1 },
    offset = { x = 0, y = -8 },
})


-- Sets custom content anchors.
ScrollView:SetContentAnchor(
    Vector2 or table  anchorMin,
    Vector2 or table  anchorMax,
    Vector2 or table  pivot,
    Vector2 or table  position
) returns ScrollView

scroll:SetContentAnchor(
    { x = 0, y = 1 },
    { x = 0, y = 1 },
    { x = 0, y = 1 },
    { x = 0, y = 0 }
)


-- Updates ScrollView frame positions.
ScrollView:UpdateFrame() returns ScrollView

scroll:UpdateFrame()


-- Changes ScrollView frame color.
ScrollView:SetFrameColor(Vector4 color) returns ScrollView

scroll:SetFrameColor(UBUI.HexToColor("#8CA0FF"))


-- Changes ScrollView frame visibility.
ScrollView:SetFrameVisible(boolean state) returns ScrollView

scroll:SetFrameVisible(true)


-- Shows or hides the viewport and scrollbars.
ScrollView:SetScrollVisible(boolean state) returns ScrollView

scroll:SetScrollVisible(true)


-- Shows the viewport and scrollbars.
ScrollView:ShowScroll() returns ScrollView

scroll:ShowScroll()


-- Hides the viewport and scrollbars.
ScrollView:HideScroll() returns ScrollView

scroll:HideScroll()


-- Toggles viewport and scrollbar visibility.
ScrollView:ToggleScroll() returns ScrollView

scroll:ToggleScroll()


-- Adds a header above the ScrollView viewport.
ScrollView:Header(
    number or table height,
    table  options
) returns ScrollView

options:
    number h
    string label
    Vector4 color
    Vector4 headerColor
    Vector4 borderColor
    number borderThickness
    Vector4 titleColor
    number titleSize
    string titleAlign
    number titleInset

scroll:Header(48, {
    label      = "<b><color=#8CA0FF>UBUI</color> Items</b>",
    titleAlign = "MiddleLeft",
    titleSize  = 22,
})


-- Creates a row inside the ScrollView header.
ScrollView:HeaderRow(
    string  alignment,
    table  options
) returns HeaderRow 

local row = scroll:HeaderRow("right", {
    inset   = 8,
    spacing = 6,
    h       = 34,
})


-- Recalculates ScrollView header rows.
ScrollView:LayoutHeader() returns ScrollView

scroll:LayoutHeader()


-- Adds a border to a ScrollView.
ScrollView:Border(table  options) returns Border 

scroll:Border({ thickness = 2 })


-- Adds an outline to a ScrollView.
ScrollView:Outline(table  options) returns LuaComponent 

scroll:Outline({ distance = 2 })


-- Adds a shadow to a ScrollView.
ScrollView:Shadow(table  options) returns LuaComponent 

scroll:Shadow({
    x = 3,
    y = -3,
    alpha = 0.5
})

-- Updates attached ScrollView borders.
ScrollView:UpdateBorders() returns ScrollView

scroll:UpdateBorders()

-- Adds tags to a ScrollView.
ScrollView:Tag(string or table tags) returns ScrollView

scroll:Tag({ "menu", "settings" })

-- Adds a ScrollView to one or multiple groups.
ScrollView:AddTo(string or Group or table group) returns ScrollView

scroll:AddTo("ui")

-- Reapplies ScrollView colors and child styles.
ScrollView:Restyle() returns ScrollView

scroll:Restyle()

-- Destroys a ScrollView and its content.
ScrollView:Destroy()

scroll:Destroy()
	
-- Returns the Unity instanceId of a GameObject or wrapped UBUI object.
UBUI.GetInstanceId(target) returns number

local id = UBUI.GetInstanceId(window)

-- Returns a previously indexed object by its instanceId.
UBUI.GetObjectByInstanceId(number id) returns LuaGameObject

local object = UBUI.GetObjectByInstanceId(id)

-- Compares two targets by their instanceId.
UBUI.SameObject(a, b) returns boolean

local same = UBUI.SameObject(window, window.obj)

-- Returns the cached Element instanceId.
Element:GetInstanceId() returns number

local id = button:GetInstanceId()

-- Returns the cached Area instanceId.
Area:GetInstanceId() returns number

local id = area:GetInstanceId()

-- Returns the cached Window instanceId.
Window:GetInstanceId() returns number

local id = window:GetInstanceId()

-- Returns the cached ScrollView instanceId.
ScrollView:GetInstanceId() returns number

local id = scroll:GetInstanceId()

-- Sets the rendering layer of a target.
-- Adds a Canvas component with overrideSorting enabled.
UBUI.SetRenderLayer(target, number order) returns target

UBUI.SetRenderLayer(window, 10)

-- Returns the current rendering layer or nil when overrideSorting is disabled.
UBUI.GetRenderLayer(target) returns number

local order = UBUI.GetRenderLayer(window)

-- Checks whether a target has an active render-layer override.
UBUI.HasRenderLayer(target) returns boolean

local overridden = UBUI.HasRenderLayer(window)

-- Disables render-layer overriding on a target.
UBUI.ClearRenderLayer(target) returns target

UBUI.ClearRenderLayer(window)

-- Moves a target to the top of its parent's draw order.
UBUI.BringToFront(target) returns target

UBUI.BringToFront(window)

-- Moves a target to the bottom of its parent's draw order.
UBUI.SendToBack(target) returns target

UBUI.SendToBack(window)

-- Returns the current sibling index of a target inside its parent.
UBUI.GetSiblingIndex(target) returns number

local index = UBUI.GetSiblingIndex(window)

-- Sets the sibling index of a target inside its parent.
UBUI.SetSiblingIndex(target, number index) returns target

UBUI.SetSiblingIndex(window, 0)

-- Sets the rendering layer of an Element.
Element:SetRenderLayer(number order) returns Element

button:SetRenderLayer(5)

-- Returns the Element rendering layer.
Element:GetRenderLayer() returns number

local order = button:GetRenderLayer()

-- Checks whether an Element has an active render-layer override.
Element:HasRenderLayer() returns boolean

local overridden = button:HasRenderLayer()

-- Disables render-layer overriding on an Element.
Element:ClearRenderLayer() returns Element

button:ClearRenderLayer()

-- Moves an Element to the top of its parent's draw order.
Element:BringToFront() returns Element

button:BringToFront()

-- Moves an Element to the bottom of its parent's draw order.
Element:SendToBack() returns Element

button:SendToBack()

-- Returns the Element sibling index.
Element:GetSiblingIndex() returns number

local index = button:GetSiblingIndex()

-- Sets the Element sibling index.
Element:SetSiblingIndex(number index) returns Element

button:SetSiblingIndex(2)

-- Sets the rendering layer of an Area.
Area:SetRenderLayer(number order) returns Area

area:SetRenderLayer(5)

-- Returns the Area rendering layer.
Area:GetRenderLayer() returns number

local order = area:GetRenderLayer()

-- Checks whether an Area has an active render-layer override.
Area:HasRenderLayer() returns boolean

local overridden = area:HasRenderLayer()

-- Disables render-layer overriding on an Area.
Area:ClearRenderLayer() returns Area

area:ClearRenderLayer()

-- Moves an Area to the top of its parent's draw order.
Area:BringToFront() returns Area

area:BringToFront()

-- Moves an Area to the bottom of its parent's draw order.
Area:SendToBack() returns Area

area:SendToBack()

-- Returns the Area sibling index.
Area:GetSiblingIndex() returns number

local index = area:GetSiblingIndex()

-- Sets the Area sibling index.
Area:SetSiblingIndex(number index) returns Area

area:SetSiblingIndex(0)

-- Sets the rendering layer of a Window.
Window:SetRenderLayer(number order) returns Window

window:SetRenderLayer(20)

-- Returns the Window rendering layer.
Window:GetRenderLayer() returns number

local order = window:GetRenderLayer()

-- Checks whether a Window has an active render-layer override.
Window:HasRenderLayer() returns boolean

local overridden = window:HasRenderLayer()

-- Disables render-layer overriding on a Window.
Window:ClearRenderLayer() returns Window

window:ClearRenderLayer()

-- Moves a Window to the top of its parent's draw order.
Window:BringToFront() returns Window

window:BringToFront()

-- Moves a Window to the bottom of its parent's draw order.
Window:SendToBack() returns Window

window:SendToBack()

-- Returns the Window sibling index.
Window:GetSiblingIndex() returns number

local index = window:GetSiblingIndex()

-- Sets the Window sibling index.
Window:SetSiblingIndex(number index) returns Window

window:SetSiblingIndex(0)

-- Sets the rendering layer of a ScrollView.
ScrollView:SetRenderLayer(number order) returns ScrollView

scroll:SetRenderLayer(10)

-- Returns the ScrollView rendering layer.
ScrollView:GetRenderLayer() returns number

local order = scroll:GetRenderLayer()

-- Checks whether a ScrollView has an active render-layer override.
ScrollView:HasRenderLayer() returns boolean

local overridden = scroll:HasRenderLayer()

-- Disables render-layer overriding on a ScrollView.
ScrollView:ClearRenderLayer() returns ScrollView

scroll:ClearRenderLayer()

-- Moves a ScrollView to the top of its parent's draw order.
ScrollView:BringToFront() returns ScrollView

scroll:BringToFront()

-- Moves a ScrollView to the bottom of its parent's draw order.
ScrollView:SendToBack() returns ScrollView

scroll:SendToBack()

-- Returns the ScrollView sibling index.
ScrollView:GetSiblingIndex() returns number

local index = scroll:GetSiblingIndex()

-- Sets the ScrollView sibling index.
ScrollView:SetSiblingIndex(number index) returns ScrollView

scroll:SetSiblingIndex(1)
	
	
	
-- UBUI Styles API
-- v1.0
-- Made By Wosek

-- Contains prefab paths used by UBUI.
S.PREFABS returns table

fields:
    string label
    string button
    string toggle
    string input
    string slider
    string colorPicker

local labelPath = S.PREFABS.label
local buttonPath = S.PREFABS.button


-- Contains reusable named colors.
S.Colors returns table

fields:
    Vector4 clear
    Vector4 white
    Vector4 black
    Vector4 gray
    Vector4 grey
    Vector4 red
    Vector4 green
    Vector4 blue
    Vector4 yellow
    Vector4 orange
    Vector4 cyan
    Vector4 magenta
    Vector4 purple
    Vector4 pink

local white = S.Colors.white
local clear = S.Colors.clear


-- Contains default widget sizes.
S.SIZES returns table

fields:
    number text
    number button
    number toggle
    number input
    number image
    number slider
    number sliderHandle
    number sliderTrack
    number pickerButton

for name, size in tableIterators.pairs(S.SIZES) do
    Debug.Log(
        "" ..
        name ..
        "'s size is " ..
        basicModule.tostring(size)
    )
end


-- Maps alignment names to TMP and Unity UI alignment values.
S.ALIGN returns table

fields:
    table UpperLeft
    table UpperCenter
    table UpperRight
    table MiddleLeft
    table MiddleCenter
    table MiddleRight
    table LowerLeft
    table LowerCenter
    table LowerRight

local middleCenter = S.ALIGN.MiddleCenter
local tmpAlignment = middleCenter[1]
local uiAlignment = middleCenter[2]


-- Contains the active theme.
-- The table identity remains stable after S.SetTheme.
S.Theme returns table

local activeTheme = S.Theme


-- Contains all registered themes.
S.Themes returns table

local darkTheme = S.Themes.dark
local lightTheme = S.Themes.light


-- Contains the active registered theme name.
S.ThemeName returns string 

Debug.Log(
    "Theme Name is... " ..
    basicModule.tostring(S.ThemeName)
)


-- Contains all registered styles.
S.Styles returns table

local buttonStyle = S.Styles.button


-- Maps Style fields to widget option names.
S.FIELD_MAP returns table

local optionName = S.FIELD_MAP.background


-- Maps widget option names to Style fields.
S.OPTS_MAP returns table

local styleField = S.OPTS_MAP.color


-- Contains the Style metatable.
S.StyleClass returns table

local StyleClass = S.StyleClass


-- Called after active theme or registered style changes.
S.OnChange returns function 

S.OnChange = function(theme)
    Debug.Log(
        "Styles updated!"
    )
end


-- Public theme fields.
S.Theme fields:
    Vector4 root
    Vector4 header
    Vector4 border
    Vector4 text
    Vector4 button
    Vector4 buttonText
    Vector4 close
    Vector4 outline
    Vector4 shadow
    Vector4 sliderBg
    Vector4 sliderFill
    Vector4 sliderHandle
    Vector4 pickerBg
    Vector4 pickerApply
    Vector4 pickerClose
    Vector4 pickerLabel
	Vector4 pickerLabelText
    Vector4 scrollBg
    Vector4 scrollTrack
    Vector4 scrollHandle
    Vector4 scrollHeader
    Vector4 scrollBorder
    Vector4 texture
    number borderThickness
    number outlineDistance
    number shadowX
    number shadowY
    number shadowAlpha
    number closeInset
    number padding
    number spacing
    number fontSize
    number titleSize
    number pickerHue


-- Registers a theme.
-- Missing values are inherited from the base theme.
S.DefineTheme(
    string name,
    table definition,
    string  baseName
) returns table 

local theme = S.DefineTheme("violet", {
    root          = Vector4.New(0.06, 0.07, 0.11, 0.95),
    header        = Vector4.New(0.09, 0.11, 0.16, 1),
    border        = Vector4.New(0.55, 0.63, 1, 1),
    text          = S.Colors.white,
    button        = Vector4.New(0.20, 0.23, 0.39, 1),
    buttonText    = S.Colors.white,
    sliderFill    = Vector4.New(0.55, 0.63, 1, 1),
    pickerApply   = Vector4.New(0.35, 0.42, 1, 1),
    scrollHandle  = Vector4.New(0.55, 0.63, 1, 1),
}, "dark")


-- Activates a registered theme.
-- The active S.Theme table keeps its identity.
S.SetTheme(string name) returns table

local theme = S.SetTheme("violet")


-- Changes one value in the active theme.
-- Plain Lua tables are copied before storage.
S.SetThemeValue(string key, value) returns table 

S.SetThemeValue(
    "button",
    Vector4.New(0.35, 0.42, 1, 1)
)


-- Returns one value from the active theme.
S.GetThemeValue(string key) returns any 

local buttonColor = S.GetThemeValue("button")


-- Returns an independent copy of the active theme.
S.GetThemeSnapshot() returns table

local snapshot = S.GetThemeSnapshot()

snapshot.fontSize = 28
snapshot.padding = 18


-- Resolves a theme reference.
-- Strings beginning with @ are resolved recursively.
-- Empty, missing and cyclic references return nil.
S.Resolve(value) returns value 

local textColor = S.Resolve("@text")
local fontSize = S.Resolve("@fontSize")
local literalNumber = S.Resolve(24)


-- Creates a style definition from recognized widget options.
-- Returns a plain table, not a Style object.
S.StyleFromOpts(table options) returns table

local definition = S.StyleFromOpts({
    color       = Vector4.New(0.35, 0.42, 1, 1),
    textColor   = S.Colors.white,
    fontSize    = 22,
    w           = 200,
    h           = 46,
    align       = "MiddleCenter",
    wordWrap    = false,
    clipping    = true,
    fillAmount  = 0.75,
})

local style = S.NewStyle(definition)


-- Creates an independent Style object.
S.NewStyle(table  definition) returns Style

local style = S.NewStyle({
    background  = "@button",
    textColor   = "@buttonText",
    fontSize    = 22,
    fixedWidth  = 200,
    fixedHeight = 46,
})


-- Returns true when a value is a Style created by this module.
S.IsStyle(value) returns boolean

local isStyle = S.IsStyle(style)


-- Converts a supported value into Style.
S.Coerce(Style or string or table  value) returns Style 

local fromStyle = S.Coerce(style)
local fromName = S.Coerce("button")

local fromDefinition = S.Coerce({
    fontSize = 22,
})


-- Registers a named style.
-- baseName inherits fields from another registered style.
S.DefineStyle(
    string name,
    table definition,
    string  baseName
) returns Style 

local accentButton = S.DefineStyle("accentButton", {
    background  = "@button",
    textColor   = "@buttonText",
    fixedHeight = 48,
    fontSize    = 22,
    alignment   = "MiddleCenter",
}, "button")


-- Returns a registered Style.
S.GetStyle(string name) returns Style 

local style = S.GetStyle("accentButton")


-- Changes one field of a registered Style.
-- Triggers S.OnChange.
S.SetStyleValue(
    string name,
    string field,
    value
) returns Style 

S.SetStyleValue(
    "accentButton",
    "fontSize",
    24
)


-- Applies a style to an existing UBUI target.
S.ApplyStyle(
    Element or Area target,
    Style or string or table style
) returns target

S.ApplyStyle(button, "accentButton")


-- Merges a base style with widget options.
-- Priority: base style, options.style, direct options.
S.Merge(
    Style or string or table style,
    table  options
) returns table

local options = S.Merge("button", {
    style    = "accentButton",
    fontSize = 26,
    w        = 220,
    h        = 48,
})


-- Returns an unresolved Style field.
-- nil returns the mutable internal definition.
Style:Raw(string field) returns any

local rawBackground = style:Raw("background")
local rawDefinition = style:Raw()


-- Returns a Style field after resolving @themeKey.
Style:Get(string field) returns any 

local background = style:Get("background")


-- Changes one Style field.
Style:Set(string field, value) returns Style

style:Set("fontSize", 24)


-- Changes multiple Style fields.
Style:SetAll(table definition) returns Style

style:SetAll({
    fontSize  = 24,
    textColor = "@text",
    alignment = "MiddleCenter",
})


-- Returns an independent Style copy.
Style:Copy() returns Style

local copiedStyle = style:Copy()

copiedStyle:Set("fontSize", 30)


-- Returns a copied Style with additional overrides.
Style:Extend(table definition) returns Style

local largeStyle = style:Extend({
    fixedHeight = 58,
    fontSize    = 28,
})


-- Returns an independent copy of the Style definition.
Style:Snapshot() returns table

local definition = style:Snapshot()

definition.fontSize = 30


-- Converts a Style into widget options.
-- Direct options override Style values.
Style:ToOpts(table  options) returns table

local buttonOptions = style:ToOpts({
    w     = 240,
    h     = 48,
    group = "controls",
    tags  = { "button", "interactive" },
})


-- Applies supported fields to an existing target.
Style:Apply(Element or Area target) returns target

style:Apply(button)


-- General Style fields.
Style fields:
    Vector4 or string background
    Vector4 or string textColor
    number or string fontSize
    string alignment
    boolean wordWrap
    number or string fixedWidth
    number or string fixedHeight
    boolean stretchWidth
    boolean stretchHeight
    number or string padding
    number or string spacing
    number or string margin
    boolean raycast
    boolean clipping


-- Image Style fields.
Style fields:
    string or number imageType
    string or number fillMethod
    number fillAmount
    boolean fillClockwise
    number fillOrigin
    boolean preserveAspect


-- Slider Style fields.
Style fields:
    Vector4 or string fillColor
    Vector4 or string bgColor
    Vector4 or string handleColor
    number or string handleWidth
    number or string handleHeight
    number or string trackHeight
    boolean handle
    boolean wholeNumbers


-- Input Style fields.
Style fields:
    number characterLimit


-- Color picker Style fields.
Style fields:
    Vector4 or string bgColor
    Vector4 or string applyColor
    Vector4 or string closeColor
    boolean gbColors
    number or string hueThickness
    boolean or string code
    number or string pickerScale
    string labelText
    Vector4 or string labelColor
    Vector4 or string labelTextColor


-- Style field to widget option mapping.
Style option mapping:
    background     returns color
    textColor      returns textColor
    fontSize       returns fontSize
    alignment      returns align
    wordWrap       returns wordWrap
    fixedWidth     returns w
    fixedHeight    returns h
    stretchWidth   returns stretchWidth
    stretchHeight  returns stretchHeight
    padding        returns padding
    spacing        returns spacing
    margin         returns indent
    raycast        returns raycast
    clipping       returns clipping
    fillColor      returns fillColor
    bgColor        returns bgColor
    handleColor    returns handleColor
    handleWidth    returns handleWidth
    handleHeight   returns handleHeight
    trackHeight    returns trackHeight
    handle         returns handle
    wholeNumbers   returns wholeNumbers
    characterLimit returns characterLimit
    applyColor     returns applyColor
    closeColor     returns closeColor
    gbColors       returns gbColors
    hueThickness   returns hueThickness
    code           returns code
    pickerScale    returns scale
    labelText      returns labelText
    labelColor     returns labelColor
    labelTextColor returns labelTextColor
    imageType      returns imageType
    fillMethod     returns fillMethod
    fillAmount     returns fillAmount
    fillClockwise  returns fillClockwise
    fillOrigin     returns fillOrigin
    preserveAspect returns preserveAspect


-- Direct Style application mapping.
Style direct application:
    background     returns target:SetColor
    textColor      returns target:SetTextColor
    fontSize       returns target:SetFontSize
    alignment      returns target:SetAlign
    wordWrap       returns target:SetWordWrap
    clipping       returns target:SetClipping
    fixedWidth     returns target:SetSize
    fixedHeight    returns target:SetSize
    padding        returns target layout padding
    spacing        returns target layout spacing


-- Direct slider Style application mapping.
Slider direct application:
    fillColor      returns target:SetSliderColors
    bgColor        returns target:SetSliderColors
    handleColor    returns target:SetHandleColor
    handleWidth    returns target:SetHandleWidth


-- Direct color picker Style application mapping.
Color picker direct application:
    bgColor        returns target:SetPickerBgColor
    applyColor     returns target:SetApplyColor
    closeColor     returns target:SetCloseColor
    gbColors       returns target:SetGBColors
    hueThickness   returns target:SetHueThickness
    code           returns target:SetCodeVisible
    pickerScale    returns target:SetPickerScale
    labelText      returns target:SetLabelText
    labelColor     returns target:SetLabelColor
    labelTextColor returns target:SetLabelTextColor


-- Creation-only fields are emitted by Style:ToOpts.
-- They are not reapplied directly by Style:Apply.
Creation-only Style fields:
    stretchWidth
    stretchHeight
    raycast
    imageType
    fillMethod
    fillAmount
    fillClockwise
    fillOrigin
    preserveAspect
    handle
    handleHeight
    trackHeight
    wholeNumbers
    characterLimit


-- Creates a Style using theme references.
local themedStyle = S.NewStyle({
    background = "@button",
    textColor  = "@buttonText",
    fontSize   = "@fontSize",
    padding    = "@padding",
    spacing    = "@spacing",
})


-- Creates and resolves a theme reference chain.
S.SetThemeValue(
    "accent",
    Vector4.New(0.55, 0.63, 1, 1)
)

S.SetThemeValue("primaryButton", "@accent")

local resolved = S.Resolve("@primaryButton")


-- Uses a boolean theme reference.
S.SetThemeValue("showColorCode", true)

local pickerStyle = S.NewStyle({
    code = "@showColorCode",
})


-- Creates a clipping Style.
local clippedAreaStyle = S.NewStyle({
    clipping = true,
    padding  = 10,
    spacing  = 6,
})


-- Defines a complete custom button Style.
S.DefineStyle("primaryButton", {
    background  = "@button",
    textColor   = "@buttonText",
    fontSize    = "@fontSize",
    alignment   = "MiddleCenter",
    fixedHeight = 48,
    wordWrap    = false,
}, "button")


-- Defines an image fill Style.
S.DefineStyle("radialImage", {
    background     = "@texture",
    imageType      = "filled",
    fillMethod     = "radial360",
    fillAmount     = 0.75,
    fillClockwise  = true,
    fillOrigin     = 0,
    preserveAspect = true,
}, "image")


-- Defines a slider Style.
S.DefineStyle("accentSlider", {
    fillColor    = "@sliderFill",
    bgColor      = "@sliderBg",
    handleColor  = "@sliderHandle",
    handleWidth  = 18,
    handleHeight = 28,
    trackHeight  = 8,
    handle       = true,
    wholeNumbers = false,
}, "slider")


-- Defines a color picker Style.
S.DefineStyle("accentPicker", {
    bgColor       = "@pickerBg",
    applyColor    = "@pickerApply",
    closeColor    = "@pickerClose",
    hueThickness  = "@pickerHue",
    pickerScale   = 1,
    code          = true,
    labelText     = "<b>Select color</b>",
    labelTextColor = "@text",
}, "colorpicker")


-- Built-in registered themes.
Built-in themes:
    string dark
    string light

S.SetTheme("dark")
S.SetTheme("light")


-- Built-in registered styles.
Built-in styles:
    string image
    string text
    string label
    string button
    string toggle
    string input
    string slider
    string colorpicker
    string area
    string title
    string close
    string scrollview

local buttonStyle = S.GetStyle("button")
local pickerStyle = S.GetStyle("colorpicker")
local areaStyle = S.GetStyle("area")


-- Numeric fields must resolve to finite numbers.
Finite numeric Style fields:
    fontSize
    fixedWidth
    fixedHeight
    handleWidth
    hueThickness
    pickerScale
    padding
    spacing


-- Invalid numeric values are ignored during direct application.
local invalidStyle = S.NewStyle({
    fontSize = "not a number",
})


-- The color picker code field must resolve to boolean.
local codeVisibleStyle = S.NewStyle({
    code = true,
})


-- Clipping must resolve to boolean.
local clippingStyle = S.NewStyle({
    clipping = true,
})


-- Theme references may point to other references.
S.SetThemeValue("accent", S.Colors.purple)
S.SetThemeValue("controlBackground", "@accent")

local controlStyle = S.NewStyle({
    background = "@controlBackground",
})


-- Missing references return nil.
local missing = S.Resolve("@missingThemeValue")


-- Cyclic references return nil.
S.SetThemeValue("cycleA", "@cycleB")
S.SetThemeValue("cycleB", "@cycleA")

local cyclic = S.Resolve("@cycleA")


-- Style merging uses three priority levels.
local merged = S.Merge("button", {
    style = "primaryButton",
    w = 240,
    h = 52,
    fontSize = 26,
})


-- Plain tables are copied by public mutation methods.
local sourceDefinition = {
    fontSize = 22,
    metadata = {
        category = "controls",
    },
}

local copiedStyle = S.NewStyle(sourceDefinition)

sourceDefinition.fontSize = 30
sourceDefinition.metadata.category = "changed"


-- Style:Raw returns mutable internal data.
local raw = copiedStyle:Raw()

raw.fontSize = 26


-- Style:Snapshot returns independent data.
local snapshot = copiedStyle:Snapshot()

snapshot.fontSize = 32


-- Apply a named style through UBUI.
local button = area:Button("Apply", function(element)
    Debug.Log(
        "Applied"
    )
end, {
    style = "primaryButton",
})


-- Apply a Style through UBUI.
local rStyle = S.NewStyle({
    background = Vector4.New(0.35, 0.42, 1, 1),
    textColor  = S.Colors.white,
    alignment  = "MiddleCenter",
})

button:SetStyle(rStyle)


-- Change the active theme.
S.SetTheme("light")

Debug.Log(
    "Light theme activated"
)


-- Change a registered style.
S.SetStyleValue(
    "primaryButton",
    "fontSize",
    24
)
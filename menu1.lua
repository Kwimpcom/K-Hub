local menu = {}

--//================================================================================--
--//      Virtual Key Codes (for readability)
--//================================================================================--
local VK = {
    INSERT = 0x2D,
    UP = 0x26,
    DOWN = 0x28,
    LEFT = 0x25,
    RIGHT = 0x27,
    RETURN = 0x0D -- The Enter key
}

--//================================================================================--
--//      Configuration & Theme
--//================================================================================--
menu.theme = {
    background = { 0.1, 0.1, 0.1, 0.95 },
    title_bar = { 0.15, 0.15, 0.15, 1.0 },
    outline = { 0.3, 0.3, 0.3, 1.0 },
    text = { 1.0, 1.0, 1.0, 1.0 },
    tab_inactive = { 0.18, 0.18, 0.18, 1.0 },
    tab_active = { 0.25, 0.25, 0.25, 1.0 },
    control_background = { 0.2, 0.2, 0.2, 1.0 },
    control_selected = { 0.4, 0.6, 1.0, 1.0 } -- Accent color for selection
}

--//================================================================================--
--//      Internal State
--//================================================================================--
menu.windows = {}
menu.visible = true -- Show the menu by default
menu.key_state = {}
menu.last_key_state = {}

--//================================================================================--
--//      Private Helper Functions
--//================================================================================--
local function was_key_pressed(key)
    return menu.key_state[key] and not menu.last_key_state[key]
end

local function unpack_color(color)
    return color[1], color[2], color[3], color[4]
end

--//================================================================================--
--//      Drawing Functions
--//================================================================================--
local function draw_window(win)
    if not win.visible then return end

    -- Main background and outline
    valex.draw_filled_rect(win.x, win.y, win.w, win.h, unpack_color(menu.theme.background))
    valex.draw_rect(win.x, win.y, win.w, win.h, unpack_color(menu.theme.outline))

    -- Title bar
    valex.draw_filled_rect(win.x, win.y, win.w, 30, unpack_color(menu.theme.title_bar))
    local title_w, title_h = valex.get_text_size(win.title)
    valex.draw_text(win.title, win.x + (win.w / 2) - (title_w / 2), win.y + 15 - (title_h / 2), unpack_color(menu.theme.text))

    -- Tabs
    if #win.tabs > 0 then
        local tab_x = win.x + 5
        for i, tab in ipairs(win.tabs) do
            local color = (win.active_tab_index == i) and menu.theme.tab_active or menu.theme.tab_inactive
            valex.draw_filled_rect(tab_x, win.y + 35, tab.w, tab.h, unpack_color(color))
            local tab_text_w, tab_text_h = valex.get_text_size(tab.title)
            valex.draw_text(tab.title, tab_x + (tab.w / 2) - (tab_text_w / 2), win.y + 35 + (tab.h / 2) - (tab_text_h / 2), unpack_color(menu.theme.text))
            tab_x = tab_x + tab.w + 5
        end

        -- Controls for the active tab
        local active_tab = win.tabs[win.active_tab_index]
        if active_tab and #active_tab.controls > 0 then
            for i, control in ipairs(active_tab.controls) do
                local is_selected = (active_tab.selected_control_index == i)
                control:render(win.x, win.y, is_selected)
            end
        end
    end
end

--//================================================================================--
--//      Control Templates
--//================================================================================--
local Button = {}
Button.__index = Button
function Button:new(props)
    local obj = setmetatable({}, Button)
    obj.title = props.title or "Button"
    obj.x = props.x or 10
    obj.y = props.y or 10
    obj.w = props.w or 100
    obj.h = props.h or 25
    obj.callback = props.callback or function() print(obj.title .. " pressed.") end
    return obj
end

function Button:render(win_x, win_y, is_selected)
    local abs_x, abs_y = win_x + self.x, win_y + self.y
    valex.draw_filled_rect(abs_x, abs_y, self.w, self.h, unpack_color(menu.theme.control_background))
    if is_selected then
        valex.draw_rect(abs_x, abs_y, self.w, self.h, unpack_color(menu.theme.control_selected), 2.0)
    end
    local text_w, text_h = valex.get_text_size(self.title)
    valex.draw_text(self.title, abs_x + (self.w / 2) - (text_w / 2), abs_y + (self.h / 2) - (text_h / 2), unpack_color(menu.theme.text))
end

function Button:activate()
    self.callback()
end

local Toggle = {}
Toggle.__index = Toggle
function Toggle:new(props)
    local obj = setmetatable({}, Toggle)
    obj.title = props.title or "Toggle"
    obj.x = props.x or 10
    obj.y = props.y or 10
    obj.w = 15
    obj.h = 15
    obj.toggled = props.default or false
    obj.callback = props.callback or function(state) print(obj.title .. " toggled to " .. tostring(state)) end
    return obj
end

function Toggle:render(win_x, win_y, is_selected)
    local abs_x, abs_y = win_x + self.x, win_y + self.y
    valex.draw_filled_rect(abs_x, abs_y, self.w, self.h, unpack_color(menu.theme.control_background))
    if is_selected then
        valex.draw_rect(abs_x, abs_y, self.w, self.h, unpack_color(menu.theme.control_selected), 2.0)
    end
    if self.toggled then
        valex.draw_filled_rect(abs_x + 3, abs_y + 3, self.w - 6, self.h - 6, unpack_color(menu.theme.control_selected))
    end
    local _, text_h = valex.get_text_size(self.title)
    valex.draw_text(self.title, abs_x + self.w + 10, abs_y + (self.h / 2) - (text_h / 2), unpack_color(menu.theme.text))
end

function Toggle:activate()
    self.toggled = not self.toggled
    self.callback(self.toggled)
end

--//================================================================================--
--//      Public API
--//================================================================================--
function menu:CreateWindow(props)
    local new_window = {
        title = props.title or "Window",
        w = props.width or 300,
        h = props.height or 400,
        x = props.x or 100,
        y = props.y or 100,
        visible = true,
        tabs = {},
        active_tab_index = 1
    }
    table.insert(self.windows, new_window)
    return new_window
end

function menu:AddTab(parent_window, props)
    local new_tab = {
        title = props.title or "Tab",
        w = props.width or 80,
        h = props.height or 25,
        controls = {},
        selected_control_index = 1
    }
    table.insert(parent_window.tabs, new_tab)
    return new_tab
end

function menu:AddButton(parent_tab, props)
    table.insert(parent_tab.controls, Button:new(props))
end

function menu:AddToggle(parent_tab, props)
    table.insert(parent_tab.controls, Toggle:new(props))
end

--//================================================================================--
--//      Main Loop Handlers
--//================================================================================--
function menu:Update()
    -- Copy current key state to last state
    self.last_key_state = {}
    for k, v in pairs(self.key_state) do
        self.last_key_state[k] = v
    end

    -- Update key states for debouncing
    self.key_state = {}
    for _, key_code in pairs(VK) do
        self.key_state[key_code] = valex.is_key_pressed(key_code)
    end

    -- Toggle menu visibility
    if was_key_pressed(VK.INSERT) then
        self.visible = not self.visible
    end

    if not self.visible then 
        return 
    end

    -- For now, we only handle the first window. Multi-window support could be added.
    local active_window = self.windows[1]
    if not active_window or #active_window.tabs == 0 then 
        return 
    end
    
    local active_tab = active_window.tabs[active_window.active_tab_index]
    if not active_tab or #active_tab.controls == 0 then
        return
    end

    -- NAV: UP/DOWN to change selected control
    if was_key_pressed(VK.DOWN) then
        active_tab.selected_control_index = active_tab.selected_control_index + 1
        if active_tab.selected_control_index > #active_tab.controls then
            active_tab.selected_control_index = 1 -- Wrap around
        end
    elseif was_key_pressed(VK.UP) then
        active_tab.selected_control_index = active_tab.selected_control_index - 1
        if active_tab.selected_control_index < 1 then
            active_tab.selected_control_index = #active_tab.controls -- Wrap around
        end
    end

    -- NAV: LEFT/RIGHT to change active tab
    if was_key_pressed(VK.RIGHT) then
        active_window.active_tab_index = active_window.active_tab_index + 1
        if active_window.active_tab_index > #active_window.tabs then
            active_window.active_tab_index = 1 -- Wrap around
        end
    elseif was_key_pressed(VK.LEFT) then
        active_window.active_tab_index = active_window.active_tab_index - 1
        if active_window.active_tab_index < 1 then
            active_window.active_tab_index = #active_window.tabs -- Wrap around
        end
    end

    -- ACTION: ENTER to activate selected control
    if was_key_pressed(VK.RETURN) then
        local selected_control = active_tab.controls[active_tab.selected_control_index]
        if selected_control and selected_control.activate then
            selected_control:activate()
        end
    end
end

function menu:Render()
    if not self.visible then return end
    for _, win in ipairs(self.windows) do
        draw_window(win)
    end
end

function menu:Init()
    valex.register("update", function() self:Update() end)
    valex.register("render", function() self:Render() end)
    print("Keyboard UI Initialized. Press INSERT to toggle.")
end

return menu

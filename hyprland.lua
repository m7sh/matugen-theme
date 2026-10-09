-- Matugen Hyprland appearance for Omarchy
-- Subtle frosted glass border outline & refined 6px rounding
local active_border_color = { colors = { "rgba(c5cc7a77)", "rgba(ffffff33)" }, angle = 45 }
local inactive_border_color = "rgba(ffffff18)"

hl.config({
  general = {
    border_size = 1,
    gaps_in = 0,
    gaps_out = 0,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  decoration = {
    rounding = 6,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = false,
    },
    blur = {
      enabled = false,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})

-- Dynamic Mode: rounded floating windows (dialogs, modals, pickers)
hl.window_rule({
  name = "matugen-floating-rounding",
  match = { float = true },
  rounding = 8,
})

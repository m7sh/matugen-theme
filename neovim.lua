return {
  {
    "omacom/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#13140c",
        dark_bg = "#1c1c14",
        darker_bg = "#0e0f08",
        lighter_bg = "#2a2a22",

        fg = "#e5e3d6",
        dark_fg = "#c8c7b7",
        light_fg = "#e5e3d6",
        bright_fg = "#e5e3d6",
        muted = "#929182",

        red = "#ffb3b3",
        yellow = "#d6c871",
        orange = "#fcb974",
        green = "#b1d18a",
        cyan = "#8ad6b7",
        blue = "#99ccfa",
        magenta = "#e6b6f1",
        brown = "#ffb77e",

        bright_red = "#ffdcdc",
        bright_yellow = "#dfd491",
        bright_green = "#c5dda7",
        bright_cyan = "#a8e1ca",
        bright_blue = "#c0dffc",
        bright_magenta = "#f2d8f8",

        accent = "#c5cc7a",
        cursor = "#e5e3d6",
        foreground = "#e5e3d6",
        background = "#13140c",
        selection = "#454b04",
        selection_foreground = "#e1e993",
        selection_background = "#454b04",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}

-- GitHub Copilot AI pair programmer
-- Docs: https://github.com/zbirenbaum/copilot.lua
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  build = ":Copilot auth",            -- trigger login after install
  opts = {
    suggestion = { enabled = true },  -- inline suggestions
    panel      = { enabled = true }   -- suggestion panel
  }
}
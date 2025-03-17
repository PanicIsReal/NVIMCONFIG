local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- Set global indentation to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = false
vim.o.scrolloff = 10
vim.o.background = 'dark'
vim.opt.number = true

-- Filetype-specific indentation for TypeScript, JavaScript, TSX, and JSON
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact", "json" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
    vim.bo.softtabstop = 2
  end,
})

require("lazy").setup({
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  "nvim-lua/plenary.nvim",
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    config = function()
      require("telescope").setup {}
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({})
    end,
  },
  {
    "b0o/incline.nvim",
    dependencies = { "craftzdog/solarized-osaka.nvim" },
    event = "BufReadPre",
    priority = 1200,
    config = function()
      local colors = require("solarized-osaka.colors").setup()
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = colors.magenta500, guifg = colors.base04 },
            InclineNormalNC = { guifg = colors.violet500, guibg = colors.base03 },
          },
        },
        window = { margin = { vertical = 0, horizontal = 1 } },
        hide = {
          cursorline = true,
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
          end
  
          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = color }, { " " }, { filename } }
        end,
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },
  {
    "folke/noice.nvim",
    config = function()
      require("noice").setup({
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help
        },
      })
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      local original_ui_select = vim.ui.select
      vim.ui.select = function(items, opts, on_choice)
        if opts.prompt and opts.prompt:match("Select a file") and vim.fn.getline('.'):match('#file:') then
          require("telescope.builtin").find_files({
            prompt_title = "Select a file",
            cwd = vim.fn.getcwd(),
            attach_mappings = function(prompt_bufnr, map)
              require("telescope.actions").select_default:replace(function()
                local selection = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr)
                if selection then
                  on_choice(selection[1])
                else
                  on_choice(nil)
                end
              end)
              return true
            end,
          })
        else
          original_ui_select(items, opts, on_choice)
        end
      end
    end,
  },
  "nvim-tree/nvim-web-devicons",
  "neovim/nvim-lspconfig",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer", -- Optional: for buffer completions
  "hrsh7th/cmp-path", -- Optional: for path completions
  "tpope/vim-fugitive",
  {
    "kyazdani42/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 35,
          side = "left",
        },
        filters = {
          dotfiles = false, -- Show dotfiles (optional tweak from earlier)
        },
        git = {
          ignore = false, -- Show git-ignored files (from earlier)
        },
        renderer = {
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
            glyphs = { -- Optional: Customize icons if needed
              default = "",
              symlink = "",
              folder = {
                default = "",
                open = "",
              },
            },
          },
        },
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require('lualine').setup {
        options = { theme = 'auto' },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        }
      }
    end
  },
  {
    "zbirenbaum/copilot.lua",
    config = function()
      require("copilot").setup({
        panel = {
          enabled = true,
          auto_refresh = false,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<M-CR>",
          },
          layout = {
            position = "bottom", -- | top | left | right | horizontal | vertical
            ratio = 0.4,
          },
        },
        suggestion = {
          enabled = true,
          auto_trigger = false,
        },
        filetypes = {
          typescript = true,
          javascript = true,
          ["*"] = false,
        },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      model = 'gpt-4o',
      prompts = {
        file = {
          prompt = '#file:',
          picker = function()
            local cwd = vim.fn.getcwd()
            local telescope = require("telescope.builtin")
            telescope.find_files({
              cwd = cwd,
              hidden = true,
              -- file_ignore_patterns = { "%.git/", "node_modules/" },
            })
          end,
        },
      },
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
  },
  "HiPhish/rainbow-delimiters.nvim",
  "sbdchd/neoformat",
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin"
      require("catppuccin").setup({
        transparent_background = true,
      })
    end,
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = true
  }
})

-- nvim-cmp setup
local cmp = require("cmp")
cmp.setup {
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
  mapping = {
    ["<C-Space>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete()
      end
    end, { "i", "s" }),
    ["<C-S-Up>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<C-S-Down>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Insert,
    }),
    ["<C-e>"] = cmp.mapping.abort(),
  },
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  experimental = {
    ghost_text = false,
  },
}

-- LSP Configuration
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.ts_ls.setup {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    if client.server_capabilities.semanticTokensProvider then
      local semantic = client.config.capabilities.textDocument.semanticTokens
      semantic.requested = true
    end
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
}

-- Neoformat configuration
-- vim.g.neoformat_typescript_prettier = {
--   exe = "prettier",
--   args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
--   stdin = 1,
-- }
-- vim.g.neoformat_javascript_prettier = {
--   exe = "prettier",
--   args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
--   stdin = 1,
-- }
-- vim.g.neoformat_typescriptreact_prettier = {
--   exe = "prettier",
--   args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
--   stdin = 1,
-- }
-- vim.g.neoformat_json_prettier = {
--   exe = "prettier",
--   args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
--   stdin = 1,
-- }
-- vim.g.neoformat_enabled_typescript = {"prettier"}
-- vim.g.neoformat_enabled_javascript = {"prettier"}
-- vim.g.neoformat_enabled_typescriptreact = {"prettier"}
-- vim.g.neoformat_enabled_json = {"prettier"}

-- Telescope keybindings
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", function()
  telescope.find_files({
    hidden = true,
    file_ignore_patterns = { "%.git/", "node_modules/" },
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<C-v>", function()
        local action_state = require("telescope.actions.state")
        local selection = action_state.get_selected_entry()
        if selection then
          require("telescope.actions").select_vertical(prompt_bufnr)
        end
      end)
      map("i", "<C-h>", function()
        local action_state = require("telescope.actions.state")
        local selection = action_state.get_selected_entry()
        if selection then
          require("telescope.actions").select_horizontal(prompt_bufnr)
        end
      end)
      return true
    end,
  })
end, { desc = "Telescope: Find Files" })
vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Telescope: Buffers" })
vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Telescope: Live Grep" })
vim.keymap.set("n", "<leader>t", ":below 10split | terminal<CR>", { desc = "Open terminal below" })

-- Copilot
vim.keymap.set("i", "<C-\\>", function()
  require("copilot.suggestion").toggle_auto_trigger()
  if require("copilot.suggestion").is_visible() then
    require("copilot.suggestion").dismiss()
  else
    require("copilot.suggestion").next() -- Trigger the next suggestion
  end
end, { desc = "Toggle/Trigger Copilot suggestion" })

-- lsp
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    wrap = true,
    max_width = 80,
    border = "rounded",
  }
)

-- Enable wrapping for diagnostic popups
vim.diagnostic.config({
  float = {
    wrap = true,
    max_width = 80,
    border = "rounded",
    source = "always",
  },
})

-- Keybinding to show diagnostics in a floating window
vim.keymap.set("n", "<leader>dd", function()
  vim.diagnostic.open_float(nil, {
    scope = "line", -- Show diagnostics for the current line
    border = "rounded", -- Optional: Add a border for better visibility
    max_width = 80, -- Ensure the window doesn't run off the screen
    max_height = 20, -- Limit the height of the window
    focusable = true, -- Allow scrolling/interaction
    source = "always", -- Show the source of the diagnostic (e.g., ts_ls)
  })
end, { desc = "toggles local troubleshoot" })

vim.g.copilot_enabled = 0
vim.cmd("Copilot disable")

-- New tab
vim.keymap.set("n", "te", ":tabedit")
vim.keymap.set("n", "<tab>", ":tabnext<Return>")
vim.keymap.set("n", "<s-tab>", ":tabprev<Return>")

-- Split Window
vim.keymap.set("n", "ss", ":split<Return>")
vim.keymap.set("n", "sv", ":vsplit<Return>")

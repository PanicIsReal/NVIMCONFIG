-- Bootstrap lazy.nvim ---------------------------------------------------------
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

-- Core UI / editor options ----------------------------------------------------
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = false
vim.opt.splitright = true
vim.opt.foldenable = true
vim.opt.foldlevelstart = 99
vim.o.scrolloff = 999
vim.o.background = 'dark'
vim.o.relativenumber = true
vim.opt.foldcolumn = "auto:1"
vim.opt.number = true

-- Filetype-specific indentation for TS/JS/TSX/JSON ---------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact", "json" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
    vim.bo.softtabstop = 2
  end,
})

-- Plugins via lazy.nvim -------------------------------------------------------
require("lazy").setup({
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = { border = "Normal", background = "Normal" },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "javascript", "typescript", "tsx", "json", "python" },
        highlight = { enable = true },
        fold = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
            },
          },
        },
      })
    end,
  },
  "ojroques/vim-oscyank",
  "nvim-lua/plenary.nvim",
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    config = function() require("telescope").setup {} end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function() require('nvim-autopairs').setup({}) end,
  },
  {
    "folke/noice.nvim",
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          signature = { enabled = true, auto_open = true },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
        views = {
          popupmenu = {
            relative = "editor",
            position = { row = 8, col = "50%" },
            size = { width = 60, height = 10 },
            border = { style = "rounded", padding = { 0, 1 } },
          },
        },
      })
    end,
    dependencies = { "rcarriga/nvim-notify" },
  },
  {
    "b0o/incline.nvim",
    dependencies = {
      "catppuccin/nvim",
      "nvim-tree/nvim-web-devicons",
    },
    event = "BufReadPre",
    priority = 1200,
    config = function()
      local catppuccin = require("catppuccin.palettes").get_palette()
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = catppuccin.pink, guifg = catppuccin.base },
            InclineNormalNC = { guibg = catppuccin.surface1, guifg = catppuccin.lavender },
          },
        },
        window = { margin = { vertical = 1, horizontal = 1 } },
        hide = { cursorline = true },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if vim.bo[props.buf].modified then filename = "[+] " .. filename end
          local icon, color = require("nvim-web-devicons").get_icon_color(filename)
          return { { icon, guifg = color }, { " " }, { filename } }
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = { options = { mode = "tabs", show_buffer_close_icons = false, show_close_icon = false } },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 2000,
      stages = "fade_in_slide_out",
      render = "default",
      background_colour = "#000000",
      on_open = function(win) vim.api.nvim_win_set_config(win, { focusable = false }) end,
    },
    config = function(_, opts) require("notify").setup(opts); vim.notify = require("notify") end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      local telescope_ui = require("telescope")
      telescope_ui.load_extension("ui-select")
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
                if selection then on_choice(selection[1]) else on_choice(nil) end
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
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  {
    "kyazdani42/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 35, side = "left" },
        filters = { dotfiles = false, custom = { "^tests$" } },
        git = { ignore = false },
        renderer = {
          icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true },
            glyphs = {
              default = "",
              symlink = "",
              folder = { default = "", open = "" },
            },
          },
        },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim", -- already added above; harmless if duplicated in lazy merges
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
          keymap = { jump_prev = "[[", jump_next = "]]", accept = "<CR>", refresh = "gr", open = "S-CR" },
          layout = { position = "bottom", ratio = 0.4 },
        },
        suggestion = { enabled = true, auto_trigger = false },
        filetypes = { typescript = true, javascript = true, ["*"] = false },
      })
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      model = 'gpt-5',
      prompts = {
        file = {
          prompt = '#file:',
          picker = function()
            local cwd = vim.fn.getcwd()
            local telescope = require("telescope.builtin")
            telescope.find_files({ cwd = cwd, hidden = true, file_ignore_patterns = { "%.git/", "node_modules/", "tests/" } })
          end,
        },
        Explainer = { prompt = 'Explain how it works', system_prompt = 'You are very good at explaining stuff', mapping = '<leader>ccce', description = 'Explainer' },
        Optimizer = { prompt = 'Optimize the code, reduce and redundancy and improve readability, simplify any functions as long as it doesnt hinder readability', system_prompt = 'You specialize in assiting with coding', mapping = '<leader>ccco', description = 'Optimizes code.' },
        TypeErrorCorrect = { prompt = 'I have a Type Error in this code, can you correct it?', system_prompt = 'You specialize in assiting with coding, especially with TypeScript', mapping = '<leader>cccte', description = 'Attempts to identify and correct type issues.' },
        CommentGenerator = { prompt = 'I need you to generate comments for all methods/functions/classes that follows TypeScript standards', system_prompt = 'You specialize in assiting with coding, especially with TypeScript', mapping = '<leader>cccg', description = 'Attempts to generate comments for all method/functions in the code' },
        CodeAssistant = { prompt = 'I need assistance with this problem.', system_prompt = 'You are a professional coder, with a masters knowledge in TypeScript, and JavaScript/Node, you take all passed in files into account to help make well informed decisions', mapping = '<leader>ccca', description = 'Assists in programming' },
      },
    },
    config = function(_, opts) require("CopilotChat").setup(opts) end,
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
        flavour = "auto",
        background = { light = "latte", dark = "mocha" },
        transparent_background = false,
        float = { transparent = true, solid = true },
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
        },
        lsp_styles = {
          virtual_text = { errors = { "italic" }, hints = { "italic" }, warnings = { "italic" }, information = { "italic" }, ok = { "italic" } },
          underlines = { errors = { "underline" }, hints = { "underline" }, warnings = { "underline" }, information = { "underline" }, ok = { "underline" } },
          inlay_hints = { background = true },
        },
        default_integrations = true,
        auto_integrations = false,
        integrations = { cmp = true, gitsigns = true, nvimtree = true, notify = false, mini = { enabled = true, indentscope_color = "" } },
      })
    end,
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = true,
  },
  { "tpope/vim-commentary" },
})

-- nvim-cmp setup --------------------------------------------------------------
local cmp = require("cmp")
cmp.setup({
  sources = { { name = "nvim_lsp" }, { name = "buffer" }, { name = "path" } },
  mapping = {
    ["<C-Space>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item() else cmp.complete() end
    end, { "i", "s" }),
    ["<C-S-Up>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end, { "i", "s" }),
    ["<C-S-Down>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item() else fallback() end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
    ["<C-e>"] = cmp.mapping.abort(),
  },
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  experimental = { ghost_text = false },
})

-- LSP Configuration -----------------------------------------------------------
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- NOTE: Neovim 0.10 offers vim.lsp.config; if on 0.9.x, use lspconfig.tsserver
pcall(function()
  vim.lsp.config('ts_ls', {
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
      vim.keymap.set("n", "<leader>ai", function()
        vim.lsp.buf.code_action({ context = { only = {"source.addMissingImports.ts"} }, apply = true })
      end, { buffer = bufnr, desc = "Auto-import missing TypeScript imports" })
      vim.keymap.set("i", "<C-j>", vim.lsp.buf.signature_help, opts)
      vim.keymap.set("i", "<C-n>", function() vim.lsp.buf.signature_help({ next = true }) end, opts)
      vim.keymap.set("i", "<C-p>", function() vim.lsp.buf.signature_help({ prev = true }) end, opts)
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
  })
end)

-- Telescope keymaps -----------------------------------------------------------
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<C-p>", function()
  telescope.find_files({
    hidden = true,
    file_ignore_patterns = { "%.git/", "node_modules/" },
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<C-v>", function()
        local action_state = require("telescope.actions.state")
        local selection = action_state.get_selected_entry()
        if selection then require("telescope.actions").select_vertical(prompt_bufnr) end
      end)
      map("i", "<C-h>", function()
        local action_state = require("telescope.actions.state")
        local selection = action_state.get_selected_entry()
        if selection then require("telescope.actions").select_horizontal(prompt_bufnr) end
      end)
      return true
    end,
  })
end, { desc = "Telescope: Find Files" })

vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Telescope: Buffers" })
vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Telescope: Live Grep" })
vim.keymap.set("n", "<leader>t", ":below 10split | terminal<CR>", { desc = "Open terminal below" })

-- Copilot toggler -------------------------------------------------------------
vim.keymap.set("i", "<C-\\>", function()
  require("copilot.suggestion").toggle_auto_trigger()
  if require("copilot.suggestion").is_visible() then
    require("copilot.suggestion").dismiss()
  else
    require("copilot.suggestion").next()
  end
end, { desc = "Toggle/Trigger Copilot suggestion" })

-- LSP hover/diagnostic UI -----------------------------------------------------
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { wrap = true, max_width = 80, border = "rounded" })

vim.diagnostic.config({
  float = { wrap = true, max_width = 80, border = "rounded", source = "always" },
})

vim.keymap.set("n", "<leader>dd", function()
  vim.diagnostic.open_float(nil, { scope = "line", border = "rounded", max_width = 80, max_height = 20, focusable = true, source = "always" })
end, { desc = "toggles local troubleshoot" })

-- Tabs, splits, neogit --------------------------------------------------------
vim.keymap.set("n", "te", ":tabedit")
vim.keymap.set("n", "<tab>", ":tabnext<Return>")
vim.keymap.set("n", "<s-tab>", ":tabprev<Return>")
vim.keymap.set("n", "ss", ":split<Return>")
vim.keymap.set("n", "sv", ":vsplit<Return>")
vim.keymap.set("n", "<leader>ng", ":Neogit<Return>")

-- Commentary
vim.keymap.set('n', '<leader>/', 'gcc', { remap = true })
vim.keymap.set('v', '<leader>/', 'gc', { remap = true })

-- Close floating windows in insert mode
vim.keymap.set("i", "<C-h>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
end, { desc = "Close floating windows in insert mode" })

-- NvimTree & resizing
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle NVIM Tree" })
vim.keymap.set('n', '<M-S-Up>', ':resize +1<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-S-Down>', ':resize -1<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-S-Right>', ':vertical resize +1<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-S-Left>', ':vertical resize -1<CR>', { noremap = true, silent = true })

-- OSCYank
vim.api.nvim_set_keymap('n', '<leader>c', '<Plug>OSCYankOperator', { noremap = true, silent = true, desc = 'OSCYank: Yank with operator' })
vim.api.nvim_set_keymap('n', '<leader>cc', '<leader>c_', { noremap = true, silent = true, desc = 'OSCYank: Yank current line' })
vim.keymap.set({'n', 'v'}, '<leader>gh', function() require('CopilotChat').open() end, { noremap = true, silent = true, desc = 'Open Copilot Chat' })
vim.api.nvim_set_keymap('x', '<leader>c', '<Plug>OSCYankVisual', { noremap = true, silent = true, desc = 'OSCYank: Yank visual selection' })

-- Terminal window navigation
vim.api.nvim_set_keymap('t', '<C-h>', '<C-\\><C-n><C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<C-j>', '<C-\\><C-n><C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<C-k>', '<C-\\><C-n><C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<C-l>', '<C-\\><C-n><C-w>l', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })

-- ===================== Robust Tree-sitter folding block =====================
local use_new_foldexpr = (vim.fn.has("nvim-0.10") == 1)
vim.opt.foldmethod = "expr"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldminlines = 1
vim.opt.foldexpr = use_new_foldexpr and "v:lua.vim.treesitter.foldexpr()" or "nvim_treesitter#foldexpr()"
vim.opt.foldcolumn = "1"

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "BufWritePost", "FileType", "InsertLeave", "FocusGained" }, {
  callback = function()
    pcall(vim.treesitter.start, 0)
    vim.cmd.normal({ args = { "zX" }, bang = true })
  end,
})

-- Compute folds once UI is up (first start)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      vim.api.nvim_win_call(win, function()
        pcall(vim.treesitter.start, 0)
        vim.cmd("silent! normal! zX")
      end)
    end
  end,
})

-- Reliable fold mappings (use :normal!)
vim.keymap.set("n", "<leader>fc", function() vim.cmd.normal({ args={"zc"}, bang=true }) end, { desc = "Fold close" })
vim.keymap.set("n", "<leader>fo", function() vim.cmd.normal({ args={"zo"}, bang=true }) end, { desc = "Fold open" })
vim.keymap.set("n", "<leader>ft", function() vim.cmd.normal({ args={"za"}, bang=true }) end, { desc = "Fold toggle" })
vim.keymap.set("n", "<leader>fM", function() vim.cmd.normal({ args={"zM"}, bang=true }) end, { desc = "Fold mass close" })
vim.keymap.set("n", "<leader>fR", function() vim.cmd.normal({ args={"zR"}, bang=true }) end, { desc = "Fold mass open" })
vim.keymap.set("n", "<leader>fr", function() vim.cmd.normal({ args={"zX"}, bang=true }) end, { desc = "Recompute folds" })

-- ================= CopilotChat helper: open with current file ===============
local function open_copilotchat_with_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then file = vim.fn.expand("%:p") end
  local ok, chat = pcall(require, "CopilotChat")
  if not ok then vim.notify("CopilotChat not installed", vim.log.levels.ERROR); return end
  chat.open()
  vim.defer_fn(function()
    if type(chat.append) == "function" then
      chat.append("#file: " .. file .. "\n")
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        local ft = vim.bo[buf].filetype
        if (name:match("CopilotChat") or name:match("copilot")) and (ft == "markdown" or ft == "copilot-chat") then
          vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "#file: " .. file, "" })
          break
        end
      end
    end
  end, 100)
end
vim.keymap.set("n", "<leader>gF", open_copilotchat_with_current_file, { desc = "CopilotChat: open with current file header" })

-- ========== Fold methods INSIDE class (keep class itself open) ==============
local function fold_methods_in_class()

  pcall(vim.treesitter.start, 0)
  vim.cmd.normal({ args = { "zX" }, bang = true })

  local ok_ts, ts = pcall(require, "vim.treesitter")
  if not ok_ts then vim.notify("nvim-treesitter not available", vim.log.levels.ERROR); return end

  local lang = vim.bo.filetype
  local ft_to_lang = { typescriptreact = "tsx" }
  lang = ft_to_lang[lang] or lang

  local parser = ts.get_parser(0, lang)
  if not parser then vim.notify("No parser for " .. tostring(lang), vim.log.levels.ERROR); return end

  local function get_node_at_cursor()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1
    local root = (parser:parse()[1]):root()
    return root:named_descendant_for_range(row, col, row, col)
  end

  local node = get_node_at_cursor()
  if not node then return end

  local class_types = { class_declaration = true, class_definition = true, class_specifier = true, class = true }
  while node and not class_types[node:type()] do node = node:parent() end
  if not node then vim.notify("No class found at cursor", vim.log.levels.WARN); return end

  local q_by_lang = {
    typescript = [[
      (class_declaration
        body: (class_body
          ((method_definition) @method)
          ((constructor) @method)))
    ]],
    tsx = [[
      (class_declaration
        body: (class_body
          ((method_definition) @method)
          ((constructor) @method)))
    ]],
    javascript = [[
      (class_declaration
        body: (class_body
          ((method_definition) @method)
          ((constructor) @method)))
    ]],
    python = [[
      (class_definition
        body: (block
          ((function_definition) @method)
          ((decorated_definition (function_definition) @method))))
    ]],
  }

  local Query = vim.treesitter.query
  local query
  do
    local src = q_by_lang[lang]
    if src then
      local ok, q = pcall(Query.parse, lang, src)
      if ok then query = q end
    end
  end

  local ranges = {}
  if query then
    for id, cap in query:iter_captures(node, 0, node:range()) do
      if cap then
        local t = cap:type()
        if t == "method_definition" or t == "constructor" or t == "function_definition" then
          local sr, _, er, _ = cap:range()
          table.insert(ranges, { sr + 1, er + 1 })
        end
      end
    end
  else
    local wanted = { method_definition = true, constructor = true, function_definition = true, decorated_definition = true }
    local function walk(n)
      if wanted[n:type()] then
        local sr, _, er, _ = n:range()
        table.insert(ranges, { sr + 1, er + 1 })
      end
      for child in n:iter_children() do walk(child) end
    end
    walk(node)
  end

  table.sort(ranges, function(a,b) return a[1] < b[1] end)
  local unique, last = {}, -1
  for _, r in ipairs(ranges) do if r[1] ~= last then table.insert(unique, r); last = r[1] end end
  ranges = unique

  if #ranges == 0 then vim.notify("No methods found to fold inside this class", vim.log.levels.INFO); return end

  for _, r in ipairs(ranges) do
    pcall(vim.cmd, string.format("%d,%dfoldclose", r[1], r[2]))
  end
end

vim.keymap.set("n", "<leader>cm", fold_methods_in_class, { desc = "Fold methods inside current class" })


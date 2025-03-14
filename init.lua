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
vim.opt.rtp:append("~/.local/share/nvim/lualib") -- Add custom Lua module path
package.cpath = package.cpath .. ";~/.local/share/nvim/lualib/?.so" -- Add to cpath

-- Set global indentation to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = false

-- Set clipboard to use system clipboard
vim.opt.clipboard = "unnamedplus"

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
      require("telescope").setup {
        defaults = {
          -- file_ignore_patterns = { "%.git/", "node_modules/" }, -- Commented out to test
          cache_picker = {
            enable = true,
            num_pickers = 10,
          },
        },
      }
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              cwd = vim.fn.getcwd(), -- Explicitly set CWD
            },
          },
        },
      }
      require("telescope").load_extension("ui-select")
    end,
  },
  -- Custom vim.ui.select override for CopilotChat #file:
  -- Note: Place this after telescope-ui-select to ensure proper override
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
  "neovim/nvim-lspconfig",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer", -- Optional: for buffer completions
  "hrsh7th/cmp-path", -- Optional: for path completions
  "tpope/vim-fugitive",
  "preservim/nerdtree",
  "nvim-lualine/lualine.nvim",
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = true },
        panel = {
          enabled = true,
          keymap = {
            accept = "<C-y>",
            next = "<C-n>",
            prev = "<C-p>",
            dismiss = "<C-e>",
          },
          layout = {
            position = "right",
            ratio = 0.4,
          },
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
    branch = "canary",
    dependencies = {
      "zbirenbaum/copilot.lua",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      local ok, copilot_chat = pcall(require, "CopilotChat")
      if not ok then
        vim.notify("CopilotChat not found: " .. copilot_chat, vim.log.levels.ERROR)
        return
      end
      local tiktoken_ok, tiktoken = pcall(require, "tiktoken_core")
      if tiktoken_ok then
        vim.notify("tiktoken_core loaded successfully", vim.log.levels.INFO)
      else
        vim.notify("tiktoken_core not found, using fallback token counting", vim.log.levels.WARN)
      end
      copilot_chat.setup {
        context = "workspace",
        mappings = {
          submit_prompt = "<Enter>",
          clear_chat = "<C-c>",
        },
      }
    end,
  },
  "HiPhish/rainbow-delimiters.nvim",
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin"
    end,
  },
  "sbdchd/neoformat",
})

-- nvim-cmp setup
local cmp = require("cmp")
cmp.setup {
  mapping = {
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.fn.getline('.'):match('#file:') then
        fallback() -- Allow CopilotChat to handle #file: without completion
      elseif vim.fn.getline('.') == '' then
        vim.api.nvim_put({string.rep(' ', vim.bo.shiftwidth)}, 'c', true, true) -- Insert shiftwidth spaces on empty line
      elseif vim.fn.getline('.'):sub(1, vim.fn.col('.') - 1) == '' then
        vim.api.nvim_put({string.rep(' ', vim.bo.shiftwidth)}, 'c', true, true) -- Insert shiftwidth spaces if no chars before cursor
      else
        cmp.complete() -- Trigger completion if chars exist before cursor
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept completion with Enter
    ['<C-e>'] = cmp.mapping.abort(), -- Close completion menu
    ['<C-Space>'] = cmp.mapping.complete(), -- Manually trigger completion
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
}

require("nvim-treesitter.configs").setup {
  ensure_installed = {"c", "lua", "vim", "python", "javascript", "typescript", "tsx", "json"},
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      node_decremental = "<S-space>",
    },
  },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = 1000,
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
  end,
}

-- Neoformat configuration
vim.g.neoformat_typescript_prettier = {
  exe = "prettier",
  args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
  stdin = 1,
}
vim.g.neoformat_javascript_prettier = {
  exe = "prettier",
  args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
  stdin = 1,
}
vim.g.neoformat_typescriptreact_prettier = {
  exe = "prettier",
  args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
  stdin = 1,
}
vim.g.neoformat_json_prettier = {
  exe = "prettier",
  args = {"--stdin-filepath", vim.fn.expand("%:p"), "--single-quote", "--trailing-comma", "es5"},
  stdin = 1,
}
vim.g.neoformat_enabled_typescript = {"prettier"}
vim.g.neoformat_enabled_javascript = {"prettier"}
vim.g.neoformat_enabled_typescriptreact = {"prettier"}
vim.g.neoformat_enabled_json = {"prettier"}

-- Leader keybinding to format the entire file (Prettier + reindent)
vim.keymap.set("n", "<leader>f", function()
  vim.cmd("Neoformat")
  vim.cmd("normal! gg=G")
  vim.cmd("write")
end, { desc = "Format File (Prettier + Reindent)" })

-- Auto-format on save for specific filetypes
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.json" },
  callback = function()
    vim.cmd("Neoformat")
  end,
})

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

-- Window navigation keybindings
local function set_window_keymap(lhs, rhs, desc)
  if rhs == nil then
    vim.notify("Invalid rhs for keymap: " .. lhs, vim.log.levels.ERROR)
    return
  end
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

set_window_keymap("<C-h>", "<C-w>h", "Move to Left Window")
set_window_keymap("<C-j>", "<C-w>j", "Move to Window Below")
set_window_keymap("<C-k>", "<C-w>k", "Move to Window Above")
set_window_keymap("<C-l>", "<C-w>l", "Move to Right Window")

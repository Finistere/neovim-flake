-- local llm = require('llm')

require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})

-- llm.setup({
--   model = "deepseek-coder-v2",
--   url = "http://localhost:11434",
--   backend = "ollama", -- backend ID, "huggingface" | "ollama" | "openai" | "tgi"
--   lsp = {
--     bin_path = vim.g.llm_path
--   },
--   -- tokens_to_clear = { "<|endoftext|>" }, -- tokens to remove from the model's output
--   -- parameters that are added to the request body, values are arbitrary, you can set any field:value pair here it will be passed as is to the backend
--   request_body = {
--     system = "You're a code assistant. Provide the appropriate missing code without any Mardown wrapping, only the raw code.",
--   },
--   context_window = 16 * 1024,
--   -- debounce_ms = 150,
--   -- accept_keymap = "<Tab>",
--   -- dismiss_keymap = "<S-Tab>",
--   -- tls_skip_verify_insecure = false,
--   -- -- llm-ls configuration, cf llm-ls section
--   -- lsp = {
--   --   bin_path = nil,
--   --   host = nil,
--   --   port = nil,
--   --   cmd_env = nil, -- or { LLM_LOG_LEVEL = "DEBUG" } to set the log level of llm-ls
--   --   version = "0.5.3",
--   -- },
--   -- tokenizer = nil,                     -- cf Tokenizer paragraph
--   -- context_window = 1024,               -- max number of tokens for the context window
--   -- enable_suggestions_on_startup = true,
--   -- enable_suggestions_on_files = "*",   -- pattern matching syntax to enable suggestions on specific files, either a string or a list of strings
--   -- disable_url_path_completion = false, -- cf Backend
-- })
--

-- local cmp_ai = require('cmp_ai.config')
--
-- cmp_ai:setup({
--   max_lines = 1000,
--   provider = 'Ollama',
--   provider_options = {
--     model = 'deepseek-coder-v2',
--     system = "You're a code assistant. Provide the appropriate missing code without any Mardown wrapping, only the raw Rust code without ```.",
--   },
--   notify = true,
--   notify_callback = function(msg)
--     vim.notify(msg)
--   end,
--   run_on_every_keystroke = false,
--   ignored_file_types = {
--     -- default is not to ignore
--     -- uncomment to ignore in lua:
--     -- lua = true
--   },
-- })

-- require('gen').setup({
--     model = "deepseek-coder-v2", -- The default model to use.
--     quit_map = "q", -- set keymap for close the response window
--     retry_map = "<c-r>", -- set keymap to re-send the current prompt
--     accept_map = "<c-cr>", -- set keymap to replace the previous selection with the last result
--     host = "localhost", -- The host running the Ollama service.
--     port = "11434", -- The port on which the Ollama service is listening.
--     display_mode = "horizontal-split", -- The display mode. Can be "float" or "split" or "horizontal-split".
--     show_prompt = false, -- Shows the prompt submitted to Ollama.
--     show_model = false, -- Displays which model you are using at the beginning of your chat session.
--     no_auto_close = false, -- Never closes the window automatically.
--     hidden = false, -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
--     init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
--     -- Function to initialize Ollama
--     command = function(options)
--         local body = {
--           model = options.model,
--           stream = true
--         }
--         return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
--     end,
--     -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
--     -- This can also be a command string.
--     -- The executed command must return a JSON object with { response, context }
--     -- (context property is optional).
--     -- list_models = '<omitted lua function>', -- Retrieves a list of model names
--     debug = false -- Prints errors and the command which is run.
-- })

-- require('gen').prompts['GenCode'] = {
--   prompt = "Generate the missing code requested by a comment starting with 'ai'. Code will replace the comment and MUST NOT copy existing code. Generate ONLY the missing code without any explanations or comments. Only ouput the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
--   replace = true,
--   extract = "```$filetype\n(.-)```"
-- }

-- vim.keymap.set({ 'n', 'v' }, '<leader>a', ':Gen<CR>')

require('avante').setup({
  provider = "ollama",
  vendors = {
    ---@type AvanteProvider
    ollama = {
      ["local"] = true,
      endpoint = "127.0.0.1:11434/v1",
      model = "llama3.1",
      -- model = "deepseek-coder-v2",
      parse_curl_args = function(opts, code_opts)
        return {
          url = opts.endpoint .. "/chat/completions",
          headers = {
            ["Accept"] = "application/json",
            ["Content-Type"] = "application/json",
          },
          body = {
            model = opts.model,
            messages = require("avante.providers").copilot.parse_message(code_opts), -- you can make your own message, but this is very advanced
            max_tokens = 8 * 2048,
            stream = true,
          },
        }
      end,
      parse_response_data = function(data_stream, event_state, opts)
        require("avante.providers").openai.parse_response(data_stream, event_state, opts)
      end,
    },
  },
})

local null_ls = require("null-ls")

---@class none_hicad_ls
local M = {}

local function jsonstring_to_table(jsonString)
	local t = vim.json.decode(jsonString)
	return t
end

local function table_to_jsonstring(t)
	local s = { '\'{"sources": ["' }
	for i = 1, #t do
		s[#s + 1] = t[i]
		if i == #t then
			s[#s + 1] = '"' -- for the last element
		else
			s[#s + 1] = '", "'
		end
	end
	s[#s + 1] = "]}'"
	s = table.concat(s)
	return s
end

local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/\\])") or "./"
end

function M.setup(opts)
	opts = opts or {}

	if opts.lsp.source then
		Sources = table_to_jsonstring(opts.lsp.source)
	else
		print("none_hicad_lsp: You have to specify one source at least")
	end
	if opts.lsp.table then
		Table = opts.lsp.table
	else
		print("none_hicad_lsp: You have to specify the table to read from")
	end
	if opts.lsp.name_column then
		Name_column = opts.lsp.name_column
	else
		print("none_hicad_lsp: You have to specify the column where the name should be looked up")
	end
	if opts.lsp.description_column then
		Description_column = opts.lsp.description_column
	else
		print("none_hicad_lsp: You have to specify the column where the description to be displayed is stored")
	end
end

Path_cmd = script_path() .. "lsp_source.nu "

local function lsp_source(flag)
	-- Corrently only the json one gets called.
	if flag == "--json" then
		Command = (
			Path_cmd
			.. flag
			.. " "
			.. "--sources "
			.. tostring(Sources)
			.. " "
			.. "--table "
			.. Table
			.. " "
			.. "--name_column "
			.. Name_column
			.. " "
			.. "--description_column"
			.. " "
			.. Description_column
		)
	end
	if flag == "--names" then
		Command = (
			Path_cmd
			.. flag
			.. " "
			.. "--sources "
			.. tostring(Sources)
			.. " "
			.. "--table "
			.. tostring(Table)
			.. " "
			.. "--column "
			.. tostring(Name_column)
		)
	end
	if flag == "--description" then
		Command = (
			Path_cmd
			.. flag
			.. " "
			.. "--sources "
			.. tostring(Sources)
			.. " "
			.. "--table "
			.. tostring(Table)
			.. " "
			.. "--column "
			.. tostring(Description_column)
		)
	end
	if flag == "--version" then
		Command = (Path_cmd .. "--version")
	end
	local com = "-c `nu " .. Command .. "`"
	local result = vim.system({ "nu", com }, { text = true }):wait()

	if result then
		return result.stdout
	else
		print("Error when reading source")
	end
end

local function get_lookup_name()
	local node = vim.treesitter.get_node()
	local node_text = vim.treesitter.get_node_text(node, 0)

	if node_text == false then
		return vim.fn.expand("<cword>")
	else
		return node_text
	end
end

local global_var_hint = {
	method = null_ls.methods.HOVER,
	filetypes = { "hicad" },
	generator = {
		fn = function(_, done)
			local description = ""
			local word = get_lookup_name()

			local lookup_wordlist = jsonstring_to_table(lsp_source("--json"))
			for _, entry in ipairs(lookup_wordlist) do
				for key, value in pairs(entry) do
					if key == word then
						description = value
						print(description .. "   is the desc")
					end
				end
			end
			done({ tostring(description) })
		end,
		async = true,
	},
}

local no_hicad_lsp = {
	method = null_ls.methods.DIAGNOSTICS,
	filetypes = { "hicad" },
	generator = {
		fn = function(params)
			local diagnostics = {}
			-- sources have access to a params object
			-- containing info about the current file and editor state
			for i, line in ipairs(params.content) do
				local col, end_col = line:find("rem")
				if col and end_col then
					-- null-ls fills in undefined positions
					-- and converts source diagnostics into the required format
					table.insert(diagnostics, {
						row = i,
						col = col,
						end_col = end_col + 1,
						source = "Uppercase comment",
						message = "rem should be uppercase",
						severity = vim.diagnostic.severity.WARN,
					})
				end
			end
			return diagnostics
		end,
	},
}

null_ls.register(no_hicad_lsp)
null_ls.register(global_var_hint)

-- Can be used to display a hover window with debug text
function Debugg(text)
	local buf, win

	local function open_win()
		buf = vim.api.nvim_create_buf(false, true)

		vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

		local width = vim.api.nvim_get_option("columns")
		local height = vim.api.nvim_get_option("lines")

		local win_height = math.ceil(height * 0.8 - 4)
		local win_width = math.ceil(width * 0.8)

		local row = math.ceil((height - win_height) / 2 - 1)
		local col = math.ceil((width - win_width) / 2)

		local opts = {
			style = "minimal",
			relative = "editor",
			width = win_width,
			height = win_height,
			row = row,
			col = col,
			border = "rounded",
		}

		win = vim.api.nvim_open_win(buf, true, opts)
		vim.api.nvim_win_set_option(win, "cursorline", true)
	end

	local function view()
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, -1, -1, true, { text })
		vim.api.nvim_buf_set_option(0, "modifiable", false)
	end
	open_win()
	view()
end

return M

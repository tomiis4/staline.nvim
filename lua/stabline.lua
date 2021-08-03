Stabline = {}
local cmd = vim.api.nvim_command

local type_chars={ bar={left="┃", right=" "}, slant={left="", right=""}, arrow={left="", right=""}, bubble={left="", right=""} }

local normal_bg = vim.api.nvim_get_hl_by_name("Normal", {})['background'] or 255
local normal_fg = vim.api.nvim_get_hl_by_name("Normal", {})['foreground'] or 0

function Stabline.setup(opts)
	Stabline.stabline_opts =  opts or {style = "bar"}
	vim.tbl_deep_extend('force', Stabline.stabline_opts, opts or {})

	vim.cmd [[au BufEnter * lua require"stabline".call_stabline_colors()]]
	vim.o.tabline = '%!v:lua.require\'stabline\'.get_tabline()'
end

function Stabline.call_stabline_colors()
	local opts = Stabline.stabline_opts
	local stab_type = opts.style or "bar"
	local bg_hex = opts.bg or string.format("#%x", normal_bg)
	local fg_hex = opts.fg or string.format("#%x", normal_fg)
	local dark_bg = opts.stab_bg or string.format("#%x", normal_bg/2)
	local inactive_bg, inactive_fg = opts.inactive_bg or "#1e2127", opts.inactive_fg or "#aaaaaa"
	local set = {}

	if stab_type == "bar" then
		set = { left = {f = fg_hex, b = bg_hex}, right = {f = fg_hex, b = bg_hex} }
	elseif stab_type == "slant" then
		set = { left = {f = bg_hex, b = dark_bg}, right = {f = bg_hex, b = dark_bg} }
	elseif stab_type == "arrow" then
		set = { left = {f = dark_bg, b = bg_hex}, right = {f = bg_hex, b = dark_bg} }
	elseif stab_type == "bubble" then
		set = { left = {f = bg_hex, b = dark_bg}, right = {f = bg_hex, b = dark_bg} }
	end

	cmd('hi StablineSel guifg='..fg_hex..' guibg='..bg_hex)
	cmd('hi Stabline guibg='..dark_bg)
	cmd('hi StablineLeft guifg='..set.left.f..' guibg='..set.left.b)
	cmd('hi StablineRight guifg='..set.right.f..' guibg='..set.right.b)
	cmd('hi StablineInactive guifg='..inactive_fg..' guibg='..inactive_bg)
	cmd('hi StablineSepInactive guifg='..inactive_bg..' guibg='..dark_bg)

end

local function get_file_icon(f_name, ext)
	if not pcall(require, 'nvim-web-devicons') then
		return require'tables'.file_icons[ext] or " " end
	return require'nvim-web-devicons'.get_icon(f_name, ext, {default = true})
end

local function do_icon_hl(icon_hl)
	local new_fg = string.format("#%x",vim.api.nvim_get_hl_by_name(icon_hl or 'Normal', {})['foreground'] or 0)
	local icon_bg = Stabline.stabline_opts.bg or string.format("#%x", normal_bg)
	cmd('hi NewIconHl guibg='..icon_bg..' guifg='..new_fg..' gui=bold')
	return '%#NewIconHl#'
end

function Stabline.get_tabline()
	local opts = Stabline.stabline_opts
	local stab_type = opts.style or "bar"
	local stab_left = opts.stab_left or type_chars[stab_type].left
	local stab_right= opts.stab_right or  type_chars[stab_type].right
	local tabline = ""

	for _, buf in pairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
			local edited = vim.bo.modified and "" or ""

			local f_name = vim.api.nvim_buf_get_name(buf):match("^.+/(.+)$") or ""
			local ext = string.match(f_name, "%w+%.(.+)")
			local f_icon, icon_hl = get_file_icon(f_name, ext)

			if f_name == 'NvimTree' or f_name == '' then
				goto do_nothing
			elseif f_name ~= nil then
				f_name = " "..f_name.."  "
			else
				f_name = ""
			end

			if vim.api.nvim_get_current_buf() == buf then
				if buf == 1 and stab_type == "arrow" then stab_left = " " end
				tabline = tabline.."%#StablineLeft#"..stab_left.."%#StablineSel# "..
				do_icon_hl(icon_hl)..f_icon.."%#StablineSel#"..
				f_name..edited.."%#StablineRight#"..stab_right
			else
				tabline = tabline.."%#Stabline#  "..f_icon..f_name.." "
-- 				tabline = tabline.."%#StablineSepInactive#"..stab_left.."%#StablineInactive# "..
-- 				f_icon.."%#StablineInactive#".. f_name.."%#StablineSepInactive#"..stab_right
			end
		end
		::do_nothing::
	end

	return tabline.."%#Stabline#"
end

return Stabline


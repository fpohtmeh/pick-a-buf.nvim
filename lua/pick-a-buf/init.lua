local M = {}

local State = {
  win_id = nil,
  bufnr = nil,
}

local function create_window()
  local popup = require("plenary.popup")
  local width = 100
  local height = 30
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local bufnr = vim.api.nvim_create_buf(false, false)

  local new_win_id, win = popup.create(bufnr, {
    title = "Pick Buffer",
    highlight = "TelescopeNormal",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  vim.api.nvim_win_set_option(win.border.win_id, "winhl", "Normal:TelescopeBorder")

  vim.api.nvim_create_autocmd("BufLeave", {
    desc = "Close pick-a-buf window when leaving buffer",
    buffer = bufnr,
    once = true,
    nested = true,
    callback = function()
      if vim.api.nvim_win_is_valid(new_win_id) then
        vim.api.nvim_win_close(new_win_id, true)
      end
    end,
  })

  return {
    bufnr = bufnr,
    win_id = new_win_id,
  }
end

local function close_window()
  vim.api.nvim_win_close(State.win_id, true)
  State.win_id = nil
  State.bufnr = nil
end

local function get_buf_info(buf)
  if vim.fn.buflisted(buf) ~= 1 then
    return nil
  end
  return { buf, vim.api.nvim_buf_get_name(buf) }
end

local function get_bufs_info()
  local bufs_info = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_info = get_buf_info(buf)
    if buf_info then
      bufs_info[#bufs_info + 1] = buf_info
    end
  end
  return bufs_info
end

function M.open_buffer(bufnr)
  close_window()
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.cmd(":buffer " .. bufnr)
  else
    vim.notify("Buffer is not valid anymore")
  end
end

local function create_mapping(bufnr, key)
  if not key then
    return
  end
  vim.api.nvim_buf_set_keymap(
    State.bufnr,
    "n",
    key,
    "<cmd>lua require('pick-a-buf').open_buffer(" .. bufnr .. ")<cr>",
    { silent = true, noremap = true }
  )
end

function M.toggle()
  if State.win_id ~= nil and vim.api.nvim_win_is_valid(State.win_id) then
    close_window()
    return
  end

  local win_info = create_window()
  State.win_id = win_info.win_id
  State.bufnr = win_info.bufnr

  vim.api.nvim_win_set_option(State.win_id, "number", false)
  vim.api.nvim_buf_set_name(State.bufnr, "pick-a-buf-window")
  vim.api.nvim_buf_set_option(State.bufnr, "filetype", "pick-a-buf")
  vim.api.nvim_buf_set_option(State.bufnr, "buftype", "nowrite")
  vim.api.nvim_buf_set_option(State.bufnr, "buflisted", false)
  vim.api.nvim_buf_set_option(State.bufnr, "bufhidden", "delete")

  local bufs_info = get_bufs_info()
  local contents = {}
  local keys = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0123456789"
  for index, buf_info in ipairs(bufs_info) do
    local key = string.sub(keys, index, index)
    create_mapping(buf_info[1], key)
    contents[#contents + 1] = string.format(" %s │ %s", key, buf_info[2])
    index = index + 1
  end
  vim.api.nvim_buf_set_lines(State.bufnr, 0, #contents, false, contents)
  vim.api.nvim_buf_set_option(State.bufnr, "modifiable", false)
end

return M

local json = require("code-runner/json")

local M = {}
M.config = {
	window = {
		width = 70,
		split = "right",
	},
	shell = "bash",
	linger_ms = 1,
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

function M.run()
	local build_command = M.get_build_command(vim.fn.getcwd())

	local buf = vim.api.nvim_create_buf(false, true)
	local opts = {
		win = -1, -- global split
		split = M.config.window.split,
		width = M.config.window.width,
	}
	local win_id = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_call(buf, function()
		vim.fn.jobstart({ M.config.shell, "-ic", build_command }, {
			term = true,
			on_exit = function(_, code)
				if code ~= 0 then
					vim.notify("Build failed: exit code: " .. code)
				end

				vim.defer_fn(function()
					vim.api.nvim_win_close(win_id, true)
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end, M.config.linger_ms)
			end,
		})
	end)
	vim.fn.feedkeys("Gi")
end

function M.get_build_command(repo)
	local repodata_dir = vim.fn.stdpath("data") .. "/code-runner/"
	local repodata_file = repodata_dir .. "repodata.json"
	if vim.fn.filereadable(repodata_file) ~= 1 then
		vim.fn.mkdir(repodata_dir, "p")
		vim.fn.writefile({ "{}" }, repodata_file)
	end

	local raw = vim.fn.readfile(repodata_file)
	local contents = json.decode(table.concat(raw, "\n"))
	if contents[repo] == nil then
		contents[repo] = vim.fn.input("What is the build command for this project?")
		local new = json.encode(contents)
		vim.fn.writefile({ new }, repodata_file)
	end

	return contents[repo]
end

return M

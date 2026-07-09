vim.api.nvim_create_user_command('CodeRunner', function()
    -- Only loads the heavy module code when the command is typed
    require('code-runner').run()
end, {})

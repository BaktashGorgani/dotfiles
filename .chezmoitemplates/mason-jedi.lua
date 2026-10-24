local ok_registry, registry = pcall(require, "mason-registry")
local ok_settings, settings = pcall(require, "mason.settings")
local ok_commands, commands = pcall(require, "mason.api.command")
local ok_async, async = pcall(require, "mason-core.async")

local function healthy()
    local executable = settings.current.install_root_dir .. "/bin/jedi-language-server"
    local ok, result = pcall(function()
        return vim.system({ executable, "--version" }, { text = true }):wait(15000)
    end)
    return ok and result.code == 0
end

local ok, err = pcall(function()
    assert(ok_registry, tostring(registry))
    assert(ok_settings, tostring(settings))
    assert(ok_commands, tostring(commands))
    assert(ok_async, tostring(async))
    if healthy() then
        print("Mason Jedi is healthy")
        return
    end
    print("Repairing Mason Jedi...")
    local python = vim.env.PIPX_DEFAULT_PYTHON
    if python then
        assert(vim.fn.executable(python) == 1, "Selected Python is unavailable: " .. python)
        vim.env.PATH = vim.fn.fnamemodify(python, ":h") .. ":" .. (vim.env.PATH or "")
    end
    -- Refresh before looking up a package on a freshly bootstrapped machine.
    local refreshed, refresh_err = registry.refresh()
    assert(refreshed, "Mason registry refresh failed: " .. tostring(refresh_err))
    local package = registry.get_package("jedi-language-server")
    assert(not package:is_installing(), "Jedi is already installing; retry maintenance afterwards")
    if package:is_installed() then
        async.run_blocking(function()
            local success, uninstall_err = async.wait(function(resolve)
                package:uninstall({}, function(success, uninstall_err)
                    resolve(success, uninstall_err)
                end)
            end)
            assert(success, tostring(uninstall_err))
        end)
    end
    -- MasonInstall blocks and propagates installation failures in headless mode.
    -- Do not force unsupported Python versions.
    commands.MasonInstall({ "jedi-language-server" })
    assert(healthy(), "Mason Jedi failed verification after installation")
end)
if not ok then
    vim.api.nvim_err_writeln(tostring(err))
    vim.cmd("cquit 1")
end

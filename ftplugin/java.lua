-- Java LSP configuration via nvim-jdtls
-- This file is automatically loaded when a Java file is opened

local jdtls = require('jdtls')

-- Resolve the Java executable from sdkman
local sdkman_dir = vim.env.SDKMAN_DIR or (vim.env.HOME .. '/.sdkman')
local java_cmd = sdkman_dir .. '/candidates/java/current/bin/java'

-- Resolve Mason install path
local mason_packages = vim.fn.stdpath('data') .. '/mason/packages'

local function get_mason_package_path(name)
  local path = mason_packages .. '/' .. name
  if vim.fn.isdirectory(path) == 1 then
    return path
  end
  return nil
end

-- JDTLS must be installed via Mason
local jdtls_path = get_mason_package_path('jdtls')
if not jdtls_path then
  vim.notify('jdtls not installed via Mason — run :Mason to install', vim.log.levels.WARN)
  return
end

-- Project root detection
local root_dir = require('jdtls.setup').find_root({ 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git', 'mvnw', 'gradlew' })
if not root_dir then
  return
end

-- Per-project workspace directory
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.env.HOME .. '/.cache/jdtls/workspace/' .. project_name

-- Lombok agent — use the one bundled with Mason's jdtls, fall back to manual download
local lombok_jar = jdtls_path .. '/lombok.jar'
if vim.fn.filereadable(lombok_jar) == 0 then
  local lombok_dir = vim.env.HOME .. '/.local/share/java'
  lombok_jar = lombok_dir .. '/lombok.jar'
  if vim.fn.filereadable(lombok_jar) == 0 then
    vim.fn.mkdir(lombok_dir, 'p')
    vim.fn.system({ 'curl', '-fsSL', '-o', lombok_jar, 'https://projectlombok.org/downloads/lombok.jar' })
  end
end

-- Detect platform-specific configuration directory
local config_dir = jdtls_path .. '/config_mac_arm'
if vim.fn.isdirectory(config_dir) == 0 then
  config_dir = jdtls_path .. '/config_mac'
end
if vim.fn.isdirectory(config_dir) == 0 then
  config_dir = jdtls_path .. '/config_linux'
end

-- Debug and test bundles
local bundles = {}

local java_debug_path = get_mason_package_path('java-debug-adapter')
if java_debug_path then
  local debug_jars = vim.fn.glob(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', false, true)
  vim.list_extend(bundles, debug_jars)
end

local java_test_path = get_mason_package_path('java-test')
if java_test_path then
  local test_jars = vim.fn.glob(java_test_path .. '/extension/server/*.jar', false, true)
  vim.list_extend(bundles, test_jars)
end

-- JDTLS configuration
local config = {
  cmd = {
    java_cmd,
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. lombok_jar,
    '-jar', vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration', config_dir,
    '-data', workspace_dir,
  },
  root_dir = root_dir,

  settings = {
    java = {
      autobuild = { enabled = false },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      completion = {
        favouriteStaticMembers = {
          'org.hamcrest.MatcherAssert.assertThat',
          'org.hamcrest.Matchers.*',
          'org.hamcrest.CoreMatchers.*',
          'org.junit.jupiter.api.Assertions.*',
          'java.util.Objects.requireNonNull',
          'java.util.Objects.requireNonNullElse',
          'org.mockito.Mockito.*',
        },
        filteredTypes = {
          'com.sun.*',
          'io.micrometer.shaded.*',
          'java.awt.*',
          'jdk.*',
          'sun.*',
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      configuration = {
        -- Detected runtimes from sdkman
        runtimes = (function()
          local runtimes = {}
          local candidates_dir = sdkman_dir .. '/candidates/java'
          local entries = vim.fn.readdir(candidates_dir)
          for _, entry in ipairs(entries) do
            if entry ~= 'current' then
              local major = entry:match('^(%d+)%.')
              if major then
                table.insert(runtimes, {
                  name = 'JavaSE-' .. major,
                  path = candidates_dir .. '/' .. entry,
                })
              end
            end
          end
          return runtimes
        end)(),
      },
    },
  },

  init_options = {
    bundles = bundles,
  },

  on_attach = function(_, bufnr)
    -- Java-specific keymaps (code actions only — tests handled by neotest)
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set('n', '<leader>co', jdtls.organize_imports, vim.tbl_extend('force', opts, { desc = 'Organise imports' }))
    vim.keymap.set('n', '<leader>cv', jdtls.extract_variable, vim.tbl_extend('force', opts, { desc = 'Extract variable' }))
    vim.keymap.set('v', '<leader>cv', function() jdtls.extract_variable(true) end, vim.tbl_extend('force', opts, { desc = 'Extract variable' }))
    vim.keymap.set('n', '<leader>cc', jdtls.extract_constant, vim.tbl_extend('force', opts, { desc = 'Extract constant' }))
    vim.keymap.set('v', '<leader>cc', function() jdtls.extract_constant(true) end, vim.tbl_extend('force', opts, { desc = 'Extract constant' }))
    vim.keymap.set('v', '<leader>cm', function() jdtls.extract_method(true) end, vim.tbl_extend('force', opts, { desc = 'Extract method' }))

    -- Maven test command helpers
    local function get_test_class_name()
      local filepath = vim.fn.expand('%:p')
      local class_name = filepath:match('.*/src/test/java/(.+)%.java$')
        or filepath:match('.*/src/main/java/(.+)%.java$')
      if class_name then
        return class_name:gsub('/', '.')
      end
      return nil
    end

    local function get_test_method_name()
      local node = vim.treesitter.get_node()
      while node do
        if node:type() == 'method_declaration' then
          for child in node:iter_children() do
            if child:type() == 'identifier' then
              return vim.treesitter.get_node_text(child, bufnr)
            end
          end
        end
        node = node:parent()
      end
      return nil
    end

    local function get_maven_module()
      local filepath = vim.fn.expand('%:p:h')
      -- Walk up from the file to find the nearest pom.xml
      local module_dir = filepath
      while module_dir ~= '/' do
        if vim.fn.filereadable(module_dir .. '/pom.xml') == 1 then
          break
        end
        module_dir = vim.fn.fnamemodify(module_dir, ':h')
      end
      -- If module pom.xml is different from root pom.xml, extract the module path
      if module_dir ~= root_dir then
        local module = module_dir:sub(#root_dir + 2) -- +2 for the trailing /
        return module
      end
      return nil
    end

    local function get_maven_cmd()
      if vim.fn.filereadable(root_dir .. '/mvnw') == 1 then
        return './mvnw'
      end
      return 'mvn'
    end

    local function build_maven_test_cmd(include_method)
      local class_name = get_test_class_name()
      if not class_name then
        vim.notify('Could not determine test class name', vim.log.levels.WARN)
        return nil
      end

      local mvn = get_maven_cmd()
      local module = get_maven_module()
      local test_spec = class_name

      if include_method then
        local method = get_test_method_name()
        if method then
          test_spec = class_name .. '#' .. method
        end
      end

      local cmd = mvn .. ' test'
      if module then
        cmd = cmd .. ' -pl ' .. module
      end
      cmd = cmd .. ' -Dtest=' .. test_spec

      return cmd
    end

    -- Maven keymaps
    vim.keymap.set('n', '<leader>mt', function()
      local cmd = build_maven_test_cmd(true)
      if cmd then
        vim.fn.setreg('+', cmd)
        vim.notify('Copied: ' .. cmd)
      end
    end, vim.tbl_extend('force', opts, { desc = '[M]aven [t]est nearest method' }))

    vim.keymap.set('n', '<leader>mT', function()
      local cmd = build_maven_test_cmd(false)
      if cmd then
        vim.fn.setreg('+', cmd)
        vim.notify('Copied: ' .. cmd)
      end
    end, vim.tbl_extend('force', opts, { desc = '[M]aven [T]est class' }))

    -- Set up debug adapter after LSP attaches
    jdtls.setup_dap({ hotcodereplace = 'auto' })

    -- Quarkus remote debug configuration (quarkus:dev listens on port 5005)
    local dap_ok, dap = pcall(require, 'dap')
    if dap_ok then
      dap.configurations.java = dap.configurations.java or {}
      -- Only add if not already present
      local has_quarkus = false
      for _, cfg in ipairs(dap.configurations.java) do
        if cfg.name == 'Attach to Quarkus (port 5005)' then
          has_quarkus = true
          break
        end
      end
      if not has_quarkus then
        table.insert(dap.configurations.java, {
          type = 'java',
          request = 'attach',
          name = 'Attach to Quarkus (port 5005)',
          hostName = 'localhost',
          port = 5005,
        })
      end
    end
  end,
}

-- Start or attach JDTLS
jdtls.start_or_attach(config)

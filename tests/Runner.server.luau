--[[
    test.rbxlx entrypoint — runs all spec modules on server start.
    Open test.rbxlx in Studio, press Play (F5), watch Output.

    Build: tools\rojo.exe build test.project.json -o test.rbxlx
]]

local TestRunner = require(script.Parent:WaitForChild("TestRunner"))
local Specs = script.Parent:WaitForChild("specs")

print("\n" .. string.rep("#", 60))
print("# Rivals test.rbxlx — auto-run on server start")
print(string.rep("#", 60))

task.wait(1)  -- let modules replicate

local suites = {}

for _, mod in ipairs(Specs:GetChildren()) do
    if mod:IsA("ModuleScript") then
        local ok, suite = pcall(require, mod)
        if ok and suite then
            table.insert(suites, suite)
        else
            print(string.format("[Runner] skipped %s: %s", mod.Name, tostring(suite)))
        end
    end
end

local result = TestRunner.run(suites)

if result.failed > 0 then
    warn(string.format("[Rivals Tests] FAILED — %d/%d tests failed", result.failed, result.total))
else
    print(string.format("[Rivals Tests] OK — %d/%d tests passed", result.passed, result.total))
end

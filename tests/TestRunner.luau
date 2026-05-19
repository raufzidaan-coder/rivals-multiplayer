--[[
    Minimal TestEZ-lite harness. No external deps. Run by Runner.server.luau.
    Use:
        local t = require(TestRunner)
        local suite = t.describe("MyClass", function(it)
            it("does X", function(expect)
                expect.equal(1, 1)
                expect.truthy(true)
                expect.errors(function() error("nope") end)
            end)
        end)
]]

local TestRunner = {}

local function makeExpect(failures)
    return {
        equal = function(a, b)
            if a ~= b then
                table.insert(failures, string.format("expected %s == %s", tostring(a), tostring(b)))
            end
        end,
        notEqual = function(a, b)
            if a == b then
                table.insert(failures, string.format("expected %s ~= %s", tostring(a), tostring(b)))
            end
        end,
        truthy = function(v)
            if not v then
                table.insert(failures, string.format("expected truthy, got %s", tostring(v)))
            end
        end,
        falsy = function(v)
            if v then
                table.insert(failures, string.format("expected falsy, got %s", tostring(v)))
            end
        end,
        near = function(a, b, eps)
            eps = eps or 0.0001
            if math.abs(a - b) > eps then
                table.insert(
                    failures,
                    string.format("expected %s ~= %s within %s", tostring(a), tostring(b), tostring(eps))
                )
            end
        end,
        ge = function(a, b)
            if not (a >= b) then
                table.insert(failures, string.format("expected %s >= %s", tostring(a), tostring(b)))
            end
        end,
        le = function(a, b)
            if not (a <= b) then
                table.insert(failures, string.format("expected %s <= %s", tostring(a), tostring(b)))
            end
        end,
        errors = function(fn)
            local ok = pcall(fn)
            if ok then
                table.insert(failures, "expected function to error, but it succeeded")
            end
        end,
        ok = function(ok, msg)
            if not ok then
                table.insert(failures, "ok check failed: " .. tostring(msg))
            end
        end,
        is_a = function(v, className)
            if typeof(v) ~= "Instance" or not v:IsA(className) then
                table.insert(failures, string.format("expected Instance<%s>, got %s", className, typeof(v)))
            end
        end,
    }
end

function TestRunner.describe(label, body)
    local cases = {}
    local function it(name, fn)
        table.insert(cases, { name = name, fn = fn })
    end
    body(it)
    return { label = label, cases = cases }
end

function TestRunner.run(suites)
    local total, passed, failed, skipped = 0, 0, 0, 0
    local failedDetails = {}

    print(string.rep("=", 60))
    print("[Rivals Tests] Running " .. #suites .. " suites")
    print(string.rep("=", 60))

    for _, suite in ipairs(suites) do
        print(string.format("\n--- %s ---", suite.label))
        for _, case in ipairs(suite.cases) do
            total += 1
            local failures = {}
            local ok, err = pcall(case.fn, makeExpect(failures))
            if not ok then
                failed += 1
                local detail = string.format("  [X] %s — threw: %s", case.name, tostring(err))
                print(detail)
                table.insert(failedDetails, suite.label .. " > " .. case.name)
            elseif #failures > 0 then
                failed += 1
                local detail = string.format("  [X] %s", case.name)
                print(detail)
                for _, f in ipairs(failures) do
                    print("       " .. f)
                end
                table.insert(failedDetails, suite.label .. " > " .. case.name)
            else
                passed += 1
                print(string.format("  [PASS] %s", case.name))
            end
        end
    end

    print("\n" .. string.rep("=", 60))
    print(string.format("[Rivals Tests] %d/%d passed, %d failed, %d skipped", passed, total, failed, skipped))
    print(string.rep("=", 60))
    if #failedDetails > 0 then
        print("\nFailed tests:")
        for _, d in ipairs(failedDetails) do
            print("  - " .. d)
        end
    end
    return { total = total, passed = passed, failed = failed }
end

return TestRunner

--[[
    SpawnCar — test.rbxlx only.
    Builds a driveable VehicleSeat car at (0, 5, 30) on server start.
    Sit in the seat and drive with WASD. Differential steering on front wheels.
]]

local RunService = game:GetService("RunService")

local SPAWN = Vector3.new(0, 5, 30)

local function buildCar()
    local existing = workspace:FindFirstChild("RivalsCar")
    if existing then
        existing:Destroy()
    end

    local car = Instance.new("Folder")
    car.Name = "RivalsCar"
    car.Parent = workspace

    -- Chassis
    local chassis = Instance.new("Part")
    chassis.Name = "Chassis"
    chassis.Size = Vector3.new(8, 1.5, 4)
    chassis.Position = SPAWN
    chassis.BrickColor = BrickColor.new("Really red")
    chassis.Material = Enum.Material.Metal
    chassis.TopSurface = Enum.SurfaceType.Smooth
    chassis.BottomSurface = Enum.SurfaceType.Smooth
    chassis.Parent = car

    -- VehicleSeat
    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.Position = SPAWN + Vector3.new(0, 1.25, 0)
    seat.BrickColor = BrickColor.new("Black")
    seat.MaxSpeed = 60
    seat.Torque = 35
    seat.TurnSpeed = 8
    seat.Parent = car

    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = chassis
    seatWeld.Part1 = seat
    seatWeld.Parent = chassis

    -- Wheel factory. offsetX: +front / -back. offsetZ: +right / -left.
    local function makeWheel(name, offsetX, offsetZ)
        local wheel = Instance.new("Part")
        wheel.Name = name
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Size = Vector3.new(1, 2.5, 2.5)
        wheel.Position = SPAWN + Vector3.new(offsetX, -1, offsetZ)
        wheel.Orientation = Vector3.new(0, 0, 90)
        wheel.BrickColor = BrickColor.new("Really black")
        wheel.Material = Enum.Material.Rubber
        wheel.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1.5, 0.2, 1, 1)
        wheel.Parent = car

        local chassisAtt = Instance.new("Attachment")
        chassisAtt.Name = name .. "_ChassisAtt"
        chassisAtt.Position = Vector3.new(offsetX, -0.75, offsetZ)
        chassisAtt.Axis = Vector3.new(0, 0, 1)
        chassisAtt.SecondaryAxis = Vector3.new(0, 1, 0)
        chassisAtt.Parent = chassis

        local wheelAtt = Instance.new("Attachment")
        wheelAtt.Name = name .. "_WheelAtt"
        wheelAtt.Axis = Vector3.new(0, 0, 1)
        wheelAtt.SecondaryAxis = Vector3.new(0, 1, 0)
        wheelAtt.Parent = wheel

        local hinge = Instance.new("HingeConstraint")
        hinge.Name = name .. "_Hinge"
        hinge.Attachment0 = chassisAtt
        hinge.Attachment1 = wheelAtt
        hinge.ActuatorType = Enum.ActuatorType.Motor
        hinge.MotorMaxAcceleration = 1e5
        hinge.MotorMaxTorque = 1e6
        hinge.AngularVelocity = 0
        hinge.Parent = chassis

        return hinge
    end

    local flHinge = makeWheel("FrontLeft", 3, -2.5)
    local frHinge = makeWheel("FrontRight", 3, 2.5)
    local rlHinge = makeWheel("RearLeft", -3, -2.5)
    local rrHinge = makeWheel("RearRight", -3, 2.5)

    -- Drive loop: read VehicleSeat throttle/steer floats and apply to hinges.
    -- Front wheels get differential steering (inner slower, outer faster).
    RunService.Heartbeat:Connect(function()
        if not seat.Parent then
            return
        end
        local throttle = seat.ThrottleFloat
        local steer = seat.SteerFloat

        local driveSpeed = -throttle * seat.MaxSpeed * 2
        rlHinge.AngularVelocity = driveSpeed
        rrHinge.AngularVelocity = driveSpeed

        local steerBias = steer * seat.MaxSpeed
        flHinge.AngularVelocity = driveSpeed - steerBias
        frHinge.AngularVelocity = driveSpeed + steerBias
    end)

    print(
        string.format(
            "[Car] RivalsCar spawned at (%d, %d, %d). Sit in the VehicleSeat, WASD to drive.",
            SPAWN.X,
            SPAWN.Y,
            SPAWN.Z
        )
    )
end

buildCar()

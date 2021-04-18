local canvas;
local points = {};
local i = 0;
local spawn_delay = 0.25;
local threshold = 0.6;
local POINT_RADIUS = 3;
local POINT_MAX_RADIUS = 10;
local LINE_THICKNESS = 3;
local GROWTH_SPEED = 50;
local DIM = 50;
local COLORS = {
    obe.Graphics.Color(255, DIM, DIM),
    obe.Graphics.Color(DIM, 255, DIM),
    obe.Graphics.Color(DIM, DIM, 255),
    obe.Graphics.Color(255, 255, DIM),
    obe.Graphics.Color(255, DIM, 255),
    obe.Graphics.Color(DIM, 255, 255)
}

local dimensions = Engine.Window:getSize():to(obe.Transform.Units.SceneUnits);

function Local.Init()
    local window_size = Engine.Window:getSize():to(obe.Transform.Units.ScenePixels);
    canvas = obe.Canvas.Canvas(window_size.x, window_size.y);

    Engine.Events:schedule():every(spawn_delay):run(SpawnPoint);
end

function SpawnPoint()
    local angle;
    local x;
    if math.random() < 0.5 then
        x = 0;
        angle = (math.random() * 90) - 45;
    else
        x = dimensions.x;
        angle = (math.random() * 90) + 180 - 45;
    end
    local y = math.random() * dimensions.y;
    local speed = math.random() * 0.5 + 0.1;
    local snode = obe.Scene.SceneNode();
    snode:setPosition(obe.Transform.UnitVector(x, y));
    local tnode = obe.Collision.TrajectoryNode(snode);
    local trajectory = tnode:addTrajectory("default"):setSpeed(speed):setAngle(angle);
    local point_color = COLORS[math.random(1, #COLORS)];
    local render_point = canvas:Circle ("point_" .. tostring(i)) {
        x = x,
        y = y,
        radius = POINT_RADIUS,
        color = "white",
        unit = obe.Transform.Units.SceneUnits
    };
    render_point.color.a = 200;
    local color1 = "yellow";
    local color2 = "cyan";
    local master_junctions = {};
    for _, point in pairs(points) do
        local new_line = canvas:Line() {
            p1 = {x = 0, y = 0, unit = obe.Transform.Units.SceneUnits, color=point_color},
            p2 = {x = 0, y = 0, unit = obe.Transform.Units.SceneUnits, color=point.color},
            thickness = LINE_THICKNESS
        }
        master_junctions[point.i] = new_line;
        point.slave_junctions[i] = new_line;
    end
    points[i] = {
        i = i,
        snode = snode,
        tnode = tnode,
        trajectory = trajectory,
        render_point = render_point,
        master_junctions = master_junctions,
        slave_junctions = {},
        angle = angle,
        radius = POINT_RADIUS,
        color = point_color
    };
    i = i + 1;
end

local cursor_state = false;

function Event.Cursor.Hold(event)
    cursor_state = true;
    for _, point in pairs(points) do
        local point_position = point.snode:getPosition():to(obe.Transform.Units.ScenePixels);
        local angle_to_cursor;
        if event.left then
            angle_to_cursor = math.atan(point_position.y - event.y, event.x - point_position.x);
        elseif event.right then
            angle_to_cursor = math.atan(event.y - point_position.y, point_position.x - event.x);
        end
        point.trajectory:setAngle(math.deg(angle_to_cursor));
    end
end

function Event.Cursor.Release(event)
    cursor_state = false;
    for _, point in pairs(points) do
        point.trajectory:setAngle(point.angle);
    end
end

function Event.Game.Update(event)
    local radius_offset;
    for _, point in pairs(points) do
        radius_offset = obe.Transform.UnitVector(point.radius / 2, 0, obe.Transform.Units.ScenePixels):to(obe.Transform.Units.SceneUnits).x;
        if cursor_state then
            point.radius = point.radius + (GROWTH_SPEED * event.dt);
            if point.radius > POINT_MAX_RADIUS then
                point.radius = POINT_MAX_RADIUS;
            end
        else
            point.radius = point.radius - (GROWTH_SPEED * event.dt);
            if point.radius < POINT_RADIUS then
                point.radius = POINT_RADIUS;
            end
        end
        point.tnode:update(event.dt);
        local point_position = point.snode:getPosition();
        point.render_point.x = point_position.x;
        point.render_point.y = point_position.y;
        for _, junction in pairs(point.slave_junctions) do
            junction.p2.x = point_position.x + radius_offset;
            junction.p2.y = point_position.y + radius_offset;
        end
    end
    for pid, point in pairs(points) do
        local point_position = point.snode:getPosition();
        for jid, junction in pairs(point.master_junctions) do
            local dist = obe.Transform.UnitVector(junction.p2.x, junction.p2.y):distance(point_position);
            local alpha = math.max(0, threshold - dist) * 255;
            junction.p1.color.a = alpha;
            junction.p2.color.a = alpha;
            junction.p1.x = point_position.x + radius_offset;
            junction.p1.y = point_position.y + radius_offset;
        end
    end
end

function CleanDots()
    for point_id, point in pairs(points) do
        local point_position = point.snode:getPosition();
        if point_position.x < 0 or point_position.y > dimensions.x or point_position.y < 0 or point_position.y > dimensions.y then
            for _, point_clean in pairs(points) do
                if point_clean.slave_junctions[point_id] ~= nil then
                    canvas:remove(point_clean.slave_junctions[point_id].id);
                    point_clean.slave_junctions[point_id] = nil;
                end
                if point_clean.master_junctions[point_id] ~= nil then
                    canvas:remove(point_clean.master_junctions[point_id].id);
                    point_clean.master_junctions[point_id] = nil;
                end
            end
            canvas:remove(point.render_point.id);
            points[point_id] = nil;
        end
    end
end

function Event.Game.Render()
    CleanDots();
    for _, point in pairs(points) do
        point.render_point.radius = point.radius;
    end
    canvas:render(This.Sprite);
end
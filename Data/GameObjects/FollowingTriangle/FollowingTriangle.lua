function Local.Init()
    local window_size = Engine.Window:getSize():to(obe.Transform.Units.ScenePixels);
    canvas = obe.Canvas.Canvas(window_size.x, window_size.y);
    triangle = canvas:Polygon "triangle" {
        color = obe.Graphics.Color.White,
        points = {
            {x=0, y=0, unit=obe.Transform.Units.ScenePixels},
            {x=0, y=0, unit=obe.Transform.Units.ScenePixels},
            {x=0, y=0, unit=obe.Transform.Units.ScenePixels},
        }
    };
    position_buffer = {};
    color = {r=255, g=0, b=0, variation_speed=255, mode=0};

    Engine.Events:schedule():every(0.009):run(MovePolygon);
end

function ComputeTrianglePoints(p1, p2, dist)
    local x1 = p1.x; local x2 = p2.x;
    local y1 = p1.y; local y2 = p2.y;

    -- x > x2. P4 coordinates
    local x = math.sqrt((dist * dist * (y1 - y2) ^ 2) / (x1 * x1 - 2 * x1 * x2 + x2 * x2 + (y1 - y2) ^ 2)) + x2
    local y = ((x2 - x1) * (x - x2) + y1 * y2 - y2 * y2) / (y1 - y2)
    local p1 = {x = x, y = y};

    -- x <= x2. P3 coordinates
    local x = x2 - math.sqrt((dist * dist * (y1 - y2) ^ 2) / (x1 * x1 - 2 * x1 * x2 + x2 * x2 + (y1 - y2) ^ 2))
    local y = ((x1 - x2) * (-x + x2) + y1 * y2 - y2 * y2) / (y1 - y2)
    local p2 = {x = x, y = y};

    return p1, p2
end

function MovePolygon()
    if #position_buffer > 1 then
        local current_point = position_buffer[#position_buffer];
        local last_point = position_buffer[1];
        local length = math.sqrt((current_point.y - last_point.y) ^ 2 + (current_point.x - last_point.y) ^ 2);
        local p1, p2 = ComputeTrianglePoints(current_point, last_point, 60);
        triangle.points[1] = {
            x=current_point.x,
            y=current_point.y,
            unit=obe.Transform.Units.ScenePixels,
        };
        triangle.points[2] = {
            x=p1.x,
            y=p1.y,
            unit=obe.Transform.Units.ScenePixels
        };
        triangle.points[3] = {
            x=p2.x,
            y=p2.y,
            unit=obe.Transform.Units.ScenePixels
        };
        table.remove(position_buffer, 1);
    end
end

function Event.Game.Update(event)
    local mouse_position = Engine.Cursor:getPosition();
    if #position_buffer == 0 or mouse_position.x ~= position_buffer[#position_buffer].x or mouse_position.y ~= position_buffer[#position_buffer].y then
        table.insert(position_buffer, {x=mouse_position.x, y=mouse_position.y});
    end
    if #position_buffer > 10 then
        table.remove(position_buffer, 1);
    end
    if color.mode == 0 then
        color.g = color.g + color.variation_speed * event.dt;
        if color.g >= 255 then color.g = 255; color.mode = color.mode + 1; end
    elseif color.mode == 1 then
        color.r = color.r - color.variation_speed * event.dt;
        if color.r <= 0 then color.r = 0; color.mode = color.mode + 1; end
    elseif color.mode == 2 then
        color.b = color.b + color.variation_speed * event.dt;
        if color.b >= 255 then color.b = 255; color.mode = color.mode + 1; end
    elseif color.mode == 3 then
        color.g = color.g - color.variation_speed * event.dt;
        if color.g <= 0 then color.g = 0; color.mode = color.mode + 1; end
    elseif color.mode == 4 then
        color.r = color.r + color.variation_speed * event.dt;
        if color.r >= 255 then color.r = 255; color.mode = color.mode + 1; end
    elseif color.mode == 5 then
        color.b = color.b - color.variation_speed * event.dt;
        if color.b <= 0 then color.b = 0; color.mode = 0; end
    end
end

function Event.Game.Render()
    canvas:render(This.Sprite);
    print(inspect(color));
    triangle.color = color;
end
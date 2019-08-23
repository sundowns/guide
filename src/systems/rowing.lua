local rowing = System({_components.transform, _components.controlled, _components.paddle, _components.orientation})

function rowing.init(_)
end

function rowing:update(dt)
  for i = 1, self.pool.size do
    self.pool:get(i):get(_components.paddle):update(dt)
  end
end

function rowing:start_game()
  self:getInstance():addEntity(_entities.boatboy(Vector(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)))
end

function rowing.action_held(_, _, _)
end

function rowing:action_pressed(action, entity)
  assert(entity:has(_components.paddle) and entity:has(_components.orientation))

  local paddle = entity:get(_components.paddle)
  if action == "left" or action == "right" then
    paddle:set(action)
  elseif action == "row" then
    self:row(entity)
  end
end

function rowing:row(entity)
  local paddle = entity:get(_components.paddle)
  if paddle.ready then
    local direction_rowed = paddle:row()
    local orientation = entity:get(_components.orientation)
    local angle_delta = 0.1

    -- TODO: not sure yet which way around it should be
    if direction_rowed == "left" then
      orientation:adjust(angle_delta)
    else
      orientation:adjust(-angle_delta)
    end
  end
end

function rowing:draw_ui()
  local ROW_BAR_WIDTH = love.graphics.getWidth() * _constants.ROW_BAR_WIDTH
  local ROW_BAR_HEIGHT = love.graphics.getHeight() * _constants.ROW_BAR_HEIGHT
  for i = 1, self.pool.size do
    local paddle = self.pool:get(i):get(_components.paddle)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle(
      "fill",
      (love.graphics.getWidth() / 2) - (ROW_BAR_WIDTH / 2),
      love.graphics.getHeight() - ROW_BAR_HEIGHT,
      (ROW_BAR_WIDTH) * paddle.percentage_ready,
      ROW_BAR_HEIGHT
    )
    _util.l.resetColour()
    love.graphics.rectangle(
      "line",
      (love.graphics.getWidth() / 2) - (ROW_BAR_WIDTH / 2),
      love.graphics.getHeight() - ROW_BAR_HEIGHT,
      ROW_BAR_WIDTH,
      ROW_BAR_HEIGHT
    )

    _util.l.resetColour()
  end
end

function rowing:draw()
  local rectangle_width = 30
  local rectangle_height = 150
  for i = 1, self.pool.size do
    local e = self.pool:get(i)
    local orientation = e:get(_components.orientation)
    local position = e:get(_components.transform).position

    love.graphics.setColor(1, 0.5, 0.5, 1)

    -- push matrix
    love.graphics.push()
    -- Move object to its final destination
    love.graphics.translate(position.x, position.y)
    -- Apply rotations
    love.graphics.rotate(orientation.angle)

    -- Draw with position relative to object's centre
    love.graphics.rectangle("fill", -rectangle_width / 2, -rectangle_height / 2, rectangle_width, rectangle_height)

    -- pop matrix
    love.graphics.pop()
    _util.l.resetColour()
  end
end

return rowing
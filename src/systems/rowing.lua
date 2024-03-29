local rowing =
  System(
  {
    _components.transform,
    _components.controlled,
    _components.paddle,
    _components.orientation,
    _components.boat,
    _components.dimensions,
    "PLAYER"
  }
)

function rowing:init()
  self.boatboy_scale = 1.5 -- TODO: we could oscilate this to give a "bobbing in water" effect
  self.current_ferryman_frame = 1

  self.animation_timer = Timer.new()
  self.animation_timer:every(
    1,
    function()
      self.current_ferryman_frame = self.current_ferryman_frame + 1
      if self.current_ferryman_frame > 2 then
        self.current_ferryman_frame = 1
      end
    end
  )

  self.player_bobbing_duration = 1.5
  self.player_bobbing_timer = self.player_bobbing_duration
  self.player_bobbing_up = false
end

-- Prepare the world
function rowing:start_game(player_position)
  self:getInstance():addEntity(_entities.boatboy(player_position))
end

function rowing.action_held(_, action, entity)
  local paddle = entity:get(_components.paddle)
  local boat = entity:get(_components.boat)
  local canMove = entity:get(_components.controlled).canMove
  if canMove then
    if action == "left" then --boat controls are inverted, this feels more natural for the not-so-boaty (maybe an option to toggle it?)
      if paddle.ready then
        paddle:set("right")
      end
    elseif action == "right" then
      if paddle.ready then
        paddle:set("left")
      end
    elseif action == "reverse" then
      if paddle.ready then
        boat:reverse()
      end
    elseif action == "row" then
      assert(entity:has(_components.orientation))
      if paddle.rowing and paddle.side ~= "none" then
        boat:push(entity)
      else
        paddle.rowing = false
      end
    end
  end
end

function rowing.action_released(_, action, entity)
  local canMove = entity:get(_components.controlled).canMove
  if action == "row" and canMove then
    local paddle = entity:get(_components.paddle)
    paddle.rowing = false
    paddle.percentage_at_press = 0
  end
end

function rowing:action_pressed(action, entity)
  assert(entity:has(_components.paddle) and entity:has(_components.orientation))
  local paddle = entity:get(_components.paddle)
  local canMove = entity:get(_components.controlled).canMove

  if action == "row" and paddle.ready and paddle.side ~= "none" and canMove then
    paddle.percentage_at_press = paddle.percentage_rowed
    paddle.rowing = true
    self:row(entity)
  end
end

function rowing:row(entity)
  local paddle = entity:get(_components.paddle)
  local boat = entity:get(_components.boat)
  if paddle.rowing and paddle.side ~= "none" then
    local direction_rowed = paddle:row(self:getInstance())
    local orientation = entity:get(_components.orientation)

    -- apply rowing force
    entity:get(_components.boat):push(entity)

    local angle_delta = _constants.ROW_ANGLE_DELTA

    if love.keyboard.isDown("lshift", "rshift") then
      angle_delta = angle_delta + (0.15 * math.pi)
    end

    if direction_rowed == "left" then
      if boat.is_reversing then
        orientation:adjust(-angle_delta)
      else
        orientation:adjust(angle_delta)
      end
    elseif direction_rowed == "right" then
      if boat.is_reversing then
        orientation:adjust(angle_delta)
      else
        orientation:adjust(-angle_delta)
      end
    end
  end
end

function rowing:update(dt)
  self.animation_timer:update(dt)

  self.player_bobbing_timer = self.player_bobbing_timer + dt
  if self.player_bobbing_timer > self.player_bobbing_duration then
    self.player_bobbing_up = not self.player_bobbing_up
    self.player_bobbing_timer = self.player_bobbing_timer - self.player_bobbing_duration
  end

  if self.player_bobbing_up then
    self.boatboy_scale = self.boatboy_scale + (0.04 * dt)
  else
    self.boatboy_scale = self.boatboy_scale - (0.04 * dt)
  end

  for i = 1, self.PLAYER.size do
    local e = self.PLAYER:get(i)
    e:get(_components.paddle):update(dt)
    local orientation = e:get(_components.orientation)
    local boat = e:get(_components.boat)
    local transform = e:get(_components.transform)

    orientation:update(dt)
    boat:update(dt)

    -- think this might be different behaviour with different fps (no dt component)?
    transform.velocity = transform.velocity + (Vector.fromPolar(orientation.angle - math.pi / 2, boat.force)) * dt

    -- apply water friction
    if transform.velocity:len() > 0 then
      transform.velocity =
        transform.velocity -
        transform.velocity:normalized() * (transform.velocity:len() * _constants.WATER_FRICTION * dt)
    end
  end
end

function rowing:draw_ui()
  local ROW_BAR_WIDTH = love.graphics.getWidth() * _constants.ROW_BAR_WIDTH
  local ROW_BAR_HEIGHT = love.graphics.getHeight() * _constants.ROW_BAR_HEIGHT
  for i = 1, self.PLAYER.size do
    local e = self.PLAYER:get(i)
    local paddle = e:get(_components.paddle)

    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    love.graphics.rectangle("fill", (love.graphics.getWidth()) - (ROW_BAR_WIDTH), 0, ROW_BAR_WIDTH, ROW_BAR_HEIGHT)
    love.graphics.setColor(paddle.timer_color)
    love.graphics.rectangle(
      "fill",
      (love.graphics.getWidth()) - (ROW_BAR_WIDTH),
      ROW_BAR_HEIGHT,
      (ROW_BAR_WIDTH),
      -(ROW_BAR_HEIGHT * paddle.percentage_rowed)
    )

    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    love.graphics.rectangle("line", (love.graphics.getWidth()) - (ROW_BAR_WIDTH), 0, ROW_BAR_WIDTH, ROW_BAR_HEIGHT)

    _util.l.resetColour()
  end
end

function rowing:draw()
  for i = 1, self.PLAYER.size do
    local e = self.PLAYER:get(i)
    local orientation = e:get(_components.orientation)
    local position = e:get(_components.transform).position
    local dimensions = e:get(_components.dimensions)
    local paddle = e:get(_components.paddle)

    _util.l.resetColour()

    local paddle_offset = paddle.rowing_angle_offset
    if love.keyboard.isDown("lshift", "rshift") then
      paddle_offset = paddle_offset + math.pi / 10
    end

    if e:get(_components.boat).is_reversing then
      paddle_offset = -paddle_offset
    end

    love.graphics.draw(
      _sprites.sheet,
      _sprites.quads["boat"],
      position.x,
      position.y,
      orientation.angle,
      self.boatboy_scale,
      self.boatboy_scale,
      dimensions.width / 2,
      dimensions.height / 2
    )

    if paddle.side == "left" then
      love.graphics.draw(
        _sprites.sheet,
        _sprites.quads["paddle_left"],
        position.x,
        position.y,
        orientation.angle - paddle_offset,
        self.boatboy_scale,
        self.boatboy_scale,
        30,
        10
      )
      love.graphics.draw(
        _sprites.sheet,
        _sprites.quads["ferryman_left"][self.current_ferryman_frame],
        position.x,
        position.y,
        orientation.angle,
        self.boatboy_scale,
        self.boatboy_scale,
        dimensions.width / 2
      )
    elseif paddle.side == "right" then
      love.graphics.draw(
        _sprites.sheet,
        _sprites.quads["paddle_right"],
        position.x,
        position.y,
        orientation.angle + paddle_offset,
        self.boatboy_scale,
        self.boatboy_scale,
        2,
        10
      )

      love.graphics.draw(
        _sprites.sheet,
        _sprites.quads["ferryman_right"][self.current_ferryman_frame],
        position.x,
        position.y,
        orientation.angle,
        self.boatboy_scale,
        self.boatboy_scale,
        dimensions.width / 2 + 1
      )
    elseif paddle.side == "none" then
      love.graphics.draw(
        _sprites.sheet,
        _sprites.quads["ferryman_neutral"],
        position.x,
        position.y,
        orientation.angle,
        self.boatboy_scale,
        self.boatboy_scale,
        dimensions.width / 2
      )
    end
  end
end

return rowing

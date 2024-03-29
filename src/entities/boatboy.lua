return function(position)
  local image = love.graphics.newImage("assets/protag.png")
  local BOAT_WIDTH = 32 -- 32
  local BOAT_HEIGHT = 62 -- 64
  local boatboy =
    Entity():give(_components.transform, position):give(_components.orientation):give(
    _components.controlled,
    {a = "left", d = "right", s = "reverse", space = "row", e = "use", ["return"] = "next"}
  ):give(_components.paddle):give(_components.boat):give(_components.camera_target):give(
    _components.collides,
    BOAT_WIDTH,
    BOAT_HEIGHT,
    Vector(0, 0)
  ):give(_components.dimensions, "RECTANGLE", {width = BOAT_WIDTH, height = BOAT_HEIGHT}):give(
    _components.dialogue,
    image
  ):give(_components.inventory):apply()
  return boatboy
end

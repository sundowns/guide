return function(position, variant)
  local obstacle =
    Entity():give(_components.transform, position):give(_components.collides, 32, 32, Vector(32, 16)):give(
    _components.dimensions,
    32,
    32
  ):give(_components.obstacle, "default", variant or 1):apply()
  return obstacle
end

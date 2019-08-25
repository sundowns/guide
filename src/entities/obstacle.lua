return function(position)
  local obstacle =
    Entity():give(_components.transform, position):give(_components.collides, 32, 32, Vector(32, 16)):give(
    _components.dimensions,
    32,
    32
  ):apply()
  return obstacle
end
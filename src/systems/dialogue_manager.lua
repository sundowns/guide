local dialogue_manager = System({_components.dialogue, _components.controlled})

function dialogue_manager:init()
  self.isActive = false
  self.boatboy_image = love.graphics.newImage("assets/protag.png")
  self.nextSoul = nil
  self.sound = love.audio.newSource("assets/audio/chat.wav", "static")
end

function dialogue_manager:start_dialogue(entity)
  if not self.isActive then
    local dialogue = entity:get(_components.dialogue)
    self.isActive = true
    for i = 1, self.pool.size do
      if self.pool:get(i):has(_components.controlled) then
        self.pool:get(i):get(_components.controlled).canMove = false
      end
    end

    local collect =
      _dialogue["SOUL_" .. dialogue.index][1](self.boatboy_image, dialogue.image, _fonts["DIALOGUE"], self.sound)
    if collect and self.nextSoul == nil then
      self.nextSoul = entity
    end
    self.isActive = Talkies.isOpen()
  end
end

function dialogue_manager:action_released(action, entity)
  local controlled = entity:get(_components.controlled)

  if action == "next" and self.isActive then
    Talkies.onAction()
    self.isActive = Talkies.isOpen()
    if not Talkies.isOpen() then
      for i = 1, self.pool.size do
        if self.pool:get(i):has(_components.inventory) then
          self.pool:get(i):get(_components.inventory):addSoul(self.nextSoul)
          self:getInstance():emit("remove_soul", self.nextSoul)
          self.nextSoul = nil
        end
      end
      self.nextSoul = nil
      controlled.canMove = true
    end
  end
end

function dialogue_manager.update(_, dt)
  Talkies.update(dt)
end

function dialogue_manager.draw_ui(_)
  Talkies.draw()
end

return dialogue_manager

local floor,ceil,min,max = math.floor, math.ceil, math.min, math.max
local abs = math.abs
local random = math.random

local recycle_one = function(player)
  if #player.grave > 0 then
    player:grave_to_bottom_deck(#player.grave)
  end
end

local ex2_recycle = function(player, char)
  if #player.grave >= 5 and
      #player:hand_idxs_with_preds(pred.neg(pred[char.faction])) == 0 and
      #player:field_idxs_with_preds(pred.neg(pred[char.faction])) == 0 then
    local target = uniformly(player:grave_idxs_with_preds(pred.follower))
    if target then
      player:grave_to_bottom_deck(target)
    end
  end
end

local sita_vilosa = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    if idx < 4 and player.opponent.field[idx] then
	buff[idx] = {sta={"-",1}}
    end
  end
  buff:apply()
end

local cinia_pacifica = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player.opponent,target_idx,{atk={"-",1},sta={"-",1}}):apply()
end

local luthica_preventer = function(player)
  local target_idxs = player:field_idxs_with_preds(pred[player.character.faction], pred.follower)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  OneBuff(player,target_idx,{atk={"+",1},sta={"+",1}}):apply()
end

local iri_flina = function(player)
  if player:field_size() > player.opponent:field_size() then
    OneBuff(player.opponent,0,{life={"-",1}}):apply()
  end
end

local curious_vernika = function(player)
  local idx = player.opponent:field_idxs_with_most_and_preds(pred.def, pred.follower)[1]
  if idx then
    OneBuff(player.opponent,idx,{def={"=",0}}):apply()
  end
end

local thorn_witch_rose = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local target_idx = uniformly(nme_followers)
  local buff_size = ceil(math.abs(player.opponent.field[target_idx].size - player.opponent.field[target_idx].def)/2)
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},sta={"-",buff_size}}):apply()
end

local head_knight_jaina = function(player)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    else
      OneBuff(player, target, {atk={"+",2}}):apply()
    end
  end
end

local clarice = function(stats, skill)
  return function(player)
    local to_kill = player:field_idxs_with_preds(function(card) return card.id == 300201 end)
    for _,idx in ipairs(to_kill) do
      player:field_to_grave(idx)
    end
    local slot = player:last_empty_field_slot()
    if slot then
      if stats == "turn" then
        local amt = 10 - (player.game.turn % 10)
        if amt ~= 10 then
          player.field[slot] = Card(300201)
          OneBuff(player, slot, {atk={"=",amt},def={"=",1},sta={"=",amt}}):apply()
        end
      else
        player.field[slot] = Card(300201)
        OneBuff(player, slot, {atk={"=",stats[1]},def={"=",stats[2]},sta={"=",stats[3]}}):apply()
        if skill then
          player.field[slot].skills[1] = 1075
        end
      end
    end
  end
end

local rihanna = function(top, bottom)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    local slot = uniformly(player:empty_field_slots())
    if target and slot then
      local card = player.field[target]
      player.field[target] = nil
      player.field[slot] = card
      if slot <= 3 then
        OneBuff(player, slot, top):apply()
      end
      if slot >= 3 then
        OneBuff(player, slot, bottom):apply()
      end
    end
  end
end

local council_vp_tieria = function(group_pred, faction_pred)
  return function(player)
    local target = uniformly(player:field_idxs_with_preds(group_pred, pred.follower))
    local faction_count = #player:field_idxs_with_preds(faction_pred, pred.follower)
    if target then
      if faction_count == 1 then
        OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
      elseif faction_count >= 2 then
        OneBuff(player, target, {size={"-",1},atk={"+",1},sta={"+",2}}):apply()
      end
    end
  end
end

local hanbok_sita = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"+",1},sta={"+",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(player, target, the_buff):apply()
  end
end

local hanbok_cinia = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local buff = GlobalBuff(player)
  if target then
    buff.field[opponent][target] = {def={"-",1},sta={"-",2}}
  end
  target = opponent:hand_idxs_with_preds(pred.follower)[1]
  if target then
    buff.hand[opponent][target] = {}
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      buff.hand[opponent][target].def = {"-",1}
    end
    if #player.hand >= #opponent.hand then
      local amt = min(2,opponent.hand[target].sta-1)
      buff.hand[opponent][target].sta={"-",amt}
    end
  end
  buff:apply()
end

local hanbok_luthica = function(player, opponent, my_card)
  local n = 1
  if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
    n = n + 1
  end
  if #player.hand >= #opponent.hand then
    n = n + 1
  end
  for i=1,n do
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end

local hanbok_iri = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local the_buff = {atk={"-",1},sta={"-",2}}
  if target then
    if #opponent:field_idxs_with_preds() > #player:field_idxs_with_preds() then
      the_buff.atk[2] = the_buff.atk[2] + 1
    end
    if #player.hand >= #opponent.hand then
      the_buff.sta[2] = the_buff.sta[2] + 1
    end
    OneBuff(opponent, target, the_buff):apply()
  end
end

characters_func = {

--Mysterious Girl Sita Vilosa
[100001] = sita_vilosa,

--Beautiful and Smart Cinia Pacifica
[100002] = cinia_pacifica,

--Crux Knight Luthica
[100003] = luthica_preventer,

--Runaway Iri Flina
[100004] = iri_flina,

--Nold
[100005] = function(player)
  if #player.hand == 0 then
    return
  end
  local hand_idx = math.random(#player.hand)
  local buff = GlobalBuff(player) --stolen from Tower of Books
  buff.hand[player][hand_idx] = {size={"+",1}}
  buff:apply()
  local my_cards = player:field_idxs_with_preds(function(card) return card.size > 2 end)
  if #my_cards == 0 then
    return
  end
  local target_idx = uniformly(my_cards)
  OneBuff(player,target_idx,{size={"-",1}}):apply()
end,

--Ginger
[100006] = function(player)
  local ncards = #player:field_idxs_with_preds()
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size >= ncards end)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",1}, sta={"+",2}}
  end
  buff:apply()
end,

--Curious Girl Vernika
[100007] = curious_vernika,

--Cannelle
[100008] = function(player)
  if player.opponent:field_size() == 0 or #player:get_follower_idxs() == 0 then
    return
  end
  local max_size = player.opponent.field[player.opponent:field_idxs_with_most_and_preds(pred.size)[1]].size
  local min_size = player.field[player:field_idxs_with_least_and_preds(pred.size)[1]].size
  local buff_size = abs(max_size - min_size)
  local target_idxs = player:field_idxs_with_least_and_preds(pred.size, pred.follower)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"+",buff_size}, sta={"+",buff_size}}
  end
  buff:apply()
end,

--Gart
[100009] = function(player)
  local num_follower = #player.opponent:get_follower_idxs()
  if num_follower == 0 then
    return
  end
  local num_vita = #player.opponent:field_idxs_with_preds({pred.follower, pred.V})
  local buff = OnePlayerBuff(player.opponent)
  if num_follower==num_vita then
    local target_idxs = shuffle(player.opponent:get_follower_idxs())
    for i=1,2 do
	    if target_idxs[i] then
	      buff[target_idxs[i]] = {sta={"-",1}}
	    end
    end
  else
    local target_idx = uniformly(player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.faction.V)))
    if target_idx then
	    buff[target_idx] = {atk={"-",2},sta={"-",2}}
    end
  end
  buff:apply()
end,

--Dress Sita
[100010] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local buff = OnePlayerBuff(player.opponent)
  if #nme_followers > 1 then
    local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
    buff[target_idx] = {atk={"-",2},def={"-",1},sta={"-",2}}
  elseif #nme_followers == 1 then
    buff[nme_followers[1]] = {sta={"-",2}}
  end
  buff:apply()
end,

--Dress Cinia
[100011] = function(player)
  local target_idxs = player.opponent:get_follower_idxs()
  if #target_idxs == 0 then
    return
  end
  local max_size
  if #player.hand == 0 then
    max_size = 0
  elseif #player.hand == 1 then
    max_size = math.ceil(player.hand[1].size/2)
  else
    max_size = math.ceil((player.hand[1].size + player.hand[2].size)/2)
  end
  local target_idx = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size <= max_size end)[1]
  if target_idx then
    OneBuff(player.opponent,target_idx,{atk={"-",2},def={"-",2},sta={"-",2}}):apply()
  end
end,

--Dress Luthica
[100012] = function(player)
  local buff = OnePlayerBuff(player)
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local target_idxs = player:get_follower_idxs()
  if math.abs(size1 - size2)%2 == 1 then
    for _,idx in ipairs(target_idxs) do
	    buff[idx] = {sta={"+",2}}
    end
  else
    for _,idx in ipairs(target_idxs) do
	    buff[idx] = {atk={"+",2}}
    end
  end
  buff:apply()
end,

--Dress Iri
[100013] = function(player)
  if #player.hand == 0 then
    return
  end
  if (player.character.life + player.hand[1].size)%2 == 0 then
    OneBuff(player,0,{life={"+",3}}):apply()
  end
end,

--Dress Vernika
[100014] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, function(card) return card.size > 1 end)
  if #target_idxs == 0 then
    return
  end
  local size1 = 0
  local size2 = 0
  if player.hand[1] then
    size1 = player.hand[1].size
  end
  if player.hand[2] then
    size2 = player.hand[2].size
  end
  local size_diff = math.abs(size1 - size2)
  OneBuff(player,uniformly(target_idxs),{size={"-",size_diff}}):apply()
end,

--Kendo Sita
[100015] = function(player)
  if #player.opponent:get_follower_idxs() == 0 then
    return
  end
  if not player.opponent.field[3] then
    local old_card_idx = uniformly(player.opponent:get_follower_idxs())
    local card = player.opponent.field[old_card_idx]
    player.opponent.field[3] = card
    player.opponent.field[old_card_idx] = nil
  end
  if pred.follower(player.opponent.field[3]) then
    OneBuff(player.opponent,3,{sta={"-",3}}):apply()
  end
end,

--Chess Cinia
[100016] = function(player)
  local target_idx = player.opponent:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  local followers = player:get_follower_idxs()
  if not target_idx or #followers == 0 then
    return
  end
  local buff_size = 0
  if player.field[4] then
    buff_size = math.ceil((player.field[followers[1]].size + player.field[4].size)/2)
  else
    buff_size = math.ceil(player.field[followers[1]].size/2)
  end
  OneBuff(player.opponent,target_idx,{atk={"-",buff_size},sta={"-",buff_size}}):apply()
end,

--Sports Luthica
[100017] = function(player)
  if player.field[5] and pred.follower(player.field[5]) and not player.field[1] then
    local card = player.field[5]
    player.field[1] = card
    player.field[5] = nil
    OneBuff(player,1,{sta={"+",5}}):apply()
  elseif player.field[1] and pred.follower(player.field[1]) and not player.field[5] then
    local card = player.field[1]
    player.field[5] = card
    player.field[1] = nil
    OneBuff(player,5,{sta={"+",5}}):apply()
  end
end,

--Cheerleader Iri
[100018] = function(player)
  local hand_idx = uniformly(player:hand_idxs_with_preds(function(card) return card.size >= 2 end))
  if hand_idx then
    local buff = GlobalBuff(player) --stolen from Tower of Books
    buff.hand[player][hand_idx] = {size={"-",1}}
    buff:apply()
  end
end,

--Team Manager Vernika
[100019] = function(player)
  local hand_size = #player.hand
  if hand_size < 4 then
    for i=1,hand_size do
	    player:hand_to_bottom_deck(1)
    end
  else
    return
  end
  local buff_size = math.ceil(hand_size/2)
  local followers = player:get_follower_idxs()
  if #followers > 0 then
    OneBuff(player,uniformly(followers),{atk={"+",buff_size},sta={"+",buff_size}}):apply()
  end
end,

--Swimwear Sita
[100020] = function(player)
  local hand_idx = player:hand_idxs_with_least_and_preds(pred.size, pred.follower)[1]
  local nme_followers = player.opponent:get_follower_idxs()
  if (not hand_idx) or #nme_followers == 0 then
    return
  end
  local def_lose = math.floor(player.hand[hand_idx].atk/2)
  OneBuff(player.opponent,uniformly(nme_followers),{def={"-",def_lose}}):apply()
end,

--Swimwear Cinia
[100021] = function(player)
  local my_followers = player:get_follower_idxs()
  local nme_followers = player.opponent:get_follower_idxs()
  if #my_followers == 0 or #nme_followers == 0 then
    return
  end
  local my_size = player.field[my_followers[1]].size
  local target_idxs = player.opponent:field_idxs_with_preds(pred.follower, function(card) return card.size < my_size end)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(target_idxs) do
    buff[idx] = {atk={"-",1},sta={"-",2}}
  end
  buff:apply()
end,

--Swimwear Luthica
[100022] = function(player)
  local my_followers = player:get_follower_idxs()
  if #player.hand == 0 or #my_followers == 0 then
    return
  end
  if pred.C(player.hand[1]) and #player:field_idxs_with_preds(pred.neg(pred.C)) == 0 then
    OneBuff(player,uniformly(my_followers),{atk={"+",2},sta={"+",2}}):apply()
  end
end,

--Swimwear Iri
[100023] = function(player)
  if player.opponent.field[5] then
    player.opponent:field_to_bottom_deck(5)
  end
  if player.opponent:field_size() == 0 then
    return
  end
  local target_idx = uniformly(player.opponent:field_idxs_with_preds())
  local card = player.opponent.field[target_idx]
  for i=target_idx,4 do
    if not player.opponent.field[i+1] then
	    player.opponent.field[i+1] = card
	    player.opponent.field[target_idx] = nil
	    break
    end
  end
  if player.opponent.field[5] then
    player.opponent:destroy(5)
  end
end,

--Swimwear Vernika
[100024] = function(player)
  if #player.opponent.hand < 2 or #player:get_follower_idxs() == 0 then
    return
  end
  local new_size = math.abs(player.opponent.hand[1].size - player.opponent.hand[2].size)
  local target_idx = player:field_idxs_with_most_and_preds(pred.size, pred.follower)[1]
  if target_idx then
    OneBuff(player,target_idx,{size={"=",new_size}}):apply()
  end
end,

--Lightseeker Sita
[100025] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  local target_idxs = player:field_idxs_with_preds(pred.D, pred.follower, function(card) return card.size < 10 end)
  if #target_idxs == 0 then
    return
  end
  local target_idx = uniformly(target_idxs)
  local buff_size = floor(1.5*player.field[target_idx].size)
  player:field_to_grave(target_idx)
  if #nme_followers > 0 then
    OneBuff(player.opponent,uniformly(nme_followers),{sta={"-",buff_size}}):apply()
  end
end,

--Foreign Student Cinia
[100026] = function(player)
  local my_followers = player:get_follower_idxs()
  if #my_followers == 0 or #player.hand == 0 then
    return
  end
  local target_idx = uniformly(my_followers)
  if pred.V(player.hand[1]) then
    OneBuff(player,target_idx,{atk={"+",1},sta={"+",2}}):apply()
  elseif pred.A(player.hand[1]) then
    OneBuff(player,target_idx,{sta={"+",3}}):apply()
  elseif pred.C(player.hand[1]) then
    OneBuff(player,target_idx,{def={"+",1}}):apply()
  elseif pred.D(player.hand[1]) then
    OneBuff(player,target_idx,{size={"-",2}}):apply()
  end
end,

--Blue Reaper Luthica
[100027] = function(player)
  local target_idxs = player:field_idxs_with_preds(pred.follower, pred.C)
  if #target_idxs == 0 then
    return
  end
  local crux_cards = #player.opponent:field_idxs_with_preds(pred.C) + #player.opponent:hand_idxs_with_preds(pred.C)
  local non_crux_cards = #player.opponent:field_idxs_with_preds() + #player.opponent.hand - crux_cards
  OneBuff(player,uniformly(target_idxs),{sta={"+",math.max(crux_cards, non_crux_cards)}}):apply()
end,

--Lovestruck Iri
[100028] = function(player)
  local factions = {}
  for i=1,5 do
    if player.opponent.hand[i] and factions[1] ~= player.opponent.hand[i].faction then
      factions[#factions+1] = player.opponent.hand[i].faction
    end
    if player.opponent.field[i] and factions[1] ~= player.opponent.field[i].faction then
      factions[#factions+1] = player.opponent.field[i].faction
    end
  end
  if #factions > 1 and #player.hand > 0 then
    local hand_idx = math.random(#player.hand)
    local buff = GlobalBuff(player)
    buff.hand[player][hand_idx] = {size={"-",2}}
    buff:apply()
  end
end,

--Night Denizen Vernika
[100029] = function(player)
  local nme_followers = player.opponent:get_follower_idxs()
  if #nme_followers == 0 then
    return
  end
  local target_idx = uniformly(nme_followers)
  OneBuff(player.opponent,target_idx,{sta={"-",3}}):apply()
  OneBuff(player, 0, {life={"+",1}}):apply()
end,

--Thorn Witch Rose
[100030] = thorn_witch_rose,

-- rose pacifica
[100031] = function(player)
  local hand_idx = player:hand_idxs_with_preds(pred.D)[1]
  if hand_idx then
    local sz = player.hand[hand_idx].size
    player:hand_to_grave(hand_idx)
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",sz},sta={"-",sz}}):apply()
    end
  end
end,

-- blood witch rose
[100032] = function(player)
  if player.game.turn % 1 == 1 then
    local idx = uniformly(player.opponent:hand_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:hand_to_exile(idx)
    end
  else
    local idx = uniformly(player.opponent:grave_idxs_with_preds(pred.spell))
    if idx then
      player.opponent:grave_to_exile(idx)
    end
  end
end,

-- outcast rose
[100033] = function(player)
  if #player:field_idxs_with_preds(pred.follower) >= 2 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.D))
    local buff = OnePlayerBuff(player)
    buff[0] = {life={"-",1}}
    if target then
      buff[target] = {atk={"+",2},def={"+",1},sta={"+",2}}
    end
    buff:apply()
  end
end,

-- picnic rose
[100034] = function(player)
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  if #targets >= 2 then
    local amt = abs(player.field[targets[1]].size - player.field[targets[2]].size)
    local buff = OnePlayerBuff(player)
    for i=1,2 do
      buff[targets[i]] = {sta={"+",amt}}
    end
    buff:apply()
  end
end,

-- wedding dress rose
[100035] = thorn_witch_rose,

-- wedding dress sita
[100036] = sita_vilosa,

-- wedding dress cinia
[100037] = cinia_pacifica,

-- wedding dress luthica
[100038] = luthica_preventer,

-- wedding dress iri
[100039] = iri_flina,

-- wedding dress vernika
[100040] = curious_vernika,

-- laevateinn
[100041] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    OneBuff(player, 0, {life={"+",ceil(size/2)}}):apply()
  end
end,

-- sisters sion & rion
[100042] = function(player)
  local field_idxs = player:field_idxs_with_preds(pred.follower)
  local hand_idxs = player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(field_idxs)
  if target then
    OneBuff(player, target, {atk={"+",#hand_idxs},sta={"+",#field_idxs}}):apply()
  end
end,

-- head knight jaina
[100043] = head_knight_jaina,

-- resting jaina
[100044] = function(player, opponent, my_card)
  if player.game.turn % 3 == 0 then
    local targets = shuffle(player:field_idxs_with_preds(pred.follower, pred.C))
    local buff = OnePlayerBuff(player)
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",3},sta={"+",3}}
    end
    buff[0] = {life={"+",2}}
    buff:apply()
  end
end,

-- adept jaina
[100045] = function(player, opponent, my_card)
  local amt = min(4, 6-#player.hand)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",amt}}):apply()
  end
end,

-- swimwear jaina
[100046] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target and player:first_empty_field_slot() then
    for i=target+1,5 do
      if not player.field[i] then
        local card = player.field[target]
        player.field[target] = nil
        player.field[i] = card
        OneBuff(player, i, {atk={"+",i}}):apply()
        return
      end
    end
    local slot = player:first_empty_field_slot()
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
    OneBuff(player, slot, {atk={"+",slot}}):apply()
  end
end,

-- sword planter jaina
[100047] = function(player, opponent, my_card)
  local amt = 0
  local sizes = {}
  for i=1,#player.hand do
    if not sizes[player.hand[i].size] then
      sizes[player.hand[i].size] = true
      amt = amt + 1
    end
  end
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  local buff = OnePlayerBuff(player)
  for i=1,min(2,#targets) do
    buff[targets[i]] = {atk={"+",amt}}
  end
  buff:apply()
end,

-- wedding dress jaina
[100048] = head_knight_jaina,

-- sigma
[100049] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local hand_targets = shuffle(player:hand_idxs_with_preds(pred.follower))
  local targets = shuffle(player:field_idxs_with_preds(pred.follower))
  for i=1,min(2,#hand_targets) do
    buff.hand[player][hand_targets[i]] = {atk={"+",1},sta={"+",1}}
  end
  for i=1,min(2,#targets) do
    buff.field[player][targets[i]] = {sta={"+",1}}
  end
  buff:apply()
end,

-- child sita
[100050] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs({1,2,5}) do
    if opponent.field[idx] and pred.follower(opponent.field[idx]) then
      buff[idx] = {sta={"-",2}}
    end
  end
  buff:apply()
end,

-- child cinia
[100051] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].size >= 3 then
      OneBuff(opponent, target, {atk={"-",2}}):apply()
    else
      OneBuff(opponent, target, {sta={"-",3}}):apply()
    end
  end
end,

-- child luthica
[100052] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.field[target].size >= 3 then
      OneBuff(player, target, {atk={"+",2}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- child iri
[100053] = function(player, opponent, my_card)
  if #player.hand % 2 == 0 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {atk={"-",1},def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- hot springs sita
[100054] = function(player, opponent, my_card)
  local buff = OnePlayerBuff(opponent)
  for i=2,4 do
    if opponent.field[i] and pred.follower(opponent.field[i]) then
      buff[i] = {sta={"-",2}}
    end
  end
  buff:apply()
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",1}}):apply()
  end
end,

-- hot springs cinia
[100055] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].def <= 0 then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",2}}):apply()
    else
      OneBuff(opponent, target, {def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- hot springs luthica
[100056] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.field[target].def >= 1 then
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {def={"+",1},sta={"+",1}}):apply()
    end
  end
end,

-- hot springs iri
[100057] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if opponent.field[target].sta >= 10 then
      OneBuff(opponent, target, {sta={"-",4}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},def={"-",1},sta={"-",1}}):apply()
    end
  end
end,

-- miracle panda panica
[100058] = function(player, opponent, my_card)
  if player.game.turn % 2 ==1 then
    local buff = OnePlayerBuff(player)
    local targets = shuffle(player:field_idxs_with_preds(pred.follower))
    for i=1,min(2,#targets) do
      buff[targets[i]] = {atk={"+",1}}
    end
    buff:apply()
  else
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {sta={"+",2}}):apply()
    end
  end
end,

-- child vernika
[100059] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(3,ceil(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = opponent:field_idxs_with_most_and_preds(pred.sta,pred.follower)[1]
    if target then
      OneBuff(opponent, target, {def={"-",amt}}):apply()
    end
  end
end,

-- child rose
[100060] = function(player, opponent, my_card)
  local hand_idx = player:hand_idxs_with_preds(pred.spell, pred.A,
      function(card) return card.size <= (9-player:field_size()) end)[1]
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = player:first_empty_field_slot()
  if hand_idx and slot then
    local amt = player.hand[hand_idx].size
    player:hand_to_field(hand_idx)
    if target then
      OneBuff(opponent, target, {atk={"-",amt},sta={"-",amt}}):apply()
    end
  end
end,

-- child jaina
[100061] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local my_guy = uniformly(player:field_idxs_with_preds(pred.follower))
  local op_guy = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if my_guy then
    buff.field[player][my_guy] = {atk={"+",2}}
  end
  if op_guy then
    buff.field[opponent][op_guy] = {atk={"-",1}}
  end
  buff:apply()
end,

-- child ginger
[100062] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
    player:field_to_top_deck(target)
  end
  target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2}}):apply()
  end
end,

-- child laevateinn
[100063] = function(player)
  local size_to_n = {}
  for i=1,#player.hand do
    local sz = player.hand[i].size
    size_to_n[sz] = (size_to_n[sz] or 0) + 1
  end
  local size = -1
  for k,v in pairs(size_to_n) do
    if v >= 2 and k > size then
      size = k
    end
  end
  if size > 0 then
    for i=1,5 do
      while player.hand[i] and player.hand[i].size == size do
        player:hand_to_bottom_deck(i)
      end
    end
    OneBuff(player, 0, {life={"+",min(4,ceil(size/2))}}):apply()
  end
end,

-- child sigma
[100064] = function(player, opponent, my_card)
  if player.hand[1] then
    local amt = min(4,floor(player.hand[1].size/2))
    player:hand_to_bottom_deck(1)
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",amt},sta={"+",amt}}):apply()
    end
  end
end,

-- layna scentriver
[100065] = luthica_preventer,

-- chief maid
[100066] = iri_flina,

-- new knight
[100067] = sita_vilosa,

-- nytitch
[100068] = cinia_pacifica,

-- alchemist clarice
[100069] = clarice({5,0,5}),

-- street idol clarice
[100070] = clarice("turn"),

-- assistant clarice
[100071] = clarice({1,0,9}),

-- swimwear clarice
[100072] = clarice({7,0,2}),

-- dress clarice
[100073] = clarice({3,0,3}, true),

-- wedding dress clarice
[100074] = clarice({5,0,5}),

-- lig nijes
[100075] = function(player)
  local life = player.opponent.character.life
  if 26 <= life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  elseif 16 <= life and life <= 20 then
    OneBuff(player, 0, {life={"+",1}}):apply()
  elseif life <= 9 then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  end
end,

-- child nold
[100076] = function(player, opponent, my_card)
  if (player.game.turn + #player.hand) % 2 == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower,
        function(card) return card.size >= 2 end))
    if target then
      OneBuff(player, target, {size={"-",2}}):apply()
    end
  end
end,

-- child cannelle
[100077] = function(player, opponent, my_card)
  local target = uniformly(opponent:hand_idxs_with_preds(pred.follower))
  if target then
    local buff = GlobalBuff(player)
    buff.hand[opponent][target] = {size={"=",1},atk={"=",5},def={"=",0},sta={"=",7}}
    buff:apply()
  end
end,

-- child gart
[100078] = function(player, opponent, my_card)
  if #player:field_idxs_with_preds(pred.A) + #player:hand_idxs_with_preds(pred.A) == 0 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",2},sta={"+",1}}):apply()
    end
  end
end,

-- child panica
[100079] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if player.game.turn % 2 == 0 then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {sta={"+",3}}):apply()
    end
  end
end,

-- bedroom nold
[100081] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.A))
  if target then
    OneBuff(player, target, {size={"-",1},sta={"+",2}}):apply()
  end
end,

-- bunny girl cannelle
[100083] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower,
      function(card) return card.size <= 5 end))
  if target then
    OneBuff(player, target, {size={"+",1},atk={"+",2},def={"+",1},sta={"+",2}}):apply()
  end
end,

-- rain-soaked gart
[100084] = function(player, opponent, my_card)
  local amt = #player:hand_idxs_with_preds(pred.follower)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {def={"-",amt},sta={"-",amt}}):apply()
  end
end,

-- hammered sigma
[100087] = function(player, opponent, my_card)
  if #player.hand > 0 then
    local n = player.hand[1].size
    local targets = player:hand_idxs_with_preds(pred.follower)
    local buff = GlobalBuff(player)
    for i=1,min(n,#targets) do
      buff.hand[player][targets[i]] = {atk={"+",1},sta={"+",1}}
    end
    buff:apply()
  end
end,

-- anj inyghem
[100088] = function(player)
  local life = player.opponent.character.life
  if 31 <= life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  elseif 20 <= life and life <= 25 then
    local target = uniformly(player:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  elseif 10 <= life and life <= 15 then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  elseif life <= 6 then
    OneBuff(player.opponent, 0, {life={"=",0}}):apply()
  end
end,

-- swimsuit sita
[100090] = function(player, opponent, my_card)
  local do_second = player.character.life < opponent.character.life
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(opponent, target, {sta={"-",3}}):apply()
  end
  if do_second then
    target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(opponent, target, {sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit cinia
[100091] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(opponent, target, {atk={"-",2},sta={"-",3}}):apply()
    else
      OneBuff(opponent, target, {atk={"-",1},sta={"-",2}}):apply()
    end
  end
end,

-- swimsuit luthica
[100092] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower, pred.C))
  if target then
    if player.character.life < opponent.character.life then
      OneBuff(player, target, {atk={"+",2},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",2}}):apply()
    end
  end
end,

-- swimsuit iri
[100093] = function(player)
  if player.character.life < player.opponent.character.life then
    OneBuff(player.opponent, 0, {life={"-",2}}):apply()
  else
    OneBuff(player, 0, {life={"+",1}}):apply()
  end
end,

-- vita principal treanna
[100095] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if pred.skill(player.field[target]) then
      player.field[target].skills = {}
      OneBuff(player, target, {size={"-",1},atk={"+",2},sta={"+",2}}):apply()
    else
      OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
    end
  end
end,

-- dean rihanna
[100096] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- dress rihanna
[100097] = rihanna({atk={"+",1},sta={"+",2}},{atk={"+",2},sta={"+",1}}),

-- swimwear rihanna
[100098] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  local slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
    if slot <= 3 then
      OneBuff(opponent, slot, {atk={"-",1},sta={"-",2}}):apply()
    end
    if slot >= 3 and opponent.field[slot] then
      OneBuff(opponent, slot, {atk={"-",2},sta={"-",1}}):apply()
    end
  end
end,

-- waitress rihanna
[100099] = rihanna({sta={"+",4}},{size={"-",1},atk={"+",1}}),

-- persuasive rihanna
[100100] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  local slot = uniformly(player:empty_field_slots())
  if target and slot then
    local card = player.field[target]
    player.field[target] = nil
    player.field[slot] = card
  end
  target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  slot = uniformly(opponent:empty_field_slots())
  if target and slot then
    local card = opponent.field[target]
    opponent.field[target] = nil
    opponent.field[slot] = card
  end
  local do_steal = false
  for i=5,1,-1 do
    if player.field[i] and opponent.field[i] then
      to_steal = true
    end
  end
  slot = player:first_empty_field_slot()
  target = uniformly(opponent:field_idxs_with_preds())
  if do_steal and slot and target then
    local card = opponent.field[target]
    opponent.field[target] = nil
    player.field[slot] = card
  end
end,

-- wedding dress rihanna
[100101] = rihanna({sta={"+",3}},{atk={"+",2}}),

-- hanbok sita
[100102] = hanbok_sita,

-- hanbok cinia
[100103] = hanbok_cinia,

-- hanbok luthica
[100104] = hanbok_luthica,

-- hanbok iri
[100105] = hanbok_iri,

-- vernika answer
[100107] = function(player, opponent, my_card)
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_bottom_deck(i)
    end
  end
end,

-- waiting sita
[100108] = function(player, _, char)
  ex2_recycle(player, char)
  local buff = {atk={"+",2},sta={"+",2}}
  if #player.deck <= #player.opponent.deck then
    buff.def = {"+",1}
    buff.sta[2]=3
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, buff):apply()
  end
end,

-- council president cinia
[100109] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local target = uniformly(player.opponent:field_idxs_with_preds(pred.follower))
    if target then
      OneBuff(player.opponent, target, {def={"-",1},sta={"-",2}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- wanderer luthica
[100110] = function(player, _, char)
  ex2_recycle(player, char)
  local buff = {atk={"+",2},sta={"+",2}}
  if #player.deck <= #player.opponent.deck then
    buff.sta[2]=3
    OneBuff(player.opponent, 0, {life={"-",1}}):apply()
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, buff):apply()
  end
end,

-- conflicted iri
[100111] = function(player, _, char)
  ex2_recycle(player, char)
  if #player.deck <= #player.opponent.deck then
    local targets = shuffle(player.opponent:field_idxs_with_preds(pred.follower))
    if targets[1] then
      OneBuff(player.opponent, targets[1], {sta={"-",3}}):apply()
    end
    if targets[2] then
      OneBuff(player.opponent, targets[2], {sta={"-",1}}):apply()
    end
  end
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    OneBuff(player, target, {atk={"+",2},sta={"+",2}}):apply()
  end
end,

-- office chief esprit
[100112] = function(player, opponent, my_card)
  local nskills = 0
  local followers = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(followers) do
    nskills = nskills + #player.field[idx]:squished_skills()
  end
  if nskills <= 2 then
    local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
    if target then
      opponent.field[target].skills = {}
    end
  else
    local target = uniformly(followers)
    OneBuff(player, target, {atk={"+",nskills},sta={"+",nskills}}):apply()
  end
end,

-- council vp tieria
[100113] = council_vp_tieria(pred.council, pred.V),

-- maid lesnoa
[100114] = council_vp_tieria(pred.maid, pred.A),

-- seeker odien
[100115] = council_vp_tieria(pred.seeker, pred.C),

-- lightning palomporom
[100116] = council_vp_tieria(pred.witch, pred.D),

-- ereshkigal
-- [100117] = function(player, opponent, my_card)
-- end,

-- apostle l red sun
[100118] = function(player, opponent, my_card)
  local target = uniformly(player:field_idxs_with_preds(pred.follower))
  if target then
    if #player.deck > 0 and pred.follower(player.deck[#player.deck]) then
      OneBuff(player, target, {atk={"+",1},sta={"+",3}}):apply()
    else
      OneBuff(player, target, {atk={"+",1},sta={"+",1}}):apply()
    end
  end
end,

-- wafuku sita
[100171] = hanbok_sita,

-- wafuku cinia
[100172] = hanbok_cinia,

-- wafuku luthica
[100173] = hanbok_luthica,

-- wafuku iri
[100174] = hanbok_iri,

-- hero sita
[100182] = hanbok_sita,

-- hero cinia
[100183] = hanbok_cinia,

-- hero luthica
[100184] = hanbok_luthica,

-- hero iri
[100185] = hanbok_iri,

-- rio
[110133] = function(player)
  local buff = OnePlayerBuff(player)
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"+",3},sta={"+",3}}
  end
  buff:apply()
  recycle_one(player)
end,

-- nanai
[110134] = function(player)
  local amt, opponent = 0, player.opponent
  for i=1,5 do
    while opponent.hand[i] and pred.spell(opponent.hand[i]) do
      opponent:hand_to_grave(i)
      amt = amt + 2
    end
  end
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(opponent:field_idxs_with_preds(pred.follower)) do
    buff[idx] = {atk={"-",amt},sta={"-",amt}}
  end
  buff:apply()
  recycle_one(player)
end,

-- seven
[110135] = function(player)
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    local card = player.opponent.field[idx]
    buff[idx] = {atk={"+",card.sta-1},sta={"=",1}}
  end
  buff:apply()
  recycle_one(player)
end,

-- new knight
[110136] = function(player)
  local buff = GlobalBuff(player)
  for _,idx in ipairs(player.opponent:field_idxs_with_preds(pred.follower)) do
    buff.field[player.opponent][idx] = {def={"-",2}}
  end
  for _,idx in ipairs(player:field_idxs_with_preds(pred.follower)) do
    buff.field[player][idx] = {def={"+",2}}
  end
  for _,idx in ipairs(player:hand_idxs_with_preds(pred.follower)) do
    buff.hand[player][idx] = {def={"+",2}}
  end
  buff:apply()
  recycle_one(player)
end,

-- origin disciple
[110137] = function(player)
  OneBuff(player, 0, {life={"+",8}}):apply()
end,

-- sion flina
[110138] = function(player)
  if #player.opponent:field_idxs_with_preds(pred.rion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
end,

-- rion flina
[110139] = function(player)
  local targets = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.sion))
  local buff = OnePlayerBuff(player.opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {atk={"-",2},def={"-",2},sta={"-",2}}
  end
  buff:apply()
  if #player.opponent:field_idxs_with_preds(pred.sion) > 0 then
    OneBuff(player, 0, {life={"-",7}}):apply()
  end
  recycle_one(player)
  recycle_one(player)
end,

-- frett
[110140] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(function(card) return card.size ~= 3 end)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- odien
[110141] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- lyrica
[110142] = function(player)
  local idxs = player.opponent:field_idxs_with_preds(pred.follower, pred.neg(pred.skill))
  for _,idx in ipairs(idxs) do
    player.opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- sarah
[110149] = function(player, opponent, my_card)
  local targets = {}
  for i=1,5 do
    if opponent.field[i] and pred.follower(opponent.field[i]) and
        ((opponent.field[i-1] and pred.follower(opponent.field[i-1])) or
          (opponent.field[i+1] and pred.follower(opponent.field[i+1])) or
          opponent.field[i].sta == 1) then
      targets[#targets+1] = i
    end
  end
  for _,idx in ipairs(targets) do
    opponent:destroy(idx)
  end
  recycle_one(player)
end,

-- gart
[110150] = function(player, opponent, my_card)
  if player.game.turn == 14 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
  recycle_one(player)
end,

-- knight messenger
[110151] = function(player, opponent, my_card)
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- gs 1st star
[110152] = function(player, opponent, my_card)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  local buff = OnePlayerBuff(opponent)
  for _,idx in ipairs(targets) do
    buff[idx] = {sta={"-",1}}
  end
  buff:apply()
  targets = opponent:field_idxs_with_preds(pred.follower, pred.skill)
  for _,idx in ipairs(targets) do
    opponent.field[idx].skills = {1237}
  end
  recycle_one(player)
end,

-- kana dtd
[110153] = function(player, opponent, my_card)
  OneBuff(player, 0, {life={"+",4}}):apply()
  while #player.grave > 0 do
    recycle_one(player)
  end
end,

-- lotte
[110154] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    if #player:field_idxs_with_preds() == 0 then
      OneBuff(opponent, 0, {life={"-",10}}):apply()
    end
  end
end,

-- conundrum
[110155] = function(player, opponent, my_card)
  if player.character.life <= 10 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
end,

-- knight vanguard
[110156] = function(player, opponent, my_card)
  if player.game.turn > 1 then
    local amt = 5-#opponent.hand
    OneBuff(opponent, 0, {life={"-",4*amt}}):apply()
  end
end,

-- serie
[110157] = function(player, opponent, my_card)
  local target = uniformly(opponent:field_idxs_with_preds(pred.follower))
  if target then
    opponent.field[target].active = false
  end
  local buff = OnePlayerBuff(player)
  local the_buff = {atk={"+",0},def={"+",0},sta={"+",0}}
  local targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    buff[idx] = the_buff
    the_buff.atk[2] = the_buff.atk[2] + player.field[idx].def
    the_buff.def[2] = the_buff.def[2] + player.field[idx].def
    the_buff.sta[2] = the_buff.sta[2] + player.field[idx].def
  end
  buff:apply()
  recycle_one(player)
end,

-- envy lady
[110158] = function(player, opponent, my_card)
  local buff = GlobalBuff(player)
  local targets = opponent:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = opponent.field[idx]
    buff.field[opponent][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] > id_to_canonical_card[card.id][stat] then
        buff.field[opponent][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  targets = player:field_idxs_with_preds(pred.follower)
  for _,idx in ipairs(targets) do
    local card = player.field[idx]
    buff.field[player][idx] = {}
    for _,stat in ipairs({"atk","def","sta"}) do
      if card[stat] < id_to_canonical_card[card.id][stat] then
        buff.field[player][idx][stat] = {"=",id_to_canonical_card[card.id][stat]}
      end
    end
  end
  buff:apply()
  recycle_one(player)
end,

-- true vampire god
[120010] = function(player, opponent)
  if opponent.character.life >= 15 then
    OneBuff(opponent, 0, {life={"-",1}}):apply()
  elseif opponent.character.life <= 8 then
    OneBuff(opponent, 0, {life={"=",0}}):apply()
  end
  recycle_one(player)
end,
}
setmetatable(characters_func, {__index = function()return function() end end})

-- trim a string.
function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

---
-- Splits a string on the given pattern, returned as a table of the delimited strings.
-- @param str the string to parse through
-- @param pat the pattern/delimiter to look for in str
-- @return a table of the delimited strings. If pat is empty, returns str. If str is not given, aka '' is given, then it returns an empty table.
function split(str, pat)
   if pat == '' then
      return str
   end

   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function managePlayers(channel)
  if channel ~= nil then
    print("Managing Players...")
    channel:push("players")

    local isManaging = true

    while isManaging do
      print("\nOptions:")
      print("\tA[dd]\n\t\tAdd/Change a player")
      print("\tC[hange]\n\t\tEdit a player's points")
      print("\tD[elete]\n\t\tRemove a player from the game")
      print("\tL[ist]\n\t\tList all players")
      print("\tT[est]\n\t\tTest player buttons")
      print("\tR[eturn]\n\t\tGo back to previous menu")

      local option = trim(io.read()):lower()

      if option == "add" or option == "a" then
        print("Player Name?")
        local playerName = trim(io.read())
        channel:push("add || "..playerName)
        print("Switch over to the video program and have the player press their button.")

        local playerInfo = playerChannel:demand()
        playerInfo = split(playerInfo, " || ")

        players[playerInfo[3]] = {["name"] = playerInfo[2], ["index"] = playerInfo[3], ["points"] = 0}

        print("Player "..playerInfo[2].." is set to button "..playerInfo[3].."!")
      elseif option == "change" or option == "c" then
        print("Which player?")
        local playerName = trim(io.read())

        local playerButton = getPlayerButton(playerName)
        if playerButton ~= nil then
          print("Enter new point value:")
          -- ERROR CHECK HERE!!!
          local newPoints = tonumber(trim(io.read()))
          players[playerButton].points = newPoints
          channel:push("edit || "..playerButton.." || "..newPoints)

          print("Player "..playerName.." now has "..newPoints.." points.")
        else
          print("Could not find player \""..playerName.."\"... Try again.")
        end
      elseif option == "delete" or option == "d" then
        print("Which player?")
        local playerName = trim(io.read())

        local playerButton = getPlayerButton(playerName)
        if playerButton ~= nil then
          channel:push("remove || "..playerButton)

          print("Player "..playerName.." has been removed from the game.")
        else
          print("Could not find player \""..playerName.."\"... Try again.")
        end
      elseif option == "test" or option == "t" then
      elseif option == "list" or option == "l" then
        printPlayers()
      elseif option == "return" or option == "r" then
        print("Returning to previous menu...")
        isManaging = false
      else
        print("Bad option, try again.")
      end
    end
  end

  return true
end

function getPlayerButton(playerName)
  for key, value in pairs(players) do
    if value.name:lower() == playerName:lower() then
      return key
    end
  end

  return nil
end

function printPlayerByIndex(button)
  if players[button] ~= nil then
    print("Button "..players[button].index..": "..players[button].name.." ("..players[button].points.." points)")
  end
end

function printPlayerByName(name)
  for key, value in pairs(players) do
    if value.name == name then
      printPlayerByIndex(key)
      break
    end
  end
end

function printPlayers()
  for key, value in pairs(players) do
    printPlayerByIndex(key)
  end
end

function sendMessage(beginningMessage, channelMessage)
  if channel ~= nil then
    print(beginningMessage)
    channel:push(channelMessage)
  end
end

function beginGame(channel)
  if channel ~= nil then
    print("To begin the game, please switch to the game board window.")
    channel:push("start")
    gameStartChannel:demand()

    -- options for when the game is playing should be here.
    print("\nControls for game:")
    print("\to\n\t\tCorrect")
    print("\tx\n\t\tIncorrect")
    print("\tp\n\t\tToggle Pause")
    print("\t]\n\t\tQuick Skip Forwards")
    print("\t[\n\t\tQuick Skip Backwards")
    print("\ts\n\t\tStop Game")
    print("\nSwitch to this screen to edit player scores if necessary.\n")

    local isWaitingForMessage = true

    -- look for "LostFocus" or "GameOver"
    while isWaitingForMessage do
      if gameStartChannel:getCount() > 0 then
        for i = 1, gameStartChannel:getCount() do
          local action = gameStartChannel:pop()

          if action == "LostFocus" then
            -- show options for editing players. ...I think?
          elseif action == "GameOver" then
            isWaitingForMessage = false
          elseif action:find("update || ") then
            -- "update || <button number> || <new point value>"
            action = split(action, " || ")

            players[action[2]].points = action[3]
          elseif action:find("NextImage || ") then
            action = split(action, " || ")
            print(action[2])
          end
        end
      end
    end
  end

  return true
end

function reloadImages(channel)
  if channel ~= nil then
    print("Reloading image folder...")
    channel:push("reload")
  end

  return true
end

function setFullscreen(channel)
  if channel ~= nil then
    print("Toggling fullscreen...")
    channel:push("fullscreen")
  end

  return true
end

function pauseGame(channel)
  if channel ~= nil then
    print("Toggling pause...")
    channel:push("pause")
  end

  return true
end

function exitProgram(channel)
  if channel ~= nil then
    print("Goodbye!")
    channel:push("exit")
  end

  return false
end

-- do a do-while loop, waiting for the user's input
print("Welcome to MnA Anime Eyes, the ghetto version!")
print("(Phyllis made this, she promises you'll have a more graphical backend in the future)")
print()

local channel = love.thread.getChannel("Console")
playerChannel = love.thread.getChannel("AddPlayer")
gameStartChannel = love.thread.getChannel("GameStart")
players = {}
local consoleIsRunning = true

while consoleIsRunning do
  print("\nOptions:")
  print("\tPlayers\n\t\tManage players")
  print("\tS[tart]\n\t\tBegin the round")
  print("\tR[eload]\n\t\tReload the image folder")
  print("\tF[ullscreen]\n\t\tToggle fullscreen")
  print("\tP[ause]\n\t\tToggle pause")
  print("\tQ[uit]\n\t\tExit the program")

  local option = trim(io.read()):lower()
  --print(option.." : did it newline tho")

  if option == "players" then
    consoleIsRunning = managePlayers(channel)
  elseif option == "p" or option == "pause" then
    consoleIsRunning = pauseGame(channel)
  elseif option == "start" or option == "s" then
    consoleIsRunning = beginGame(channel)
  elseif option == "reload" or option == "r" then
    consoleIsRunning = reloadImages(channel)
  elseif option == "fullscreen" or option == "f" then
    consoleIsRunning = setFullscreen(channel)
  elseif option == "quit" or option == "q" then
    consoleIsRunning = exitProgram(channel)
  else
    print("Bad option, try again.")
  end

  --consoleIsRunning = false

  if channel:peek() == "exit" then
    --exitProgram(channel)
    consoleIsRunning = false
  end
end

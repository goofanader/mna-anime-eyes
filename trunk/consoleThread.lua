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

function managePlayers(channel, isDuringGame)
  if channel ~= nil then
    print("Managing Players...")
    channel:push("players")
    isDuringGame = isDuringGame or false

    local isManaging = true

    while isManaging do
      print("\nOptions (Choose one by entering the number, first letter, or full command):")
      print("\t1. A[dd]: Create a new player/Change a player's name")
      print("\t2. C[hange]: Edit a player's points")
      print("\t3. D[elete]: Remove a player from the game")
      print("\t4. L[ist]: List all players")
      --print("\t5. T[est]: Test player buttons")
      print("\t5. R[eturn]: Go back to previous menu")

      local option = trim(io.read()):lower()

      if option == "add" or option == "a" or option == "1" then
        print("Please note that adding a new player sets that buzzer to zero points.\nPlayer Name?")
        local playerName = trim(io.read())
        channel:push("add || "..playerName)
        print("Switch over to the video program and have the player press their button.")

        local playerInfo = playerChannel:demand()
        playerInfo = split(playerInfo, " || ")

        players[playerInfo[3]] = {["name"] = playerInfo[2], ["index"] = playerInfo[3], ["points"] = 0}

        print("Player "..playerInfo[2].." is set to button "..playerInfo[3].."!")
      elseif option == "change" or option == "c" or option == "2" then
        print("Which player?")
        local playerName = trim(io.read())

        local playerButton = getPlayerButton(playerName)
        if playerButton ~= nil then
          print("Their current point value:"..players[playerButton].points..". Enter new point value:")
          -- ERROR CHECK HERE!!!
          local newPoints = tonumber(trim(io.read()))
          
          if newPoints ~= nil then
             players[playerButton].points = newPoints
             channel:push("edit || "..playerButton.." || "..newPoints)

             print("Player "..playerName.." now has "..newPoints.." points.")
          else
             print("Invalid point value! Try again.")
          end
        else
          print("Could not find player \""..playerName.."\"... Try again.")
        end
      elseif option == "delete" or option == "d" or option == "3" then
        print("Which player?")
        local playerName = trim(io.read())

        local playerButton = getPlayerButton(playerName)
        if playerButton ~= nil then
          channel:push("remove || "..playerButton)

          print("Player "..playerName.." has been removed from the game.")
        else
          print("Could not find player \""..playerName.."\"... Try again.")
        end
      --elseif option == "test" or option == "t" then
      elseif option == "list" or option == "l" or option == "4" then
        printPlayers()
      elseif option == "return" or option == "r" or option == "5" then
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

function printBeginGameMessage()
   -- options for when the game is playing should be here.
   print("\nControls for game:")
   print("\ty: Correct Answer")
   print("\tn: Incorrect Answer")
   print("\tp: Toggle Pause")
   print("\t]: Go to Next Image")

   --print("\tf: Fullscreen (please pause the game before doing so)")
   --print("\t[: Quick Skip Backwards")
   --print("\ts\n\t\tStop Game")
   print("\nSwitch to this screen to edit player scores if necessary.\n")
 end
 
function beginGame(channel)
  if channel ~= nil then
    print("To begin the game, please switch to the game board window.")
    channel:push("start")
    gameStartChannel:demand()

    printBeginGameMessage()

    local isWaitingForMessage = true

    -- look for "LostFocus" or "GameOver"
    while isWaitingForMessage do
      if gameStartChannel:getCount() > 0 then
        for i = 1, gameStartChannel:getCount() do
          local action = gameStartChannel:pop()

          if action == "LostFocus" then
            -- show options for editing players. ...I think?
            managePlayers(channel, true)
            printBeginGameMessage()
          elseif action == "GameOver" then
            isWaitingForMessage = false
          elseif action:find("update || ") then
            -- "update || <button number> || <new point value>"
            action = split(action, " || ")
            local player = players[action[2]]
            local newPoints = tonumber(action[3])

            if (newPoints < player.points) then
              print("\t"..player.name.." lost "..tostring(player.points - newPoints).." point(s)... They now have "..newPoints)
            else
              print("\t"..player.name.." won "..tostring(newPoints - player.points).." point(s)! They now have "..newPoints)
            end
            print()
            players[action[2]].points = tonumber(action[3])
          elseif action:find("NextImage || ") then
            action = split(action, " || ")
            print(action[2])
          elseif action:find("buzzedPlayer || ") then
            action = split(action, " || ")
            print("\t"..action[2].."'s Turn!")
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

function manageSettings(channel)
  if channel ~= nil then
    while true do
      print("\nSetting Options (Type in the number of the command you want):")
      print("\t1. Change pixel size")
      print("\t2. Change length of time for an image to be onscreen")
      --print("\t3. Toggle Image Checking Mode")
      print("\t3. Toggle Randomly Ordered Images")
      --print("\t5. Manage Point Distribution")
      --print("\t5. Show current settings")
      print("\t4. Return to previous menu")

      local option = trim(io.read()):lower()

      if option == "1" then
        print("Enter new pixel size:")
        local size = tonumber(trim(io.read()):lower())

        if size == nil then
          print("Not a valid entry. Try again.")
        else
          print("Pixel size is now "..size..".")
          channel:push("pixelSize || "..size)
        end
      elseif option == "2" then
        print("Enter new amount of time:")
        local time = tonumber(trim(io.read()):lower())

        if time == nil then
          print("Not a valid entry. Try again.")
        else
          print("Game time is now "..time..".")
          channel:push("gameTime || "..time)
        end
      --[[elseif option == "3" then
        print("Toggling image checking mode...")
        channel:push("isCheckingImages")]]
      elseif option == "3" then
        print("Toggling random order of images...")
        channel:push("isRandomFiles")
      elseif option == "4" then
        break
      end
    end
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
print("\nWelcome to MnA Anime Eyes, the ghetto version!")
print("(Phyllis made this, she promises you'll have a more graphical backend in the future)")
print()

local channel = love.thread.getChannel("Console")
playerChannel = love.thread.getChannel("AddPlayer")
gameStartChannel = love.thread.getChannel("GameStart")
players = {}
local consoleIsRunning = true

local saveDirectory = channel:demand()

print("The directory for placing images is "..saveDirectory)

while consoleIsRunning do
  print("\nOptions (Choose one by entering the number, first letter, or full command):")
  print("\t1. Players: Manage players")
  print("\t2. S[tart]: Begin the round")
  print("\t3. R[eload]: Reload the image folder")
  --print("\t4. F[ullscreen]: Toggle fullscreen")
  --print("\tP[ause]\n\t\tToggle pause")
  print("\t4. Settings: Configure game settings")
  print("\t5. Q[uit]: Exit the program")
  
  print("\nHow to toggle fullscreen: Switch to the Game Window and press 'f'.\n")

  local option = trim(io.read()):lower()
  --print(option.." : did it newline tho")

  if option == "players" or option == "1" then
    consoleIsRunning = managePlayers(channel)
  --elseif option == "p" or option == "pause" then
    --consoleIsRunning = pauseGame(channel)
  elseif option == "start" or option == "s" or option == "2" then
    consoleIsRunning = beginGame(channel)
  elseif option == "reload" or option == "r" or option == "3" then
    consoleIsRunning = reloadImages(channel)
  --[[elseif option == "fullscreen" or option == "f" or option == "4" then
    consoleIsRunning = setFullscreen(channel)]]
  elseif option == "settings" or option == "4" then
    consoleIsRunning = manageSettings(channel)
  elseif option == "quit" or option == "q" or option == "5" then
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

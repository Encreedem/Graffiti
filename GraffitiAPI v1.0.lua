-- GraffitiAPI v1.0

-- fields for users
local userFunctions = {}
local userLists = {}
local selectedItems = {}
local userInputs = {}

--monitor
local monitorSide = "right"
local monitor = nil

-- texts
local refreshText = "Refresh"
local backText = "Back"
local doneString = "Done"

-- colors
local buttonDefaultColor = colors.red
local buttonPressedColor = colors.lime
local sliderLowValueColor = colors.red
local sliderMediumValueColor = colors.yellow
local sliderHighValueColor = colors.lime
local inputDefaultColor = colors.white
local inputPressedColor = colors.yellow
local listDefaultColor = colors.lightBlue
local listSelectedColor = colors.orange
local editorMoveColor = colors.magenta
local editorScaleColor = colors.pink

-- API
variableValues = {}
sliderValues = {}

-- other
local args = { ... }
local quit = false
local maxX, maxY = 51, 19
local autoLoadObjects = true
local changeButtonColor = true
local screens = {}
screens.mainScreen = {}
local currentScreen = "mainScreen"

function readUserInput(message, isPassword)
  term.restore()
  print(message)
  
  if isPassword  then
    ret = read("*")
  else
    ret = read()
  end
  
  term.redirect(monitor)
  return ret
end

-- Redirects the input to the computer and lets
-- the user enter something. The result will be
-- in the userInputs array with the inputID as the
-- key.
function getUserInput(inputObject)
  if (inputObject == nil or inputObject.objType ~= "Input") then
    return
  end
  
  x = inputObject.x
  y = inputObject.y
  inputID = inputObject.inputID
  message = inputObject.message
  isPassword = (inputObject.isPassword == nil) and false or inputObject.isPassword
  maxLength = inputObject.maxLength
  
  existingInput = userInputs[inputID]
  if (existingInput ~= nil) then -- Clear the text on the input object.
    term.setCursorPos(x, y)
    for i = -1, string.len(existingInput) do
      term.write(" ")
    end
    
    userInputs[inputID] = nil
  end
  
  -- make the input-object yellow
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.yellow)
  term.write("  ")
  term.setBackgroundColor(colors.black)
  
  userInput = readUserInput(message, isPassword)
  if (userInput ~= nil) then
    userInputs[inputID] = userInput
  end
  
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  
  term.write(" ")
  if (userInput ~= nil and userInput ~= "") then
    if isPassword then
      for i = 1, string.len(userInput) do
        term.write("*")
      end
    else
      term.write(userInput)
    end
  end
  
  term.write(" ")
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  
  return ret
end

-- Checks if dir is a valid direction-string
function isValidDirection(dir)
  if (dir == "left" or 
      dir == "up" or 
      dir == "right" or 
      dir == "down") then
    return true
  end
  
  return false
end

-- display objects region start --

function showBox(x, y, width, height, color)
  for row = x, x + width - 1 do
    for col = y, y + height - 1 do
      paintutils.drawPixel(row, col, color)
    end
  end
  
  term.setBackgroundColor(colors.black)
end

-- Displays the text on the screen.
function showText(textObject)
  if (textObject.objType ~= "Text") then
    return
  end
  
  x = textObject.x
  y = textObject.y
  text = textObject.text
  assert(x, "Text: X-coordinate has to be set!")
  assert(y, "Text: Y-coordinate has to be set!")
  
  term.setCursorPos(x, y)
  term.write(text)
end

-- Displays the slider on the screen.
function showSlider(slider, fillPercentage)
  if (slider == nil or slider.objType ~= "Slider") then
    return
  end
  
  x = slider.x
  y = slider.y
  length = slider.length
  direction = (isValidDirection(slider.direction)) and slider.direction or "right"
  
  startSymbol, endSymbol = "<", ">"
  addX, addY = 1, 0 -- Sets the direction of the slider, therefore it could even be diagonal.
  
  if (direction == "left") then
    addX, addY = -1, 0
    startSymbol, endSymbol = ">", "<"
    term.setCursorPos(x - length, y)
    term.write(endSymbol)
  elseif (direction == "up") then
    addX, addY = 0, -1
    startSymbol, endSymbol = "V", "^"
    term.setCursorPos(x, y - length)
    term.write(endSymbol)
  elseif (direction == "right") then
    addX, addY = 1, 0
    startSymbol, endSymbol = "<", ">"
    term.setCursorPos(x + length, y)
    term.write(endSymbol)
  elseif (direction == "down") then
    addX, addY = 0, 1
    startSymbol, endSymbol = "^", "V"
    term.setCursorPos(x, y + length)
    term.write(endSymbol)
  else -- return if it's not a valid direction, even if I checked it before
    return
  end
  
  term.setCursorPos(x, y)
  term.write(startSymbol)
  
  if (fillPercentage ~= nil) then
    if (fillPercentage < 33) then
      sliderColor = sliderLowValueColor
    elseif (fillPercentage > 66) then
      sliderColor = sliderHighValueColor
    else
      sliderColor = sliderMediumValueColor
    end
    
    filled = math.floor((length / 100) * fillPercentage)
    currentX = x + addX
    currentY = y + addY
    
    for i = 1, filled do
      paintutils.drawPixel(currentX, currentY, sliderColor)
      currentX = currentX + addX
      currentY = currentY + addY
    end
  end
  
  term.setBackgroundColor(colors.black)
end

-- Displays the given button on the screen.
function showButton(button, color)
  if (button == nil or button.objType ~= "Button") then
    return
  end
  
  x = button.x
  y = button.y
  width = button.width
  height = button.height
  text = button.text
  
  showBox(x, y, width, height, color)
  
  -- Tries to center the text in the button.
  textCol = x + math.floor((width - string.len(text)) / 2)
  textRow = y + math.ceil(height / 2) - 1
  term.setCursorPos(textCol, textRow)
  term.setBackgroundColor(color)
  term.write(text)
  
  term.setBackgroundColor(colors.black)
end

-- Displays the input-object (two white spaces)
function showInput(inputObject)
  if (inputObject == nil or inputObject.objType ~= "Input") then
    return
  end
  
  inputId = inputObject.inputID
  x = inputObject.x
  y = inputObject.y
  
  term.setCursorPos(x, y)
  term.setBackgroundColor(inputDefaultColor)
  term.write(" ")
  if (userInputs[inputID] ~= nil) then
    term.write(userInputs[inputID])
  end
  term.write(" ")
  
  term.setBackgroundColor(colors.black)
end

-- Used by "showList" and "showSelector" to
-- determine how wide the list should be.
function getLongestString(stringArray)
  if (stringArray == nil or #stringArray == 0) then
    return 0
  end
  
  ret = 0
  
  for key, value in pairs(stringArray) do
    length = string.len(value)
    if (length > ret) then
      ret = length
    end
  end
  
  return ret
end

-- Displays a list on the monitor.
function showList(listObject)
  if (listObject == nil or listObject.objType ~= "List") then
    return
  end
  
  if (type(listObject.elements) == "string") then
    listObject.elements = { listObject.elements }
  end
  
  if (#listObject.elements == 1 and userLists[listObject.elements[1]] ~= nil) then
    listObject.elements = userLists[listObject.elements[1]]
  end
  
  x = listObject.x
  y = listObject.y
  elements = (listObject.elements ~= nil) and listObject.elements or { "empty" }
  width = getLongestString(elements) + 2
  listObject.width = width
  height = #elements
  listObject.height = height
  elements = listObject.elements
  listID = listObject.listID
  isMultiselect = (listObject.isMultiselect ~= nil) and listObject.isMultiselect or false
  
  showBox(x, y, width, height, listDefaultColor)
  
  if (selectedItems[listID] == nil and isMultiselect) then
    selectedItems[listID] = {  }
    for index, elementKey in ipairs(elements) do
      selectedItems[listID][elementKey] = false
    end
  end
  
  posY = 0
  for key,element in pairs(elements) do
    term.setCursorPos(x, y + posY)
    
    if (isMultiselect) then
      if (selectedItems[listID][elements] == true) then
        term.setBackgroundColor(listSelectedColor)
      else
        term.setBackgroundColor(listDefaultColor)
      end
    else
      if (selectedItems[listID] == key) then
        term.setBackgroundColor(listSelectedColor)
      else
        term.setBackgroundColor(listDefaultColor)
      end
    end
    
    term.write(" " .. element .. " ")
    posY = posY + 1
  end
  
  term.setBackgroundColor(colors.black)
end

-- Displays the text with red background colour.
function showSimpleButton(x, y, text)
  term.setCursorPos(x, y)
  term.setBackgroundColor(colors.red)
  term.write(text)
  term.setBackgroundColor(colors.black)
end

-- Displays the "Back"- and "Refresh"-Buttons
function showDefaultButtons()
  x = maxX - string.len(refreshText) + 1
  showSimpleButton(x, maxY, refreshText)
  
  showSimpleButton(1, maxY, backText)
end

-- display objects region end

function setVariableValue(varID, value)
  variableValues[varID] = value
end

function setSliderValue(sliderID, value)
  sliderValues[varID] = value
end

-- Loads the values of all variables and sliders
-- of the current screen.
function loadObjects()
  for objectID, object in pairs(screens[currentScreen]) do
    objectType = object.objType
    x = object.x
    y = object.y
    term.setCursorPos(x, y)
    
    if (objectType == "Variable") then
      term.write(variableValues[object.varID])
    elseif (objectType == "Slider") then
      term.write(variableValues[object.varID])
    end
  end
end

-- Displays all objects of the selected screen.
function showScreen(screenID)
  term.clear()
  currentScreen = screenID
  
  if (currentScreen == "mainScreen") then
    backText = "Quit"
  else
    backText = "Back"
  end
  
  local objectType
  
  for sObjectID, sObject in pairs(screens[screenID]) do
    objectType = sObject.objType
    
    if (objectType == "Button") then
      showButton(sObject, buttonDefaultColor)
    elseif (objectType == "Text") then
      showText(sObject)
    elseif (objectType == "Slider") then
      showSlider(sObject, 0)
    elseif (objectType == "Input") then
      showInput(sObject)
    elseif (objectType == "List") then
      showList(sObject)
    end
  end
  
  if autoLoadObjects then
    loadObjects()
  end
  
  showDefaultButtons()
  
  term.setCursorPos(1, maxY)
end

-- Waits until the user touches the monitor and
-- if he touched a button, the function stored in
-- it will be called.
function getInput()
  finished = false
  while (not finished and not quit)do
    key, side, x, y = os.pullEvent("monitor_touch")
    
    if (y == maxY) then -- Checking the default buttons
      if (x <= string.len(backText)) then -- "Back"-Button pressed
        if (currentScreen == "mainScreen") then
          term.restore()
          return "quit"
        else
          if (screens[currentScreen].parentScreen ~= nil) then
            showScreen(screens[currentScreen].parentScreen)
            finished = true
          else
            showScreen("mainScreen")
            finished = true
          end
        end
      elseif (x >= maxX - string.len(refreshText)) then -- "Refresh"-Button pressed
        showScreen(currentScreen)
        finished = true
      end
    end
    
    if (finished == false and quit == false) then
      for sObjectID, sObject in pairs(screens[currentScreen]) do
        objectType = sObject.objType
        
        if (objectType == "Button") then
          left = sObject.x
          top = sObject.y
          width = sObject.width
          height = sObject.height
          right = left + width
          bottom = top + height
          
          if (x >= left and x < right and y >= top and y < bottom) then
            return sObject.param
          end
        elseif (objectType == "Input") then
          left = sObject.x
          top = sObject.y
          inputID = sObject.inputID
          message = sObject.message
          isPassword = sObject.isPassword
          
          if ((x == left or x == left + 1) and y == top) then
            getUserInput(sObject)
          end
        elseif (objectType == "List") then
          left = sObject.x
          top = sObject.y
          width = sObject.width
          height = #sObject.elements
          right = left + width
          bottom = top + height
          
          listID = sObject.listID
          isMultiselect = sObject.isMultiselect
          
          if (x >= left and x < right and y >= top and y < bottom) then
            if (isMultiselect) then
              if (selectedItems[listID][y - top + 1]) then
                selectedItems[listID][y - top + 1] = false
              else
                selectedItems[listID][y - top + 1] = true
              end
            else
              selectedItems[listID] = y - top + 1
            end
            
            showList(sObject)
            
            finished = true
          end
        end
        
        if (finished == true) then
          break
        end
      end
    end
  end
end

function getMonitor()
  if (peripheral.getType(monitorSide) == "monitor") then
    monitor = peripheral.wrap(monitorSide)
    return true
  else
    return false
  end
end

-- Shows the message on the computer for debugging. Probably my most-used function.
function debugMessage(message)
  term.restore()
  print(message)
  term.redirect(monitor)
end

function loadScreens()
  if not fs.exists("screens.sav") then
    error("screens.sav not found!")
  end
  
  file = fs.open("screens.sav", "r")
  loadString = file.readAll()
  if (loadString ~= nil and loadString ~= "") then
    screens = textutils.unserialize(loadString)
  end
  file.close()
end

function setMonitorSide(monSide)
  loadScreens()
  monitorSide = monSide
  
  if not getMonitor() then
    error("No monitor at " .. monitorSide .. " side!");
  end
  
  maxX, maxY = monitor.getSize()
  if (maxX < 16 or maxY < 10) then -- smaller than 2x2
    error("Screen too small! You need at least 2x2 monitors!")
  end
  
  term.redirect(monitor)
  
  return true
end
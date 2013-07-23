local version = "Graffiti v1.2"

-- fields for users
local userFunctions = {}
local userLists = {}
local selectedItems = {}
local userInputs = {}

--monitor
local monitorSide = "left"
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
local editorMarkerColor = colors.gray
local editorAlignmentTrueColor = colors.lime
local editorAlignmentFalseColor = colors.red

-- sizes
local buttonDefaultWidth = 10
local buttonDefaultHeight = 3
local sliderDefaultLength = 10

-- save file
saveFileName = "Graffiti.sav"

-- editor options
local editMode = false
local showEditorOptions = false
local editActions = { "Design", "Attributes", "Delete" }
local lastScreen = "mainScreen"
local editorFunctions = {}

-- AddOn options
local addOns = {}
local addOnExtension = ".add"

-- other
local args = { ... }
local quit = false
local maxX, maxY = 51, 19
local autoLoadObjects = true
local changeButtonColor = true
local screens = {}
screens.mainScreen = {}
local currentScreen = "mainScreen"
local objectTypes = { "Button", "Text", "Variable", "Slider", "Input", "List" }

-- Displays a star in the upper left corner for a
-- short amount of time. Used when you want to see
-- when something certain happens.
-- Should only be used when you are desperately
-- looking for a bug.
function extremeDebug()
  term.setCursorPos(1, 1)
  term.write("*")
  os.sleep(0.5)
  term.setCursorPos(1, 1)
  term.write(" ")
  os.sleep(0.5)
end

-- user variables
local randomValue= 50

-- user functions

function userFunctions.setRandomValue()
  randomValue = math.random(100)
end

-- user lists

userLists.testList = {
  "Testitem 1",
  "Testitem 2",
  "Testitem 3"
}

-- Define the value of a variable-object.
function getVariableValue(variable)
  if (variable == nil or variable.objType ~= "Variable") then
    return
  end
  
  variableID = variable.varID
  if (variableID == "testVariable") then
    return "Variable";
  elseif (variableID == "Time") then
    return textutils.formatTime(os.time(), true)
  end
  
  return ""
end

-- Definie the value of a slider-object
-- 0: empty; 100: full
function getSliderValue(slider)
  if (slider == nil or slider.objType ~= "Slider") then
    return
  end
  
  sliderID = slider.sliderID
  
  if (sliderID == "testSlider") then
    return 87;
  elseif (sliderID == "randomSlider") then
    return randomValue
  end
end

-- WARNING! Everything below this comment
-- shouldn't be edited! If you do so and the program
-- doesn't work any more then it's your fault!

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
  if (dir ~= nil and
     (dir == "left" or 
      dir == "up" or 
      dir == "right" or 
      dir == "down")) then
    return true
  end
  
  return false
end

-- display objects region start --

-- Displays a line at the given coordinates.
function showLine(x, y, direction, length, color)
  term.setBackgroundColor(color)
  
  direction = (isValidDirection(direction)) and direction or "right"
  local addX, addY = 1, 0
  local currentX, currentY = x, y
  
  if (direction == "left") then
    addX, addY = -1, 0
  elseif (direction == "up") then
    addX, addY = 0, -1
  elseif (direction == "right") then
    addX, addY = 1, 0
  elseif (direction == "down") then
    addX, addY = 0, 1
  end
  
  for i = 1, length do
    paintutils.drawPixel(currentX, currentY, color)
    currentX = currentX + addX
    currentY = currentY + addY
  end
end

-- Displays a rectangle at the given coordinates.
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
    showLine(x + addX, y + addY, direction, filled, sliderColor)
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
      if (selectedItems[listID][key] == true) then
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

-- Displays a list and returns the field that the
-- user touched.
function showSelector(x, y, elements)
  width = getLongestString(elements) + 2
  height = #elements + 2 -- Elements + up and down
  elementCount = #elements
  displayCount = elementCount
  
  enoughXSpace = true
  -- determine where the selector should actually be displayed
  if (width > maxX) then -- Not enough monitors horizontally?
    x = 1
    enoughXSpace = false
  elseif (maxX - x < width) then -- Not enough space to the right.
    if (x >= width) then -- Let's see if there is space to the left.
      x = x - width
    else -- No space? Check where you've got more space.
      if (maxX / 2) > x then -- More space to the left.
        x = maxX - width + 1
        enoughXSpace = false
      else -- More space to the right
        x = 1
        enoughXSpace = false
      end
    end
  else -- Enough space to the right.
    x = x + 1
  end
  
  if (height > maxY - y) then -- Not enough space from y to bottom.
    if ((maxY / 2) > y) then -- More space below y.
      if enoughXSpace then
        if (maxY < height) then -- Too big for the whole screen.
          y = 1
          displayCount = maxY - 2
        else -- Enough space next to x and not too high.
          y = maxY - height
        end
      else -- Can't display it next to the selected point.
        y = y + 1
        displayCount = maxY - y - 1
      end
    else -- More space above y.
      if enoughXSpace then
        if (y < height) then -- Not enough space from top to y.
          if (maxY < height) then -- Too big for the whole screen.
            y = 1
            displayCount = maxY - 2
          else -- Enough space next to x and not too high.
            y = 1
          end
        else -- Enough space from top to y.
          y = y - height + 1
        end
      else
        if (y < height) then -- Not enough space from top to y.
          if (maxY < height) then -- Too big for the whole screen.
            y = 1
            displayCount = maxY - 2
          else -- Not enough space next to x but not too high.
            y = 1
            displayCount = y - 4
          end
        else -- Enough space from top to y.
          y = y - height
        end
      end
    end
  end
  
  term.setBackgroundColor(colors.black)
  
  -- Read the user input.
  scroll = 1
  right = x + width - 1
  bottom = y + displayCount + 1
  
  finished = false
  while not finished do
    -- Display the actual selector.
    showBox(x, y, width, height, listDefaultColor)
    
    term.setBackgroundColor(listDefaultColor)
    middle = math.floor(width / 2)
    term.setCursorPos(x + middle, y)
    term.write("^")
    term.setCursorPos(x + middle, bottom)
    term.write("V")
    
    for i = 1, displayCount do
      term.setCursorPos(x, y + i)
      term.write(" " .. elements[i + scroll - 1] .. " ")
    end
    term.setBackgroundColor(colors.black)
    
    _, _, touchX, touchY = os.pullEvent("monitor_touch")
    
    if (touchX < x or touchX > right or touchY < y or touchY > bottom) then
      selectedItem = nil
      result = false
      finished = true
    else -- User touched the selector.
      if (touchY == y) then -- up
        if (scroll > 1) then -- Check if it makes sense to scroll up.
          scroll = scroll - 1
        end
      elseif (touchY == bottom) then -- down
        if (displayCount < elementCount) then
          if (scroll <= elementCount - displayCount) then
            scroll = scroll + 1
          end
        end
      else
        selectedItem = elements[touchY - y + scroll - 1]
        result = true
        finished = true
      end
    end
  end
  
  showScreen(currentScreen)
  return result
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

function getSystemInfo()
  systemInfo = {}
  systemInfo.maxX = maxX
  systemInfo.maxY = maxY
  systemInfo.selectedItems = selectedItems
  systemInfo.userInputs = userInputs
  
  return systemInfo
end

-- Loads the values of all variables and sliders
-- of the current screen.
function loadObjects()
  for objectID, object in pairs(screens[currentScreen]) do
    objectType = object.objType
    x = object.x
    y = object.y
    
    if (objectType == "Variable") then
      value = getVariableValue(object)
      term.setCursorPos(x, y)
      term.write(value)
    elseif (objectType == "Slider") then
      length = object.length
      value = getSliderValue(object)
      showSlider(object, value)
    end
  end
end

-- Displays all objects of the selected screen.
function showScreen(screenID)
  term.clear()
  
  currentScreen = screenID
  
  if not editMode then
    if (currentScreen == "mainScreen") then
      backText = "Quit"
    else
      backText = "Back"
    end
  else
    backText = "Quit"
    refreshText = "Options"
  end
  
  local screenObject
  local objectType
  if showEditorOptions then
    screenObject = editorScreens[screenID]
  else
    screenObject = screens[screenID]
  end
  
  for sObjectID, sObject in pairs(screenObject) do
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
    elseif (objectType == "Custom") then
      callAddOn(sObject, "Show")
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
  _, _, x, y = os.pullEvent("monitor_touch")
  
  if (y == maxY) then -- Checking the default buttons
    if (x <= string.len(backText)) then -- "Back"-Button pressed
      if (currentScreen == "mainScreen" or editMode) then
        quit = true
      else
        if (screens[currentScreen].parentScreen ~= nil) then
          showScreen(screens[currentScreen].parentScreen)
          finished = true
        else
          showScreen("mainScreen")
          finished = true
        end
      end
    elseif (x >= maxX - string.len(refreshText) and not editMode) then -- "Refresh"-Button pressed
      showScreen(currentScreen)
      finished = true
    end
  end
  
  if (finished == true or quit==true) then
    return nil
  end
  
  sObjectID, sObject = findObject(x, y)
  if (sObjectID ~= nil and sObject ~= nil) then
    objectType = sObject.objType
    
    if (objectType == "Button") then
      if (sObject.isAddon) then
        callAddOn(sObject, "Click")
      elseif (sObject.funcType ~= nil and sObject.param ~= nil) then
        callAction(sObject)
      end
    elseif (objectType == "Input") then
      getUserInput(sObject)
    elseif (objectType == "List") then
      top = sObject.y
      listID = sObject.listID
      isMultiselect = sObject.isMultiselect
      
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
    elseif (objectType == "Custom" and sObject.canClick) then -- AddOn Object
      callAddOn(sObject, "Click")
    end
  end
end

function callAction(button)
  actionType = button.funcType
  param = button.param
  
  if (actionType == "switch") then
    showScreen(param)
  elseif (actionType == "function") then
    if changeButtonColor then
      showButton(button, buttonPressedColor)
    end
    
    if userFunctions[param] ~= nil then
      userFunctions[param]()
    elseif editorFunctions[param] ~= nil then
      editorFunctions[param]()
    end
    
    if changeButtonColor then
      showButton(button, buttonDefaultColor)
    else
      changeButtonColor = true
    end
  end
end

function callAddOn(object, callType)
  addOnName = object.addOnName
  objectID = object.objID
  x = object.x
  y = object.y
  width = object.width
  height = object.height
  addOnPath = fs.combine(shell.dir(), addOnName .. addOnExtension)
  
  systemInfo = getSystemInfo()
  systemInfo.x = x
  systemInfo.y = y
  systemInfo.width = width
  systemInfo.height = height
  
  if changeButtonColor then
      showButton(object, buttonPressedColor)
  end
  
  shell.run(addOnPath, callType, objectID, textutils.serialize(systemInfo))
  
  if changeButtonColor then
    showButton(button, buttonDefaultColor)
  else
    changeButtonColor = true
  end
end

-- Checks if the monitor on monitorSide exists and wraps it into "monitor".
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

-- Calls the "getInput" function until the user presses the quit-button.
function main()
  showScreen("mainScreen")
  
  while not quit do
    getInput()
  end
end

-- Saves the content of the screens-table into the save file
function saveScreens()
  saveString = textutils.serialize(screens)
  file = fs.open(saveFileName, "w")
  file.write(saveString)
  file.close()
end

-- Loads the save file and puts the content into the screens-table
function loadScreens()
  if not fs.exists(saveFileName) then
    return
  end
  
  file = fs.open(saveFileName, "r")
  loadString = file.readAll()
  if (loadString ~= nil and loadString ~= "") then
    screens = textutils.unserialize(loadString)
  end
  file.close()
end

function splitAt(toSplit, delimiter)
  delimiterPos = string.find(toSplit, delimiter)
  left = string.sub(toSplit, 1, delimiterPos - 1)
  right = string.sub(toSplit, delimiterPos + #delimiter)
  
  return left, right
end

-- screen editor region start --

function generateScreenList()
  ret = {  }
  for key, value in pairs(screens) do
    table.insert(ret, key)
  end
  
  return ret
end

editorScreens = {
  mainScreen = {
    { objType="Text", x=2, y=1, text="Mode:" };
    { objType="List", x=2, y=2, elements=editActions, listID="editActionList", isMultiselect=false };
    { objType="Button", x=2, y=6, width=14, height=1, text="last screen", funcType="function", param="editLastScreen" };
    { objType="Button", x=2, y=8, width=14, height=1, text="edit screens", funcType="function", param="loadScreenList" };
  };
  
  screenListScreen = {
    { objType="List", x=2, y=2, elements=screenList, listID="screenList", isMultiselect=false };
    { objType="Button", x=2, y=maxY-6, width=12, height=1, text="Set parent", funcType="function", param="setParent" };
    { objType="Button", x=2, y=maxY-4, width=8, height=1, text="New", funcType="function", param="newScreen" };
    { objType="Button", x=2, y=maxY-3, width=8, height=1, text="Edit", funcType="function", param="editScreen" };
    { objType="Button", x=2, y=maxY-2, width=8, height=1, text="Delete", funcType="function", param="deleteScreen" };
  };
}

-- Used to give a List-object an array of all screens
function editorFunctions.loadScreenList()
  screenList = generateScreenList()
  editorScreens["screenListScreen"][1].elements = screenList
  changeButtonColor = false
  showScreen("screenListScreen")
end

function editorFunctions.editLastScreen()
  if (lastScreen == nil) then
    lastScreen = "mainScreen"
  end
  
  showEditorOptions = false
  showScreen(lastScreen)
  changeButtonColor = false
end

-- Let's the user define the parentScreen-attribute of the current screen.
function editorFunctions.setParent()
  if (selectedItems.screenList == nil) then
    return
  end
  
  list = editorScreens.screenListScreen[1]
  height = list.height
  for i = 1, height do
    if (selectedItems.screenList ~= i) then
      paintutils.drawPixel(1, i + 1, colors.lime)
    end
  end
  
  event, side, x, y = os.pullEvent("monitor_touch")
  
  if (y > 1 and y <= height + 1) then -- Clicked inside the list.
    if (y - 1 ~= selectedItems.screenList) then -- Selected parentScreen is not selected screen.
      screens[list.elements[selectedItems.screenList]].parentScreen = list.elements[y - 1]
    end
  end
  
  for i = 1, height do
    paintutils.drawPixel(1, i + 1, colors.black)
  end
end

-- Creates a new screen. The user has to enter the screen name in the computer.
function editorFunctions.newScreen()
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Enter a screen-name.")
  message = "Pleas enter the name of the new screen."
  userInput = readUserInput(message, false)
  
  while (userInput ~= nil and screens[userInput] ~= nil) do
    message = "There is already a screen with that name!"
    userInput = readUserInput(message, false)
  end
  
  if (userInput ~= nil) then
    screens[userInput] = { parentScreen="mainScreen" }
    showEditorOptions = false
    showScreen(userInput)
    lastScreen = userInput
    changeButtonColor = false
  end
end

-- Edits the screen that has been selected in the "screenList"-list.
function editorFunctions.editScreen()
  if (selectedItems.screenList ~= nil) then
    showEditorOptions = false
    lastScreen = screenList[selectedItems.screenList]
    showScreen(screenList[selectedItems.screenList])
    changeButtonColor = false
  end
end

-- Deletes the screen that has been selected in the "screenList"-list.
function editorFunctions.deleteScreen()
  if (selectedItems.screenList ~= nil and screenList[selectedItems.screenList] ~= "mainScreen") then
    screens[screenList[selectedItems.screenList]] = nil
    showEditorOptions = true
    editorFunctions.loadScreenList()
  end
end

-- Displays an object with default attributes and adds it to the current screen.
function showDefaultObject(objectType, xCoord, yCoord)
  object = {  }
  
  object.objType = objectType
  object.x = xCoord
  object.y = yCoord
  
  maxWidth = maxX - xCoord
  maxHeight = maxY - yCoord
  
  if (string.find(objectType, " - ") ~= nil) then -- object is an AddOn
    addOnName, objectName = splitAt(objectType, " - ")
    objectValues = addOns[addOnName][objectName]
    
    objectID = objectValues.objectID
    objectType = objectValues.objectType
    defaultWidth = tonumber(objectValues.defaultWidth)
    defaultHeight = tonumber(objectValues.defaultHeight)
    canScale = objectValues.canScale
    canClick = objectValues.canClick
    
    object.objID = objectID
    object.objType = objectType
    object.canScale = canScale
    object.canClick = canClick
    object.isAddOn = true
    object.addOnName = addOnName
    
    if (objectType == "Button") then
      object.width = (defaultWidth <= maxWidth) and defaultWidth or maxWidth
      object.height = (defaultHeight <= maxHeight) and defaultHeight or maxHeight
      object.text = objectValues.text
      object.horizontalAlignment = "left"
      object.verticalAlignment = "top"
      showButton(object, buttonDefaultColor)
    elseif (objectType == "Custom") then
      if canScale then
        object.width = (defaultWidth <= maxWidth) and defaultWidth or maxWidth
        object.height = (defaultHeight <= maxHeight) and defaultHeight or maxHeight
      else
        object.width = defaultWidth
        object.height = defaultHeight
      end
    elseif (objectType == "Variable") then
      object.varID = objectID
    elseif (objectType == "Input") then
      object.inputID = objectID
      object.message = objectValues.message
      showInput(object)
    elseif (objectType == "List") then
      object.listID = objectID
      object.elements = objectValues.elements
      showList(object)
    end
  elseif (objectType == "Button") then
    object.width = (maxWidth < buttonDefaultWidth) and maxWidth or buttonDefaultWidth
    object.height = (maxHeight < buttonDefaultHeight) and maxHeight or buttonDefaultHeight
    object.text = "Button"
    object.funcType = ""
    object.param = ""
    object.horizontalAlignment = "left"
    object.verticalAlignment = "top"
    showButton(object, buttonDefaultColor)
  elseif (objectType == "Text") then
    object.text = "Text"
    showText(object)
  elseif (objectType == "Variable") then
    object.varID = "testVariable"
  elseif (objectType == "Slider") then
    object.length = (maxWidth < sliderDefaultLength) and maxWidth or sliderDefaultLength
    object.direction = "right"
    object.sliderID = "testSlider"
    showSlider(object)
  elseif (objectType == "Input") then
    object.inputID = "testInput"
    object.message = "Enter something."
    object.isPassword = false
    showInput(object)
  elseif (objectType == "List") then
    object.elements = userLists.testList
    object.listID = "testList"
    object.isMultiselect = false
    showList(object)
  else
    return
  end
  
  table.insert(screens[currentScreen], object)
end

-- Shows lines marking the top left part of an
-- object as well as well as pixels displaying
-- the alignment of an object.
function showAlignmentLines(object, left, top, right, bottom, color)
  -- Draw the lines.
  showLine(left - 1, top, "left", left - 2, color) -- left
  showLine(left, top -1, "up", top - 2, color) -- up
  showLine(right + 1, top, "right", maxX - (right + 1), color) -- right
  showLine(left, bottom + 1, "down", maxY - (bottom + 1), color) -- down
  
  -- Display the alignment-pixels.
  horizontalAlignment = object.horizontalAlignment
  verticalAlignment = object.verticalAlignment
  
  if (horizontalAlignment == "left" or horizontalAlignment == "stretch") then -- left
    paintutils.drawPixel(1, top, editorAlignmentTrueColor)
  else
    paintutils.drawPixel(1, top, editorAlignmentFalseColor)
  end
  
  if (horizontalAlignment == "right" or horizontalAlignment == "stretch") then -- right
    paintutils.drawPixel(maxX, top, editorAlignmentTrueColor)
  else
    paintutils.drawPixel(maxX, top, editorAlignmentFalseColor)
  end
  
  if (verticalAlignment == "top" or verticalAlignment == "stretch") then -- top
    paintutils.drawPixel(left, 1, editorAlignmentTrueColor)
  else
    paintutils.drawPixel(left, 1, editorAlignmentFalseColor)
  end
  
  if (verticalAlignment == "bottom" or verticalAlignment == "stretch") then -- bottom
    paintutils.drawPixel(left, maxY, editorAlignmentTrueColor)
  else
    paintutils.drawPixel(left, maxY, editorAlignmentFalseColor)
  end
  
  term.setBackgroundColor(colors.black)
end

-- Returns the values of horizontalAlignment and
-- verticalAlignment depending which sides are set
-- to true.
function getAlignment(left, top, right, bottom)
  local retHorizontal, retVertical = "left", "top"
  
  if right then
    if left then
      retHorizontal = "stretch"
    else
      retHorizontal = "right"
    end
  else
    retHorizontal = "left"
  end
  
  if bottom then
    if top then
      retVertical = "stretch"
    else
      retVertical = "bottom"
    end
  else
    retVertical = "top"
  end
  
  return retHorizontal, retVertical
end

-- Returns the right- and bottom-coordinates of the object.
function getObjectDimensions(object)
  if (type(object) ~= "table") then
    return -1, -1, -1, -1
  end
  
  objectType = object.objType
  left = object.x
  top = object.y
  
  if (objectType == "Button" or objectType == "List") then
    right = left + object.width - 1
    bottom = top + object.height - 1
  elseif (objectType == "Text") then
    right = left + string.len(object.text) - 1
    bottom = top
  elseif (objectType == "Variable" or objectType == "Input") then
    right = left + 1
    bottom = top
  elseif (objectType == "Slider") then
    direction = object.direction
    length = object.length
    
    if (direction == "left") then
      left = object.x - length
      top = object.y
      right = object.x
      bottom = top
    elseif (direction == "up") then
      left = object.x
      top = object.y - length
      right = object.x
      bottom = object.y
    elseif (direction == "down") then
      left = object.x
      top = object.y
      right = object.x
      bottom = top + length
    else -- right
      left = object.x
      top = object.y
      right = object.x + length
      bottom = top
    end
  elseif (objectType == "Custom") then -- AddOn
    if (object.canScale or object.canClick) then
      right = left + object.width
      bottom = top + object.height
    else
      right = left
      bottom = top
    end
  else
    right = -1
    bottom = -1
  end
  
  return left, top, right, bottom
end

function findObject(x, y)
  if showEditorOptions then
    screenObject = editorScreens[currentScreen]
  else
    screenObject = screens[currentScreen]
  end
  for sObjectID, sObject in pairs(screenObject) do
    left, top, right, bottom = getObjectDimensions(sObject)
    
    if (x >= left and x <= right and y >= top and y <= bottom) then
      return sObjectID, sObject
    end
  end
  
  return nil, nil
end

-- Let's the user delete an object or change its attributes depending on the current edit-mode.
function editObject(objectKey)
  sObject = screens[currentScreen][objectKey]
  objType = sObject.objType
  left, top, right, bottom = getObjectDimensions(sObject)
  
  if (editActions[selectedItems.editActionList] == "Delete") then
    screens[currentScreen][objectKey] = nil
  elseif (editActions[selectedItems.editActionList] == "Attributes" and not screens[currentScreen][objectKey].isAddOn) then
    objAttr = {  }
    
    index = 1
    for key, value in pairs(sObject) do
      if (key ~= "objType" and key ~= "x" and key ~= "y" and key ~= "width" and key ~= "height" and key ~= "length" and key ~= "direction") then
        table.insert(objAttr, index, key)
        index = index + 1
      end
    end
    
    term.clear()
    
    yPos = 2
    top = yPos
    for attrKey, attrValue in ipairs(objAttr) do
      term.setCursorPos(2, yPos)
      term.write(attrValue .. ": ")
      print(sObject[attrValue])
      yPos = yPos + 1
    end
    term.setCursorPos(2, yPos + 1)
    term.setBackgroundColor(colors.red)
    term.write(doneString)
    term.setBackgroundColor(colors.black)
    
    bottom = yPos - 1
    finished = false
    while not finished do
      event, side, x, y = os.pullEvent("monitor_touch")
      
      if y >= top and y <= bottom then
        selectedAttr = objAttr[y - 1]
        paintutils.drawPixel(1, y, colors.yellow)
        
        if (selectedAttr == "text" or 
            selectedAttr == "param" or 
            selectedAttr == "varID" or 
            selectedAttr == "sliderID" or 
            selectedAttr == "inputID" or 
            selectedAttr == "listID" or 
            selectedAttr == "message" or
            selectedAttr == "elements" or
            selectedAttr == "message") then
          userInput = readUserInput("Please enter a value for the " .. selectedAttr .. ".", false)
          if (userInput ~= nil) then
            screens[currentScreen][objectKey][selectedAttr] = userInput
          end
        elseif (selectedAttr == "funcType") then -- Button attribute
          if (sObject.funcType == "switch") then
            screens[currentScreen][objectKey][selectedAttr] = "function"
          else
            screens[currentScreen][objectKey][selectedAttr] = "switch"
          end
        elseif (selectedAttr == "isPassword" or selectedAttr == "isMultiselect") then
          if (sObject[selectedAttr]) then
            screens[currentScreen][objectKey][selectedAttr] = false
          else
            screens[currentScreen][objectKey][selectedAttr] = true
          end
        end
        paintutils.drawPixel(1, y, colors.black)
        if (not finished and selectedAttr ~= nil) then
          term.setCursorPos(2, y) -- I don't know if that's neccessary...
          for i = 2, maxX do
            term.write(" ")
          end
          term.setCursorPos(2, y)
          term.write(selectedAttr .. ": ")
          term.write(sObject[selectedAttr])
        end
      elseif (y == yPos + 1 and x >= 2 and x <= 1 + string.len(doneString)) then
        finished = true
      end
    end
  else -- Design mode
    canScale = false
    moveX = left
    moveY = top
    
    if (objType == "Button") then
      paintutils.drawPixel(right, bottom, editorScaleColor) -- Draw scale-pixel.
      scaleX = right
      scaleY = bottom
      canScale = true
    elseif (objType == "Slider") then
      direction = sObject.direction
      assert(direction)
      canScale = true
      
      if (direction == "left") then
        moveX = right
        moveY = top
        scaleX = left
        scaleY = bottom
      elseif (direction == "up") then
        moveX = left
        moveY = bottom
        scaleX = right
        scaleY = top
      else -- right or down
        moveX = left
        moveY = top
        scaleX = right
        scaleY = bottom
      end
      
      paintutils.drawPixel(scaleX, scaleY, editorScaleColor) -- Draw scale-pixel.
    elseif (objType == "Custom" and sObject.canScale) then -- AddOn
      canScale = true
      scaleX = right
      scaleY = bottom
      paintutils.drawPixel(scaleX, scaleY, editorScaleColor)
    end
    
    paintutils.drawPixel(moveX, moveY, editorMoveColor)
    showAlignmentLines(sObject, left, top, right, bottom, editorMarkerColor)
    
    horizontalAlignment = screens[currentScreen][objectKey].horizontalAlignment
    verticalAlignment = screens[currentScreen][objectKey].verticalAlignment
    leftAlignment = (horizontalAlignment == "left" or horizontalAlignment == "stretch")
    rightAlignment = (horizontalAlignment == "right" or horizontalAlignment == "stretch")
    topAlignment = (verticalAlignment == "top" or verticalAlignment == "stretch")
    bottomAlignment = (verticalAlignment == "bottom" or verticalAlignment == "stretch")
    
    term.setBackgroundColor(colors.black)
    
    _, _, x, y = os.pullEvent("monitor_touch")
    
    if (x >= left and x <= right and y >= top and y <= bottom) then -- clicked inside the object
      if (x == moveX and y == moveY) then -- move object
        paintutils.drawPixel(moveX, moveY, colors.white)
        _, _, x, y = os.pullEvent("monitor_touch")
        screens[currentScreen][objectKey].x = x
        screens[currentScreen][objectKey].y = y
      elseif (canScale and x == scaleX and y == scaleY) then -- scale object
        paintutils.drawPixel(scaleX, scaleY, colors.white)
        term.setBackgroundColor(colors.black)
        _, _, x, y = os.pullEvent("monitor_touch")
        
        if (objType == "Button" or objType == "Custom") then
          if (x > moveX + 2 and y >= moveY) then
            screens[currentScreen][objectKey].width = x - left + 1
            screens[currentScreen][objectKey].height = y - top + 1
          end
        elseif (objType == "Slider") then
          if (x < moveX and y == moveY) then -- Clicked left of the slider.
            screens[currentScreen][objectKey].direction = "left"
            screens[currentScreen][objectKey].length = moveX - x
          elseif (x == moveX and y < moveY) then -- Clicked above the slider.
            screens[currentScreen][objectKey].direction = "up"
            screens[currentScreen][objectKey].length = moveY - y
          elseif (x > moveX and y == moveY) then -- Clicked right of the slider.
            screens[currentScreen][objectKey].direction = "right"
            screens[currentScreen][objectKey].length = x - moveX
          elseif (x == moveX and y > moveY) then -- Clicked below the slider.
            screens[currentScreen][objectKey].direction = "down"
            screens[currentScreen][objectKey].length = y - moveY
          end
        end
      else -- clicked something else inside the object (no idea what I could use this for)
        
      end
    else -- User might have clicked an alignment-pixel.
      finished = false
      while not finished do
        
        if (x == 1 and y == top) then -- left alignment-pixel
          leftAlignment = not leftAlignment
        elseif (x == left and y == 1) then -- top alignment-pixel
          topAlignment = not topAlignment
        elseif (x == maxX and y == top) then -- right alignment-pixel
          rightAlignment = not rightAlignment
        elseif (x == left and y == maxY) then -- bottom alignment-pixel
          bottomAlignment = not bottomAlignment
        else
          finished = true
        end
        
        horizontalAlignment, verticalAlignment = getAlignment(leftAlignment, topAlignment, rightAlignment, bottomAlignment)
        screens[currentScreen][objectKey].horizontalAlignment = horizontalAlignment
        screens[currentScreen][objectKey].verticalAlignment = verticalAlignment
        
        if not finished then
          showAlignmentLines(sObject, left, top, right, bottom, editorMarkerColor)
          _, _, x, y = os.pullEvent("monitor_touch")
        end
      end
    end
  end
  
  term.setBackgroundColor(colors.black)
  showScreen(currentScreen)
end

function markVariables()
  for sObjectID, sObject in pairs(screens[currentScreen]) do
    if (sObject.objType == "Variable") then
      paintutils.drawPixel(sObject.x, sObject.y, colors.lime)
      term.setBackgroundColor(colors.black)
    end
  end
end

function getEditorInput()
  if not showEditorOptions then
    markVariables()
    _, _, xCoord, yCoord = os.pullEvent("monitor_touch")
  end
  
  if (showEditorOptions or yCoord == maxY and xCoord > maxX - string.len(refreshText)) then -- "Refresh" pressed => Options screen
    showEditorOptions = true
    showScreen("mainScreen")
    while showEditorOptions and not quit do
      getInput()
    end
  elseif (yCoord == maxY and xCoord >= 1 and xCoord <= string.len(backText)) then -- "Back" pressed => Quit
    quit = true
  else
    key, value = findObject(xCoord, yCoord) -- Find the object that the user touched.
    if (key == nil) then -- No object touched. Show selector for new object.
      paintutils.drawPixel(xCoord, yCoord, colors.white)
      if (showSelector(xCoord, yCoord, objectTypes)) then -- something has been selected
        showDefaultObject(selectedItem, xCoord, yCoord)
      end
    else
      editObject(key)
    end
  end
end

function screenEditor()
  editMode = true
  autoLoadObjects = false
  
  showEditorOptions = true
  showScreen("mainScreen")
  
  while not quit do
    getEditorInput()
  end
end

-- screen editor region end --

-- AddOn manager region start --

-- Removes all whitespaces to the left and right of the string.
function trim(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

-- Prints the message at the screen and exits the program.
function throwException(message, fileName, lineNumber)
  term.restore()
  error("AddOn loader error when reading file " .. fileName .. " at line " .. lineNumber .. ": " .. message)
end

-- Sets the optional attributes to their default-values if they haven't been set.
function setDefaultAttributes(object)
  if (object.objectType == "Button") then
    object.defaultWidth = (object.defaultWidth ~= nil) and object.defaultWidth or buttonDefaultWidth
    object.defaultHeight = (object.defaultHeight ~= nil) and object.defaultHeight or buttonDefaultHeight
  elseif (object.objectType == "List") then
    object.elements = string.gmatch(object.elements, "[^;]+")
  end
  
  object.canScale = (object.canScale ~= nil) and object.canScale or false
  object.canClick = (object.canClick ~= nil) and object.canClick or false
  
  return object
end

-- Returns whether the object is valid or not. Returns a message if it isn't.
function validateAddOnObject(object)
  if (object == nil or type(object) ~= "table") then
    return false, "Object is not a table!"
  end
  
  if (object.objectID == nil or object.objectID == "") then
    return false, "Object has no objecID!"
  end
  
  objType = object.objectType
  if (objType ~= "Button" and
      objType ~= "Variable" and
      objType ~= "Input" and
      objType ~= "List" and
      objType ~= "Custom") then
    return false, "Object has an invalid type!"
  end
  
  if (objType == "Button") then
    if (object.defaultWidth == nil or 
        object.defaultHeight == nil) then
      return false, "Button-type objects need to have defaultWidth and defaultHeight attributes!"
    elseif (object.text == nil) then
      return false, "Button-type objects need to have a text attribute!"
    end
  elseif (objType == "List") then
    if (object.elements == nil) then
      return false, "List-type objects need to have an elements-attribute!"
    end
  elseif (objType == "Custom") then
    if (object.canScale or object.canClick) then
      if (object.defaultWidth == nil or 
        object.defaultHeight == nil) then
        return false, "Default objects need to have defaultWidth and defaultHeight attributes when canScale or canClick is set to true!"
      end
    end
  end
  
  return true, nil
end

-- Reads the information between the file's <object> tags and adds the objects to the addOns-table.
function readAddOn(filePath)
  file = fs.open(filePath, "r")
  fileName = string.sub(fs.getName(filePath), 1, -5)
  addOns[fileName] = {}
  
  started = false
  finished = false
  lineNumber = 0
  
  newObject = nil
  createNewObject = false
  newObjectLine = -1
  
  while not finished do
    line = file.readLine()
    line = trim(line)
    lineNumber = lineNumber + 1
    
    if (line == nil) then -- Reached end of line.
      throwException("Objects not found!", fileName, lineNumber)
    elseif (line == "" and started) then
      throwException("No </objects> tag found in the file! Make sure that you don't have any empty lines between the <objects> tags!", fileName, lineNumber)
    elseif (line == "<objects>") then
      if started then
        throwException("Root tag <objects> can only be used once!", fileName, lineNumber)
      else
        started = true
      end
    elseif (line == "</objects>") then
      if createNewObject then -- Code ends without finishing the last object.
        throwException("No </object> tag found to close <object> at line " .. newObjectLine, fileName, lineNumber)
      else
        finished = true
      end
    elseif (line == "<object>") then
      if createNewObject then -- no "</object>" before the next "<object>" tag.
        throwException("No </object> tag found to close <object> at line " .. newObjectLine, fileName, lineNumber)
      else
        createNewObject = true
        newObject = {}
        newObjectLine = lineNumber
      end
    elseif (line == "</object>") then -- Create object and add it to the addOns-table.
      if not createNewObject then
        throwException("No <object> tag found that needs to be closed.", fileName, lineNumber)
      else
        newObject = setDefaultAttributes(newObject)
        isValid, errMsg = validateAddOnObject(newObject)
        if not isValid then
          throwException("Object declared between line " .. newObjectLine .. " and " .. lineNumber .. " is invalid: " .. errMsg, fileName, lineNumber)
        else
          addOns[fileName][newObject.objectID] = newObject
          newObject = nil
          createNewObject = false
          newObjectLine = -1
        end
      end
    elseif (string.find(line, "=") and started) then -- Line defines an attribute.
      if not createNewObject then
        throwException("Declared an attribute without having an <object> tag!", fileName, lineNumber)
      else
        attribute, value = splitAt(line, "=")
        newObject[attribute] = value
      end
    elseif started then -- Throw an error if the line is inside the <objects> tags and if it's invalid. Otherwise keep looking for the <objects> tag.
      throwException("Line is neither a tag nor an attribute!", fileName, lineNumber)
    end
  end
  
  file.close()
end

-- Looks for AddOn files and adds them to the addOns-table.
function loadAddOns()
  files = fs.list(shell.dir())
  for key, file in pairs(files) do
    if not fs.isDir(file) then -- if "file" is an actual file
      if string.sub(file, -4) == addOnExtension then -- if the file is a valid AddOn-file
        readAddOn(file)
      end
    end
  end
  
  for tableKey, tableValue in pairs(addOns) do
    for key, value in pairs(tableValue) do
      table.insert(objectTypes, tableKey .. " - " .. key)
    end
  end
end

-- AddOn manager region end --

-- Screen size adaptation region start --

-- Checks the default-size of the screens
-- table and adapts all objects to the new size if
-- the screen-size has changed.
function checkDefaultSize()
  if (screens["defaultX"] == nil or screens["defaultY"] == nil) then -- Program has been started for the first time.
    screens["defaultX"] = maxX
    screens["defaultY"] = maxY
  elseif (screens["defaultX"] ~= maxX or screens["defaultY"] ~= maxY) then -- Screen-size is different since last program start.
    defaultX = screens["defaultX"]
    defaultY = screens["defaultY"]
    xDiff = maxX - defaultX
    yDiff = maxY - defaultY
    xDiffPercent = maxX / defaultX -- unused right now... to complicated ):
    yDiffPercent = maxY / defaultY -- same here
    
    for screenID, screen in pairs(screens) do
      if (type(screen) == "table") then
        for objectID, object in pairs(screen) do
          if (type(object) == "table") then
            x = object.x
            y = object.y
            horizontalAlignment = object.horizontalAlignment
            verticalAlignment = object.verticalAlignment
            if (horizontalAlignment == nil or verticalAlignment == nil) then
              horizontalAlignment = "left"
              verticalAlignment = "top"
              screens[screenID][objectID].horizontalAlignment = horizontalAlignment
              screens[screenID][objectID].verticalAlignment = verticalAlignment
            end
            
            if (horizontalAlignment == "right") then
              screens[currentScreen][objectID].x = x + xDiff
            elseif (horizontalAlignment == "stretch") then
              if (object.objType == "Button") then
                screens[currentScreen][objectID].width = object.width + xDiff
              elseif (object.objType == "Slider") then
                if (object.direction == "left" or object.direction == "right") then
                  screens[currentScreen][objectID].length = object.length + xDiff
                  
                  if (object.direction == "left") then -- Slider has to be moved because it goes to the left.
                    screens[currentScreen][objectID].x = object.x + xDiff
                  end
                end
              end
            end
            
            if (verticalAlignment == "bottom") then
              screens[currentScreen][objectID].y = y + yDiff
            elseif (verticalAlignment == "stretch") then
              if (object.objType == "Button") then
                screens[currentScreen][objectID].height = object.height + yDiff
              elseif (object.objType == "Slider") then
                if (object.direction == "up" or object.direction == "down") then
                  screens[currentScreen][objectID].length = object.length + yDiff
                  
                  if (object.direction == "up") then -- Slider has to be moved because it goes to the left.
                    screens[currentScreen][objectID].y = object.y + yDiff
                  end
                end
              end
            end
          end
        end
      end
    end
    
    screens.defaultX = maxX
    screens.defaultY = maxy
  end
end

-- Screen size adaptation region end --

function printInfo()
  term.restore()
  print()
  print(version)
  print("Author: Encreedem")
  print()
  print("Param(s):")
  print("info - Shows some info about the program... but I guess you know that already.")
  print("edit - Starts the program in edit-mode.")
  print()
  print("Visit the CC-forums or my YouTube channel (LPF1337) for news and help.")
  term.redirect(monitor)
end

-- initialization

function init()
  if not getMonitor() then
    print("No monitor at " .. monitorSide .. " side!");
    return false
  end
  
  maxX, maxY = monitor.getSize()
  if (maxX < 16 or maxY < 10) then -- smaller than 2x2
    print("Screen too small! You need at least 2x2 monitors!")
    return false
  end
  
  loadAddOns()
  term.redirect(monitor)
  
  return true
end

function checkArgs()
  doCall = main
  
  if (args[1] ~= nil) then
    if (args[1] == "edit") then
      doCall = screenEditor
    elseif (args[1] == "info") then
      printInfo()
      return
    end
  end
  
  doCall()
end

if init() then
  loadScreens()
  checkDefaultSize()
  checkArgs()
  
  if editMode then
    saveScreens()
  end
  
  term.clear()
  term.setCursorPos(1, 1)
  term.restore()
end
; -------------------- CONSTANTS --------------------
DeclareModule App
  #APP_TITLE = "Docker Status"
  
  #MAX_CONTAINERS = 1000
  #MAX_PATTERNS = 1000
  #MAX_LINES = 1000
  
  #ICON_SIZE = 64
  
  #JSON_SAVE = 0
  #JSON_LOAD = 1
  
  #Notification_Running_TimerID = 1
  #Notification_Duration = 2500
  #Notification_Width = 215
  #Notification_Height = 46
  
  #Notification_Large_Width = 270
  #Notification_TimerID = 2
  #Notification_Long_Duration = 5000
  
  Structure ContainerOutput
    List lines.s()
    currentLine.q
  EndStructure
  
  Structure LogWindow
    winID.i
    editorGadgetID.i
    containerIndex.i
  EndStructure
  
  Structure ContainterMetaData
    logWindowX.l
    logWindowY.l
    logWindowW.l
    logWindowH.l
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      overlayIconHandle.i
    CompilerEndIf
  EndStructure
  
  Global containerCount.l = 0
  
  Global Dim containerName.s(#MAX_CONTAINERS-1)
  Global Dim bgColor.l(#MAX_CONTAINERS-1)
  Global Dim innerColor.l(#MAX_CONTAINERS-1)
  Global Dim neutralInnerColor.l(#MAX_CONTAINERS-1)
  Global Dim infoImageID.q(#MAX_CONTAINERS-1)
  Global Dim infoImageRunningID.q(#MAX_CONTAINERS-1)
  Global Dim dockerProgramID(#MAX_CONTAINERS-1)
  Global Dim patternCount.l(#MAX_CONTAINERS-1)
  Global Dim lastMatchTime.l(#MAX_CONTAINERS-1)
  Global Dim tooltip.s(#MAX_CONTAINERS-1)
  Global Dim trayID.l(#MAX_CONTAINERS-1)
  Global Dim containerStarted.b(#MAX_CONTAINERS-1)
  Global Dim containerOutput.containerOutput(#MAX_CONTAINERS-1)
  Global Dim lastMatch.s(#MAX_CONTAINERS-1)
  Global Dim containerStatusColor.l(#MAX_CONTAINERS-1)
  Global Dim lastMatchPattern.l(#MAX_CONTAINERS-1)
  Global Dim patterns.s(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
  Global Dim patternColor.l(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
  Global Dim patternsNotification.b(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
  Global Dim containerStartedTime.l(#MAX_CONTAINERS-1)
  Global Dim containerLogEditorID(#MAX_CONTAINERS-1)
  Global Dim containterMetaData.ContainterMetaData(#MAX_CONTAINERS-1)
  Global NewList logWindows.LogWindow()
  
  ; Declare procedures in order of use
  Declare ApplyTheme(winID)
  Declare ShowWindowFadeIn(winID)
  Declare ApplySingleColumnListIcon(listHwnd)
  
  Declare AddMonitor(contName.s, bgCol.l)
  Declare RemoveMonitor(index)
  Declare UpdateMonitorList()
  Declare UpdateButtonStates()
  
  Declare AddPattern(index, pat.s, color.l, notification)
  Declare UpdatePatternList(index)
  Declare UpdatePatternButtonStates()
  
  Declare CreateMonitorIcon(index, innerCol, bgCol)
  Declare UpdateMonitorIcon(index, matchColor)
  
  Declare SaveSettings()
  Declare LoadSettings()
  
  Declare StartDockerFollow(index)
  Declare StopDockerFollow(index)
  Declare CheckDockerOutput(index)
  
  Declare HandleInputLine(index, line$, addLine = #True, waitingForInput = #False)
  Declare ShowLogs(index)
  
  Declare SetListItemColor(gadgetID, index, color)
  Declare SetListItemStarted(index, started)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows: Declare SetOverlayIcon(winID, index):CompilerEndIf
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows:Declare SetEditorTextColor(index, newLinesCount.l = 0):CompilerEndIf
  
  Declare IsSomeRunning()
  
  Declare IsDarkModeActive()
  
  Declare WindowCallback(hwnd, msg, wParam, lParam)
  
  Declare CleanupApp() 
  
  Enumeration KeyboardEvents
    #EventOk
  EndEnumeration
  
  
  Structure MainWindowGadgets
    ContainerList.i
    BtnAdd.i
    BtnEdit.i
    BtnRemove.i
    BtnRules.i
    BtnStart.i
    BtnStop.i
  EndStructure
  
  Global *MainWindowGadgets.MainWindowGadgets = AllocateMemory(SizeOf(MainWindowGadgets))
  
  Enumeration MonitorType
    #COMMAND
    #CONTAINER
  EndEnumeration
  
  Structure MonitorConfiguration
    type.i
    content.s
    commandTransformed.s
    currentCommand.i
    waitingForInput.b
  EndStructure
  
  Global Dim monitorConfiguration.MonitorConfiguration(#MAX_CONTAINERS-1)
  
  Global notificationWinID = 0
  Global notificationRunningWinID = 0
  
  Declare NormalResizeGadget(Gadget, x.f, y.f, width.f, height.f,parentsRoundingDeltaX.f = 0,parentsRoundingDeltaY.f = 0)
  
  Global DPI_Scale.f
  Global consoleFont
  
  
  Debug DPI_Scale
  
  
  Declare.f MaxF(a.f, b.f)
  
  Global IsDarkModeActiveCached = #False
  Global darkThemeBackgroundColor = RGB(30,30,30)
  Global darkThemeForegroundColor = RGB(255, 255, 255)
  Global lightThemeBackgroundColor = RGB(250,250,250)
  Global lightThemeForegroundColor = RGB(0,0,0)
  
  
  Global themeBackgroundColor = lightThemeBackgroundColor
  Global themeForegroundColor = lightThemeForegroundColor
  
  Prototype.i ProtoHandleThemeChange(*p)
  Structure ThemeHandler
    *handleChange.ProtoHandleThemeChange
    *p
  EndStructure 
  Global NewList ThemeHandler.ThemeHandler()
  
  Global DPI_Scale.f 
EndDeclareModule 

; -------------------- GLOBAL VARIABLES --------------------
Module App
  
  Global patCol = 0
  Global bgCol = 0
  Global currentContainerIndex = 0
  Global currentPatternIndex = 0
  Global lastTimeOuputAdded = 0
  
  IncludeFile "utils.pb"
  IncludeFile "winTheme.pb"
  
  
  ExamineDesktops()
  
  
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
      fontName$ = "Consolas"
    CompilerCase #PB_OS_Linux
      fontName$ = "Monospace"
    CompilerCase #PB_OS_MacOS
      fontName$ = "Monaco"
  CompilerEndSelect
  
  Global consoleFont =  LoadFont(#PB_Any , fontName$, 12, #PB_Font_HighQuality)
  
  ; -------------------- Dark Mode Helpers --------------------
  Procedure IsDarkModeActive()
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      
      Protected key, result = 0, value.l, size = SizeOf(Long)
      If RegOpenKeyEx_(#HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", 0, #KEY_READ, @key) = #ERROR_SUCCESS
        If RegQueryValueEx_(key, "AppsUseLightTheme", 0, 0, @value, @size) = #ERROR_SUCCESS
          result = Bool(value = 0) ; 0 = dark mode
          IsDarkModeActiveCached = result
        EndIf
        RegCloseKey_(key)
      EndIf
      
    CompilerElseIf #PB_Compiler_OS = #PB_OS_MacOS
      Define mode$, result
      result = RunProgram("/usr/bin/defaults", "read -g AppleInterfaceStyle", "", #PB_Program_Open | #PB_Program_Read)
      If result
        mode$ = ReadProgramString(result)
        CloseProgram(result)
      EndIf
      
      If mode$ = "Dark"
        IsDarkModeActiveCached = #True 
      Else
        IsDarkModeActiveCached = #False 
      EndIf
    CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
      
      Protected result, line$, theme$, cmd$, tmp$
      
      ; --- 1️⃣ Try freedesktop.org unified color-scheme (modern GNOME/KDE)
      result = RunProgram("gsettings", "get org.freedesktop.appearance color-scheme", "", #PB_Program_Open | #PB_Program_Read)
      If result
        tmp$ = Trim(ReadProgramString(result), "'")
        CloseProgram(result)
        If LCase(tmp$) = "prefer-dark"
          IsDarkModeActiveCached = #True
          ProcedureReturn
        ElseIf LCase(tmp$) = "default"
          IsDarkModeActiveCached = #False
          ProcedureReturn
        EndIf
      EndIf
      
      ; --- 2️⃣ Try GNOME / Cinnamon / XFCE GTK theme
      result = RunProgram("gsettings", "get org.gnome.desktop.interface gtk-theme", "", #PB_Program_Open | #PB_Program_Read)
      If result
        theme$ = Trim(ReadProgramString(result), "'")
        CloseProgram(result)
        If FindString(LCase(theme$), "dark")
          IsDarkModeActiveCached = #True
          ProcedureReturn
        ElseIf theme$ <> ""
          IsDarkModeActiveCached = #False
          ProcedureReturn
        EndIf
      EndIf
      
      ; --- 3️⃣ Try KDE Plasma config
      If FileSize(GetHomeDirectory() + ".config/kdeglobals") > 0
        result = ReadFile(#PB_Any, GetHomeDirectory() + ".config/kdeglobals")
        If result
          While Eof(result) = 0
            line$ = ReadString(result)
            If Left(line$, 11) = "ColorScheme"
              theme$ = Trim(StringField(line$, 2, "="))
              Break
            EndIf
          Wend
          CloseFile(result)
          If FindString(LCase(theme$), "dark")
            IsDarkModeActiveCached = #True
          Else
            IsDarkModeActiveCached = #False
          EndIf
          ProcedureReturn
        EndIf
      EndIf
      
      ; --- 4️⃣ Default: assume Light mode
      IsDarkModeActiveCached = #False
      
    CompilerEndIf
    If IsDarkModeActiveCached
      themeBackgroundColor = darkThemeBackgroundColor
      themeForegroundColor = darkThemeForegroundColor
    Else
      themeBackgroundColor = lightThemeBackgroundColor
      themeForegroundColor = lightThemeForegroundColor
    EndIf 
    ProcedureReturn result
  EndProcedure
  
  IsDarkModeActive()   
  
  
  Procedure.s ReadProgramOutputBytes(ProgramID, length)
    Protected buffer
    Protected bytesRead.l
    
    buffer = AllocateMemory(length)
    If buffer = 0
      ProcedureReturn ""
    EndIf
    
    bytesRead = ReadProgramData(ProgramID, buffer, length)
    ProcedureReturn PeekS(buffer, bytesRead, #PB_UTF8)
  EndProcedure
  
  Procedure IsWaitingForInput(output.s)
    foundPrompt = #False
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If FindString(output, ">", #PB_String_NoCase) > 0
        If Mid(Trim(output), Len(Trim(output)), 1) = ">"
          If FindString(output, ":\", #PB_String_NoCase) > 0 Or FindString(output, "\", #PB_String_NoCase) > 0
            foundPrompt = #True
          EndIf
        EndIf
      EndIf
    CompilerElse
      foundPrompt = #True
    CompilerEndIf
    ProcedureReturn foundPrompt
  EndProcedure
  
  
  Procedure NormalResizeGadget(Gadget, x.f, y.f, width.f, height.f,parentsRoundingDeltaX.f = 0,parentsRoundingDeltaY.f = 0)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(Gadget)
        Protected hWnd = GadgetID(Gadget)
        Protected hParent = GetParent_(hWnd)
        
        Protected flags = #SWP_NOACTIVATE | #SWP_NOZORDER |#SWP_NOREDRAW |#SWP_NOCOPYBITS|#SWP_NOOWNERZORDER|#SWP_NOSENDCHANGING
        Protected currentX.f, currentY.f, currentW.f, currentH.f
        
        Protected rect.RECT
        
        Protected newX.f, newY.f, newW.f, newH.f
        
        ; Get current position and size of the gadget
        If GetWindowRect_(hWnd, @rect)
          point.POINT
          point\x =  rect\left
          point\y =  rect\top
          
          MapWindowPoints_(#Null, hParent, @point, 2)
          currentX = point\x
          currentY = point\y
          currentW = rect\right-rect\left
          currentH = rect\bottom-rect\top
        Else
          currentX = 0.0
          currentY = 0.0
          currentW = 0.0
          currentH = 0.0
        EndIf
        
        currentRoundingDeltaX.f = 0
        If x = #PB_Ignore
          newX = currentX
          currentRoundingDeltaX = parentsRoundingDeltaX
        Else
          newX = x * DPI_Scale
          ; x position did not change because of parentDiff -> let w handle diff
          If Round(newX,#PB_Round_Nearest)-Round(newX+ parentsRoundingDeltaX,#PB_Round_Nearest)=0
            currentRoundingDeltaX = parentsRoundingDeltaX
          EndIf 
          newX + parentsRoundingDeltaX
        EndIf
        currentRoundingDeltaY.f = 0
        
        If y = #PB_Ignore
          newY = currentY
          currentRoundingDeltaY = parentsRoundingDeltaY
          
        Else
          newY = y * DPI_Scale
          If Round(newY,#PB_Round_Nearest)-Round(newY+ parentsRoundingDeltaY,#PB_Round_Nearest)=0
            currentRoundingDeltaY = parentsRoundingDeltaY
          EndIf 
          newY + parentsRoundingDeltaY
        EndIf
        
        If width = #PB_Ignore
          newW = currentW
        Else
          currentRoundingDeltaX = currentRoundingDeltaX + newX -Round(newX,#PB_Round_Nearest)
          newW = width * DPI_Scale
          If currentRoundingDeltaX<>0
            newW = newW + currentRoundingDeltaX   
          EndIf 
        EndIf
        
        If height = #PB_Ignore
          newH = currentH
        Else  
          currentRoundingDeltaY = currentRoundingDeltaY + newY -Round(newY,#PB_Round_Nearest)
          newH = height * DPI_Scale
          If currentRoundingDeltaY<>0
            newH = newH + currentRoundingDeltaY   
          EndIf 
        EndIf
        
        newX = Round(newX, #PB_Round_Nearest)
        newY = Round(newY, #PB_Round_Nearest)
        newW = Round(newW, #PB_Round_Nearest)
        newH = Round(newH, #PB_Round_Nearest)
        
        SetWindowPos_(GadgetID(Gadget), #Null, newX, newY, newW, newH, flags)
        InvalidateRect_(GadgetID(Gadget), #Null, #False)
      EndIf
    CompilerElse
      ResizeGadget(Gadget, x,y,width,height)
    CompilerEndIf
    ProcedureReturn
  EndProcedure
  
  
  Procedure ApplyTheme(winID)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hWnd = WindowID(winID)
      ApplyThemeHandle(hWnd)
    CompilerEndIf
  EndProcedure
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Procedure ShowWindowFadeInHandle(hWnd, dontWait=#False )
      ShowWindow_(hWnd, #SW_SHOWNA)
      UpdateWindow_(hWnd)
      RedrawWindow_(hWnd, #Null, #Null, #RDW_UPDATENOW | #RDW_ALLCHILDREN | #RDW_FRAME)
      While PeekMessage_(@msg, hWnd, #WM_PAINT, #WM_PAINT, #PM_REMOVE)
        DispatchMessage_(@msg)
      Wend
      If dontWait = #False
        Repeat : Delay(1) : Until WindowEvent() = 0
      EndIf 
      Protected hUser32 = OpenLibrary(#PB_Any, "user32.dll")
      If hUser32
        Protected *AnimateWindow = GetFunction(hUser32, "AnimateWindow")
        If *AnimateWindow
          CallFunctionFast(*AnimateWindow, hWnd, 300, $80000 | $20000)
        EndIf
        CloseLibrary(hUser32)
      EndIf
    EndProcedure
  CompilerEndIf
  Procedure ShowWindowFadeIn(winID)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hWnd = WindowID(winID)
      ShowWindowFadeInHandle(hWnd)
    CompilerElse
      HideWindow(winID, #False)
    CompilerEndIf
  EndProcedure
  
  
  IncludeFile "winIcon.pb"
  
  Global settingsFile.s = "docker_status.json"
  
  Procedure SaveSettings()
    If CreateJSON(#JSON_SAVE)
      MonitorArray = SetJSONArray(JSONValue(#JSON_SAVE))
      For i = 0 To containerCount-1
        MonitorObj = SetJSONObject(AddJSONElement(MonitorArray))
        SetJSONString(AddJSONMember(MonitorObj, "Name"), containerName(i))
        SetJSONInteger(AddJSONMember(MonitorObj, "BGColor"), bgColor(i))
        SetJSONInteger(AddJSONMember(MonitorObj, "InnerColor"), innerColor(i))
        SetJSONInteger(AddJSONMember(MonitorObj, "NeutralColor"), neutralInnerColor(i))
        SetJSONInteger(AddJSONMember(MonitorObj, "Started"), containerStarted(i))
        SetJSONInteger(AddJSONMember(MonitorObj, "LogX"), containterMetaData(i)\logWindowX)
        SetJSONInteger(AddJSONMember(MonitorObj, "LogY"), containterMetaData(i)\logWindowY)
        SetJSONInteger(AddJSONMember(MonitorObj, "LogW"), containterMetaData(i)\logWindowW)
        SetJSONInteger(AddJSONMember(MonitorObj, "LogH"), containterMetaData(i)\logWindowH)
        PatternArray = SetJSONArray(AddJSONMember(MonitorObj, "Patterns"))
        For p = 0 To patternCount(i)-1
          PatternObj = SetJSONObject(AddJSONElement(PatternArray))
          SetJSONString(AddJSONMember(PatternObj, "Pattern"), patterns(i,p))
          SetJSONInteger(AddJSONMember(PatternObj, "Color"), patternColor(i,p))
          SetJSONBoolean(AddJSONMember(PatternObj, "Notification"), patternsNotification(i,p))
        Next
      Next
      If CreateFile(0, settingsFile)
        WriteString(0, ComposeJSON(#JSON_SAVE, #PB_JSON_PrettyPrint))
        CloseFile(0)
      EndIf
    EndIf
  EndProcedure
  
  Procedure LoadSettings()
    If ReadFile(0, settingsFile)
      Input$ = ""
      While Not Eof(0)
        Input$ + Trim(ReadString(0))
      Wend
      CloseFile(0)
      If ParseJSON(#JSON_LOAD, Input$, #PB_JSON_NoCase)
        Structure Pattern
          pattern.s
          color.l
          notification.b
        EndStructure
        Structure Container
          name.s
          bgColor.l
          innerColor.l
          neutralInnerColor.l
          containerStarted.b
          logX.l
          logY.l
          logW.l
          logH.l
          List patterns.Pattern()
        EndStructure
        NewList ContainerList.Container()
        ParseJSON(0, Input$)
        ExtractJSONList(JSONValue(#JSON_LOAD), ContainerList())
        ForEach ContainerList()
          containerName(containerCount) = ContainerList()\name
          bgColor(containerCount) = ContainerList()\bgColor
          innerColor(containerCount) = ContainerList()\innerColor
          neutralInnerColor(containerCount) = ContainerList()\neutralInnerColor
          containerStarted(containerCount) = ContainerList()\containerStarted
          containterMetaData(containerCount)\logWindowX = ContainerList()\logX
          containterMetaData(containerCount)\logWindowY = ContainerList()\logY
          containterMetaData(containerCount)\logWindowW = ContainerList()\logW
          containterMetaData(containerCount)\logWindowH = ContainerList()\logH
          patternCount(containerCount) = 0
          ForEach ContainerList()\patterns()
            patterns(containerCount, patternCount(containerCount)) = ContainerList()\patterns()\pattern
            patternColor(containerCount, patternCount(containerCount)) = ContainerList()\patterns()\color
            patternsNotification(containerCount, patternCount(containerCount)) = ContainerList()\patterns()\notification
            patternCount(containerCount) + 1
          Next
          tooltip(containerCount) = containerName(containerCount)
          containerCount + 1
        Next
      EndIf
    EndIf
  EndProcedure
  
  IncludeFile "winEditor.pb"
  
  Procedure ScrollEditorToBottom(gadget)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      ProcedureReturn ScrollEditorToBottomWin(gadget)
    CompilerEndIf
  EndProcedure
  
  Procedure.l IsAtScrollBottom(EditorGadgetID)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      ProcedureReturn IsAtScrollBottomWin(EditorGadgetID)
    CompilerEndIf
  EndProcedure
  
  
  
  
  Procedure ShowSystrayRunningNotification(index)
    ExamineDesktops()
    w = DesktopUnscaledX(DesktopWidth(0))
    h = DesktopUnscaledY(DesktopHeight(0))
    winID = OpenWindow(#PB_Any, w - #Notification_Width - 10 - 10, h - #Notification_Height - 10 - 80, #Notification_Width, #Notification_Height, "", #PB_Window_BorderLess | #PB_Window_Tool | #PB_Window_Invisible)
    If winID
      StickyWindow(winID, #True)
      textGadget = TextGadget(#PB_Any, 60, 2, #Notification_Width-80, 20, "Docker Status is running", #PB_Text_Center)
      ImageGadget(#PB_Any, 20, 0, 0, 0, ImageID(infoImageRunningID(index)), #PB_Image_Raised)
      If notificationRunningWinID <> 0
        CloseWindow(notificationRunningWinID)
        notificationRunningWinID = 0
      EndIf
      notificationRunningWinID = winID
      AddWindowTimer(winID, #Notification_Running_TimerID, #Notification_Duration)
      ApplyTheme(winID)
      Repeat : Delay(1) : Until WindowEvent() = 0
      ShowWindowFadeIn(winID)
    EndIf   
  EndProcedure
  
  
  Global notificationTextGadgetID = 0
  Global notificationImageGadgetID = 0
  
  
  
  Procedure ShowSystrayNotification(index, text.s)
    If ElapsedMilliseconds()-containerStartedTime(index) < 5000
      ProcedureReturn
    EndIf
    RemoveWindowTimer(notificationWinID, #Notification_TimerID)
    If notificationWinID <> 0
      SetGadgetText(notificationTextGadgetID, text)
      SetGadgetState(notificationImageGadgetID, ImageID(infoImageRunningID(index)))
      AddWindowTimer(notificationWinID, #Notification_TimerID, #Notification_Long_Duration)
    Else
      ExamineDesktops()
      w = DesktopUnscaledX(DesktopWidth(0))
      h = DesktopUnscaledY(DesktopHeight(0))
      winID = OpenWindow(#PB_Any, w - #Notification_Large_Width - 10 - 10, h - #Notification_Height - 10 - 80, #Notification_Large_Width, #Notification_Height, "", #PB_Window_BorderLess | #PB_Window_Tool | #PB_Window_Invisible)
      If winID
        StickyWindow(winID, #True)
        
        notificationTextGadgetID = TextGadget(#PB_Any, 60, 2, #Notification_Width-80, 20, text, #PB_Text_Center)
        notificationImageGadgetID = ImageGadget(#PB_Any, 20, 0, 0, 0, ImageID(infoImageRunningID(index)), #PB_Image_Raised)
        
        notificationWinID = winID
        AddWindowTimer(winID, #Notification_TimerID, #Notification_Long_Duration)
        ApplyTheme(winID)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(winID)
      EndIf
    EndIf
    GadgetToolTip(notificationImageGadgetID, text)
    GadgetToolTip(notificationTextGadgetID, text)
  EndProcedure
  
  Procedure CreateMonitorIcon(index, innerCol, bgCol)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      CreateMonitorIconWin(index, innerCol, bgCol)
    CompilerEndIf
  EndProcedure
  
  Procedure SetListItemStarted(index, started)
    bgCol = bgColor(index)
    Protected img = CreateImage(#PB_Any, 32, 32, 32, bgCol)
    If img
      StartVectorDrawing(ImageVectorOutput(img))
      VectorSourceColor(RGBA(Red(bgCol), Green(bgCol), Blue(bgCol), 255))
      FillVectorOutput()
      If started
        MovePathCursor(8, 6)
        AddPathLine(24, 16)
        AddPathLine(8, 26)
        ClosePath()
        VectorSourceColor(RGBA(0, 147, 242, 255))
        FillPath()
        MovePathCursor(8, 6)
        AddPathLine(24, 16)
        AddPathLine(8, 26)
        ClosePath()
        VectorSourceColor(RGBA(255, 255, 255, 255))
        StrokePath(4)
        infoImageRunningID(index) = img
      EndIf
      StopVectorDrawing()
      SetGadgetItemImage(*MainWindowGadgets\ContainerList, index, ImageID(img))
    EndIf
  EndProcedure
  
  Procedure SetListItemColor(gadgetID, index, color)
    Protected img = CreateImage(#PB_Any, 1, 1)
    If img
      StartDrawing(ImageOutput(img))
      Box(0, 0, 1, 1, color)
      StopDrawing()
      SetGadgetItemImage(gadgetID, index, ImageID(img))
    EndIf
  EndProcedure
  
  
  
  Procedure AddMonitor(contName.s, bgCol.l)
    If containerCount >= #MAX_CONTAINERS
      MessageRequester("Docker Status", "Max monitors reached", 0)
      ProcedureReturn
    EndIf
    containerName(containerCount) = contName
    bgColor(containerCount) = bgCol
    innerColor(containerCount) = $FFFFFF
    neutralInnerColor(containerCount) = $FFFFFF
    patternCount(containerCount) = 0
    tooltip(containerCount) = contName
    containerCount + 1
    SaveSettings()
  EndProcedure
  
  Procedure RemoveMonitor(index)
    If dockerProgramID(index) <> 0
      CloseProgram(dockerProgramID(index))
      dockerProgramID(index) = 0
    EndIf
    If trayID(index) <> 0
      RemoveSysTrayIcon(trayID(index))
      trayID(index) = 0
    EndIf
    For i = index To containerCount - 2
      containerName(i) = containerName(i + 1)
      bgColor(i) = bgColor(i + 1)
      innerColor(i) = innerColor(i + 1)
      neutralInnerColor(i) = neutralInnerColor(i + 1)
      infoImageID(i) = infoImageID(i + 1)
      trayID(i) = trayID(i + 1)
      containerStarted(i) = containerStarted(i + 1)
      dockerProgramID(i) = dockerProgramID(i + 1)
      patternCount(i) = patternCount(i + 1)
      tooltip(i) = tooltip(i + 1)
      For p = 0 To #MAX_PATTERNS-1
        patterns(i, p) = patterns(i+1, p)
        patternColor(i, p) = patternColor(i+1, p)
      Next
      lastMatchTime(i) = lastMatchTime(i+1)
    Next
    containerCount - 1
    SaveSettings()
  EndProcedure
  
  Procedure ApplySingleColumnListIcon(listHwnd)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      ApplySingleColumnListIconWin(listHwnd)
    CompilerEndIf
  EndProcedure
  
  Procedure UpdatePatternButtonStates()
    If IsWindow(4)
      selIndex = GetGadgetState(40)
      If selIndex >= 0
        DisableGadget(42, #False)
        DisableGadget(43, #False)
      Else
        DisableGadget(42, #True)
        DisableGadget(43, #True)
      EndIf
    EndIf
  EndProcedure
  
  Procedure UpdatePatternList(index)
    If IsWindow(4)
      ClearGadgetItems(40)
      For p = 0 To patternCount(index)-1
        AddGadgetItem(40, -1, "  " + patterns(index, p))
        SetListItemColor(40, p, patternColor(index, p))
      Next
    EndIf
  EndProcedure
  
  Procedure AddPattern(index, pat.s, color.l, notification)
    If index < 0 Or index >= containerCount
      ProcedureReturn
    EndIf
    If patternCount(index) >= #MAX_PATTERNS
      ProcedureReturn
    EndIf
    patterns(index, patternCount(index)) = pat
    patternColor(index, patternCount(index)) = color
    patternsNotification(index, patternCount(index)) = notification
    patternCount(index) + 1
    SaveSettings()
  EndProcedure
  
  Procedure.s TryDockerDefaultPaths()
    Protected dockerPaths.s
    Protected i = 1
    Protected path$ = ""
    Select #PB_Compiler_OS
      Case #PB_OS_Windows
        dockerPaths = "C:\Program Files\Docker\Docker\resources\bin\docker.exe|C:\Program Files\Docker\Docker\docker.exe|C:\Program Files\Docker\docker.exe|C:\Program Files (x86)\Docker\Docker\resources\bin\docker.exe|C:\Program Files (x86)\Docker\Docker\docker.exe"
      Case #PB_OS_Linux
        dockerPaths = "/usr/bin/docker|/usr/local/bin/docker|/snap/bin/docker|/bin/docker"
      Case #PB_OS_MacOS
        dockerPaths = "/usr/local/bin/docker|/usr/bin/docker|/opt/homebrew/bin/docker|/Applications/Docker.app/Contents/Resources/bin/docker"
    EndSelect
    Repeat
      path$ = StringField(dockerPaths, i, "|")
      If path$ <> "" And FileSize(path$)
        ProcedureReturn path$
      EndIf
      i + 1
    Until Trim(path$) = ""
    ProcedureReturn "docker"
  EndProcedure
  
  Procedure.s GetDockerExcutable()
    Protected pathEnv.s = GetEnvironmentVariable("PATH")
    folder.s = ""
    index = 1
    Repeat
      folder = StringField(pathEnv, index, ";")
      Protected candidate.s = folder + "\docker.exe"
      If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
      candidate = folder + "\Docker.exe"
      If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
      index + 1
    Until folder = ""
    ProcedureReturn TryDockerDefaultPaths()
  EndProcedure
  
  Procedure StopDockerFollow(index)
    If notificationRunningWinID <> 0
      CloseWindow(notificationRunningWinID)
      notificationRunningWinID = 0
    EndIf
    If notificationWinID <> 0
      CloseWindow(notificationWinID)
      notificationWinID = 0
    EndIf
    If dockerProgramID(index) <> 0 And IsProgram(ProgramID)
      If ProgramRunning(ProgramID)
        CloseProgram(dockerProgramID(index))
      EndIf
      dockerProgramID(index) = 0
    EndIf
    dockerProgramID(index) = 0
    monitorConfiguration(index)\currentCommand = 0
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows : RemoveOverlayIcon(WindowID(0)) : CompilerEndIf
    ForEach logWindows()
      If logWindows()\containerIndex = index
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows : RemoveOverlayIcon(WindowID(logWindows()\winID)) : CompilerEndIf
        CloseWindow(logWindows()\winID)
        DeleteElement(logWindows())
        Break
      EndIf
    Next
    If trayID(index) <> 0
      RemoveSysTrayIcon(trayID(index))
      trayID(index) = 0
    EndIf
    containerStarted(index) = #False
    SetListItemStarted(index, #False)
    SetActiveGadget(*MainWindowGadgets\ContainerList)
    SetGadgetItemState(*MainWindowGadgets\ContainerList, index, #PB_ListIcon_Selected)
    UpdateButtonStates()
    containerStartedTime(index) = ElapsedMilliseconds()
  EndProcedure
  
  Procedure.s TransformCommand(commandString.s)
    Protected result.s = ""
    Protected commandCount.i
    Protected command.s
    Protected insideDocker.i = #False
    Protected dockerCommand.s = ""
    Protected containerName.s = ""
    Protected shellType.s = ""
    Protected shellCommands.s = ""
    Protected postDockerCommands.s = ""
    Protected chainOperator.s
    Protected i.i
    
    commandCount = CountString(commandString, Chr(10)) + 1
    If commandCount = 1
      ProcedureReturn Trim(commandString)
    EndIf
    If FindString(commandString, Chr(3)) > 0
      ProcedureReturn commandString
    EndIf
    
    For i = 1 To commandCount
      command = Trim(StringField(commandString, i, Chr(10)))
      If command = Chr(3) Or FindString(command, Chr(3)) > 0
        If insideDocker
          insideDocker = #False
        EndIf
        Continue
      EndIf
      
      If command <> ""
        If FindString(command, "docker exec", 1, #PB_String_NoCase) > 0
          insideDocker = #True
          dockerCommand = command
          tempCmd.s = command
          tempCmd = ReplaceString(tempCmd, "docker exec", "", #PB_String_NoCase, 1, 1)
          tempCmd = Trim(tempCmd)
          tempCmd = ReplaceString(tempCmd, "-it", "")
          tempCmd = ReplaceString(tempCmd, "-i", "")
          tempCmd = ReplaceString(tempCmd, "-t", "")
          tempCmd = ReplaceString(tempCmd, "-d", "")
          tempCmd = Trim(tempCmd)
          spacePos = FindString(tempCmd, " ")
          If spacePos > 0
            containerName = Left(tempCmd, spacePos - 1)
            shellType = Trim(Mid(tempCmd, spacePos + 1))
          Else
            containerName = tempCmd
            shellType = "/bin/sh"
          EndIf
          If shellType = ""
            shellType = "/bin/sh"
          ElseIf FindString(shellType, "bash", 1, #PB_String_NoCase) > 0
            shellType = "/bin/bash"
          ElseIf FindString(shellType, "sh", 1, #PB_String_NoCase) > 0
            shellType = "/bin/sh"
          ElseIf FindString(shellType, "ash", 1, #PB_String_NoCase) > 0
            shellType = "/bin/ash"
          ElseIf FindString(shellType, "dash", 1, #PB_String_NoCase) > 0
            shellType = "/bin/dash"
          Else
            If Left(shellType, 1) <> "/"
              shellType = "/bin/sh"
            EndIf
          EndIf
          chainOperator = " && "
        ElseIf insideDocker And (LCase(command) = "exit" Or FindString(LCase(command), "exit ", 1) = 1)
          insideDocker = #False
        Else
          If insideDocker
            If shellCommands <> ""
              shellCommands + chainOperator
            EndIf
            shellCommands + command
          Else
            If dockerCommand = ""
              If result <> ""
                result + Chr(10)
              EndIf
              result + command
            Else
              If postDockerCommands <> ""
                postDockerCommands + Chr(10)
              EndIf
              postDockerCommands + command
            EndIf
          EndIf
        EndIf
      EndIf
    Next
    
    If dockerCommand <> ""
      If result <> ""
        result + Chr(10)
      EndIf
      If shellCommands <> ""
        result + "docker exec -i " + containerName + " " + shellType + " -c " + Chr(34) + shellCommands + Chr(34)
      Else
        result + "docker exec -i " + containerName + " " + shellType
      EndIf
      If postDockerCommands <> ""
        result + Chr(10) + postDockerCommands
      EndIf
    EndIf
    
    ProcedureReturn result
  EndProcedure
  
  Procedure StartDockerFollow(index)
    If dockerProgramID(index) <> 0
      If IsProgram(dockerProgramID(index))
        CloseProgram(dockerProgramID(index))
      EndIf
      dockerProgramID(index) = 0
    EndIf
    
    containerStarted(index) = #True
    If trayID(index) = 0
      CreateMonitorIcon(index, innerColor(index), bgColor(index))
    EndIf
    SetListItemStarted(index, #True)
    ShowSystrayRunningNotification(index)
    
    dockerExecutable$ = GetDockerExcutable()
    cmdWithUTF8Command.s = "chcp 65001 >NUL &"
    
    
    Select monitorConfiguration(index)\type
      Case #COMMAND
        monitorConfiguration(index)\commandTransformed = TransformCommand(monitorConfiguration(index)\content)
        commandString$ = monitorConfiguration(index)\commandTransformed
        commandCount = CountString(commandString$, Chr(10)) + 1
        
        If commandCount > 1
          firstCommand$ = Trim(StringField(commandString$, 1, Chr(10)))
          dockerCommand$ = "/k " + cmdWithUTF8Command + " " + firstCommand$
          ProgramID = RunProgram("cmd.exe", dockerCommand$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Write | #PB_Program_Hide)
          monitorConfiguration(index)\currentCommand = 2
          dockerProgramID(index) = ProgramID
        Else
          dockerCommand$ = "/c " + cmdWithUTF8Command + " " + commandString$
          dockerProgramID(index) = RunProgram("cmd.exe", dockerCommand$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Hide)
          monitorConfiguration(index)\currentCommand = 0
        EndIf
        
      Case #CONTAINER
        container$ = monitorConfiguration(index)\content
        ProgramID = RunProgram(dockerExecutable$, "inspect -f {{.State.Running}} " + container$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Hide)
        
        If ProgramID = 0 Or Not IsProgram(ProgramID) Or Not ProgramRunning(ProgramID)
          ProcedureReturn
        EndIf
        
        Repeat
          dataRead = #False
          Repeat
            line.s = ReadProgramError(ProgramID)
            If Trim(line) <> ""
              MessageRequester("Error", line)
              ProcedureReturn
            EndIf
          Until line = ""
          
          programOutput = AvailableProgramOutput(ProgramID)
          If programOutput > 0
            line = ReadProgramString(ProgramID)
            If FindString(line, "false") > 0
              MessageRequester("Error", "Container '" + container$ + "' is not running.")
              ProcedureReturn
            ElseIf FindString(line, "true") > 0
              Break
            EndIf
            If line <> ""
              dataRead = #True
            EndIf
          EndIf
          Delay(1)
        Until dataRead = #False And #False
        
        dockerCommand$ = "/c " + cmdWithUTF8Command + " " + Chr(34) + dockerExecutable$ + Chr(34) + " logs --follow --tail 1000 " + container$
        dockerProgramID(index) = RunProgram("cmd.exe", dockerCommand$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Hide)
        monitorConfiguration(index)\currentCommand = 0
    EndSelect
    
    If dockerProgramID(index) = 0 Or Not IsProgram(dockerProgramID(index))
      StopDockerFollow(index)
      MessageRequester("Error", "Failed to start monitoring process")
      ProcedureReturn
    EndIf
    
    containerStarted(index) = #True
    ClearList(containerOutput(index)\lines())
    
    If monitorConfiguration(index)\type = #COMMAND
      commandString.s = monitorConfiguration(index)\commandTransformed
      commandCount = CountString(commandString, Chr(10)) + 1
      command$ = Trim(StringField(commandString, 1, Chr(10)))
      If command$ <> ""
        AddElement(containerOutput(index)\lines())
        currentDir.s = GetCurrentDirectory()
        currentDir = Left(currentDir, Len(currentDir)-1)
        containerOutput(index)\lines() = currentDir + "> " + command$
      EndIf
    EndIf
    
    containerOutput(index)\currentLine = 0
  EndProcedure
  
  Procedure UpdateMonitorIcon(index, matchColor)
    containerStatusColor(index) = matchColor
    CreateMonitorIcon(index, matchColor, bgColor(index))
    info$ = tooltip(index)
    If Len(info$) > 25
      info$ = Left(info$, 25) + "..."
    EndIf
    output$ = lastMatch(index)
    If Len(output$) > 25
      output$ = Left(output$, 25 + MaxI(0, (25-Len(info$)))) + "..."
    EndIf
    If output$ <> ""
      output$ = output$ + Chr(10) + info$ + " - " + FormatDate("%hh:%ii", Date())
    Else
      output$ = info$
    EndIf
    SysTrayIconToolTip(trayID(index), output$)
    
    ForEach logWindows()
      If logWindows()\containerIndex = index
        SetWindowTitle(logWindows()\winID, containerName(index) + " - " + lastMatch(index))
        Break
      EndIf
    Next
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetOverlayIcon(WindowID(0), index) : CompilerEndIf
  EndProcedure
  
  Procedure OnMatch(index, patternIndex, line.s, hideNotification = #False)
    lastMatch(index) = line
    lastMatchTime(index) = ElapsedMilliseconds()
    lastMatchPattern(index) = patternIndex
    UpdateMonitorIcon(index, patternColor(index, lastMatchPattern(index)))
    If Not hideNotification And patternsNotification(index, patternIndex) = #True
      ShowSystrayNotification(index, line)
    EndIf
  EndProcedure
  
  Procedure.s RemoveFirstLineFromText(Text.s)
    Protected LineBreakPos.i
    Protected NewText.s
    LineBreakPos = FindString(Text, Chr(10), 1)
    If LineBreakPos > 0
      NewText = Mid(Text, LineBreakPos + 1)
    Else
      NewText = ""
    EndIf
    ProcedureReturn NewText
  EndProcedure
  
  #ST_DEFAULT = 0
  #ST_SELECTION = 1
  #ECO_READONLY = $800
  #CFM_COLOR = $40000000
  #CFE_AUTOCOLOR = $40000000
  
  Procedure AddOutputLines(index, editorGadgetID, lines.s)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hEditor = GadgetID(editorGadgetID)
      If Not hEditor
        ProcedureReturn
      EndIf
      Protected wasAtScrollBottom = IsAtScrollBottom(editorGadgetID)
      SendMessage_(hEditor, #WM_SETREDRAW, #False, 0)
      
      Protected options.l = SendMessage_(hEditor, #EM_GETOPTIONS, 0, 0)
      Protected isReadOnly = Bool(options & #ECO_READONLY)
      
      If isReadOnly
        SendMessage_(hEditor, #EM_SETREADONLY, #False, 0)
      EndIf
      
      Protected scrollPos.POINT
      If Not wasAtScrollBottom
        SendMessage_(hEditor, #EM_GETSCROLLPOS, 0, @scrollPos)
      EndIf
      
      Protected newLinesToAdd.l = CountString(lines, Chr(10))
      Protected i.l
      newlines.s = ""
      
      For i = 1 To newLinesToAdd + 2
        line.s = Trim(StringField(lines, i, Chr(10)))
        If line = "" Or IsWaitingForInput(line) Or Asc(Mid(line, 1, 1)) = 0
          newLinesToAdd = newLinesToAdd - 1
        Else
          newlines = newlines + line + Chr(10)
        EndIf
      Next
      
      Protected lineCount.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
      Protected lineCountBeforeDeletion.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
      
      If lineCount + newLinesToAdd > #MAX_LINES
        Protected linesToDelete.l = (lineCount + newLinesToAdd) - #MAX_LINES
        Protected startSel.l, endSel.l
        For i = 1 To linesToDelete
          Protected startPos.l = SendMessage_(hEditor, #EM_LINEINDEX, 0, 0)
          Protected firstLineLen.l = SendMessage_(hEditor, #EM_LINELENGTH, startPos, 0)
          Protected endPos.l = startPos + firstLineLen + 2
          SendMessage_(hEditor, #EM_SETSEL, startPos, endPos)
          SendMessage_(hEditor, #EM_GETSEL, @startSel, @endSel)
          SendMessage_(hEditor, #EM_REPLACESEL, #True, @"")
        Next
      EndIf
      
      Protected lineCountAfterDeletion.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
      Protected linesDeleted.l = lineCountBeforeDeletion - lineCountAfterDeletion
      Protected oldLineCount.l = lineCountAfterDeletion
      
      Protected textLen.l = SendMessage_(hEditor, #WM_GETTEXTLENGTH, 0, 0)
      SendMessage_(hEditor, #EM_SETSEL, textLen, textLen)
      SendMessage_(hEditor, #EM_GETSEL, @startSel, @endSel)
      
      Protected cf.CHARFORMAT2
      cf\cbSize = SizeOf(CHARFORMAT2)
      cf\dwMask = #CFM_COLOR
      cf\dwEffects = 0
      If IsDarkModeActiveCached
        cf\crTextColor = RGB(255, 255, 255)
      Else
        cf\crTextColor = RGB(0, 0, 0)
      EndIf
      SendMessage_(hEditor, #EM_SETCHARFORMAT, #SCF_SELECTION, @cf)
      
      Result = SendMessage_(hEditor, #EM_REPLACESEL, #True, @newLines)
      
      Protected newLineCount.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
      Protected newLinesCount.l = newLineCount - oldLineCount
      If lines = "" And newLinesCount = 1
        newLinesCount = 0
      EndIf
      
      If isReadOnly
        SendMessage_(hEditor, #EM_SETREADONLY, #True, 0)
      EndIf
      
      SetEditorTextColor(index, newLinesCount + 1)
      
      Protected firstCharIndex.l = SendMessage_(hEditor, #EM_LINEINDEX, 0, 0)
      Protected pt.POINT
      SendMessage_(hEditor, #EM_POSFROMCHAR, @pt, firstCharIndex)
      Protected firstLineY.l = pt\y
      Protected secondCharIndex.l = SendMessage_(hEditor, #EM_LINEINDEX, 1, 0)
      SendMessage_(hEditor, #EM_POSFROMCHAR, @pt, secondCharIndex)
      Protected secondLineY.l = pt\y
      Protected lineHeight.l = secondLineY - firstLineY
      
      If wasAtScrollBottom
        ScrollEditorToBottom(editorGadgetID)
      Else
        scrollPos\y = scrollPos\y - (lineHeight * linesDeleted)
        If scrollPos\y < 0
          scrollPos\y = 0
        EndIf
        SendMessage_(hEditor, #EM_SETSCROLLPOS, 0, @scrollPos)
      EndIf
      
      SendMessage_(hEditor, #WM_SETREDRAW, #True, 0)
      UpdateWindow_(hEditor)
    CompilerElse
      text.s = GetGadgetText(editorGadgetID)
      ListSize = ListSize(containerOutput(index)\lines())
      If ListSize >= #MAX_LINES
        text = RemoveFirstLineFromText(text.s)
      EndIf
      wasAtScrollBottom = IsAtScrollBottom(editorGadgetID)
      SetGadgetText(editorGadgetID, text + Chr(10) + lines)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetEditorTextColor(index, #True) : CompilerEndIf
      If wasAtScrollBottom
        ScrollEditorToBottom(editorGadgetID)
      EndIf
    CompilerEndIf
  EndProcedure
  
  Procedure HandleInputLine(index, line$, addLine = #True, waitingForInput = #False)
    If addLine
      LastElement(containerOutput(index)\lines())
      If waitingForInput
        lastLine$ = containerOutput(index)\lines()
        AddElement(containerOutput(index)\lines())
        containerOutput(index)\lines() = lastLine$ + " " + line$
      Else
        AddElement(containerOutput(index)\lines())
        containerOutput(index)\lines() = line$
      EndIf
      ListSize = ListSize(containerOutput(index)\lines())
      If ListSize > #MAX_LINES
        FirstElement(containerOutput(index)\lines())
        DeleteElement(containerOutput(index)\lines())
        LastElement(containerOutput(index)\lines())
      EndIf
    EndIf
    
    If Not waitingForInput
      For p = 0 To patternCount(index)-1
        If FindString(line$, patterns(index, p), 1) > 0
          OnMatch(index, p, line$, 1-addLine)
        Else
          If CreateRegularExpression(0, patterns(index, p))
            If MatchRegularExpression(0, line$)
              OnMatch(index, p, line$, 1-addLine)
            EndIf
          EndIf
        EndIf
      Next
    EndIf
  EndProcedure
  
  Procedure HandleInputDisplay(index)
    If ListSize(containerOutput(index)\lines()) = 0
      ProcedureReturn
    EndIf
    
    text$ = ""
    If containerOutput(index)\currentline = 0
      FirstElement(containerOutput(index)\lines())
      currentElement = @containerOutput(index)\lines()
    Else
      ChangeCurrentElement(containerOutput(index)\lines(), containerOutput(index)\currentline)
      currentElement = NextElement(containerOutput(index)\lines())
    EndIf
    
    lastOutputElement = 0
    While currentElement <> 0
      text$ = text$ + Chr(10) + containerOutput(index)\lines()
      lastOutputElement = currentElement
      currentElement = NextElement(containerOutput(index)\lines())
    Wend
    
    If lastOutputElement <> 0
      containerOutput(index)\currentline = lastOutputElement
    EndIf
    
    If text$ <> ""
      ForEach logWindows()
        If logWindows()\containerIndex = index
          AddOutputLines(logWindows()\containerIndex, logWindows()\editorGadgetID, text$)
        EndIf
      Next
    EndIf
  EndProcedure
  
  Procedure CheckDockerOutput(index)
    Protected line.s
    Protected ProgramID.i = dockerProgramID(index)
    Protected dataRead.l
    
    If ProgramID = 0 Or Not IsProgram(ProgramID) Or Not ProgramRunning(ProgramID)
      If containerStarted(index)
        StopDockerFollow(index)
      EndIf
      ProcedureReturn
    EndIf
    
    Repeat
      dataRead = #False
      
      Repeat
        line = ReadProgramError(ProgramID)
        If FindString(line, "Error response from daemon: No such container:", #PB_String_NoCase) > 0
          StopDockerFollow(index)
          MessageRequester("Error", line)
          ProcedureReturn
        EndIf
        If line <> ""
          HandleInputLine(index, line)
          dataRead = #True
        EndIf
      Until line = ""
      
      programOutput = AvailableProgramOutput(ProgramID)
      If programOutput > 0
        output.s = ReadProgramOutputBytes(ProgramID, programOutput)
        If output <> ""
          lineCount = CountString(output, Chr(10)) + 1
          For i = 1 To lineCount
            line.s = Trim(ReplaceString(StringField(output, i, Chr(10)), Chr(13), ""))
            If line <> ""
              waitingForInput = IsWaitingForInput(containerOutput(index)\lines())
              HandleInputLine(index, line, #True, waitingForInput)
              monitorConfiguration(index)\waitingForInput = waitingForInput
              dataRead = #True
            EndIf
          Next
        EndIf
      EndIf
      
      If Not IsProgram(ProgramID) Or Not ProgramRunning(ProgramID)
        If containerStarted(index)
          StopDockerFollow(index)
        EndIf
        ProcedureReturn
      EndIf
    Until dataRead = #False
    
    If monitorConfiguration(index)\currentCommand > 0
      If ElapsedMilliseconds() - containerStartedTime(index) > 5000
        LastElement(containerOutput(index)\lines())
        waitingForInput = IsWaitingForInput(containerOutput(index)\lines())
        If waitingForInput
          commandCount = CountString(monitorConfiguration(index)\commandTransformed, Chr(10)) + 1
          command$ = Trim(StringField(monitorConfiguration(index)\commandTransformed, monitorConfiguration(index)\currentCommand, Chr(10)))
          WriteProgramStringN(ProgramID, command$)
          monitorConfiguration(index)\currentCommand = monitorConfiguration(index)\currentCommand + 1
          If monitorConfiguration(index)\currentCommand > commandCount
            monitorConfiguration(index)\currentCommand = 0
          EndIf
          monitorConfiguration(index)\waitingForInput = #False
        EndIf
      EndIf
    EndIf
    
    If ElapsedMilliseconds() - lastTimeOuputAdded > 50
      lastTimeOuputAdded = ElapsedMilliseconds()
      HandleInputDisplay(index)
    EndIf
  EndProcedure
  
  Procedure IsSomeRunning()
    For i = 0 To containerCount-1
      If containerStarted(i)
        ProcedureReturn #True
      EndIf
    Next
    ProcedureReturn #False
  EndProcedure
  
  Procedure ResizeLogWindow()
    ForEach logWindows()
      If logWindows()\winID = EventWindow()
        CurrentW = WindowWidth(EventWindow())
        CurrentH = WindowHeight(EventWindow())
        If CurrentW >= 0 And CurrentH >= 0
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            ResizeGadget(logWindows()\editorGadgetID, -2, -2, CurrentW + 4, CurrentH + 4)
          CompilerElse
            ResizeGadget(logWindows()\editorGadgetID, 0, 0, CurrentW, CurrentH)
          CompilerEndIf
          containterMetaData(logWindows()\containerIndex)\logWindowW = CurrentW
          containterMetaData(logWindows()\containerIndex)\logWindowH = CurrentH
        EndIf
        Break
      EndIf
    Next
  EndProcedure
  
  Procedure MoveLogWindow()
    ForEach logWindows()
      If logWindows()\winID = EventWindow()
        CurrentX = WindowX(EventWindow())
        CurrentY = WindowY(EventWindow())
        If CurrentX >= 0 And CurrentY >= 0
          containterMetaData(logWindows()\containerIndex)\logWindowX = CurrentX
          containterMetaData(logWindows()\containerIndex)\logWindowY = CurrentY
        EndIf
        Break
      EndIf
    Next
  EndProcedure
  
  Procedure CloseLogWindow()
    CloseWindow(EventWindow())
    ForEach logWindows()
      If logWindows()\winID = EventWindow()
        DeleteElement(logWindows())
        Break
      EndIf
    Next
  EndProcedure
  
  Procedure ShowLogs(index)
    ForEach logWindows()
      If logWindows()\containerIndex = index
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetOverlayIcon(WindowID(logWindows()\winID), logWindows()\containerIndex) : CompilerEndIf
        If GetWindowState(logWindows()\winId) = #PB_Window_Minimize Or GetWindowState(logWindows()\winId) = #PB_Window_Maximize
          SetWindowState(logWindows()\winId, #PB_Window_Normal)
        Else
          SetWindowState(logWindows()\winId, #PB_Window_Minimize)
        EndIf
        ProcedureReturn
      EndIf
    Next
    
    Protected winID, gadgetID
    Protected text$ = ""
    
    If index < 0 Or index > #MAX_CONTAINERS-1
      ProcedureReturn
    EndIf
    
    ForEach containerOutput(index)\lines()
      If Trim(containerOutput(index)\lines()) <> "" And Not IsWaitingForInput(containerOutput(index)\lines())
        text$ = text$ + containerOutput(index)\lines() + Chr(10)
      EndIf
    Next
    
    If containterMetaData(index)\logWindowW = 0 And containterMetaData(index)\logWindowH = 0
      containterMetaData(index)\logWindowW = 600
      containterMetaData(index)\logWindowH = 400
    EndIf
    
    If containterMetaData(index)\logWindowX = 0 And containterMetaData(index)\logWindowY = 0
      WindowFlags = #PB_Window_SystemMenu | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered
    Else
      WindowFlags = #PB_Window_SystemMenu | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget
    EndIf
    
    winID = OpenWindow(#PB_Any, containterMetaData(index)\logWindowX, containterMetaData(index)\logWindowY, containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, containerName(index), WindowFlags | #PB_Window_SizeGadget | #PB_Window_Invisible)
    If winID
      SetWindowColor(winID, RGB(0, 0, 0))
      StickyWindow(winID, #True)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        editorID = EditorGadget(#PB_Any, -2, -2, containterMetaData(index)\logWindowW + 4, containterMetaData(index)\logWindowH + 4, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      CompilerElse
        editorID = EditorGadget(#PB_Any, 0, 0, containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      CompilerEndIf
      containerLogEditorID(index) = editorID
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        LoadLibrary_("Msftedit.dll")
        SendMessage_(GadgetID(editorID), #EM_SETTEXTMODE, #TM_RICHTEXT, 0)
        SetFixedLineHeight(GadgetID(editorID), #EDITOR_LINE_HEIGHT)
      CompilerEndIf
      
      CompilerSelect #PB_Compiler_OS
        CompilerCase #PB_OS_Windows
          fontName$ = "Consolas"
        CompilerCase #PB_OS_Linux
          fontName$ = "Monospace"
        CompilerCase #PB_OS_MacOS
          fontName$ = "Monaco"
      CompilerEndSelect
      
      If LoadFont(0, fontName$, 10, #PB_Font_HighQuality)
        SetGadgetFont(editorID, FontID(0))
      EndIf
      
      AddElement(logWindows())
      logWindows()\winID = winID
      logWindows()\editorGadgetID = editorID
      logWindows()\containerIndex = index
      BindEvent(#PB_Event_SizeWindow, @ResizeLogWindow(), winID)
      BindEvent(#PB_Event_CloseWindow, @CloseLogWindow(), winID)
      BindEvent(#PB_Event_MoveWindow, @MoveLogWindow(), winID)
      
      SetGadgetText(editorID, text$)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetEditorTextColor(index) : CompilerEndIf
      
      ScrollEditorToBottom(editorID)
      ApplyTheme(winID)
      Repeat : Delay(1) : Until WindowEvent() = 0
      ShowWindowFadeIn(winID)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows : CreateWindowIcon(winID, index) : CompilerEndIf
      UpdateMonitorIcon(index, patternColor(index, lastMatchPattern(index)))
      ScrollEditorToBottom(editorID)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows: SetEditorTextColor(index): CompilerEndIf
    EndIf
  EndProcedure
  
  
  Procedure UpdateButtonStates()
    selIndex = GetGadgetState(*MainWindowGadgets\ContainerList)
    If selIndex >= 0
      DisableGadget(*MainWindowGadgets\BtnRemove, #False)
      DisableGadget(*MainWindowGadgets\BtnEdit, #False)
      DisableGadget(*MainWindowGadgets\BtnRules, #False)
      If containerStarted(selIndex)
        DisableGadget(*MainWindowGadgets\BtnStart, #True)
        DisableGadget(*MainWindowGadgets\BtnStop, #False)
      Else
        DisableGadget(*MainWindowGadgets\BtnStart, #False)
        DisableGadget(*MainWindowGadgets\BtnStop, #True)
      EndIf
    Else
      DisableGadget(*MainWindowGadgets\BtnRemove, #True)
      DisableGadget(*MainWindowGadgets\BtnEdit, #True)
      DisableGadget(*MainWindowGadgets\BtnRules, #True)
      DisableGadget(*MainWindowGadgets\BtnStart, #True)
      DisableGadget(*MainWindowGadgets\BtnStop, #True)
    EndIf
  EndProcedure
  
  Procedure UpdateMonitorList()
    ClearGadgetItems(*MainWindowGadgets\ContainerList)
    For i = 0 To containerCount-1
      AddGadgetItem(*MainWindowGadgets\ContainerList, -1, "  "+containerName(i))
      SetListItemStarted(i, containerStarted(i))
    Next
    UpdateButtonStates()
  EndProcedure
  
  
  Procedure WindowCallback(hwnd, msg, wParam, lParam)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected bg.l, fg.l
      
      
      bg = themeBackgroundColor 
      fg = themeForegroundColor 
      Protected parentBrush.i
      Select msg
        Case #WM_SETTINGCHANGE
          
          
          If lParam
            Protected *themeName = lParam
            Protected themeName.s = PeekS(*themeName)
            If themeName = "ImmersiveColorSet"
              ;SendMessage_(hwnd, #WM_SETREDRAW, #False, 0)
              IsDarkModeActive()
              ForEach ThemeHandler()
                ThemeHandler()\handleChange(ThemeHandler()\p)
              Next 
              bg = themeBackgroundColor 
              fg = themeForegroundColor
              If themeBgBrush
                DeleteObject_(themeBgBrush)
              EndIf
              themeBgBrush = CreateSolidBrush_(bg)
              ApplyThemeHandle(hwnd)
              
              ;SendMessage_(hwnd, #WM_SETREDRAW, #True, 0)
              ;InvalidateRect_(hwnd, #Null, #True)
              ;UpdateWindow_(hwnd)
              
              RedrawWindow_(hwnd, #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW)
              
              
            EndIf
          EndIf
          
          
        Case #WM_CTLCOLORBTN
          SetTextColor_(wParam, fg)
          SetBkMode_(wParam, #TRANSPARENT)
          
          Protected hBrush = GetProp_(GetParent_(lParam), "BackgroundBrush")
          If hBrush
            SetTextColor_(wParam, fg)
            SetBkMode_(wParam, #TRANSPARENT)
            SetBkColor_(wParam, buttonContainerColor) 
            ProcedureReturn hBrush
          Else
            parentBrush = GetClassLongPtr_(hwnd, #GCL_HBRBACKGROUND)
            If parentBrush
              ProcedureReturn parentBrush
            Else
              ProcedureReturn GetStockObject_(#NULL_BRUSH)
            EndIf
          EndIf
          
          
          
        Case #WM_CTLCOLORSTATIC
          SetTextColor_(wParam, fg)
          SetBkMode_(wParam, #TRANSPARENT)
          parentBrush = GetClassLongPtr_(hwnd, #GCL_HBRBACKGROUND)
          If parentBrush
            ProcedureReturn parentBrush
          Else
            ProcedureReturn GetStockObject_(#NULL_BRUSH)
          EndIf
      EndSelect
      ProcedureReturn #PB_ProcessPureBasicEvents
    CompilerEndIf
    
  EndProcedure
  
  
  Procedure CleanupApp() 
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      ForEach logWindows()
        If containterMetaData(logWindows()\containerIndex)\overlayIconHandle
          DestroyIcon_(containterMetaData(logWindows()\containerIndex)\overlayIconHandle)
        EndIf
      Next
      For i = 0 To containerCount-1
        If infoImageId(i)
          DestroyIcon_(infoImageId(i))
        EndIf
      Next
    CompilerEndIf
    
  EndProcedure
  
EndModule

; =============================================================================
;- VERTICAL TABBAR MODULE
; =============================================================================

DeclareModule VerticalTabBar
  UseModule App
  
  
  Structure TabConfig
    Name.s
    IconImage.i
    *ClickCallback
  EndStructure
  
  #PB_Event_RedrawHamburger = #PB_Event_FirstCustomValue
  
  Declare.i Create(window.i, x.i, y.i, sidebarWidth.i, expandedWidth.i, contentWidth.i, height.i, List tabConfigs.TabConfig(),User_DPI_Scale.f=1 , *resizeProc = 0, openSidebar = #False )
  
  
  Structure VerticalTabBarData
    Window.i 
    ContentContainer.i
    SidebarContainer.i
    InnerSidebarContainer.i
    InnerContentContainer.i
    ContentX.i
    ContentY.i
    ContentWidth.i
    ContentHeight.i
    SidebarWidth.i
    SidebarExpandedWidth.i
    IsExpanded.i
    ActiveTabIndex.i
    TabCount.i
    HamburgerGadget.i
    Array TabGadgets.i(0)
    Array TabConfigs.TabConfig(0)
    *ResizeCallback
    HoveredTabIndex.i
    HamburgerHovered.i
    AnimationThread.i
    AnimationLineWidth.f
    CurrentAnimationLineWidth.f
    AnimationRunning.i
    ParentsRoundingDeltaX.f 
  EndStructure
  
  
  Declare DoResize(*tabBar.VerticalTabBarData,externalResize = #False )
  Declare Toggle(*tabBar.VerticalTabBarData)
  Declare Resize(*tabBar.VerticalTabBarData,contentWidth.i, contentHeight.i,externalResize = #False )
  Declare SetActiveTab(*tabBar.VerticalTabBarData, tabIndex.i)
  Declare HandleTabBarEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
  Declare GetWidth(*tabBar.VerticalTabBarData)
  Declare GetContentContainer(*tabBar.VerticalTabBarData)
  Declare RedrawAllTabs(*tabBar.VerticalTabBarData)
  
  
EndDeclareModule

Module VerticalTabBar
  UseModule App
  
  ; VS Code color scheme
  Global COLOR_EDITOR_BG = RGB(0, 0, 0)
  Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)
  
  Global PatternColor = RGB(255, 0, 0)
  
  Global DPI_Scale.f = 1
  
  Global menuFontSize.f = 10
  Global menuFont
  
  Global colorAccent
  Global colorHover
  Global colorSideBar
  Global inactiveForegroundColor 
  
  Procedure SetColors()
    If IsDarkModeActiveCached
      colorHover = RGB(70, 70, 70)
      colorSideBar = RGB(51, 51, 51)
      colorAccent = RGB(0, 122, 204)
      inactiveForegroundColor = RGB(220,220,220)
    Else
      colorHover = RGB(230, 230, 230)
      colorSideBar = RGB(240, 240, 240)
      colorAccent = RGB(0, 122, 204)
      inactiveForegroundColor = RGB(55,55,55) 
    EndIf 
  EndProcedure
  
  Procedure DrawHamburgerButton(*tabBar.VerticalTabBarData)
    
    If StartDrawing(CanvasOutput(*tabBar\HamburgerGadget))
      canvasW = OutputWidth()
      canvasH = OutputHeight()
      
      SetColors()
      
      ; Background with hover effect
      If *tabBar\HamburgerHovered
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, colorHover)
      Else
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, colorSideBar)
      EndIf
      
      ; Hamburger icon with animated line width
      lineColor = RGB(180, 180, 180)
      centerX = canvasH / 2
      centerY = canvasH / 2
      lineWidth.f = *tabBar\CurrentAnimationLineWidth
      lineHeight = 1 * DPI_Scale
      spacing = 4 * DPI_Scale
      
      Box(centerX - lineWidth/2, centerY - spacing - lineHeight/2, lineWidth, lineHeight, lineColor)
      Box(centerX - lineWidth/2, centerY - lineHeight/2, lineWidth, lineHeight, lineColor)
      Box(centerX - lineWidth/2, centerY + spacing - lineHeight/2, lineWidth, lineHeight, lineColor)
      
      StopDrawing()
    EndIf
  EndProcedure
  
  Procedure DrawTabButton(*tabBar.VerticalTabBarData, tabIndex.i, active.i)
    gadget = *tabBar\TabGadgets(tabIndex)
    If StartDrawing(CanvasOutput(gadget))
      canvasW = OutputWidth()
      canvasH = OutputHeight()
      
      
      SetColors()
      ; Background
      If active 
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, themeBackgroundColor)
        Box(0, 0, 4 * DPI_Scale, canvasH, colorAccent)
      ElseIf tabIndex = *tabBar\HoveredTabIndex
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, colorHover)
      Else
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, colorSideBar)
      EndIf
      
      ; Draw icon
      If *tabBar\TabConfigs(tabIndex)\IconImage
        DrawingMode(#PB_2DDrawing_AlphaBlend)
        DrawImage(ImageID(*tabBar\TabConfigs(tabIndex)\IconImage), (canvasH - ImageWidth(*tabBar\TabConfigs(tabIndex)\IconImage)) / 2, (canvasH - ImageHeight(*tabBar\TabConfigs(tabIndex)\IconImage)) / 2)
      Else
        If active
          Circle(canvasH/2, canvasH/2, 8 * DPI_Scale, RGB(0, 122, 204))
        Else
          Circle(canvasH/2, canvasH/2, 8 * DPI_Scale, RGB(120, 120, 120))
        EndIf
      EndIf
      
      ; Draw text if expanded
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(menuFont))
      Protected yPos.f
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected hDC = GetDC_(GadgetID(gadget))
        Protected tm.TEXTMETRIC
        If hDC And SelectObject_(hDC, FontID(menuFont)) And GetTextMetrics_(hDC, @tm)
          If DPI_Scale = 1
            yPos = canvasH/2 - tm\tmAscent/2 -1
          ElseIf DPI_Scale <= 1.25
            yPos = canvasH/2 - tm\tmAscent/2 - 2
          Else
            yPos = canvasH/2 - tm\tmAscent/2 - 2*DPI_Scale
          EndIf 
        Else
          ; Fallback if GetTextMetrics_ fails
          yPos = canvasH/2 - (menuFontSize * DPI_Scale)/2 - 4 * DPI_Scale
        EndIf
        If hDC
          ReleaseDC_(GadgetID(gadget), hDC)
        EndIf
      CompilerElse
        ; Non-Windows fallback
        yPos = canvasH/2 - (menuFontSize * DPI_Scale)/2 - 4 * DPI_Scale
      CompilerEndIf
      If active
        DrawText(canvasH + 2 * DPI_Scale, yPos, *tabBar\TabConfigs(tabIndex)\Name, themeForegroundColor)
      Else
        DrawText(canvasH + 2 * DPI_Scale, yPos, *tabBar\TabConfigs(tabIndex)\Name, inactiveForegroundColor)
      EndIf
      
      StopDrawing()
    EndIf
  EndProcedure
  
  
  
  Procedure AnimationThread(*tabBar.VerticalTabBarData)
    Protected frames = 12 ; 8 frames for each phase (shrink and expand)
    Protected frameDelay = 8 ; 20ms per frame, total 320ms (8*20ms shrink + 8*20ms expand)
    Protected i
    Protected startWidth.f = *tabBar\AnimationLineWidth
    Protected endWidth.f = 10.0 * DPI_Scale
    
    ; Shrink phase
    For i = 0 To frames - 1
      *tabBar\CurrentAnimationLineWidth = startWidth + (endWidth - startWidth) * i / frames
      PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadget)
      Delay(frameDelay)
    Next
    
    ; Expand phase
    For i = 0 To frames - 1
      *tabBar\CurrentAnimationLineWidth = endWidth + (startWidth - endWidth) * i / frames
      PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadget)
      Delay(frameDelay)
    Next
    
    ; Reset animation state
    *tabBar\CurrentAnimationLineWidth = startWidth
    *tabBar\AnimationRunning = #False
    PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadget)
  EndProcedure
  
  Procedure RedrawAllTabs(*tabBar.VerticalTabBarData)
    Protected isActive.i, i.i
    SetColors()
    SetGadgetColor(*tabBar\InnerSidebarContainer , #PB_Gadget_BackColor, colorSideBar)
    SetGadgetColor(*tabBar\InnerContentContainer, #PB_Gadget_BackColor, themeBackgroundColor)
    
    DrawHamburgerButton(*tabBar)
    
    For i = 0 To *tabBar\TabCount - 1
      If i = *tabBar\ActiveTabIndex
        isActive = #True
      Else
        isActive = #False
      EndIf
      DrawTabButton(*tabBar, i, isActive)
    Next
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows: RedrawWindow_(GadgetID(*tabBar\InnerSidebarContainer), #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW):CompilerEndIf
    
  EndProcedure
  
  Procedure.i Create(window.i, x.i, y.i, sidebarWidth.i, expandedWidth.i, contentWidth.i, height.i, List tabConfigs.TabConfig(),User_DPI_Scale.f=1 , *resizeProc = 0, openSidebar = #False )
    Protected *tabBar.VerticalTabBarData = AllocateMemory(SizeOf(VerticalTabBarData))
    Protected i.i, tabCount.i
    
    SetColors()
    
    DPI_Scale = User_DPI_Scale
    
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        fontName$ = "Consolas"
      CompilerCase #PB_OS_Linux
        fontName$ = "Monospace"
      CompilerCase #PB_OS_MacOS
        fontName$ = "Monaco"
    CompilerEndSelect
    menuFont =  LoadFont(#PB_Any , "Segoe UI", menuFontSize,#PB_Font_HighQuality)
    *tabBar\Window = window
    *tabBar\SidebarWidth = Round(sidebarWidth ,#PB_Round_Down)
    *tabBar\SidebarExpandedWidth = Round(expandedWidth ,#PB_Round_Down)
    *tabBar\IsExpanded = openSidebar
    *tabBar\ActiveTabIndex = 0
    *tabBar\ContentX = x + *tabBar\SidebarWidth
    *tabBar\ContentY = y
    *tabBar\ContentWidth = Round(contentWidth ,#PB_Round_Down)
    *tabBar\ContentHeight = Round(height ,#PB_Round_Down)
    *tabBar\HoveredTabIndex = -1
    *tabBar\HamburgerHovered = #False
    *tabBar\AnimationLineWidth = Round(13.0*DPI_Scale ,#PB_Round_Down) ; Initial line width
    *tabBar\CurrentAnimationLineWidth = *tabBar\AnimationLineWidth
    *tabBar\AnimationRunning = #False
    *tabBar\window = window
    
    Debug "*tabBar\IsExpanded"
    Debug *tabBar\IsExpanded
    If *tabBar\IsExpanded
      currentSidebarWidth = *tabBar\SidebarExpandedWidth
      currentContentX =  *tabBar\ContentX + sidebarDifference
      currentContentWidth = *tabBar\ContentWidth - sidebarDifference
    Else
      currentSidebarWidth = *tabBar\SidebarWidth
      currentContentX =  *tabBar\ContentX 
      currentContentWidth = *tabBar\ContentWidth 
    EndIf
    
    
    
    ; Count tabs
    tabCount = ListSize(tabConfigs()) 
    *tabBar\TabCount = tabCount
    
    ; Copy tab configs
    Dim *tabBar\TabConfigs(tabCount - 1)
    FirstElement(tabConfigs())
    For i = 0 To tabCount - 1
      *tabBar\TabConfigs(i)\Name = tabConfigs()\Name
      *tabBar\TabConfigs(i)\IconImage = tabConfigs()\IconImage
      *tabBar\TabConfigs(i)\ClickCallback = tabConfigs()\ClickCallback
      NextElement(tabConfigs())
    Next
    
    ; Create sidebar container
    
    *tabBar\SidebarContainer = ContainerGadget(#PB_Any, x, y, currentSidebarWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    *tabBar\InnerSidebarContainer  = ContainerGadget(#PB_Any, 0, 0, *tabBar\SidebarExpandedWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(*tabBar\InnerSidebarContainer , #PB_Gadget_BackColor, colorSideBar)
    
    ; Create hamburger button (square, width = height = sidebarWidth)
    *tabBar\HamburgerGadget = CanvasGadget(#PB_Any, 0, 5 , *tabBar\SidebarWidth, *tabBar\SidebarWidth)
    GadgetToolTip(*tabBar\HamburgerGadget, "Toggle Menu")
    
    ; Create tab buttons
    Dim *tabBar\TabGadgets(tabCount - 1)
    
    For i = 0 To tabCount - 1
      *tabBar\TabGadgets(i) = CanvasGadget(#PB_Any, 0, 10  + *tabBar\SidebarWidth * (i + 1), expandedWidth , *tabBar\SidebarWidth)
      If Not *tabBar\IsExpanded
        GadgetToolTip(*tabBar\TabGadgets(i),  *tabBar\TabConfigs(i)\Name )
      EndIf
    Next
    CloseGadgetList()
    CloseGadgetList()
    Debug "currentSidebarWidth"
    Debug currentSidebarWidth
    ; Create content container
    *tabBar\ContentContainer = ContainerGadget(#PB_Any, x + currentSidebarWidth, y, currentContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    *tabBar\InnerContentContainer = ContainerGadget(#PB_Any, 0, 0, currentContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(*tabBar\InnerContentContainer, #PB_Gadget_BackColor, themeBackgroundColor)
    
    CloseGadgetList()
    CloseGadgetList()
    
    *tabBar\ResizeCallback = *resizeProc
    
    ; Draw initial state
    RedrawAllTabs(*tabBar)
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      ; In VerticalTabBar::Create, add WS_CLIPCHILDREN to containers
      Protected hSidebar = GadgetID(*tabBar\SidebarContainer)
      SetWindowLongPtr_(hSidebar, #GWL_STYLE, GetWindowLongPtr_(hSidebar, #GWL_STYLE) | #WS_CLIPCHILDREN)
      
      Protected hContent = GadgetID(*tabBar\ContentContainer)
      SetWindowLongPtr_(hContent, #GWL_STYLE, GetWindowLongPtr_(hContent, #GWL_STYLE) | #WS_CLIPCHILDREN)
      
      Protected hInnerSidebar = GadgetID(*tabBar\InnerSidebarContainer)
      SetWindowLongPtr_(hInnerSidebar, #GWL_STYLE, GetWindowLongPtr_(hInnerSidebar, #GWL_STYLE) | #WS_CLIPCHILDREN)
      
      Protected hInnerContent = GadgetID(*tabBar\InnerContentContainer)
      SetWindowLongPtr_(hInnerContent, #GWL_STYLE, GetWindowLongPtr_(hInnerContent, #GWL_STYLE) | #WS_CLIPCHILDREN)
      
      ;     
      ; hwnd = GadgetID(*tabBar\SidebarContainer)
      ; SetWindowLongPtr_(hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(hwnd, #GWL_EXSTYLE) | #WS_EX_COMPOSITED)  
      ; SetWindowPos_(hwnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      ; hwnd = GadgetID(*tabBar\InnerContentContainer)
      ; SetWindowLongPtr_(hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(hwnd, #GWL_EXSTYLE) | #WS_EX_COMPOSITED)  
      ; SetWindowPos_(hwnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      ; 
      ;  hwnd = GadgetID(*tabBar\ContentContainer)
      ; SetWindowLongPtr_(hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(hwnd, #GWL_EXSTYLE) | #WS_EX_COMPOSITED)
      ; SetWindowPos_(hwnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      ;  hwnd = GadgetID(*tabBar\InnerContentContainer)
      ; SetWindowLongPtr_(hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(hwnd, #GWL_EXSTYLE) | #WS_EX_COMPOSITED)
      ; SetWindowPos_(hwnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      
      
    CompilerEndIf
    ProcedureReturn *tabBar
  EndProcedure
  
  Procedure SmoothResizeGadget(Gadget, x.f, y.f, width.f, height.f)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hWnd = GadgetID(Gadget)
      ; Pause redrawing
      SendMessage_(hWnd, #WM_SETREDRAW, 0, 0)
      ; Resize
      NormalResizeGadget(Gadget, Round(x,#PB_Round_Down),Round(y,#PB_Round_Down),Round(width,#PB_Round_Down),Round(height,#PB_Round_Down))
      ; Resume redrawing and force repaint
      SendMessage_(hWnd, #WM_SETREDRAW, 1, 0)
      RedrawWindow_(hWnd, 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    CompilerElse
      NormalResizeGadget(Gadget, Round(x,#PB_Round_Down),Round(y,#PB_Round_Down),Round(width,#PB_Round_Down),Round(height,#PB_Round_Down))
    CompilerEndIf
  EndProcedure
  
  Structure TabBarDimensions 
    newWidth.l
    newContentX.l
    newContentWidth.l
  EndStructure 
  
  
  Procedure Refresh(*tabBar.VerticalTabBarData)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows: 
      RedrawWindow_(GadgetID(*tabBar\SidebarContainer), 0, 0,#RDW_ERASE | #RDW_INVALIDATE  | #RDW_UPDATENOW)
      RedrawWindow_(GadgetID(*tabBar\ContentContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE  | #RDW_UPDATENOW)
      RedrawWindow_(GadgetID(*tabBar\InnerSidebarContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      RedrawWindow_(GadgetID(*tabBar\InnerContentContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      InvalidateRect_(GadgetID(*tabBar\ContentContainer), #Null, #False)
      InvalidateRect_(GadgetID(*tabBar\InnerContentContainer), #Null, #False)
      UpdateWindow_(GadgetID(*tabBar\ContentContainer))
      UpdateWindow_(GadgetID(*tabBar\InnerContentContainer))
    CompilerEndIf 
  EndProcedure
  
  
  
  
  Procedure DoResize(*tabBar.VerticalTabBarData,externalResize = #False)
    sidebarDifference.f = *tabBar\SidebarExpandedWidth - *tabBar\SidebarWidth
    parentsRoundingDeltaX.f
    If *tabBar\IsExpanded
      newWidth = *tabBar\SidebarExpandedWidth
      newContentX =  *tabBar\ContentX + sidebarDifference
      newContentWidth = *tabBar\ContentWidth - sidebarDifference
      parentsRoundingDeltaX = *tabBar\SidebarExpandedWidth* DPI_Scale -Round(*tabBar\SidebarExpandedWidth *DPI_Scale,#PB_Round_Nearest)
      
    Else
      newWidth = *tabBar\SidebarWidth
      newContentX =  *tabBar\ContentX 
      newContentWidth = *tabBar\ContentWidth 
      parentsRoundingDeltaX = *tabBar\SidebarWidth* DPI_Scale -Round(*tabBar\SidebarWidth* DPI_Scale,#PB_Round_Nearest)
    EndIf
    
    *tabBar\ParentsRoundingDeltaX = parentsRoundingDeltaX
    ; Update tooltips based on expansion state
    For i = 0 To *tabBar\TabCount - 1
      If *tabBar\IsExpanded
        GadgetToolTip(*tabBar\TabGadgets(i), "")
      Else
        GadgetToolTip(*tabBar\TabGadgets(i), *tabBar\TabConfigs(i)\Name)
      EndIf
      
    Next
    
    
    ; ---- call user supplied handler ----
    If *tabBar\ResizeCallback
      CallFunctionFast(*tabBar\ResizeCallback, *tabBar, *tabBar\ActiveTabIndex, newContentWidth, *tabBar\IsExpanded,@sidebarDifference,@parentsRoundingDeltaX )
    EndIf
    
    
    ; ---- existing resize logic ----
    
    NormalResizeGadget(*tabBar\SidebarContainer, #PB_Ignore, #PB_Ignore, newWidth, *tabBar\ContentHeight,0,0)
    
    NormalResizeGadget(*tabBar\ContentContainer, newContentX, #PB_Ignore, newContentWidth, *tabBar\ContentHeight,0,0)
    
    NormalResizeGadget(*tabBar\InnerContentContainer, #PB_Ignore, #PB_Ignore, newContentWidth, *tabBar\ContentHeight,0,0)
    
    If Not externalResize
      Refresh(*tabBar.VerticalTabBarData)
    EndIf 
    tabBarDimensions.TabBarDimensions
    tabBarDimensions\newWidth = newWidth
    tabBarDimensions\newContentX = newContentX
    tabBarDimensions\newContentWidth = newContentWidth
    
    ProcedureReturn newContentWidth
  EndProcedure
  
  
  
  Procedure Toggle(*tabBar.VerticalTabBarData)
    Protected newWidth.i, i.i, newContentX.f, newContentWidth.f
    
    ; Start animation BEFORE toggling (Win11 style)
    If Not *tabBar\AnimationRunning
      *tabBar\AnimationRunning = #True
      *tabBar\AnimationThread = CreateThread(@AnimationThread(), *tabBar)
    EndIf
    
    *tabBar\IsExpanded = 1 - *tabBar\IsExpanded
    DoResize(*tabBar)
    
    RedrawAllTabs(*tabBar)
    
    
  EndProcedure
  
  
  Procedure Resize(*tabBar.VerticalTabBarData,contentWidth.i, contentHeight.i,externalResize = #False )
    
    *tabBar\ContentWidth = contentWidth
    *tabBar\ContentHeight = contentHeight
    
    newContentWidth = DoResize(*tabBar,externalResize)
    NormalResizeGadget(*tabBar\InnerSidebarContainer, #PB_Ignore,#PB_Ignore, #PB_Ignore, *tabBar\ContentHeight,0,0)
    
    ;NormalResizeGadget(*tabBar\InnerContentContainer, #PB_Ignore, #PB_Ignore, newContentWidth, *tabBar\ContentHeight0,0,hDefer)
    ;NormalResizeGadget(*tabBar\ContentContainer, #PB_Ignore, #PB_Ignore, newContentWidth, *tabBar\ContentHeight0,0,hDefer)
    
    
  EndProcedure
  
  
  
  
  Procedure SetActiveTab(*tabBar.VerticalTabBarData, tabIndex.i)
    If tabIndex >= 0 And tabIndex < *tabBar\TabCount
      DrawTabButton(*tabBar, *tabBar\ActiveTabIndex, #False)
      *tabBar\ActiveTabIndex = tabIndex
      DrawTabButton(*tabBar, *tabBar\ActiveTabIndex, #True)
    EndIf
    DoResize(*tabBar)
  EndProcedure
  
  Procedure HandleTabBarEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
    
    Protected i.i
    Protected callbackProc
    Protected isActive.i
    
    ; Handle custom redraw event
    If event = #PB_Event_RedrawHamburger And eventGadget = *tabBar\HamburgerGadget
      DrawHamburgerButton(*tabBar)
      ProcedureReturn #True
    EndIf
    
    ; Check hamburger button
    If eventGadget = *tabBar\HamburgerGadget
      If EventType() = #PB_EventType_LeftClick Or EventType() = #PB_EventType_LeftDoubleClick
        Toggle(*tabBar)
      ElseIf EventType() = #PB_EventType_MouseEnter
        *tabBar\HamburgerHovered = #True
        DrawHamburgerButton(*tabBar)
      ElseIf EventType() = #PB_EventType_MouseLeave
        *tabBar\HamburgerHovered = #False
        DrawHamburgerButton(*tabBar)
      EndIf
      ProcedureReturn #True
    EndIf
    
    ; Check tab buttons
    For i = 0 To *tabBar\TabCount - 1
      If eventGadget = *tabBar\TabGadgets(i)
        If EventType() = #PB_EventType_LeftClick
          SetActiveTab(*tabBar, i)
          
          ; Call the callback if defined
          If *tabBar\TabConfigs(i)\ClickCallback
            callbackProc = *tabBar\TabConfigs(i)\ClickCallback
            CallFunctionFast(callbackProc, i)
          EndIf
        ElseIf EventType() = #PB_EventType_MouseEnter
          *tabBar\HoveredTabIndex = i
          If i = *tabBar\ActiveTabIndex
            isActive = #True
          Else
            isActive = #False
          EndIf
          DrawTabButton(*tabBar, i, isActive)
        ElseIf EventType() = #PB_EventType_MouseLeave
          *tabBar\HoveredTabIndex = -1
          If i = *tabBar\ActiveTabIndex
            isActive = #True
          Else
            isActive = #False
          EndIf
          DrawTabButton(*tabBar, i, isActive)
        EndIf
        ProcedureReturn #True
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  
  
  Procedure GetWidth(*tabBar.VerticalTabBarData)
    If *tabBar\IsExpanded
      ProcedureReturn *tabBar\SidebarExpandedWidth
    Else
      ProcedureReturn *tabBar\SidebarWidth
    EndIf
  EndProcedure
  
  Procedure GetContentContainer(*tabBar.VerticalTabBarData)
    ProcedureReturn *tabBar\InnerContentContainer
  EndProcedure
EndModule


; =============================================================================
;- MODERN LIST  MODULE
; =============================================================================

DeclareModule ModernListElement
  Enumeration ElementTypes
    #Element_Text
    #Element_Image
    #Element_Gadget
  EndEnumeration
  Prototype.i ProtoCreateGadget(parentGadget.i, x.i, y.i, width.i, height.i)
  Prototype.i ProtoHandleGadgetEvent(*list, index.i ,eventGadget.i, event.i ,childIndex.i, whichGadget = 0)
  Prototype ProtoDestroyGadget(gadget.i)
  Structure GadgetInterface
    *Create.ProtoCreateGadget
    *HandleEvent.ProtoHandleGadgetEvent
    *Destroy.ProtoDestroyGadget
  EndStructure
  Declare CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface.GadgetInterface=0)
  Declare Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
  Declare HandleEvent(currentElementMap.s,foundRowGadget, foundCellGadget, foundChildGadget,childIndex,  eventGadget.i, event.i, *list, index)
  Structure ChildGadgets
    List Gadgets.i()
  EndStructure
  Structure ModernListElementData
    RowGadget.i
    Gadget.i
    *ChildGadgets.ChildGadgets  ; The actual gadget inside the container (button, combo, etc.)
    Type.i
    Content.s
    X.i
    Y.i
    Width.i
    Height.i
    *EventProc.ProtoHandleGadgetEvent
    *DestroyProc.ProtoDestroyGadget
    *List
  EndStructure
  
  Global NewMap ElementMap.ModernListElementData()
  
  
  
EndDeclareModule

Module ModernListElement
  
  
  
  
  Procedure CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface.GadgetInterface=0)
    Protected g.i = 0
    Protected containerGadget.i = 0
    Protected gadgetToStore.i = 0
    Protected *childGadgets.ChildGadgets = 0
    
    If type = #Element_Gadget And *interface
      containerGadget = ContainerGadget(#PB_Any, x, y, width, height)
      *childGadgets = *interface\Create(containerGadget, 0, 0, width, height)
      CloseGadgetList()
      gadgetToStore = containerGadget
    Else
      gadgetToStore = g
    EndIf
    
    Protected key$ = Str(rowGadget) + "_" + Str(elementIndex)
    AddMapElement(ElementMap(), key$)
    ElementMap()\RowGadget = rowGadget
    ElementMap()\Gadget = gadgetToStore
    ElementMap()\ChildGadgets = *childGadgets  ; Store the child gadget reference
    ElementMap()\Type = type
    ElementMap()\Content = content
    ElementMap()\X = x
    ElementMap()\Y = y
    ElementMap()\Width = width
    ElementMap()\Height = height
    If *interface
      ElementMap()\EventProc = *interface\HandleEvent
      ElementMap()\DestroyProc = *interface\Destroy
    EndIf
    
    ProcedureReturn ElementMap()\Gadget
  EndProcedure
  
  Procedure Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
    Protected key$ = Str(rowGadget) + "_" + Str(elementIndex)
    If FindMapElement(ElementMap(), key$)
      If ElementMap()\Type = #Element_Gadget And ElementMap()\Gadget
        If ElementMap()\DestroyProc
          ElementMap()\DestroyProc(ElementMap()\Gadget)
        Else
          FreeGadget(ElementMap()\Gadget)
        EndIf
      EndIf
      DeleteMapElement(ElementMap())
    EndIf
  EndProcedure
  
  Procedure HandleEvent(currentElementMap.s,foundRowGadget, foundCellGadget, foundChildGadget, childIndex, eventGadget.i, event.i, *list, index)
    
    Protected handled = #False
    If eventGadget <> 0 And foundRowGadget Or  foundCellGadget Or foundChildGadget
      If FindMapElement(ElementMap(),currentElementMap)
        If ElementMap()\Type = #Element_Gadget And ElementMap()\EventProc
          Protected actualGadget.i = 0
          ; The event came from the child gadget (button, combo, etc.)
          If foundChildGadget
            actualGadget = eventGadget
            handled = ElementMap()\EventProc(*list, index,actualGadget, event,childIndex, 0 )
            ; The event came from the container
          ElseIf IsGadget(ElementMap()\Gadget)
            actualGadget = GetGadgetData(ElementMap()\Gadget)
            If actualGadget = 0
              actualGadget = eventGadget
            EndIf
            If foundCellGadget 
              handled = ElementMap()\EventProc(*list, index ,actualGadget, event,-1, 1 )
            Else ; RowGadget
              handled = ElementMap()\EventProc(*list, index ,actualGadget, event,-1, 2 )
            EndIf 
          EndIf
        EndIf
        If Not handled
          Select event
            Case #PB_EventType_LeftClick   
              If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or foundGadget)
                Debug "Clicked gadget container: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              ElseIf ElementMap()\RowGadget = eventGadget
                Protected mx.i = GetGadgetAttribute(eventGadget, #PB_Canvas_MouseX)
                Protected my.i = GetGadgetAttribute(eventGadget, #PB_Canvas_MouseY)
                If mx >= ElementMap()\X And mx < ElementMap()\X + ElementMap()\Width And
                   my >= ElementMap()\Y And my < ElementMap()\Y + ElementMap()\Height
                  Debug "Clicked " + Str(ElementMap()\Type) + ": " + ElementMap()\Content + " at (" + Str(mx) + "," + Str(my) + ")"
                  handled = #True
                EndIf
              EndIf
              
            Case #PB_EventType_Change
              If ElementMap()\Type = #Element_Gadget
                Debug "Gadget changed: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              EndIf
              
            Case #PB_EventType_Focus
              If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or foundGadget)
                Debug "Gadget focused: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              ElseIf ElementMap()\RowGadget = eventGadget
                Debug "Row canvas focused for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                handled = #True
              EndIf
              
            Case #PB_EventType_LostFocus
              If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or foundGadget)
                Debug "Gadget lost focus: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              ElseIf ElementMap()\RowGadget = eventGadget
                Debug "Row canvas lost focus for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                handled = #True
              EndIf
          EndSelect
        EndIf
      EndIf
    EndIf
    ProcedureReturn handled
  EndProcedure
EndModule

DeclareModule ModernList
  UseModule App
  UseModule ModernListElement
  
  Structure ListElement
    Type.i
    Content.s
    Width.i
    Alignment.i
    ForeColor.i
    BackColor.i
    HoveredForeColor.i
    SelectedForeColor.i
    SelectedHoveredForeColor.i
    HoveredBackColor.i
    SelectedBackColor.i
    SelectedHoveredBackColor.i
    TintColor.i
    HoveredTintColor.i
    SelectedTintColor.i
    SelectedHoveredTintColor.i
    Gadget.i
    *Interface.GadgetInterface
  EndStructure
  
  Structure ListRow
    List Elements.ListElement()
    Height.i
    UserData.i
  EndStructure
  
  Structure ListHeader
    List Columns.ListElement()
    Height.i
  EndStructure
  
  #PB_Event_RedrawRow = #PB_Event_FirstCustomValue + 1
  
  Structure ModernListData
    Window.i
    MainContainer.i
    HeaderContainer.i
    ScrollArea.i
    InnerContainer.i
    HeaderHeight.i
    RowHeight.i
    List Rows.ListRow()
    Header.ListHeader
    ActiveRowIndex.i
    HoveredRowIndex.i
    Width.i
    Height.i
    InnerWidth.i
    InnerHeight.i
    *ResizeCallback
    AnimationRunning.i
    DPI_Scale.f
    Array rowGadgets.i(0)
  EndStructure
  
  Global rowFont
  Global headerFont
  
  Declare SetColors()
  Declare Refresh(*list.ModernListData)
  Declare DrawHeader(*list.ModernListData)
  Declare DrawRow(*list.ModernListData, rowIndex.i, gadget.i, active.i, hovered.i)
  Declare RedrawAll(*list.ModernListData)
  Declare CreateList(window.i, x.i, y.i, width.i, height.i, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=30, User_DPI_Scale.f=1, *resizeProc=0)
  Declare AddRow(*list.ModernListData, List elements.ListElement(), height.i=0, userData.i=0)
  Declare SetRow(*list.ModernListData, rowIndex.i, List elements.ListElement(), height.i=0, userData.i=0)
  Declare ClearRows(*list.ModernListData)
  Declare DoResize(*list.ModernListData, externalResize=#False)
  Declare Resize(*list.ModernListData, width.i, height.i, externalResize=#False)
  Declare UpdateHoverState(*list.ModernListData)
  Declare HandleListEvent(*list.ModernListData, eventGadget.i, event.i)
  Declare GetSelectedRow(*list.ModernListData)
  Declare GetInnerContainer(*list.ModernListData)
EndDeclareModule

Module ModernList
  UseModule App
  UseModule ModernListElement
  
  Global COLOR_EDITOR_BG = RGB(0, 0, 0)
  Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)
  Global PatternColor = RGB(255, 0, 0)
  Global Local_DPI_Scale.f = 1
  Global menuFontSize.f = 7
  Global menuFont
  Global colorAccent
  Global colorHover
  Global colorSideBar
  Global inactiveForegroundColor
  Global rowFont
  Global headerFont
  
  
  
  ; =============================================================================
  ; IsBelowMousePointer – Plattformübergreifend
  ; =============================================================================
  
  
  
  Procedure.i IsBelowMousePointer(hwnd.i)
    If hwnd = 0
      ProcedureReturn #False
    EndIf
    
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        Protected pt.POINT
        GetCursorPos_(@pt)
        Protected hUnder.i = WindowFromPoint_(pt\y << 32 | pt\x)
        If hUnder = 0
          ProcedureReturn #False
        EndIf
        If GetAncestor_(hUnder, #GA_ROOT) = GetAncestor_(hwnd, #GA_ROOT)
          ProcedureReturn #True
        EndIf
        ProcedureReturn #False
        
      CompilerCase #PB_OS_MacOS
        ProcedureReturn #True
        
      CompilerCase #PB_OS_Linux
        ImportC "-lX11"
          XOpenDisplay(*name)
          XDefaultRootWindow(display)
          XQueryPointer(display, root, *root_return, *child_return, *root_x, *root_y, *win_x, *win_y, *mask)
          XQueryTree(display, w, *root_return, *parent_return, **children, *nchildren)
          XFree(p)
          XCloseDisplay(display)
          EndImportC
          
          Protected display = XOpenDisplay(0)
          If display = 0
            ProcedureReturn #False
          EndIf
          
          Protected root = XDefaultRootWindow(display)
          Protected root_ret, child_ret, root_x, root_y, win_x, win_y, mask
          If XQueryPointer(display, root, @root_ret, @child_ret, @root_x, @root_y, @win_x, @win_y, @mask) = 0
            XCloseDisplay(display)
            ProcedureReturn #False
          EndIf
          
          Protected target_win = child_ret
          If target_win = 0
            target_win = root_ret
          EndIf
          
          Protected current = target_win
          Protected found = #False
          
          While current <> 0 And current <> root
            If current = hwnd
              found = #True
              Break
            EndIf
            Protected parent, *children, nchildren
            If XQueryTree(display, current, @root, @parent, @*children, @nchildren) <> 0 And parent <> 0
              If *children
                XFree(*children)
              EndIf
              current = parent
            Else
              Break
            EndIf
          Wend
          
          XCloseDisplay(display)
          ProcedureReturn found
      CompilerEndSelect
      
      ProcedureReturn #False
    EndProcedure
    
    
    Procedure SetColors()
      If IsDarkModeActiveCached
        colorHover = RGB(70, 70, 70)
        colorSideBar = RGB(51, 51, 51)
        colorAccent = RGB(0, 122, 204)
        inactiveForegroundColor = RGB(220,220,220)
      Else
        colorHover = RGB(230, 230, 230)
        colorSideBar = RGB(240, 240, 240)
        colorAccent = RGB(0, 122, 204)
        inactiveForegroundColor = RGB(55,55,55)
      EndIf
    EndProcedure
    
    Procedure Refresh(*list.ModernListData)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        
        Protected hMain = GadgetID(*list\MainContainer)
        Protected hInner = GadgetID(*list\InnerContainer)
        RedrawWindow_(hMain, 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_UPDATENOW)
        RedrawWindow_(hInner, 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
        InvalidateRect_(hMain, #Null, #False)
        UpdateWindow_(hMain)
      CompilerEndIf
    EndProcedure
    
    Procedure DrawHeader(*list.ModernListData)
      If *list\HeaderContainer
        If StartDrawing(CanvasOutput(*list\HeaderContainer))
          Protected xPos.i, colWidth.i, yPos.i, text$, foreColor.i, imgID.i
          SetColors()
          Box(0, 0, OutputWidth(), OutputHeight(), colorSideBar)
          
          xPos = 0
          DrawingMode(#PB_2DDrawing_Transparent)
          DrawingFont(FontID(headerFont))
          
          ForEach *list\Header\Columns()
            colWidth = *list\Header\Columns()\Width
            Select *list\Header\Columns()\Type
              Case #Element_Text
                text$ = *list\Header\Columns()\Content
                foreColor = *list\Header\Columns()\ForeColor
                If foreColor = 0
                  foreColor = inactiveForegroundColor
                EndIf
                yPos = (OutputHeight() - TextHeight(text$)) / 2
                DrawText(xPos + 5 * Local_DPI_Scale, yPos, text$, foreColor)
              Case #Element_Image
                If Val(*list\Header\Columns()\Content) > 0
                  imgID = Val(*list\Header\Columns()\Content)
                  DrawImage(ImageID(imgID), xPos + (colWidth - ImageWidth(imgID)) / 2, (OutputHeight() - ImageHeight(imgID)) / 2)
                EndIf
            EndSelect
            xPos + colWidth
          Next
          
          StopDrawing()
        EndIf
      EndIf
    EndProcedure
    
    Procedure DrawRow(*list.ModernListData, rowIndex.i, gadget.i, active.i, hovered.i)
      
      If gadget And IsGadget(gadget)
        If StartDrawing(CanvasOutput(gadget))
          Protected canvasW.i = OutputWidth()
          Protected canvasH.i = OutputHeight()
          Protected xPos.i, elemWidth.i, backColor.i, foreColor.i, text$, textW.i, textH.i, yPos.i, xAlign.i, imgID.i, imgW.i, imgH.i, yAlign.i, tintColor.i
          
          Protected isSelected.i = active
          Protected isHovered.i = hovered
          
          SetColors()
          If isSelected
            Box(0, 0, canvasW, canvasH, colorAccent)
          ElseIf isHovered
            Box(0, 0, canvasW, canvasH, colorHover)
          Else
            If IsDarkModeActiveCached
              Box(0, 0, canvasW, canvasH, darkThemeBackgroundColor)
            Else
              Box(0, 0, canvasW, canvasH, lightThemeBackgroundColor)
            EndIf
          EndIf
          
          SelectElement(*list\Rows(), rowIndex)
          xPos = 0
          DrawingMode(#PB_2DDrawing_Transparent)
          DrawingFont(FontID(rowFont))
          
          ForEach *list\Rows()\Elements()
            elemWidth = *list\Rows()\Elements()\Width
            
            backColor = *list\Rows()\Elements()\BackColor
            If isSelected And isHovered
              If *list\Rows()\Elements()\SelectedHoveredBackColor <> 0
                backColor = *list\Rows()\Elements()\SelectedHoveredBackColor
              EndIf
            ElseIf isSelected
              If *list\Rows()\Elements()\SelectedBackColor <> 0
                backColor = *list\Rows()\Elements()\SelectedBackColor
              EndIf
            ElseIf isHovered
              If *list\Rows()\Elements()\HoveredBackColor <> 0
                backColor = *list\Rows()\Elements()\HoveredBackColor
              EndIf
            EndIf
            If backColor <> 0
              Box(xPos, 0, elemWidth, canvasH, backColor)
            EndIf
            
            Select *list\Rows()\Elements()\Type
              Case #Element_Text
                text$ = *list\Rows()\Elements()\Content
                
                foreColor = *list\Rows()\Elements()\ForeColor
                If isSelected And isHovered
                  If *list\Rows()\Elements()\SelectedHoveredForeColor <> 0
                    foreColor = *list\Rows()\Elements()\SelectedHoveredForeColor
                  Else
                    foreColor = RGB(255, 255, 255)
                  EndIf
                ElseIf isSelected
                  If *list\Rows()\Elements()\SelectedForeColor <> 0
                    foreColor = *list\Rows()\Elements()\SelectedForeColor
                  Else
                    foreColor = RGB(255, 255, 255)
                  EndIf
                ElseIf isHovered
                  If *list\Rows()\Elements()\HoveredForeColor <> 0
                    foreColor = *list\Rows()\Elements()\HoveredForeColor
                  EndIf
                EndIf
                If foreColor = 0
                  If IsDarkModeActiveCached
                    foreColor = darkThemeForegroundColor
                  Else
                    foreColor = lightThemeForegroundColor
                  EndIf
                EndIf
                
                textW = TextWidth(text$)
                textH = TextHeight(text$)
                yPos = (canvasH - textH) / 2
                Select *list\Rows()\Elements()\Alignment
                  Case 1
                    xAlign = (elemWidth - textW) / 2
                  Case 2
                    xAlign = elemWidth - textW - 5 * Local_DPI_Scale
                  Default
                    xAlign = 5 * Local_DPI_Scale
                EndSelect
                DrawText(xPos + xAlign, yPos, text$, foreColor)
                
              Case #Element_Image
                If Val(*list\Rows()\Elements()\Content) > 0
                  imgID = Val(*list\Rows()\Elements()\Content)
                  imgW = ImageWidth(imgID)
                  imgH = ImageHeight(imgID)
                  DrawingMode(#PB_2DDrawing_AlphaBlend)
                  Select *list\Rows()\Elements()\Alignment
                    Case 1
                      xAlign = (elemWidth - imgW) / 2
                    Case 2
                      xAlign = elemWidth - imgW - 5 * Local_DPI_Scale
                    Default
                      xAlign = 5 * Local_DPI_Scale
                  EndSelect
                  yAlign = (canvasH - imgH) / 2
                  DrawImage(ImageID(imgID), xPos + xAlign, yAlign)
                  
                  tintColor = *list\Rows()\Elements()\TintColor
                  If isSelected And isHovered
                    If *list\Rows()\Elements()\SelectedHoveredTintColor <> 0
                      tintColor = *list\Rows()\Elements()\SelectedHoveredTintColor
                    EndIf
                  ElseIf isSelected
                    If *list\Rows()\Elements()\SelectedTintColor <> 0
                      tintColor = *list\Rows()\Elements()\SelectedTintColor
                    EndIf
                  ElseIf isHovered
                    If *list\Rows()\Elements()\HoveredTintColor <> 0
                      tintColor = *list\Rows()\Elements()\HoveredTintColor
                    EndIf
                  EndIf
                  If tintColor <> 0
                    DrawingMode(#PB_2DDrawing_AlphaBlend)
                    Box(xPos, 0, elemWidth, canvasH, tintColor)
                  EndIf
                EndIf
            EndSelect
            
            xPos + elemWidth
          Next
          
          StopDrawing()
        EndIf
      EndIf
    EndProcedure
    
    Procedure RedrawAll(*list.ModernListData)
      SetColors()
      DrawHeader(*list)
      
      Protected yPos.i = 0
      Protected rowIndex.i = 0
      ForEach *list\Rows()
        Protected rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        If rowIndex =< ArraySize(*list\rowGadgets())
          Protected rowGadget.i = *list\rowGadgets(rowIndex)
          If rowGadget And IsGadget(rowGadget)
            Protected isActive.i = #False
            Protected isHovered.i = #False
            If rowIndex = *list\ActiveRowIndex
              isActive = #True
            EndIf
            If rowIndex = *list\HoveredRowIndex
              isHovered = #True
            EndIf
            DrawRow(*list, rowIndex, rowGadget, isActive, isHovered)
          EndIf
        EndIf
        yPos + rowH
        rowIndex + 1
      Next
      
      Refresh(*list)
    EndProcedure
    
    Procedure CreateList(window.i, x.i, y.i, width.i, height.i, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=30, User_DPI_Scale.f=1, *resizeProc=0)
      
      If IsDarkModeActiveCached
        bg = darkThemeBackgroundColor
      Else
        bg = lightThemeBackgroundColor
      EndIf
      
      Protected *list.ModernListData = AllocateMemory(SizeOf(ModernListData))
      Protected rowCount.i, yPos.i, rowIndex.i, elemW.i, xElem.i, rowGadget.i
      
      SetColors()
      Local_DPI_Scale = User_DPI_Scale
      
      Protected fontName$
      CompilerSelect #PB_Compiler_OS
        CompilerCase #PB_OS_Windows
          fontName$ = "Segoe UI"
        CompilerCase #PB_OS_Linux
          fontName$ = "Sans"
        CompilerCase #PB_OS_MacOS
          fontName$ = "Helvetica"
      CompilerEndSelect
      rowFont = LoadFont(#PB_Any, fontName$, 10 , #PB_Font_HighQuality)
      headerFont = LoadFont(#PB_Any, fontName$, 10 , #PB_Font_HighQuality)
      
      *list\Window = window
      *list\Width = width 
      *list\Height = height
      *list\RowHeight = defaultRowHeight
      
      *list\ActiveRowIndex = -1
      *list\HoveredRowIndex = -1
      *list\DPI_Scale = Local_DPI_Scale
      *list\ResizeCallback = *resizeProc
      
      NewList *list\Rows.ListRow()
      rowCount = ListSize(rows())
      CopyList(rows(), *list\Rows())
      
      If *header
        CopyStructure(*header, @*list\Header, ListHeader)
        *list\HeaderHeight = *header\Height
        If *list\HeaderHeight = 0 : *list\HeaderHeight = *list\RowHeight : EndIf
      Else
        *list\HeaderHeight = 0
      EndIf
      
      *list\MainContainer = ContainerGadget(#PB_Any, x, y, *list\Width, *list\Height, #PB_Container_BorderLess)
      
      
      If *list\HeaderHeight > 0
        *list\HeaderContainer = CanvasGadget(#PB_Any, 0, 0, *list\Width, *list\HeaderHeight)
      EndIf
      
      Protected scrollY.i = *list\HeaderHeight
      Protected scrollH.i = *list\Height - *list\HeaderHeight
      Protected totalRowHeight.i = 0
      ForEach *list\Rows()
        Protected rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        totalRowHeight + rowH
      Next
      *list\ScrollArea = ScrollAreaGadget(#PB_Any, 0, scrollY, *list\Width, scrollH, *list\Width, totalRowHeight, 0, #PB_ScrollArea_BorderLess)
      SetGadgetColor(*list\ScrollArea,#PB_Gadget_BackColor,bg)
      
      
      *list\InnerContainer = ContainerGadget(#PB_Any, 0, 0, *list\Width, totalRowHeight, #PB_Container_BorderLess)
      
      
      
      If IsDarkModeActiveCached
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      Else
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      EndIf
      
      yPos = 0
      rowIndex = 0
      Dim *list\rowGadgets(rowCount - 1)
      ForEach *list\Rows()
        rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        rowGadget = CanvasGadget(#PB_Any, 0, yPos, *list\Width, rowH, #PB_Canvas_Container | #PB_Canvas_Keyboard)
        xElem = 0
        Protected elementIndex.i = 0
        ForEach *list\Rows()\Elements()
          elemW = *list\Rows()\Elements()\Width
          Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
          *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, rowH, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface)
          xElem + elemW
          elementIndex + 1
        Next
        
        CloseGadgetList()
        
        *list\rowGadgets(rowIndex) = rowGadget
        SetGadgetData(rowGadget, rowIndex)
        
        yPos + rowH
        rowIndex + 1
      Next
      
      CloseGadgetList()
      CloseGadgetList()
      CloseGadgetList()
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        
        Protected hMain.i = GadgetID(*list\MainContainer)
        SetWindowLongPtr_(hMain, #GWL_STYLE, GetWindowLongPtr_(hMain, #GWL_STYLE) | #WS_CLIPCHILDREN)
        
        Protected hScroll.i = GadgetID(*list\ScrollArea)
        SetWindowLongPtr_(hScroll, #GWL_STYLE, GetWindowLongPtr_(hScroll, #GWL_STYLE) | #WS_CLIPCHILDREN)
        
        Protected hInner.i = GadgetID(*list\InnerContainer)
        SetWindowLongPtr_(hInner, #GWL_STYLE, GetWindowLongPtr_(hInner, #GWL_STYLE) | #WS_CLIPCHILDREN)
      CompilerEndIf
      RedrawAll(*list)
      
      ProcedureReturn *list
    EndProcedure
    
    Procedure AddRow(*list.ModernListData, List elements.ListElement(), height.i=0, userData.i=0)
      LastElement(*list\Rows())
      AddElement(*list\Rows())
      CopyList(elements(), *list\Rows()\Elements())
      *list\Rows()\Height = height
      *list\Rows()\UserData = userData
      
      Protected yPos.i = 0
      Protected totalRowHeight.i = 0
      ForEach *list\Rows()
        Protected rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        totalRowHeight + rowH
        yPos = totalRowHeight - rowH
      Next
      
      Protected rowIndex.i = ListSize(*list\Rows()) - 1
      ReDim *list\rowGadgets(ArraySize(*list\rowGadgets()) + 1)
      
      Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos, *list\Width, *list\Rows()\Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
      
      Protected xElem.i = 0
      Protected elementIndex.i = 0
      ForEach *list\Rows()\Elements()
        Protected elemW.i = *list\Rows()\Elements()\Width
        Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
        *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, *list\Rows()\Height, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface)
        xElem + elemW
        elementIndex + 1
      Next
      
      CloseGadgetList()
      
      *list\rowGadgets(rowIndex) = rowGadget
      SetGadgetData(rowGadget, rowIndex)
      
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, totalRowHeight)
      ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, *list\Width, totalRowHeight)
      
      RedrawAll(*list)
    EndProcedure
    
    Procedure SetRow(*list.ModernListData, rowIndex.i, List elements.ListElement(), height.i=0, userData.i=0)
      If SelectElement(*list\Rows(), rowIndex)
        Protected elementIndex.i = 0
        ForEach *list\Rows()\Elements()
          ModernListElement::Remove(*list\Rows()\Elements()\Gadget, *list\rowGadgets(rowIndex), *list\Rows()\Elements()\Type, elementIndex)
          *list\Rows()\Elements()\Gadget = 0
          elementIndex + 1
        Next
        
        ClearList(*list\Rows()\Elements())
        CopyList(elements(), *list\Rows()\Elements())
        *list\Rows()\Height = height
        *list\Rows()\UserData = userData
        
        Protected yPos.i = 0
        Protected totalRowHeight.i = 0
        ForEach *list\Rows()
          Protected rowH.i = *list\Rows()\Height
          If rowH = 0
            rowH = *list\RowHeight
          EndIf
          totalRowHeight + rowH
          If ListIndex(*list\Rows()) = rowIndex
            yPos = totalRowHeight - rowH
            Break
          EndIf
        Next
        
        If rowIndex < ArraySize(*list\rowGadgets())
          If *list\rowGadgets(rowIndex) And IsGadget(*list\rowGadgets(rowIndex))
            FreeGadget(*list\rowGadgets(rowIndex))
          EndIf
        EndIf
        
        Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos, *list\Width, *list\Rows()\Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
        
        Protected xElem.i = 0
        elementIndex = 0
        ForEach *list\Rows()\Elements()
          Protected elemW.i = *list\Rows()\Elements()\Width
          Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
          *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, *list\Rows()\Height, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface)
          xElem + elemW
          elementIndex + 1
        Next
        
        CloseGadgetList()
        
        *list\rowGadgets(rowIndex) = rowGadget
        SetGadgetData(rowGadget, rowIndex)
        
        SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, totalRowHeight)
        ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, *list\Width, totalRowHeight)
        
        RedrawAll(*list)
      EndIf
    EndProcedure
    
    Procedure ClearRows(*list.ModernListData)
      Protected rowIndex.i = 0
      ForEach *list\Rows()
        Protected elementIndex.i = 0
        ForEach *list\Rows()\Elements()
          ModernListElement::Remove(*list\Rows()\Elements()\Gadget, *list\rowGadgets(rowIndex), *list\Rows()\Elements()\Type, elementIndex)
          *list\Rows()\Elements()\Gadget = 0
          elementIndex + 1
        Next
        rowIndex + 1
      Next
      ClearList(*list\Rows())
      For i = 0 To ArraySize(*list\rowGadgets())
        If *list\rowGadgets(i) And IsGadget(*list\rowGadgets(i))
          FreeGadget(*list\rowGadgets(i))
        EndIf
      Next
      ReDim *list\rowGadgets(0)
      FreeGadget(*list\InnerContainer)
      *list\InnerContainer = ContainerGadget(#PB_Any, 0, 0, *list\Width, *list\RowHeight, #PB_Container_BorderLess)
      If IsDarkModeActiveCached
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      Else
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      EndIf
      CloseGadgetList()
      
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, *list\RowHeight)
      ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, *list\Width, *list\RowHeight)
      
      RedrawAll(*list)
    EndProcedure
    
    Procedure DoResize(*list.ModernListData, externalResize=#False)
      Protected newWidth.i = *list\Width
      Protected newHeight.i = *list\Height
      
      If *list\ResizeCallback
        CallFunctionFast(*list\ResizeCallback, *list, newWidth, newHeight)
      EndIf
      
      ResizeGadget(*list\MainContainer, #PB_Ignore, #PB_Ignore, newWidth, newHeight)
      If *list\HeaderContainer
        ResizeGadget(*list\HeaderContainer, #PB_Ignore, #PB_Ignore, newWidth, *list\HeaderHeight)
      EndIf
      ResizeGadget(*list\ScrollArea, #PB_Ignore, *list\HeaderHeight, newWidth, newHeight - *list\HeaderHeight)
      
      Protected innerH.i = 0
      ForEach *list\Rows()
        rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        innerH + rowH
      Next
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, innerH)
      ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, newWidth, innerH)
      
      Protected yPos.i = 0
      Protected rowIndex.i = 0
      ForEach *list\Rows()
        rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        If rowIndex < ArraySize(*list\rowGadgets())
          Protected rowGadget.i = *list\rowGadgets(rowIndex)
          If rowGadget And IsGadget(rowGadget)
            ResizeGadget(rowGadget, #PB_Ignore, yPos, newWidth, rowH)
          EndIf
        EndIf
        yPos + rowH
        rowIndex + 1
      Next
      
      If Not externalResize
        Refresh(*list)
      EndIf
    EndProcedure
    
    Procedure Resize(*list.ModernListData, width.i, height.i, externalResize=#False)
      *list\Width = Round(width * Local_DPI_Scale, #PB_Round_Down)
      *list\Height = Round(height * Local_DPI_Scale, #PB_Round_Down)
      DoResize(*list, externalResize)
    EndProcedure
    
    ; FIXED: Use DesktopUnscaledX/Y to get actual physical mouse position
    Procedure.i IsMouseOverGadget(gadget.i, window.i, scrollAreaGadget.i, headerHeight.i)
      If Not IsGadget(gadget)
        ProcedureReturn #False
      EndIf
      
      ; Get PHYSICAL mouse position (unscaled by DPI)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected mx.i = DesktopUnscaledX(WindowMouseX(window))
        Protected my.i = DesktopUnscaledY(WindowMouseY(window))
      CompilerElse
        mx.i = WindowMouseX(window)
        my.i = WindowMouseY(window)
      CompilerEndIf
      
      ; Get gadget's PHYSICAL position in window coordinates (unscaled)
      Protected gx.i = GadgetX(gadget, #PB_Gadget_WindowCoordinate)
      Protected gy.i = GadgetY(gadget, #PB_Gadget_WindowCoordinate)
      Protected gw.i = GadgetWidth(gadget)
      Protected gh.i = GadgetHeight(gadget)
      
      ; Check if mouse is within gadget bounds
      If mx >= gx And mx < gx + gw And my >= gy And my < gy + gh
        ProcedureReturn #True
      EndIf
      ProcedureReturn #False
    EndProcedure
    
    Procedure UpdateHoverState(*list.ModernListData)
      Protected mouseOverRow.i = -1
      Protected foundHover.i = #False
      
      ; Check all row gadgets
      For i = 0 To ArraySize(*list\rowGadgets())
        If *list\rowGadgets(i) And IsGadget(*list\rowGadgets(i))
          If IsMouseOverGadget(*list\rowGadgets(i), *list\Window, *list\ScrollArea, *list\HeaderHeight)
            If IsBelowMousePointer(GadgetID(*list\rowGadgets(i)))
              mouseOverRow = i
              foundHover = #True
              Break
            EndIf
          EndIf
        EndIf
      Next
      
      ; If not over a row, check if over an element gadget
      If Not foundHover
        ForEach ModernListElement::ElementMap()
          If ModernListElement::ElementMap()\Type = #Element_Gadget
            If IsMouseOverGadget(ModernListElement::ElementMap()\Gadget, *list\Window, *list\ScrollArea, *list\HeaderHeight)
              If IsBelowMousePointer(GadgetID(ModernListElement::ElementMap()\Gadget))
                
                For i = 0 To ArraySize(*list\rowGadgets())
                  If *list\rowGadgets(i) = ModernListElement::ElementMap()\RowGadget
                    mouseOverRow = i
                    foundHover = #True
                    Break
                  EndIf
                Next
                If foundHover
                  Break
                EndIf
              EndIf
            EndIf
          EndIf
        Next
      EndIf
      
      ; Update hover state if changed
      If mouseOverRow <> *list\HoveredRowIndex
        Protected oldHoverRow.i = *list\HoveredRowIndex
        *list\HoveredRowIndex = mouseOverRow
        
        ; Redraw old hovered row
        If oldHoverRow >= 0 And oldHoverRow <= ArraySize(*list\rowGadgets())
          If *list\rowGadgets(oldHoverRow) And IsGadget(*list\rowGadgets(oldHoverRow))
            Protected oldIsActive.i = #False
            If oldHoverRow = *list\ActiveRowIndex
              oldIsActive = #True
            EndIf
            DrawRow(*list, oldHoverRow, *list\rowGadgets(oldHoverRow), oldIsActive, #False)
          EndIf
        EndIf
        
        ; Redraw new hovered row
        If mouseOverRow >= 0 And mouseOverRow <= ArraySize(*list\rowGadgets())
          If *list\rowGadgets(mouseOverRow) And IsGadget(*list\rowGadgets(mouseOverRow))
            Protected newIsActive.i = #False
            If mouseOverRow = *list\ActiveRowIndex
              newIsActive = #True
            EndIf
            DrawRow(*list, mouseOverRow, *list\rowGadgets(mouseOverRow), newIsActive, #True)
          EndIf
        EndIf
      EndIf
    EndProcedure
    Global wheelAccum.i = 0
    
    Procedure HandleListEvent(*list.ModernListData, eventGadget.i, event.i)
      If eventGadget = *list\HeaderContainer
        If event = #PB_EventType_LeftClick
        EndIf
        ProcedureReturn #True
      EndIf
      
      Protected rowIndex.i = -1
      Protected foundRow.i = #False
      Protected foundGadget = #False 
      Protected foundRowGadget = #False
      Protected foundCellGadget= #False
      Protected foundChildGadget = #False
      Protected childIndex = -1 
      
      For i = 0 To ArraySize(*list\rowGadgets())
        If *list\rowGadgets(i) = eventGadget
          rowIndex = GetGadgetData(eventGadget)
          foundRow = #True
          foundGadget = #True 
          foundRowGadget = #True
          Break
        EndIf
      Next
      
      If Not foundRow
        ForEach ModernListElement::ElementMap()
          childIndex = -1 
          If ElementMap()\RowGadget = eventGadget 
            foundGadget = #True 
            foundRowGadget = #True            
          ElseIf  ElementMap()\Gadget = eventGadget
            foundGadget = #True 
            foundCellGadget= #True            
          ElseIf ElementMap()\ChildGadgets <> 0
            
            ForEach ElementMap()\ChildGadgets\Gadgets()
              
              If ElementMap()\ChildGadgets\Gadgets() = eventGadget
                foundGadget = #True 
                foundChildGadget = #True
                Break 
              EndIf 
              childIndex  +1 
            Next 
            If foundGadget
              childIndex  +1 
            EndIf 
          EndIf
          
          If foundGadget
            For i = 0 To ArraySize(*list\rowGadgets())
              If *list\rowGadgets(i) = ModernListElement::ElementMap()\RowGadget
                rowIndex = GetGadgetData(*list\rowGadgets(i))
                foundRow = #True
                Break
              EndIf
            Next
            Break
          EndIf
        Next
      EndIf
      Select event 
        Case #PB_EventType_MouseWheel
          Protected delta.f = GetGadgetAttribute(eventGadget, #PB_Canvas_WheelDelta)
          Protected currentY.i = GetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y)
          Protected scrollSpeed.i
          
          
          
          CompilerSelect #PB_Compiler_OS
            CompilerCase #PB_OS_Windows               
              scrollSpeed = (delta /3) * (*list\RowHeight * 3)
            CompilerCase #PB_OS_MacOS
              scrollSpeed = delta * (*list\RowHeight / 2)
            CompilerCase #PB_OS_Linux
              scrollSpeed = (delta / 120) * (*list\RowHeight * 3)
          CompilerEndSelect
          Debug scrollSpeed
          SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y, currentY - scrollSpeed)
          UpdateWindow_(GadgetID(*list\ScrollArea))
          ;RedrawWindow_(GadgetID(*list\ScrollArea), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_UPDATENOW | #RDW_ALLCHILDREN)
      EndSelect 
      If foundRow And rowIndex >= 0 And rowIndex < ListSize(*list\Rows())
        
        Select event
          Case #PB_EventType_LeftClick,#PB_EventType_LeftDoubleClick,#PB_EventType_RightClick,  #PB_EventType_Change
            *list\ActiveRowIndex = rowIndex
            *list\HoveredRowIndex = rowIndex
            RedrawAll(*list)
        EndSelect
        ProcedureReturn ModernListElement::HandleEvent(MapKey(ElementMap()),foundRowGadget, foundCellGadget, foundChildGadget,childIndex, eventGadget, event,*list,rowIndex )
      EndIf
      ProcedureReturn #False 
    EndProcedure
    
    Procedure GetSelectedRow(*list.ModernListData)
      ProcedureReturn *list\ActiveRowIndex
    EndProcedure
    
    Procedure GetInnerContainer(*list.ModernListData)
      ProcedureReturn *list\InnerContainer
    EndProcedure
  EndModule
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  ; =============================================================================
  ;- WINDOW MANAGER MODULE
  ; =============================================================================
  
  DeclareModule WindowManager
    
    Prototype.i HandleMainEvent(Event.i, Window.i, Gadget.i)
    Prototype.i ProtoOpenWindow(*Window)
    Prototype.i ProtoHandleEvent(Event.i, Window.i, Gadget.i)
    Prototype.i ProtoCloseWindow(Window.i)
    Prototype.i ProtoCleanupWindow()
    
    Structure AppWindow
      WindowID.i
      Title.s
      *CreateProc.ProtoOpenWindow
      *HandleProc.ProtoHandleEvent
      *RemoveProc.ProtoCloseWindow
      *CleanupProc.ProtoCleanupWindow
      UserData.i
      Open.b
      *Gadgets
    EndStructure
    
    Declare.i AddManagedWindow(Title.s, *Gadgets, *CreateProc, *HandleProc, *RemoveProc, *CleanupProc = 0)
    Declare OpenManagedWindow(*Window.AppWindow)
    Declare CloseManagedWindow(*Window.AppWindow)
    Declare RunEventLoop(*HandleMainEvent.HandleMainEvent)
    Declare CleanupManagedWindows()
    
  EndDeclareModule
  
  Module WindowManager
    Global NewList ManagedWindows.AppWindow()
    
    
    
    Procedure.i AddManagedWindow(Title.s, *Gadgets, *CreateProc, *HandleProc, *RemoveProc, *CleanupProc = 0)
      AddElement(ManagedWindows())
      ManagedWindows()\Title = Title
      ManagedWindows()\Gadgets = *Gadgets
      ManagedWindows()\CreateProc = *CreateProc
      ManagedWindows()\HandleProc = *HandleProc
      ManagedWindows()\RemoveProc = *RemoveProc
      ManagedWindows()\CleanupProc = *CleanupProc
      ProcedureReturn @ManagedWindows()
    EndProcedure
    
    Procedure OpenManagedWindow(*Window.AppWindow)
      If Not *Window\Open
        If *Window\CreateProc
          *Window\WindowID = CallFunctionFast(*Window\CreateProc)
          If *Window\WindowID <> -1
            *Window\Open = #True
          EndIf
          ProcedureReturn *Window\WindowID
        EndIf
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure CloseManagedWindow(*Window.AppWindow)
      If *Window\WindowID
        If *Window\RemoveProc
          CallFunctionFast(*Window\RemoveProc, *Window\WindowID)
        EndIf
        *Window\Open = #False     
      EndIf
    EndProcedure
    
    
    Procedure CleanupManagedWindows()
      ForEach ManagedWindows()
        If  ManagedWindows()\WindowID And ManagedWindows()\CleanupProc
          CallFunctionFast( ManagedWindows()\CleanupProc)
        EndIf
      Next
    EndProcedure
    
    
    
    Procedure RunEventLoop(*HandleMainEvent.HandleMainEvent)
      Protected Event.i
      Protected EventWindow.i
      Protected EventGadget.i
      Protected KeepRunning.i = #True
      Protected KeepWindow.i
      Protected OpenedWindowExists.i
      While KeepRunning
        Event = WaitWindowEvent()
        If Event <> 0
          EventWindow = EventWindow()
          EventGadget = EventGadget()
          If *HandleMainEvent( Event, EventWindow, EventGadget) = 0
            ForEach ManagedWindows()
              If ManagedWindows()\Open 
                If EventWindow = ManagedWindows()\WindowID And  ManagedWindows()\HandleProc
                  KeepWindow = CallFunctionFast(ManagedWindows()\HandleProc, Event, EventGadget)
                  If Not KeepWindow
                    DeleteElement(ManagedWindows())
                    Break
                  EndIf
                EndIf
              EndIf
            Next
          EndIf 
        EndIf 
        OpenedWindowExists = #False
        ForEach ManagedWindows()
          If ManagedWindows()\Open
            OpenedWindowExists = #True
            Break
          EndIf
        Next
        
        If Not OpenedWindowExists Or ListSize(ManagedWindows()) = 0
          KeepRunning = #False
        EndIf
      Wend
      
    EndProcedure
  EndModule
  
  
  ; ALL WINDOWS
  
  Global *AddMonitorDialog 
  
  ; =============================================================================
  ;- ADD MONITOR DIALOG MODULE
  ; =============================================================================
  
  
  DeclareModule MonitorDialog
    UseModule App
    UseModule WindowManager
    Declare.i Open()
    Declare.i CreateWindow()
  EndDeclareModule
  
  Module MonitorDialog
    UseModule App
    UseModule VerticalTabBar
    
    Structure AddMonitorGadgets
      ContainerColorPreview.i
      BtnChooseColor.i
      StartCommandEdit.i
      StopCommandEdit.i
      DirBrowser.i
      
      StatusNotifications.i
      
      TxtContainer.i
      LblBgColor.i
      
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    #WIN_ID = 1
    
    Global *Window.AppWindow
    Global *Gadgets.AddMonitorGadgets = AllocateMemory(SizeOf(AddMonitorGadgets))
    Global bgCol.l
    
    Global *tabBar.VerticalTabBarData
    
    Global Dim tabIds(7)
    
    
    ExamineDesktops()
    desktopWidth =  DesktopWidth(0)
    
    
    Global buttonContainer
    
    Global windowWidth = 700
    Global windowHeight = 450
    Global sidebarExtendedWidth = 160
    Global buttonAreaHeight = 51
    Global sidebarWidth = 40
    Global buttonHeight = 30
    
    Global buttonContainerBackground
    
    Procedure SetColors()
      If IsDarkModeActiveCached
        buttonContainerBackground = RGB(65, 65, 65)
      Else
        buttonContainerBackground = RGB(230,230,230)
      EndIf 
    EndProcedure
    
    
    Procedure ResizeWindowCallback() 
      
      Protected windowWidth = WindowWidth(#WIN_ID)
      Protected windowHeight = WindowHeight(#WIN_ID)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #False, 0)
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #False, 0)
      CompilerEndIf
      Define x = 0, y = 0, width.f = windowWidth - sidebarWidth , height.f = windowHeight - buttonAreaHeight 
      VerticalTabBar::Resize(*tabBar, windowWidth - sidebarWidth, windowHeight ,#True )
      
      NormalResizeGadget(buttonContainer, #PB_Ignore, height, width+5, #PB_Ignore,*tabBar\ParentsRoundingDeltaX)
      
      NormalResizeGadget(tabIds(*tabBar\ActiveTabIndex), #PB_Ignore,#PB_Ignore,width,height,*tabBar\ParentsRoundingDeltaX)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #True, 0)
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #True, 0)
        
        ;RedrawWindow_(GadgetID(*tabBar\SidebarContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN) ; Omit #RDW_ERASE if your paint handlers fill the background fully
        ;RedrawWindow_(GadgetID(*tabBar\ContentContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN)
        
        RedrawWindow_(WindowID(#WIN_ID), #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW)
      CompilerEndIf
      
    EndProcedure
    
    Procedure CreateMockIcon(width.i, height.i, bgColor.i, fgColor.i)
      Protected img = CreateImage(#PB_Any, width * DPI_Scale, height * DPI_Scale, 32, bgColor)
      If img
        StartDrawing(ImageOutput(img))
        DrawingMode(#PB_2DDrawing_Default)
        Box(2 * DPI_Scale, 2 * DPI_Scale, (width-4) * DPI_Scale, (height-4) * DPI_Scale, fgColor)
        StopDrawing()
      EndIf
      ProcedureReturn img
    EndProcedure
    
    
    Procedure OnTabClick(tabIndex.i)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        ; Hide all content containers
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, 0, 0)
        SendMessage_(GadgetID(tabIds(tabIndex)), #WM_SETREDRAW, 0, 0)
      CompilerEndIf   
      
      
      For i = 0 To ArraySize(tabIds())
        If i = tabIndex
          HideGadget(tabIds(i), #False)
        Else
          HideGadget(tabIds(i), #True)
        EndIf 
      Next
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(*tabBar\ContentContainer), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
        SendMessage_(GadgetID(tabIds(tabIndex)), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(tabIds(tabIndex)), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      CompilerEndIf
      
    EndProcedure
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows: Global NewList brushes.i():CompilerEndIf
    
    Procedure SetGadgetBackgoundColor(gadget, bg)
      SetGadgetColor(gadget, #PB_Gadget_BackColor, bg)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows: 
        hBrush = CreateSolidBrush_(bg)
        AddElement(brushes())
        brushes() = hBrush
        SetProp_(GadgetID(gadget), "BackgroundBrush", hBrush) 
      CompilerEndIf
    EndProcedure 
    
    
    Procedure HandleLayout(*tabBar.VerticalTabBarData, index.i, width, IsExpanded,*deltaWidth, *parentsRoundingDeltaX)
      parentsRoundingDeltaX.f = PeekF(*parentsRoundingDeltaX)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(tabIds(index)), #WM_SETREDRAW, 0, 0)
      CompilerEndIf
      
      NormalResizeGadget(tabIds(index), #PB_Ignore, #PB_Ignore, width, #PB_Ignore,parentsRoundingDeltaX)
      
      Select index 
        Case 0:        
          NormalResizeGadget(*Gadgets\BtnChooseColor, width-(150+10+20+15) , #PB_Ignore, #PB_Ignore, #PB_Ignore ,parentsRoundingDeltaX)
          NormalResizeGadget(*Gadgets\ContainerColorPreview, width-(20+15), #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
        Case 1:
          NormalResizeGadget(*Gadgets\StartCommandEdit,#PB_Ignore, #PB_Ignore,width-20, #PB_Ignore,parentsRoundingDeltaX) 
        Case 2:
          NormalResizeGadget(*Gadgets\StopCommandEdit,#PB_Ignore, #PB_Ignore,width-20, #PB_Ignore,parentsRoundingDeltaX)
        Case 3:
          NormalResizeGadget(*Gadgets\DirBrowser,#PB_Ignore, #PB_Ignore,width-20, #PB_Ignore,parentsRoundingDeltaX)
      EndSelect
      
      NormalResizeGadget(*Gadgets\BtnOk, width-(85+15+85+15), #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
      NormalResizeGadget(*Gadgets\BtnCancel, width-(85+15), #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(tabIds(index)), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(tabIds(index)), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      CompilerEndIf
      
    EndProcedure
    
    
    Procedure.i ShowWindow()
      HideWindow(#WIN_ID,#False)
      ProcedureReturn #WIN_ID
    EndProcedure 
    
    
    Procedure  ApplyMonitorTheme(*p)
      SetColors()
      SetGadgetColor(buttonContainer, #PB_Gadget_BackColor,buttonContainerBackground )
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected bgBrush = GetProp_(GadgetID(buttonContainer), "BackgroundBrush")
        If bgBrush
          DeleteObject_(bgBrush)
        EndIf 
        buttonContainerHBrush = CreateSolidBrush_(buttonContainerBackground)
        SetProp_(GadgetID(buttonContainer), "BackgroundBrush", buttonContainerHBrush) 
      CompilerEndIf
    EndProcedure
    
    
    Procedure.i CreateWindow()
      If Not IsWindow(#WIN_ID)
        ; Create main window with DPI scaling
        If OpenWindow(#WIN_ID, 0, 0, windowWidth , windowHeight , "Monitor - VS Code Style", 
                      #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget|#PB_Window_MaximizeGadget| #PB_Window_SizeGadget | #PB_Window_Invisible)
          
          
          SetColors()
          
          SetWindowColor(#WIN_ID, themeBackgroundColor)
          
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            SetWindowLongPtr_(WindowID(#WIN_ID), #GWL_STYLE, GetWindowLongPtr_(WindowID(#WIN_ID), #GWL_STYLE) | #WS_CLIPCHILDREN)
            SetWindowCallback(@WindowCallback())
          CompilerEndIf
          BindEvent(#PB_Event_SizeWindow, @ResizeWindowCallback(),#WIN_ID)
          
          iconSize = 10
          ; Create mock icons
          imgPresets = CreateMockIcon(iconSize, iconSize, RGB(100, 100, 250), RGB(50, 50, 200))
          imgCommand = CreateMockIcon(iconSize, iconSize, RGB(100, 250, 100), RGB(50, 200, 50))
          imgDirectory = CreateMockIcon(iconSize, iconSize, RGB(250, 200, 100), RGB(200, 150, 50))
          imgStatus = CreateMockIcon(iconSize, iconSize, RGB(250, 100, 100), RGB(200, 50, 50))
          imgReaction = CreateMockIcon(iconSize, iconSize, RGB(250, 100, 250), RGB(200, 50, 200))
          imgFilter = CreateMockIcon(iconSize, iconSize, RGB(100, 250, 250), RGB(50, 200, 200))
          
          ; Configure tabs
          NewList tabConfigs.TabConfig()
          AddElement(tabConfigs())
          tabConfigs()\Name = "General"
          tabConfigs()\IconImage = imgPresets
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Environment"
          tabConfigs()\IconImage = imgDirectory
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Start Command"
          tabConfigs()\IconImage = imgCommand
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Stop Command"
          tabConfigs()\IconImage = imgStatus
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Flow"
          tabConfigs()\IconImage = imgFilter
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Status"
          tabConfigs()\IconImage = imgStatus
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Reaction"
          tabConfigs()\IconImage = imgReaction
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          
          tabConfigs()\Name = "Filter"
          tabConfigs()\IconImage = imgFilter
          tabConfigs()\ClickCallback = @OnTabClick()
          
          ;Create vertical tab bar
          
          *tabBar = VerticalTabBar::Create(#WIN_ID, 0, 0, sidebarWidth, sidebarExtendedWidth, windowWidth-sidebarWidth, windowHeight, tabConfigs(),DPI_Scale, @handleLayout(), #True)
          *monitorTabBar = *tabBar
          
          AddElement(ThemeHandler())
          ThemeHandler()\handleChange = @RedrawAllTabs()
          ThemeHandler()\p = *tabBar
          
          ; Get content container and add tab content inside it
          InnerContentContainer = VerticalTabBar::GetContentContainer(*tabBar)
          OpenGadgetList(InnerContentContainer)
          
          ; Content area containers - now inside the TabBar's content container
          Define x = 0, y = 0, width.f = windowWidth-sidebarExtendedWidth, height.f = windowHeight- buttonAreaHeight
          
          tabIndex = 0
          ; General ######################################################################
          tabIds(tabIndex) =  ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          *Gadgets\BtnChooseColor = ButtonGadget(#PB_Any, width-(150+10+20+15) , 10 , 150 , buttonHeight, "Select Monitor Color...")
          SetGadgetColor(*Gadgets\BtnChooseColor, #PB_Gadget_BackColor, RGB(60, 60, 60))
          SetGadgetColor(*Gadgets\BtnChooseColor, #PB_Gadget_FrontColor, themeForegroundColor)
          *Gadgets\ContainerColorPreview = ContainerGadget(#PB_Any, width-(20+15) , 15 , 20 , 20 , #PB_Container_BorderLess)
          CloseGadgetList()
          SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, PatternColor)
          
          CloseGadgetList()
          
          tabIndex + 1
          ; Environment
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          *Gadgets\DirBrowser = ExplorerListGadget(#PB_Any, 10 , 10 , width-20, height-20 , "*.*", #PB_Explorer_MultiSelect)
          SetGadgetColor(*Gadgets\DirBrowser, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(*Gadgets\DirBrowser, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          CloseGadgetList()
          
          tabIndex + 1
          ; Start Command ######################################################################
          tabIds(tabIndex) =  ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          cg = ComboBoxGadget(#PB_Any, 10 , 10 , 150 , 15 )
          AddGadgetItem(cg, -1,"Powershell")   
          AddGadgetItem(cg, -1,"CMD")
          AddGadgetItem(cg, -1,"WSL")
          SetGadgetState(cg, 0)
          
          
          SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          
          *Gadgets\StartCommandEdit =  EditorGadget(#PB_Any, 10 , 40 , width-20, height - 100 )
          SetGadgetColor(*Gadgets\StartCommandEdit, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(*Gadgets\StartCommandEdit, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            LoadLibrary_("Msftedit.dll")
            SendMessage_(GadgetID(*Gadgets\StartCommandEdit), #EM_SETTEXTMODE, #TM_RICHTEXT, 0)
            
            
            
            rect.RECT
            
            ; Get current formatting rectangle
            SendMessage_(GadgetID(*Gadgets\StartCommandEdit), #EM_GETRECT, 0, @rect)
            
            ; Adjust for padding: top=10px, bottom=10px, left=10px, right=10px
            rect\top + 5* DPI_Scale
            rect\bottom - 5* DPI_Scale
            rect\left + 5* DPI_Scale
            rect\right - 5* DPI_Scale
            
            ; Apply the new rectangle
            SendMessage_(GadgetID(*Gadgets\StartCommandEdit), #EM_SETRECT, 0, @rect)
          CompilerEndIf
          
          SetGadgetFont(*Gadgets\StartCommandEdit, FontID(consoleFont))
          
          CloseGadgetList()
          
          tabIndex + 1
          ; Stop Command ######################################################################
          tabIds(tabIndex) =  ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          cg = ComboBoxGadget(#PB_Any, 10 , 10 , 150 , 15 )
          AddGadgetItem(cg, -1,"Powershell")   
          AddGadgetItem(cg, -1,"CMD")
          AddGadgetItem(cg, -1,"WSL")
          SetGadgetState(cg, 0)
          
          
          SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          
          *Gadgets\StopCommandEdit =  EditorGadget(#PB_Any, 10 , 40 , width-20, height - 100 )
          
          SetGadgetColor(*Gadgets\StopCommandEdit, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(*Gadgets\StopCommandEdit, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          
          CloseGadgetList()
          
          tabIndex + 1
          
          
          ; Flow ######################################################################
          tabIds(tabIndex) =  ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          wv= WebViewGadget(#PB_Any,0,0, width, height)
          SetGadgetText(wv, "https://reactflow.dev/examples/nodes/intersections")
          
          CloseGadgetList()
          
          
          
          tabIndex + 1
          ; Status ######################################################################
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          *Gadgets\StatusNotifications = CheckBoxGadget(#PB_Any, 10 , 200 , 200 , 20 , "Enable Notifications")
          
          CloseGadgetList()
          
          tabIndex + 1
          ; Reaction ######################################################################
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          tg = TextGadget(#PB_Any, 10 , 10 , width-20 , height-20 , "Reaction content goes here.")
          SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          CloseGadgetList()
          
          tabIndex + 1
          ; Filter ######################################################################
          tabIds(tabIndex) =  ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          wv= WebViewGadget(#PB_Any,0,0, width, height)
          SetGadgetText(wv, "http://www.google.de")
          
          CloseGadgetList()
          
          
          ; Bottom buttons ######################################################################
          
          
          buttonContainer = ContainerGadget(#PB_Any, 0, height , width, buttonAreaHeight , #PB_Container_BorderLess)
          SetGadgetColor(buttonContainer, #PB_Gadget_BackColor,buttonContainerBackground )
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            buttonContainerHBrush = CreateSolidBrush_(buttonContainerBackground)
            SetProp_(GadgetID(buttonContainer), "BackgroundBrush", buttonContainerHBrush) 
          CompilerEndIf
          
          *Gadgets\BtnOk = ButtonGadget(#PB_Any , width-(85+15+85+15), 10 , 85, buttonHeight, "OK")
          
          *Gadgets\BtnCancel = ButtonGadget(#PB_Any, width-(85+15), 10 , 85 , buttonHeight , "Cancel")
          
          CloseGadgetList()
          CloseGadgetList()
          
          ;VerticalTabBar::Toggle(*tabBar)
          
          ; Show first tab
          OnTabClick(0)
          SetActiveTab(*tabBar,0)
          
          StickyWindow(#WIN_ID, #True)
          AddElement(ThemeHandler())
          ThemeHandler()\handleChange = @ApplyMonitorTheme()
          ApplyTheme(#WIN_ID)
          
          ProcedureReturn 1
        EndIf
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    
    
    Procedure.i HandleEvent(Event.i, Gadget.i) 
      Protected closeWindow = #False
      
      EventType = EventType()
      EventGadget = EventGadget()
      
      If Not VerticalTabBar::HandleTabBarEvent(*tabBar, EventGadget, Event)
        Select Event
          Case #PB_Event_Gadget          
            Select EventGadget
              Case *Gadgets\BtnChooseColor
                PatternColor = ColorRequester(PatternColor)
                SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, PatternColor)
                
              Case *Gadgets\BtnOk
                commandText.s = GetGadgetText(*Gadgets\StartCommandEdit)
                notifyState = GetGadgetState(*Gadgets\StatusNotifications)
                colorHex.s = Right("000000" + Hex(PatternColor), 6)
                MessageRequester("Info", "Command (first 200 chars):" + #LF$ +
                                         Left(commandText, 200) + #LF$ +
                                         "Notifications: " + Str(notifyState) + #LF$ +
                                         "Pattern color: #" + colorHex)
                closeWindow = #True 
              Case *Gadgets\BtnCancel
                closeWindow = #True 
            EndSelect
            
          Case #PB_Event_CloseWindow
            ; Ensure animation thread is stopped before closing
            closeWindow = #True 
        EndSelect
      EndIf
      
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      HideWindow(*Window\WindowID,#True)
    EndProcedure
    
    Procedure Cleanup()
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected bgBrush = GetProp_(GadgetID(buttonContainer), "BackgroundBrush")
        If bgBrush
          DeleteObject_(bgBrush)
        EndIf 
      CompilerEndIf
    EndProcedure 
    
    
    
    *Window = AddManagedWindow("Add Container", *Gadgets, @ShowWindow(), @HandleEvent(), @RemoveWindow(),@Cleanup())
    
    Global isCreated = #False 
    Procedure.i Open()
      editIndex = index
      If Not isCreated
        isCreated = #True
        CreateWindow()
        
      EndIf
      ProcedureReturn OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  
  
  
  
  DeclareModule AddMonitorDialogX
    UseModule App
    UseModule WindowManager
    Declare.i Open()
  EndDeclareModule
  
  Module AddMonitorDialogX
    Structure AddMonitorGadgets
      TxtContainer.i
      LblBgColor.i
      ContainerColorPreview.i
      BtnChooseColor.i
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    Global *Window.AppWindow
    Global *Gadgets.AddMonitorGadgets = AllocateMemory(SizeOf(AddMonitorGadgets))
    Global bgCol.l
    
    Procedure.i CreateWindow()
      If OpenWindow(1, 0, 0, 380, 130, "Add Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\TxtContainer = StringGadget(#PB_Any, 10, 10, 360, 24, "")
        SetActiveGadget(*Gadgets\TxtContainer)
        AddKeyboardShortcut(1, #PB_Shortcut_Return, #EventOk)
        *Gadgets\LblBgColor = TextGadget(#PB_Any, 10, 53, 100, 24, "Background Color:")
        *Gadgets\ContainerColorPreview = ContainerGadget(#PB_Any, 120, 50, 24, 24, #PB_Container_BorderLess)
        CloseGadgetList()
        *Gadgets\BtnChooseColor = ButtonGadget(#PB_Any, 150, 50, 100, 24, "Choose...")
        *Gadgets\BtnOk = ButtonGadget(#PB_Any, 80, 100, 80, 24, "OK")
        *Gadgets\BtnCancel = ButtonGadget(#PB_Any, 170, 100, 80, 24, "Cancel")
        
        bgCol = RGB(200, 200, 200)
        SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, bgCol)
        DisableGadget(*Gadgets\BtnOk, #True)
        StickyWindow(1, #True)
        ApplyTheme(1)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(1)
        ProcedureReturn 1
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent(Event.i, Gadget.i)
      Protected closeWindow = #False
      
      Select Event
        Case #PB_Event_CloseWindow
          closeWindow = #True
          
        Case #PB_Event_Menu
          Select EventMenu()
            Case #EventOk
              Protected container$ = GetGadgetText(*Gadgets\TxtContainer)
              If container$ <> ""
                AddMonitor(container$, bgCol)
                UpdateMonitorList()
                SetActiveGadget(*MainWindowGadgets\ContainerList)
                SetGadgetItemState(*MainWindowGadgets\ContainerList, containerCount-1, #PB_ListIcon_Selected)
                UpdateButtonStates()
                closeWindow = #True
              EndIf
          EndSelect
          
        Case #PB_Event_Gadget
          Select Gadget
            Case *Gadgets\TxtContainer
              If GetGadgetText(*Gadgets\TxtContainer) = ""
                DisableGadget(*Gadgets\BtnOk, #True)
              Else
                DisableGadget(*Gadgets\BtnOk, #False)
              EndIf
              
            Case *Gadgets\BtnChooseColor
              bgCol = ColorRequester(GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor))
              SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, bgCol)
              
            Case *Gadgets\BtnOk
              container$ = GetGadgetText(*Gadgets\TxtContainer)
              If container$ <> ""
                AddMonitor(container$, bgCol)
                UpdateMonitorList()
                SetActiveGadget(*MainWindowGadgets\ContainerList)
                SetGadgetItemState(*MainWindowGadgets\ContainerList, containerCount-1, #PB_ListIcon_Selected)
                UpdateButtonStates()
                closeWindow = #True
              EndIf
              
            Case *Gadgets\BtnCancel
              closeWindow = #True
          EndSelect
      EndSelect
      
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    
    Procedure.i Open()
      editIndex = index
      If Not *Window
        *Window = AddManagedWindow("Add Container", *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      ProcedureReturn OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  ; =============================================================================
  ;- EDIT MONITOR DIALOG MODULE
  ; =============================================================================
  
  DeclareModule EditMonitorDialog
    UseModule App
    UseModule WindowManager
    
    Declare Open(index.i)
  EndDeclareModule
  
  Module EditMonitorDialog
    Structure EditMonitorGadgets
      TxtContainer.i
      LblBgColor.i
      ContainerColorPreview.i
      BtnChooseColor.i
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    Global *Window.AppWindow
    Global *Gadgets.EditMonitorGadgets = AllocateMemory(SizeOf(EditMonitorGadgets))
    Global bgCol.l
    Global editIndex.i
    
    Procedure.i CreateWindow()
      Protected container$ = containerName(editIndex)
      bgCol = bgColor(editIndex)
      
      If OpenWindow(5, 0, 0, 380, 130, "Edit Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\TxtContainer = StringGadget(#PB_Any, 10, 10, 360, 24, container$)
        SetActiveGadget(*Gadgets\TxtContainer)
        *Gadgets\LblBgColor = TextGadget(#PB_Any, 10, 53, 100, 24, "Background Color:")
        *Gadgets\ContainerColorPreview = ContainerGadget(#PB_Any, 120, 50, 24, 24, #PB_Container_BorderLess)
        CloseGadgetList()
        *Gadgets\BtnChooseColor = ButtonGadget(#PB_Any, 150, 50, 100, 24, "Choose...")
        *Gadgets\BtnOk = ButtonGadget(#PB_Any, 80, 100, 80, 24, "OK")
        *Gadgets\BtnCancel = ButtonGadget(#PB_Any, 170, 100, 80, 24, "Cancel")
        
        SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, bgCol)
        If container$ = ""
          DisableGadget(*Gadgets\BtnOk, #True)
        EndIf
        
        StickyWindow(5, #True)
        ApplyTheme(5)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(5)
        
        ProcedureReturn 5
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent(Event.i, Gadget.i)
      
      
      Protected closeWindow = #False
      
      Select Event
        Case #PB_Event_CloseWindow
          closeWindow = #True
          
        Case #PB_Event_Gadget
          Select Gadget
            Case *Gadgets\TxtContainer
              If GetGadgetText(*Gadgets\TxtContainer) = ""
                DisableGadget(*Gadgets\BtnOk, #True)
              Else
                DisableGadget(*Gadgets\BtnOk, #False)
              EndIf
              
            Case *Gadgets\BtnChooseColor
              bgCol = ColorRequester(GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor))
              SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, bgCol)
              
            Case *Gadgets\BtnOk
              containerName(editIndex) = GetGadgetText(*Gadgets\TxtContainer)
              bgColor(editIndex) = bgCol
              UpdateMonitorList()
              SaveSettings()
              If containerStarted(editIndex)
                If trayID(editIndex) = 0
                  CreateMonitorIcon(editIndex, innerColor(editIndex), bgColor(editIndex))
                Else
                  UpdateMonitorIcon(editIndex, patternColor(editIndex, lastMatchPattern(editIndex)))
                EndIf
                HandleInputLine(editIndex, lastMatch(editIndex), #False)
              EndIf
              closeWindow = #True
              
            Case *Gadgets\BtnCancel
              closeWindow = #True
          EndSelect
      EndSelect
      
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    Procedure Open(index.i)
      editIndex = index
      If Not *Window
        *Window = AddManagedWindow("Edit Container", *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  ; =============================================================================
  ;- ADD PATTERN DIALOG MODULE
  ; =============================================================================
  
  DeclareModule AddPatternDialog
    UseModule App
    UseModule WindowManager
    
    
    Declare Open(monitorIndex.i)
  EndDeclareModule
  
  Module AddPatternDialog
    Structure AddPatternGadgets
      TxtPattern.i
      LblColor.i
      ContainerColorPreview.i
      BtnChooseColor.i
      ChkNotification.i
      LnkNotification.i
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    Global *Window.AppWindow
    Global *Gadgets.AddPatternGadgets = AllocateMemory(SizeOf(AddPatternGadgets))
    Global patCol.l
    Global monitorIndex.i
    
    Procedure.i CreateWindow()
      If OpenWindow(2, 0, 0, 380, 170, "Add Status Log Pattern", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\TxtPattern = StringGadget(#PB_Any, 10, 10, 360, 24, "")
        SetActiveGadget(*Gadgets\TxtPattern)
        *Gadgets\LblColor = TextGadget(#PB_Any, 10, 53, 100, 24, "Pattern Color:")
        *Gadgets\ContainerColorPreview = ContainerGadget(#PB_Any, 95, 50, 24, 24, #PB_Container_BorderLess)
        CloseGadgetList()
        *Gadgets\BtnChooseColor = ButtonGadget(#PB_Any, 125, 50, 100, 24, "Choose...")
        *Gadgets\ChkNotification = CheckBoxGadget(#PB_Any, 10, 90, 15, 24, "")
        *Gadgets\LnkNotification = HyperLinkGadget(#PB_Any, 30, 90, 100, 24, "Show notification", 0)
        
        Protected buttonWidth = 80
        Protected buttonSpacing = 10
        Protected totalWidth = buttonWidth * 2 + buttonSpacing
        Protected startX = (380 - totalWidth) / 2
        *Gadgets\BtnOk = ButtonGadget(#PB_Any, startX, 140, buttonWidth, 24, "OK")
        *Gadgets\BtnCancel = ButtonGadget(#PB_Any, startX + buttonWidth + buttonSpacing, 140, buttonWidth, 24, "Cancel")
        
        DisableGadget(*Gadgets\BtnOk, #True)
        patCol = RGB(255, 0, 0)
        SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, patCol)
        
        StickyWindow(2, #True)
        ApplyTheme(2)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(2)
        
        ProcedureReturn 2
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent(Event.i, Gadget.i)
      
      Protected closeWindow = #False
      
      Select Event
        Case #PB_Event_CloseWindow
          closeWindow = #True
          
        Case #PB_Event_Gadget
          Select Gadget
            Case *Gadgets\TxtPattern
              If GetGadgetText(*Gadgets\TxtPattern) = ""
                DisableGadget(*Gadgets\BtnOk, #True)
              Else
                DisableGadget(*Gadgets\BtnOk, #False)
              EndIf
              
            Case *Gadgets\BtnChooseColor
              patCol = ColorRequester(GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor))
              SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, patCol)
              
            Case *Gadgets\BtnOk
              Protected pattern.s = GetGadgetText(*Gadgets\TxtPattern)
              If pattern <> ""
                patCol = GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor)
                AddPattern(monitorIndex, pattern, patCol, GetGadgetState(*Gadgets\ChkNotification))
                UpdatePatternList(monitorIndex)
                If IsWindow(4)
                  SetActiveWindow(4)
                  SetActiveGadget(40)
                  SetGadgetItemState(40, patternCount(monitorIndex)-1, #PB_ListIcon_Selected)
                EndIf
                If containerStarted(monitorIndex)
                  HandleInputLine(monitorIndex, lastMatch(monitorIndex), #False)
                  CompilerIf #PB_Compiler_OS = #PB_OS_Windows: SetEditorTextColor(monitorIndex):CompilerEndIf
                EndIf
                closeWindow = #True
              EndIf
              
            Case *Gadgets\BtnCancel
              closeWindow = #True
              
            Case *Gadgets\LnkNotification
              SetGadgetState(*Gadgets\ChkNotification, 1 - GetGadgetState(*Gadgets\ChkNotification))
          EndSelect
      EndSelect
      
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    Procedure Open(index.i)
      monitorIndex = index
      If Not *Window
        *Window = AddManagedWindow("Add Status Log Pattern", *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  ; =============================================================================
  ;- EDIT PATTERN DIALOG MODULE
  ; =============================================================================
  
  DeclareModule EditPatternDialog
    UseModule App
    UseModule WindowManager
    
    
    Declare Open(monitorIdx.i, patternIdx.i)
  EndDeclareModule
  
  Module EditPatternDialog
    Structure EditPatternGadgets
      TxtPattern.i
      LblColor.i
      ContainerColorPreview.i
      BtnChooseColor.i
      ChkNotification.i
      LnkNotification.i
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    Global *Window.AppWindow
    Global *Gadgets.EditPatternGadgets = AllocateMemory(SizeOf(EditPatternGadgets))
    Global patCol.l
    Global monitorIndex.i
    Global patternIndex.i
    
    Procedure.i CreateWindow()
      Protected pattern.s = patterns(monitorIndex, patternIndex)
      patCol = patternColor(monitorIndex, patternIndex)
      
      If OpenWindow(3, 0, 0, 380, 170, "Edit Status Filter Rules", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\TxtPattern = StringGadget(#PB_Any, 10, 10, 360, 24, pattern)
        SetActiveGadget(*Gadgets\TxtPattern)
        *Gadgets\LblColor = TextGadget(#PB_Any, 10, 53, 100, 24, "Pattern Color:")
        *Gadgets\ContainerColorPreview = ContainerGadget(#PB_Any, 95, 50, 24, 24, #PB_Container_BorderLess)
        CloseGadgetList()
        *Gadgets\BtnChooseColor = ButtonGadget(#PB_Any, 125, 50, 100, 24, "Choose...")
        *Gadgets\ChkNotification = CheckBoxGadget(#PB_Any, 10, 90, 15, 24, "")
        *Gadgets\LnkNotification = HyperLinkGadget(#PB_Any, 30, 90, 100, 24, "Show notification", 0)
        
        Protected buttonWidth = 80
        Protected buttonSpacing = 10
        Protected totalWidth = buttonWidth * 2 + buttonSpacing
        Protected startX = (380 - totalWidth) / 2
        *Gadgets\BtnOk = ButtonGadget(#PB_Any, startX, 140, buttonWidth, 24, "OK")
        *Gadgets\BtnCancel = ButtonGadget(#PB_Any, startX + buttonWidth + buttonSpacing, 140, buttonWidth, 24, "Cancel")
        
        SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, patCol)
        SetGadgetState(*Gadgets\ChkNotification, patternsNotification(monitorIndex, patternIndex))
        
        StickyWindow(3, #True)
        ApplyTheme(3)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(3)
        
        ProcedureReturn 3
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent(Event.i, Gadget.i)
      
      Protected closeWindow = #False
      
      Select Event
        Case #PB_Event_CloseWindow
          closeWindow = #True
          
        Case #PB_Event_Gadget
          Select Gadget
            Case *Gadgets\TxtPattern
              If GetGadgetText(*Gadgets\TxtPattern) = ""
                DisableGadget(*Gadgets\BtnOk, #True)
              Else
                DisableGadget(*Gadgets\BtnOk, #False)
              EndIf
              
            Case *Gadgets\BtnChooseColor
              patCol = ColorRequester(GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor))
              SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, patCol)
              
            Case *Gadgets\BtnOk
              patCol = GetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor)
              patterns(monitorIndex, patternIndex) = GetGadgetText(*Gadgets\TxtPattern)
              patternColor(monitorIndex, patternIndex) = patCol
              patternsNotification(monitorIndex, patternIndex) = GetGadgetState(*Gadgets\ChkNotification)
              
              If containerStarted(monitorIndex)
                HandleInputLine(monitorIndex, lastMatch(monitorIndex), #False)
                CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetEditorTextColor(monitorIndex) : CompilerEndIf
              EndIf
              
              SaveSettings()
              closeWindow = #True
              
            Case *Gadgets\BtnCancel
              closeWindow = #True
              
            Case *Gadgets\LnkNotification
              SetGadgetState(*Gadgets\ChkNotification, 1 - GetGadgetState(*Gadgets\ChkNotification))
          EndSelect
      EndSelect
      
      
      
      If closeWindow
        UpdatePatternList(monitorIndex)
        If IsWindow(4)
          SetActiveWindow(4)
          SetActiveGadget(40)
          SetGadgetItemState(40, patternIndex, #PB_ListIcon_Selected)
        EndIf
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
      
      
      
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    Procedure Open(monIdx.i, patIdx.i)
      monitorIndex = monIdx
      patternIndex = patIdx
      If Not *Window
        *Window = AddManagedWindow("Edit Status Filter Rules", *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  ; =============================================================================
  ; EDIT PATTERNS DIALOG MODULE
  ; =============================================================================
  
  DeclareModule EditPatternsDialog
    UseModule App
    UseModule WindowManager
    Declare Open(index.i)
  EndDeclareModule
  
  Module EditPatternsDialog
    Structure EditPatternsGadgets
      PatternList.i
      BtnAdd.i
      BtnRemove.i
      BtnEdit.i
      BtnOk.i
    EndStructure
    
    Global *Window.AppWindow
    Global *Gadgets.EditPatternsGadgets = AllocateMemory(SizeOf(EditPatternsGadgets))
    Global editIndex.i
    
    Procedure.i CreateWindow()
      If editIndex < 0 Or editIndex >= containerCount
        ProcedureReturn 0
      EndIf
      
      If OpenWindow(4, 150, 150, 420, 450, "Edit Status Filter Rules", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\PatternList = ListIconGadget(#PB_Any, 10, 10, 300, 430, "Status Log Filter Rules", 295, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
        ApplySingleColumnListIcon(GadgetID(*Gadgets\PatternList))
        *Gadgets\BtnAdd = ButtonGadget(#PB_Any, 325, 10, 80, 24, "Add")
        *Gadgets\BtnRemove = ButtonGadget(#PB_Any, 325, 40, 80, 24, "Remove")
        *Gadgets\BtnEdit = ButtonGadget(#PB_Any, 325, 80, 80, 24, "Edit")
        *Gadgets\BtnOk = ButtonGadget(#PB_Any, 325, 417, 80, 24, "Ok")
        
        UpdatePatternList(editIndex)
        UpdatePatternButtonStates()
        
        StickyWindow(4, #True)
        ApplyTheme(4)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(4)
        
        ProcedureReturn 4
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent(Event.i, Gadget.i)
      
      Protected closeWindow = #False
      
      Select Event
        Case #PB_Event_CloseWindow
          closeWindow = #True
          
        Case #PB_Event_Gadget
          Protected currentPatternIndex = GetGadgetState(*Gadgets\PatternList)
          
          Select Gadget
            Case *Gadgets\PatternList
              UpdatePatternButtonStates()
              If EventType() = #PB_EventType_LeftDoubleClick
                If currentPatternIndex >= 0
                  EditPatternDialog::Open(editIndex, currentPatternIndex)
                EndIf
              EndIf
              
            Case *Gadgets\BtnAdd
              AddPatternDialog::Open(editIndex)
              UpdatePatternButtonStates()
              
            Case *Gadgets\BtnEdit
              If currentPatternIndex >= 0
                EditPatternDialog::Open(editIndex, currentPatternIndex)
              EndIf
              
            Case *Gadgets\BtnRemove
              If currentPatternIndex >= 0
                For p = currentPatternIndex To patternCount(editIndex)-2
                  patterns(editIndex, p) = patterns(editIndex, p+1)
                  patternColor(editIndex, p) = patternColor(editIndex, p+1)
                Next
                patternCount(editIndex) - 1
              EndIf
              UpdatePatternList(editIndex)
              UpdatePatternButtonStates()
              
            Case *Gadgets\BtnOk
              closeWindow = #True
          EndSelect
      EndSelect
      
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    Procedure Open(index.i)
      editIndex = index
      If Not *Window
        *Window = AddManagedWindow("Edit Status Filter Rules", *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      OpenManagedWindow(*Window)
    EndProcedure
    
  EndModule
  
  
  
  
  ; =============================================================================
  ;- NEW MAIN WINDOW MODULE
  ; =============================================================================
  
  
  DeclareModule AppWindow
    UseModule App
    UseModule WindowManager
    Declare.i Open()
    Declare.i CreateWindow()
  EndDeclareModule
  
  Module AppWindow
    UseModule App
    UseModule VerticalTabBar
    
    
    Structure AddMonitorGadgets
      ContainerColorPreview.i
      BtnChooseColor.i
      StartCommandEdit.i
      StopCommandEdit.i
      DirBrowser.i
      
      StatusNotifications.i
      
      BtnAdd.i
      BtnRemove.i
      
      
      TxtContainer.i
      LblBgColor.i
      
      BtnOk.i
      BtnCancel.i
    EndStructure
    
    #WIN_ID = 1000; TODO CHANGE TO 0 
    
    Global *Window.AppWindow
    Global *Gadgets.AddMonitorGadgets = AllocateMemory(SizeOf(AddMonitorGadgets))
    Global bgCol.l
    
    Global *tabBar.VerticalTabBarData
    
    Global Dim tabIds(3)
    
    
    ExamineDesktops()
    desktopWidth =  DesktopWidth(0)
    Debug "DPI_Scale 1"
    Debug DPI_Scale
    
    Global buttonContainer
    
    Global windowWidth = 650
    Global windowHeight = 400
    Global sidebarExtendedWidth = 160
    Global buttonAreaHeight = 51
    Global sidebarWidth = 40
    Global buttonHeight = 30
    
    Global buttonContainerBackground
    
    Global *list.ModernList::ModernListData
    
    Procedure SetColors()
      If IsDarkModeActiveCached
        buttonContainerBackground = RGB(65, 65, 65)
      Else
        buttonContainerBackground = RGB(230,230,230)
      EndIf 
    EndProcedure
    
    
    Procedure ResizeWindowCallback() 
      
      Protected windowWidth = WindowWidth(#WIN_ID)
      Protected windowHeight = WindowHeight(#WIN_ID)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows: 
        SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #False, 0)
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #False, 0)
      CompilerEndIf
      Define x = 0, y = 0, width.f = windowWidth - sidebarWidth , height.f = windowHeight - buttonAreaHeight 
      VerticalTabBar::Resize(*tabBar, windowWidth - sidebarWidth, windowHeight ,#True )
      
      NormalResizeGadget(buttonContainer, #PB_Ignore, height, width+5, #PB_Ignore,*tabBar\ParentsRoundingDeltaX)
      
      NormalResizeGadget(tabIds(*tabBar\ActiveTabIndex), #PB_Ignore,#PB_Ignore,width,height,*tabBar\ParentsRoundingDeltaX)
      
      
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #True, 0)
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #True, 0)
        
        ;RedrawWindow_(GadgetID(*tabBar\SidebarContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN) ; Omit #RDW_ERASE if your paint handlers fill the background fully
        ;RedrawWindow_(GadgetID(*tabBar\ContentContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN)
        
        RedrawWindow_(WindowID(#WIN_ID), #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW)
      CompilerEndIf 
      
    EndProcedure
    
    Procedure CreateMockIcon(width.i, height.i, bgColor.i, fgColor.i)
      Protected img = CreateImage(#PB_Any, width * DPI_Scale, height * DPI_Scale, 32, bgColor)
      If img
        StartDrawing(ImageOutput(img))
        DrawingMode(#PB_2DDrawing_Default)
        Box(2 * DPI_Scale, 2 * DPI_Scale, (width-4) * DPI_Scale, (height-4) * DPI_Scale, fgColor)
        StopDrawing()
      EndIf
      ProcedureReturn img
    EndProcedure
    
    
    Procedure OnTabClick(tabIndex.i)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        ; Hide all content containers
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, 0, 0)
        SendMessage_(GadgetID(tabIds(tabIndex)), #WM_SETREDRAW, 0, 0)
      CompilerEndIf   
      
      
      For i = 0 To ArraySize(tabIds())
        If i = tabIndex
          HideGadget(tabIds(i), #False)
        Else
          HideGadget(tabIds(i), #True)
        EndIf 
      Next
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(*tabBar\ContentContainer), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
        SendMessage_(GadgetID(tabIds(tabIndex)), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(tabIds(tabIndex)), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      CompilerEndIf
      
    EndProcedure
    
    Global NewList brushes.i()
    
    Procedure SetGadgetBackgoundColor(gadget, bg)
      SetGadgetColor(gadget, #PB_Gadget_BackColor, g)
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        hBrush = CreateSolidBrush_(bg)
        AddElement(brushes())
        brushes() = hBrush
        SetProp_(GadgetID(gadget), "BackgroundBrush", hBrush) 
      CompilerEndIf 
    EndProcedure 
    
    
    Procedure HandleLayout(*tabBar.VerticalTabBarData, index.i, width, IsExpanded,*deltaWidth,*parentsRoundingDeltaX)
      parentsRoundingDeltaX.f = PeekF(*parentsRoundingDeltaX)
      deltaWidth.f = PeekF(*deltaWidth)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(tabIds(index)), #WM_SETREDRAW, 0, 0)
      CompilerEndIf
      
      NormalResizeGadget(tabIds(index), #PB_Ignore, #PB_Ignore, width, #PB_Ignore,parentsRoundingDeltaX)
      
      
      ;TODO
      buttonGroupX = (width-30)/2-(85+15+85)/2
      
      If IsExpanded
        Debug deltaWidth
        buttonGroupX-deltaWidth/2
      EndIf 
      If buttonGroupX < 0
        buttonGroupX = 0
      EndIf 
      NormalResizeGadget(*Gadgets\BtnAdd, 15+buttonGroupX, #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
      NormalResizeGadget(*Gadgets\BtnRemove, 15+buttonGroupX+85+15,#PB_Ignore,#PB_Ignore , #PB_Ignore, parentsRoundingDeltaX)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(tabIds(index)), #WM_SETREDRAW, 1, 0)
        RedrawWindow_(GadgetID(tabIds(index)), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
      CompilerEndIf
      
    EndProcedure
    
    
    Procedure.i ShowWindow()
      Debug "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ShowWindow"
      ShowWindowFadeIn(#WIN_ID)
      ProcedureReturn #WIN_ID
    EndProcedure 
    
    
    Procedure  ApplyMonitorTheme(*p)
      SetColors()
      SetGadgetColor(buttonContainer, #PB_Gadget_BackColor,buttonContainerBackground )
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected bgBrush = GetProp_(GadgetID(buttonContainer), "BackgroundBrush")
        If bgBrush
          DeleteObject_(bgBrush)
        EndIf 
        buttonContainerHBrush = CreateSolidBrush_(buttonContainerBackground)
        SetProp_(GadgetID(buttonContainer), "BackgroundBrush", buttonContainerHBrush) 
      CompilerEndIf
    EndProcedure
    
    
    
    Procedure DestroyGadget(gadget.i)
      If IsGadget(gadget)
        FreeGadget(gadget)
      EndIf
    EndProcedure
    
    
    Procedure HandleButtonEvent(*list.ModernList::ModernListData, index ,eventGadget.i, event.i,childIndex, whichGadget = 0)
      
      Protected handled = #False
      If event = #PB_EventType_LeftClick And whichGadget = 0
        Debug "HandleButtonEvent "+Str(index)
        Debug *list\DPI_Scale
        Debug index
        Debug "Button clicked: Gadget ID " + Str(eventGadget)
        MessageRequester("Button Action", "Button clicked! Gadget ID: " + Str(eventGadget))
        handled = #True
      EndIf
      
      ProcedureReturn handled
    EndProcedure
    
    Procedure CreateButtonGadget(parentGadget.i, x.i, y.i, width.i, height.i)
      
      Protected g.i = ButtonGadget(#PB_Any, x, y, width, height, "Click Me")
      If IsGadget(g)
        If IsDarkModeActiveCached
          SetGadgetColor(g, #PB_Gadget_BackColor, darkThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, darkThemeForegroundColor)
        Else
          SetGadgetColor(g, #PB_Gadget_BackColor, lightThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, lightThemeForegroundColor)
        EndIf
      EndIf
      Protected *childGadgets.ModernListElement::ChildGadgets = AllocateStructure(ModernListElement::ChildGadgets)
      If *childGadgets
        InitializeStructure(*childGadgets, ModernListElement::ChildGadgets)
        AddElement(*childGadgets\Gadgets())
        *childGadgets\Gadgets() = g
      EndIf
      
      ProcedureReturn *childGadgets
    EndProcedure
    
    Global ButtonInterface.ModernListElement::GadgetInterface
    ButtonInterface\Create = @CreateButtonGadget()
    ButtonInterface\HandleEvent = @HandleButtonEvent()
    ButtonInterface\Destroy = @DestroyGadget()
    
    Procedure HandleComboEvent(*list, index ,eventGadget.i, event.i,childIndex, whichGadget = 0)
      Debug "!!!!!!!!!!!!!!!!!!!xxxxxx "+Str(event)
      Protected handled = #False
      If event = #PB_EventType_Change
        Protected selectedText$ = GetGadgetText(eventGadget)
        Debug "XXXXXComboBox changed: Gadget ID " + Str(eventGadget) + ", Selected: " + selectedText$
        MessageRequester("ComboBox Selection", "Selected option: " + selectedText$)
        handled = #True
      EndIf
      ProcedureReturn handled
    EndProcedure
    
    
    #WM_MOUSEWHEEL = $020A
    
    Global oldProc
    Procedure ComboSubclass(hwnd, msg, wParam, lParam)
      Select msg
        Case #WM_MOUSEWHEEL
          ; Forward to parent instead of scrolling the combo
          SendMessage_(GetParent_(hwnd), msg, wParam, lParam)
          ProcedureReturn 0 ; don't handle here
      EndSelect
      ProcedureReturn CallWindowProc_(oldProc, hwnd, msg, wParam, lParam)
    EndProcedure
    Procedure CreateComboBoxGadget(parentGadget.i, x.i, y.i, width.i, height.i, isContainerEvent=#False)
      Protected g.i = ComboBoxGadget(#PB_Any, x, y, width, height)
      oldProc = SetWindowLongPtr_(GadgetID(g), #GWL_WNDPROC, @ComboSubclass())
      
      If IsGadget(g)
        AddGadgetItem(g, -1, "Option 1")
        AddGadgetItem(g, -1, "Option 2")
        AddGadgetItem(g, -1, "Option 3")
        SetGadgetState(g, 0)
        If IsDarkModeActiveCached
          SetGadgetColor(g, #PB_Gadget_BackColor, darkThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, darkThemeForegroundColor)
        Else
          SetGadgetColor(g, #PB_Gadget_BackColor, lightThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, lightThemeForegroundColor)
        EndIf
      EndIf
      Protected *childGadgets.ModernListElement::ChildGadgets = AllocateStructure(ModernListElement::ChildGadgets)
      If *childGadgets
        InitializeStructure(*childGadgets, ModernListElement::ChildGadgets) ; Important for lists/maps!
        AddElement(*childGadgets\Gadgets())
        *childGadgets\Gadgets() = g
      EndIf
      
      ProcedureReturn *childGadgets
    EndProcedure
    
    Global ComboInterface.ModernListElement::GadgetInterface
    ComboInterface\Create = @CreateComboBoxGadget()
    ComboInterface\HandleEvent = @HandleComboEvent()
    ComboInterface\Destroy = @DestroyGadget()
    
    Procedure HandleStringEvent(*list, index ,eventGadget.i, event.i,childIndex, whichGadget = 0)
      Protected handled = #False
      Debug "!!!!!!!!!!!!!!!"
      If event = #PB_EventType_Change
        Debug "StringGadget changed: Gadget ID " + Str(eventGadget) + ", Text: " + GetGadgetText(eventGadget)
        MessageRequester("StringGadget Action index: "+Str(index) +" childIndex:"+Str(childIndex), "Text changed To: " + GetGadgetText(eventGadget))
        handled = #True
      EndIf
      ProcedureReturn handled
    EndProcedure
    
    Procedure CreateStringGadget(parentGadget.i, x.i, y.i, width.i, height.i)
      
      g1 = StringGadget(#PB_Any, x, y, width, height/2, "Edit me")
      g2 = StringGadget(#PB_Any, x, y+height/2, width, height/2, "Edit me2")
      
      If IsGadget(g)
        If IsDarkModeActiveCached
          SetGadgetColor(g, #PB_Gadget_BackColor, darkThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, darkThemeForegroundColor)
        Else
          SetGadgetColor(g, #PB_Gadget_BackColor, lightThemeBackgroundColor)
          SetGadgetColor(g, #PB_Gadget_FrontColor, lightThemeForegroundColor)
        EndIf
      EndIf
      Protected *childGadgets.ModernListElement::ChildGadgets = AllocateStructure(ModernListElement::ChildGadgets)
      If *childGadgets
        InitializeStructure(*childGadgets, ModernListElement::ChildGadgets) 
        AddElement(*childGadgets\Gadgets())
        *childGadgets\Gadgets() = g1
        AddElement(*childGadgets\Gadgets())
        *childGadgets\Gadgets() = g2
      EndIf
      
      ProcedureReturn *childGadgets
    EndProcedure
    
    Global StringInterface.ModernListElement::GadgetInterface
    StringInterface\Create = @CreateStringGadget()
    StringInterface\HandleEvent = @HandleStringEvent()
    StringInterface\Destroy = @DestroyGadget()
    
    
    
    
    
    Procedure ListResizeCallback(*list.ModernList::ModernListData, width.i, height.i)
      Debug "List resized to " + Str(width) + "x" + Str(height)
    EndProcedure
    
    
    Procedure CreateListMockImage()
      Protected img.i = CreateImage(#PB_Any, 32, 32, 32)
      If StartDrawing(ImageOutput(img))
        Box(0, 0, 32, 32, RGB(255, 0, 0))
        LineXY(0, 0, 32, 32, RGB(255, 255, 255))
        LineXY(0, 32, 32, 0, RGB(255, 255, 255))
        StopDrawing()
      EndIf
      ProcedureReturn img
    EndProcedure
    
    
    
    
    
    Procedure.i CreateWindow()
      If Not IsWindow(#WIN_ID)
        ; Create main window with DPI scaling
        If OpenWindow(#WIN_ID, 0, 0, windowWidth , windowHeight , "Monitor - VS Code Style", 
                      #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget|#PB_Window_MaximizeGadget| #PB_Window_SizeGadget | #PB_Window_Invisible)
          
          Debug "DPI_Scale 2"
          Debug DPI_Scale
          
          
          Debug "DPI_Scale 3"
          Debug DPI_Scale
          
          
          SetColors()
          
          SetWindowColor(#WIN_ID, themeBackgroundColor)
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            SetWindowLongPtr_(WindowID(#WIN_ID), #GWL_STYLE, GetWindowLongPtr_(WindowID(#WIN_ID), #GWL_STYLE) | #WS_CLIPCHILDREN)
            
            SetWindowCallback(@WindowCallback())
          CompilerEndIf 
          BindEvent(#PB_Event_SizeWindow, @ResizeWindowCallback(),#WIN_ID)
          
          iconSize = 10
          ; Create mock icons
          imgPresets = CreateMockIcon(iconSize, iconSize, RGB(100, 100, 250), RGB(50, 50, 200))
          imgCommand = CreateMockIcon(iconSize, iconSize, RGB(100, 250, 100), RGB(50, 200, 50))
          imgDirectory = CreateMockIcon(iconSize, iconSize, RGB(250, 200, 100), RGB(200, 150, 50))
          imgStatus = CreateMockIcon(iconSize, iconSize, RGB(250, 100, 100), RGB(200, 50, 50))
          imgReaction = CreateMockIcon(iconSize, iconSize, RGB(250, 100, 250), RGB(200, 50, 200))
          imgFilter = CreateMockIcon(iconSize, iconSize, RGB(100, 250, 250), RGB(50, 200, 200))
          
          ; Configure tabs
          NewList tabConfigs.TabConfig()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Monitors"
          tabConfigs()\IconImage = imgPresets
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Events"
          tabConfigs()\IconImage = imgReaction
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "Extensions"
          tabConfigs()\IconImage = imgCommand
          tabConfigs()\ClickCallback = @OnTabClick()
          AddElement(tabConfigs())
          tabConfigs()\Name = "About"
          tabConfigs()\IconImage = imgStatus
          tabConfigs()\ClickCallback = @OnTabClick()
          
          
          ;Create vertical tab bar
          
          *tabBar = VerticalTabBar::Create(#WIN_ID, 0, 0, sidebarWidth, sidebarExtendedWidth, windowWidth-sidebarWidth, windowHeight, tabConfigs(),DPI_Scale, @handleLayout())
          *monitorTabBar = *tabBar
          
          AddElement(ThemeHandler())
          ThemeHandler()\handleChange = @RedrawAllTabs()
          ThemeHandler()\p = *tabBar
          
          
          ; Get content container and add tab content inside it
          InnerContentContainer = VerticalTabBar::GetContentContainer(*tabBar)
          OpenGadgetList(InnerContentContainer)
          
          ; Content area containers - now inside the TabBar's content container
          Define x = 0, y = 0, width.f = windowWidth-sidebarWidth , height.f = (windowHeight - buttonAreaHeight)
          
          tabIndex = 0
          ; Monitors
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          Protected mockImage.i = CreateListMockImage()
          
          Define header.ModernList::ListHeader
          header\Height = 30
          
          AddElement(header\Columns())
          header\Columns()\Type = ModernListElement::#Element_Text
          header\Columns()\Content = "ID"
          header\Columns()\Width = 100
          header\Columns()\Alignment = 1
          
          AddElement(header\Columns())
          header\Columns()\Type = ModernListElement::#Element_Text
          header\Columns()\Content = "Name"
          header\Columns()\Width = 200
          
          AddElement(header\Columns())
          header\Columns()\Type = ModernListElement::#Element_Text
          header\Columns()\Content = "Action"
          header\Columns()\Width = 150
          
          NewList rows.ModernList::ListRow()
          
          AddElement(rows())
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Text
          rows()\Elements()\Content = "001"
          rows()\Elements()\Width = 100
          rows()\Elements()\Alignment = 1
          rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
          rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
          rows()\Elements()\HoveredForeColor = RGB(0, 0, 255)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Image
          rows()\Elements()\Content = Str(mockImage)
          rows()\Elements()\Width = 200
          rows()\Elements()\Alignment = 1
          rows()\Elements()\HoveredTintColor = RGBA(0, 0, 255, 50)
          rows()\Elements()\SelectedTintColor = RGBA(255, 255, 255, 50)
          rows()\Elements()\SelectedHoveredTintColor = RGBA(200, 200, 200, 50)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Gadget
          rows()\Elements()\Content = "Button 1"
          rows()\Elements()\Interface = @ButtonInterface
          rows()\Elements()\Width = 150
          
          AddElement(rows())
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Text
          rows()\Elements()\Content = "002"
          rows()\Elements()\Width = 100
          rows()\Elements()\Alignment = 1
          rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
          rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Text
          rows()\Elements()\Content = "Jane Doe"
          rows()\Elements()\Width = 200
          rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
          rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Gadget
          rows()\Elements()\Content = "Button Data"
          rows()\Elements()\Interface = @ButtonInterface
          rows()\Elements()\Width = 150
          
          AddElement(rows())
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Image
          rows()\Elements()\Content = Str(mockImage)
          rows()\Elements()\Width = 100
          rows()\Elements()\Alignment = 1
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Text
          rows()\Elements()\Content = "Item 3"
          rows()\Elements()\Width = 200
          rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
          rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Gadget
          rows()\Elements()\Content = "Combo Data"
          rows()\Elements()\Interface = @ComboInterface
          
          rows()\Elements()\Width = 150
          rows()\Height = 80
          
          AddElement(rows())
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Text
          rows()\Elements()\Content = "003"
          rows()\Elements()\Width = 100
          rows()\Elements()\Alignment = 1
          rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
          rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
          
          AddElement(rows()\Elements())
          rows()\Elements()\Type = ModernListElement::#Element_Gadget
          rows()\Elements()\Content = "String Data"
          rows()\Elements()\Interface = @StringInterface
          rows()\Elements()\Width = 200
          
          For i = 5 To 100
            AddElement(rows())
            
            AddElement(rows()\Elements())
            rows()\Elements()\Type = ModernListElement::#Element_Text
            rows()\Elements()\Content = RSet(Str(i), 3, "0")
            rows()\Elements()\Width = 100
            rows()\Elements()\Alignment = 1
            
            AddElement(rows()\Elements())
            rows()\Elements()\Type = ModernListElement::#Element_Text
            rows()\Elements()\Content = "Row " + Str(i)
            rows()\Elements()\Width = 200
            
            AddElement(rows()\Elements())
            If i % 3 = 0
              rows()\Elements()\Type = ModernListElement::#Element_Gadget
              rows()\Elements()\Content = "Button " + Str(i)
              rows()\Elements()\Interface = @ButtonInterface
            Else
              rows()\Elements()\Type = ModernListElement::#Element_Text
              rows()\Elements()\Content = "No gadget"
            EndIf
            rows()\Elements()\Width = 150
          Next
          
           *list.ModernList::ModernListData = ModernList::CreateList(0, 0, 0, 750, 700, rows(), @header, 30, DPI_Scale, @ListResizeCallback())
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          CloseGadgetList()
          
          tabIndex + 1
          ; Logs
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          tg = TextGadget(#PB_Any, 10 , 10 , width-20 , height-20 , "Logs...")
          SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          CloseGadgetList()
          
          tabIndex + 1
          ; Extensions
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          tg = TextGadget(#PB_Any, 10 , 10 , width-20 , height-20 , "Extensions...")
          SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          CloseGadgetList()
          
          tabIndex + 1
          ; About
          tabIds(tabIndex) = ContainerGadget(#PB_Any, x, y, width, height, #PB_Container_BorderLess)
          
          tg = TextGadget(#PB_Any, 10 , 10 , width-20 , height-20 , "About...")
          SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
          SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
          
          CloseGadgetList()
          
          
          ; Bottom buttons
          
          buttonContainer = ContainerGadget(#PB_Any, 0, height , width, buttonAreaHeight , #PB_Container_BorderLess)
          SetGadgetColor(buttonContainer, #PB_Gadget_BackColor,buttonContainerBackground )
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            buttonContainerHBrush = CreateSolidBrush_(buttonContainerBackground)
            SetProp_(GadgetID(buttonContainer), "BackgroundBrush", buttonContainerHBrush) 
          CompilerEndIf 
          
          buttonGroupX = (width-30)/2-(85+15+85)/2
          If buttonGroupX < 0
            buttonGroupX = 0
          EndIf 
          *Gadgets\BtnAdd = ButtonGadget(#PB_Any , 15+buttonGroupX, 10 , 85, buttonHeight, "Add")
          *Gadgets\BtnRemove = ButtonGadget(#PB_Any,15+buttonGroupX+85+15, 10 , 85 , buttonHeight , "Remove")
          
          
          CloseGadgetList()
          CloseGadgetList()
          
          ; Show first tab
          OnTabClick(0)
          SetActiveTab(*tabBar,0)
          
          StickyWindow(#WIN_ID, #True)
          
          AddElement(ThemeHandler())
          ThemeHandler()\handleChange = @ApplyMonitorTheme()
          ApplyTheme(#WIN_ID)
          
          ProcedureReturn 1
        EndIf
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    
    
    Procedure.i HandleEvent(Event.i, Gadget.i) 
      Protected closeWindow = #False
      EventType = EventType()
      EventGadget = EventGadget()
      
      If Not ModernList::HandleListEvent(*list, EventGadget(), EventType())
        
        
        
        If Not VerticalTabBar::HandleTabBarEvent(*tabBar, EventGadget, Event)
          Select Event
            Case #PB_Event_Gadget          
              Select EventGadget
                Case *Gadgets\BtnChooseColor,  *Gadgets\ContainerColorPreview
                  PatternColor = ColorRequester(PatternColor)
                  SetGadgetColor(*Gadgets\ContainerColorPreview, #PB_Gadget_BackColor, PatternColor)
                  
                Case *Gadgets\BtnOk
                  
                  closeWindow = #True 
                Case *Gadgets\BtnCancel
                  closeWindow = #True 
              EndSelect
              
            Case #PB_Event_CloseWindow
              ; Ensure animation thread is stopped before closing
              closeWindow = #True 
          EndSelect
        EndIf
      EndIf
      If closeWindow
        CloseManagedWindow(*Window)
      EndIf    
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      HideWindow(*Window\WindowID,#True)
    EndProcedure
    
    Procedure Cleanup()
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected bgBrush = GetProp_(GadgetID(buttonContainer), "BackgroundBrush")
        If bgBrush
          DeleteObject_(bgBrush)
        EndIf 
      CompilerEndIf
    EndProcedure 
    
    
    
    *Window = AddManagedWindow("Add Container", *Gadgets, @ShowWindow(), @HandleEvent(), @RemoveWindow(),@Cleanup())
    
    Global isCreated = #False 
    Procedure.i Open()
      editIndex = index
      If Not isCreated
        isCreated = #True
        CreateWindow()
        
      EndIf
      
      ProcedureReturn OpenManagedWindow(*Window)
    EndProcedure
    
    
  EndModule
  
  
  ; =============================================================================
  ;- MAIN WINDOW MODULE
  ; =============================================================================
  
  DeclareModule MainWindow
    UseModule App
    UseModule WindowManager
    Declare.i Open()
  EndDeclareModule
  
  Module MainWindow
    UseModule App
    UseModule WindowManager
    
    
    Global *Window.AppWindow
    Global *Gadgets.MainWindowGadgets = *MainWindowGadgets
    
    Procedure.i CreateWindow()
      If OpenWindow(0, 0, 0, 420, 300, #APP_TITLE, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered | #PB_Window_Invisible)
        *Gadgets\ContainerList = ListIconGadget(#PB_Any, 10, 10, 300, 280, "Container", 295, #PB_ListIcon_FullRowSelect)
        ApplySingleColumnListIcon(GadgetID(*Gadgets\ContainerList))
        *Gadgets\BtnAdd = ButtonGadget(#PB_Any, 325, 10, 80, 24, "Add")
        *Gadgets\BtnEdit = ButtonGadget(#PB_Any, 325, 40, 80, 24, "Edit")
        *Gadgets\BtnRemove = ButtonGadget(#PB_Any, 325, 70, 80, 24, "Remove")
        *Gadgets\BtnRules = ButtonGadget(#PB_Any, 325, 110, 80, 24, "Rules")
        *Gadgets\BtnStart = ButtonGadget(#PB_Any, 325, 150, 80, 24, "Start")
        *Gadgets\BtnStop = ButtonGadget(#PB_Any, 325, 180, 80, 24, "Stop")
        
        UpdateMonitorList()
        ApplyTheme(0)
        Repeat : Delay(1) : Until WindowEvent() = 0
        ShowWindowFadeIn(0)
        
        ProcedureReturn 0
      EndIf
      ProcedureReturn -1
    EndProcedure
    
    Procedure.i HandleEvent( Event.i, Window.i, Gadget.i)
      Select Event
          
        Case #PB_Event_Gadget
          Protected currentContainerIndex = GetGadgetState(*Gadgets\ContainerList)
          Select Gadget
            Case *Gadgets\ContainerList
              UpdateButtonStates()
              If EventType() = #PB_EventType_LeftDoubleClick
                If currentContainerIndex >= 0
                  If Not containerStarted(currentContainerIndex)
                    StartDockerFollow(currentContainerIndex)
                    SetActiveGadget(*Gadgets\ContainerList)
                    SetGadgetItemState(*Gadgets\ContainerList, currentContainerIndex, #PB_ListIcon_Selected)
                    UpdateButtonStates()
                  Else
                    StopDockerFollow(currentContainerIndex)
                  EndIf
                EndIf
              EndIf
              
            Case *Gadgets\BtnAdd
              MonitorDialog::Open()
              
            Case *Gadgets\BtnRemove
              If currentContainerIndex >= 0
                RemoveMonitor(currentContainerIndex)
                UpdateMonitorList()
              EndIf
              
            Case *Gadgets\BtnStart
              If currentContainerIndex >= 0
                StartDockerFollow(currentContainerIndex)
                SetActiveGadget(*Gadgets\ContainerList)
                SetGadgetItemState(*Gadgets\ContainerList, currentContainerIndex, #PB_ListIcon_Selected)
                UpdateButtonStates()
              EndIf
              
            Case *Gadgets\BtnStop
              If currentContainerIndex >= 0
                StopDockerFollow(currentContainerIndex)
              EndIf
              
            Case *Gadgets\BtnRules
              If currentContainerIndex >= 0
                EditPatternsDialog::Open(currentContainerIndex)
                SetActiveGadget(*Gadgets\ContainerList)
                SetGadgetItemState(*Gadgets\ContainerList, currentContainerIndex, #PB_ListIcon_Selected)
                UpdateButtonStates()
              EndIf
              
            Case *Gadgets\BtnEdit
              If currentContainerIndex >= 0
                AppWindow::Open()
                SetActiveGadget(*Gadgets\ContainerList)
                SetGadgetItemState(*Gadgets\ContainerList, currentContainerIndex, #PB_ListIcon_Selected)
                UpdateButtonStates()
              EndIf
          EndSelect
          
        Case #PB_Event_CloseWindow
          If IsSomeRunning()
            HideWindow(Window, #True)
          Else
            ProcedureReturn #False
          EndIf
          
      EndSelect
      
      For i = 0 To containerCount-1
        CheckDockerOutput(i)
      Next
      
      ProcedureReturn #True
    EndProcedure
    
    Procedure RemoveWindow()
      CloseWindow(*Window\WindowID)
    EndProcedure
    
    
    Procedure.i Open()
      If Not *Window
        *Window = AddManagedWindow(#APP_TITLE, *Gadgets, @CreateWindow(), @HandleEvent(), @RemoveWindow())
      EndIf
      ProcedureReturn OpenManagedWindow(*Window)
    EndProcedure
  EndModule
  
  
  ; =============================================================================
  ;- MAIN APPLICATION STARTUP
  ; =============================================================================
  
  DeclareModule Execute
    Declare StartApp()
  EndDeclareModule
  Module Execute
    
    Procedure.i HandleMainEvent( Event.i, Window.i, Gadget.i)
      UseModule App
      Select Event
        Case #PB_Event_SysTray
          Protected systrayId = EventGadget()
          For i = 0 To containerCount-1
            If systrayId = trayID(i)
              ShowLogs(i)
              Break
            EndIf
          Next
          
        Case #PB_Event_Menu
          Protected menuEvent = EventMenu()
          If menuEvent >= 1000
            Protected menuContainerIndex = Mod(menuEvent/10, 10)
            Protected menuId = menuEvent - 1000 - menuContainerIndex*10
            Select menuId
              Case 0
                HideWindow(Window, #False)
                CompilerIf #PB_Compiler_OS = #PB_OS_Windows : SetOverlayIcon(WindowID(Window), menuContainerIndex) : CompilerEndIf
              Case 1
                ShowLogs(menuContainerIndex)
              Case 2
                For i = 0 To containerCount-1
                  If dockerProgramID(i) <> 0
                    CloseProgram(dockerProgramID(i))
                    dockerProgramID(i) = 0
                  EndIf
                Next
                ProcedureReturn #False
            EndSelect
          EndIf
          
        Case #PB_Event_Timer
          
          If notificationRunningWinID <> 0 And Window = notificationRunningWinID
            RemoveWindowTimer(notificationRunningWinID, #Notification_Running_TimerID)
            CloseWindow(notificationRunningWinID)
            notificationRunningWinID = 0
          EndIf
          If notificationWinID <> 0 And Window = notificationWinID
            RemoveWindowTimer(notificationWinID, #Notification_TimerID)
            CloseWindow(notificationWinID)
            notificationWinID = 0
          EndIf
      EndSelect
    EndProcedure 
    
    
    Procedure StartApp()
      UseModule App
      UseModule WindowManager
      UseModule MainWindow
      index = 0
      
      monitorConfiguration(index)\type = #COMMAND
      
      monitorConfiguration(index)\content =  "docker exec -i my-app /bin/sh -c " + Chr(34) + 
                                             "cd /app && ls -la && npx ng serve --host 0.0.0.0 --poll=2000" + Chr(34)
      
      monitorConfiguration(index)\content =  "docker exec -it my-app /bin/sh" + Chr(10) +
                                             "cd /app" + Chr(10) +
                                             "ls -la" + Chr(10) +
                                             "npx ng serve --host 0.0.0.0 --poll=2000" + Chr(10) +
                                             "exit" + Chr(10) +
                                             "echo Done"
      
      monitorConfiguration(index)\content = "docker exec -it my-app /bin/sh" + Chr(10) +
                                            "cd /app" + Chr(10) +
                                            "ls -la" + Chr(10) +
                                            "npx ng build" + Chr(10) +
                                            "exit" + Chr(10) +
                                            "echo Done"
      
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SetWindowCallback(@WindowCallback())
      CompilerEndIf
      
      LoadSettings()
      
      DPI_Scale.f = DesktopResolutionX()
      If DPI_Scale <= 0
        DPI_Scale = 1.0
      EndIf
      
      
      AppWindow::CreateWindow()
      
      
      MonitorDialog::CreateWindow()
      
      MainWindow::Open()           
      AppWindow::Open()
      
      MonitorDialog::Open()
      
      RunEventLoop(@HandleMainEvent())
      
      
    EndModule
    
    
    
  EndProcedure
  
  Execute::StartApp()
  ; Cleanup
  
  WindowManager::CleanupManagedWindows()
  App::CleanupApp() 
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 5201
; FirstLine = 5184
; Folding = ----------------------------------------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = Docker Status.exe
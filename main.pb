; -------------------- CONSTANTS --------------------

#APP_TITLE = "Docker Status"

#MAX_CONTAINERS = 1000
#MAX_PATTERNS = 1000
#MAX_LINES = 1000

#ICON_SIZE = 64

#JSON_SAVE = 0
#JSON_LOAD = 1

; -------------------- GLOBAL VARIABLES --------------------

Structure ContainerOutput
  List lines.s()
  currentLine.q
EndStructure

Structure LogWindow
  winID.i
  editorGadgetID.i
  containerIndex.i
EndStructure

Global NewList logWindows.LogWindow()

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

Global patCol = 0
Global bgCol = 0
Global currentContainerIndex = 0
Global currentPatternIndex = 0

Global lastTimeOuputAdded = 0

Enumeration KeyboardEvents
  #EventOk
EndEnumeration

IncludeFile "utils.pb"
IncludeFile "winTheme.pb"



; Apply Theme
Procedure ApplyTheme(winID)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected hWnd = WindowID(winID)
    ApplyThemeHandle(hWnd)
  CompilerEndIf
EndProcedure


; Window Fade In without flicker
Procedure ShowWindowFadeIn(winID)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected hWnd = WindowID(winID)
    ; Show window invisible to force rendering
    ShowWindow_(hWnd, #SW_SHOWNA)  
    UpdateWindow_(hWnd)
    RedrawWindow_(hWnd, #Null, #Null, #RDW_UPDATENOW | #RDW_ALLCHILDREN | #RDW_FRAME)
    While PeekMessage_(@msg, hWnd, #WM_PAINT, #WM_PAINT, #PM_REMOVE)
      DispatchMessage_(@msg)
    Wend
    ; Process all events
    Repeat : Delay(1) : Until WindowEvent() = 0
    ; Now fade in with everything rendered
    Protected hUser32 = OpenLibrary(#PB_Any, "user32.dll")
    If hUser32
      Protected *AnimateWindow = GetFunction(hUser32, "AnimateWindow")
      If *AnimateWindow
        CallFunctionFast(*AnimateWindow, hWnd, 300, $80000 | $20000)
      EndIf
      CloseLibrary(hUser32)
    EndIf
  CompilerElse
    HideWindow(winID,#False)
  CompilerEndIf 
EndProcedure

; Window Callback

Procedure WindowCallback(hwnd, msg, wParam, lParam)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected bg.l, fg.l
    If IsDarkModeActiveCached
      bg = RGB(30, 30, 30)
      fg = RGB(220, 220, 220)
    Else
      bg = RGB(255, 255, 255)
      fg = RGB(0, 0, 0)
    EndIf
    Protected parentBrush.i
    Select msg
      Case #WM_SETTINGCHANGE
        If lParam
          Protected *themeName = lParam
          Protected themeName.s = PeekS(*themeName)
          If themeName = "ImmersiveColorSet"
            IsDarkModeActive()
            If themeBgBrush
              DeleteObject_(themeBgBrush)
            EndIf 
            If IsDarkModeActiveCached
              bg = RGB(30, 30, 30)
            Else
              bg = RGB(255, 255, 255)
            EndIf
            themeBgBrush = CreateSolidBrush_(bg)
            ApplyThemeHandle(hwnd)
            InvalidateRect_(hwnd, #Null, #True)
          EndIf
        EndIf  
      Case #WM_CTLCOLORBTN  ; For checkboxes and buttons
        ; Set text color based on current theme
        SetTextColor_(wParam, fg)
        SetBkMode_(wParam, #TRANSPARENT)
        ; Return parent's background brush
        parentBrush = GetClassLongPtr_(hwnd, #GCL_HBRBACKGROUND)
        If parentBrush
          ProcedureReturn parentBrush
        Else
          ProcedureReturn GetStockObject_(#NULL_BRUSH)
        EndIf
      Case #WM_CTLCOLORSTATIC  ; For static text
        ; Set text color based on current theme (not just dark mode!)
        SetTextColor_(wParam, fg)
        SetBkMode_(wParam, #TRANSPARENT)
        ; Return parent's background brush
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


IncludeFile "winIcon.pb"


; -------------------- JSON FILE --------------------
Global settingsFile.s = "docker_status.json"

; -------------------- SAVE/LOAD PROCEDURES --------------------
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
    ; Write to file
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
        ; Directly read fields
        containerName(containerCount)     = ContainerList()\name
        bgColor(containerCount)          = ContainerList()\bgColor
        innerColor(containerCount)       = ContainerList()\innerColor
        neutralInnerColor(containerCount) = ContainerList()\neutralInnerColor
        containerStarted(containerCount)= ContainerList()\containerStarted
        containterMetaData(containerCount)\logWindowX = ContainerList()\logX
        containterMetaData(containerCount)\logWindowY = ContainerList()\logY
        containterMetaData(containerCount)\logWindowW = ContainerList()\logW
        containterMetaData(containerCount)\logWindowH = ContainerList()\logH
        patternCount(containerCount) = 0
        ForEach ContainerList()\patterns()
          patterns(containerCount, patternCount(containerCount))     = ContainerList()\patterns()\pattern
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



; Systra Notifications

#Notification_Running_TimerID = 1 ; A unique ID for the timer
#Notification_Duration = 2500     ; 5000 ms = 5 seconds
#Notification_Width = 200
#Notification_Height = 50


Global notificationRunningWinID = 0
; Procedure to create and show the notification
Procedure ShowSystrayRunningNotification(index)
  ExamineDesktops()
  w = DesktopUnscaledX(DesktopWidth(0))
  h = DesktopUnscaledY(DesktopHeight(0))
  winID  = OpenWindow(#PB_Any, w - #Notification_Width - 10 - 10, h - #Notification_Height - 10 - 80, #Notification_Width, #Notification_Height, "", #PB_Window_BorderLess | #PB_Window_Tool |#PB_Window_Invisible      )
  If winID
    StickyWindow(winID,#True)
    textGadget = TextGadget(#PB_Any, 30, 5, #Notification_Width-20, 20, "Docker Status is running",#PB_Text_Center )
    ImageGadget(#PB_Any,14, 0,26,26,ImageID(infoImageRunningID(index)),  #PB_Image_Raised)
    If notificationRunningWinID <>0
      CloseWindow(notificationRunningWinID)
      notificationRunningWinID = 0
    EndIf
    notificationRunningWinID = winID
    AddWindowTimer(winID, #Notification_Running_TimerID, #Notification_Duration)
    
    ApplyTheme(winID)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(winID)
   
  EndIf
EndProcedure

Global notificationWinID = 0
Global notificationTextGadgetID = 0
Global notificationImageGadgetID = 0

#Notification_Large_Width = 270
#Notification_TimerID = 2
#Notification_Long_Duration = 5000

Procedure ShowSystrayNotification(index, text.s)
  If ElapsedMilliseconds()-containerStartedTime(index) < 5000
    ProcedureReturn
  EndIf 
  RemoveWindowTimer(notificationWinID, #Notification_TimerID)
  If notificationWinID <>0
    SetGadgetText(notificationTextGadgetID,text)
    SetGadgetState(notificationImageGadgetID,ImageID(infoImageRunningID(index)))
    AddWindowTimer(notificationWinID, #Notification_TimerID, #Notification_Long_Duration)
  Else
    ExamineDesktops()
    w = DesktopUnscaledX(DesktopWidth(0))
    h = DesktopUnscaledY(DesktopHeight(0))
    winID  = OpenWindow(#PB_Any, w - #Notification_Large_Width - 10 - 10, h - #Notification_Height - 10 - 80, #Notification_Large_Width, #Notification_Height, "", #PB_Window_BorderLess | #PB_Window_Tool |#PB_Window_Invisible      )
    If winID
      StickyWindow(winID,#True)
      notificationTextGadgetID = TextGadget(#PB_Any, 50, 5, #Notification_Large_Width-64, 20, text,#PB_Text_Center )
      notificationImageGadgetID = ImageGadget(#PB_Any,14, 0,26,26,ImageID(infoImageRunningID(index)),  #PB_Image_Raised)
      notificationWinID = winID
      AddWindowTimer(winID, #Notification_TimerID, #Notification_Long_Duration)
      ApplyTheme(winID)
      Repeat :Delay(1): Until WindowEvent() = 0
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

; -------------------- SET LIST ITEM STARTED --------------------

Procedure SetListItemStarted(index,started)
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
      VectorSourceColor(RGBA(0,147,242, 255))
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
    SetGadgetItemImage(0, index, ImageID(  img))
  EndIf
EndProcedure


; -------------------- LIST ITEM COLOR --------------------

Procedure SetListItemColor(gadgetID, index, color)
  Protected img = CreateImage(#PB_Any, 1, 1)
  If img
    StartDrawing(ImageOutput(img))
    Box(0,0,1,1,color)
    StopDrawing()
    SetGadgetItemImage(gadgetID, index, ImageID(img))
  EndIf
EndProcedure

; -------------------- BUTTON STATES --------------------

Procedure UpdateButtonStates()
  selIndex = GetGadgetState(0)
  If selIndex >= 0
    DisableGadget(2, #False)
    DisableGadget(5, #False)
    DisableGadget(6, #False)
    If containerStarted(selIndex)
      DisableGadget(3, #True)
      DisableGadget(4, #False)
    Else
      DisableGadget(3, #False)
      DisableGadget(4, #True)
    EndIf
  Else
    DisableGadget(2, #True)
    DisableGadget(3, #True)
    DisableGadget(4, #True)
    DisableGadget(5, #True)
    DisableGadget(6, #True)
  EndIf
EndProcedure

; -------------------- MONITOR LIST --------------------
Procedure UpdateMonitorList()
  ClearGadgetItems(0)
  For i = 0 To containerCount-1
    AddGadgetItem(0, -1, "  "+containerName(i))
    SetListItemStarted(i, containerStarted(i))
  Next
  UpdateButtonStates()
EndProcedure

; -------------------- ADD MONITOR --------------------
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

; -------------------- REMOVE MONITOR --------------------
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
      patterns(i,p) = patterns(i+1,p)
      patternColor(i,p) = patternColor(i+1,p)
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

; -------------------- PATTERNS --------------------
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
      AddGadgetItem(40, -1,"  "+ patterns(index,p))
      SetListItemColor(40, p, patternColor(index,p))
    Next
  EndIf 
EndProcedure
; -------------------- ADD MONITOR DIALOG --------------------
Procedure CloseAddMonitorDialog(bgCol)
  container$ = GetGadgetText(10)
  If container$ <> ""
    AddMonitor(container$, bgCol)
    UpdateMonitorList()
    SetActiveGadget(0)
    SetGadgetItemState(0, containerCount-1, #PB_ListIcon_Selected)
    UpdateButtonStates()
  EndIf
EndProcedure

Procedure AddMonitorDialog()
  If OpenWindow(1, 0, 0, 380, 130, "Add Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_Invisible)
    StringGadget(10, 10, 10, 360, 24, "")
    SetActiveGadget(10)
    AddKeyboardShortcut(1, #PB_Shortcut_Return, #EventOk)
    
    TextGadget(11, 10, 53, 100, 24, "Background Color:")
    ContainerGadget(14, 120, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(12, 150, 50, 100, 24, "Choose...")
    ButtonGadget(13, 80, 100, 80, 24, "OK")
    ButtonGadget(15, 170, 100, 80, 24, "Cancel")
    
    bgCol = RGB(200,200,200)
    SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
    DisableGadget(13, #True)
    
    StickyWindow(1,#True)
    
    ApplyTheme(1)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(1)
  EndIf
EndProcedure

; -------------------- EDIT MONITOR DIALOG --------------------
Procedure EditMonitorDialog(selIndex)
  container$ = containerName(selIndex)
  bgCol      = bgColor(selIndex)
  
  If OpenWindow(5, 0, 0, 380, 130, "Edit Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_Invisible)
    StringGadget(50, 10, 10, 360, 24, container$)
    SetActiveGadget(50)
    
    TextGadget(51, 10, 53, 100, 24, "Background Color:")
    ContainerGadget(54, 120, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(52, 150, 50, 100, 24, "Choose...")
    ButtonGadget(53, 80, 100, 80, 24, "OK")
    ButtonGadget(55, 170, 100, 80, 24, "Cancel")
    
    SetGadgetColor(54, #PB_Gadget_BackColor, bgCol)
    If container$ = ""
      DisableGadget(53, #True)
    EndIf
    
    StickyWindow(5,#True)
    
    ApplyTheme(5)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(5)
    
  EndIf
EndProcedure


; -------------------- ADD PATTERN --------------------
Procedure AddPattern(index, pat.s, color.l,notification)
  If index < 0 Or index >= containerCount
    ProcedureReturn
  EndIf
  If patternCount(index) >= #MAX_PATTERNS
    ProcedureReturn
  EndIf
  patterns(index, patternCount(index)) = pat
  patternColor(index, patternCount(index)) = color
  patternsNotification(index,patternCount(index)) = notification
  
  patternCount(index) + 1
  SaveSettings()
EndProcedure

; -------------------- ADD PATTERN DIALOG --------------------
Procedure AddPatternDialog(monitorIndex)
  If OpenWindow(2,0,0,380,170,"Add Status Log Pattern",#PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_Invisible)
    StringGadget(20,10,10,360,24,"")
    SetActiveGadget(20)
    TextGadget(21,10,53,100,24,"Pattern Color:")
    ContainerGadget(24,95,50,24,24,#PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(22,125,50,100,24,"Choose...")
    
    
    
    ; --- New alert section (spaced 10px above/below) ---
    CheckBoxGadget(26, 10, 90, 15, 24, "")
    HyperLinkGadget(27, 30, 90, 100, 24, "Show notification",0) ; color via callback on Windows
    
    ; ---------------------------------------------------
    
    ; Centered OK/Cancel buttons, same close spacing as before
    Protected buttonWidth = 80
    Protected buttonSpacing = 10   ; closer, like your original layout
    Protected totalWidth = buttonWidth * 2 + buttonSpacing
    Protected startX = (380 - totalWidth) / 2
    
    ButtonGadget(23, startX, 140, buttonWidth, 24, "OK")
    ButtonGadget(25, startX + buttonWidth + buttonSpacing, 140, buttonWidth, 24, "Cancel")
    
    
    
    
    DisableGadget(23,#True)
    
    patCol = RGB(255,0,0)
    SetGadgetColor(24,#PB_Gadget_BackColor,patCol)
    StickyWindow(2,#True)
    ApplyTheme(2)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(2)
  EndIf
EndProcedure

; -------------------- EDIT PATTERN DIALOG --------------------
Procedure EditPatternDialog(index, selIndex)
  pattern.s = patterns(index, selIndex)
  patCol = patternColor(index, selIndex)
  If OpenWindow(3, 0, 0, 380, 170, "Edit Status Filter Rules", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible)
    StringGadget(30, 10, 10, 360, 24, pattern)
    SetActiveGadget(30)
    TextGadget(31, 10, 53, 100, 24, "Pattern Color:")
    ContainerGadget(34, 95, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(32, 125, 50, 100, 24, "Choose...")
    
    ; --- New alert section (spaced 10px above/below) ---
    CheckBoxGadget(36, 10, 90, 15, 24, "")
    HyperLinkGadget(37, 30, 90, 100, 24, "Show notification",0) ; color via callback on Windows
    
    ; ---------------------------------------------------
    
    ; Centered OK/Cancel buttons, same close spacing as before
    Protected buttonWidth = 80
    Protected buttonSpacing = 10   ; closer, like your original layout
    Protected totalWidth = buttonWidth * 2 + buttonSpacing
    Protected startX = (380 - totalWidth) / 2
    
    ButtonGadget(33, startX, 140, buttonWidth, 24, "OK")
    ButtonGadget(35, startX + buttonWidth + buttonSpacing, 140, buttonWidth, 24, "Cancel")
    
    SetGadgetColor(34, #PB_Gadget_BackColor, patCol)
    SetGadgetState(36,patternsNotification(currentContainerIndex,currentPatternIndex))
    
    StickyWindow(3, #True)
    ApplyTheme(3)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(3)
  EndIf
EndProcedure



Procedure EditPatternsDialog(index)
  If index < 0 Or index >= containerCount
    ProcedureReturn
  EndIf
  If OpenWindow(4,150,150,420,450,"Edit Status Filter Rules",#PB_Window_SystemMenu | #PB_Window_ScreenCentered|#PB_Window_Invisible)
    ListIconGadget(40,10, 10, 300, 430,"Status Log Filter Rules",295,#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection):ApplySingleColumnListIcon(GadgetID(40))
    ButtonGadget(41, 325, 10, 80, 24, "Add")
    ButtonGadget(43, 325, 40, 80, 24, "Remove")
    ButtonGadget(42, 325, 80, 80, 24, "Edit")
    ButtonGadget(44, 325, 417, 80, 24, "Ok")
    
    
    UpdatePatternList(index)
    UpdatePatternButtonStates()
    
    StickyWindow(4,#True)
    ApplyTheme(4)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(4)
  EndIf
EndProcedure

; -------------------- DOCKER EXECUTABLE --------------------
Procedure.s TryDockerDefaultPaths()
  Protected dockerPaths.s
  Protected dockerPath.s
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
    folder = StringField(pathEnv, index,";")
    Protected candidate.s = folder + "\docker.exe"
    If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
    candidate = folder + "\Docker.exe"
    If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
    index + 1
  Until folder = ""
  ProcedureReturn TryDockerDefaultPaths()
EndProcedure



; -------------------- STOP DOCKER FOLLOW --------------------
Procedure StopDockerFollow(index)
  If notificationRunningWinID <>0
    CloseWindow(notificationRunningWinID)
    notificationRunningWinID = 0
  EndIf
  If notificationWinID <>0
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
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows:RemoveOverlayIcon(WindowID(0)):CompilerEndIf
  ForEach logWindows()
    If logWindows()\containerIndex = index
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows:RemoveOverlayIcon(WindowID(logWindows()\winID)):CompilerEndIf
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
  SetListItemStarted(index,#False)
  SetActiveGadget(0)
  SetGadgetItemState(0,index,#PB_ListIcon_Selected)
  UpdateButtonStates()
  containerStartedTime(index) = ElapsedMilliseconds()
EndProcedure
; -------------------- START DOCKER FOLLOW --------------------
Procedure StartDockerFollow(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  
  dockerExecutable$ = GetDockerExcutable()
  container$ = containerName(index)
  
  ProgramID =  RunProgram(dockerExecutable$, "inspect -f {{.State.Running}} " + container$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Hide)
  
  If ProgramID = 0 Or Not IsProgram(ProgramID) Or Not ProgramRunning(ProgramID)
    If containerStarted(index)
      StopDockerFollow(index)
    EndIf
    ProcedureReturn
  EndIf
  
  ; Check if container started
  Repeat
    dataRead = #False ; Reset for this iteration
    Repeat
      line.s = ReadProgramError(ProgramID) 
      If Trim(line) <> ""
        StopDockerFollow(index)
        MessageRequester(#APP_TITLE, line)
        ProcedureReturn 
      EndIf
      
      
    Until line = "" ; Loop until ReadProgramError returns an empty string
    
    programOutput = AvailableProgramOutput(ProgramID)
    
    If  programOutput > 0
      
      
      line = ReadProgramString(ProgramID)    
      If FindString(line,"false")>0
        StopDockerFollow(index)
        MessageRequester(#APP_TITLE, "Container '" + container$ + "' is not running.")
        ProcedureReturn
      ElseIf FindString(line,"true")>0
        Break
      EndIf 
      If line <> ""
        dataRead = #True
      EndIf
    EndIf
    
    WindowEvent()
    Delay(1)
  Until dataRead = #False And #False
  
  dockerCommand$ = "/c " + Chr(34) + dockerExecutable$  +Chr(34) +" logs --follow --tail 1000 " + container$ 
  dockerProgramID(index) = RunProgram("cmd.exe", dockerCommand$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read| #PB_Program_Hide );
  
  If trayID(index) = 0
    CreateMonitorIcon(index, innerColor(index), bgColor(index))
  EndIf
  containerStarted(index) = #True
  SetListItemStarted(index,#True)
  
  ShowSystrayRunningNotification(index)
  
  ClearList(containerOutput(index)\lines())
  containerOutput(index)\currentLine = 0
  
  currentLine = 0;
  
EndProcedure


; -------------------- UPDATE MONITOR ICON ON MATCH --------------------

Procedure.s CleanTooltip(s.s)
  For i = 0 To 31
    If i <> 9 And i <> 10
      s =  ReplaceString(s, Chr(i), "")
    EndIf
  Next
  ProcedureReturn s
EndProcedure



Procedure UpdateMonitorIcon(index, matchColor)
  containerStatusColor(index) = matchColor
  CreateMonitorIcon(index, matchColor, bgColor(index))
  info$ =  tooltip(index) 
  If Len(info$) > 25
    info$ = Left(info$, 25) + "..."
  EndIf
  output$=lastMatch(index)
  If Len(output$) > 25
    output$ = Left(output$,25+MaxI(0,(25-Len(info$)))) + "..."
  EndIf
  If output$ <> ""
    output$ = output$+Chr(10)+ info$+" - "+FormatDate("%hh:%ii", Date())
  Else
    output$ = info$
  EndIf 
  SysTrayIconToolTip(trayID(index),output$ )
  
  ForEach logWindows()
    If logWindows()\containerIndex = index
      SetWindowTitle(logWindows()\winID,containerName(index)+" - "+lastMatch(index))
      Break
    EndIf
  Next
  
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetOverlayIcon(WindowID(0),index):CompilerEndIf
EndProcedure

Procedure OnMatch(index, patternIndex , line.s, hideNotification = #False)
  lastMatch(index) = line
  lastMatchTime(index) = ElapsedMilliseconds()
  lastMatchPattern(index) = patternIndex
  UpdateMonitorIcon(index, patternColor(index,lastMatchPattern(index)))
  If Not hideNotification And  patternsNotification(index,patternIndex) = #True
    ShowSystrayNotification(index,line)
  EndIf 
EndProcedure

Procedure.s RemoveFirstLineFromText(Text.s)
  Protected LineBreakPos.i
  Protected NewText.s
  
  ; Find the position of the first line break (Chr(10) / Line Feed)
  ; Note: Text files often use Chr(13) + Chr(10) (CRLF), so searching for Chr(10) is safer.
  LineBreakPos = FindString(Text, Chr(10), 1)
  
  If LineBreakPos > 0
    ; Return the substring starting just after the line break.
    ; This effectively skips the first line and the line break itself.
    NewText = Mid(Text, LineBreakPos + 1)
  Else
    ; If no line break is found, the text only has one line, so clear it.
    NewText = ""
  EndIf
  
  ProcedureReturn NewText
EndProcedure






#ST_DEFAULT = 0    ; Replace entire text
#ST_SELECTION = 1  ; Insert at selection
#ST_SELECTION = 1  ; Not used, but kept for reference
#ECO_READONLY = $800  ; 0x800 for read-only flag


#CFM_COLOR = $40000000
#CFE_AUTOCOLOR = $40000000


#CFM_COLOR = $40000000



Procedure AddOutputLines(index, editorGadgetID, lines.s)
  Debug "AddOutputLines"
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    
    Protected hEditor = GadgetID(editorGadgetID)
    If Not hEditor
      ProcedureReturn
    EndIf
    ; Check if at scroll bottom
    Protected wasAtScrollBottom = IsAtScrollBottom(editorGadgetID)
    
    ; Disable redraw to prevent flickering
    SendMessage_(hEditor, #WM_SETREDRAW, #False, 0)
    
    ; Get current text for debugging
    Protected text.s = GetEditorGadgetText(hEditor)
    
    ; Check if read-only
    Protected options.l = SendMessage_(hEditor, #EM_GETOPTIONS, 0, 0)
    Protected isReadOnly = Bool(options & #ECO_READONLY)
    
    ; Temporarily disable read-only if needed
    If isReadOnly
      SendMessage_(hEditor, #EM_SETREADONLY, #False, 0)
    EndIf
    ; Save current scroll position if not at bottom (AFTER deletion)
    Protected scrollPos.POINT
    If Not wasAtScrollBottom
      SendMessage_(hEditor, #EM_GETSCROLLPOS, 0, @scrollPos)
      Debug "Saved scroll position: X=" + Str(scrollPos\x) + ", Y=" + Str(scrollPos\y)
    EndIf
    ; Count how many lines we're about to add
    Protected newLinesToAdd.l = 1 ; At least one line
    Protected i.l
    For i = 1 To Len(lines)
      If Mid(lines, i, 1) = Chr(10)
        newLinesToAdd + 1
      EndIf
    Next
    Debug "Lines to add: " + Str(newLinesToAdd)
    
    ; Handle line limit - delete as many lines as we're adding
    Protected lineCount.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
    Protected lineCountBeforeDeletion.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
    
    If lineCount + newLinesToAdd > #MAX_LINES
      Protected linesToDelete.l = (lineCount + newLinesToAdd) - #MAX_LINES
      Debug "Current line count: " + Str(lineCount) + ", Lines to delete: " + Str(linesToDelete)
      
      ; Delete multiple lines from the top
      Protected startSel.l, endSel.l
      For i = 1 To linesToDelete
        ; Select the first line
        Protected startPos.l = SendMessage_(hEditor, #EM_LINEINDEX, 0, 0)
        Protected firstLineLen.l = SendMessage_(hEditor, #EM_LINELENGTH, startPos, 0)
        Protected endPos.l = startPos + firstLineLen + 2 ; Include CRLF
        SendMessage_(hEditor, #EM_SETSEL, startPos, endPos)
        SendMessage_(hEditor, #EM_GETSEL, @startSel, @endSel)
        Debug "Deleting line " + Str(i) + "/" + Str(linesToDelete) + ", Selection: Start = " + Str(startSel) + ", End = " + Str(endSel)
        
        ;       ; Debug first line content
        ;       Protected *buffer = AllocateMemory((firstLineLen + 3) * SizeOf(Character))
        ;       If *buffer
        ;         PokeW(*buffer, firstLineLen) ; Set length for EM_GETLINE
        ;         SendMessage_(hEditor, #EM_GETLINE, 0, *buffer)
        ;         Protected firstLineText.s = PeekS(*buffer, -1, #PB_Unicode)
        ;         Debug "Deleting line text: '" + firstLineText + "'"
        ;         FreeMemory(*buffer)
        ;       EndIf
        
        ; Delete by replacing with empty string
        SendMessage_(hEditor, #EM_REPLACESEL, #True, @"")
        
      Next
    EndIf
    Protected lineCountAfterDeletion.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
    Protected linesDeleted.l = lineCountBeforeDeletion - lineCountAfterDeletion
    Debug "Lines actually deleted: " + Str(linesDeleted) + " (before: " + Str(lineCountBeforeDeletion) + ", after: " + Str(lineCountAfterDeletion) + ")"
    
    
    
    ; Get line count BEFORE append (after deletion if any)
    Protected oldLineCount.l = lineCountAfterDeletion
    
    ; Append new lines at the end
    Protected textLen.l = SendMessage_(hEditor, #WM_GETTEXTLENGTH, 0, 0)
    SendMessage_(hEditor, #EM_SETSEL, textLen, textLen) ; Select end of text
    SendMessage_(hEditor, #EM_GETSEL, @startSel, @endSel)
    
    ; Reset character format to match current theme before inserting
    Protected cf.CHARFORMAT2
    cf\cbSize = SizeOf(CHARFORMAT2)
    cf\dwMask = #CFM_COLOR
    cf\dwEffects = 0  ; No special effects, we'll set explicit color
                      ; Get the appropriate text color based on theme
    If IsDarkModeActiveCached
      cf\crTextColor = RGB(255, 255, 255)  ; White for dark theme
    Else
      cf\crTextColor = RGB(0, 0, 0)  ; Black for light theme
    EndIf
    SendMessage_(hEditor, #EM_SETCHARFORMAT, #SCF_SELECTION, @cf)
    
    Protected appendText.s = Chr(13) + Chr(10) + lines ; Use CRLF for Windows Rich Edit
    Result = SendMessage_(hEditor, #EM_REPLACESEL, #True, @appendText)
    
    ; Verify text length after append
    Protected newTextLen.l = SendMessage_(hEditor, #WM_GETTEXTLENGTH, 0, 0)
    
    ; Calculate number of new lines using editor's line count
    Protected newLineCount.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
    Protected newLinesCount.l = newLineCount - oldLineCount
    If lines = "" And newLinesCount = 1 ; If only empty newline added
      newLinesCount = 0
    EndIf
    
    ; Restore read-only if it was set
    If isReadOnly
      SendMessage_(hEditor, #EM_SETREADONLY, #True, 0)
    EndIf
    
    ; Color the new lines (or all text if newLinesCount = 0)
    SetEditorTextColor(index, newLinesCount)
    
    ; Get line height for scroll adjustment
    Protected firstCharIndex.l = SendMessage_(hEditor, #EM_LINEINDEX, 0, 0)
    Protected pt.POINT
    SendMessage_(hEditor, #EM_POSFROMCHAR, @pt, firstCharIndex)
    Protected firstLineY.l = pt\y
    Protected secondCharIndex.l = SendMessage_(hEditor, #EM_LINEINDEX, 1, 0)
    SendMessage_(hEditor, #EM_POSFROMCHAR, @pt, secondCharIndex)
    Protected secondLineY.l = pt\y
    Protected lineHeight.l = secondLineY - firstLineY
    Debug "Calculated line height: " + Str(lineHeight)
    
    
    ; Restore scroll position based on where user was
    Debug "wasAtScrollBottom: " + Str(wasAtScrollBottom)
    If wasAtScrollBottom
      Debug "Scrolling to bottom -"+ Str(lineHeight * linesDeleted)
      ScrollEditorToBottom(editorGadgetID)
    Else
      Debug "Scrolling to "+Str(scrollPos\y)+" -"+ Str(lineHeight * linesDeleted)
      
      ;         indicateHeight = linesDeleted
      ;         If indicateHeight>lineHeight*5
      ;           indicateHeight = lineHeight*5
      ;         EndIf 
      
      
      
      scrollPos\y  =   scrollPos\y - (lineHeight * linesDeleted) ; +  indicateHeight ; indicateHeight to indicate someting happened
      If scrollPos\y < 0
        scrollPos\y = 0
      EndIf
      Debug "Restoring scroll position: X=" + Str(scrollPos\x) + ", Y=" + Str(scrollPos\y)
      SendMessage_(hEditor, #EM_SETSCROLLPOS, 0, @scrollPos)
    EndIf
    ; Re-enable redraw and force repaint
    SendMessage_(hEditor, #WM_SETREDRAW, #True, 0)
    ;InvalidateRect_(hEditor, #Null, #True)
    UpdateWindow_(hEditor)
    
  CompilerElse
    text.s = GetGadgetText(editorGadgetID)
    
    ListSize = ListSize(containerOutput(index)\lines()) 
    If ListSize >= #MAX_LINES
      text = RemoveFirstLineFromText(text.s)
    EndIf
    wasAtScrollBottom = IsAtScrollBottom(editorGadgetID)
    
    SetGadgetText(editorGadgetID,text+Chr(10)+lines)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetEditorTextColor(index,#True):CompilerEndIf
    
    If wasAtScrollBottom
      ScrollEditorToBottom(editorGadgetID)
    EndIf
  CompilerEndIf
  
EndProcedure



; -------------------- CHECK DOCKER OUTPUT --------------------

Procedure HandleInputLine(index,line$, addLine = #True)
  If addLine
    LastElement(containerOutput(index)\lines())
    AddElement(containerOutput(index)\lines())
    containerOutput(index)\lines() = line$
    
    ListSize = ListSize(containerOutput(index)\lines())
    
    If ListSize > #MAX_LINES
      FirstElement(containerOutput(index)\lines())
      DeleteElement(containerOutput(index)\lines())
      LastElement(containerOutput(index)\lines())
    EndIf
  EndIf 
  
  For p = 0 To patternCount(index)-1
    If FindString(line$, patterns(index,p), 1) > 0
      OnMatch(index, p, line$,1-addLine)
    Else
      If CreateRegularExpression(0, patterns(index,p))
        If MatchRegularExpression(0, line$)
          OnMatch(index, p, line$,1-addLine)
        EndIf
      EndIf
    EndIf
  Next
  
  
EndProcedure


Procedure HandleInputDisplay(index)
  
  If(ListSize(containerOutput(index)\lines())=0)
    ProcedureReturn
  EndIf 
  
  text$ = ""
  
  If(containerOutput(index)\currentline=0)
    FirstElement(containerOutput(index)\lines())
    currentElement = @containerOutput(index)\lines()
  Else
    ChangeCurrentElement(containerOutput(index)\lines(),containerOutput(index)\currentline)
    currentElement = NextElement(containerOutput(index)\lines())
  EndIf 
  
  lastOutputElement = 0
  While currentElement<> 0 
    text$ =  text$+Chr(10)+containerOutput(index)\lines()
    lastOutputElement = currentElement
    currentElement = NextElement(containerOutput(index)\lines())
  Wend
  
  If lastOutputElement <> 0
    containerOutput(index)\currentline = lastOutputElement
  EndIf 
  
  ;Update log windows
  If text$ <> ""
    ForEach logWindows()
      If logWindows()\containerIndex = index
        AddOutputLines(logWindows()\containerIndex,logWindows()\editorGadgetID,text$) 
      EndIf
    Next
  EndIf 
  
EndProcedure

Procedure.s ReadProgramOutputBytes(ProgramID, length)
  Protected buffer
  Protected bytesRead.l
  
  ; Allocate a memory buffer
  buffer = AllocateMemory(length)
  If buffer = 0
    ProcedureReturn ""
  EndIf
  
  ; Read data from program output
  bytesRead = ReadProgramData(ProgramID, buffer, length)
  
  ; Convert buffer to string
  ProcedureReturn PeekS(buffer, bytesRead, #PB_UTF8   )
EndProcedure

Procedure CheckDockerOutput(index)
  Protected line.s
  Protected ProgramID.i = dockerProgramID(index)
  Protected dataRead.l ; Flag to track if ANY data was read
  
  ; --- 1. Program Termination Check ---
  If ProgramID = 0 Or Not IsProgram(ProgramID) Or Not ProgramRunning(ProgramID)
    If containerStarted(index)
      StopDockerFollow(index)
    EndIf
    ProcedureReturn
  EndIf
  
  ; --- 2. Non-Blocking Read Loop ---
  Repeat
    dataRead = #False ; Reset for this iteration
    
    ; A. Drain Standard Error (stderr) - (ERROR lines)
    ;    ReadProgramError() is NON-BLOCKING. We drain this stream completely
    ;    on every pass, ensuring no error lines are missed or block the buffer.
    Repeat
      
      line = ReadProgramError(ProgramID) 
      
      If FindString(line,"Error response from daemon: No such container:",#PB_String_NoCase       )>0
        StopDockerFollow(index)
        
        MessageRequester("Error",line);
        ProcedureReturn
      EndIf 
      
      If line <> ""
        HandleInputLine(index, line)
        dataRead = #True
      EndIf
    Until line = "" ; Loop until ReadProgramError returns an empty string
    
    ; B. Read Standard Output (stdout) - (NORMAL lines)
    ;    ReadProgramString() is BLOCKING, so we MUST check for data first.
    programOutput = AvailableProgramOutput(ProgramID)
    If  programOutput > 0
      ; Data is available, so ReadProgramString() will not block indefinitely.      
      
      
      output.s = ReadProgramOutputBytes(ProgramID,programOutput)    
      If output <> ""
        
        lineCount = CountString(output, Chr(10)) + 1
        
        ; Loop through each line (1-based!)
        For i = 1 To lineCount
          line.s = Trim(ReplaceString(StringField(output, i, Chr(10)),Chr(13),"")) ; remove any trailing CR/LF or spaces
          If line <> ""
            HandleInputLine(index, line)
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
    
    ; The outer loop ensures that if we read ANYTHING (either from stderr's drain
    ; loop or from stdout), we immediately run the full check again. This is
    ; essential because new data might have arrived during the processing of the last batch.
  Until dataRead = #False 
  
  If ElapsedMilliseconds()-lastTimeOuputAdded>50
    lastTimeOuputAdded = ElapsedMilliseconds()
    HandleInputDisplay(index)
  EndIf 
  
  
  
EndProcedure






; -------------------- IS RUNNING --------------------


Procedure IsRunning()
  For i = 0 To containerCount-1
    If containerStarted(i)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure



; -------------------- SHOW LOGS --------------------





Procedure ResizeLogWindow()  
  ForEach logWindows()
    If logWindows()\winID = EventWindow()
      
      CurrentW =WindowWidth(EventWindow())
      CurrentH =WindowHeight(EventWindow())
      If CurrentW >= 0 And CurrentH >= 0
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
          ResizeGadget(logWindows()\editorGadgetID, -2, -2, CurrentW+4, CurrentH+4) ;dark mode no border
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
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetOverlayIcon(WindowID(logWindows()\winID),logWindows()\containerIndex):CompilerEndIf
      
      If GetWindowState(logWindows()\winId) = #PB_Window_Minimize Or GetWindowState(logWindows()\winId) = #PB_Window_Maximize
        SetWindowState(logWindows()\winId,#PB_Window_Normal) 
      Else
        SetWindowState(logWindows()\winId,#PB_Window_Minimize) 
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
    text$ =  text$+Chr(10)+containerOutput(index)\lines()
  Next
  
  
  ; Open non-blocking window
  If containterMetaData(index)\logWindowW = 0 And containterMetaData(index)\logWindowH = 0
    containterMetaData(index)\logWindowW = 600
    containterMetaData(index)\logWindowH = 400
  EndIf
  
  If containterMetaData(index)\logWindowX = 0 And containterMetaData(index)\logWindowY = 0
    WindowFlags =  #PB_Window_SystemMenu|  #PB_Window_MaximizeGadget|   #PB_Window_MinimizeGadget |#PB_Window_ScreenCentered
  Else
    WindowFlags = #PB_Window_SystemMenu|   #PB_Window_MaximizeGadget|  #PB_Window_MinimizeGadget
  EndIf
  
  
  
  winID = OpenWindow(#PB_Any, containterMetaData(index)\logWindowX, containterMetaData(index)\logWindowY, containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, containerName(index), WindowFlags |#PB_Window_SizeGadget |#PB_Window_Invisible)
  If winID
    SetWindowColor(winID,RGB(0,0,0))
    
    StickyWindow(winID,#True) 
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      editorID = EditorGadget(#PB_Any, -2, -2,  containterMetaData(index)\logWindowW+4, containterMetaData(index)\logWindowH+4,  #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      ;dark mode no border
    CompilerElse
      editorID = EditorGadget(#PB_Any, 0, 0,  containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    CompilerEndIf 
    containerLogEditorID(index) = editorID
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    LoadLibrary_("Msftedit.dll")
    SendMessage_(GadgetID(editorID), #EM_SETTEXTMODE, #TM_RICHTEXT, 0)
    SetFixedLineHeight(GadgetID(editorID), #EDITOR_LINE_HEIGHT)
    CompilerEndIf
    ; Enable anti-aliasing with cross-platform font selection
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
    ;SetGadgetColor(editorID,#PB_Gadget_FrontColor,RGB(200,200,200)) 
    ; SetGadgetColor(editorID, #PB_Gadget_BackColor ,RGB(20,0,0)) 
    
    AddElement(logWindows())
    logWindows()\winID = winID
    logWindows()\editorGadgetID = editorID
    logWindows()\containerIndex = index
    BindEvent(#PB_Event_SizeWindow, @ResizeLogWindow(),winID)
    BindEvent(#PB_Event_CloseWindow, @CloseLogWindow(),winID)
    BindEvent(#PB_Event_MoveWindow, @MoveLogWindow(),winID)
    
    SetGadgetText(editorID,text$)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetEditorTextColor( index):CompilerEndIf
    
    ScrollEditorToBottom(editorID)
    
    ApplyTheme(winID)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(winID)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows:CreateWindowIcon(winID,index):CompilerEndIf
    UpdateMonitorIcon(index, patternColor(index,lastMatchPattern(index)))
    
    ScrollEditorToBottom(editorID)
    
  EndIf
EndProcedure




Procedure StartApp()
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    IsDarkModeActive()
    SetWindowCallback(@WindowCallback())
  CompilerEndIf
  If OpenWindow(0,0,0,420,300,#APP_TITLE,#PB_Window_SystemMenu  | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered | #PB_Window_Invisible)
    ; Gadgets
    ListIconGadget(0, 10, 10, 300, 280,"Container",295,#PB_ListIcon_FullRowSelect):ApplySingleColumnListIcon(GadgetID(0))
    ButtonGadget(1, 325, 10, 80, 24, "Add")
    ButtonGadget(6, 325, 40, 80, 24, "Edit")
    ButtonGadget(2, 325, 70, 80, 24, "Remove")
    ButtonGadget(5, 325, 110, 80, 24, "Rules")
    ButtonGadget(3, 325, 150, 80, 24, "Start")
    ButtonGadget(4, 325, 180, 80, 24, "Stop")
    
    
    LoadSettings()
    UpdateMonitorList()
    
    ApplyTheme(0)
    Repeat :Delay(1): Until WindowEvent() = 0
    ShowWindowFadeIn(0)
    
  Else
    End 
  EndIf
  
  
  
  ; -------------------- MAIN EVENT LOOP --------------------
  Repeat
    Event = WindowEvent()
    Window = EventWindow()
    
    If Event = #PB_Event_Timer
      If notificationRunningWinID <> 0 And Window = notificationRunningWinID
        RemoveWindowTimer(notificationRunningWinID, #Notification_Running_TimerID)
        CloseWindow(notificationRunningWinID)
        notificationRunningWinID = 0
        
      EndIf
      If  notificationWinID <> 0 And Window = notificationWinID 
        RemoveWindowTimer(notificationWinID, #Notification_TimerID)
        CloseWindow(notificationWinID)
        notificationWinID = 0
        
      EndIf
    EndIf     
    
    Select Window 
      Case 0:
        If Event
          Select Event
            Case #PB_Event_SysTray
              systrayId = EventGadget() 
              For i = 0 To containerCount-1
                If systrayId = trayID(i)
                  ShowLogs(i)
                  Break
                EndIf 
              Next
            Case #PB_Event_Menu
              menuEvent = EventMenu()
              If menuEvent>=1000
                menuContainerIndex = Mod(menuEvent/10,10)
                menuId = menuEvent-1000-menuContainerIndex*10
                Select menuId
                  Case 0
                    HideWindow(0,#False)
                    CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetOverlayIcon(WindowID(0),menuContainerIndex):CompilerEndIf
                    
                  Case 1
                    ShowLogs(menuContainerIndex)
                  Case 2 ; Exit 
                    For i = 0 To containerCount-1
                      If dockerProgramID(i) <> 0 : CloseProgram(dockerProgramID(i)) : dockerProgramID(i) = 0 : EndIf
                    Next
                    End
                    End
                EndSelect
              EndIf
            Case #PB_Event_Gadget
              
              currentContainerIndex = GetGadgetState(0)
              Select EventGadget()
                Case 0: UpdateButtonStates()
                  If EventType()= #PB_EventType_LeftDoubleClick
                    
                    If currentContainerIndex >= 0
                      If Not containerStarted(currentContainerIndex)
                        StartDockerFollow(currentContainerIndex)
                        SetActiveGadget(0)
                        SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                        UpdateButtonStates()
                      Else
                        StopDockerFollow(currentContainerIndex) 
                      EndIf 
                    EndIf
                  EndIf
                Case 1: AddMonitorDialog()
                Case 2
                  If currentContainerIndex >= 0
                    RemoveMonitor(currentContainerIndex)
                    UpdateMonitorList()
                  EndIf
                Case 3
                  If currentContainerIndex >= 0
                    StartDockerFollow(currentContainerIndex)
                    SetActiveGadget(0)
                    SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                    UpdateButtonStates()
                  EndIf
                Case 4
                  If currentContainerIndex >= 0 : StopDockerFollow(currentContainerIndex) : EndIf
                Case 5
                  If currentContainerIndex >= 0
                    EditPatternsDialog(currentContainerIndex)
                    SetActiveGadget(0)
                    SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                    UpdateButtonStates()
                  EndIf
                Case 6
                  If currentContainerIndex >= 0
                    EditMonitorDialog(currentContainerIndex)
                    SetActiveGadget(0)
                    SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                    UpdateButtonStates()
                  EndIf
              EndSelect
              
            Case #PB_Event_CloseWindow
              
              If IsRunning()
                HideWindow(0,#True)
              Else
                Break;
              EndIf
          EndSelect
        EndIf
      Case 1: ; Add Monitor  
        closeWindow = #False
        If Event =  #PB_Event_CloseWindow
          closeWindow = #True
        ElseIf Event = #PB_Event_Menu
          closeWindow = #False
          Select EventMenu()
            Case #EventOk
              bgCol = GetGadgetColor(14,#PB_Gadget_BackColor)
              CloseAddMonitorDialog(bgCol)
              Event = #PB_Event_CloseWindow
          EndSelect
        ElseIf Event = #PB_Event_Gadget
          Select EventGadget()
            Case 10
              If GetGadgetText(10) = ""
                DisableGadget(13, #True)
              Else
                DisableGadget(13, #False)
              EndIf
            Case 12
              bgCol = ColorRequester(GetGadgetColor(14,#PB_Gadget_BackColor))
              SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
            Case 13
              bgCol = GetGadgetColor(14,#PB_Gadget_BackColor)
              CloseAddMonitorDialog(bgCol)
              closeWindow = #True
            Case 15
              closeWindow = #True
              
          EndSelect
        EndIf
        If closeWindow
          CloseWindow(1)
        EndIf 
      Case 2: ; Add Pattern
        closeWindow = #False
        If Event =  #PB_Event_CloseWindow
          closeWindow = #True
        ElseIf Event = #PB_Event_Gadget
          closeWindow = #False
          Select EventGadget()
            Case 20
              If GetGadgetText(20) = ""
                DisableGadget(23,#True)
              Else
                DisableGadget(23,#False)
              EndIf
            Case 22
              patCol = ColorRequester(GetGadgetColor(24,#PB_Gadget_BackColor))
              SetGadgetColor(24,#PB_Gadget_BackColor, patCol)
            Case 23
              pattern.s = GetGadgetText(20)
              If pattern <> ""
                patCol = GetGadgetColor(24,#PB_Gadget_BackColor)
                AddPattern(currentContainerIndex, pattern, patCol, GetGadgetState(26))
                UpdatePatternList(currentContainerIndex)
                If IsWindow(4)
                  SetActiveWindow(4)
                  SetActiveGadget(40)
                  SetGadgetItemState(40,patternCount(currentContainerIndex)-1,#PB_ListIcon_Selected)
                EndIf 
                closeWindow = #True
              EndIf
            Case 25
              closeWindow = #True
            Case 27
              SetGadgetState(26,1-GetGadgetState(26))
          EndSelect    
        EndIf  
        If closeWindow
          CloseWindow(2)
          UpdatePatternButtonStates()
        EndIf 
        
      Case 3: ;Edit Patterns
        
        closeWindow = #False
        If Event =  #PB_Event_CloseWindow
          closeWindow = #True
        ElseIf Event = #PB_Event_Gadget
          closeWindow = #False
          Select EventGadget()
            Case 30
              If GetGadgetText(30) = ""
                DisableGadget(33,#True)
              Else
                DisableGadget(33,#False)
              EndIf
            Case 32
              patCol = ColorRequester(GetGadgetColor(34,#PB_Gadget_BackColor))
              SetGadgetColor(34,#PB_Gadget_BackColor,patCol)
            Case 33
              patCol = GetGadgetColor(34,#PB_Gadget_BackColor)
              patterns(currentContainerIndex,currentPatternIndex) = GetGadgetText(30)
              patternColor(currentContainerIndex,currentPatternIndex) = patCol
              
              patternsNotification(currentContainerIndex,currentPatternIndex) = GetGadgetState(36)
              
              
              If containerStarted(currentContainerIndex)
                HandleInputLine(currentContainerIndex, lastMatch(currentContainerIndex),#False)
                CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetEditorTextColor( currentContainerIndex):CompilerEndIf
                
              EndIf 
              
              SaveSettings()
              closeWindow = #True
            Case 35
              closeWindow = #True
            Case 37
              SetGadgetState(36,1-GetGadgetState(36))
              
          EndSelect
          
        EndIf
        If  closeWindow 
          UpdatePatternList(currentContainerIndex)
          If IsWindow(4)
            SetActiveWindow(4)
            SetActiveGadget(40)
            SetGadgetItemState(40,currentPatternIndex,#PB_ListIcon_Selected)
          EndIf 
          CloseWindow(3)
        EndIf
      Case 4: ; Patterns Window
        closeWindow = #False
        If Event =  #PB_Event_CloseWindow
          closeWindow = #True
        ElseIf Event = #PB_Event_Gadget
          closeWindow = #False
          
          currentPatternIndex = GetGadgetState(40)
          
          Select EventGadget()
            Case 40:             UpdatePatternButtonStates()
              If EventType()= #PB_EventType_LeftDoubleClick
                If currentPatternIndex >= 0
                  EditPatternDialog(currentContainerIndex,currentPatternIndex)
                EndIf
              EndIf
            Case 41 ; Add pattern
              AddPatternDialog(currentContainerIndex)
              UpdatePatternButtonStates() 
            Case 42 ; Edit selected
              If currentPatternIndex >= 0
                EditPatternDialog(currentContainerIndex,currentPatternIndex)
              EndIf
            Case 43 ; Remove selected
              If currentPatternIndex >= 0
                For p = currentPatternIndex To patternCount(currentContainerIndex)-2
                  patterns(currentContainerIndex,p) = patterns(currentContainerIndex,p+1)
                  patternColor(currentContainerIndex,p) = patternColor(currentContainerIndex,p+1)
                Next
                patternCount(currentContainerIndex) - 1
              EndIf
              UpdatePatternList(currentContainerIndex)
              UpdatePatternButtonStates()
            Case 44: 
              closeWindow = #True            
              
          EndSelect
        EndIf
        If  closeWindow 
          CloseWindow(4)
        EndIf
      Case 5: ; Edit Monitor
        closeWindow = #False
        If Event =  #PB_Event_CloseWindow
          closeWindow = #True
        ElseIf Event = #PB_Event_Gadget
          closeWindow = #False
          Select EventGadget()
            Case 50
              If GetGadgetText(50) = ""
                DisableGadget(53, #True)
              Else
                DisableGadget(53, #False)
              EndIf
            Case 52
              bgCol = ColorRequester(GetGadgetColor(54,#PB_Gadget_BackColor))
              SetGadgetColor(54, #PB_Gadget_BackColor, bgCol)
            Case 53
              bgCol = GetGadgetColor(54,#PB_Gadget_BackColor)
              containerName(currentContainerIndex) = GetGadgetText(50)
              bgColor(currentContainerIndex) = bgCol
              UpdateMonitorList()
              SaveSettings()
              If containerStarted(currentContainerIndex)
                If trayID(currentContainerIndex) = 0
                  CreateMonitorIcon(currentContainerIndex, innerColor(currentContainerIndex), bgColor(currentContainerIndex))
                Else
                  UpdateMonitorIcon(currentContainerIndex, patternColor(currentContainerIndex,lastMatchPattern(currentContainerIndex)))
                EndIf
                HandleInputLine(currentContainerIndex, lastMatch(currentContainerIndex),#False)
              EndIf 
              closeWindow = #True
            Case 55
              closeWindow = #True
          EndSelect
        EndIf
        If closeWindow
          CloseWindow(5)
          SetActiveGadget(0)
          SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
          UpdateButtonStates()
        EndIf 
        
      Default:  
        
        If Event =  #PB_Event_ActivateWindow  
          ForEach logWindows()
            If logWindows()\winID = Window
              CompilerIf #PB_Compiler_OS = #PB_OS_Windows:SetOverlayIcon(WindowID(logWindows()\winID),logWindows()\containerIndex):CompilerEndif
              Break;
            EndIf
          Next
        ElseIf Event =  #PB_Event_SizeWindow Or Event =  #PB_Event_MoveWindow
          ForEach logWindows()
            If logWindows()\winID = Window
              SaveSettings()
              Break
            EndIf
          Next
        EndIf
        
    EndSelect
    
    
    For i = 0 To containerCount-1
      CheckDockerOutput(i)
    Next
    Delay(1)
  Until 0
  CloseWindow(0)
  
  
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ;Free Windows Icons
    ForEach logWindows()
      If containterMetaData(index)\overlayIconHandle
        DestroyIcon_(containterMetaData(index)\overlayIconHandle)
      EndIf 
    Next
    For i = 0 To containerCount-1
      If infoImageId(i)
        DestroyIcon_(infoImageId(i))
      EndIf
    Next
  CompilerEndIf
  
EndProcedure



StartApp()



; IDE Options = PureBasic 6.21 - C Backend (MacOS X - arm64)
; CursorPosition = 689
; FirstLine = 685
; Folding = ------------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = Docker Status.exe
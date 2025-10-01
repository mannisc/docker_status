#MAX_CONTAINERS = 16
#MAX_PATTERNS   = 32
#ICON_SIZE      = 24
#UPDATE_INTERVAL = 1

Global monitorCount.l = 0
Global Dim containerName.s(#MAX_CONTAINERS-1)
Global Dim bgColor.l(#MAX_CONTAINERS-1)
Global Dim innerColor.l(#MAX_CONTAINERS-1)
Global Dim neutralInnerColor.l(#MAX_CONTAINERS-1)
Global Dim infoImageID.l(#MAX_CONTAINERS-1)
Global Dim dockerProgramID(#MAX_CONTAINERS-1)
Global Dim patternCount.l(#MAX_CONTAINERS-1)
Global Dim lastMatchTime.l(#MAX_CONTAINERS-1)
Global Dim tooltip.s(#MAX_CONTAINERS-1)
Global Dim trayID.l(#MAX_CONTAINERS-1)
Global Dim containerStarted.b(#MAX_CONTAINERS-1)

Global Dim patterns.s(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
Global Dim patternColor.l(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)


Procedure CreateMonitorIcon(index, innerCol, bgCol)
  If CreateImage(infoImageID(index), #ICON_SIZE, #ICON_SIZE, 32)
    If StartVectorDrawing(ImageVectorOutput(infoImageID(index)))
      VectorSourceColor(RGBA(0,0,0,0))
      VectorSourceColor(RGBA(Red(bgCol), Green(bgCol), Blue(bgCol), 255))
      ;AddPathCircle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2 - 1)
      ;FillPath()
      FillVectorOutput()

      VectorSourceColor(RGBA(Red(innerCol), Green(innerCol), Blue(innerCol), 255))
      AddPathCircle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2 - 4)
      FillPath()
      StopVectorDrawing()
    EndIf
  EndIf

  
    If trayID(index) = 0
      trayID(index) = index + 1
      AddSysTrayIcon(trayID(index), WindowID(0), ImageID(infoImageID(index)))
      SysTrayIconToolTip(trayID(index), tooltip(index))
    Else
      ChangeSysTrayIcon(trayID(index), ImageID(infoImageID(index)))
    EndIf
EndProcedure


Procedure SetListItemStarted(index,started)
  bgCol = bgColor(index)
  
  Protected img = CreateImage(#PB_Any, 32, 32, 32, bgCol)
  If img
    StartVectorDrawing(ImageVectorOutput(img))
    VectorSourceColor(RGBA(Red(bgCol), Green(bgCol), Blue(bgCol), 255))
    FillVectorOutput()
    If started
      ; Play triangle coordinates (scaled to 32x32)
      
      MovePathCursor(8, 6)
      AddPathLine(24, 16)
      AddPathLine(8, 26)
      ClosePath()
      
      VectorSourceColor(RGBA(0,0,0,255)) ; black
      FillPath()
      
      MovePathCursor(8, 6)
      AddPathLine(24, 16)
      AddPathLine(8, 26)
      ClosePath()
      ; Stroke (outline) triangle in white
      VectorSourceColor(RGBA(255, 255, 255, 255))
      StrokePath(3) 
    EndIf
    StopVectorDrawing()
    
    SetGadgetItemImage(0, index, ImageID(img))
  EndIf
EndProcedure

Enumeration KeyboardEvents
  #EventOk
EndEnumeration



Procedure SetListItemColor(gadgetID, index, color)
  Protected img = CreateImage(#PB_Any, 1, 1)
  If img
    StartDrawing(ImageOutput(img))
    Box(0, 0, 1, 1, color)
    StopDrawing()
    SetGadgetItemImage(gadgetID, index, ImageID(img))
  EndIf
EndProcedure

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

Procedure UpdateMonitorList()
  ClearGadgetItems(0)
  For i = 0 To monitorCount-1
    AddGadgetItem(0, -1, containerName(i))
    ;SetListItemColor(0, i, bgColor(i))
    SetListItemStarted(i,containerStarted(i))
  Next
  UpdateButtonStates()
EndProcedure

Procedure AddMonitor(contName.s, bgCol.l)
  If monitorCount >= #MAX_CONTAINERS
    MessageRequester("Docker Status", "Max monitors reached", 0)
    ProcedureReturn
  EndIf
  containerName(monitorCount) = contName
  bgColor(monitorCount) = bgCol
  innerColor(monitorCount) = $FFFFFF
  neutralInnerColor(monitorCount) = $FFFFFF
  patternCount(monitorCount) = 0
  tooltip(monitorCount) = "Docker: " + contName
  monitorCount + 1
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
  For i = index To monitorCount - 2
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
  monitorCount - 1
EndProcedure


Procedure CloseAddMonitorDialog(bgCol)
  container$ = GetGadgetText(10)
            If container$ <> ""
              AddMonitor(container$, bgCol)
              UpdateMonitorList()
              SetActiveGadget(0)
              SetGadgetItemState(0,monitorCount-1,#PB_ListIcon_Selected)
              UpdateButtonStates()
              
            EndIf
            
  EndProcedure


Procedure AddMonitorDialog()
  If OpenWindow(1, 0, 0, 380, 130, "Add Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(10, 10, 10, 360, 24, "") ; container name
    SetActiveGadget(10)
    
    AddKeyboardShortcut(1, #PB_Shortcut_Return, #EventOk)
    
    TextGadget(11, 10, 53, 100, 24, "Background Color:")
    ContainerGadget(14, 120, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(12, 150, 50, 100, 24, "Choose...")
    
    ButtonGadget(13, 80, 100, 80, 24, "OK")
    ButtonGadget(15, 170, 100, 80, 24, "Cancel")
    
    bgCol = RGB(200, 200, 200)
    SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
    DisableGadget(13, #True)
    Repeat
      Event = WaitWindowEvent()
      If   Event = #PB_Event_Menu
        Select EventMenu()
          Case  #EventOk:
           
            CloseAddMonitorDialog(bgCol)
            Event = #PB_Event_CloseWindow
        EndSelect
        
      ElseIf Event = #PB_Event_Gadget
        Select EventGadget()
          Case 10 ; pattern input changed
            If GetGadgetText(10) = ""
              DisableGadget(13, #True)
            Else
              DisableGadget(13, #False)
            EndIf
          Case 12 ; choose background color
            bgCol = ColorRequester(bgCol)
            SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
            
          Case 13 ; OK
            CloseAddMonitorDialog(bgCol)
            Event = #PB_Event_CloseWindow
          Case 15 ; Cancel
            Event = #PB_Event_CloseWindow
        EndSelect
        
      EndIf
    Until Event = #PB_Event_CloseWindow
    
    CloseWindow(1)
  EndIf
EndProcedure

Procedure EditMonitorDialog(selIndex)
  container$ = containerName(selIndex)
  bgCol      = bgColor(selIndex)
  
  If OpenWindow(5, 0, 0, 380, 130, "Edit Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(50, 10, 10, 360, 24, container$) ; container name
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
    
    Repeat
      Event = WaitWindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 50 ; container input changed
            If GetGadgetText(50) = ""
              DisableGadget(53, #True)
            Else
              DisableGadget(53, #False)
            EndIf
            
          Case 52 ; choose background color
            bgCol = ColorRequester(bgCol)
            SetGadgetColor(54, #PB_Gadget_BackColor, bgCol)
            
          Case 53 ; OK
            containerName(selIndex)      = GetGadgetText(50)
            bgColor(selIndex)  = bgCol
            UpdateMonitorList()
            
            
            Event = #PB_Event_CloseWindow
            
          Case 55 ; Cancel
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
    Until Event = #PB_Event_CloseWindow
    
    CloseWindow(5)
  EndIf
EndProcedure



Procedure RedrawTimeoutIcons()
  For i = 0 To monitorCount-1
    If lastMatchTime(i) > 0
      If ElapsedMilliseconds() - lastMatchTime(i) > 10000
        CreateMonitorIcon(i, neutralInnerColor(i), bgColor(i))
        lastMatchTime(i) = 0
      EndIf
    EndIf
  Next
EndProcedure





Procedure  UpdatePatternButtonStates()
  selIndex = GetGadgetState(40)
  If selIndex >= 0
    DisableGadget(42, #False)
    DisableGadget(43, #False)
  Else
    DisableGadget(42, #True)
    DisableGadget(43, #True)
  EndIf
EndProcedure

Procedure UpdatePatternList(index)
  ClearGadgetItems(40)
  For p = 0 To patternCount(index)-1
    AddGadgetItem(40, -1, patterns(index,p))
    SetListItemColor(40, p, patternColor(index,p))
  Next
EndProcedure

Procedure AddPattern(index, pat.s, color.l)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If patternCount(index) >= #MAX_PATTERNS
    ProcedureReturn
  EndIf
  patterns(index, patternCount(index)) = pat
  patternColor(index, patternCount(index)) = color
  patternCount(index) + 1
EndProcedure

Procedure AddPatternDialog(monitorIndex)
  If OpenWindow(2, 0, 0, 380, 130, "Add Log Status Pattern", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(20, 10, 10, 360, 24, "") ; pattern
    SetActiveGadget(20)
    
    TextGadget(21, 10, 53, 100, 24, "Pattern Color:")
    ContainerGadget(24, 95, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(22, 125, 50, 100, 24, "Choose...")
    
    ButtonGadget(23, 80, 100, 80, 24, "OK")
    ButtonGadget(25, 170, 100, 80, 24, "Cancel")
    
    DisableGadget(23, #True) ; start disabled
    
    patCol = RGB(255, 0, 0)
    SetGadgetColor(24, #PB_Gadget_BackColor, patCol)
    
    Repeat
      Event = WaitWindowEvent()
      Select Event
        Case #PB_Event_Gadget
          Select EventGadget()
            Case 20 ; pattern input changed
              If GetGadgetText(20) = ""
                DisableGadget(23, #True)
              Else
                DisableGadget(23, #False)
              EndIf
              
            Case 22 ; choose pattern color
              patCol = ColorRequester(patCol)
              SetGadgetColor(24, #PB_Gadget_BackColor, patCol)
              
            Case 23 ; OK
              pattern$ = GetGadgetText(20)
              If pattern$ <> ""
                AddPattern(monitorIndex, pattern$, patCol)
                UpdatePatternList(monitorIndex)
                
                Debug "ADD PATERN"
                Debug patternCount(monitorIndex)-1
                
                SetActiveWindow(4)
                SetActiveGadget(40)
                SetGadgetItemState(40,patternCount(monitorIndex)-1,#PB_ListIcon_Selected)
                
                Event = #PB_Event_CloseWindow
              EndIf
              
            Case 25 ; Cancel
              Event = #PB_Event_CloseWindow
          EndSelect
      EndSelect
    Until Event = #PB_Event_CloseWindow
    
    CloseWindow(2)
  EndIf
EndProcedure



Procedure EditPatternDialog(index,selIndex)
  pattern$ = patterns(index,selIndex)
  patCol   = patternColor(index,selIndex)
  
  If OpenWindow(3, 0, 0, 380, 130, "Edit Log Status Pattern", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(30, 10, 10, 360, 24, pattern$) ; pattern
    SetActiveGadget(30)
    
    TextGadget(31, 10, 53, 100, 24, "Pattern Color:")
    ContainerGadget(34, 95, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(32, 125, 50, 100, 24, "Choose...")
    
    ButtonGadget(33, 80, 100, 80, 24, "OK")
    ButtonGadget(35, 170, 100, 80, 24, "Cancel")
    
    If pattern$ = ""
      DisableGadget(33, #True)
    EndIf
    
    SetGadgetColor(34, #PB_Gadget_BackColor, patCol)
    
    Repeat
      Event = WaitWindowEvent()
      Select Event
        Case #PB_Event_Gadget
          Select EventGadget()
            Case 30 ; pattern input changed
              If GetGadgetText(30) = ""
                DisableGadget(33, #True)
              Else
                DisableGadget(33, #False)
              EndIf
              
            Case 32 ; choose pattern color
              patCol = ColorRequester(patCol)
              SetGadgetColor(34, #PB_Gadget_BackColor, patCol)
              
            Case 33 ; OK
              patterns(index, selIndex)    = GetGadgetText(30)
              patternColor(index, selIndex) = patCol
              Event = #PB_Event_CloseWindow
              
            Case 35 ; Cancel
              Event = #PB_Event_CloseWindow
          EndSelect
      EndSelect
    Until Event = #PB_Event_CloseWindow
    
    UpdatePatternList(monitorIndex)
    SetActiveGadget(40)        
    SetGadgetItemState(40,selIndex,#PB_ListIcon_Selected)
    
    CloseWindow(3)
  EndIf
EndProcedure


Procedure EditPatternsDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(4,150,150,420,200,"Log Status Patterns",#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ListIconGadget(40,10, 10, 300, 180,"Log Pattern",180,#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection)
    ButtonGadget(41, 325, 10, 80, 24, "Add")
    ButtonGadget(43, 325, 40, 80, 24, "Remove")
    ButtonGadget(42, 325, 80, 80, 24, "Edit")
    
    UpdatePatternList(index)
    UpdatePatternButtonStates()
    Repeat
      Event = WindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 40:             UpdatePatternButtonStates()
            
          Case 41 ; Add pattern
            AddPatternDialog(index)
            UpdatePatternButtonStates()
            
          Case 42 ; Edit selected
            selIndex = GetGadgetState(40)
            If selIndex >= 0
              EditPatternDialog(index,selIndex)
            EndIf
          Case 43 ; Remove selected
            selIndex = GetGadgetState(40)
            If selIndex >= 0
              For p = selIndex To patternCount(index)-2
                patterns(index,p) = patterns(index,p+1)
                patternColor(index,p) = patternColor(index,p+1)
              Next
              patternCount(index) - 1
            EndIf
            UpdatePatternList(index)
            UpdatePatternButtonStates()
          Case 44: 
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
      Delay(#UPDATE_INTERVAL)
    Until Event = #PB_Event_CloseWindow
    CloseWindow(4)
  EndIf
EndProcedure

Procedure EditColorsDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(3,150,150,360,160,"Edit Colors for " + containerName(index),#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ButtonGadget(30,10,10,160,28,"Pick Background")
    ButtonGadget(31,190,10,160,28,"Pick Neutral Inner")
    ButtonGadget(32,10,50,160,28,"Pick Inner (active)")
    ButtonGadget(33,190,50,160,28,"Recreate Icon")
    ButtonGadget(34,80,100,80,24,"Close")
    Repeat
      Event = WaitWindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 30: bgColor(index) = ColorRequester(bgColor(index))
          Case 31: neutralInnerColor(index) = ColorRequester(neutralInnerColor(index))
          Case 32: innerColor(index) = ColorRequester(innerColor(index))
          Case 33: CreateMonitorIcon(index, innerColor(index), bgColor(index))
          Case 34: 
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
    Until Event = #PB_Event_CloseWindow
    CloseWindow(3)
  EndIf 
EndProcedure

Procedure.s TryDockerDefaultPaths()
  Debug "TryDockerDefaultPaths"
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
  ; check each path
  Repeat 
    path$ = StringField(dockerPaths, i, "|")
    Debug path
    If path$ <> "" And FileSize(path$)
      ProcedureReturn path$
    EndIf
    i + 1
  Until Trim(path$) = ""
  ProcedureReturn "docker" ; not found
EndProcedure

Procedure.s GetDockerExcutable()
  Debug "GetDockerPath"
  Protected pathEnv.s = GetEnvironmentVariable("PATH")
  folder.s = ""
  index = 1
  Repeat
    folder = StringField(pathEnv, index,";")
    Protected candidate.s = folder + "\docker.exe"
    If FileSize(candidate) > 0
      ProcedureReturn candidate
    EndIf
    candidate = folder + "\Docker.exe"
    If FileSize(candidate) > 0
      ProcedureReturn candidate
    EndIf
    index+1
  Until folder = ""
  
  
  ProcedureReturn TryDockerDefaultPaths() ; not found
EndProcedure


Procedure StartDockerFollow(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  
  
  
  
  dockerExecutable$ = GetDockerExcutable()
  Debug dockerExecutable$
  
  cmd$ = "cmd.exe"
  
  containerName$ = "mycontainer"
  
  dockerCommand$ = "/k " + Chr(34) + dockerExecutable$  +Chr(34) +" logs --follow " + containerName(index)
  
  Debug dockerCommand
  
  dockerProgramID(index) = RunProgram(cmd$, dockerCommand$, "", #PB_Program_Open   |#PB_Program_Write |#PB_Program_Read |#PB_Program_Error | #PB_Program_Hide)
  dockerProgramID = dockerProgramID(index)
  
  ;   If dockerProgramID
  ;     Debug "Program started successfully"
  ;     
  ;     ; You MUST read the output!
  ;     While ProgramRunning(dockerProgramID)
  ;       Debug "ProgramRunning NOW READING"
  ;       If AvailableProgramOutput(dockerProgramID)
  ;         Debug "ProgramRunning AvailableProgramOutput"
  ;         
  ;         error$ = ReadProgramError(dockerProgramID)
  ;         If error$ = ""
  ;           output$ = ReadProgramString(dockerProgramID)
  ;         EndIf 
  ;         Debug "Docker error$: " + error$
  ;        
  ;         Debug "Docker output$: " + output$
  ;       EndIf
  ;       Debug "ProgramRunning STOPPED READING"
  ;       Delay(10)
  ;     Wend
  ;     Debug "Program finished"
  ;     
  ;     ; Read any remaining output after program finishes
  ;     While AvailableProgramOutput(dockerProgramID)
  ;       output$ = ReadProgramString(dockerProgramID)
  ;       Debug "Docker output: " + output$
  ;     Wend
  ;       Debug "Program after output"
  ;   
  ;     CloseProgram(dockerProgramID)
  ;   Else
  ;     Debug "Failed to start program!"
  ;   EndIf
  ;     
  If trayID(index) = 0
    CreateMonitorIcon(index, innerColor(index), bgColor(index))
  EndIf
  containerStarted(index) = #True
  SetListItemStarted(index,#True)
EndProcedure

Procedure StopDockerFollow(index)
  If dockerProgramID(selIndex) <> 0
    CloseProgram(dockerProgramID(selIndex))
    dockerProgramID(selIndex) = 0
  EndIf
  If trayID(selIndex) <> 0
    RemoveSysTrayIcon(trayID(selIndex))
    trayID(selIndex) = 0
  EndIf
  containerStarted(index) = #False
  SetListItemStarted(selIndex,#False)
  SetActiveGadget(0)
  SetGadgetItemState(0, selIndex, #PB_ListIcon_Selected)
  UpdateButtonStates()
EndProcedure


Procedure UpdateMonitorIconOnMatch(index, matchColor)
  CreateMonitorIcon(index, matchColor, bgColor(index))
  lastMatchTime(index) = ElapsedMilliseconds()
  SysTrayIconToolTip(trayID(index), tooltip(index) + " (last match: " + FormatDate("%Y-%m-%d %H:%M:%S", Date()) + ")")
EndProcedure

Procedure CheckDockerOutput(index)
  
  If dockerProgramID(index) = 0
    ProcedureReturn
  EndIf
  
  While IsProgram(dockerProgramID(index)) And AvailableProgramOutput(dockerProgramID(index)) > 0
    error$ = ReadProgramError(dockerProgramID(index))
    If error$ = ""
      line$ = ReadProgramString(dockerProgramID(index))
      Debug line$
      If line$ <> ""
        For p = 0 To patternCount(index)-1
          If FindString(line$, patterns(index,p), 1) > 0
            Debug "FOUND "+p
            UpdateMonitorIconOnMatch(index, patternColor(index,p))
            Break
          EndIf
        Next
      EndIf
    EndIf
  Wend
EndProcedure


If OpenWindow(0,0,0,420,300,"Docker Status",#PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
  ListIconGadget(0, 10, 10, 300, 280,"Container",290,#PB_ListIcon_FullRowSelect)
  ButtonGadget(1, 325, 10, 80, 24, "Add")
  ButtonGadget(6, 325, 40, 80, 24, "Edit")
  ButtonGadget(2, 325, 70, 80, 24, "Remove")
  ButtonGadget(5, 325, 110, 80, 24, "Log Status")
  ButtonGadget(3, 325, 150, 80, 24, "Start")
  ButtonGadget(4, 325, 180, 80, 24, "Stop")
EndIf



UpdateMonitorList()

Repeat
  Event = WindowEvent()
  If Event
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case 0: UpdateButtonStates()
          Case 1: AddMonitorDialog()
          Case 2:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              RemoveMonitor(selIndex)
              UpdateMonitorList()
            EndIf
          Case 3:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              StartDockerFollow(selIndex)
              SetActiveGadget(0)
              SetGadgetItemState(0, selIndex, #PB_ListIcon_Selected)
              UpdateButtonStates()
            EndIf
          Case 4:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              StopDockerFollow(selIndex)
            EndIf
          Case 5:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              EditPatternsDialog(selIndex)
              SetActiveGadget(0)
              SetGadgetItemState(0, selIndex, #PB_ListIcon_Selected)
              UpdateButtonStates()
            EndIf
          Case 6:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              EditMonitorDialog(selIndex)
              SetActiveGadget(0)
              SetGadgetItemState(0, selIndex, #PB_ListIcon_Selected)
              UpdateButtonStates()
            EndIf
          Case 7: ;UNUSED
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              EditColorsDialog(selIndex)
              SetActiveGadget(0)
              SetGadgetItemState(0, selIndex, #PB_ListIcon_Selected)
              UpdateButtonStates()
            EndIf
        EndSelect
      Case #PB_Event_SysTray
        idx = EventGadget() - 1
        If idx >= 0 And idx < monitorCount
          If EventType() = #PB_EventType_LeftDoubleClick
            MessageRequester("Docker Status", tooltip(idx), 0)
          EndIf
        EndIf
      Case #PB_Event_CloseWindow
        For i = 0 To monitorCount-1
          If dockerProgramID(i) <> 0
            CloseProgram(dockerProgramID(i))
            dockerProgramID(i) = 0
          EndIf
        Next
        End
    EndSelect
  EndIf
  
  For i = 0 To monitorCount-1
    CheckDockerOutput(i)
  Next
  RedrawTimeoutIcons()
  Delay(#UPDATE_INTERVAL)
Until 0
CloseWindow(0)
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 32
; FirstLine = 9
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; Executable = Docker Status.exe
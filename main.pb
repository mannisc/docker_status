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
Global Dim dockerProgramID.l(#MAX_CONTAINERS-1)
Global Dim patternCount.l(#MAX_CONTAINERS-1)
Global Dim lastMatchTime.l(#MAX_CONTAINERS-1)
Global Dim tooltip.s(#MAX_CONTAINERS-1)
Global Dim trayID.l(#MAX_CONTAINERS-1)

Global Dim patterns.s(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
Global Dim patternColor.l(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)

Procedure CreateMonitorIcon(index, innerCol, bgCol)
  If CreateImage(infoImageID(index), #ICON_SIZE, #ICON_SIZE)
    If StartDrawing(ImageOutput(infoImageID(index)))
      Box(0, 0, #ICON_SIZE, #ICON_SIZE, $000000)
      Circle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2, bgCol)
      Circle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2 - 5, innerCol)
      StopDrawing()
    EndIf
  EndIf
  If trayID(index) = 0
    trayID(index) = index + 1
    AddSysTrayIcon(trayID(index), WindowID(0), ImageID(infoImageID(index)))
    SysTrayIconToolTip(trayID(index), tooltip(index))
  Else
    ChangeSysTrayIcon(trayID(index), infoImageID(index))
  EndIf
EndProcedure

Procedure StartDockerFollow(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  dockerProgramID(index) = RunProgram("docker", "logs --follow " + containerName(index), "", #PB_Program_Read | #PB_Program_Hide)
  
  If trayID(index) = 0
    CreateMonitorIcon(index, innerColor(index), bgColor(index))
  EndIf
  
  SetGadgetItemColor(0, index, #PB_Gadget_BackColor, RGB(0,255,0))
  SetGadgetItemColor(0, index, #PB_Gadget_FrontColor, RGB(0,0,0))
EndProcedure

Procedure AddMonitorInternal(contName.s, bgCol.l, innerCol.l)
  If monitorCount >= #MAX_CONTAINERS
    MessageRequester("Docker Status", "Max monitors reached", 0)
    ProcedureReturn
  EndIf
  containerName(monitorCount) = contName
  bgColor(monitorCount) = bgCol
  innerColor(monitorCount) = innerCol
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

Procedure AddPatternToMonitor(index, pat.s, color.l)
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

Procedure UpdateMonitorIconOnMatch(index, matchColor)
  CreateMonitorIcon(index, matchColor, bgColor(index))
  lastMatchTime(index) = ElapsedMilliseconds()
  SysTrayIconToolTip(trayID(index), tooltip(index) + " (last match: " + FormatDate("%Y-%m-%d %H:%M:%S", Date()) + ")")
EndProcedure

Procedure CheckDockerOutput(index)
  If dockerProgramID(index) = 0
    ProcedureReturn
  EndIf
  While AvailableProgramOutput(dockerProgramID(index)) > 0
    line$ = ReadProgramString(dockerProgramID(index))
    If line$ <> ""
      For p = 0 To patternCount(index)-1
        If FindString(line$, patterns(index,p), 1) > 0
          UpdateMonitorIconOnMatch(index, patternColor(index,p))
          Break
        EndIf
      Next
    EndIf
  Wend
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

Procedure UpdateButtonStates()
  If monitorCount = 0
    DisableGadget(2, #True)
    DisableGadget(3, #True)
    DisableGadget(4, #True)
    DisableGadget(5, #True)
  Else
    selIndex = GetGadgetState(0)
    If selIndex >= 0
      DisableGadget(2, #False)
      DisableGadget(3, #False)
      DisableGadget(4, #False)
      DisableGadget(5, #False)
    Else
      DisableGadget(2, #True)
      DisableGadget(3, #True)
      DisableGadget(4, #True)
      DisableGadget(5, #True)
    EndIf
  EndIf
EndProcedure

If OpenWindow(0,0,0,420,300,"Docker Status",#PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
  ListIconGadget(0, 10, 10, 300, 280,"Container",290,#PB_ListIcon_FullRowSelect)
  ButtonGadget(1, 325, 10, 80, 24, "Add")
  ButtonGadget(2, 325, 40, 80, 24, "Remove")
  ButtonGadget(3, 325, 80, 80, 24, "Start")
  ButtonGadget(4, 325, 110, 80, 24, "Stop")
  ButtonGadget(5, 325, 150, 80, 24, "Edit Patterns")
EndIf

Procedure UpdateMonitorList()
  ClearGadgetItems(0)
  For i = 0 To monitorCount-1
    AddGadgetItem(0, -1, containerName(i))
  Next
  UpdateButtonStates()
EndProcedure

Procedure OpenAddMonitorDialog()
  If OpenWindow(1, 100, 100, 360, 130, "Add Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(10, 10, 10, 340, 24, "")
    SetActiveGadget(10)
    ButtonGadget(11, 170, 50, 180, 24, "Set icon background color")
    ButtonGadget(13, 80,90,80,24,"OK")
    ButtonGadget(14,170,90,80,24,"Cancel")
    bgSel = RGB(0,160,200)
    innerSel = RGB(255,255,255)
    Repeat
      Event = WaitWindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 11: bgSel = ColorRequester(bgSel)
          Case 13
            name$ = GetGadgetText(10)
            If name$ <> ""
              AddMonitorInternal(name$, bgSel, innerSel)
              UpdateMonitorList()
              CloseWindow(1)
              Event = #PB_Event_CloseWindow
            EndIf
          Case 14: CloseWindow(1)
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
    Until Event = #PB_Event_CloseWindow
  EndIf
EndProcedure

Procedure OpenAddPatternDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(2,150,150,360,160,"Add Pattern to " + containerName(index),#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(20,10,10,340,24,"")
    ButtonGadget(21,200,50,70,24,"Pick Color")
    ButtonGadget(22,80,100,80,24,"OK")
    ButtonGadget(23,170,100,80,24,"Cancel")
    pickCol = RGB(255,0,0)
    SetActiveGadget(20)
    Repeat
      Event = WaitWindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 21: pickCol = ColorRequester(pickCol)
          Case 22
            pat$ = GetGadgetText(20)
            If pat$ <> ""
              AddPatternToMonitor(index, pat$, pickCol)
              CloseWindow(2)
              Event = #PB_Event_CloseWindow
            EndIf
          Case 23: CloseWindow(2)
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
    Until Event = #PB_Event_CloseWindow
  EndIf
EndProcedure

Procedure UpdatePatternList(index)
  ClearGadgetItems(40)
  For p = 0 To patternCount(index)-1
    AddGadgetItem(40, -1, patterns(index,p))
    SetGadgetItemText(40, p, Right("000000" + Hex(patternColor(index,p)),6), 1)
  Next
EndProcedure

Procedure OpenEditPatternsDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(4,150,150,400,250,"Edit Patterns for " + containerName(index),#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ListIconGadget(40,10,10,380,150,"Pattern",200,#PB_ListIcon_FullRowSelect)
    AddGadgetColumn(40,1,"Color",150)
    ButtonGadget(41,10,170,80,24,"Add")
    ButtonGadget(42,100,170,80,24,"Edit")
    ButtonGadget(43,190,170,80,24,"Remove")
    ButtonGadget(44,280,170,80,24,"Close")
    
    UpdatePatternList(index)
    
    Repeat
      Event = WindowEvent()
      If Event = #PB_Event_Gadget
        Select EventGadget()
          Case 41 ; Add pattern
            OpenAddPatternDialog(index)
            UpdatePatternList(index)
          Case 42 ; Edit selected
            selIndex = GetGadgetState(40)
            If selIndex >= 0
              pat$ = GetGadgetItemText(40, selIndex, 0)
              col$ = GetGadgetItemText(40, selIndex, 1)
              colVal = Val("$" + col$)
              If OpenWindow(5,200,200,360,160,"Edit Pattern",#PB_Window_SystemMenu)
                StringGadget(50,10,10,340,24,pat$)
                ButtonGadget(51,200,50,70,24,"Pick Color")
                ButtonGadget(52,80,100,80,24,"OK")
                ButtonGadget(53,170,100,80,24,"Cancel")
                pickCol = colVal
                SetActiveGadget(50)
                Repeat
                  e2 = WaitWindowEvent()
                  If e2 = #PB_Event_Gadget
                    Select EventGadget()
                      Case 51: pickCol = ColorRequester(pickCol)
                      Case 52
                        newPat$ = GetGadgetText(50)
                        If newPat$ <> ""
                          patterns(index, selIndex) = newPat$
                          patternColor(index, selIndex) = pickCol
                          CloseWindow(5)
                          e2 = #PB_Event_CloseWindow
                        EndIf
                      Case 53: CloseWindow(5)
                        e2 = #PB_Event_CloseWindow
                    EndSelect
                  EndIf
                Until e2 = #PB_Event_CloseWindow
              EndIf
            EndIf
            UpdatePatternList(index)
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
          Case 44: CloseWindow(4)
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
      Delay(#UPDATE_INTERVAL)
    Until Event = #PB_Event_CloseWindow
   EndIf
EndProcedure

Procedure OpenEditColorsDialog(index)
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
          Case 34: CloseWindow(3)
            Event = #PB_Event_CloseWindow
        EndSelect
      EndIf
    Until Event = #PB_Event_CloseWindow
  EndIf 
EndProcedure

UpdateMonitorList()

Repeat
  Event = WindowEvent()
  If Event
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case 0: UpdateButtonStates()
          Case 1: OpenAddMonitorDialog()
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
            EndIf
          Case 4:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              If dockerProgramID(selIndex) <> 0
                CloseProgram(dockerProgramID(selIndex))
                dockerProgramID(selIndex) = 0
              EndIf
              If trayID(selIndex) <> 0
                RemoveSysTrayIcon(trayID(selIndex))
                trayID(selIndex) = 0
              EndIf
              SetGadgetItemColor(0, selIndex, #PB_Gadget_BackColor, RGB(255,255,255))
              SetGadgetItemColor(0, selIndex, #PB_Gadget_FrontColor, RGB(0,0,0))
            EndIf
          Case 5:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              OpenEditPatternsDialog(selIndex)
            EndIf
          Case 6:
            selIndex = GetGadgetState(0)
            If selIndex >= 0
              OpenEditColorsDialog(selIndex)
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

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 245
; FirstLine = 237
; Folding = ---
; EnableXP
; DPIAware
; VS Code-style vertical tab bar interface
; Color scheme matching VS Code Dark theme

#WIN_MAIN = 0
#CNT_SIDEBAR = 1
#CNT_CONTENT = 2
#IMG_PRESETS = 10
#IMG_COMMAND = 11
#IMG_DIRECTORY = 12
#IMG_STATUS = 13
#IMG_REACTION = 14
#IMG_FILTER = 15
#BTN_TAB_BASE = 100
#BTN_HAMBURGER = 106
#EDT_CMD = 200
#BTN_COLOR = 201
#CHK_NOTIFY = 202
#CNT_COLORPREVIEW = 203
#BTN_OK = 204
#BTN_CANCEL = 205

Global CurrentTab = 0
Global PatternColor = RGB(255, 0, 0)
Global SidebarWidth = 40
Global SidebarExpanded = #False
Global SidebarExpandedWidth = 150

; VS Code color scheme - using runtime variables instead of constants
Global COLOR_BG_DARK = RGB(30, 30, 30)
Global COLOR_SIDEBAR = RGB(51, 51, 51)
Global COLOR_SIDEBAR_HOVER = RGB(42, 45, 46)
Global COLOR_ACCENT = RGB(0, 122, 204)
Global COLOR_TEXT = RGB(204, 204, 204)
Global COLOR_EDITOR_BG = RGB(30, 30, 30)
Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)

Procedure.s GetTabName(index)
  Select index
    Case 0: ProcedureReturn "Presets"
    Case 1: ProcedureReturn "Command"
    Case 2: ProcedureReturn "Directory"
    Case 3: ProcedureReturn "Status"
    Case 4: ProcedureReturn "Reaction"
    Case 5: ProcedureReturn "Filter"
  EndSelect
  ProcedureReturn ""
EndProcedure


Procedure DrawTabButton(gadget, text.s, active)
  If StartDrawing(CanvasOutput(gadget))
    ; Get actual canvas dimensions (DPI aware)
    canvasW = OutputWidth()
    canvasH = OutputHeight()
    
    ; Background
    If active
      DrawingMode(#PB_2DDrawing_Default)
      Box(0, 0, canvasW, canvasH, COLOR_BG_DARK)
      ; Active indicator bar on left
      Box(0, 0, 3, canvasH, COLOR_ACCENT)
    Else
      DrawingMode(#PB_2DDrawing_Default)
      Box(0, 0, canvasW, canvasH, COLOR_SIDEBAR)
    EndIf
    
    ; Draw icon placeholder - always centered in 40px area
    If active
      Circle(canvasH/2, canvasH/2, 8, RGB(0, 122, 204))
    Else
      Circle(canvasH/2, canvasH/2, 8, RGB(120, 120, 120))
    EndIf
    
    ; Draw text label if sidebar is expanded
    If SidebarExpanded
      DrawingMode(#PB_2DDrawing_Transparent)
      If active
        DrawingFont(FontID(0))
        DrawText(canvasH +5, canvasH/2-16, text, RGB(255, 255, 255))
      Else
        DrawingFont(FontID(0))
        DrawText(canvasH +5, canvasH/2-16, text, RGB(245, 245, 245))
      EndIf
    EndIf
    
    StopDrawing()
  EndIf
EndProcedure

Procedure DrawHamburgerButton(gadget)
  If StartDrawing(CanvasOutput(gadget))
    canvasW = OutputWidth()
    canvasH = OutputHeight()
    
    ; Background
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, canvasW, canvasH, COLOR_SIDEBAR)
    
    ; Draw hamburger icon (three horizontal lines) - centered in 40px area
    lineColor = RGB(180, 180, 180)
    centerX = canvasH / 2
    centerY = canvasH / 2
    lineWidth = 16
    lineHeight = 2
    spacing = 5
    
    Box(centerX - lineWidth/2, centerY - spacing - lineHeight/2, lineWidth, lineHeight, lineColor)
    Box(centerX - lineWidth/2, centerY - lineHeight/2, lineWidth, lineHeight, lineColor)
    Box(centerX - lineWidth/2, centerY + spacing - lineHeight/2, lineWidth, lineHeight, lineColor)
    
    ; Draw text label if sidebar is expanded
    If SidebarExpanded
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(0))
      DrawText(canvasH +5, canvasH/2-16, "Menu", RGB(180, 180, 180))
    EndIf
    
    StopDrawing()
  EndIf
EndProcedure

Procedure ToggleSidebar()
  SidebarExpanded = ~SidebarExpanded
  
  Protected newWidth
  If SidebarExpanded
    newWidth = SidebarExpandedWidth
  Else
    newWidth = SidebarWidth
  EndIf
  
  ; Resize sidebar
  ResizeGadget(#CNT_SIDEBAR, #PB_Ignore, #PB_Ignore, newWidth, #PB_Ignore)
  
  ; Resize all tab buttons
  For i = 0 To 5
    ResizeGadget(#BTN_TAB_BASE + i, #PB_Ignore, #PB_Ignore, newWidth, #PB_Ignore)
  Next
  ResizeGadget(#BTN_HAMBURGER, #PB_Ignore, #PB_Ignore, newWidth, #PB_Ignore)
  
  ; Redraw hamburger button
  DrawHamburgerButton(#BTN_HAMBURGER)
  
  ; Redraw all tab buttons
  For i = 0 To 5
    If i = CurrentTab
      DrawTabButton(#BTN_TAB_BASE + i, GetTabName(i), #True)
    Else
      DrawTabButton(#BTN_TAB_BASE + i, GetTabName(i), #False)
    EndIf
  Next
  
  ; Move content containers to the right of sidebar
  For i = 0 To 5
    ResizeGadget(#CNT_CONTENT + i, newWidth, #PB_Ignore, 750 - newWidth, #PB_Ignore)
  Next
  
  ; Update editor width in command tab
  If IsGadget(#EDT_CMD)
    ResizeGadget(#EDT_CMD, #PB_Ignore, #PB_Ignore, 750 - newWidth - 20, #PB_Ignore)
  EndIf
EndProcedure


Procedure ShowTabContent(tab)
  CurrentTab = tab
  
  ; Update all tab buttons
  For i = 0 To 5
    If i = tab
      DrawTabButton(#BTN_TAB_BASE + i, GetTabName(i), #True)
    Else
      DrawTabButton(#BTN_TAB_BASE + i, GetTabName(i), #False)
    EndIf
  Next
  
  ; Hide all content containers
  HideGadget(#CNT_CONTENT + 0, #True)
  HideGadget(#CNT_CONTENT + 1, #True)
  HideGadget(#CNT_CONTENT + 2, #True)
  HideGadget(#CNT_CONTENT + 3, #True)
  HideGadget(#CNT_CONTENT + 4, #True)
  HideGadget(#CNT_CONTENT + 5, #True)
  
  ; Show selected content
  HideGadget(#CNT_CONTENT + tab, #False)
EndProcedure

; Load fonts
LoadFont(0, "Segoe UI", 11)
LoadFont(1, "Segoe UI", 11, #PB_Font_Bold)

; Create main window
OpenWindow(#WIN_MAIN, 0, 0, 750, 500, "Monitor - VS Code Style", 
           #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)

SetWindowColor(#WIN_MAIN, COLOR_BG_DARK)

; Vertical sidebar
ContainerGadget(#CNT_SIDEBAR, 0, 0, SidebarWidth, 500, #PB_Container_BorderLess )
SetGadgetColor(#CNT_SIDEBAR, #PB_Gadget_BackColor, COLOR_SIDEBAR)

  ; Hamburger button at bottom
  CanvasGadget(#BTN_HAMBURGER, 0, 460, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_HAMBURGER, "Toggle Menu")
  DrawHamburgerButton(#BTN_HAMBURGER)
  
  ; Tab buttons as canvas gadgets
  CanvasGadget(#BTN_TAB_BASE + 0, 0, 0, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 0, "Presets")
  CanvasGadget(#BTN_TAB_BASE + 1, 0, SidebarWidth, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 1, "Command")
  CanvasGadget(#BTN_TAB_BASE + 2, 0, SidebarWidth*2, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 2, "Directory")
  CanvasGadget(#BTN_TAB_BASE + 3, 0, SidebarWidth*3, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 3, "Status")
  CanvasGadget(#BTN_TAB_BASE + 4, 0, SidebarWidth*4, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 4, "Reaction")
  CanvasGadget(#BTN_TAB_BASE + 5, 0, SidebarWidth*5, SidebarWidth, SidebarWidth)
  GadgetToolTip(#BTN_TAB_BASE + 5, "Filter")
  
  ; Draw initial tab buttons with labels
  DrawTabButton(#BTN_TAB_BASE + 0, "Presets", #True)
  DrawTabButton(#BTN_TAB_BASE + 1, "Command", #False)
  DrawTabButton(#BTN_TAB_BASE + 2, "Directory", #False)
  DrawTabButton(#BTN_TAB_BASE + 3, "Status", #False)
  DrawTabButton(#BTN_TAB_BASE + 4, "Reaction", #False)
  DrawTabButton(#BTN_TAB_BASE + 5, "Filter", #False)
  
CloseGadgetList()

; Content area containers - 5px padding
Define x = SidebarWidth, y = 0, w = 750 - SidebarWidth, h = 450

; Tab 0 - Presets
ContainerGadget(#CNT_CONTENT + 0, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 0, #PB_Gadget_BackColor, COLOR_BG_DARK)
  tg = TextGadget(#PB_Any, 10, 10, 400, 25, "Presets", #PB_Text_Border)
  SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 1 - Command
ContainerGadget(#CNT_CONTENT + 1, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 1, #PB_Gadget_BackColor, COLOR_BG_DARK)
  cg = ComboBoxGadget(#PB_Any, 10, 10, 200, 25)
  SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
  
  EditorGadget(#EDT_CMD, 10, 45, w-20, 300)
  SetGadgetColor(#EDT_CMD, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(#EDT_CMD, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
  
  ButtonGadget(#BTN_COLOR, 220, 10, 200, 25, "Select Monitor Color...")
  SetGadgetColor(#BTN_COLOR, #PB_Gadget_BackColor, RGB(60, 60, 60))
  SetGadgetColor(#BTN_COLOR, #PB_Gadget_FrontColor, COLOR_TEXT)
  
  ContainerGadget(#CNT_COLORPREVIEW, 430, 12, 21, 21, #PB_Container_BorderLess )
  CloseGadgetList()
  SetGadgetColor(#CNT_COLORPREVIEW, #PB_Gadget_BackColor, PatternColor)
  
  CheckBoxGadget(#CHK_NOTIFY, 10, 355, 200, 20, "Enable Notifications")
  SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_BackColor, COLOR_BG_DARK)
  SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_FrontColor, COLOR_TEXT)
CloseGadgetList()

; Tab 2 - Directory
ContainerGadget(#CNT_CONTENT + 2, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 2, #PB_Gadget_BackColor, COLOR_BG_DARK)
  elg= ExplorerListGadget(#PB_Any, 10, 10, w-20, h-20, "*.*", #PB_Explorer_MultiSelect)
  SetGadgetColor(elg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(elg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 3 - Status
ContainerGadget(#CNT_CONTENT + 3, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 3, #PB_Gadget_BackColor, COLOR_BG_DARK)
  tg = TextGadget(#PB_Any, 10, 10, w-20, h-20, "Status content goes here.")
  SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 4 - Reaction
ContainerGadget(#CNT_CONTENT + 4, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 4, #PB_Gadget_BackColor, COLOR_BG_DARK)
  tg = TextGadget(#PB_Any, 10, 10, w-20, h-20, "Reaction content goes here.")
  SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 5 - Filter
ContainerGadget(#CNT_CONTENT + 5, x, y, w, h, #PB_Container_BorderLess )
SetGadgetColor(#CNT_CONTENT + 5, #PB_Gadget_BackColor, COLOR_BG_DARK)
  tg = TextGadget(#PB_Any, 10, 10, w-20, h-20, "Filter content goes here.")
  SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
  SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Bottom buttons
ButtonGadget(#BTN_OK, 555, 460, 90, 30, "OK")
SetGadgetColor(#BTN_OK, #PB_Gadget_BackColor, COLOR_ACCENT)
SetGadgetColor(#BTN_OK, #PB_Gadget_FrontColor, RGB(255, 255, 255))

ButtonGadget(#BTN_CANCEL, 655, 460, 90, 30, "Cancel")
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_BackColor, RGB(60, 60, 60))
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_FrontColor, COLOR_TEXT)

; Show first tab
ShowTabContent(0)

; Main event loop
Repeat
  Event = WaitWindowEvent()
  EventType = EventType() 

  Select Event
    Case #PB_Event_Gadget
      If EventType = #PB_EventType_LeftClick       
      Select EventGadget()
        Case #BTN_HAMBURGER
          ToggleSidebar()
          
        Case #BTN_TAB_BASE To #BTN_TAB_BASE + 5
          ShowTabContent(EventGadget() - #BTN_TAB_BASE)
          
        Case #BTN_COLOR, #CNT_COLORPREVIEW
          PatternColor = ColorRequester(PatternColor)
          SetGadgetColor(#CNT_COLORPREVIEW, #PB_Gadget_BackColor, PatternColor)
          
        Case #BTN_OK
          commandText.s = GetGadgetText(#EDT_CMD)
          notifyState = GetGadgetState(#CHK_NOTIFY)
          colorHex.s = Right("000000" + Hex(PatternColor), 6)
          MessageRequester("Info", "Command (first 200 chars):" + #LF$ +
            Left(commandText, 200) + #LF$ +
            "Notifications: " + Str(notifyState) + #LF$ +
            "Pattern color: #" + colorHex)
            
        Case #BTN_CANCEL
          CloseWindow(#WIN_MAIN)
      EndSelect
      EndIf
    Case #PB_Event_CloseWindow
      Break
  EndSelect
ForEver
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 77
; FirstLine = 57
; Folding = -
; EnableXP
; DPIAware
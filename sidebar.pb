; VS Code-style vertical tab bar interface
; Color scheme matching VS Code Dark theme

DeclareModule App
  #WIN_MAIN = 0
  #CNT_CONTENT = 2
  #EDT_CMD = 200
  #BTN_COLOR = 201
  #CHK_NOTIFY = 202
  #CNT_COLORPREVIEW = 203
  #BTN_OK = 204
  #BTN_CANCEL = 205
  
  Global PatternColor = RGB(255, 0, 0)
  ; VS Code color scheme
  Global COLOR_BG_DARK = RGB(30,30,30)
  Global COLOR_SIDEBAR = RGB(51, 51, 51)
  Global COLOR_ACCENT = RGB(0, 122, 204)
  Global COLOR_TEXT = RGB(204, 204, 204)
  Global COLOR_EDITOR_BG = COLOR_BG_DARK
  Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)
  Declare AppResizeGadget(Gadget, x, y, w, h)
EndDeclareModule

Module App
  Procedure AppResizeGadget(Gadget, x, y, w, h)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected hWnd = GadgetID(Gadget)
    ; Pause redrawing
    SendMessage_(hWnd, #WM_SETREDRAW, 0, 0)
    ; Resize
    ResizeGadget(Gadget, x, y, w, h)
    ; Resume redrawing and force repaint
    SendMessage_(hWnd, #WM_SETREDRAW, 1, 0)
    RedrawWindow_(hWnd, 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    CompilerElse
    ResizeGadget(Gadget,x,y,w,h)
    CompilerEndIf
  EndProcedure
EndModule

;- ===== Vertical TabBar Module =====
DeclareModule VerticalTabBar
  Structure TabConfig
    Name.s
    IconImage.i
    *ClickCallback
  EndStructure
  
  Structure VerticalTabBarData
    window.i 
    OuterContentContainerID.i
    ContainerGadgetID.i
    ContentContainerID.i
    ContentX.i
    ContentY.i
    ContentWidth.i
    ContentHeight.i
    SidebarWidth.i
    SidebarExpandedWidth.i
    IsExpanded.i
    ActiveTabIndex.i
    TabCount.i
    HamburgerGadgetID.i
    Array TabGadgets.i(0)
    Array TabConfigs.TabConfig(0)
    *ResizeCallback
    HoveredTabIndex.i
    HamburgerHovered.i
    AnimationThread.i
    AnimationLineWidth.f
    CurrentAnimationLineWidth.f
    AnimationRunning.i
  EndStructure
  
  #PB_Event_RedrawHamburger = #PB_Event_FirstCustomValue
  
  Declare.i Create(window.i, x.i, y.i, sidebarWidth.i, expandedWidth.i, contentWidth.i, height.i, List tabConfigs.TabConfig(),User_DPI_Scale.f=1 , *resizeProc = 0)
  Declare Toggle(*tabBar.VerticalTabBarData)
  Declare SetActiveTab(*tabBar.VerticalTabBarData, tabIndex.i)
  Declare HandleEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
  Declare GetWidth(*tabBar.VerticalTabBarData)
  Declare GetContentContainerID(*tabBar.VerticalTabBarData)
EndDeclareModule

Module VerticalTabBar
  UseModule App
  
  ; VS Code color scheme
  Global COLOR_BG_DARK = RGB(30,30,30)
  Global COLOR_SIDEBAR = RGB(51, 51, 51)
  Global COLOR_ACCENT = RGB(0, 122, 204)
  Global COLOR_TEXT = RGB(204, 204, 204)
  Global COLOR_EDITOR_BG = COLOR_BG_DARK
  Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)
  Global COLOR_HOVER = RGB(70, 70, 70)
  
  Global DPI_Scale.f = 1
  
  Global menuFontSize.f = 7
   Global menuFont

   Procedure DrawHamburgerButton(*tabBar.VerticalTabBarData)
    If StartDrawing(CanvasOutput(*tabBar\HamburgerGadgetID))
      canvasW = OutputWidth()
      canvasH = OutputHeight()
      
      ; Background with hover effect
      If *tabBar\HamburgerHovered
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, COLOR_HOVER)
      Else
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, COLOR_SIDEBAR)
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
      
      ; Background
      If active 
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, COLOR_BG_DARK)
        Box(0, 0, 4 * DPI_Scale, canvasH, COLOR_ACCENT)
      ElseIf tabIndex = *tabBar\HoveredTabIndex
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, COLOR_HOVER)
      Else
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, canvasW, canvasH, COLOR_SIDEBAR)
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
      If active
        DrawText(canvasH + 2 * DPI_Scale, canvasH/2 - menuFontSize*2.8* DPI_Scale /2  , *tabBar\TabConfigs(tabIndex)\Name, RGB(255, 255, 255))
      Else
        DrawText(canvasH + 2 * DPI_Scale, canvasH/2 - menuFontSize*2.8 * DPI_Scale/2 , *tabBar\TabConfigs(tabIndex)\Name, RGB(245, 245, 245))
      EndIf
      
      StopDrawing()
    EndIf
  EndProcedure
  
 
  
  Procedure AnimationThread(*tabBar.VerticalTabBarData)
    Protected frames = 24 ; 8 frames for each phase (shrink and expand)
    Protected frameDelay = 8 ; 20ms per frame, total 320ms (8*20ms shrink + 8*20ms expand)
    Protected i
    Protected startWidth.f = *tabBar\AnimationLineWidth
    Protected endWidth.f = 10.0 * DPI_Scale
    
    ; Shrink phase
    For i = 0 To frames - 1
      *tabBar\CurrentAnimationLineWidth = startWidth + (endWidth - startWidth) * i / frames
      PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadgetID)
      Delay(frameDelay)
    Next
    
    ; Expand phase
    For i = 0 To frames - 1
      *tabBar\CurrentAnimationLineWidth = endWidth + (startWidth - endWidth) * i / frames
      PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadgetID)
      Delay(frameDelay)
    Next
    
    ; Reset animation state
    *tabBar\CurrentAnimationLineWidth = startWidth
    *tabBar\AnimationRunning = #False
    PostEvent(#PB_Event_RedrawHamburger, *tabBar\window, *tabBar\HamburgerGadgetID)
  EndProcedure
  
  Procedure RedrawAllTabs(*tabBar.VerticalTabBarData)
    Protected isActive.i, i.i
    
    DrawHamburgerButton(*tabBar)
    
    For i = 0 To *tabBar\TabCount - 1
      If i = *tabBar\ActiveTabIndex
        isActive = #True
      Else
        isActive = #False
      EndIf
      DrawTabButton(*tabBar, i, isActive)
    Next
  EndProcedure
  
  Procedure.i Create(window.i, x.i, y.i, sidebarWidth.i, expandedWidth.i, contentWidth.i, height.i, List tabConfigs.TabConfig(),User_DPI_Scale.f=1 , *resizeProc = 0)
    Protected *tabBar.VerticalTabBarData = AllocateMemory(SizeOf(VerticalTabBarData))
    Protected i.i, tabCount.i
    
    
    DPI_Scale = User_DPI_Scale
    

    menuFont =  LoadFont(#PB_Any , "Segoe UI", menuFontSize * DPI_Scale)

    *tabBar\SidebarWidth = sidebarWidth * DPI_Scale
    *tabBar\SidebarExpandedWidth = expandedWidth * DPI_Scale
    *tabBar\IsExpanded = #False
    *tabBar\ActiveTabIndex = 0
    *tabBar\ContentX = x + *tabBar\SidebarWidth
    *tabBar\ContentY = y
    *tabBar\ContentWidth = contentWidth * DPI_Scale
    *tabBar\ContentHeight = height * DPI_Scale
    *tabBar\HoveredTabIndex = -1
    *tabBar\HamburgerHovered = #False
    *tabBar\AnimationLineWidth = 14.0 * DPI_Scale ; Initial line width
    *tabBar\CurrentAnimationLineWidth = *tabBar\AnimationLineWidth
    *tabBar\AnimationRunning = #False
    *tabBar\window = window
    Debug "contentWidth"
    Debug  contentWidth
    Debug  contentWidth * DPI_Scale
    Debug ""
    
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
    *tabBar\ContainerGadgetID = ContainerGadget(#PB_Any, x, y, *tabBar\SidebarWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    innerContainerGadgetID = ContainerGadget(#PB_Any, 0, 0, *tabBar\SidebarExpandedWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(innerContainerGadgetID, #PB_Gadget_BackColor, COLOR_SIDEBAR)
    
    ; Create hamburger button (square, width = height = sidebarWidth)
    *tabBar\HamburgerGadgetID = CanvasGadget(#PB_Any, 0, 5 * DPI_Scale, *tabBar\SidebarWidth, *tabBar\SidebarWidth)
    GadgetToolTip(*tabBar\HamburgerGadgetID, "Toggle Menu")
    
    ; Create tab buttons
    Dim *tabBar\TabGadgets(tabCount - 1)
    
    For i = 0 To tabCount - 1
      *tabBar\TabGadgets(i) = CanvasGadget(#PB_Any, 0, 10 * DPI_Scale + *tabBar\SidebarWidth * (i + 1), expandedWidth * DPI_Scale, *tabBar\SidebarWidth)
      If Not *tabBar\IsExpanded
        GadgetToolTip(*tabBar\TabGadgets(i),  *tabBar\TabConfigs(i)\Name )
      EndIf
    Next
    CloseGadgetList()
    CloseGadgetList()
    
    ; Create content container
    *tabBar\OuterContentContainerID = ContainerGadget(#PB_Any, x + *tabBar\SidebarWidth, y, *tabBar\ContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    *tabBar\ContentContainerID = ContainerGadget(#PB_Any, 0, 0, *tabBar\ContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(*tabBar\ContentContainerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
    
    CloseGadgetList()
    CloseGadgetList()
    
    *tabBar\ResizeCallback = *resizeProc
    
    ; Draw initial state
    RedrawAllTabs(*tabBar)
    
    ProcedureReturn *tabBar
  EndProcedure
  
  Procedure SmoothResizeGadget(Gadget, x, y, w, h)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected hWnd = GadgetID(Gadget)
    ; Pause redrawing
    SendMessage_(hWnd, #WM_SETREDRAW, 0, 0)
    ; Resize
    ResizeGadget(Gadget, x, y, w, h)
    ; Resume redrawing and force repaint
    SendMessage_(hWnd, #WM_SETREDRAW, 1, 0)
    RedrawWindow_(hWnd, 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    CompilerElse
    ResizeGadget(Gadget,x,y,w,h)
    CompilerEndIf   
  EndProcedure
  
  Procedure Toggle(*tabBar.VerticalTabBarData)
    Protected newWidth.i, i.i, newContentX.i, newContentWidth.i
    
    ; Start animation BEFORE toggling (Win11 style)
    If Not *tabBar\AnimationRunning
      *tabBar\AnimationRunning = #True
      *tabBar\AnimationThread = CreateThread(@AnimationThread(), *tabBar)
    EndIf
    
    *tabBar\IsExpanded = 1 - *tabBar\IsExpanded
    
    If *tabBar\IsExpanded
      newWidth = *tabBar\SidebarExpandedWidth
    Else
      newWidth = *tabBar\SidebarWidth
    EndIf
    
    ; Update tooltips based on expansion state
    For i = 0 To *tabBar\TabCount - 1
      If *tabBar\IsExpanded
        GadgetToolTip(*tabBar\TabGadgets(i), "")
      Else
        GadgetToolTip(*tabBar\TabGadgets(i), *tabBar\TabConfigs(i)\Name)
      EndIf
    Next
    
    
    ; ---- existing resize logic ----
    newContentX = *tabBar\ContentX - *tabBar\SidebarWidth + newWidth
    newContentWidth = *tabBar\ContentWidth + *tabBar\SidebarWidth - newWidth
    
    ; ---- call user supplied handler ----
    If *tabBar\ResizeCallback
      CallFunctionFast(*tabBar\ResizeCallback, *tabBar, *tabBar\ActiveTabIndex, newContentWidth)
    EndIf
    
    SmoothResizeGadget(*tabBar\OuterContentContainerID, newContentX, #PB_Ignore, newContentWidth, #PB_Ignore)
    SmoothResizeGadget(*tabBar\ContainerGadgetID, #PB_Ignore, #PB_Ignore, newWidth, #PB_Ignore)
    
    RedrawAllTabs(*tabBar)
  EndProcedure
  
  Procedure SetActiveTab(*tabBar.VerticalTabBarData, tabIndex.i)
    If tabIndex >= 0 And tabIndex < *tabBar\TabCount
      DrawTabButton(*tabBar, *tabBar\ActiveTabIndex, #False)
      *tabBar\ActiveTabIndex = tabIndex
      DrawTabButton(*tabBar, *tabBar\ActiveTabIndex, #True)
    EndIf
  EndProcedure
  
  Procedure HandleEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
    Protected i.i
    Protected callbackProc
    Protected isActive.i
    
    ; Handle custom redraw event
    If event = #PB_Event_RedrawHamburger And eventGadget = *tabBar\HamburgerGadgetID
      DrawHamburgerButton(*tabBar)
      ProcedureReturn #True
    EndIf
    
    ; Check hamburger button
    If eventGadget = *tabBar\HamburgerGadgetID
      If EventType() = #PB_EventType_LeftClick
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
  
  Procedure GetContentContainerID(*tabBar.VerticalTabBarData)
    ProcedureReturn *tabBar\ContentContainerID
  EndProcedure
EndModule

;- ===== Main Code =====

UseModule App
UseModule VerticalTabBar


Global IsDarkModeActiveCached = #True

IncludeFile "utils.pb"
IncludeFile "winThemeGeneralUsage.pb"

Debug "IsDarkModeActiveCached "+Str(IsDarkModeActiveCached)

ExamineDesktops()
Global DPI_Scale.f = DesktopResolutionX()

Global *TabBar.VerticalTabBarData

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
  SendMessage_(GadgetID(*TabBar\OuterContentContainerID), #WM_SETREDRAW, 0, 0)
  SendMessage_(GadgetID(#CNT_CONTENT + tabIndex), #WM_SETREDRAW, 0, 0)
  CompilerEndIf   
  
 
  For i = 0 To 6
    HideGadget(#CNT_CONTENT + i, #True)
  Next
  ; Show selected content
  HideGadget(#CNT_CONTENT + tabIndex, #False)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  SendMessage_(GadgetID(*TabBar\OuterContentContainerID), #WM_SETREDRAW, 1, 0)
  RedrawWindow_(GadgetID(*TabBar\OuterContentContainerID), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
  SendMessage_(GadgetID(#CNT_CONTENT + tabIndex), #WM_SETREDRAW, 1, 0)
  RedrawWindow_(GadgetID(#CNT_CONTENT + tabIndex), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
CompilerEndIf

EndProcedure

Procedure ShowWindowFadeIn(winID)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected hWnd = WindowID(winID)
    ShowWindow_(hWnd, #SW_SHOWNA)
    UpdateWindow_(hWnd)
    RedrawWindow_(hWnd, #Null, #Null, #RDW_UPDATENOW | #RDW_ALLCHILDREN | #RDW_FRAME)
    While PeekMessage_(@msg, hWnd, #WM_PAINT, #WM_PAINT, #PM_REMOVE)
      DispatchMessage_(@msg)
    Wend
    Repeat : Delay(1) : Until WindowEvent() = 0
    Protected hUser32 = OpenLibrary(#PB_Any, "user32.dll")
    If hUser32
      Protected *AnimateWindow = GetFunction(hUser32, "AnimateWindow")
      If *AnimateWindow
        CallFunctionFast(*AnimateWindow, hWnd, 300, $80000 | $20000)
      EndIf
      CloseLibrary(hUser32)
    EndIf
  CompilerElse
    HideWindow(winID, #False)
  CompilerEndIf
EndProcedure

Procedure handleSidebarResize(*tabBar.VerticalTabBarData, index.i, width.i)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
   SendMessage_(GadgetID(#CNT_CONTENT + index), #WM_SETREDRAW, 0, 0)
  CompilerEndIf
  
  For i = 0 To 5 
    ResizeGadget(#CNT_CONTENT + i, #PB_Ignore, #PB_Ignore, width, #PB_Ignore)
  Next

  ResizeGadget(#EDT_CMD,#PB_Ignore, #PB_Ignore, width-10 * DPI_Scale, #PB_Ignore)

  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(#CNT_CONTENT + index), #WM_SETREDRAW, 1, 0)
    RedrawWindow_(GadgetID(#CNT_CONTENT + index), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
  CompilerEndIf
  
  AppResizeGadget(#BTN_OK, width-205, #PB_Ignore, #PB_Ignore, #PB_Ignore)
  AppResizeGadget(#BTN_CANCEL, width-105, #PB_Ignore, #PB_Ignore, #PB_Ignore)
  
EndProcedure





windowWidth = 500
windowHeight = 300

; Create main window with DPI scaling
OpenWindow(#WIN_MAIN, 0, 0, windowWidth * DPI_Scale, windowHeight * DPI_Scale, "Monitor - VS Code Style", 
           #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_Invisible)

SetWindowColor(#WIN_MAIN, COLOR_BG_DARK)


#ICON_SIZE = 10
; Create mock icons
imgPresets = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(100, 100, 250), RGB(50, 50, 200))
imgCommand = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(100, 250, 100), RGB(50, 200, 50))
imgDirectory = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(250, 200, 100), RGB(200, 150, 50))
imgStatus = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(250, 100, 100), RGB(200, 50, 50))
imgReaction = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(250, 100, 250), RGB(200, 50, 200))
imgFilter = CreateMockIcon(#ICON_SIZE, #ICON_SIZE, RGB(100, 250, 250), RGB(50, 200, 200))

; Configure tabs
NewList tabConfigs.TabConfig()
AddElement(tabConfigs())
tabConfigs()\Name = "General"
tabConfigs()\IconImage = imgPresets
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
tabConfigs()\Name = "Directory"
tabConfigs()\IconImage = imgDirectory
tabConfigs()\ClickCallback = @OnTabClick()
AddElement(tabConfigs())
tabConfigs()\Name = "Status"
tabConfigs()\IconImage = imgStatus
tabConfigs()\ClickCallback = @OnTabClick()
AddElement(tabConfigs())
tabConfigs()\Name = "Reaction"
tabConfigs()\IconImage = imgReaction
tabConfigs()\ClickCallback = @OnTabClick()

tabConfigs()\Name = "Filter"
tabConfigs()\IconImage = imgFilter
tabConfigs()\ClickCallback = @OnTabClick()


Debug "DPI_Scale"
Debug DPI_Scale
; Create vertical tab bar


sidebarWidth = 28
sidebarExtendedWidth = 110


*TabBar = VerticalTabBar::Create(#WIN_MAIN, 0, 0, sidebarWidth, sidebarExtendedWidth, windowWidth-sidebarWidth, windowHeight, tabConfigs(),DPI_Scale, @handleSidebarResize())
Debug "DPI_Scale"
Debug DPI_Scale
; Get content container and add tab content inside it
contentContainerID = VerticalTabBar::GetContentContainerID(*TabBar)
OpenGadgetList(contentContainerID)

buttonAreaHeight = 35


; Content area containers - now inside the TabBar's content container
Define x = 0, y = 0, w = (windowWidth-sidebarWidth) * DPI_Scale, h = (windowHeight- buttonAreaHeight)* DPI_Scale


containerID = #CNT_CONTENT

; Tab 0 - Presets
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(#CNT_CONTENT + 0, #PB_Gadget_BackColor,  COLOR_BG_DARK)
xxx = TextGadget(#PB_Any,  10 * DPI_Scale, 10 * DPI_Scale, w-20 * DPI_Scale, h-20 * DPI_Scale, "Presets content goes here.")

SetGadgetColor(xxx, #PB_Gadget_FrontColor, RGB(255,255,0))


ButtonGadget(#BTN_COLOR, w-(100+5+10+10) * DPI_Scale, 5 * DPI_Scale, 100 * DPI_Scale, 15 * DPI_Scale, "Select Monitor Color...")
SetGadgetColor(#BTN_COLOR, #PB_Gadget_BackColor, RGB(60, 60, 60))
SetGadgetColor(#BTN_COLOR, #PB_Gadget_FrontColor, COLOR_TEXT)
ContainerGadget(#CNT_COLORPREVIEW, w-(10+10) * DPI_Scale, 7.5 * DPI_Scale, 10 * DPI_Scale, 10 * DPI_Scale, #PB_Container_BorderLess)
CloseGadgetList()
SetGadgetColor(#CNT_COLORPREVIEW, #PB_Gadget_BackColor, PatternColor)

CloseGadgetList()

; Tab 1 - Start Command
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
cg = ComboBoxGadget(#PB_Any, 5 * DPI_Scale, 5 * DPI_Scale, 150 * DPI_Scale, 15 * DPI_Scale)
AddGadgetItem(cg, -1,"Powershell")   
AddGadgetItem(cg, -1,"CMD")
AddGadgetItem(cg, -1,"WSL")
SetGadgetState(cg, 0)


SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)




EditorGadget(#EDT_CMD, 5 * DPI_Scale, 25 * DPI_Scale, w-10 * DPI_Scale, h - 100 * DPI_Scale)
SetGadgetColor(#EDT_CMD, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(#EDT_CMD, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)


CheckBoxGadget(#CHK_NOTIFY, 10 * DPI_Scale, 355 * DPI_Scale, 200 * DPI_Scale, 20 * DPI_Scale, "Enable Notifications")
SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_BackColor, COLOR_BG_DARK)
SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_FrontColor, COLOR_TEXT)



CloseGadgetList()

; Tab 1 - Start Command
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
cg = ComboBoxGadget(#PB_Any, 5 * DPI_Scale, 5 * DPI_Scale, 150 * DPI_Scale, 15 * DPI_Scale)
AddGadgetItem(cg, -1,"Powershell")   
AddGadgetItem(cg, -1,"CMD")
AddGadgetItem(cg, -1,"WSL")
SetGadgetState(cg, 0)


SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)




EditorGadget(#EDT_CMD+1000, 5 * DPI_Scale, 25 * DPI_Scale, w-10 * DPI_Scale, h - 100 * DPI_Scale)
SetGadgetColor(#EDT_CMD+1000, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(#EDT_CMD+1000, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)


CheckBoxGadget(#CHK_NOTIFY+1000, 10 * DPI_Scale, 355 * DPI_Scale, 200 * DPI_Scale, 20 * DPI_Scale, "Enable Notifications")
SetGadgetColor(#CHK_NOTIFY+1000, #PB_Gadget_BackColor, COLOR_BG_DARK)
SetGadgetColor(#CHK_NOTIFY+1000, #PB_Gadget_FrontColor, COLOR_TEXT)



CloseGadgetList()


; Tab 2 - Directory
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
elg = ExplorerListGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, w-20 * DPI_Scale, h-20 * DPI_Scale, "*.*", #PB_Explorer_MultiSelect)
SetGadgetColor(elg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(elg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 3 - Status
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
tg = TextGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, w-20 * DPI_Scale, h-20 * DPI_Scale, "Status content goes here.")
SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 4 - Reaction
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
tg = TextGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, w-20 * DPI_Scale, h-20 * DPI_Scale, "Reaction content goes here.")
SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 5 - Filter
containerID+1
ContainerGadget(containerID, x, y, w, h, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
tgx = TextGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, w-20 * DPI_Scale, h-20 * DPI_Scale, "Filter content goes here.")
SetGadgetColor(tgx, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(tgx, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

buttonContainer = ContainerGadget(#PB_Any, 0, h , w, buttonAreaHeight * DPI_Scale, #PB_Container_BorderLess)
SetGadgetColor(buttonContainer, #PB_Gadget_BackColor, RGB(65, 65, 65))

; Bottom buttons
ButtonGadget(#BTN_OK, w-(55+5+55+10) * DPI_Scale, 7 * DPI_Scale, 55 * DPI_Scale, 20 * DPI_Scale, "OK")
SetGadgetColor(#BTN_OK, #PB_Gadget_BackColor, COLOR_ACCENT)
SetGadgetColor(#BTN_OK, #PB_Gadget_FrontColor, RGB(255, 255, 255))

ButtonGadget(#BTN_CANCEL, w-(55+10) * DPI_Scale, 7 * DPI_Scale, 55 * DPI_Scale, 20 * DPI_Scale, "Cancel")
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_BackColor, RGB(60, 60, 60))
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_FrontColor, COLOR_TEXT)
CloseGadgetList()
CloseGadgetList()

SetGadgetColor(xxx, #PB_Gadget_BackColor, RGB(0,0,0))


; Show first tab
OnTabClick(0)




ApplyThemeHandle(WindowID(#WIN_MAIN))


Repeat : Delay(1) : Until WindowEvent() = 0

ShowWindowFadeIn(#WIN_MAIN)

; Main event loop
Repeat
  Delay(1)
  Event = WindowEvent()
  EventType = EventType()
  EventGadget = EventGadget()
  If Not VerticalTabBar::HandleEvent(*TabBar, EventGadget, Event)
    Select Event
      Case #PB_Event_Gadget
        ; Try to handle with TabBar first
        
        ; Handle other gadgets
        Select EventGadget
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
        
        
      Case #PB_Event_CloseWindow
        ; Ensure animation thread is stopped before closing
       
        Break
    EndSelect
  EndIf
ForEver
CloseWindow(#WIN_MAIN)

 If *TabBar And *TabBar\AnimationRunning
          WaitThread(*TabBar\AnimationThread)
        EndIf
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 599
; FirstLine = 589
; Folding = -----
; EnableThread
; EnableXP
; DPIAware
; DisableDebugger
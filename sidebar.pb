; VS Code-style vertical tab bar interface
; Color scheme matching VS Code Dark theme


DeclareModule App
  #WIN_MAIN = 0
  #CNT_CONTENT = 2
  #EDT_CMD = 200
  #EXP_DIR = 300
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
  Declare NormalResizeGadget(Gadget, x.f, y.f, width.f, height.f,parentsRoundingDeltaX.f = 0,parentsDeltaY.f = 0)
  Global DPI_Scale.f
  
  Global consoleFont
EndDeclareModule


Module App
  
  ExamineDesktops()
  Global DPI_Scale.f = DesktopResolutionX()
  

    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        fontName$ = "Consolas"
      CompilerCase #PB_OS_Linux
        fontName$ = "Monospace"
      CompilerCase #PB_OS_MacOS
        fontName$ = "Monaco"
    CompilerEndSelect
    
    Global consoleFont =  LoadFont(#PB_Any , fontName$, 8*DPI_Scale, #PB_Font_HighQuality)
  
  
  Structure FLOATPOINT
    x.l
    y.l
    
  EndStructure 
  
  Global NewMap GadgetPosition.FLOATPOINT ()
  
  Procedure NormalResizeGadget(Gadget, x.f, y.f, width.f, height.f,parentsRoundingDeltaX.f = 0,parentsRoundingDeltaY.f = 0)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
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
    
    ; Use current values for #PB_Ignore, apply DPI scaling otherwise
    If DPI_Scale <= 0
      DPI_Scale = 1.0
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
    CompilerElse
      ResizeGadget(Gadget, x,y,width,height)
    CompilerEndIf
    ProcedureReturn
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
  
  #PB_Event_RedrawHamburger = #PB_Event_FirstCustomValue
  
  Declare.i Create(window.i, x.i, y.i, sidebarWidth.i, expandedWidth.i, contentWidth.i, height.i, List tabConfigs.TabConfig(),User_DPI_Scale.f=1 , *resizeProc = 0)
  
  Declare DoResize(*tabBar.VerticalTabBarData,externalResize = #False )
  Declare Toggle(*tabBar.VerticalTabBarData)
  Declare Resize(*tabBar.VerticalTabBarData,contentWidth.i, contentHeight.i,externalResize = #False )
  Declare SetActiveTab(*tabBar.VerticalTabBarData, tabIndex.i)
  Declare HandleEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
  Declare GetWidth(*tabBar.VerticalTabBarData)
  Declare GetContentContainer(*tabBar.VerticalTabBarData)
  
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
    If StartDrawing(CanvasOutput(*tabBar\HamburgerGadget))
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
          yPos = canvasH/2 - (menuFontSize * DPI_Scale)/2 - 113.5 * DPI_Scale
        EndIf
        If hDC
          ReleaseDC_(GadgetID(gadget), hDC)
        EndIf
      CompilerElse
        ; Non-Windows fallback
        yPos = canvasH/2 - (menuFontSize * DPI_Scale)/2 - 113.5 * DPI_Scale
      CompilerEndIf
      If active
        DrawText(canvasH + 2 * DPI_Scale, yPos, *tabBar\TabConfigs(tabIndex)\Name, RGB(255, 255, 255))
      Else
        DrawText(canvasH + 2 * DPI_Scale, yPos, *tabBar\TabConfigs(tabIndex)\Name, RGB(245, 245, 245))
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
    
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        fontName$ = "Consolas"
      CompilerCase #PB_OS_Linux
        fontName$ = "Monospace"
      CompilerCase #PB_OS_MacOS
        fontName$ = "Monaco"
    CompilerEndSelect
    menuFont =  LoadFont(#PB_Any , "Segoe UI", menuFontSize*DPI_Scale ,#PB_Font_HighQuality)
    
    *tabBar\Window = window
    *tabBar\SidebarWidth = Round(sidebarWidth * DPI_Scale,#PB_Round_Down)
    *tabBar\SidebarExpandedWidth = Round(expandedWidth * DPI_Scale,#PB_Round_Down)
    *tabBar\IsExpanded = #False
    *tabBar\ActiveTabIndex = 0
    *tabBar\ContentX = x + *tabBar\SidebarWidth
    *tabBar\ContentY = y
    *tabBar\ContentWidth = Round(contentWidth * DPI_Scale,#PB_Round_Down)
    *tabBar\ContentHeight = Round(height * DPI_Scale,#PB_Round_Down)
    *tabBar\HoveredTabIndex = -1
    *tabBar\HamburgerHovered = #False
    *tabBar\AnimationLineWidth = Round(14.0 * DPI_Scale,#PB_Round_Down) ; Initial line width
    *tabBar\CurrentAnimationLineWidth = *tabBar\AnimationLineWidth
    *tabBar\AnimationRunning = #False
    *tabBar\window = window
    
    
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
    *tabBar\SidebarContainer = ContainerGadget(#PB_Any, x, y, *tabBar\SidebarWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    *tabBar\InnerSidebarContainer  = ContainerGadget(#PB_Any, 0, 0, *tabBar\SidebarExpandedWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(*tabBar\InnerSidebarContainer , #PB_Gadget_BackColor, COLOR_SIDEBAR)
    
    ; Create hamburger button (square, width = height = sidebarWidth)
    *tabBar\HamburgerGadget = CanvasGadget(#PB_Any, 0, 5 * DPI_Scale, *tabBar\SidebarWidth, *tabBar\SidebarWidth)
    GadgetToolTip(*tabBar\HamburgerGadget, "Toggle Menu")
    
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
    *tabBar\ContentContainer = ContainerGadget(#PB_Any, x + *tabBar\SidebarWidth, y, *tabBar\ContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    *tabBar\InnerContentContainer = ContainerGadget(#PB_Any, 0, 0, *tabBar\ContentWidth, *tabBar\ContentHeight, #PB_Container_BorderLess)
    SetGadgetColor(*tabBar\InnerContentContainer, #PB_Gadget_BackColor, COLOR_BG_DARK)
    
    CloseGadgetList()
    CloseGadgetList()
    
    *tabBar\ResizeCallback = *resizeProc
    
    ; Draw initial state
    RedrawAllTabs(*tabBar)
    
    
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
    RedrawWindow_(GadgetID(*tabBar\SidebarContainer), 0, 0,#RDW_ERASE | #RDW_INVALIDATE  | #RDW_UPDATENOW)
    RedrawWindow_(GadgetID(*tabBar\ContentContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE  | #RDW_UPDATENOW)
    RedrawWindow_(GadgetID(*tabBar\InnerSidebarContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    RedrawWindow_(GadgetID(*tabBar\InnerContentContainer), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    InvalidateRect_(GadgetID(*tabBar\ContentContainer), #Null, #False)
    InvalidateRect_(GadgetID(*tabBar\InnerContentContainer), #Null, #False)
    UpdateWindow_(GadgetID(*tabBar\ContentContainer))
    UpdateWindow_(GadgetID(*tabBar\InnerContentContainer))
  EndProcedure
  
  
  Procedure DoResize(*tabBar.VerticalTabBarData,externalResize = #False)
    sidebarDifference = *tabBar\SidebarExpandedWidth - *tabBar\SidebarWidth
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
      CallFunctionFast(*tabBar\ResizeCallback, *tabBar, *tabBar\ActiveTabIndex, newContentWidth,@parentsRoundingDeltaX )
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
    *tabBar\ContentWidth = Round(contentWidth * DPI_Scale,#PB_Round_Down)
    *tabBar\ContentHeight = Round(contentHeight * DPI_Scale,#PB_Round_Down)
    
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
  
  Procedure HandleEvent(*tabBar.VerticalTabBarData, eventGadget.i, event.i)
    
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
  
  Procedure GetContentContainer(*tabBar.VerticalTabBarData)
    ProcedureReturn *tabBar\InnerContentContainer
  EndProcedure
EndModule

;- ===== Main Code =====

UseModule App
UseModule VerticalTabBar


Global IsDarkModeActiveCached = #True

IncludeFile "utils.pb"
IncludeFile "winThemeGeneralUsage.pb"




desktopWidth =  DesktopWidth(0)

If desktopWidth >= 1920
  DPI_Scale = MaxF(1.5,DPI_Scale)
ElseIf desktopWidth > 1024
  DPI_Scale = MaxF(1.25,DPI_Scale)
EndIf 


Global *tabBar.VerticalTabBarData

Global buttonContainer


Global windowWidth = 500
Global windowHeight = 300
Global sidebarExtendedWidth = 110
Global buttonAreaHeight = 37
Global sidebarWidth = 28


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
    SendMessage_(GadgetID(#CNT_CONTENT + tabIndex), #WM_SETREDRAW, 0, 0)
  CompilerEndIf   
  
  
  For i = 0 To 6
    HideGadget(#CNT_CONTENT + i, #True)
  Next
  ; Show selected content
  HideGadget(#CNT_CONTENT + tabIndex, #False)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, 1, 0)
    RedrawWindow_(GadgetID(*tabBar\ContentContainer), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
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

Procedure HandleLayout(*tabBar.VerticalTabBarData, index.i, width, *parentsRoundingDeltaX)
  parentsRoundingDeltaX.f = PeekF(*parentsRoundingDeltaX)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(#CNT_CONTENT + index), #WM_SETREDRAW, 0, 0)
  CompilerEndIf
  
  NormalResizeGadget(#CNT_CONTENT + index, #PB_Ignore, #PB_Ignore, width, #PB_Ignore,parentsRoundingDeltaX)
  
  Debug "HandleLayout"
Debug index
  Select index 
    Case 0:
            Debug "#BTN_COLOR+"

      NormalResizeGadget(#BTN_COLOR, width-(150+10+10+10) * DPI_Scale, #PB_Ignore, #PB_Ignore, #PB_Ignore ,parentsRoundingDeltaX)
      NormalResizeGadget(#CNT_COLORPREVIEW, width-(10+10) * DPI_Scale, #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
                  Debug "#BTN_COLOR-"

    Case 1:
      Debug "#EDT_CMD+"
      NormalResizeGadget(#EDT_CMD,#PB_Ignore, #PB_Ignore,width-20* DPI_Scale, #PB_Ignore,parentsRoundingDeltaX) 
      Debug "#EDT_CMD-"
    Case 2:
      NormalResizeGadget(#EDT_CMD+1000,#PB_Ignore, #PB_Ignore,width-20* DPI_Scale, #PB_Ignore,parentsRoundingDeltaX)
    Case 3:
      NormalResizeGadget(#EXP_DIR,#PB_Ignore, #PB_Ignore,width-20, #PB_Ignore,parentsRoundingDeltaX)
  EndSelect
  
  
  
  NormalResizeGadget(#BTN_OK, width-(55+10+55+10)* DPI_Scale, #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
  NormalResizeGadget(#BTN_CANCEL, width-(55+10)* DPI_Scale, #PB_Ignore, #PB_Ignore, #PB_Ignore,parentsRoundingDeltaX)
  
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(#CNT_CONTENT + index), #WM_SETREDRAW, 1, 0)
    RedrawWindow_(GadgetID(#CNT_CONTENT + index), 0, 0, #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
  CompilerEndIf
  
EndProcedure










Procedure ResizeMainWindow() 
  
  Protected windowWidth = WindowWidth(#WIN_MAIN)
  Protected windowHeight = WindowHeight(#WIN_MAIN)

  SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #False, 0)
  SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #False, 0)
  
  Define x = 0, y = 0, width.f = windowWidth - sidebarWidth * DPI_Scale, height.f = windowHeight - buttonAreaHeight * DPI_Scale
  VerticalTabBar::Resize(*tabBar, windowWidth / DPI_Scale - sidebarWidth, windowHeight / DPI_Scale,#True )
  
  NormalResizeGadget(buttonContainer, #PB_Ignore, height, width+5, #PB_Ignore,*tabBar\ParentsRoundingDeltaX)
  NormalResizeGadget(#CNT_CONTENT + *tabBar\ActiveTabIndex, #PB_Ignore,#PB_Ignore,width,height,*tabBar\ParentsRoundingDeltaX)
  
  SendMessage_(GadgetID(*tabBar\SidebarContainer), #WM_SETREDRAW, #True, 0)
  SendMessage_(GadgetID(*tabBar\ContentContainer), #WM_SETREDRAW, #True, 0)
  
  ;RedrawWindow_(GadgetID(*tabBar\SidebarContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN) ; Omit #RDW_ERASE if your paint handlers fill the background fully
  ;RedrawWindow_(GadgetID(*tabBar\ContentContainer), #Null, #Null, #RDW_INVALIDATE | #RDW_ALLCHILDREN)
    
  RedrawWindow_(WindowID(#WIN_MAIN), #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW)
  
  
EndProcedure

Procedure WindowCallback(hwnd, msg, wParam, lParam)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected bg.l, fg.l
    If IsDarkModeActiveCached
      bg = RGBA(30, 30, 30,0)
      fg = RGB(220, 220, 220)
    Else
      bg = RGB(255, 255, 255)
      fg = RGB(0, 0, 0)
    EndIf
    Protected parentBrush.i
    
    

    
    
    Select msg
      Case #WM_SIZE
        ; Update clipping and force repaint for containers
        If hwnd <> WindowID(#WIN_MAIN)
          
          
        EndIf
        
      Case #WM_TIMER
        
        
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
      Case #WM_CTLCOLORBTN, #WM_CTLCOLORDLG, #WM_CTLCOLORSTATIC
        SetTextColor_(wParam, fg)
        SetBkMode_(wParam, #TRANSPARENT)
        hBrush = GetProp_(GetParent_(lParam), "BackgroundBrush")
        If hBrush
          SetTextColor_(wParam, fg)
          SetBkMode_(wParam, #TRANSPARENT)
          SetBkColor_(wParam, buttonContainerColor) ; Use stored color for consistency
          ProcedureReturn hBrush
        Else
          ProcedureReturn GetStockObject_(#NULL_BRUSH)
        EndIf
      Case #WM_CTLCOLORSTATIC  ; For static text
                               ; Set text color based on current theme (not just dark mode!)
        SetTextColor_(wParam, fg)
        SetBkMode_(wParam, #TRANSPARENT)
        parentBrush = GetClassLongPtr_(WindowID(#WIN_MAIN), #GCL_HBRBACKGROUND)
        If parentBrush
          ProcedureReturn parentBrush
        Else
          ProcedureReturn GetStockObject_(#NULL_BRUSH)
        EndIf
    EndSelect
    ProcedureReturn #PB_ProcessPureBasicEvents
  CompilerEndIf 
EndProcedure

Global NewList brushes.i()
Procedure SetGadgetBackgoundColor(gadget, COLOR_BG_DARK)
  SetGadgetColor(gadget, #PB_Gadget_BackColor, COLOR_BG_DARK)
  hBrush = CreateSolidBrush_(COLOR_BG_DARK)
  AddElement(brushes())
  brushes() = hBrush
  SetProp_(GadgetID(gadget), "BackgroundBrush", hBrush) 
EndProcedure 


; Create main window with DPI scaling
OpenWindow(#WIN_MAIN, 0, 0, windowWidth * DPI_Scale, windowHeight * DPI_Scale, "Monitor - VS Code Style", 
           #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget|#PB_Window_MaximizeGadget| #PB_Window_SizeGadget | #PB_Window_Invisible)

SetWindowColor(#WIN_MAIN, COLOR_BG_DARK)


SetWindowLongPtr_(WindowID(#WIN_MAIN), #GWL_STYLE, GetWindowLongPtr_(WindowID(#WIN_MAIN), #GWL_STYLE) | #WS_CLIPCHILDREN)

SetWindowCallback(@WindowCallback())
BindEvent(#PB_Event_SizeWindow, @ResizeMainWindow(),#WIN_MAIN)

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
AddElement(tabConfigs())

tabConfigs()\Name = "Filter"
tabConfigs()\IconImage = imgFilter
tabConfigs()\ClickCallback = @OnTabClick()


;Create vertical tab bar



*tabBar = VerticalTabBar::Create(#WIN_MAIN, 0, 0, sidebarWidth, sidebarExtendedWidth, windowWidth-sidebarWidth, windowHeight, tabConfigs(),DPI_Scale, @handleLayout())


; Get content container and add tab content inside it
InnerContentContainer = VerticalTabBar::GetContentContainer(*tabBar)
OpenGadgetList(InnerContentContainer)



; Content area containers - now inside the TabBar's content container
Define x = 0, y = 0, width.f = (windowWidth-sidebarWidth) * DPI_Scale, height.f = (windowHeight- buttonAreaHeight)* DPI_Scale


containerID = #CNT_CONTENT

; Tab 0 - General
ContainerGadget(containerID, x, y, 10000, 10000, #PB_Container_BorderLess)
SetGadgetBackgoundColor(#CNT_CONTENT + 0,  COLOR_BG_DARK)

ButtonGadget(#BTN_COLOR, width-(150+10+10+10) * DPI_Scale, 10 * DPI_Scale, 150 * DPI_Scale, 20 * DPI_Scale, "Select Monitor Color...")
SetGadgetColor(#BTN_COLOR, #PB_Gadget_BackColor, RGB(60, 60, 60))
SetGadgetColor(#BTN_COLOR, #PB_Gadget_FrontColor, COLOR_TEXT)
ContainerGadget(#CNT_COLORPREVIEW, width-(10+10) * DPI_Scale, 15 * DPI_Scale, 10 * DPI_Scale, 10 * DPI_Scale, #PB_Container_BorderLess)
CloseGadgetList()
SetGadgetColor(#CNT_COLORPREVIEW, #PB_Gadget_BackColor, PatternColor)

CloseGadgetList()

; Tab 1 - Start Command
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)
SetGadgetBackgoundColor(containerID,  COLOR_BG_DARK)
cg = ComboBoxGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, 150 * DPI_Scale, 15 * DPI_Scale)
AddGadgetItem(cg, -1,"Powershell")   
AddGadgetItem(cg, -1,"CMD")
AddGadgetItem(cg, -1,"WSL")
SetGadgetState(cg, 0)


SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)


EditorGadget(#EDT_CMD, 10 * DPI_Scale, 40 * DPI_Scale, width-20* DPI_Scale, height - 100 * DPI_Scale)
SetGadgetColor(#EDT_CMD, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(#EDT_CMD, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)

LoadLibrary_("Msftedit.dll")
SendMessage_(GadgetID(#EDT_CMD), #EM_SETTEXTMODE, #TM_RICHTEXT, 0)

SetGadgetFont(#EDT_CMD, FontID(consoleFont))
    

rect.RECT

; Get current formatting rectangle
SendMessage_(GadgetID(#EDT_CMD), #EM_GETRECT, 0, @rect)

; Adjust for padding: top=10px, bottom=10px, left=10px, right=10px
rect\top + 5* DPI_Scale
rect\bottom - 5* DPI_Scale
rect\left + 5* DPI_Scale
rect\right - 5* DPI_Scale

; Apply the new rectangle
SendMessage_(GadgetID(#EDT_CMD), #EM_SETRECT, 0, @rect)

CloseGadgetList()

; Tab 2 - Stop Command
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)

SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)

cg = ComboBoxGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, 150 * DPI_Scale, 15 * DPI_Scale)
AddGadgetItem(cg, -1,"Powershell")   
AddGadgetItem(cg, -1,"CMD")
AddGadgetItem(cg, -1,"WSL")
SetGadgetState(cg, 0)


SetGadgetColor(cg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(cg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)




EditorGadget(#EDT_CMD+1000, 10 * DPI_Scale, 40 * DPI_Scale, width-20* DPI_Scale, height - 100 * DPI_Scale)

SetGadgetColor(#EDT_CMD+1000, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(#EDT_CMD+1000, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)





CloseGadgetList()


; Tab 3 - Directory
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)
SetGadgetBackgoundColor(containerID, COLOR_BG_DARK)



ExplorerListGadget(#EXP_DIR, 10 * DPI_Scale, 10 * DPI_Scale, width-20 * DPI_Scale, height-20 * DPI_Scale, "*.*", #PB_Explorer_MultiSelect)
SetGadgetColor(#EXP_DIR, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(#EXP_DIR, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 4 - Status
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)

CheckBoxGadget(#CHK_NOTIFY, 10 * DPI_Scale, 200 * DPI_Scale, 200 * DPI_Scale, 20 * DPI_Scale, "Enable Notifications")
SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_BackColor, COLOR_BG_DARK)
SetGadgetColor(#CHK_NOTIFY, #PB_Gadget_FrontColor, COLOR_TEXT)

CloseGadgetList()

; Tab 5 - Reaction
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
tg = TextGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, width-20 * DPI_Scale, height-20 * DPI_Scale, "Reaction content goes here.")
SetGadgetColor(tg, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
SetGadgetColor(tg, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)
CloseGadgetList()

; Tab 6 - Filter
containerID+1
ContainerGadget(containerID, x, y, width, height, #PB_Container_BorderLess)
SetGadgetColor(containerID, #PB_Gadget_BackColor, COLOR_BG_DARK)
; tgx = TextGadget(#PB_Any, 10 * DPI_Scale, 10 * DPI_Scale, width-20 * DPI_Scale, height-20 * DPI_Scale, "Filter content goes here.")
; SetGadgetColor(tgx, #PB_Gadget_BackColor, COLOR_EDITOR_BG)
; SetGadgetColor(tgx, #PB_Gadget_FrontColor, COLOR_EDITOR_TEXT)

wv= WebViewGadget(#PB_Any,0,0, width, height)
SetGadgetText(wv, "http://www.google.de")

CloseGadgetList()


; Bottom buttons

buttonContainer = ContainerGadget(#PB_Any, 0, height , width+5, buttonAreaHeight * DPI_Scale, #PB_Container_BorderLess)
SetGadgetColor(buttonContainer, #PB_Gadget_BackColor, RGB(65, 65, 65))

hBrush = CreateSolidBrush_(RGB(65, 65, 65))
SetProp_(GadgetID(buttonContainer), "BackgroundBrush", hBrush) 


ButtonGadget(#BTN_OK, width-Round((55+10+55+10) * DPI_Scale,#PB_Round_Down), 8 * DPI_Scale, 55 * DPI_Scale, 20 * DPI_Scale, "OK")
SetGadgetColor(#BTN_OK, #PB_Gadget_BackColor, COLOR_ACCENT)
SetGadgetColor(#BTN_OK, #PB_Gadget_FrontColor, RGB(255, 255, 255))

ButtonGadget(#BTN_CANCEL, width-Round((55+10) * DPI_Scale,#PB_Round_Down), 8 * DPI_Scale, 55 * DPI_Scale, 20 * DPI_Scale, "Cancel")
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_BackColor, RGB(60, 60, 60))
SetGadgetColor(#BTN_CANCEL, #PB_Gadget_FrontColor, COLOR_TEXT)
CloseGadgetList()
CloseGadgetList()

; Show first tab
OnTabClick(0)
SetActiveTab(*tabBar,0)

;VerticalTabBar::Toggle(*tabBar)

ApplyThemeHandle(WindowID(#WIN_MAIN))


Repeat : Delay(1) : Until WindowEvent() = 0

ShowWindowFadeIn(#WIN_MAIN)

; Main event loop
Repeat
  
  
   
  Event = WaitWindowEvent()
  
   
  EventType = EventType()
  EventGadget = EventGadget()
  If Not VerticalTabBar::HandleEvent(*tabBar, EventGadget, Event)
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
            Break
        EndSelect
        
        
      Case #PB_Event_CloseWindow
        ; Ensure animation thread is stopped before closing
        
        Break
    EndSelect
  EndIf
ForEver
CloseWindow(#WIN_MAIN)

If *tabBar And *tabBar\AnimationRunning
  WaitThread(*tabBar\AnimationThread)
EndIf

ForEach brushes()
  DeleteObject_(brushes())
Next 
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 225
; FirstLine = 192
; Folding = ------
; EnableThread
; EnableXP
; DPIAware
; Executable = ..\..\sidebar.exe
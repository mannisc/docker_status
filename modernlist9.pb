; DPI Detection at the very top - exactly as requested



DeclareModule App
  Global IsDarkModeActiveCached = #True
  Global darkThemeBackgroundColor = RGB(30,30,30)
  Global darkThemeForegroundColor = RGB(255, 255, 255)
  Global lightThemeBackgroundColor = RGB(250,250,250)
  Global lightThemeForegroundColor = RGB(0,0,0)
EndDeclareModule

Module App
EndModule


IncludeFile "modernListElement.pb"

UseModule App
UseModule ModernListElement
UseModule ModernList

ExamineDesktops()

Global *list.ModernListData








Procedure DestroyGadget(gadget.i)
  If IsGadget(gadget)
    FreeGadget(gadget)
  EndIf
EndProcedure

Procedure HandleButtonEvent(*list.ModernListData, index ,eventGadget.i, event.i,childIndex, whichGadget = 0)
  
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
  Protected *childGadgets.ChildGadgets = AllocateStructure(ChildGadgets)
  If *childGadgets
    InitializeStructure(*childGadgets, ChildGadgets) ; Important for lists/maps!
    AddElement(*childGadgets\Gadgets())
    *childGadgets\Gadgets() = g
  EndIf
  
  ProcedureReturn *childGadgets
EndProcedure

Global ButtonInterface.GadgetInterface
ButtonInterface\Create = @CreateButtonGadget()
ButtonInterface\HandleEvent = @HandleButtonEvent()
ButtonInterface\AutoResize = #True
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
  Protected *childGadgets.ChildGadgets = AllocateStructure(ChildGadgets)
  If *childGadgets
    InitializeStructure(*childGadgets, ChildGadgets) ; Important for lists/maps!
    AddElement(*childGadgets\Gadgets())
    *childGadgets\Gadgets() = g
  EndIf
  
  ProcedureReturn *childGadgets
EndProcedure

Global ComboInterface.GadgetInterface
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
  
  If IsGadget(g1)
    If IsDarkModeActiveCached
      SetGadgetColor(g1, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      SetGadgetColor(g1, #PB_Gadget_FrontColor, darkThemeForegroundColor)
    Else
      SetGadgetColor(g1, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      SetGadgetColor(g1, #PB_Gadget_FrontColor, lightThemeForegroundColor)
    EndIf
  EndIf
  If IsGadget(g2)
    If IsDarkModeActiveCached
      SetGadgetColor(g2, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      SetGadgetColor(g2, #PB_Gadget_FrontColor, darkThemeForegroundColor)
    Else
      SetGadgetColor(g2, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      SetGadgetColor(g2, #PB_Gadget_FrontColor, lightThemeForegroundColor)
    EndIf
  EndIf
  Protected *childGadgets.ChildGadgets = AllocateStructure(ChildGadgets)
  If *childGadgets
    InitializeStructure(*childGadgets, ChildGadgets) ; Important for lists/maps!
    AddElement(*childGadgets\Gadgets())
    *childGadgets\Gadgets() = g1
    AddElement(*childGadgets\Gadgets())
    *childGadgets\Gadgets() = g2
  EndIf
  
  ProcedureReturn *childGadgets
EndProcedure

Global StringInterface.GadgetInterface
StringInterface\Create = @CreateStringGadget()
StringInterface\HandleEvent = @HandleStringEvent()
StringInterface\Destroy = @DestroyGadget()

Procedure CreateMockImage()
  Protected img.i = CreateImage(#PB_Any, 32, 32, 32)
  If StartDrawing(ImageOutput(img))
    Box(0, 0, 32, 32, RGB(255, 0, 0))
    LineXY(0, 0, 32, 32, RGB(255, 255, 255))
    LineXY(0, 32, 32, 0, RGB(255, 255, 255))
    StopDrawing()
  EndIf
  ProcedureReturn img
EndProcedure

Procedure ListResizeCallback(*list.ModernListData, width.i, height.i)
  Debug "List resized to " + Str(width) + "x" + Str(height)
EndProcedure



Procedure ResizeWindowCallback() 
  
  Protected windowWidth = WindowWidth(0)
  Protected windowHeight = WindowHeight(0)
  
  ModernList::ResizeList(*list, windowWidth, windowHeight)
  
  
  ;RedrawWindow_(WindowID(0), #Null, #Null,  #RDW_INVALIDATE | #RDW_ALLCHILDREN|#RDW_UPDATENOW)
EndProcedure 




Procedure Main()
  DPI_Scale.f = DesktopResolutionX()
  
  If OpenWindow(0, 0, 0, 750, 500, "ModernList Example with Flex Layout - DPI: " + StrF(DPI_Scale * 100, 0) + "%", #PB_Window_SystemMenu | #PB_Window_ScreenCentered| #PB_Window_SizeGadget|#PB_Window_MaximizeGadget)
    Protected mockImage.i = CreateMockImage()
              BindEvent(#PB_Event_SizeWindow, @ResizeWindowCallback(),0)


    Define header.ModernList::ListHeader
    header\Height = 30
    
    ; Header with flex layout
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "Sym"
    header\Columns()\Width = 50  ; Fixed width
    
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "Name"
    header\Columns()\Flex = 2.0  ; Takes 2/3 of remaining space
    header\Columns()\MinWidth = 100  ; But never smaller than 100px
    
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "Action"
    header\Columns()\Flex = 1.0  ; Takes 1/3 of remaining space
    header\Columns()\MinWidth = 80  ; But never smaller than 80px
    
    NewList rows.ListRow()
    
    ; Row 1: Using flex layout
    AddElement(rows())
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Image
    rows()\Elements()\Content = Str(mockImage)
    rows()\Elements()\Width = 50  ; Fixed width
    rows()\Elements()\Alignment = 1
    rows()\Elements()\HoveredTintColor = RGBA(0, 0, 255, 50)
    rows()\Elements()\SelectedTintColor = RGBA(255, 255, 255, 50)
    rows()\Elements()\SelectedHoveredTintColor = RGBA(200, 200, 200, 50)
    
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "Name 1"
    rows()\Elements()\Flex = 2.0  ; Twice as wide as button column
    rows()\Elements()\MinWidth = 100  ; Minimum 100px
    rows()\Elements()\Alignment = 0

    
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Gadget
    rows()\Elements()\Content = "Button 1"
    rows()\Elements()\Interface = @ButtonInterface
    rows()\Elements()\Flex = 1.0  ; Half as wide as name column
    rows()\Elements()\MinWidth = 80  ; Minimum 80px
    
    ; Row 2: Different content, same flex ratios
    AddElement(rows())
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Image
    rows()\Elements()\Content = Str(mockImage)
    rows()\Elements()\Width = 50  ; Fixed width
    rows()\Elements()\Alignment = 1
    rows()\Elements()\HoveredTintColor = RGBA(0, 0, 255, 50)
    rows()\Elements()\SelectedTintColor = RGBA(255, 255, 255, 50)
    rows()\Elements()\SelectedHoveredTintColor = RGBA(200, 200, 200, 50)
    
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "Item 3 xxxxxxxxxxxxxxxxxxxxxxxx"
    rows()\Elements()\Flex = 2.0  ; Same flex ratio
    rows()\Elements()\MinWidth = 100
    rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
    rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
    
    
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Gadget
    rows()\Elements()\Content = "Button 2"
    rows()\Elements()\Interface = @ButtonInterface
    rows()\Elements()\Flex = 1.0  ; Same flex ratio
    rows()\Elements()\MinWidth = 80
    
    ; Add more rows to demonstrate flex layout with different content
    For i = 3 To 20
      AddElement(rows())
      
      AddElement(rows()\Elements())
      rows()\Elements()\Type = ModernListElement::#Element_Image
      rows()\Elements()\Content = Str(mockImage)
      rows()\Elements()\Width = 50
      rows()\Elements()\Alignment = 1
      
      AddElement(rows()\Elements())
      rows()\Elements()\Type = ModernListElement::#Element_Text
      rows()\Elements()\Content = "Row " + Str(i) + " with flexible width"
      rows()\Elements()\Flex = 2.0
      rows()\Elements()\MinWidth = 100
      
      AddElement(rows()\Elements())
      If i % 3 = 0
        rows()\Elements()\Type = ModernListElement::#Element_Gadget
        rows()\Elements()\Content = "Button " + Str(i)
        rows()\Elements()\Interface = @ButtonInterface
      Else
        rows()\Elements()\Type = ModernListElement::#Element_Text
        rows()\Elements()\Content = "Text " + Str(i)
      EndIf
      rows()\Elements()\Flex = 1.0
      rows()\Elements()\MinWidth = 80
    Next
    
    DPI_Scale.f = DesktopResolutionX()
    
    *list.ModernListData = ModernList::CreateList(0, 0, 0, 750, 500, 0, rows(), @header, 30, DPI_Scale, @ListResizeCallback())
    
    Protected lastMouseX.i = -1
    Protected lastMouseY.i = -1
    
    Repeat
      Protected event.i = WaitWindowEvent()
      
      Protected currentMouseX.i = WindowMouseX(0)
      Protected currentMouseY.i = WindowMouseY(0)
      
      If currentMouseX <> lastMouseX Or currentMouseY <> lastMouseY
        ModernList::UpdateHoverState(*list)
        lastMouseX = currentMouseX
        lastMouseY = currentMouseY
      EndIf
      
      Select event
        Case #PB_Event_Gadget
          If ModernList::HandleListEvent(*list, EventGadget(), EventType())
          Else
            ; Debug "Unhandled gadget event: Gadget=" + Str(EventGadget()) + ", Type=" + Str(EventType())
          EndIf

        Case #PB_Event_CloseWindow
          Break
      EndSelect
    ForEver
    
    FreeImage(mockImage)
    FreeMemory(*list)
    FreeFont(rowFont)
    FreeFont(headerFont)
  EndIf
EndProcedure

Main()
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 15
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; Executable = ..\..\list.exe
; DisableDebugger

DeclareModule ModernListElement
  Enumeration ElementTypes
    #Element_Space
    #Element_Text
    #Element_Image
    #Element_Gadget
  EndEnumeration
  
  Prototype.i ProtoCreateGadget(parentGadget.i, content.s, x.i, y.i, width.i, height.i)
  Prototype.i ProtoHandleGadgetEvent(*list, content.s, *interfaceData, index.i ,eventGadget.i, event.i ,childIndex.i, whichGadget = 0)
  Prototype ProtoDestroyGadget(gadget.i)
  
  
  
  Declare CreateElement(rowGadget.i, x.i, y.i,marginTop.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface=0, autoResize=#False)
  Declare Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
  Declare HandleEvent(currentElementMap.s,foundRowGadget, foundCellGadget, foundChildGadget,childIndex,  eventGadget.i, event.i, *list, index)
  
  Structure GadgetInterface
    *Create.ProtoCreateGadget
    *HandleEvent.ProtoHandleGadgetEvent
    *Destroy.ProtoDestroyGadget
    AutoResize.b
  EndStructure
  
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
    AutoResize.b
    *InterfaceData.GadgetInterface
  EndStructure
  
  Global NewMap ElementMap.ModernListElementData()
  
  
  
EndDeclareModule

Module ModernListElement
  
  
  Procedure CreateElement(rowGadget.i, x.i, y.i,marginTop.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface.GadgetInterface=0, autoResize=#False)
    Protected g.i = 0
    Protected containerGadget.i = 0
    Protected gadgetToStore.i = 0
    Protected *childGadgets.ChildGadgets = 0
    
    If type = #Element_Gadget And *interface
      
      containerGadget = ContainerGadget(#PB_Any, x, y+marginTop, width, height)
      
      *childGadgets = *interface\Create(containerGadget,content, 0, 0, width, height-marginTop)
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
    ElementMap()\InterfaceData =  *interface
    If *interface
      ElementMap()\EventProc = *interface\HandleEvent
      ElementMap()\DestroyProc = *interface\Destroy
      
      ElementMap()\AutoResize = *interface\AutoResize
      If Not ElementMap()\AutoResize
        ElementMap()\AutoResize = autoResize
      EndIf 
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
      Debug "!!!HandleEvent "+Str(event)
      Debug "TYPE "+Str(foundRowGadget)+" "+Str(foundCellGadget)+" "+Str(foundChildGadget)+" "
      Debug "currentElementMap #"+currentElementMap
      If currentElementMap<>"" And    FindMapElement(ElementMap(),currentElementMap)
        
        If ElementMap()\Type = #Element_Gadget And ElementMap()\EventProc
          Protected actualGadget.i = 0
          ; The event came from the child gadget (button, combo, etc.)
          If foundChildGadget
            Debug "CHILD ööööö"
            actualGadget = eventGadget
            handled = ElementMap()\EventProc(*list,ElementMap()\Content,ElementMap()\InterfaceData, index,actualGadget, event,childIndex, 0 )
            
                        
            ; The event came from the container
          ElseIf IsGadget(ElementMap()\Gadget)
            actualGadget = GetGadgetData(ElementMap()\Gadget)
            If actualGadget = 0
              actualGadget = eventGadget
            EndIf
            
            If foundCellGadget 
              handled = ElementMap()\EventProc(*List,ElementMap()\Content,ElementMap()\InterfaceData, index ,actualGadget, event,-1, 1 )
            Else ; RowGadget
              handled = ElementMap()\EventProc(*list,ElementMap()\Content,ElementMap()\InterfaceData, index ,actualGadget, event,-1, 2 )
            EndIf 
          EndIf
        EndIf
        If #False And Not handled ; mapKey empty for these gadget -> ERROR FIX IF NEEDED
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
    Flex.f
    MinWidth.i
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
    AutoResize.b
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
    MarginSide.i
    MarginElementTop.i
    AddLeftScrollbarMaring.b
    *ResizeCallback
    AnimationRunning.i
    DPI_Scale.f
    Array rowGadgets.i(0)
    IsResizing.i      
    ResizeEndTime.q 
  EndStructure
  
  Global rowFont
  Global headerFont
  
  Declare SetColors()
  Declare Refresh(*list.ModernListData)
  Declare DrawHeader(*list.ModernListData)
  Declare DrawRow(*list.ModernListData, rowIndex.i, gadget.i, active.i, hovered.i)
  Declare RedrawAll(*list.ModernListData)
  Declare CreateList(window.i, x.i, y.i, width.i, height.i, marginSide, marginElementTop, addLeftScrollbarMaring, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=30, User_DPI_Scale.f=1, *resizeProc=0)
  Declare AddRow(*list.ModernListData, List elements.ListElement(), height.i=0, userData.i=0)
  Declare SetRow(*list.ModernListData, rowIndex.i, List elements.ListElement(), height.i=0, userData.i=0)
  Declare ClearRows(*list.ModernListData)
  Declare DoResize(*list.ModernListData, externalResize=#False)
  Declare ResizeList(*list.ModernListData, width.i, height.i)
  Declare UpdateHoverState(*list.ModernListData)
  Declare HandleListEvent(*list.ModernListData, eventGadget.i, event.i)
  Declare GetSelectedRow(*list.ModernListData)
  Declare GetInnerContainer(*list.ModernListData)
  Declare CleanUp()
EndDeclareModule

Module ModernList
  UseModule App
  UseModule ModernListElement
  
  Global COLOR_EDITOR_BG = RGB(0, 0, 0)
  Global COLOR_EDITOR_TEXT = RGB(212, 212, 212)
  Global PatternColor = RGB(255, 0, 0)
  Global menuFontSize.f = 7
  Global menuFont
  Global colorAccent
  Global colorHover
  Global colorHeader
  Global inactiveForegroundColor
  Global rowFont
  Global headerFont
  
  
  
  ; =============================================================================
  ; IsBelowMousePointer – Plattformübergreifend
  ; =============================================================================
  
  Global NewList brushes.i()
  
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
    
    ; Get the width of the vertical scrollbar for the current OS
    Procedure.i GetScrollbarWidth(DPI_Scale)
      CompilerSelect #PB_Compiler_OS
        CompilerCase #PB_OS_Windows
          ProcedureReturn Round(GetSystemMetrics_(#SM_CXVSCROLL)/DPI_Scale,#PB_Round_Up)
        CompilerCase #PB_OS_MacOS
          ProcedureReturn 15  ; macOS typically uses 15px scrollbars
        CompilerCase #PB_OS_Linux
          ProcedureReturn 16  ; Linux/GTK typically uses 16px scrollbars
      CompilerEndSelect
      ProcedureReturn 15  ; Default fallback
    EndProcedure
    
    ; Calculate element widths based on flex and fixed widths
    Procedure.i CalculateElementWidths(List elements.ListElement(), containerWidth.i, Array calculatedWidths.i(1))
      Protected totalFixedWidth.i = 0
      Protected totalFlex.f = 0
      Protected elementCount.i = ListSize(elements())
      
      If elementCount = 0
        ProcedureReturn 0
      EndIf
      
      ReDim calculatedWidths(elementCount - 1)
      
      ; First pass: calculate total fixed width and flex
      Protected index.i = 0
      ForEach elements()
        If elements()\Width > 0
          calculatedWidths(index) = elements()\Width
          totalFixedWidth + elements()\Width
        ElseIf elements()\Flex > 0
          totalFlex + elements()\Flex
        EndIf
        index + 1
      Next
      
      ; Calculate remaining space for flex items
      Protected remainingWidth.i = containerWidth - totalFixedWidth
      If remainingWidth < 0
        remainingWidth = 0
      EndIf
      
      ; Second pass: distribute remaining width according to flex values
      If totalFlex > 0 And remainingWidth > 0
        index = 0
        ForEach elements()
          If elements()\Width = 0 And elements()\Flex > 0
            Protected calculatedWidth.i = Round((elements()\Flex / totalFlex) * remainingWidth, #PB_Round_Down)
            ; Apply minimum width constraint
            If elements()\MinWidth > 0 And calculatedWidth < elements()\MinWidth
              calculatedWidth = elements()\MinWidth
            EndIf
            calculatedWidths(index) = calculatedWidth
          EndIf
          index + 1
        Next
      ElseIf totalFlex > 0
        ; No remaining width, apply only minimum widths
        index = 0
        ForEach elements()
          If elements()\Width = 0 And elements()\Flex > 0
            If elements()\MinWidth > 0
              calculatedWidths(index) = elements()\MinWidth
            Else
              calculatedWidths(index) = 0
            EndIf
          EndIf
          index + 1
        Next
      EndIf
      
      ProcedureReturn elementCount
    EndProcedure
    
    Procedure SetColors()
      If IsDarkModeActiveCached
        colorHover = RGB(45, 45, 45)
        colorHeader = RGB(51, 51, 51)
        colorAccent = RGB(0, 122, 204)
        inactiveForegroundColor = RGB(220,220,220)
      Else
        colorHover = RGB(230, 230, 230)
        colorHeader = RGB(240, 240, 240)
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
          Box(0, 0, OutputWidth(), OutputHeight(), colorHeader)
          
          ; Calculate available width (subtract scrollbar width)
          Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
          Protected availableWidth.i = *list\Width - scrollbarWidth
          
          ; Calculate column widths using flex
          Dim calculatedWidths.i(ListSize(*list\Header\Columns()) - 1)
          CalculateElementWidths(*list\Header\Columns(), availableWidth, calculatedWidths())
          
          xPos = *list\MarginSide
          If *list\AddLeftScrollbarMaring
            xPos = xPos + scrollbarWidth
          EndIf 
          DrawingMode(#PB_2DDrawing_Transparent)
          DrawingFont(FontID(headerFont))
          
          Protected colIndex.i = 0
          ForEach *list\Header\Columns()
            colWidth = calculatedWidths(colIndex) * *list\DPI_Scale
            Select *list\Header\Columns()\Type
              Case #Element_Text
                text$ = *list\Header\Columns()\Content
                foreColor = *list\Header\Columns()\ForeColor
                If foreColor = 0
                  foreColor = inactiveForegroundColor
                EndIf
                yPos = (OutputHeight() - TextHeight(text$)) / 2
                DrawText(xPos + 5 * *list\DPI_Scale, yPos, text$, foreColor)
              Case #Element_Image
                If Val(*list\Header\Columns()\Content) > 0
                  imgID = Val(*list\Header\Columns()\Content)
                  DrawImage(ImageID(imgID), xPos + (colWidth - ImageWidth(imgID)) / 2, (OutputHeight() - ImageHeight(imgID)) / 2)
                EndIf
            EndSelect
            xPos + colWidth
            colIndex + 1
          Next
          
          StopDrawing()
        EndIf
      EndIf
    EndProcedure
    
    
    
    Procedure RemoveBrush(hBrush)
      If hBrush = 0
        ProcedureReturn
      EndIf 
      ForEach brushes()
        If hBrush = brushes()
          DeleteObject_(hBrush)
          DeleteElement(brushes())
          Break
        EndIf 
      Next 
    EndProcedure
    
    Procedure SetGadgetBackgoundColor(gadget, bg)
      If IsGadget(gadget)
        SetGadgetColor(gadget, #PB_Gadget_BackColor, bg)
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows: 
          
          RemoveBrush(GetProp_(GadgetID(gadget), "BackgroundBrush"))
          hBrush = CreateSolidBrush_(bg)
          AddElement(brushes())
          brushes() = hBrush
          SetProp_(GadgetID(gadget), "BackgroundBrush", hBrush) 
        CompilerEndIf
      EndIf 
    EndProcedure 
    
    Procedure DrawRow(*list.ModernListData, rowIndex.i, gadget.i, active.i, hovered.i)
      
      If gadget And IsGadget(gadget)
        
        If StartDrawing(CanvasOutput(gadget))
          DrawingMode(#PB_2DDrawing_Transparent)
          DrawingFont(FontID(rowFont))
          Protected canvasW.i = OutputWidth()
          Protected canvasH.i = OutputHeight()
          Protected xPos.i, elemWidth.i, foreColor.i, backColor.i ,text$, textW.i, textH.i, yPos.i, xAlign.i, imgID.i, imgW.i, imgH.i, yAlign.i, tintColor.i
          
          Protected isSelected.i = active
          Protected isHovered.i = hovered
          
          
          yMarginPos = *list\MarginElementTop**list\DPI_Scale
          
          SetColors()
          If IsDarkModeActiveCached
            Box(0, 0, canvasW, canvasH, darkThemeBackgroundColor)
          Else
            Box(0, 0, canvasW, canvasH, lightThemeBackgroundColor)
          EndIf
          If isSelected
            Box(0, yMarginPos, canvasW, canvasH-yMarginPos, colorAccent)
          ElseIf isHovered
            Box(0, yMarginPos, canvasW, canvasH-yMarginPos, colorHover)
          EndIf
          StopDrawing()
          
          SelectElement(*list\Rows(), rowIndex)
          
          ; Calculate available width (subtract scrollbar width)
          Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
          Protected availableWidth.i = *list\Width - scrollbarWidth
          
          ; Calculate element widths using flex
          Dim calculatedWidths.i(ListSize(*list\Rows()\Elements()) - 1)
          CalculateElementWidths(*list\Rows()\Elements(), availableWidth, calculatedWidths())
          
          xPos = 0
          Protected elemIndex.i = 0
          ForEach *list\Rows()\Elements()
            elemWidth = calculatedWidths(elemIndex) * *list\DPI_Scale
            If StartDrawing(CanvasOutput(gadget))
              DrawingMode(#PB_2DDrawing_Transparent)
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
              If backColor<>0
                Box(xPos, yMarginPos, elemWidth, canvasH, backColor)
              EndIf 
              StopDrawing()
              
            EndIf 
            Select *list\Rows()\Elements()\Type
              Case #Element_Text
                If StartDrawing(CanvasOutput(gadget))
                  DrawingMode(#PB_2DDrawing_Transparent)
                  DrawingFont(FontID(rowFont))
                  ClipOutput(xPos, yPos, elemWidth-2, canvasH)
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
                  yPos = (canvasH - yMarginPos - textH) / 2
                  Select *list\Rows()\Elements()\Alignment
                    Case 1
                      xAlign = (elemWidth - textW) / 2
                    Case 2
                      xAlign = elemWidth - textW - 5 * *list\DPI_Scale
                    Default
                      xAlign = 5 * *list\DPI_Scale
                  EndSelect
                  
                  DrawText(xPos + xAlign, yMarginPos+yPos , text$,foreColor)
                  StopDrawing()
                  
                EndIf 
              Case #Element_Image
                If StartDrawing(CanvasOutput(gadget))
                  DrawingMode(#PB_2DDrawing_Transparent)
                  ClipOutput(xPos, yPos, elemWidth, canvasH)
                  
                  If Val(*list\Rows()\Elements()\Content) > 0
                    imgID = Val(*list\Rows()\Elements()\Content)
                    imgW = ImageWidth(imgID)
                    imgH = ImageHeight(imgID)
                    DrawingMode(#PB_2DDrawing_Default)
                    Select *list\Rows()\Elements()\Alignment
                      Case 1
                        xAlign = (elemWidth - imgW) / 2
                      Case 2
                        xAlign = elemWidth - imgW - 5 * *list\DPI_Scale
                      Default
                        xAlign = 5 * *list\DPI_Scale
                    EndSelect
                    yAlign = (canvasH - yMarginPos - imgH) / 2
                    DrawImage(ImageID(imgID), xPos + xAlign, yMarginPos+yAlign)
                    
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
                      Box(xPos, yMarginPos, elemWidth*DPI_Scale, canvasH, tintColor)
                    EndIf
                  EndIf
                  StopDrawing()
                  
                EndIf
            EndSelect
            
            xPos + elemWidth
            elemIndex + 1
          Next
          
          
          
        EndIf
        
        ;Background for Gadget
        ForEach ElementMap()
          If ElementMap()\Gadget And ElementMap()\RowGadget = gadget
            If isSelected
              SetGadgetBackgoundColor(ElementMap()\Gadget, colorAccent)
            ElseIf isHovered
              SetGadgetBackgoundColor(ElementMap()\Gadget, colorHover)
            Else
              If IsDarkModeActiveCached
                SetGadgetBackgoundColor(ElementMap()\Gadget, darkThemeBackgroundColor)
              Else
                SetGadgetBackgoundColor(ElementMap()\Gadget,lightThemeBackgroundColor)
              EndIf
            EndIf  
            ; InvalidateRect_(GadgetID(ElementMap()\Gadget) , #Null, #True)
            RedrawWindow_(GadgetID(ElementMap()\Gadget), 0, 0,  #RDW_INVALIDATE | #RDW_UPDATENOW | #RDW_ALLCHILDREN)
            
          EndIf 
        Next  
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
    
    
    
    
    Procedure CreateList(window.i, x.i, y.i, width.i, height.i, marginSide, marginElementTop, addLeftScrollbarMaring, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=30, User_DPI_Scale.f=1, *resizeProc=0)
      
      If IsDarkModeActiveCached
        bg = darkThemeBackgroundColor
      Else
        bg = lightThemeBackgroundColor
      EndIf
      
      Protected *list.ModernListData = AllocateMemory(SizeOf(ModernListData))
      Protected rowCount.i, yPos.i, rowIndex.i, elemW.i, xElem.i, rowGadget.i
      SetColors()
      
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
      Debug "WINDOW######"+Str(window)
      *list\Window = window
      *list\Width = width 
      *list\Height = height
      *list\RowHeight = defaultRowHeight
      
      If marginSide = 0
        marginSide = 3
      EndIf 
      *list\MarginSide = marginSide
      
      *list\AddLeftScrollbarMaring= addLeftScrollbarMaring
      *list\MarginElementTop = marginElementTop
      
      *list\ActiveRowIndex = -1
      *list\HoveredRowIndex = -1
      *list\DPI_Scale = User_DPI_Scale
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
      
      
      ; Calculate available width without scrollbar
      Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
      Protected innerWidth.i 
      If *list\AddLeftScrollbarMaring
        innerWidth.i = Round(( *list\Width - scrollbarWidth - *list\MarginSide*2)/*list\DPI_Scale, #PB_Round_Down   )* *list\DPI_Scale
      Else
        innerWidth.i = Round(( *list\Width - scrollbarWidth - *list\MarginSide*2)/*list\DPI_Scale, #PB_Round_Down   )* *list\DPI_Scale
      EndIf 
      If innerWidth < 0
        innerWidth = 0
      EndIf 
      Protected availableWidth.i = innerWidth
      Protected listContentWidth.i = availableWidth
      If *list\AddLeftScrollbarMaring
        listContentWidth = listContentWidth- scrollbarWidth
      EndIf 
      
      *list\ScrollArea = ScrollAreaGadget(#PB_Any, 0, scrollY, *list\Width, scrollH, innerWidth, totalRowHeight, 0, #PB_ScrollArea_BorderLess)
      SetGadgetColor(*list\ScrollArea,#PB_Gadget_BackColor,bg)
      
      
      *list\InnerContainer = ContainerGadget(#PB_Any, 0 , 0, innerWidth, totalRowHeight, #PB_Container_BorderLess)
      xPos = 0
      If *list\AddLeftScrollbarMaring
        xPos = xPos + scrollbarWidth
      EndIf 
      
      yPos = 0
      rowIndex = 0
      Dim *list\rowGadgets(rowCount - 1)
      ForEach *list\Rows()
        rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        rowGadget = CanvasGadget(#PB_Any,xPos , yPos, listContentWidth, rowH, #PB_Canvas_Container | #PB_Canvas_Keyboard)
        
        
        ; Calculate element widths using flex
        Dim elemWidths.i(ListSize(*list\Rows()\Elements()) - 1)
        CalculateElementWidths(*list\Rows()\Elements(), listContentWidth, elemWidths())
        
        xElem = 0
        Protected elementIndex.i = 0
        
        Protected widthIndex.i = 0
        ForEach *list\Rows()\Elements()
          elemW = elemWidths(widthIndex)
          Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
          *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0,*list\MarginElementTop, elemW, rowH, *List\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface, autoResize)
          xElem + elemW
          elementIndex + 1
          widthIndex + 1
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
      
      ; Calculate available width without scrollbar
      Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
      Protected innerWidth.i = *list\Width - scrollbarWidth
      
      Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos, innerWidth, *list\Rows()\Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
      
      ; Calculate available width (subtract scrollbar width)
      Protected availableWidth.i = *list\Width - scrollbarWidth
      
      ; Calculate element widths using flex
      Dim elemWidths.i(ListSize(*list\Rows()\Elements()) - 1)
      CalculateElementWidths(*list\Rows()\Elements(), availableWidth, elemWidths())
      
      Protected xElem.i = 0
      Protected elementIndex.i = 0
      Protected widthIndex.i = 0
      ForEach *list\Rows()\Elements()
        Protected elemW.i = elemWidths(widthIndex)
        Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
        *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0,*list\MarginElementTop, elemW, *list\Rows()\Height, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface)
        xElem + elemW
        elementIndex + 1
        widthIndex + 1
      Next
      
      CloseGadgetList()
      
      *list\rowGadgets(rowIndex) = rowGadget
      SetGadgetData(rowGadget, rowIndex)
      
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerWidth, innerWidth)
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, totalRowHeight)
      NormalResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, innerWidth, totalRowHeight)
      
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
        
        ; Calculate available width without scrollbar
        Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
        Protected innerWidth.i = *list\Width - scrollbarWidth
        
        Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos, innerWidth, *list\Rows()\Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
        
        ; Calculate available width (subtract scrollbar width)
        Protected availableWidth.i = *list\Width - scrollbarWidth
        
        ; Calculate element widths using flex
        Dim elemWidths.i(ListSize(*list\Rows()\Elements()) - 1)
        CalculateElementWidths(*list\Rows()\Elements(), availableWidth, elemWidths())
        
        Protected xElem.i = 0
        elementIndex = 0
        Protected widthIndex.i = 0
        ForEach *list\Rows()\Elements()
          Protected elemW.i = elemWidths(widthIndex)
          Protected *interface.GadgetInterface = *list\Rows()\Elements()\Interface
          *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0,*list\MarginElementTop, elemW, *list\Rows()\Height, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex, *interface)
          xElem + elemW
          elementIndex + 1
          widthIndex + 1
        Next
        
        CloseGadgetList()
        
        *list\rowGadgets(rowIndex) = rowGadget
        SetGadgetData(rowGadget, rowIndex)
        
        SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerWidth, innerWidth)
        SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, totalRowHeight)
        ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, innerWidth, totalRowHeight)
        
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
      
      ; Calculate available width without scrollbar
      Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
      Protected innerWidth.i = *list\Width - scrollbarWidth
      
      *list\InnerContainer = ContainerGadget(#PB_Any, 0, 0, innerWidth, *list\RowHeight, #PB_Container_BorderLess)
      If IsDarkModeActiveCached
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      Else
        SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      EndIf
      CloseGadgetList()
      
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerWidth, innerWidth)
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, *list\RowHeight)
      ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, innerWidth, *list\RowHeight)
      
      RedrawAll(*list)
    EndProcedure
    
    
    Procedure DoResize(*list.ModernListData, externalResize=#False)
      Protected newWidth.i = *list\Width
      Protected newHeight.i = *list\Height
      
      If *list\ResizeCallback
        CallFunctionFast(*list\ResizeCallback, *list, newWidth, newHeight)
      EndIf
      
      NormalResizeGadget(*list\MainContainer, #PB_Ignore, #PB_Ignore, newWidth, newHeight)
      If *list\HeaderContainer
        NormalResizeGadget(*list\HeaderContainer, #PB_Ignore, #PB_Ignore, newWidth, *list\HeaderHeight)
      EndIf
      NormalResizeGadget(*list\ScrollArea, #PB_Ignore, *list\HeaderHeight, newWidth, newHeight - *list\HeaderHeight)
      
      Protected innerH.i = 0
      ForEach *list\Rows()
        Protected rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        innerH + rowH 
      Next
      
      
      ; Calculate available width without scrollbar
      Protected scrollbarWidth.i = GetScrollbarWidth(*list\DPI_Scale)
      Protected innerWidth.i 
      If *list\AddLeftScrollbarMaring
        innerWidth.i = Round(( *list\Width - scrollbarWidth - *list\MarginSide*2)/*list\DPI_Scale, #PB_Round_Down   )* *list\DPI_Scale
      Else
        innerWidth.i = Round(( *list\Width - scrollbarWidth - *list\MarginSide*2)/*list\DPI_Scale, #PB_Round_Down   )* *list\DPI_Scale
      EndIf 
      If innerWidth < 0
        innerWidth = 0
      EndIf 
      Protected availableWidth.i = innerWidth
      Protected listContentWidth.i = availableWidth
      If *list\AddLeftScrollbarMaring
        listContentWidth = listContentWidth- scrollbarWidth
      EndIf 
      
      
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerWidth, innerWidth - 1)
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerWidth, innerWidth)
      SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, innerH)
      NormalResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, innerWidth, innerH)
      
      ; Recalculate header column widths
      If *list\HeaderContainer
        Dim headerWidths.i(ListSize(*list\Header\Columns()) - 1)
        CalculateElementWidths(*list\Header\Columns(), listContentWidth, headerWidths())
      EndIf
      
      Protected yPos.i = 0
      Protected rowIndex.i = 0
      ForEach *list\Rows()
        rowH.i = *list\Rows()\Height
        If rowH = 0
          rowH = *list\RowHeight
        EndIf
        If rowIndex <= ArraySize(*list\rowGadgets())
          Protected rowGadget.i = *list\rowGadgets(rowIndex)
          If rowGadget And IsGadget(rowGadget)
            NormalResizeGadget(rowGadget, #PB_Ignore, yPos, innerWidth, rowH)
            
            ; Recalculate element widths for this row
            Dim elemWidths.i(ListSize(*list\Rows()\Elements()) - 1)
            CalculateElementWidths(*list\Rows()\Elements(), listContentWidth, elemWidths())
            
            ; Reposition and resize elements within the row
            Protected xPos.i = 0
            Protected elemIndex.i = 0
            ForEach *list\Rows()\Elements()
              Protected elemW.i = elemWidths(elemIndex)
              Protected key$ = Str(rowGadget) + "_" + Str(elemIndex)
              
              ; Update element position and size in ElementMap
              If FindMapElement(ModernListElement::ElementMap(), key$)
                ModernListElement::ElementMap()\X = xPos
                ModernListElement::ElementMap()\Width = elemW
                
                ; Resize container gadget if it's a gadget element
                If ModernListElement::ElementMap()\Type = #Element_Gadget And ModernListElement::ElementMap()\Gadget
                  If IsGadget(ModernListElement::ElementMap()\Gadget)
                    NormalResizeGadget(ModernListElement::ElementMap()\Gadget, xPos, #PB_Ignore, elemW, #PB_Ignore)
                    ; Resize child gadgets within container
                    If ModernListElement::ElementMap()\ChildGadgets
                      ForEach ModernListElement::ElementMap()\ChildGadgets\Gadgets()
                        If  ModernListElement::ElementMap()\AutoResize And  IsGadget(ModernListElement::ElementMap()\ChildGadgets\Gadgets())
                          NormalResizeGadget(ModernListElement::ElementMap()\ChildGadgets\Gadgets(), #PB_Ignore, #PB_Ignore, elemW, #PB_Ignore)
                        EndIf
                      Next
                    EndIf
                  EndIf
                EndIf
              EndIf
              
              xPos + elemW
              elemIndex + 1
            Next
          EndIf
        EndIf
        yPos + rowH 
        rowIndex + 1
      Next
      
      ; Don't refresh here - let ResizeList handle it
      ; If Not externalResize
      ;   Refresh(*list)
      ; EndIf
    EndProcedure
    
    Procedure ResizeList(*list.ModernListData, width.i, height.i)
      *list\IsResizing = #True
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*List\ScrollArea), #WM_SETREDRAW, #False, 0)
        
        ForEach ModernListElement::ElementMap()
          If ElementMap()\ChildGadgets <> 0
            ForEach ElementMap()\ChildGadgets\Gadgets()
              If ElementMap()\ChildGadgets\Gadgets() And IsGadget(ElementMap()\ChildGadgets\Gadgets())
                SendMessage_(GadgetID(ElementMap()\ChildGadgets\Gadgets()), #WM_SETREDRAW, #False, 0)
              EndIf 
            Next 
          EndIf  
        Next 
      CompilerEndIf
      
      *list\Width = width
      *list\Height = height
      DoResize(*list, #False)
      
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        SendMessage_(GadgetID(*List\ScrollArea), #WM_SETREDRAW, #True, 0)
        
        ForEach ModernListElement::ElementMap()
          If ElementMap()\ChildGadgets <> 0
            ForEach ElementMap()\ChildGadgets\Gadgets()
              If ElementMap()\ChildGadgets\Gadgets() And IsGadget(ElementMap()\ChildGadgets\Gadgets())
                SendMessage_(GadgetID(ElementMap()\ChildGadgets\Gadgets()), #WM_SETREDRAW, #True, 0)
              EndIf 
            Next 
          EndIf  
        Next 
        ;SendMessage_(hMain, #WM_SETREDRAW, #True, 0)
        ;InvalidateRect_(GadgetID(*list\ScrollArea) , #Null, #True)
        ; InvalidateRect_(hMain, #Null, #True)
        
        ;UpdateWindow_(hMain)
      CompilerEndIf
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected hWnd = GadgetID(*list\ScrollArea)
        If hWnd
          ; Force immediate non-client repaint (scrollbars)
          ;SetWindowPos_(hWnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED | #SWP_NOACTIVATE)
        EndIf
      CompilerEndIf
      RedrawAll(*list)
      
      *list\IsResizing = #False
      *list\ResizeEndTime = ElapsedMilliseconds() + 300
    EndProcedure
    
    
    ; FIXED: Use DesktopUnscaledX/Y to get actual physical mouse position
    Procedure.i IsMouseOverGadget(gadget.i, window.i, scrollAreaGadget.i, headerHeight.i)
      If Not IsGadget(gadget)
        ProcedureReturn #False
      EndIf
      Debug "XYX"
      Debug window
      
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
      ; Block hover updates during and shortly after resize
      If *list\IsResizing Or ElapsedMilliseconds() < *list\ResizeEndTime
        ProcedureReturn
      EndIf
      Debug "! UpdateHoverState"
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
    
    Procedure HandleListEvent(*list.ModernListData, eventGadget.i, eventType.i)
      ; Block ALL events during and shortly after resize
      ;     Debug "HandleListEvent called - eventGadget: " + Str(eventGadget) + " event: " + Str(eventType) + 
      ;         " ScrollArea: " + Str(*list\ScrollArea) + " InnerContainer: " + Str(*list\InnerContainer)
      ;   
      
      If *list\IsResizing Or ElapsedMilliseconds() < *list\ResizeEndTime
        ProcedureReturn #False
      EndIf
      If eventGadget = *list\ScrollArea
        ProcedureReturn #True
      EndIf
      
      If eventGadget = *list\HeaderContainer
        If eventType = #PB_EventType_LeftClick
        EndIf
        ProcedureReturn #True
      EndIf
      
      Select eventType 
        Case #PB_EventType_MouseWheel
          Protected delta.f = GetGadgetAttribute(eventGadget, #PB_Canvas_WheelDelta)
          Protected currentY.i = GetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y)
          Protected scrollSpeed.i
          
          CompilerSelect #PB_Compiler_OS
            CompilerCase #PB_OS_Windows               
              scrollSpeed = delta*26
            CompilerCase #PB_OS_MacOS
              scrollSpeed = delta * 45
            CompilerCase #PB_OS_Linux
              scrollSpeed = (delta / 120) * 45
          CompilerEndSelect     
          
          innerHeight = GetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight)
          
          If Not ((currentY <= 0 And scrollSpeed > 0) Or( currentY >= innerHeight-GadgetHeight(*list\ScrollArea) And scrollSpeed < 0))
            ForEach ModernListElement::ElementMap()
              If ElementMap()\ChildGadgets <> 0
                ForEach ElementMap()\ChildGadgets\Gadgets()
                  If ElementMap()\ChildGadgets\Gadgets() And IsGadget(ElementMap()\ChildGadgets\Gadgets())
                    SendMessage_(GadgetID(ElementMap()\ChildGadgets\Gadgets()), #WM_SETREDRAW, #False, 0)
                  EndIf 
                Next 
              EndIf 
            Next  
            SendMessage_(GadgetID(*List\ScrollArea), #WM_SETREDRAW, #False, 0)
            SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y, currentY - scrollSpeed)
            SendMessage_(GadgetID(*List\ScrollArea), #WM_SETREDRAW, #True, 0)
            ForEach ModernListElement::ElementMap()
              If ElementMap()\ChildGadgets <> 0
                ForEach ElementMap()\ChildGadgets\Gadgets()
                  If ElementMap()\ChildGadgets\Gadgets() And IsGadget(ElementMap()\ChildGadgets\Gadgets())
                    SendMessage_(GadgetID(ElementMap()\ChildGadgets\Gadgets()), #WM_SETREDRAW, #True, 0)
                  EndIf 
                Next 
              EndIf 
            Next  
            RedrawWindow_(GadgetID(*List\ScrollArea), 0, 0,  #RDW_INVALIDATE | #RDW_UPDATENOW)
            RedrawWindow_(GadgetID(*List\InnerContainer), 0, 0,  #RDW_INVALIDATE | #RDW_UPDATENOW| #RDW_ALLCHILDREN)
            
            ;UpdateWindow_(GadgetID(*list\ScrollArea))
            ;RedrawWindow_(GadgetID(*list\ScrollArea), 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_UPDATENOW | #RDW_ALLCHILDREN)
            UpdateHoverState(*list.ModernListData) ; TODO DEBOUNCE TO AVOID FLICKER

            
          EndIf 
          
        Default ;Other Events
          

          Protected rowIndex.i = -1
          Protected foundRow.i = #False
          Protected foundGadget = #False 
          Protected foundRowGadget = #False
          Protected foundCellGadget= #False
          Protected foundChildGadget = #False
          Protected childIndex = -1 
          mapKey.s = ""
          rowGadget = 0
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
                mapKey = MapKey(ElementMap())
                Break
              ElseIf  ElementMap()\Gadget = eventGadget
                foundGadget = #True 
                foundCellGadget= #True 
                mapKey = MapKey(ElementMap())
                Break
              ElseIf ElementMap()\ChildGadgets <> 0
                ForEach ElementMap()\ChildGadgets\Gadgets()
                  If ElementMap()\ChildGadgets\Gadgets() = eventGadget
                    rowGadget = ElementMap()\RowGadget
                    foundGadget = #True 
                    foundChildGadget = #True
                    mapKey = MapKey(ElementMap())
                    Debug "GGGGGGGGGGG #"+MapKey(ElementMap())+"#"
                    Break 
                  EndIf 
                  childIndex  +1 
                Next 
                If foundGadget
                  childIndex  +1 
                EndIf 
              EndIf
            Next
          EndIf
          
          
          If foundChildGadget And rowGadget <> 0 
            For i = 0 To ArraySize(*list\rowGadgets())
              If *list\rowGadgets(i) = rowGadget
                rowIndex = GetGadgetData(rowGadget)
                foundRow = #True
                foundGadget = #True 
                foundRowGadget = #False
                Break
              EndIf
            Next
          EndIf 


          If foundRow And rowIndex >= 0 And rowIndex < ListSize(*list\Rows())
            handled = ModernListElement::HandleEvent(mapKey,foundRowGadget, foundCellGadget, foundChildGadget,childIndex, eventGadget, event,*list,rowIndex )
            If Not handled
              Select eventType
                Case #PB_EventType_LeftClick,#PB_EventType_LeftDoubleClick,#PB_EventType_RightClick,  #PB_EventType_Change
                  *list\ActiveRowIndex = rowIndex
                  *list\HoveredRowIndex = rowIndex  
                  Debug "!!!!!!!!!!!!!!!!!!!!!!!!!!CLICKED## "+Str(rowIndex)+" XX #"+mapKey+"#"
                  
                  RedrawAll(*list)
              EndSelect
            EndIf 
            ProcedureReturn handled
          EndIf
          ProcedureReturn #False 
      EndSelect 
    EndProcedure
    
    Procedure GetSelectedRow(*list.ModernListData)
      ProcedureReturn *list\ActiveRowIndex
    EndProcedure
    
    Procedure GetInnerContainer(*list.ModernListData)
      ProcedureReturn *list\InnerContainer
    EndProcedure
    
    Procedure CleanUp()
      ForEach brushes()
        DeleteObject_(brushes())
      Next 
    EndProcedure
    
  EndModule

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 128
; FirstLine = 110
; Folding = -------
; EnableXP
; DPIAware
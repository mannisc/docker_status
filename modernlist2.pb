DeclareModule App
  Global IsDarkModeActiveCached = #False
  Global darkThemeBackgroundColor = RGB(30,30,30)
  Global darkThemeForegroundColor = RGB(255, 255, 255)
  Global lightThemeBackgroundColor = RGB(250,250,250)
  Global lightThemeForegroundColor = RGB(0,0,0)
EndDeclareModule

Module App
EndModule

DeclareModule ModernListElement
  Enumeration ElementTypes
    #Element_Text
    #Element_Image
    #Element_Gadget
  EndEnumeration
  
  Declare CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i)
  Declare Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
  Declare HandleEvent(eventGadget.i, event.i)
EndDeclareModule

Module ModernListElement
  Structure ModernListElementData
    RowGadget.i
    Gadget.i
    Type.i
    Content.s
    X.i
    Y.i
    Width.i
    Height.i
  EndStructure
  
  Global NewMap ElementMap.ModernListElementData()
  
  Procedure CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i)
    Protected g.i = 0
    If type = #Element_Gadget
      Protected proc = GetFunction(0, content)
      If proc
        g = CallFunctionFast(proc, rowGadget, x, y, width, height)
      EndIf
    EndIf
    
    AddMapElement(ElementMap(), Str(rowGadget) + "_" + Str(x) + "_" + Str(type) + "_" + Str(elementIndex))
    ElementMap()\RowGadget = rowGadget
    ElementMap()\Gadget = g
    ElementMap()\Type = type
    ElementMap()\Content = content
    ElementMap()\X = x
    ElementMap()\Y = y
    ElementMap()\Width = width
    ElementMap()\Height = height
    
    ProcedureReturn g
  EndProcedure
  
  Procedure Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
    If FindMapElement(ElementMap(), Str(rowGadget) + "_" + Str(x) + "_" + Str(type) + "_" + Str(elementIndex))
      If ElementMap()\Type = #Element_Gadget And ElementMap()\Gadget
        FreeGadget(ElementMap()\Gadget)
      EndIf
      DeleteMapElement(ElementMap())
    EndIf
  EndProcedure
  
  Procedure HandleEvent(eventGadget.i, event.i)
    Protected handled = #False
    If eventGadget
      ForEach ElementMap()
        If ElementMap()\RowGadget = eventGadget Or ElementMap()\Gadget = eventGadget
          Select event
            Case #PB_EventType_LeftClick
              If ElementMap()\Type = #Element_Gadget And ElementMap()\Gadget = eventGadget
                Debug "Clicked gadget: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
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
              
            Case #PB_EventType_Focus
              If ElementMap()\Type = #Element_Gadget And ElementMap()\Gadget = eventGadget
                Debug "Gadget focused: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              ElseIf ElementMap()\RowGadget = eventGadget
                Debug "Row canvas focused for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                handled = #True
              EndIf
              
            Case #PB_EventType_LostFocus
              If ElementMap()\Type = #Element_Gadget And ElementMap()\Gadget = eventGadget
                Debug "Gadget lost focus: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                handled = #True
              ElseIf ElementMap()\RowGadget = eventGadget
                Debug "Row canvas lost focus for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                handled = #True
              EndIf
          EndSelect
        EndIf
        If handled
          Break
        EndIf
      Next
    EndIf
    ProcedureReturn handled
  EndProcedure
EndModule

DeclareModule ModernList
  UseModule App
  UseModule ModernListElement
  
  Structure ListElement
    Type.i      ; One of ElementTypes
    Content.s   ; Text string, image ID, or procedure name (for gadgets)
    Width.i     ; Fixed width in pixels (DPI-scaled)
    Alignment.i ; 0: left, 1: center, 2: right
    ForeColor.i ; Optional custom foreground color
    BackColor.i ; Optional custom background color
    Gadget.i    ; Stored gadget ID for cleanup
  EndStructure
  
  Structure ListRow
    List Elements.ListElement()  ; List of elements
    Height.i                    ; Custom row height (0 = default)
    UserData.i                  ; For sorting/filtering
  EndStructure
  
  Structure ListHeader
    List Columns.ListElement()  ; Header columns
    Height.i                   ; Header height
  EndStructure
  
  #PB_Event_RedrawRow = #PB_Event_FirstCustomValue + 1
  
  Structure ModernListData
    Window.i
    MainContainer.i
    HeaderContainer.i
    ScrollArea.i
    InnerContainer.i
    HeaderHeight.i
    RowHeight.i          ; Default row height
    List Rows.ListRow()
    Header.ListHeader
    ActiveRowIndex.i     ; Selected row
    HoveredRowIndex.i    ; Hovered row
    Width.i
    Height.i
    InnerWidth.i
    InnerHeight.i
    *ResizeCallback
    AnimationRunning.i   ; For future animations
    DPI_Scale.f
    Array rowGadgets.i(0) ; Store row gadgets
  EndStructure
  
  Global rowFont
  Global headerFont
  
  Declare SetColors()
  Declare Refresh(*list.ModernListData)
  Declare DrawHeader(*list.ModernListData)
  Declare DrawRow(*list.ModernListData, rowIndex.i, gadget.i, active.i, hovered.i)
  Declare RedrawAll(*list.ModernListData)
  Declare CreateList(window.i, x.i, y.i, width.i, height.i, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=40, User_DPI_Scale.f=1, *resizeProc=0)
  Declare AddRow(*list.ModernListData, List elements.ListElement(), height.i=0, userData.i=0)
  Declare SetRow(*list.ModernListData, rowIndex.i, List elements.ListElement(), height.i=0, userData.i=0)
  Declare ClearRows(*list.ModernListData)
  Declare DoResize(*list.ModernListData, externalResize=#False)
  Declare Resize(*list.ModernListData, width.i, height.i, externalResize=#False)
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
  Global DPI_Scale.f = 1
  Global menuFontSize.f = 7
  Global menuFont
  Global colorAccent
  Global colorHover
  Global colorSideBar
  Global inactiveForegroundColor
  Global rowFont
  Global headerFont
  
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
    Protected hMain = GadgetID(*list\MainContainer)
    Protected hInner = GadgetID(*list\InnerContainer)
    RedrawWindow_(hMain, 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_UPDATENOW)
    RedrawWindow_(hInner, 0, 0, #RDW_ERASE | #RDW_INVALIDATE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
    InvalidateRect_(hMain, #Null, #False)
    UpdateWindow_(hMain)
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
              If foreColor = 0 : foreColor = inactiveForegroundColor : EndIf
              yPos = (OutputHeight() - TextHeight(text$)) / 2
              DrawText(xPos + 5 * DPI_Scale, yPos, text$, foreColor)
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
        Protected xPos.i, elemWidth.i, backColor.i, foreColor.i, text$, textW.i, textH.i, yPos.i, xAlign.i, imgID.i, imgW.i, imgH.i, yAlign.i
        
        SetColors()
        If active
          Box(0, 0, canvasW, canvasH, colorAccent)
        ElseIf hovered
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
          If backColor
            Box(xPos, 0, elemWidth, canvasH, backColor)
          EndIf
          
          Select *list\Rows()\Elements()\Type
            Case #Element_Text
              text$ = *list\Rows()\Elements()\Content
              foreColor = *list\Rows()\Elements()\ForeColor
              If foreColor = 0
                If IsDarkModeActiveCached
                  foreColor = darkThemeForegroundColor
                Else
                  foreColor = lightThemeForegroundColor
                EndIf
              EndIf
              If hovered
                foreColor = colorAccent
              EndIf
              textW = TextWidth(text$)
              textH = TextHeight(text$)
              yPos = (canvasH - textH) / 2
              Select *list\Rows()\Elements()\Alignment
                Case 1 : xAlign = (elemWidth - textW) / 2
                Case 2 : xAlign = elemWidth - textW - 5 * DPI_Scale
                Default: xAlign = 5 * DPI_Scale
              EndSelect
              DrawText(xPos + xAlign, yPos, text$, foreColor)
              
            Case #Element_Image
              If Val(*list\Rows()\Elements()\Content) > 0
                imgID = Val(*list\Rows()\Elements()\Content)
                imgW = ImageWidth(imgID)
                imgH = ImageHeight(imgID)
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                Select *list\Rows()\Elements()\Alignment
                  Case 1 : xAlign = (elemWidth - imgW) / 2
                  Case 2 : xAlign = elemWidth - imgW - 5 * DPI_Scale
                  Default: xAlign = 5 * DPI_Scale
                EndSelect
                yAlign = (canvasH - imgH) / 2
                DrawImage(ImageID(imgID), xPos + xAlign, yAlign)
                If hovered
                  DrawingMode(#PB_2DDrawing_AlphaBlend)
                  Box(xPos, 0, elemWidth, canvasH, RGBA(0, 122, 204, 50))
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
      If rowH = 0 : rowH = *list\RowHeight : EndIf
      If rowIndex < ArraySize(*list\rowGadgets())
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
  
  Procedure CreateList(window.i, x.i, y.i, width.i, height.i, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=40, User_DPI_Scale.f=1, *resizeProc=0)
    Protected *list.ModernListData = AllocateMemory(SizeOf(ModernListData))
    Protected rowCount.i, yPos.i, rowIndex.i, elemW.i, xElem.i, rowGadget.i
    
    SetColors()
    DPI_Scale = User_DPI_Scale
    
    Protected fontName$
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        fontName$ = "Segoe UI"
      CompilerCase #PB_OS_Linux
        fontName$ = "Sans"
      CompilerCase #PB_OS_MacOS
        fontName$ = "Helvetica"
    CompilerEndSelect
    rowFont = LoadFont(#PB_Any, fontName$, 10 * DPI_Scale, #PB_Font_HighQuality)
    headerFont = LoadFont(#PB_Any, fontName$, 10 * DPI_Scale, #PB_Font_Bold | #PB_Font_HighQuality)
    
    *list\Window = window
    *list\Width = Round(width * DPI_Scale, #PB_Round_Down)
    *list\Height = Round(height * DPI_Scale, #PB_Round_Down)
    *list\RowHeight = Round(defaultRowHeight * DPI_Scale, #PB_Round_Down)
    *list\ActiveRowIndex = -1
    *list\HoveredRowIndex = -1
    *list\DPI_Scale = DPI_Scale
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
    *list\ScrollArea = ScrollAreaGadget(#PB_Any, 0, scrollY, *list\Width, scrollH, *list\Width, rowCount * *list\RowHeight, 0, #PB_ScrollArea_BorderLess)
    *list\InnerContainer = ContainerGadget(#PB_Any, 0, 0, *list\Width, rowCount * *list\RowHeight, #PB_Container_BorderLess)
    If IsDarkModeActiveCached
      SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, darkThemeBackgroundColor)
    Else
      SetGadgetColor(*list\InnerContainer, #PB_Gadget_BackColor, lightThemeBackgroundColor)
    EndIf
    
    yPos = 0
    rowIndex = 0
    Dim *list\rowGadgets(rowCount - 1)
    ForEach *list\Rows()
      Protected rowH.i = *list\Rows()\Height
      If rowH = 0 : rowH = *list\RowHeight : EndIf
      
      rowGadget = CanvasGadget(#PB_Any, 0, yPos, *list\Width, rowH, #PB_Canvas_Container | #PB_Canvas_Keyboard)
      
      xElem = 0
      Protected elementIndex.i = 0
      ForEach *list\Rows()\Elements()
        elemW = *list\Rows()\Elements()\Width
        *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, rowH, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex)
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
    
    Protected hMain.i = GadgetID(*list\MainContainer)
    SetWindowLongPtr_(hMain, #GWL_STYLE, GetWindowLongPtr_(hMain, #GWL_STYLE) | #WS_CLIPCHILDREN)
    
    Protected hScroll.i = GadgetID(*list\ScrollArea)
    SetWindowLongPtr_(hScroll, #GWL_STYLE, GetWindowLongPtr_(hScroll, #GWL_STYLE) | #WS_CLIPCHILDREN)
    
    Protected hInner.i = GadgetID(*list\InnerContainer)
    SetWindowLongPtr_(hInner, #GWL_STYLE, GetWindowLongPtr_(hInner, #GWL_STYLE) | #WS_CLIPCHILDREN)
    
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
    ForEach *list\Rows()
      Protected rowH.i = *list\Rows()\Height
      If rowH = 0 : rowH = *list\RowHeight : EndIf
      yPos + rowH
    Next
    
    Protected rowIndex.i = ListSize(*list\Rows()) - 1
    ReDim *list\rowGadgets(ArraySize(*list\rowGadgets()) + 1)
    
    Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos - *list\RowHeight, *list\Width, *list\RowHeight, #PB_Canvas_Container | #PB_Canvas_Keyboard)
    
    Protected xElem.i = 0
    Protected elementIndex.i = 0
    ForEach *list\Rows()\Elements()
      Protected elemW.i = *list\Rows()\Elements()\Width
      *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, *list\RowHeight, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex)
      xElem + elemW
      elementIndex + 1
    Next
    
    CloseGadgetList()
    
    *list\rowGadgets(rowIndex) = rowGadget
    SetGadgetData(rowGadget, rowIndex)
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
      ForEach *list\Rows()
        Protected rowH.i = *list\Rows()\Height
        If rowH = 0 : rowH = *list\RowHeight : EndIf
        If ListIndex(*list\Rows()) = rowIndex
          Break
        EndIf
        yPos + rowH
      Next
      
      If rowIndex < ArraySize(*list\rowGadgets())
        If *list\rowGadgets(rowIndex) And IsGadget(*list\rowGadgets(rowIndex))
          FreeGadget(*list\rowGadgets(rowIndex))
        EndIf
      EndIf
      
      Protected rowGadget.i = CanvasGadget(#PB_Any, 0, yPos, *list\Width, *list\RowHeight, #PB_Canvas_Container | #PB_Canvas_Keyboard)
      
      Protected xElem.i = 0
      elementIndex = 0
      ForEach *list\Rows()\Elements()
        Protected elemW.i = *list\Rows()\Elements()\Width
        *list\Rows()\Elements()\Gadget = ModernListElement::CreateElement(rowGadget, xElem, 0, elemW, *list\RowHeight, *list\Rows()\Elements()\Type, *list\Rows()\Elements()\Content, elementIndex)
        xElem + elemW
        elementIndex + 1
      Next
      
      CloseGadgetList()
      
      *list\rowGadgets(rowIndex) = rowGadget
      SetGadgetData(rowGadget, rowIndex)
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
      Protected rowH.i = *list\Rows()\Height
      If rowH = 0 : rowH = *list\RowHeight : EndIf
      innerH + rowH
    Next
    SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_InnerHeight, innerH)
    ResizeGadget(*list\InnerContainer, #PB_Ignore, #PB_Ignore, newWidth, innerH)
    
    Protected yPos.i = 0
    Protected rowIndex.i = 0
    ForEach *list\Rows()
      rowH.i = *list\Rows()\Height
      If rowH = 0 : rowH = *list\RowHeight : EndIf
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
    *list\Width = Round(width * DPI_Scale, #PB_Round_Down)
    *list\Height = Round(height * DPI_Scale, #PB_Round_Down)
    DoResize(*list, externalResize)
  EndProcedure
  
  Procedure HandleListEvent(*list.ModernListData, eventGadget.i, event.i)
    If eventGadget = *list\HeaderContainer
      If event = #PB_EventType_LeftClick
        ; TODO: Sorting
      EndIf
      ProcedureReturn #True
    EndIf
    
    Protected rowIndex.i = GetGadgetData(eventGadget)
    If rowIndex >= 0 And rowIndex < ListSize(*list\Rows())
      If event = #PB_EventType_LeftClick
        *list\ActiveRowIndex = rowIndex
        RedrawAll(*list)
      ElseIf event = #PB_EventType_MouseEnter
        *list\HoveredRowIndex = rowIndex
        If rowIndex < ArraySize(*list\rowGadgets())
          Protected rowGadget.i = *list\rowGadgets(rowIndex)
          If rowGadget And IsGadget(rowGadget)
            Protected isActive.i = #False
            If rowIndex = *list\ActiveRowIndex
              isActive = #True
            EndIf
            DrawRow(*list, rowIndex, rowGadget, isActive, #True)
          EndIf
        EndIf
      ElseIf event = #PB_EventType_MouseLeave
        *list\HoveredRowIndex = -1
        If rowIndex < ArraySize(*list\rowGadgets())
           rowGadget.i = *list\rowGadgets(rowIndex)
          If rowGadget And IsGadget(rowGadget)
             isActive.i = #False
            If rowIndex = *list\ActiveRowIndex
              isActive = #True
            EndIf
            DrawRow(*list, rowIndex, rowGadget, isActive, #False)
          EndIf
        EndIf
      EndIf
      ProcedureReturn ModernListElement::HandleEvent(eventGadget, event)
    EndIf
    
    ProcedureReturn ModernListElement::HandleEvent(eventGadget, event)
  EndProcedure
  
  Procedure GetSelectedRow(*list.ModernListData)
    ProcedureReturn *list\ActiveRowIndex
  EndProcedure
  
  Procedure GetInnerContainer(*list.ModernListData)
    ProcedureReturn *list\InnerContainer
  EndProcedure
EndModule

; Sample usage of ModernList module with mock image
EnableExplicit

UseModule App
UseModule ModernList

Procedure CreateButtonGadget(parentGadget.i, x.i, y.i, width.i, height.i)
  Protected g.i = ButtonGadget(#PB_Any, x, y, width, height, "Click Me")
  ProcedureReturn g
EndProcedure

Procedure CreateMockImage()
  Protected img.i = CreateImage(#PB_Any, 32, 32, 32)
  If StartDrawing(ImageOutput(img))
    Box(0, 0, 32, 32, RGB(255, 0, 0)) ; Red background
    LineXY(0, 0, 32, 32, RGB(255, 255, 255)) ; White diagonal line
    LineXY(0, 32, 32, 0, RGB(255, 255, 255)) ; White diagonal line (cross)
    StopDrawing()
  EndIf
  ProcedureReturn img
EndProcedure

Procedure ListResizeCallback(*list.ModernListData, width.i, height.i)
  Debug "List resized to " + Str(width) + "x" + Str(height)
EndProcedure

Procedure Main()
  If OpenWindow(0, 0, 0, 600, 400, "ModernList Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    
    Protected mockImage.i = CreateMockImage()
    
    Define header.ModernList::ListHeader
    header\Height = 30
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "ID"
    header\Columns()\Width = 100
    header\Columns()\Alignment = 1 ; Center
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "Name"
    header\Columns()\Width = 200
    AddElement(header\Columns())
    header\Columns()\Type = ModernListElement::#Element_Text
    header\Columns()\Content = "Action"
    header\Columns()\Width = 150
    
    NewList rows.ListRow()
    
    AddElement(rows())
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "001"
    rows()\Elements()\Width = 100
    rows()\Elements()\Alignment = 1
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Image
    rows()\Elements()\Content = Str(mockImage)
    rows()\Elements()\Width = 200
    rows()\Elements()\Alignment = 1
    rows()\Height = 50
    
    AddElement(rows())
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "002"
    rows()\Elements()\Width = 100
    rows()\Elements()\Alignment = 1
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "Jane Doe"
    rows()\Elements()\Width = 200
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Gadget
    rows()\Elements()\Content = "CreateButtonGadget"
    rows()\Elements()\Width = 150
    rows()\Height = 50
    
    AddElement(rows())
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Image
    rows()\Elements()\Content = Str(mockImage)
    rows()\Elements()\Width = 100
    rows()\Elements()\Alignment = 1
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Text
    rows()\Elements()\Content = "Item 3"
    rows()\Elements()\Width = 350
    rows()\Height = 50
    
    Protected *list.ModernListData = ModernList::CreateList(0, 10, 10, 450, 300, rows(), @header, 40, 1.0, @ListResizeCallback())
    
    Repeat
      Protected event.i = WaitWindowEvent()
      Select event
        Case #PB_Event_Gadget
          If ModernList::HandleListEvent(*list, EventGadget(), EventType())
            ; Handled by ModernList and ModernListElement
          EndIf
          
        Case #PB_Event_CloseWindow
          Break
      EndSelect
    ForEver
    
    FreeImage(mockImage)
    FreeMemory(*list)
    FreeFont(ModernList::rowFont)
    FreeFont(ModernList::headerFont)
  EndIf
EndProcedure

Main()
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 778
; FirstLine = 774
; Folding = -----
; EnableXP
; DPIAware
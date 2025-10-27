﻿; DPI Detection at the very top - exactly as requested
ExamineDesktops()
Global DPI_Scale.f = DesktopResolutionX()

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
  Prototype.i ProtoCreateGadget(parentGadget.i, x.i, y.i, width.i, height.i)
  Prototype.i ProtoHandleGadgetEvent(eventGadget.i, event.i)
  Prototype ProtoDestroyGadget(gadget.i)
  Structure GadgetInterface
    *Create.ProtoCreateGadget
    *HandleEvent.ProtoHandleGadgetEvent
    *Destroy.ProtoDestroyGadget
  EndStructure
  Declare CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface.GadgetInterface=0)
  Declare Remove(gadget.i, rowGadget.i, type.i, elementIndex.i)
  Declare HandleEvent(eventGadget.i, event.i)
  
  Structure ModernListElementData
    RowGadget.i
    Gadget.i
    ChildGadget.i  ; The actual gadget inside the container (button, combo, etc.)
    Type.i
    Content.s
    X.i
    Y.i
    Width.i
    Height.i
    *EventProc.ProtoHandleGadgetEvent
    *DestroyProc.ProtoDestroyGadget
  EndStructure
  
  Global NewMap ElementMap.ModernListElementData()
EndDeclareModule

Module ModernListElement
  Procedure CreateElement(rowGadget.i, x.i, y.i, width.i, height.i, type.i, content.s, elementIndex.i, *interface.GadgetInterface=0)
    Protected g.i = 0
    Protected containerGadget.i = 0
    Protected gadgetToStore.i = 0
    Protected childGadget.i = 0
    
    If type = #Element_Gadget And *interface
      containerGadget = ContainerGadget(#PB_Any, x, y, width, height)
      g = *interface\Create(containerGadget, 0, 0, width, height)
      childGadget = g  ; Store the actual child gadget
      CloseGadgetList()
      gadgetToStore = containerGadget
    Else
      gadgetToStore = g
    EndIf
    
    Protected key$ = Str(rowGadget) + "_" + Str(elementIndex)
    AddMapElement(ElementMap(), key$)
    ElementMap()\RowGadget = rowGadget
    ElementMap()\Gadget = gadgetToStore
    ElementMap()\ChildGadget = childGadget  ; Store the child gadget reference
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
  
  Procedure HandleEvent(eventGadget.i, event.i)
    Protected handled = #False
    If eventGadget
      ForEach ElementMap()
        ; Check if event is from the row canvas, container, or child gadget
        If ElementMap()\RowGadget = eventGadget Or ElementMap()\Gadget = eventGadget Or ElementMap()\ChildGadget = eventGadget
          If ElementMap()\Type = #Element_Gadget And ElementMap()\EventProc
            Protected actualGadget.i = 0
            ; The event came from the child gadget (button, combo, etc.)
            If ElementMap()\ChildGadget = eventGadget
              actualGadget = eventGadget
              handled = ElementMap()\EventProc(actualGadget, event)
            ; The event came from the container
            ElseIf IsGadget(ElementMap()\Gadget)
              actualGadget = GetGadgetData(ElementMap()\Gadget)
              If actualGadget = 0
                actualGadget = eventGadget
              EndIf
              handled = ElementMap()\EventProc(actualGadget, event)
            EndIf
          EndIf
          If Not handled
            Select event
              Case #PB_EventType_LeftClick
                If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or ElementMap()\ChildGadget = eventGadget)
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
                If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or ElementMap()\ChildGadget = eventGadget)
                  Debug "Gadget focused: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                  handled = #True
                ElseIf ElementMap()\RowGadget = eventGadget
                  Debug "Row canvas focused for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                  handled = #True
                EndIf
                
              Case #PB_EventType_LostFocus
                If ElementMap()\Type = #Element_Gadget And (ElementMap()\Gadget = eventGadget Or ElementMap()\ChildGadget = eventGadget)
                  Debug "Gadget lost focus: " + ElementMap()\Content + " (Gadget ID: " + Str(eventGadget) + ")"
                  handled = #True
                ElseIf ElementMap()\RowGadget = eventGadget
                  Debug "Row canvas lost focus for " + Str(ElementMap()\Type) + ": " + ElementMap()\Content
                  handled = #True
                EndIf
            EndSelect
          EndIf
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
  Declare CreateList(window.i, x.i, y.i, width.i, height.i, List rows.ListRow(), *header.ListHeader=0, defaultRowHeight.i=40, User_DPI_Scale.f=1, *resizeProc=0)
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
    rowFont = LoadFont(#PB_Any, fontName$, 10 * Local_DPI_Scale, #PB_Font_HighQuality)
    headerFont = LoadFont(#PB_Any, fontName$, 10 * Local_DPI_Scale, #PB_Font_Bold | #PB_Font_HighQuality)
    
    *list\Window = window
    *list\Width = Round(width * Local_DPI_Scale, #PB_Round_Down)
    *list\Height = Round(height * Local_DPI_Scale, #PB_Round_Down)
    *list\RowHeight = Round(defaultRowHeight * Local_DPI_Scale, #PB_Round_Down)
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
    Protected mx.i = DesktopUnscaledX(WindowMouseX(window))
    Protected my.i = DesktopUnscaledY(WindowMouseY(window))
    
    ; Get gadget's PHYSICAL position in window coordinates (unscaled)
    Protected gx.i = DesktopUnscaledX(GadgetX(gadget, #PB_Gadget_WindowCoordinate))
    Protected gy.i = DesktopUnscaledY(GadgetY(gadget, #PB_Gadget_WindowCoordinate))
    Protected gw.i = DesktopUnscaledX(GadgetWidth(gadget))
    Protected gh.i = DesktopUnscaledY(GadgetHeight(gadget))
    
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
          mouseOverRow = i
          foundHover = #True
          Break
        EndIf
      EndIf
    Next
    
    ; If not over a row, check if over an element gadget
    If Not foundHover
      ForEach ModernListElement::ElementMap()
        If ModernListElement::ElementMap()\Type = #Element_Gadget
          If IsMouseOverGadget(ModernListElement::ElementMap()\Gadget, *list\Window, *list\ScrollArea, *list\HeaderHeight)
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
  
  Procedure HandleListEvent(*list.ModernListData, eventGadget.i, event.i)
    If eventGadget = *list\HeaderContainer
      If event = #PB_EventType_LeftClick
      EndIf
      ProcedureReturn #True
    EndIf
    
    Protected rowIndex.i = -1
    Protected foundRow.i = #False
    
    For i = 0 To ArraySize(*list\rowGadgets())
      If *list\rowGadgets(i) = eventGadget
        rowIndex = GetGadgetData(eventGadget)
        foundRow = #True
        Break
      EndIf
    Next
    
    If Not foundRow
      ForEach ModernListElement::ElementMap()
        If ModernListElement::ElementMap()\Gadget = eventGadget
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
    
    If rowIndex >= 0 And rowIndex < ListSize(*list\Rows())
      Select event
        Case #PB_EventType_LeftClick
          *list\ActiveRowIndex = rowIndex
          RedrawAll(*list)
          
        Case #PB_EventType_MouseWheel
          Protected delta.i = GetGadgetAttribute(eventGadget, #PB_Canvas_WheelDelta)
          Protected currentY.i = GetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y)
          Protected listStep.i = *list\RowHeight
          SetGadgetAttribute(*list\ScrollArea, #PB_ScrollArea_Y, currentY - delta * listStep)
      EndSelect
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

UseModule App
UseModule ModernListElement
UseModule ModernList

Procedure DestroyGadget(gadget.i)
  If IsGadget(gadget)
    FreeGadget(gadget)
  EndIf
EndProcedure

Procedure HandleButtonEvent(eventGadget.i, event.i)
  Protected handled = #False
  If event = #PB_EventType_LeftClick
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
  ProcedureReturn g
EndProcedure

Global ButtonInterface.GadgetInterface
ButtonInterface\Create = @CreateButtonGadget()
ButtonInterface\HandleEvent = @HandleButtonEvent()
ButtonInterface\Destroy = @DestroyGadget()

Procedure HandleComboEvent(eventGadget.i, event.i)
  Protected handled = #False
  If event = #PB_EventType_Change
    Protected selectedText$ = GetGadgetText(eventGadget)
    Debug "ComboBox changed: Gadget ID " + Str(eventGadget) + ", Selected: " + selectedText$
    MessageRequester("ComboBox Selection", "Selected option: " + selectedText$)
    handled = #True
  EndIf
  ProcedureReturn handled
EndProcedure

Procedure CreateComboBoxGadget(parentGadget.i, x.i, y.i, width.i, height.i)
  Protected g.i = ComboBoxGadget(#PB_Any, x, y, width, height)
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
  ProcedureReturn g
EndProcedure

Global ComboInterface.GadgetInterface
ComboInterface\Create = @CreateComboBoxGadget()
ComboInterface\HandleEvent = @HandleComboEvent()
ComboInterface\Destroy = @DestroyGadget()

Procedure HandleStringEvent(eventGadget.i, event.i)
  Protected handled = #False
  If event = #PB_EventType_Change
    Debug "StringGadget changed: Gadget ID " + Str(eventGadget) + ", Text: " + GetGadgetText(eventGadget)
    MessageRequester("StringGadget Action", "Text changed to: " + GetGadgetText(eventGadget))
    handled = #True
  EndIf
  ProcedureReturn handled
EndProcedure

Procedure CreateStringGadget(parentGadget.i, x.i, y.i, width.i, height.i)
  Protected g.i = StringGadget(#PB_Any, x, y, width, height, "Edit me")
  If IsGadget(g)
    If IsDarkModeActiveCached
      SetGadgetColor(g, #PB_Gadget_BackColor, darkThemeBackgroundColor)
      SetGadgetColor(g, #PB_Gadget_FrontColor, darkThemeForegroundColor)
    Else
      SetGadgetColor(g, #PB_Gadget_BackColor, lightThemeBackgroundColor)
      SetGadgetColor(g, #PB_Gadget_FrontColor, lightThemeForegroundColor)
    EndIf
  EndIf
  ProcedureReturn g
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

Procedure Main()
  Debug "Detected DPI Scale: " + StrF(DPI_Scale, 2)
  
  If OpenWindow(0, 0, 0, 600, 400, "ModernList Example - DPI: " + StrF(DPI_Scale * 100, 0) + "%", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    Protected mockImage.i = CreateMockImage()
    
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
    
    NewList rows.ListRow()
    
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
    rows()\Height = 50
    
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
    rows()\Elements()\Width = 200
    rows()\Elements()\SelectedForeColor = RGB(255, 255, 255)
    rows()\Elements()\SelectedHoveredForeColor = RGB(255, 255, 255)
    
    AddElement(rows()\Elements())
    rows()\Elements()\Type = ModernListElement::#Element_Gadget
    rows()\Elements()\Content = "Combo Data"
    rows()\Elements()\Interface = @ComboInterface
    rows()\Elements()\Width = 150
    rows()\Height = 50
    
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
    rows()\Height = 50
    
    For i = 5 To 15
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
      rows()\Height = 50
    Next
    
    Protected *list.ModernListData = ModernList::CreateList(0, 0, 0, 600, 400, rows(), @header, 40, DPI_Scale, @ListResizeCallback())
    
    Protected lastMouseX.i = -1
    Protected lastMouseY.i = -1
    
    Repeat
      Protected event.i = WaitWindowEvent(10)
      
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
            Debug "Unhandled gadget event: Gadget=" + Str(EventGadget()) + ", Type=" + Str(EventType())
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
; Folding = ------
; EnableXP
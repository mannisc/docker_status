
; Theme etc-----------------------------------------------------------------------

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  
  
  #PFM_LINESPACING = $00000100
  #EM_SETPARAFORMAT = $447
  #EM_GETPARAFORMAT = $43D
  
  #EDITOR_LINE_HEIGHT = 23
  
  Procedure SetFixedLineHeight(hEditor, heightPixels)
    Protected pf.PARAFORMAT2
    pf\cbSize = SizeOf(PARAFORMAT2)
    pf\dwMask = #PFM_LINESPACING
    pf\bLineSpacingRule = 4 ; exact line spacing
    pf\dyLineSpacing = heightPixels * 15  ; 1 pixel ≈ 15 twips
    Debug SendMessage_(hEditor, #EM_SETPARAFORMAT, 0, @pf)
  EndProcedure
  
  
  Global themeBgBrush 
  
  ; -------------------- Constants --------------------
  #DWMWA_USE_IMMERSIVE_DARK_MODE = 20
  #GWL_WNDPROC = -4
  #WM_PAINT = 15
  #LVM_GETHEADER = $1000 + 31
  
  ; -------------------- Global Variables --------------------
  Global oldHeaderProc.l
  
  ; -------------------- Dynamic API Helpers --------------------
  Procedure DwmSetWindowAttributeDynamic(hwnd.i, dwAttribute.i, *pvAttribute, cbAttribute.i)
    Protected result = 0
    Protected hDll = OpenLibrary(#PB_Any, "dwmapi.dll")
    If hDll
      Protected *fn = GetFunction(hDll, "DwmSetWindowAttribute")
      If *fn
        result = CallFunctionFast(*fn, hwnd, dwAttribute, *pvAttribute, cbAttribute)
      EndIf
      CloseLibrary(hDll)
    EndIf
    ProcedureReturn result
  EndProcedure
  
  Procedure SetDarkTitleBar(hwnd.i, enable)
    Protected attrValue.i = Bool(enable)
    DwmSetWindowAttributeDynamic(hwnd, #DWMWA_USE_IMMERSIVE_DARK_MODE, @attrValue, SizeOf(Integer))
  EndProcedure
  
  Procedure SetWindowThemeDynamic(hwnd.i, subAppName.s)
    Protected hUxTheme = OpenLibrary(#PB_Any, "uxtheme.dll")
    If hUxTheme
      Protected *fn = GetFunction(hUxTheme, "SetWindowTheme")
      If *fn
        CallFunctionFast(*fn, hwnd, @subAppName, 0)
      EndIf
      CloseLibrary(hUxTheme)
    EndIf
  EndProcedure
  
  
  
  ; -------------------- Dark Mode Helpers --------------------
  Global IsDarkModeActiveCached = #False
  Procedure IsDarkModeActive()
    Protected key, result = 0, value.l, size = SizeOf(Long)
    If RegOpenKeyEx_(#HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", 0, #KEY_READ, @key) = #ERROR_SUCCESS
      If RegQueryValueEx_(key, "AppsUseLightTheme", 0, 0, @value, @size) = #ERROR_SUCCESS
        result = Bool(value = 0) ; 0 = dark mode
        IsDarkModeActiveCached = result
      EndIf
      RegCloseKey_(key)
    EndIf
    ProcedureReturn result
  EndProcedure
  
  
  
  
  ; -------------------- Dark Mode Application --------------------
  Procedure ApplyThemeToWindowHandle(hWnd)
    
    Protected bg, fg
    If IsDarkModeActiveCached
      bg = RGB(30,30,30)
      fg = RGB(220,220,220)
      SetClassLongPtr_(hWnd, #GCL_HBRBACKGROUND, CreateSolidBrush_(bg))
      InvalidateRect_(hWnd, #Null, #True)
    Else
      bg = RGB(255,255,255)
      fg = RGB(0,0,0)
      Protected currentBrush = GetClassLongPtr_(hWnd, #GCL_HBRBACKGROUND)
      
      ; Set to default system color
      Protected defaultBrush = CreateSolidBrush_(GetSysColor_(#COLOR_3DFACE))
      SetClassLongPtr_(hWnd, #GCL_HBRBACKGROUND, defaultBrush)
      InvalidateRect_(hWnd, #Null, #True)
      
      ; Clean up old brush if it's not a stock object
      If currentBrush > 31  ; Stock objects are values 0-31
        DeleteObject_(currentBrush)
      EndIf
      
      ; Redraw
      InvalidateRect_(hWnd, #Null, #True)
    EndIf
    
    
    ; Title bar
    SetDarkTitleBar(hWnd, IsDarkModeActiveCached)
  EndProcedure
  
  Procedure ApplyWindowTheme(winID)
    If IsDarkModeActiveCached
      SetWindowThemeDynamic(WindowID(winID), "DarkMode_Explorer")
    Else
      SetWindowThemeDynamic(WindowID(winID), "Explorer")
    EndIf
  EndProcedure
  
  Procedure ApplyGadgetTheme(gadgetId)
    
    ; Only apply if dark mode active
    If IsDarkModeActiveCached
      SetWindowThemeDynamic(gadgetId, "DarkMode_Explorer")
    Else
      SetWindowThemeDynamic(gadgetId, "Explorer")
    EndIf
    
    ; Force repaint
    SendMessage_(gadgetId, #WM_THEMECHANGED, 0, 0)
    InvalidateRect_(gadgetId, #Null, #True)
  EndProcedure
  
  
  
  
  
  ; --- Windows API Constants (if not already defined in your PureBasic environment) ---
  ; --- Windows API Constants ---
  #LVM_FIRST = $1000
  #LVM_GETHEADER = #LVM_FIRST + 31
  #LVM_SETCOLUMNWIDTH = #LVM_FIRST + 30
  #GWL_STYLE = -16
  #HDS_NOSIZING = $0800
  #HDS_HIDDENX = $0080 ; HDS_HIDDEN is not for hiding the divider, but is sometimes related to styling
  
  
  
  Procedure ApplySingleColumnListIconWin(listHwnd)
    
    
    ; 1. Ensure only one column exists (index 0)
    While SendMessage_(listHwnd, #LVM_DELETECOLUMN, 1, 0)
    Wend
    
    ; 2. Disable Resizing Action
    Protected hwndHeader = SendMessage_(listHwnd, #LVM_GETHEADER, 0, 0)
    If hwndHeader
      Protected HeaderStyle = GetWindowLong_(hwndHeader, #GWL_STYLE)
      SetWindowLong_(hwndHeader, #GWL_STYLE, HeaderStyle | #HDS_NOSIZING)
      RedrawWindow_(hwndHeader, 0, 0, #RDW_FRAME | #RDW_INVALIDATE | #RDW_UPDATENOW)
    EndIf
    
    ; 3. Calculate and Manually Oversize Column Width
    Protected ListIconRect.RECT
    If GetClientRect_(listHwnd, @ListIconRect)
      Protected ClientWidth = ListIconRect\Right - ListIconRect\Left
      
      ; Set the width intentionally wider than the gadget.
      ; This pushes the final divider line off the visible area.
      Protected OversizeWidth = ClientWidth + 3 ; Use +20 for a generous buffer.
      
      ; Set the column 0 width to the calculated oversize width.
      SendMessage_(listHwnd, #LVM_SETCOLUMNWIDTH, 0, OversizeWidth)
    EndIf
    
    ; 4. Disable the Horizontal Scrollbar
    ; We MUST do this immediately after oversizing the column to prevent the 
    ; horizontal scrollbar from appearing.
    ShowScrollBar_(listHwnd, #SB_HORZ, #False)
  EndProcedure
  
  
  #NM_CUSTOMDRAW = -12
  #CDRF_DODEFAULT = 0
  #CDRF_NOTIFYITEMDRAW = $20
  #CDDS_PREPAINT = 1
  #CDDS_ITEMPREPAINT = $10001
  
  Global NewMap ListIconThemeProcs()
  
  
  Procedure ListIconThemeProc(hwnd, msg, wParam, lParam)
    
    Protected bg 
    Protected fg 
    If IsDarkModeActiveCached
      bg = RGB(30, 30, 30)
      fg = RGB(255, 255, 255)
    Else
      bg = RGB(255, 255, 255)
      fg = RGB(30, 30, 30) 
    EndIf
    
    If msg = #WM_NOTIFY
      Protected *nmhdr.NMHDR = lParam
      
      Select *nmhdr\code
        Case #HDN_BEGINTRACKA, #HDN_BEGINTRACKW
          ProcedureReturn 1 ; prevent resizing
        Case #NM_CUSTOMDRAW
          Protected *nmcd.NMCUSTOMDRAW = lParam
          Select *nmcd\dwDrawStage
            Case #CDDS_PREPAINT
              ProcedureReturn #CDRF_NOTIFYITEMDRAW
            Case #CDDS_ITEMPREPAINT
              SetTextColor_(*nmcd\hdc, fg)
              SetBkColor_(*nmcd\hdc, bg)
              ProcedureReturn #CDRF_NEWFONT
          EndSelect
      EndSelect
    EndIf
    
    oldListViewProc = ListIconThemeProcs(Str(hwnd))
    
    
    ; Call original window procedure
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
      ProcedureReturn CallWindowProc_(oldListViewProc, hwnd, msg, wParam, lParam)
    CompilerElse
      ProcedureReturn CallWindowProcA_(oldListViewProc, hwnd, msg, wParam, lParam)
    CompilerEndIf
  EndProcedure
  
  Procedure ApplyListIconTheme(listHwnd)
    Protected bg 
    Protected fg 
    If IsDarkModeActiveCached
      bg = RGB(30, 30, 30)
      fg = RGB(255, 255, 255)
    Else
      bg = RGB(255, 255, 255)
      fg = RGB(30, 30, 30) 
    EndIf
    
    ; Set colors directly via Windows messages instead of SetGadgetColor
    SendMessage_(listHwnd, #LVM_SETBKCOLOR, 0, bg)
    SendMessage_(listHwnd, #LVM_SETTEXTBKCOLOR, 0, bg)
    SendMessage_(listHwnd, #LVM_SETTEXTCOLOR, 0, fg)
    
    Protected headerHwnd = SendMessage_(listHwnd, #LVM_GETHEADER, 0, 0)
    If headerHwnd
      If IsDarkModeActiveCached
        SetWindowThemeDynamic(headerHwnd, "DarkMode_ItemsView")
      Else
        SetWindowThemeDynamic(headerHwnd, "ItemsView")
      EndIf    
      ; FIRST: GET the old window proc
      ; SECOND: SET the new window proc
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
        If FindMapElement(ListIconThemeProcs(),Str(listHwnd)) = 0
          ListIconThemeProcs(Str(listHwnd)) = GetWindowLongPtr_(listHwnd, #GWL_WNDPROC)
        EndIf 
        ;oldListViewProc = GetWindowLongPtr_(listHwnd, #GWL_WNDPROC)
        SetWindowLongPtr_(listHwnd, #GWL_WNDPROC, @ListIconThemeProc())
      CompilerElse
        If FindMapElement(ListIconThemeProcs(),Str(listHwnd)) = 0
          ListIconThemeProcs(listHwnd) =  GetWindowLong_(listHwnd, #GWL_WNDPROC)
        EndIf 
        
        ; oldListViewProc = GetWindowLong_(listHwnd, #GWL_WNDPROC)
        SetWindowLong_(listHwnd, #GWL_WNDPROC, @ListIconThemeProc())
      CompilerEndIf
      
      
      InvalidateRect_(headerHwnd, 0, #True)
    EndIf
  EndProcedure
  
  
  Global NewMap StaticControlThemeProcs()
  
  Procedure StaticControlThemeProc(hwnd, msg, wParam, lParam)
    Protected oldProc = StaticControlThemeProcs(Str(hwnd))
    Protected fg, bg
    
    If IsDarkModeActiveCached
      bg = RGB(30, 30, 30)
      fg = RGB(255, 255, 255)
    Else
      bg = RGB(255, 255, 255)
      fg = RGB(30, 30, 30)
    EndIf
    Protected result
    Select msg
      Case #WM_SETTEXT
        ; Let Windows actually set the text first
        result = CallWindowProc_(oldProc, hwnd, msg, wParam, lParam)
        ; Now trigger repaint AFTER text changed
        InvalidateRect_(hwnd, #Null, #True)
        UpdateWindow_(hwnd) ; force immediate paint
        ProcedureReturn result
        
      Case #WM_PAINT
        Protected ps.PAINTSTRUCT
        Protected hdc = BeginPaint_(hwnd, @ps)
        Protected rect.RECT
        GetClientRect_(hwnd, @rect)
        
        ; Draw background
        Protected hBrush = CreateSolidBrush_(bg)
        FillRect_(hdc, @rect, hBrush)
        DeleteObject_(hBrush)
        
        ; Font + color
        Protected hFont = SendMessage_(hwnd, #WM_GETFONT, 0, 0)
        If hFont : SelectObject_(hdc, hFont) : EndIf
        SetBkMode_(hdc, #TRANSPARENT)
        SetTextColor_(hdc, fg)
        
        ; Get text
        Protected textLen = GetWindowTextLength_(hwnd)
        
        If textLen > 0
          Protected *text = AllocateMemory((textLen + 1) * SizeOf(Character))
          GetWindowText_(hwnd, *text, textLen + 1)
          
          ; Alignment + ellipsis setup
          Protected style = GetWindowLong_(hwnd, #GWL_STYLE)
          Protected format = #DT_VCENTER | #DT_SINGLELINE | #DT_END_ELLIPSIS | #DT_NOPREFIX | #DT_WORD_ELLIPSIS | #DT_MODIFYSTRING | #DT_LEFT
          
          If style & #SS_CENTER
            format | #DT_CENTER
          ElseIf style & #SS_RIGHT
            format | #DT_RIGHT
          EndIf

          ; Draw clipped text with ellipsis
          DrawText_(hdc, *text, -1, @rect, format)
          
          FreeMemory(*text)
        EndIf
        
        EndPaint_(hwnd, @ps)
        ProcedureReturn 0
        
        
        
      Case #WM_ERASEBKGND
        ProcedureReturn 1
    EndSelect
    
    ProcedureReturn CallWindowProc_(oldProc, hwnd, msg, wParam, lParam)
  EndProcedure
  
  
  
  ; Define constants globally
  #WS_EX_SIZEGRIP   = $00000100
  #SWP_FRAMECHANGED = $0020            ; Forces non-client area redraw
  #WM_USER_FORCE_REDRAW = #WM_USER + 100 ; Custom message for delayed action
  
  ; --------------------------------------------------------------------------
  ; Window Callback Procedure (Subclassing)
  ; --------------------------------------------------------------------------
  ; Note: ProcedureC ensures correct calling convention for a window callback
  ProcedureC EditGadgetWindowCallback(hWnd, uMsg, wParam, lParam)
    Protected result
    Protected style, exStyle
    Protected OrigWndProc = GetProp_(hWnd, "OrigWndProc")
    
    ; 📢 1. Handle the custom message for delayed enforcement
    If uMsg = #WM_USER_FORCE_REDRAW
      
      ; Re-enforce the style removal
      style = GetWindowLong_(hWnd, #GWL_STYLE)
      exStyle = GetWindowLong_(hWnd, #GWL_EXSTYLE)
      
      style = style & ~#WS_HSCROLL & ~#WS_SIZEBOX
      exStyle = exStyle & ~#WS_EX_SIZEGRIP
      
      SetWindowLong_(hWnd, #GWL_STYLE, style)
      SetWindowLong_(hWnd, #GWL_EXSTYLE, exStyle)
      
      ; Force the frame change now
      SetWindowPos_(hWnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      
      ; Redraw everything one last time
      RedrawWindow_(hWnd, #Null, #Null, #RDW_INVALIDATE | #RDW_FRAME | #RDW_UPDATENOW | #RDW_ALLCHILDREN)
      
      ProcedureReturn 0 ; Handled
    EndIf
    
    ; 2. Block the resize grip detection in the hit test
    If uMsg = #WM_NCHITTEST
      result = CallWindowProc_(OrigWndProc, hWnd, uMsg, wParam, lParam)
      
      ; If Windows detected the resize grip area, change the result to #HTCLIENT
      If result = #HTBOTTOMRIGHT Or result = #HTSIZE Or result = #HTGROWBOX Or result = #HTBORDER
        ProcedureReturn #HTCLIENT
      EndIf
      ProcedureReturn result
    EndIf
    
    ; 3. When window is shown, force a repaint
    If uMsg = #WM_SHOWWINDOW And wParam <> 0
      result = CallWindowProc_(OrigWndProc, hWnd, uMsg, wParam, lParam)
      
      ; Force a complete redraw after the original procedure handles the show event
      InvalidateRect_(hWnd, #Null, #True)
      UpdateWindow_(hWnd)
      
      ProcedureReturn result
    EndIf
    
    ; 4. Re-enforce style removal on size/position changes
    If uMsg = #WM_WINDOWPOSCHANGED Or uMsg = #WM_SIZE
      
      style = GetWindowLong_(hWnd, #GWL_STYLE)
      exStyle = GetWindowLong_(hWnd, #GWL_EXSTYLE)
      
      If (style & #WS_SIZEBOX) Or (exStyle & #WS_EX_SIZEGRIP) Or (style & #WS_HSCROLL)
        style = style & ~#WS_HSCROLL & ~#WS_SIZEBOX
        SetWindowLong_(hWnd, #GWL_STYLE, style)
        
        exStyle = exStyle & ~#WS_EX_SIZEGRIP
        SetWindowLong_(hWnd, #GWL_EXSTYLE, exStyle)
        
        ; Force the frame to update after changing the style
        SetWindowPos_(hWnd, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
      EndIf
      
      ; Re-enable word wrap
      SendMessage_(hWnd, #EM_SETTARGETDEVICE, 0, 0)
    EndIf
    
    ; Call original window procedure for all other messages
    ProcedureReturn CallWindowProc_(OrigWndProc, hWnd, uMsg, wParam, lParam)
  EndProcedure
  
  ; --------------------------------------------------------------------------
  ; Theme Application Procedure
  ; --------------------------------------------------------------------------
  
  
  
  Global editorID
  ; Constants for RichEdit
#EM_SETCHARFORMAT = $0444

#EM_GETSEL = $00B0
#EM_SETPROTECTED = $04C9
#SCF_SELECTION = 1
#CFM_COLOR = $40000000
#ES_READONLY = $0800
#WM_SETREDRAW = $000B
#WM_PAINT = $000F

; CHARFORMATA structure (ANSI, for fallback)
Structure CHARFORMAT_Minimal
  cbSize.l
  dwMask.l
  dwEffects.l
  yHeight.l
  yOffset.l
  crTextColor.l
  bCharSet.b
  bPitchAndFamily.b
  szFaceName.a[32]
EndStructure


Structure FINDTEXTEXW
  chrg.CHARRANGE
  lpstrText.s
  chrgText.CHARRANGE
EndStructure

#TO_ADVANCEDTYPOGRAPHY = $0001 ; Enable advanced typography
#EM_SETTYPOGRAPHYOPTIONS = #WM_USER + 202
#EM_SETBACKGROUND = #WM_USER + 43 ; Rich Edit background color message



; Calculate luminance for contrast ratio
Procedure.f CalculateLuminance(color.l)
  Protected r.f = Red(color) / 255.0
  Protected g.f = Green(color) / 255.0
  Protected b.f = Blue(color) / 255.0
  ProcedureReturn 0.299 * r + 0.587 * g + 0.114 * b
EndProcedure

; Calculate contrast ratio between two colors
Procedure.f CalculateContrastRatio(color1.l, color2.l)
  Protected l1.f = CalculateLuminance(color1)
  Protected l2.f = CalculateLuminance(color2)
  If l1 < l2
    Swap l1, l2
  EndIf
  ProcedureReturn (l1 + 0.05) / (l2 + 0.05)
EndProcedure

; Adjust foreground color to ensure visibility
Procedure.l AdjustForegroundColor(fg.l, bg.l)
  Protected contrast.f = CalculateContrastRatio(fg, bg)
  Protected minContrast.f = 4.5 ; WCAG AA threshold
  Protected r.l = Red(fg)
  Protected g.l = Green(fg)
  Protected b.l = Blue(fg)
  
  
  If contrast < minContrast
    If CalculateLuminance(bg) < 0.5 ; Dark background
      ; Lighten foreground
      r = MinI(r + 50, 255)
      g = MinI(g + 50, 255)
      b = MinI(b + 50, 255)
    Else ; Light background
      ; Darken foreground
      r = MaxI(r - 50, 0)
      g = MaxI(g - 50, 0)
      b = MaxI(b - 50, 0)
    EndIf
    Protected newFg.l = RGB(r, g, b)
    ProcedureReturn newFg
  EndIf
  ProcedureReturn fg
EndProcedure

Procedure ApplyColorToSelection(hEditor, fg.l)
  Protected Result.l
  Protected start.l, endx.l
  Protected bg.l
  
  ; Set background color based on dark mode
  If IsDarkModeActiveCached
    bg = RGB(30, 30, 30) ; Dark mode background
  Else
    bg = RGB(255, 255, 255) ; Light mode background
  EndIf
  
  ; Adjust foreground color for visibility
  fg = AdjustForegroundColor(fg, bg)
  
  SendMessage_(hEditor, #EM_GETSEL, @start, @endx)
  
  Protected *buffer = AllocateMemory(60)
  If *buffer
    PokeL(*buffer + 0, 60) ; cbSize
    PokeL(*buffer + 4, #CFM_COLOR) ; dwMask
    PokeL(*buffer + 8, 0) ; dwEffects
    PokeL(*buffer + 20, fg) ; crTextColor
    

    
    SendMessage_(hEditor, #EM_SETPROTECTED, 0, 0)
    
    Result = SendMessage_(hEditor, #EM_SETCHARFORMAT, #SCF_SELECTION, *buffer)
    
    FreeMemory(*buffer)
  Else
    ProcedureReturn 0
  EndIf
  
  ProcedureReturn Result
EndProcedure


Procedure.s GetEditorGadgetText(hEditor)
    Protected gte.GETTEXTEX
  text.s = ""
 Protected textLen.l = SendMessage_(hEditor, #WM_GETTEXTLENGTH, 0, 0) + 1
  Protected *textBuffer = AllocateMemory(textLen * SizeOf(Character))
  If *textBuffer
    gte\cb = textLen * SizeOf(Character)
    gte\flags = #GT_DEFAULT
    gte\codepage = 1200 ; CP_UNICODE
    SendMessage_(hEditor, #EM_GETTEXTEX, @gte, *textBuffer)
    text.s = PeekS(*textBuffer, -1, #PB_Unicode)
    FreeMemory(*textBuffer)
 
  EndIf
 
  ProcedureReturn text
EndProcedure

Procedure SetEditorTextColor(index, newLinesCount.l = 0)
  If containerLogEditorID(index) = 0 Or Not IsGadget(containerLogEditorID(index))
    ProcedureReturn
  EndIf

  If newLinesCount = 0
    HideGadget(containerLogEditorID(index), #True)
  EndIf

  Protected hEditor = GadgetID(containerLogEditorID(index))
  ; Get scroll position
  Protected scrollPos.POINT
  SendMessage_(hEditor, #EM_GETSCROLLPOS, 0, @scrollPos)
  Protected Result.l
  Protected start.l, endx.l
  Protected text.s, pos.l, len.l, p.l
  Protected fg.l
  Protected foundStringMatch.l
  Protected pattern.s
  Protected fte.FINDTEXTEXW
  Protected searchText.s, startPos.l

  ; Store current selection to restore later
  SendMessage_(hEditor, #EM_GETSEL, @start, @endx)

  text = GetEditorGadgetText(hEditor)
  If text = ""
    ProcedureReturn 0
  EndIf

  ; Determine search text and starting position
  If newLinesCount > 0
    ; Find the start of the last newLinesCount lines
    Protected lineCount.l = SendMessage_(hEditor, #EM_GETLINECOUNT, 0, 0)
    Protected targetLine.l = lineCount - newLinesCount
    If targetLine < 0 : targetLine = 0 : EndIf ; Ensure not negative
    startPos = SendMessage_(hEditor, #EM_LINEINDEX, targetLine, 0)
    If startPos = -1 : startPos = 0 : EndIf ; Fallback if invalid
    searchText = Mid(text, startPos + 1)
  Else
    searchText = text
    startPos = 0
  EndIf

  ; Check if read-only
  Protected options.l = SendMessage_(hEditor, #EM_GETOPTIONS, 0, 0)
  Protected isReadOnly = Bool(options & #ECO_READONLY)
  If isReadOnly
    SendMessage_(hEditor, #EM_SETREADONLY, #False, 0)
  EndIf

  ; Loop through each pattern for the given index
  For p = 0 To patternCount(index) - 1
    pattern = Trim(patterns(index, p))
    fg = patternColor(index, p)

    ; Reset string match flag for this pattern
    foundStringMatch = 0

    ; Try EM_FINDTEXTEXW for simple string matches (case-sensitive)
    pos = startPos
    While #True
      fte\chrg\cpMin = pos
      fte\chrg\cpMax = Len(text) ; Search to end of full text
      fte\lpstrText = pattern
      Result = SendMessage_(hEditor, #EM_FINDTEXTEXW, #FR_DOWN | #FR_MATCHCASE, @fte)
      If Result = -1 Or fte\chrgText\cpMin >= Len(text) Or (newLinesCount > 0 And fte\chrgText\cpMin >= startPos + Len(searchText))
        Break ; No more matches or beyond search text
      EndIf
      foundStringMatch = 1
      pos = fte\chrgText\cpMin
      len = fte\chrgText\cpMax - fte\chrgText\cpMin

      ; Set selection for the match (0-based)
      SendMessage_(hEditor, #EM_SETSEL, pos, pos + len)

      ; Apply color
      Result = ApplyColorToSelection(hEditor, fg)

      pos + len ; Move to next position
    Wend

    ; Only try regular expression if no string matches were found
    If Not foundStringMatch
      If CreateRegularExpression(0, pattern)
        Protected *matches = ExamineRegularExpression(0, searchText)
        While NextRegularExpressionMatch(0)
          pos = RegularExpressionMatchPosition(0)
          len = RegularExpressionMatchLength(0)
          ; Adjust position to full text (1-based to 0-based)
          pos = startPos + pos - 1

          ; Set selection (0-based)
          SendMessage_(hEditor, #EM_SETSEL, pos, pos + len)

          ; Apply color
          Result = ApplyColorToSelection(hEditor, fg)
        Wend
        FreeRegularExpression(0)
      EndIf
    EndIf
  Next

  ; Restore read-only if it was set
  If isReadOnly
    SendMessage_(hEditor, #EM_SETREADONLY, #True, 0)
  EndIf

  ; Restore original selection
  SendMessage_(hEditor, #EM_SETSEL, start, endx)
  If newLinesCount = 0
    HideGadget(containerLogEditorID(index), #False)
  EndIf

  ; Restore scroll position
  SendMessage_(hEditor, #EM_SETSCROLLPOS, 0, @scrollPos)
  ; Force redraw
  SendMessage_(hEditor, #WM_SETREDRAW, 1, 0)
  InvalidateRect_(hEditor, #Null, #True)
  UpdateWindow_(hEditor)

  ProcedureReturn 1
EndProcedure


  
  
  Procedure ApplyEditorGadgetTheme(gadgetHandle)
  Protected style, exStyle
  Protected Result.l
  Protected *buffer
  
  ; Apply Dark Mode attributes
  DwmSetWindowAttributeDynamic(gadgetHandle, #DWMWA_USE_IMMERSIVE_DARK_MODE, @IsDarkModeActiveCached, SizeOf(Integer))
  
  ; Set left and right margins (in pixels)
  ;Protected leftMargin = 10
  ;Protected rightMargin = 10
 ; SendMessage_(gadgetHandle, #EM_SETMARGINS, #EC_LEFTMARGIN | #EC_RIGHTMARGIN, leftMargin | (rightMargin << 16))
 
Protected leftMargin = 10  ; Pixels
  Protected rightMargin = 10 ; Pixels
  Protected bottomMargin = 10 ; Pixels
  Protected twipsPerPixel = 15 ; 1440 twips/inch ÷ 96 pixels/inch (adjust for DPI if needed)

  ; Set left and right margins
  SendMessage_(gadgetHandle, #EM_SETMARGINS, #EC_LEFTMARGIN | #EC_RIGHTMARGIN, leftMargin | (rightMargin << 16))

  ; Set bottom margin via paragraph formatting
  Protected pfmt.PARAFORMAT2
  pfmt\cbSize = SizeOf(PARAFORMAT2)
  pfmt\dwMask = #PFM_SPACEAFTER
  pfmt\dySpaceAfter = bottomMargin * twipsPerPixel ; 10 pixels → 150 twips
  SendMessage_(gadgetHandle, #EM_SETPARAFORMAT, 0, @pfmt)
  
; Protected r.RECT
; GetClientRect_(gadgetHandle, @r)
; r\left = 10        ; left margin
; r\right = r\right-10      ; right margin
; r\bottom = r\bottom-10     ; bottom margin
; 
; SendMessage_(gadgetHandle, #EM_SETRECTNP, 0, @r)

  ; Get current styles
  style = GetWindowLong_(gadgetHandle, #GWL_STYLE)
  exStyle = GetWindowLong_(gadgetHandle, #GWL_EXSTYLE)
  
  ; Remove styles
  style = style & ~#WS_HSCROLL & ~#WS_SIZEBOX
  SetWindowLong_(gadgetHandle, #GWL_STYLE, style)
  
  exStyle = exStyle & ~#WS_EX_SIZEGRIP
  SetWindowLong_(gadgetHandle, #GWL_EXSTYLE, exStyle)
  
  ; Subclass the window to block resize grip detection (only once)
  If GetProp_(gadgetHandle, "OrigWndProc") = 0
    Protected oldProc = SetWindowLongPtr_(gadgetHandle, #GWLP_WNDPROC, @EditGadgetWindowCallback())
    SetProp_(gadgetHandle, "OrigWndProc", oldProc)
  EndIf
  
  ; Enable word wrap
  SendMessage_(gadgetHandle, #EM_SETTARGETDEVICE, 0, 0)
  
  ; --- Themeing/Redraw ---
  If IsDarkModeActiveCached
    SendMessage_(gadgetHandle, #EM_SETBKGNDCOLOR, 0, RGB(0, 0, 0))
    
    ; Set default text color without overwriting existing formatting
     *buffer = AllocateMemory(60)
    If *buffer
      PokeL(*buffer + 0, 60) ; cbSize
      PokeL(*buffer + 4, #CFM_COLOR) ; dwMask
      PokeL(*buffer + 8, 0) ; dwEffects
      PokeL(*buffer + 20, RGB(255, 255, 255)) ; crTextColor (white for dark mode)
      

      Result = SendMessage_(gadgetHandle, #EM_SETCHARFORMAT, #SCF_ALL, *buffer)
      
     
      FreeMemory(*buffer)
    EndIf
    
    SetWindowThemeDynamic(gadgetHandle, "DarkMode_Explorer")
  Else
    SendMessage_(gadgetHandle, #EM_SETBKGNDCOLOR, 0, RGB(255, 255, 255))
    
    ; Set default text color without overwriting existing formatting
     *buffer = AllocateMemory(60)
    If *buffer
      PokeL(*buffer + 0, 60) ; cbSize
      PokeL(*buffer + 4, #CFM_COLOR) ; dwMask
      PokeL(*buffer + 8, 0) ; dwEffects
      PokeL(*buffer + 20, RGB(0, 0, 0)) ; crTextColor (black for light mode)
      
      
      
      Result = SendMessage_(gadgetHandle, #EM_SETCHARFORMAT, #SCF_ALL, *buffer)
      
      
      FreeMemory(*buffer)
    EndIf
    
    SetWindowThemeDynamic(gadgetHandle, "Explorer")
  EndIf
  
  ; Post custom message to force frame change
  PostMessage_(gadgetHandle, #WM_USER_FORCE_REDRAW, 0, 0)
  
  ; Final aggressive repaints
  SendMessage_(gadgetHandle, #WM_SETREDRAW, 1, 0)
  RedrawWindow_(gadgetHandle, #Null, #Null, #RDW_INVALIDATE | #RDW_FRAME | #RDW_UPDATENOW | #RDW_ALLCHILDREN | #RDW_ERASE)
  InvalidateRect_(gadgetHandle, #Null, #True)
  UpdateWindow_(gadgetHandle)
  
  
  
 
  For index = 0 To monitorCount-1
    If IsGadget( containerLogEditorID(index))
        SetEditorTextColor(index)
      EndIf
    Next

  
EndProcedure
  
  
  
  Global NewMap CheckboxThemeProcs()
  
  Procedure CheckboxThemeProc(hWnd, uMsg, wParam, lParam)
    Protected originalProc
    
    ; Get the original procedure
    If FindMapElement(CheckboxThemeProcs(), Str(hWnd))
      originalProc = CheckboxThemeProcs()
    Else
      ProcedureReturn DefWindowProc_(hWnd, uMsg, wParam, lParam)
    EndIf
    ; Handle specific messages for dark mode
    Select uMsg
      Case #WM_PAINT
        
        ; Let the default painting happen first
        Protected result.i = CallWindowProc_(originalProc, hWnd, uMsg, wParam, lParam)
        ProcedureReturn result
        
      Case #WM_ERASEBKGND
        If IsDarkModeActiveCached
          Protected hDC.i = wParam
          Protected rect.RECT
          GetClientRect_(hWnd, @rect)
          
          ; Fill with parent's dark background
          Protected hBrush.i = CreateSolidBrush_(RGB(30, 30, 30))
          FillRect_(hDC, @rect, hBrush)
          DeleteObject_(hBrush)
          
          ProcedureReturn 1 ; We handled it
        EndIf
        
        
    EndSelect
    
    ; For all other messages, call original procedure
    ProcedureReturn CallWindowProc_(originalProc, hWnd, uMsg, wParam, lParam)
  EndProcedure
  
  Procedure ApplyCheckboxTheme(hWnd)
    If IsDarkModeActiveCached
      ; Try setting dark theme first
      SetWindowThemeDynamic(hWnd, "DarkMode_Explorer")
      
      ; Subclass to handle background painting
      CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
        CheckboxThemeProcs(Str(hWnd)) = SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, @CheckboxThemeProc())
      CompilerElse
        CheckboxThemeProcs(Str(hWnd)) = SetWindowLong_(hWnd, #GWL_WNDPROC, @CheckboxThemeProc())
      CompilerEndIf
    Else
      SetWindowThemeDynamic(hWnd, "Explorer")
    EndIf
    
    InvalidateRect_(hWnd, #Null, #True)
    UpdateWindow_(hWnd)
  EndProcedure
  
  Procedure ApplyThemeToWindowChildren(hWnd, lParam)
    Protected className.s = Space(256)
    Protected length = GetClassName_(hWnd, @className, 256)
    
    If length > 0
      className = LCase(PeekS(@className))
      
      Select className
          
        Case "button"
          ; Applies to Button, CheckBox, Option gadgets
          
          textLength2 = GetWindowTextLength_(hWnd)
          style.l = GetWindowLong_(hWnd, #GWL_STYLE)
          If ((style & #BS_CHECKBOX) <> 0) Or ((style & #BS_AUTOCHECKBOX) <> 0)
            ApplyCheckboxTheme(hWnd)
            
          Else
            ; Normal button
            ApplyGadgetTheme(hWnd)
          EndIf
          
          ; Force repaint for checkboxes/options
          SendMessage_(hWnd, #WM_THEMECHANGED, 0, 0)
          InvalidateRect_(hWnd, #Null, #True)
          
        Case "static"
          Protected textLength = GetWindowTextLength_(hWnd)
          If textLength = 0
            ProcedureReturn #True ; probably ImageGadget
          EndIf
          
          CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
            Protected oldProc = SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, @StaticControlThemeProc())
          CompilerElse
            Protected oldProc = SetWindowLong_(hWnd, #GWL_WNDPROC, @StaticControlThemeProc())
          CompilerEndIf
          
          StaticControlThemeProcs(Str(hWnd)) = oldProc
          
        Case "syslistview32"
          ApplyListIconTheme(hWnd)
          
        Case  "combobox", "listbox", "systreeview32", "msctls_trackbar32"; "edit"
          ApplyGadgetTheme(hWnd)
          
        Case "richedit50w", "richedit20w", "richedit"
          ApplyEditorGadgetTheme(hWnd)
          
      EndSelect
    EndIf
    
    InvalidateRect_(hWnd, #Null, #True)
    ProcedureReturn #True
  EndProcedure
  
  
  
  
  
  
  Procedure ApplyThemeHandle(hWnd)
    ApplyThemeToWindowHandle(hWnd)
    EnumChildWindows_(hWnd, @ApplyThemeToWindowChildren(), 0)
    UpdateWindow_(hWnd)    
  EndProcedure
  
CompilerEndIf
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - arm64)
; CursorPosition = 22
; Folding = -----
; EnableXP
; DPIAware
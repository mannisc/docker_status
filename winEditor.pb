  CompilerIf #PB_Compiler_OS = #PB_OS_Windows

#EM_GETLINECOUNT = $BA
#EM_LINESCROLL   = $B6
#EM_GETFIRSTVISIBLELINE = $CE
#EM_SCROLLCARET = $B7
#EM_SETSEL = $B1
#WM_GETTEXTLENGTH = $0E
#ECO_READONLY = $800

Procedure GetEditorLineHeight(hGadget)
  Protected hFont.i = SendMessage_(hGadget, #WM_GETFONT, 0, 0)
  If hFont = 0 : ProcedureReturn 16 ; fallback
    
    Protected hDC.i = GetDC_(hGadget)
    Protected hOldFont.i = SelectObject_(hDC, hFont)
    
    Protected tm.TEXTMETRIC
    GetTextMetrics_(hDC, @tm)
    
    SelectObject_(hDC, hOldFont)
    ReleaseDC_(hGadget, hDC)
    
    ProcedureReturn tm\tmHeight + tm\tmExternalLeading
  EndIf 
  ProcedureReturn 0
EndProcedure

Procedure ScrollEditorToBottomWin(gadget)
  Protected hEditor = GadgetID(gadget)
  If hEditor = 0 : ProcedureReturn : EndIf
  
  
  ; --- Scroll caret into view ---
  SendMessage_(hEditor, #EM_SETSEL, -1, -1)
  SendMessage_(hEditor, #EM_SCROLLCARET, 0, 0)
  
EndProcedure

Procedure.l IsAtScrollBottomWin(EditorGadgetID)
  Protected Handle.i = GadgetID(EditorGadgetID)
  Protected si.SCROLLINFO
  
  If Handle
    si\cbSize = SizeOf(SCROLLINFO)
    si\fMask = #SIF_ALL
    If GetScrollInfo_(Handle, #SB_VERT, @si)
      
      ; 3. Check the condition for being at the bottom.
      ; The scrollbar is at the bottom when:
      ; Current Position (nPos) + Viewport Size (nPage) >= Maximum Scrollable Value (nMax) + 1
      Debug "SCROLL "+Str(si\nPos + si\nPage - (si\nMax -100))+" > 0 ?"
      Debug si\nPos
      Debug si\nPage
      Debug si\nMax
      
      If si\nPos + si\nPage >= si\nMax - 100
        ProcedureReturn #True
      EndIf
      
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

  CompilerEndIf 

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 66
; FirstLine = 36
; Folding = -
; EnableXP
; DPIAware
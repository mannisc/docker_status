;  %LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\profiles.json

#WIN_MAIN = 0
#PANEL_MAIN = 100
#EDT_CMD = 101
#BTN_COLOR = 102
#CHK_NOTIFY = 103
#BTN_OK = 104
#BTN_CANCEL = 105
#TXT_DOCKER = 200
#CNT_COLORPREVIEW = 300

Global PatternColor = RGB(255, 0, 0)

OpenWindow(#WIN_MAIN, 200, 120, 500, 372, "Monitor", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)

   PanelGadget(#PANEL_MAIN, 0, 0, 500, 325)

SetGadgetFont(#PANEL_MAIN, 1)
  If LoadFont(0, "Segoe UI", 10)
      SetGadgetFont(#PANEL_MAIN, FontID(0))   ; Set the loaded Arial 16 font as new standard
    EndIf
    
 AddGadgetItem(#PANEL_MAIN, -1, "  Presets  ")
 
 AddGadgetItem(#PANEL_MAIN, -1, "  Command  ")
    ComboBoxGadget(#PB_Any, 10, 10, 200, 25)

    EditorGadget(#EDT_CMD, 3, 45, 489, 205)
    ButtonGadget(#BTN_COLOR, 294, 10, 160, 25, "Select Monitor Color...")
    
    ContainerGadget(#CNT_COLORPREVIEW, 464, 12, 21, 21, #PB_Container_Flat)
      
    CloseGadgetList()
    SetGadgetColor(#CNT_COLORPREVIEW, #PB_Gadget_BackColor, PatternColor)
      
    CheckBoxGadget(#CHK_NOTIFY, 360, 263, 160, 20, "Enable Notifications")
    
  AddGadgetItem(#PANEL_MAIN, -1, "  Directory  ")
    ExplorerListGadget(#PB_Any, 3, 35, 489, 245, "*.*", #PB_Explorer_MultiSelect)
  AddGadgetItem(#PANEL_MAIN, -1, "  Status  ")
  TextGadget(#PB_Any, 10, 10, 470, 340, "Docker tab content goes here.") 

  AddGadgetItem(#PANEL_MAIN, -1, "  Reaction ")
  TextGadget(#PB_Any  , 10, 10, 470, 340, "Docker tab content goes here.") 
  AddGadgetItem(#PANEL_MAIN, -1, "  Filter  ")
  TextGadget(#PB_Any, 10, 10, 470, 340, "Docker tab content goes here.") 

  
  CloseGadgetList()
  
  ButtonGadget(#BTN_OK, 300, 333, 90, 30, "OK")
  ButtonGadget(#BTN_CANCEL, 400, 333, 90, 30, "Cancel")
  
; dark editor colors
SetGadgetColor(#EDT_CMD, #PB_Gadget_BackColor, RGB(18, 18, 18))
SetGadgetColor(#EDT_CMD, #PB_Gadget_FrontColor, RGB(230, 230, 230))


Repeat
  Select WaitWindowEvent()
    Case #PB_Event_Gadget
      Select EventGadget()
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
      Break
  EndSelect
ForEver

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 31
; EnableXP
; DPIAware
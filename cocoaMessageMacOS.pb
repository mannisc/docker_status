EnableExplicit

Define Window0ID, Event

CreateImage(0, 300, 200, 32, #PB_Image_Transparent)
StartDrawing(ImageOutput(0))
DrawingMode(#PB_2DDrawing_AllChannels)
RoundBox(0, 0, 300, 200, 30, 30, RGBA(160, 160, 160, 255))
StopDrawing()

If OpenWindow(0, 0, 0, 300, 200, "PureBasic Window", #PB_Window_BorderLess | #PB_Window_ScreenCentered | #PB_Window_Invisible)
  Window0ID = WindowID(0)
  CocoaMessage(0, Window0ID, "setOpaque:", #NO)
  CocoaMessage(0, Window0ID, "setBackgroundColor:", CocoaMessage(0, 0, "NSColor colorWithPatternImage:", ImageID(0)))
  CocoaMessage(0, Window0ID, "setMovableByWindowBackground:", #YES)
  CocoaMessage(0, Window0ID, "setHasShadow:", #NO)
  HideWindow(0, #False)
  
  ButtonGadget(0, 10, 10, 100, 30, "Quit")
  
  Repeat
    Event = WaitWindowEvent()
    
    If Event = #PB_Event_Gadget And EventGadget() = 0
      Break
    EndIf
    
  ForEver
  
EndIf
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - arm64)
; CursorPosition = 14
; EnableXP
; DPIAware
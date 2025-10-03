; -------------------- CONSTANTS --------------------
#MAX_CONTAINERS = 1000
#MAX_PATTERNS   = 1000
#MAX_LINES   = 5000
#ICON_SIZE      = 256
#UPDATE_INTERVAL = 1

#JSON_Save      = 0
#JSON_Load      = 1

; -------------------- GLOBAL VARIABLES --------------------

Structure ContainerOutput
  List lines.s()
EndStructure

Global monitorCount.l = 0
Global Dim containerName.s(#MAX_CONTAINERS-1)
Global Dim bgColor.l(#MAX_CONTAINERS-1)
Global Dim innerColor.l(#MAX_CONTAINERS-1)
Global Dim neutralInnerColor.l(#MAX_CONTAINERS-1)
Global Dim infoImageID.l(#MAX_CONTAINERS-1)
Global Dim dockerProgramID(#MAX_CONTAINERS-1)
Global Dim patternCount.l(#MAX_CONTAINERS-1)
Global Dim lastMatchTime.l(#MAX_CONTAINERS-1)
Global Dim tooltip.s(#MAX_CONTAINERS-1)
Global Dim trayID.l(#MAX_CONTAINERS-1)
Global Dim containerStarted.b(#MAX_CONTAINERS-1)
Global Dim containerOutput.containerOutput(#MAX_CONTAINERS-1)
Global Dim lastMatch.s(#MAX_CONTAINERS-1)
Global Dim containerStatusColor.l(#MAX_CONTAINERS-1)
Structure LogWindow
  winID.i
  editorGadgetID.i
  containerIndex.i
EndStructure

Global NewList logWindows.LogWindow()

Structure ContainterMetaData
  logWindowX.l
  logWindowY.l
  logWindowW.l
  logWindowH.l
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    bigIconHandle.i
    smallIconHandle.i
  CompilerEndIf
EndStructure

Global Dim containterMetaData.ContainterMetaData(#MAX_CONTAINERS-1)


Global Dim patterns.s(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)
Global Dim patternColor.l(#MAX_CONTAINERS-1, #MAX_PATTERNS-1)


 Global pattern$ = ""
 Global patCol = 0
 Global currentContainerIndex = 0
 Global currentPatternIndex = 0
 
 
Enumeration KeyboardEvents
  #EventOk
EndEnumeration


PrototypeC SetProcAppID(AppID.p-unicode) ; wide string (LPWSTR)

Global SetCurrentProcessExplicitAppUserModelID.SetProcAppID

; Load function from shell32.dll
If OpenLibrary(0, "shell32.dll")
  SetCurrentProcessExplicitAppUserModelID = GetFunction(0, "SetCurrentProcessExplicitAppUserModelID")
  CloseLibrary(0)
EndIf

Procedure SetProcessAppId(appId.s)
  Debug  "???"
  Debug SetCurrentProcessExplicitAppUserModelID
  If SetCurrentProcessExplicitAppUserModelID
    Protected result = SetCurrentProcessExplicitAppUserModelID(appId)
    If result = 0 ; S_OK
      Debug "AppUserModelID set to: " + appId
    Else
      Debug "SetCurrentProcessExplicitAppUserModelID failed: " + Str(result)
    EndIf
  Else
    Debug "Function not found in shell32.dll"
  EndIf
EndProcedure


; --- Example usage (call at program start, before opening windows) ---
;SetProcessAppId("com.mycompany.myapp.uniqueid")


;Windows Method


CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  
  ; --- PUREBASIC API DECLARATIONS ---
  
  ; Constants for the API calls
  #ICON_BIG = 1
  #ICON_SMALL = 0
  #WM_SETICON = $80
  
  ; API Function Prototypes
  ; Function to create the icon
  Prototype CreateIconIndirect(lpIconInfo.i)
  
  Global CreateIconIndirect_ = CreateIconIndirect
  
  ; Function to clean up the created icon
  Prototype DestroyIcon(hIcon)
  Global DestroyIcon_ = DestroyIcon
  
  ; Function to clean up the created bitmaps
  Prototype DeleteObject(hObject)
  Global DeleteObject_ = DeleteObject
  
  
  ; --- HICON CREATION PROCEDURE ---
  Procedure.i CreateHIconFromImage(pbImageID)
    
    Protected hIcon.i
    Protected ii.ICONINFO
    
    ; 2. Extract the HBITMAP handle from the PureBasic Image ID
    ii\hbmColor = ImageID(pbImageID)
    
    ; 3. Create the Mask Bitmap (hbmMask)
    ;    For 32-bit images with alpha, the hbmMask must be a monochrome (1-bit) bitmap.
    ;    We create a temporary mask that is the same size, filled with black.
    
    ; Get the image dimensions
    w = ImageWidth(pbImageID)
    h = ImageHeight(pbImageID)
    
    ; Create a compatible monochrome bitmap (hbmMask)
    ii\hbmMask = CreateBitmap_(w, h, 1, 1, #Null)
    
    If ii\hbmMask = 0
      ProcedureReturn 0
    EndIf
    
    ; 4. Populate the ICONINFO structure
    ii\fIcon = #True ; It's an icon, not a cursor
    ii\xHotspot = 0  ; Not used for window icons
    ii\yHotspot = 0  ; Not used for window icons
    
    ; 5. Create the HICON handle
    hIcon = CreateIconIndirect_(ii)
    
    ; 6. Clean up the temporary mask bitmap
    ;    The CreateIconIndirect_ function copies the mask, so we can delete the temporary one.
    DeleteObject_(ii\hbmMask)
    
    ProcedureReturn hIcon
  EndProcedure
  
  ; --- HICON CREATION PROCEDURE WITH CIRCLE AND TRANSPARENCY ---
  Procedure.i CreateCircularOverlayHIcon(index)
    Protected hIcon.i
    Protected ii.ICONINFO
    Protected w, h
    
    ; Use the desired size
    w = #ICON_SIZE
    h =   #ICON_SIZE
    ; Create a 32-bit RGBA image
    imgOverlay =  CreateImage(#PB_Any, w, h)
    If imgOverlay
      ; Fill fully transparent background
      StartDrawing(ImageOutput(imgOverlay))
      Box(0, 0, w, h, RGBA(0,0,0,0)) ; fully transparent; Draw filled circle in opaque color (e.g., cyan)
      Circle(w/2, h/2, w/2, bgColor(index))
      Circle(w/2, h/2, w/2- #ICON_SIZE*0.1, containerStatusColor(index))
      StopDrawing()
      imgBG =  CreateImage(#PB_Any, w, h)
      If imgBG
        ; Fill fully transparent background
        StartDrawing(ImageOutput(imgBG))
        Box(0, 0, w, h, RGB(255,255,255)) ; fully transparent; Draw filled circle in opaque color (e.g., cyan)
        Circle(w/2, h/2, w/2, RGB(0,0,0))
        StopDrawing()
        
        ; Set up ICONINFO
        ii\hbmColor = ImageID(imgOverlay)
        ii\hbmMask  = ImageID(imgBG) ;CreateBitmap_(w, h, 1, 1, #Null) ; monochrome mask
        
        If ii\hbmMask = 0
          ProcedureReturn 0
        EndIf
        
        ii\fIcon = #True
        ii\xHotspot = 0
        ii\yHotspot = 0
        
        ; Create the HICON
        hIcon = CreateIconIndirect_(ii)
        
        ; Cleanup temporary mask
        DeleteObject_(ii\hbmMask)
      EndIf
    EndIf
    ProcedureReturn hIcon
  EndProcedure
  
  
  
CompilerEndIf




; -------------------- JSON FILE --------------------
Global settingsFile.s = "docker_monitors.json"


; -------------------- SAVE/LOAD PROCEDURES --------------------
Procedure SaveSettings()
  If CreateJSON(#JSON_Save)
    MonitorArray = SetJSONArray(JSONValue(#JSON_Save))
    For i = 0 To monitorCount-1
      MonitorObj = SetJSONObject(AddJSONElement(MonitorArray))
      SetJSONString(AddJSONMember(MonitorObj, "Name"), containerName(i))
      SetJSONInteger(AddJSONMember(MonitorObj, "BGColor"), bgColor(i))
      SetJSONInteger(AddJSONMember(MonitorObj, "InnerColor"), innerColor(i))
      SetJSONInteger(AddJSONMember(MonitorObj, "NeutralColor"), neutralInnerColor(i))
      SetJSONInteger(AddJSONMember(MonitorObj, "Started"), containerStarted(i))
      
      
      
      SetJSONInteger(AddJSONMember(MonitorObj, "LogX"), containterMetaData(i)\logWindowX)
      SetJSONInteger(AddJSONMember(MonitorObj, "LogY"), containterMetaData(i)\logWindowY)
      SetJSONInteger(AddJSONMember(MonitorObj, "LogW"), containterMetaData(i)\logWindowW)
      SetJSONInteger(AddJSONMember(MonitorObj, "LogH"), containterMetaData(i)\logWindowH)
      
      
      PatternArray = SetJSONArray(AddJSONMember(MonitorObj, "Patterns"))
      For p = 0 To patternCount(i)-1
        PatternObj = SetJSONObject(AddJSONElement(PatternArray))
        SetJSONString(AddJSONMember(PatternObj, "Pattern"), patterns(i,p))
        SetJSONInteger(AddJSONMember(PatternObj, "Color"), patternColor(i,p))
      Next
    Next
    ; Write to file
    If CreateFile(0, settingsFile)
      WriteString(0, ComposeJSON(#JSON_Save, #PB_JSON_PrettyPrint))
      CloseFile(0)
    EndIf
  EndIf
EndProcedure



Procedure LoadSettings()
  If ReadFile(0, settingsFile)
    Input$ = ""
    While Not Eof(0)
      Input$ + Trim(ReadString(0))
    Wend 
    CloseFile(0)
    If ParseJSON(#JSON_Load, Input$, #PB_JSON_NoCase)
      
      Structure Pattern
        pattern.s
        color.l
      EndStructure
      Structure Container
        name.s
        bgColor.l
        innerColor.l
        neutralInnerColor.l
        containerStarted.b
        logX.l
        logY.l
        logW.l
        logH.l
        List patterns.Pattern()
      EndStructure
      
      NewList ContainerList.Container()
      ParseJSON(0, Input$)
      ExtractJSONList(JSONValue(#JSON_Load), ContainerList())
      ForEach ContainerList()
        ; Directly read fields
        containerName(monitorCount)     = ContainerList()\name
        bgColor(monitorCount)          = ContainerList()\bgColor
        innerColor(monitorCount)       = ContainerList()\innerColor
        neutralInnerColor(monitorCount) = ContainerList()\neutralInnerColor
        containerStarted(monitorCount)= ContainerList()\containerStarted
        
        
        containterMetaData(monitorCount)\logWindowX = ContainerList()\logX
        containterMetaData(monitorCount)\logWindowY = ContainerList()\logY
        containterMetaData(monitorCount)\logWindowW = ContainerList()\logW
        containterMetaData(monitorCount)\logWindowH = ContainerList()\logH
        
        patternCount(monitorCount) = 0
        ForEach ContainerList()\patterns()
          
          patterns(monitorCount, patternCount(monitorCount))     = ContainerList()\patterns()\pattern
          patternColor(monitorCount, patternCount(monitorCount)) = ContainerList()\patterns()\color
          patternCount(monitorCount) + 1
        Next 
        
        tooltip(monitorCount) = containerName(monitorCount)
        monitorCount + 1
        
        
      Next
      
      
      
    EndIf
  EndIf
EndProcedure



Procedure.l IsAtScrollBottom(EditorGadgetID)
  Protected Handle.i = GadgetID(EditorGadgetID)
  Protected si.SCROLLINFO
  
  If Handle
    si\cbSize = SizeOf(SCROLLINFO)
    si\fMask = #SIF_ALL
    If GetScrollInfo_(Handle, #SB_VERT, @si)
      
      ; 3. Check the condition for being at the bottom.
      ; The scrollbar is at the bottom when:
      ; Current Position (nPos) + Viewport Size (nPage) >= Maximum Scrollable Value (nMax) + 1
      Debug Str(si\nPos + si\nPage - (si\nMax -100))+" > 0 ?"
      If si\nPos + si\nPage >= si\nMax - 100
        ProcedureReturn #True
      EndIf
      
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure



#EM_GETLINECOUNT = $BA
#EM_LINESCROLL   = $B6

Procedure ScrollEditorToBottom(EditorGadgetID)
  Protected Handle.i = GadgetID(EditorGadgetID)
  
  If Handle
    ; 1. Get the current total length of the text in the control
    ;    The #PB_Editor_GetTextLength flag is safe for this.
    TextLength = Len(GetGadgetText(EditorGadgetID))
    
    ; 2. Force the selection/cursor to the end of the text.
    ;    wParam (Start Pos): TextLength (sets the start of the selection just past the text)
    ;    lParam (End Pos): TextLength (sets the end of the selection just past the text)
    SendMessage_(Handle, #EM_SETSEL, TextLength, TextLength)
    
    ; 3. Ensure the caret (cursor) is visible after the selection is set
    SendMessage_(Handle, #EM_SCROLLCARET, 0, 0)
  EndIf
EndProcedure




; Constants
#Notification_TimerID = 1 ; A unique ID for the timer
#Notification_Duration = 2500 ; 5000 ms = 5 seconds
#Notification_Width = 180
#Notification_Height = 40
Global notificationWinID = 0
; Procedure to create and show the notification
Procedure ShowSystrayNotification(index)
  ExamineDesktops()
  w = DesktopUnscaledX(DesktopWidth(0))
  h = DesktopUnscaledY(DesktopHeight(0))
  winID  = OpenWindow(#PB_Any, w - #Notification_Width - 10, h - #Notification_Height - 10-80, #Notification_Width, #Notification_Height, "", #PB_Window_BorderLess | #PB_Window_Tool|#PB_Window_Invisible      )
  If winID
    StickyWindow(winID,#True)
    TextGadget(#PB_Any, 20, 0, #Notification_Width-20, 20, "Docker Status is running",#PB_Text_Center )
    colorGadget = ContainerGadget(#PB_Any,10, 0,16,16,#PB_Container_BorderLess)
    CloseGadgetList()
    SetGadgetColor(colorGadget,#PB_Gadget_BackColor,bgColor(index))
    
    If notificationWinID <>0
     CloseWindow(notificationWinID)
    EndIf
    notificationWinID = winID
    AddWindowTimer(winID, #Notification_TimerID, #Notification_Duration)
    HideWindow(winID,#False)
  EndIf
EndProcedure



; -------------------- MONITOR ICON --------------------


Procedure CreateInfoImage(index, innerCol, bgCol)
  
  If  CreateImage(1000+index, #ICON_SIZE, #ICON_SIZE, 32)
     infoImageID(index)  = 1000+index
    Debug infoImageID(index) 
    If StartVectorDrawing(ImageVectorOutput(infoImageID(index)))
      VectorSourceColor(RGBA(0,0,0,0))
      VectorSourceColor(RGBA(Red(bgCol), Green(bgCol), Blue(bgCol), 255))
      ;AddPathCircle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2 - 1)
      ;FillPath()
      FillVectorOutput()
      VectorSourceColor(RGBA(Red(innerCol), Green(innerCol), Blue(innerCol), 255))
      AddPathCircle(#ICON_SIZE/2, #ICON_SIZE/2, #ICON_SIZE/2 - 20)
      FillPath()
      StopVectorDrawing()
    EndIf
  EndIf
EndProcedure



























; Constants
; -----------------------------
#ICON_BIG = 1
#ICON_SMALL = 0
#WM_SETICON = $80
#CLSCTX_ALL = $17  ; 23 decimal

; -----------------------------
; Import WinAPI & COM functions
; -----------------------------
PrototypeC CreateIconIndirect_(lpIconInfo.i)
PrototypeC DestroyIcon_(hIcon.i)
PrototypeC DeleteObject_(hObject.i)
PrototypeC CreateBitmap_(nWidth.l, nHeight.l, nPlanes.l, nBitCount.l, lpBits.i)
PrototypeC SendMessage_(hWnd.i, Msg.l, wParam.i, lParam.i)
PrototypeC CoCreateInstance_(rclsid.i, pUnkOuter.i, dwClsContext.l, riid.i, ppv.i)
PrototypeC CoInitializeEx_(pvReserved.i, dwCoInit.l)
PrototypeC CoUninitialize_()

Global CreateIconIndirect_ = GetFunction(OpenLibrary(0, "user32.dll"), "CreateIconIndirect")
Global DestroyIcon_       = GetFunction(OpenLibrary(0, "user32.dll"), "DestroyIcon")
Global DeleteObject_      = GetFunction(OpenLibrary(0, "gdi32.dll"),  "DeleteObject")
Global CreateBitmap_      = GetFunction(OpenLibrary(0, "gdi32.dll"),  "CreateBitmap")
Global SendMessage_       = GetFunction(OpenLibrary(0, "user32.dll"), "SendMessageA")

Global libOle = OpenLibrary(0, "ole32.dll")
Global CoCreateInstance_  = GetFunction(libOle, "CoCreateInstance")
Global CoInitializeEx_    = GetFunction(libOle, "CoInitializeEx")
Global CoUninitialize_    = GetFunction(libOle, "CoUninitialize")

; -----------------------------
; CLSID and IID
; -----------------------------
Global CLSID_TaskbarList.IID
CLSID_TaskbarList\Data1 = $56FDF344
CLSID_TaskbarList\Data2 = $FD6D
CLSID_TaskbarList\Data3 = $11D0
CLSID_TaskbarList\Data4[0] = $95
CLSID_TaskbarList\Data4[1] = $8A
CLSID_TaskbarList\Data4[2] = $00
CLSID_TaskbarList\Data4[3] = $60
CLSID_TaskbarList\Data4[4] = $97
CLSID_TaskbarList\Data4[5] = $C9
CLSID_TaskbarList\Data4[6] = $A0
CLSID_TaskbarList\Data4[7] = $90

Global IID_ITaskbarList.IID
IID_ITaskbarList\Data1 = $56FDF342
IID_ITaskbarList\Data2 = $FD6D
IID_ITaskbarList\Data3 = $11D0
IID_ITaskbarList\Data4[0] = $95
IID_ITaskbarList\Data4[1] = $8A
IID_ITaskbarList\Data4[2] = $00
IID_ITaskbarList\Data4[3] = $60
IID_ITaskbarList\Data4[4] = $97
IID_ITaskbarList\Data4[5] = $C9
IID_ITaskbarList\Data4[6] = $A0
IID_ITaskbarList\Data4[7] = $90

Global IID_ITaskbarList3.IID
IID_ITaskbarList3\Data1 = $EA1AFB91
IID_ITaskbarList3\Data2 = $9E28
IID_ITaskbarList3\Data3 = $4B86
IID_ITaskbarList3\Data4[0] = $90
IID_ITaskbarList3\Data4[1] = $E9
IID_ITaskbarList3\Data4[2] = $9E
IID_ITaskbarList3\Data4[3] = $9F
IID_ITaskbarList3\Data4[4] = $8A
IID_ITaskbarList3\Data4[5] = $5E
IID_ITaskbarList3\Data4[6] = $EB
IID_ITaskbarList3\Data4[7] = $9E



; -----------------------------
; Setup window icon + overlay
; -----------------------------
Procedure SetWindowAndOverlayIcon(winID,index)
  Protected hBigIcon.i = 0
  Protected pTaskbar.i = 0
  Protected pTaskbarBase.i = 0
  Protected hr.l

  ; Initialize COM
  hr = CoInitializeEx_(0, 2)
  If hr < 0
    Debug "CoInitializeEx failed: " + Hex(hr)
    ProcedureReturn 0
  EndIf

  ; Try to create ITaskbarList3
  hr = CoCreateInstance_(@CLSID_TaskbarList, 0, #CLSCTX_ALL, @IID_ITaskbarList3, @pTaskbar)
  If hr < 0 Or pTaskbar = 0
    Debug "ITaskbarList3 not available, fallback to ITaskbarList"
    ; Fallback to ITaskbarList
    hr = CoCreateInstance_(@CLSID_TaskbarList, 0, #CLSCTX_ALL, @IID_ITaskbarList, @pTaskbarBase)
    If hr < 0 Or pTaskbarBase = 0
      Debug "Failed to create any TaskbarList: " + Hex(hr)
      ProcedureReturn hBigIcon
    EndIf
  EndIf

  ; Use whichever interface is available
  Protected interfacePtr.i
  If pTaskbar <> 0
    interfacePtr = pTaskbar
  Else
    interfacePtr = pTaskbarBase
  EndIf

  ; Initialize Taskbar
  Protected vtbl.i = PeekI(interfacePtr)
  Protected *HrInit = PeekI(vtbl + 3*SizeOf(Integer))
  hr = CallFunctionFast(*HrInit, interfacePtr)
  If hr < 0
    Debug "HrInit failed: " + Hex(hr)
  EndIf
  
  ; Only ITaskbarList3 can set overlay
  If interfacePtr <> 0
    ; Create Cyan overlay image
    
    Protected Overlay = CreateCircularOverlayHIcon(index)
    ; Set overlay icon (vtable index 18)
    Protected *SetOverlayIcon = PeekI(vtbl + 18*SizeOf(Integer))
    hr = CallFunctionFast(*SetOverlayIcon, interfacePtr, winID, Overlay, 0)
    If hr < 0
      Debug "SetOverlayIcon failed: " + Hex(hr)
    EndIf
      ; Release COM interface

    ReleaseFunc = PeekI(PeekI(interfacePtr) + 2*SizeOf(Integer)) ; vtable index 2 = Release
    CallFunctionFast(ReleaseFunc, interfacePtr)

  EndIf
  ProcedureReturn hBigIcon
EndProcedure

Procedure RemoveOverlayIcon(winID)
   Protected pTaskbar.i = 0
  Protected pTaskbarBase.i = 0
  Protected hr.l

  ; Initialize COM
  hr = CoInitializeEx_(0, 2)
  If hr < 0
    Debug "CoInitializeEx failed: " + Hex(hr)
    ProcedureReturn 0
  EndIf

  ; Try to create ITaskbarList3
  hr = CoCreateInstance_(@CLSID_TaskbarList, 0, #CLSCTX_ALL, @IID_ITaskbarList3, @pTaskbar)
  If hr < 0 Or pTaskbar = 0
    Debug "ITaskbarList3 not available, fallback to ITaskbarList"
    ; Fallback to ITaskbarList
    hr = CoCreateInstance_(@CLSID_TaskbarList, 0, #CLSCTX_ALL, @IID_ITaskbarList, @pTaskbarBase)
    If hr < 0 Or pTaskbarBase = 0
      Debug "Failed to create any TaskbarList: " + Hex(hr)
      ProcedureReturn hBigIcon
    EndIf
  EndIf

  ; Use whichever interface is available
  Protected interfacePtr.i
  If pTaskbar <> 0
    interfacePtr = pTaskbar
  Else
    interfacePtr = pTaskbarBase
  EndIf

  ; Initialize Taskbar
  Protected vtbl.i = PeekI(interfacePtr)
  Protected *HrInit = PeekI(vtbl + 3*SizeOf(Integer))
  hr = CallFunctionFast(*HrInit, interfacePtr)
  If hr < 0
    Debug "HrInit failed: " + Hex(hr)
  EndIf
  
  ; Only ITaskbarList3 can set overlay
  If interfacePtr <> 0
    ; Create Cyan overlay image
    
    Protected Overlay = CreateCircularOverlayHIcon(index)
    ; Set overlay icon (vtable index 18)
    Protected *SetOverlayIcon = PeekI(vtbl + 18*SizeOf(Integer))
    
    ; Remove overlay icon (pass 0)
    hr = CallFunctionFast(*SetOverlayIcon, interfacePtr, winID, 0, 0)
    If hr < 0
      Debug "Removing overlay icon failed: " + Hex(hr)
    EndIf


  ; Release COM interface

    ReleaseFunc = PeekI(PeekI(interfacePtr) + 2*SizeOf(Integer)) ; vtable index 2 = Release
    CallFunctionFast(ReleaseFunc, interfacePtr)
  EndIf

  CoUninitialize_()
EndProcedure









; --- Necessary API Constant ---
#SWP_FRAMECHANGED = $20 ; Forces a window frame change, which helps refresh the icon.
#SWP_NOMOVE       = $2  ; Retains current position
#SWP_NOSIZE       = $1  ; Retains current size
#SWP_NOZORDER     = $4  ; Retains current Z-order



Procedure CreateWindowIcon(winID,index)
  Debug "CreateWindowIcon"
  Debug Index
  Debug infoImageID(index)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ; Call the procedure to get the icon handles
    iconBG =  CreateImage(#PB_Any, #ICON_SIZE, #ICON_SIZE)
    If iconBG
      StartDrawing(ImageOutput(iconBG))
      Box(0, 0, #ICON_SIZE, #ICON_SIZE, bgColor(index))
      StopDrawing()
      
      BigIconHandle   =  CreateHIconFromImage(iconBG) ;Taskbar icon
      SmallIconHandle =  CreateHIconFromImage(infoImageID(index))
    
    If BigIconHandle 
      If containterMetaData(index)\bigIconHandle
        DestroyIcon_(containterMetaData(index)\bigIconHandle)
      EndIf 
      containterMetaData(index)\bigIconHandle = BigIconHandle
      SendMessage_(WindowID(winID), #WM_SETICON, #ICON_BIG, BigIconHandle)
    EndIf 
    If SmallIconHandle
      If containterMetaData(index)\smallIconHandle
        DestroyIcon_(containterMetaData(index)\smallIconHandle)
      EndIf 
      containterMetaData(index)\smallIconHandle = SmallIconHandle
     SendMessage_(WindowID(winID), #WM_SETICON, #ICON_SMALL, SmallIconHandle)
   EndIf
   EndIf 
   SetWindowAndOverlayIcon(WindowID(winID),index)

  CompilerEndIf
EndProcedure














Procedure CreateMonitorIcon(index, innerCol, bgCol)
  
  CreateInfoImage(index, innerCol, bgCol)
  
  If trayID(index) = 0
    trayID(index) = index + 1
    AddSysTrayIcon(trayID(index), WindowID(0), ImageID(infoImageID(index)))
    SysTrayIconToolTip(trayID(index), tooltip(index))
    CreatePopupImageMenu(1000+index, #PB_Menu_SysTrayLook)
    MenuItem(1000+index*10, "Open")
    MenuItem(1000+index*10+1, "Logs")
    MenuBar()
    MenuItem(1000+index*10+2, "Exit")
    SysTrayIconMenu(trayID(index), MenuID(1000+index))   
  Else
    ChangeSysTrayIcon(trayID(index), ImageID(infoImageID(index)))
  EndIf
  ForEach logWindows()
    If logWindows()\containerIndex = index
      CreateWindowIcon(logWindows()\winID,index)
      Break
    EndIf
  Next
EndProcedure

; -------------------- SET LIST ITEM STARTED --------------------
Procedure SetListItemStarted(index,started)
  bgCol = bgColor(index)
  Protected img = CreateImage(#PB_Any, 32, 32, 32, bgCol)
  If img
    StartVectorDrawing(ImageVectorOutput(img))
    VectorSourceColor(RGBA(Red(bgCol), Green(bgCol), Blue(bgCol), 255))
    FillVectorOutput()
    If started
      MovePathCursor(8, 6)
      AddPathLine(24, 16)
      AddPathLine(8, 26)
      ClosePath()
      VectorSourceColor(RGBA(0,0,0,255))
      FillPath()
      MovePathCursor(8, 6)
      AddPathLine(24, 16)
      AddPathLine(8, 26)
      ClosePath()
      VectorSourceColor(RGBA(255, 255, 255, 255))
      StrokePath(3)
    EndIf
    StopVectorDrawing()
    SetGadgetItemImage(0, index, ImageID(img))
  EndIf
EndProcedure

; -------------------- LIST ITEM COLOR --------------------
Procedure SetListItemColor(gadgetID, index, color)
  Protected img = CreateImage(#PB_Any, 1, 1)
  If img
    StartDrawing(ImageOutput(img))
    Box(0,0,1,1,color)
    StopDrawing()
    SetGadgetItemImage(gadgetID, index, ImageID(img))
  EndIf
EndProcedure

; -------------------- BUTTON STATES --------------------
Procedure UpdateButtonStates()
  selIndex = GetGadgetState(0)
  If selIndex >= 0
    DisableGadget(2, #False)
    DisableGadget(5, #False)
    DisableGadget(6, #False)
    If containerStarted(selIndex)
      DisableGadget(3, #True)
      DisableGadget(4, #False)
    Else
      DisableGadget(3, #False)
      DisableGadget(4, #True)
    EndIf
  Else
    DisableGadget(2, #True)
    DisableGadget(3, #True)
    DisableGadget(4, #True)
    DisableGadget(5, #True)
    DisableGadget(6, #True)
  EndIf
EndProcedure

; -------------------- MONITOR LIST --------------------
Procedure UpdateMonitorList()
  ClearGadgetItems(0)
  For i = 0 To monitorCount-1
    AddGadgetItem(0, -1, "  "+containerName(i))
    SetListItemStarted(i, containerStarted(i))
  Next
  UpdateButtonStates()
EndProcedure

; -------------------- ADD MONITOR --------------------
Procedure AddMonitor(contName.s, bgCol.l)
  If monitorCount >= #MAX_CONTAINERS
    MessageRequester("Docker Status", "Max monitors reached", 0)
    ProcedureReturn
  EndIf
  containerName(monitorCount) = contName
  bgColor(monitorCount) = bgCol
  innerColor(monitorCount) = $FFFFFF
  neutralInnerColor(monitorCount) = $FFFFFF
  patternCount(monitorCount) = 0
  tooltip(monitorCount) = contName
  monitorCount + 1
  SaveSettings()
EndProcedure

; -------------------- REMOVE MONITOR --------------------
Procedure RemoveMonitor(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  
  
  
  If trayID(index) <> 0
    RemoveSysTrayIcon(trayID(index))
    trayID(index) = 0
  EndIf
  For i = index To monitorCount - 2
    containerName(i) = containerName(i + 1)
    bgColor(i) = bgColor(i + 1)
    innerColor(i) = innerColor(i + 1)
    neutralInnerColor(i) = neutralInnerColor(i + 1)
    infoImageID(i) = infoImageID(i + 1)
    trayID(i) = trayID(i + 1)
    containerStarted(i) = containerStarted(i + 1)
    dockerProgramID(i) = dockerProgramID(i + 1)
    patternCount(i) = patternCount(i + 1)
    tooltip(i) = tooltip(i + 1)
    For p = 0 To #MAX_PATTERNS-1
      patterns(i,p) = patterns(i+1,p)
      patternColor(i,p) = patternColor(i+1,p)
    Next
    lastMatchTime(i) = lastMatchTime(i+1)
  Next
  monitorCount - 1
  SaveSettings()
EndProcedure



; -------------------- PATTERNS --------------------
Procedure UpdatePatternButtonStates()
  selIndex = GetGadgetState(40)
  If selIndex >= 0
    DisableGadget(42, #False)
    DisableGadget(43, #False)
  Else
    DisableGadget(42, #True)
    DisableGadget(43, #True)
  EndIf
EndProcedure

Procedure UpdatePatternList(index)
  If IsGadget(40)
    ClearGadgetItems(40)
    For p = 0 To patternCount(index)-1
      AddGadgetItem(40, -1,"  "+ patterns(index,p))
      SetListItemColor(40, p, patternColor(index,p))
    Next
  EndIf 
EndProcedure
; -------------------- ADD MONITOR DIALOG --------------------
Procedure CloseAddMonitorDialog(bgCol)
  container$ = GetGadgetText(10)
  If container$ <> ""
    AddMonitor(container$, bgCol)
    UpdateMonitorList()
    SetActiveGadget(0)
    SetGadgetItemState(0, monitorCount-1, #PB_ListIcon_Selected)
    UpdateButtonStates()
  EndIf
EndProcedure

Procedure AddMonitorDialog()
  If OpenWindow(1, 0, 0, 380, 130, "Add Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(10, 10, 10, 360, 24, "")
    SetActiveGadget(10)
    AddKeyboardShortcut(1, #PB_Shortcut_Return, #EventOk)
    
    TextGadget(11, 10, 53, 100, 24, "Background Color:")
    ContainerGadget(14, 120, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(12, 150, 50, 100, 24, "Choose...")
    ButtonGadget(13, 80, 100, 80, 24, "OK")
    ButtonGadget(15, 170, 100, 80, 24, "Cancel")
    
    bgCol = RGB(200,200,200)
    SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
    DisableGadget(13, #True)
    
    StickyWindow(1,#True)
  EndIf
EndProcedure

; -------------------- EDIT MONITOR DIALOG --------------------
Procedure EditMonitorDialog(selIndex)
  container$ = containerName(selIndex)
  bgCol      = bgColor(selIndex)
  
  If OpenWindow(5, 0, 0, 380, 130, "Edit Container", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(50, 10, 10, 360, 24, container$)
    SetActiveGadget(50)
    
    TextGadget(51, 10, 53, 100, 24, "Background Color:")
    ContainerGadget(54, 120, 50, 24, 24, #PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(52, 150, 50, 100, 24, "Choose...")
    ButtonGadget(53, 80, 100, 80, 24, "OK")
    ButtonGadget(55, 170, 100, 80, 24, "Cancel")
    
    SetGadgetColor(54, #PB_Gadget_BackColor, bgCol)
    If container$ = ""
      DisableGadget(53, #True)
    EndIf
    
    StickyWindow(5,#True)
  EndIf
EndProcedure

; -------------------- EDIT COLORS DIALOG --------------------
Procedure EditColorsDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(6,150,150,360,160,"Edit Colors for " + containerName(index),#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ButtonGadget(60,10,10,160,28,"Pick Background")
    ButtonGadget(61,190,10,160,28,"Pick Neutral Inner")
    ButtonGadget(62,10,50,160,28,"Pick Inner (active)")
    ButtonGadget(63,190,50,160,28,"Recreate Icon")
    ButtonGadget(64,80,100,80,24,"Close")
    StickyWindow(6,#True)
  EndIf
EndProcedure

; -------------------- ADD PATTERN --------------------
Procedure AddPattern(index, pat.s, color.l)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If patternCount(index) >= #MAX_PATTERNS
    ProcedureReturn
  EndIf
  patterns(index, patternCount(index)) = pat
  patternColor(index, patternCount(index)) = color
  patternCount(index) + 1
  SaveSettings()
EndProcedure

; -------------------- ADD PATTERN DIALOG --------------------
Procedure AddPatternDialog(monitorIndex)
  If OpenWindow(2,0,0,380,130,"Add Log Status Pattern",#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(20,10,10,360,24,"")
    SetActiveGadget(20)
    TextGadget(21,10,53,100,24,"Pattern Color:")
    ContainerGadget(24,95,50,24,24,#PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(22,125,50,100,24,"Choose...")
    ButtonGadget(23,80,100,80,24,"OK")
    ButtonGadget(25,170,100,80,24,"Cancel")
    DisableGadget(23,#True)
    
    patCol = RGB(255,0,0)
    SetGadgetColor(24,#PB_Gadget_BackColor,patCol)
    StickyWindow(2,#True)
  EndIf
EndProcedure

; -------------------- EDIT PATTERN DIALOG --------------------
Procedure EditPatternDialog(index,selIndex)
  pattern$ = patterns(index,selIndex)
  patCol = patternColor(index,selIndex)
  
  If OpenWindow(3,0,0,380,130,"Edit Log Filter",#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    StringGadget(30,10,10,360,24,pattern$)
    SetActiveGadget(30)
    TextGadget(31,10,53,100,24,"Pattern Color:")
    ContainerGadget(34,95,50,24,24,#PB_Container_BorderLess)
    CloseGadgetList()
    ButtonGadget(32,125,50,100,24,"Choose...")
    ButtonGadget(33,80,100,80,24,"OK")
    ButtonGadget(35,170,100,80,24,"Cancel")
    SetGadgetColor(34,#PB_Gadget_BackColor,patCol)
    
    
    StickyWindow(3,#True)
  EndIf
EndProcedure


Procedure EditPatternsDialog(index)
  If index < 0 Or index >= monitorCount
    ProcedureReturn
  EndIf
  If OpenWindow(4,150,150,420,450,"Edit Log Filter",#PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ListIconGadget(40,10, 10, 300, 430,"Log Filter",295,#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection)
    ButtonGadget(41, 325, 10, 80, 24, "Add")
    ButtonGadget(43, 325, 40, 80, 24, "Remove")
    ButtonGadget(42, 325, 80, 80, 24, "Edit")
    ButtonGadget(44, 325, 417, 80, 24, "Ok")
    
    
    UpdatePatternList(index)
    UpdatePatternButtonStates()
    
    StickyWindow(4,#True)
  EndIf
EndProcedure

; -------------------- DOCKER EXECUTABLE --------------------
Procedure.s TryDockerDefaultPaths()
  Protected dockerPaths.s
  Protected dockerPath.s
  Protected i = 1
  Protected path$ = ""
  Select #PB_Compiler_OS
    Case #PB_OS_Windows
      dockerPaths = "C:\Program Files\Docker\Docker\resources\bin\docker.exe|C:\Program Files\Docker\Docker\docker.exe|C:\Program Files\Docker\docker.exe|C:\Program Files (x86)\Docker\Docker\resources\bin\docker.exe|C:\Program Files (x86)\Docker\Docker\docker.exe"
    Case #PB_OS_Linux
      dockerPaths = "/usr/bin/docker|/usr/local/bin/docker|/snap/bin/docker|/bin/docker"
    Case #PB_OS_MacOS
      dockerPaths = "/usr/local/bin/docker|/usr/bin/docker|/opt/homebrew/bin/docker|/Applications/Docker.app/Contents/Resources/bin/docker"
  EndSelect
  
  Repeat 
    path$ = StringField(dockerPaths, i, "|")
    If path$ <> "" And FileSize(path$)
      ProcedureReturn path$
    EndIf
    i + 1
  Until Trim(path$) = ""
  ProcedureReturn "docker"
EndProcedure

Procedure.s GetDockerExcutable()
  Protected pathEnv.s = GetEnvironmentVariable("PATH")
  folder.s = ""
  index = 1
  Repeat
    folder = StringField(pathEnv, index,";")
    Protected candidate.s = folder + "\docker.exe"
    If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
    candidate = folder + "\Docker.exe"
    If FileSize(candidate) > 0 : ProcedureReturn candidate : EndIf
    index + 1
  Until folder = ""
  ProcedureReturn TryDockerDefaultPaths()
EndProcedure

; -------------------- START DOCKER FOLLOW --------------------
Procedure StartDockerFollow(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  
  dockerExecutable$ = GetDockerExcutable()
  container$ = containerName(index)
  dockerCommand$ = "/k " + Chr(34) + dockerExecutable$  +Chr(34) +" logs --follow --tail 1000 " + container$ 
  
  dockerProgramID(index) = RunProgram("cmd.exe", dockerCommand$, "", #PB_Program_Open | #PB_Program_Error | #PB_Program_Read | #PB_Program_Hide)
  
  If trayID(index) = 0
    CreateMonitorIcon(index, innerColor(index), bgColor(index))
  EndIf
  containerStarted(index) = #True
  SetListItemStarted(index,#True)
  
  ShowSystrayNotification(index)

  
EndProcedure

; -------------------- STOP DOCKER FOLLOW --------------------
Procedure StopDockerFollow(index)
  If dockerProgramID(index) <> 0
    CloseProgram(dockerProgramID(index))
    dockerProgramID(index) = 0
  EndIf
  
  RemoveOverlayIcon(WindowID(0))
  ForEach logWindows()
    If logWindows()\containerIndex = index
       RemoveOverlayIcon(WindowID(logWindows()\winID))
      Break
    EndIf
  Next
  
  
  If trayID(index) <> 0
    RemoveSysTrayIcon(trayID(index))
    trayID(index) = 0
  EndIf
  containerStarted(index) = #False
  SetListItemStarted(index,#False)
  SetActiveGadget(0)
  SetGadgetItemState(0,index,#PB_ListIcon_Selected)
  UpdateButtonStates()
EndProcedure

; -------------------- UPDATE MONITOR ICON ON MATCH --------------------

Procedure.s CleanTooltip(s.s)
  For i = 0 To 31
    If i <> 9 And i <> 10
      s =  ReplaceString(s, Chr(i), "")
    EndIf
  Next
  ProcedureReturn s
EndProcedure



Procedure.i MaxI(a.i, b.i)
  If a > b
    ProcedureReturn a
  Else
    ProcedureReturn b
  EndIf
EndProcedure

Procedure UpdateMonitorIcon(index, matchColor)
  containerStatusColor(index) = matchColor
  CreateMonitorIcon(index, matchColor, bgColor(index))
  info$ =  tooltip(index) 
  If Len(info$) > 25
    info$ = Left(info$, 25) + "..."
  EndIf
  output$=lastMatch(index)
  If Len(output$) > 25
    output$ = Left(output$,25+MaxI(0,(25-Len(info$)))) + "..."
  EndIf
  If output$ <> ""
    output$ = output$+Chr(10)+ info$+" - "+FormatDate("%hh:%ii", Date())
  Else
    output$ = info$
  EndIf 
  SysTrayIconToolTip(trayID(index),output$ )
    
  SetWindowAndOverlayIcon(WindowID(0),index)
EndProcedure

Procedure OnMatch(index, patternIndex , line.s)
  lastMatch(index) = line
  lastMatchTime(index) = ElapsedMilliseconds()
  UpdateMonitorIcon(index, patternColor(index,patternIndex))
EndProcedure

Procedure.s RemoveFirstLineFromText(Text.s)
    Protected LineBreakPos.i
    Protected NewText.s
    
    ; Find the position of the first line break (Chr(10) / Line Feed)
    ; Note: Text files often use Chr(13) + Chr(10) (CRLF), so searching for Chr(10) is safer.
    LineBreakPos = FindString(Text, Chr(10), 1)
    
    If LineBreakPos > 0
        ; Return the substring starting just after the line break.
        ; This effectively skips the first line and the line break itself.
        NewText = Mid(Text, LineBreakPos + 1)
    Else
        ; If no line break is found, the text only has one line, so clear it.
        NewText = ""
    EndIf
    
    ProcedureReturn NewText
EndProcedure

Procedure AddOutputLine(index,editorGadgetID,line.s)
  text.s = GetGadgetText(editorGadgetID)
  
  ListSize = ListSize(containerOutput(index)\lines()) 
  If ListSize >= #MAX_LINES
    text = RemoveFirstLineFromText(text.s)
  EndIf
  
  SetGadgetText(editorGadgetID,text+Chr(10)+line)
  
  If IsAtScrollBottom(editorGadgetID)
    ScrollEditorToBottom(editorGadgetID)
  EndIf
EndProcedure 


; -------------------- CHECK DOCKER OUTPUT --------------------

Procedure HandleInputLine(index,line$)
  LastElement(containerOutput(index)\lines())
  AddElement(containerOutput(index)\lines())
  containerOutput(index)\lines() = line$
  
  ListSize = ListSize(containerOutput(index)\lines())
    
  If ListSize > #MAX_LINES
    FirstElement(containerOutput(index)\lines())
    DeleteElement(containerOutput(index)\lines())
    LastElement(containerOutput(index)\lines())
  EndIf
  
  For p = 0 To patternCount(index)-1
    If FindString(line$, patterns(index,p), 1) > 0
      OnMatch(index, p, line$)
    Else
      If CreateRegularExpression(0, patterns(index,p))
        If MatchRegularExpression(0, line$)
          OnMatch(index, p, line$)
        EndIf
      EndIf
    EndIf
  Next
  
  ;Update log windows
  ForEach logWindows()
    If logWindows()\containerIndex = index
      AddOutputLine(logWindows()\containerIndex,logWindows()\editorGadgetID,line$) 
    EndIf
  Next
  
EndProcedure

Procedure CheckDockerOutput(index)
  Protected line.s
  Protected ProgramID.i = dockerProgramID(index)
  Protected dataRead.l ; Flag to track if ANY data was read
  
  ; --- 1. Program Termination Check ---
  If ProgramID = 0 Or Not IsProgram(ProgramID)
    If containerStarted(index)
      ; ... Termination logic ...
      CreateMonitorIcon(index, innerColor(index), bgColor(index))
      dockerProgramID(index) = 0
      containerStarted(index) = #False
    EndIf
    ProcedureReturn
  EndIf
  
  ; --- 2. Non-Blocking Read Loop ---
  Repeat
    dataRead = #False ; Reset for this iteration
    
    ; A. Drain Standard Error (stderr) - (ERROR lines)
    ;    ReadProgramError() is NON-BLOCKING. We drain this stream completely
    ;    on every pass, ensuring no error lines are missed or block the buffer.
    Repeat
      line = ReadProgramError(ProgramID) 
      If line <> ""
        HandleInputLine(index, line)
        dataRead = #True
      EndIf
    Until line = "" ; Loop until ReadProgramError returns an empty string
    
    ; B. Read Standard Output (stdout) - (NORMAL lines)
    ;    ReadProgramString() is BLOCKING, so we MUST check for data first.
    If AvailableProgramOutput(ProgramID) > 0
      ; Data is available, so ReadProgramString() will not block indefinitely.
      line = ReadProgramString(ProgramID)
      
      If line <> ""
        HandleInputLine(index, line)
        dataRead = #True
      EndIf
    EndIf
    
    ; The outer loop ensures that if we read ANYTHING (either from stderr's drain
    ; loop or from stdout), we immediately run the full check again. This is
    ; essential because new data might have arrived during the processing of the last batch.
  Until dataRead = #False 
  
EndProcedure






; -------------------- REDRAW TIMEOUT ICONS --------------------
Procedure RedrawTimeoutIcons()
  For i = 0 To monitorCount-1
    If lastMatchTime(i) > 0
      If ElapsedMilliseconds() - lastMatchTime(i) > 10000
        CreateMonitorIcon(i, neutralInnerColor(i), bgColor(i))
        lastMatchTime(i) = 0
      EndIf
    EndIf
  Next
EndProcedure
; -------------------- IS RUNNING --------------------


Procedure IsRunning()
  For i = 0 To monitorCount-1
    If containerStarted(i)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure



; -------------------- SHOW LOGS --------------------





Procedure ResizeLogWindows()  
  ForEach logWindows()
    If logWindows()\winID = EventWindow()
      
      CurrentW =WindowWidth(EventWindow())
      CurrentH =WindowHeight(EventWindow())
      If CurrentW >= 0 And CurrentH >= 0
        ResizeGadget(logWindows()\editorGadgetID, 0, 0, CurrentW, CurrentH)
        containterMetaData(logWindows()\containerIndex)\logWindowW = CurrentW
        containterMetaData(logWindows()\containerIndex)\logWindowH = CurrentH
      EndIf
      Break
    EndIf
  Next
EndProcedure 

Procedure MoveLogWindows()  
  ForEach logWindows()
    If logWindows()\winID = EventWindow()
      CurrentX = WindowX(EventWindow())
      CurrentY = WindowY(EventWindow())
      If CurrentX >= 0 And CurrentY >= 0
        containterMetaData(logWindows()\containerIndex)\logWindowX = CurrentX
        containterMetaData(logWindows()\containerIndex)\logWindowY = CurrentY
      EndIf
      Break
    EndIf
  Next
EndProcedure 


Procedure CloseLogWindows()
  CloseWindow(EventWindow())
  ForEach logWindows()
    If logWindows()\winID = EventWindow()
      DeleteElement(logWindows())
      Break
    EndIf
  Next
EndProcedure 




Procedure ShowLogs(index)

  ForEach logWindows()
    If logWindows()\containerIndex = index
        SetWindowAndOverlayIcon(WindowID(logWindows()\winID),logWindows()\containerIndex)

      If GetWindowState(logWindows()\winId) = #PB_Window_Minimize Or GetWindowState(logWindows()\winId) = #PB_Window_Maximize
        SetWindowState(logWindows()\winId,#PB_Window_Normal) 
      Else
        SetWindowState(logWindows()\winId,#PB_Window_Minimize) 
      EndIf
      ProcedureReturn
    EndIf
  Next
  
  Protected winID, gadgetID, lineCount, skipCount, i
  Protected text$ = ""
  
  If index < 0 Or index > #MAX_CONTAINERS-1
    ProcedureReturn
  EndIf
  
  lineCount = ListSize(containerOutput(index)\lines())
  
  skipCount = 10000
  
  
  i = 0
  *element = LastElement(containerOutput(index)\lines())
  While *element And i <skipCount
    i + 1
    text$ = containerOutput(index)\lines() + Chr(10) + text$
    *element = PreviousElement(containerOutput(index)\lines())
  Wend
  
  ; Open non-blocking window
  If containterMetaData(index)\logWindowW = 0 And containterMetaData(index)\logWindowH = 0
    containterMetaData(index)\logWindowW = 600
    containterMetaData(index)\logWindowH = 400
  EndIf
  
  If containterMetaData(index)\logWindowX = 0 And containterMetaData(index)\logWindowY = 0
    WindowFlags =  #PB_Window_SystemMenu|  #PB_Window_MaximizeGadget|   #PB_Window_MinimizeGadget |#PB_Window_ScreenCentered
  Else
    WindowFlags = #PB_Window_SystemMenu|   #PB_Window_MaximizeGadget|  #PB_Window_MinimizeGadget
  EndIf
  
  
  
  winID = OpenWindow(#PB_Any, containterMetaData(index)\logWindowX, containterMetaData(index)\logWindowY, containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, containerName(index), WindowFlags |#PB_Window_SizeGadget )
  If winID
    SetWindowColor(winID,RGB(0,0,0))
    
    StickyWindow(winID,#True) 
    editorID = EditorGadget(#PB_Any, 0, 0,  containterMetaData(index)\logWindowW, containterMetaData(index)\logWindowH, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    SetGadgetText(editorID, text$)
    SetGadgetColor(editorID,#PB_Gadget_FrontColor,RGB(200,200,200)) 
    SetGadgetColor(editorID, #PB_Gadget_BackColor ,RGB(0,0,0)) 
    
    AddElement(logWindows())
    logWindows()\winID = winID
    logWindows()\editorGadgetID = editorID
    logWindows()\containerIndex = index
    BindEvent(#PB_Event_SizeWindow, @ResizeLogWindows(),winID)
    BindEvent(#PB_Event_CloseWindow, @CloseLogWindows(),winID)
    BindEvent(#PB_Event_MoveWindow, @MoveLogWindows(),winID)
    
    ScrollEditorToBottom(editorID)
    
    CreateWindowIcon(winID,index)
    
    
  EndIf
EndProcedure


; -------------------- MAIN WINDOW --------------------
If OpenWindow(0,0,0,420,300,"Docker Status",#PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
  ListIconGadget(0, 10, 10, 300, 280,"Container",295,#PB_ListIcon_FullRowSelect)
  ButtonGadget(1, 325, 10, 80, 24, "Add")
  ButtonGadget(6, 325, 40, 80, 24, "Edit")
  ButtonGadget(2, 325, 70, 80, 24, "Remove")
  ButtonGadget(5, 325, 110, 80, 24, "Log Filter")
  ButtonGadget(3, 325, 150, 80, 24, "Start")
  ButtonGadget(4, 325, 180, 80, 24, "Stop")
EndIf


; Load persisted settings
LoadSettings()
UpdateMonitorList()

; -------------------- MAIN EVENT LOOP --------------------
Repeat
  Event = WindowEvent()
  Window = EventWindow()
  
  If Event = #PB_Event_Timer
    If Window = notificationWinID
      CloseWindow(notificationWinID)
      notificationWinID = 0
    EndIf
  EndIf     
  
  Select Window 
    Case 0:
      If Event
        Select Event
          Case #PB_Event_SysTray
            systrayId = EventGadget() 
            For i = 0 To monitorCount-1
              If systrayId = trayID(i)
                ShowLogs(i)
                Break
              EndIf 
            Next
          Case #PB_Event_Menu
            menuEvent = EventMenu()
            If menuEvent>=1000
              menuContainerIndex = Mod(menuEvent/10,10)
              menuId = menuEvent-1000-menuContainerIndex*10
              Select menuId
                Case 0
                  HideWindow(0,#False)
                  SetWindowAndOverlayIcon(WindowID(0),menuContainerIndex)

                Case 1
                  ShowLogs(menuContainerIndex)
                Case 2 ; Exit 
                  For i = 0 To monitorCount-1
                    If dockerProgramID(i) <> 0 : CloseProgram(dockerProgramID(i)) : dockerProgramID(i) = 0 : EndIf
                  Next
                  End
                  End
              EndSelect
            EndIf
          Case #PB_Event_Gadget
            
            currentContainerIndex = GetGadgetState(0)
            Select EventGadget()
              Case 0: UpdateButtonStates()
                If EventType()= #PB_EventType_LeftDoubleClick
                  
                  If currentContainerIndex >= 0
                    If Not containerStarted(currentContainerIndex)
                      StartDockerFollow(currentContainerIndex)
                      SetActiveGadget(0)
                      SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                      UpdateButtonStates()
                    Else
                      StopDockerFollow(currentContainerIndex) 
                    EndIf 
                  EndIf
                EndIf
              Case 1: AddMonitorDialog()
              Case 2
                If currentContainerIndex >= 0
                  RemoveMonitor(currentContainerIndex)
                  UpdateMonitorList()
                EndIf
              Case 3
                If currentContainerIndex >= 0
                  StartDockerFollow(currentContainerIndex)
                  SetActiveGadget(0)
                  SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                  UpdateButtonStates()
                EndIf
              Case 4
                If currentContainerIndex >= 0 : StopDockerFollow(currentContainerIndex) : EndIf
              Case 5
                If currentContainerIndex >= 0
                  EditPatternsDialog(currentContainerIndex)
                  SetActiveGadget(0)
                  SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                  UpdateButtonStates()
                EndIf
              Case 6
                If currentContainerIndex >= 0
                  EditMonitorDialog(currentContainerIndex)
                  SetActiveGadget(0)
                  SetGadgetItemState(0, currentContainerIndex,#PB_ListIcon_Selected)
                  UpdateButtonStates()
                EndIf
            EndSelect
            
          Case #PB_Event_CloseWindow
          
            If IsRunning()
              HideWindow(0,#True)
            Else
              Break;
            EndIf
        EndSelect
      EndIf
    Case 1: ; Add Monitor  
      closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Menu
        closeWindow = #False
        Select EventMenu()
          Case #EventOk
            CloseAddMonitorDialog(bgCol)
            Event = #PB_Event_CloseWindow
        EndSelect
      ElseIf Event = #PB_Event_Gadget
        Select EventGadget()
          Case 10
            If GetGadgetText(10) = ""
              DisableGadget(13, #True)
            Else
              DisableGadget(13, #False)
            EndIf
          Case 12
            bgCol = ColorRequester(bgCol)
            SetGadgetColor(14, #PB_Gadget_BackColor, bgCol)
          Case 13
            CloseAddMonitorDialog(bgCol)
            closeWindow = #True
          Case 15
            closeWindow = #True
            
        EndSelect
      EndIf
      If closeWindow
        CloseWindow(1)
      EndIf 
    Case 2:
      closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Gadget
        closeWindow = #False
        Select EventGadget()
          Case 20
            If GetGadgetText(20) = ""
              DisableGadget(23,#True)
            Else
              DisableGadget(23,#False)
            EndIf
          Case 22
            patCol = ColorRequester(patCol)
            SetGadgetColor(24,#PB_Gadget_BackColor,patCol)
          Case 23
            pattern$ = GetGadgetText(20)
            If pattern$ <> ""
              AddPattern(currentContainerIndex, pattern$, patCol)
              UpdatePatternList(currentContainerIndex)
              SetActiveWindow(4)
              SetActiveGadget(40)
              SetGadgetItemState(40,patternCount(currentContainerIndex)-1,#PB_ListIcon_Selected)
             closeWindow = #True
            EndIf
          Case 25
            closeWindow = #True
        EndSelect    
      EndIf  
      If closeWindow
        CloseWindow(2)
        UpdatePatternButtonStates()
      EndIf 
    Case 5: ; Edit Monitor
      closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Gadget
        closeWindow = #False
        Select EventGadget()
          Case 50
            If GetGadgetText(50) = ""
              DisableGadget(53, #True)
            Else
              DisableGadget(53, #False)
            EndIf
          Case 52
            bgCol = ColorRequester(bgCol)
            SetGadgetColor(54, #PB_Gadget_BackColor, bgCol)
          Case 53
            containerName(currentContainerIndex) = GetGadgetText(50)
            bgColor(currentContainerIndex) = bgCol
            UpdateMonitorList()
            SaveSettings()
            closeWindow = #True
          Case 55
            closeWindow = #True
        EndSelect
      EndIf
      If closeWindow
        CloseWindow(5)
      EndIf 
    Case 3: ;Edit Patterns
      
      closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Gadget
        closeWindow = #False
        Select EventGadget()
          Case 30
            If GetGadgetText(30) = ""
              DisableGadget(33,#True)
            Else
              DisableGadget(33,#False)
            EndIf
          Case 32
            patCol = ColorRequester(patCol)
            SetGadgetColor(34,#PB_Gadget_BackColor,patCol)
          Case 33
            patterns(currentContainerIndex,currentPatternIndex) = GetGadgetText(30)
            patternColor(currentContainerIndex,currentPatternIndex) = patCol
            HandleInputLine(currentContainerIndex, lastMatch(currentContainerIndex))
            
            SaveSettings()
            closeWindow = #True
          Case 35
            closeWindow = #True
        EndSelect
       
      EndIf
       If  closeWindow 
          UpdatePatternList(currentContainerIndex)
          SetActiveGadget(40)
          SetGadgetItemState(40,currentPatternIndex,#PB_ListIcon_Selected)
          CloseWindow(3)
        EndIf
    Case 4: ;Patterns
      closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Gadget
        closeWindow = #False
        
        currentPatternIndex = GetGadgetState(40)
        
        Select EventGadget()
          Case 40:             UpdatePatternButtonStates()
            If EventType()= #PB_EventType_LeftDoubleClick
              If currentPatternIndex >= 0
                EditPatternDialog(currentContainerIndex,currentPatternIndex)
              EndIf
            EndIf
          Case 41 ; Add pattern
            AddPatternDialog(currentContainerIndex)
            UpdatePatternButtonStates() 
          Case 42 ; Edit selected
            If currentPatternIndex >= 0
              EditPatternDialog(currentContainerIndex,currentPatternIndex)
            EndIf
          Case 43 ; Remove selected
            If currentPatternIndex >= 0
              For p = currentPatternIndex To patternCount(currentContainerIndex)-2
                patterns(currentContainerIndex,p) = patterns(currentContainerIndex,p+1)
                patternColor(currentContainerIndex,p) = patternColor(currentContainerIndex,p+1)
              Next
              patternCount(currentContainerIndex) - 1
            EndIf
            UpdatePatternList(currentContainerIndex)
            UpdatePatternButtonStates()
          Case 44: 
            closeWindow = #True            
            
        EndSelect
      EndIf
      If  closeWindow 
        CloseWindow(4)
      EndIf
    Case 6:
     closeWindow = #False
      If Event =  #PB_Event_CloseWindow
        closeWindow = #True
      ElseIf Event = #PB_Event_Gadget
        closeWindow = #False
        Select EventGadget()
          Case 60: bgColor(currentContainerIndex) = ColorRequester(bgColor(currentContainerIndex)) : SaveSettings()
          Case 61: neutralInnerColor(currentContainerIndex) = ColorRequester(neutralInnerColor(currentContainerIndex)) : SaveSettings()
          Case 62: innerColor(currentContainerIndex) = ColorRequester(innerColor(currentContainerIndex)) : SaveSettings()
          Case 63: CreateMonitorIcon(currentContainerIndex, innerColor(currentContainerIndex), bgColor(currentContainerIndex))
          Case 64: closeWindow = #True
        EndSelect
      EndIf
      If  closeWindow 
        CloseWindow(6)
      EndIf
    Default:  
      
      If Event =  #PB_Event_ActivateWindow  
        
        ForEach logWindows()
          If logWindows()\winID = Window
                    SetWindowAndOverlayIcon(WindowID(logWindows()\winID),logWindows()\containerIndex)
            Break;
          EndIf
        Next
        
      
      
      ElseIf Event =  #PB_Event_SizeWindow Or Event =  #PB_Event_MoveWindow
        ForEach logWindows()
          If logWindows()\winID = Window
            SaveSettings()
            Break
          EndIf
        Next
      EndIf
      
  EndSelect
  
  
  For i = 0 To monitorCount-1
    CheckDockerOutput(i)
  Next
  ;RedrawTimeoutIcons() reset after timeout
  Delay(#UPDATE_INTERVAL)
Until 0
CloseWindow(0)

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  ;Free Windows Icons
  ForEach logWindows()
    If containterMetaData(index)\bigIconHandle
      DestroyIcon_(containterMetaData(index)\bigIconHandle)
    EndIf 
    If containterMetaData(index)\smallIconHandle
      DestroyIcon_(containterMetaData(index)\smallIconHandle)
    EndIf 
  Next
CompilerEndIf







; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 1424
; FirstLine = 1399
; Folding = ---------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; Executable = Docker Status.exe
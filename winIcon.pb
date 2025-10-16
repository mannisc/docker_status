
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  
  #ICON_OVERLAY_SIZE = 128

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
  Procedure.i CreateCircularHIcon(index)
    Protected hIcon.i
    Protected ii.ICONINFO
    Protected w, h
    
    ; Use the desired size
    w = #ICON_OVERLAY_SIZE
    h = #ICON_OVERLAY_SIZE
    ; Create a 32-bit RGBA image
    imgOverlay =  CreateImage(#PB_Any, w, h)
    If imgOverlay
      ; Fill fully transparent background
      StartDrawing(ImageOutput(imgOverlay))
      Box(0, 0, w, h, RGBA(0,0,0,0)) ; fully transparent; Draw filled circle in opaque color (e.g., cyan)
      Circle(w/2, h/2, w/2, bgColor(index))
      Circle(w/2, h/2, w/2- #ICON_OVERLAY_SIZE*0.1, containerStatusColor(index))
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
        FreeImage(imgOverlay)
        FreeImage(imgBG)
        ; Cleanup temporary mask
        DeleteObject_(ii\hbmMask)
      EndIf
    EndIf
    ProcedureReturn hIcon
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
Procedure SetOverlayIcon(winID,index)
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
    ; Debug "ITaskbarList3 not available, fallback to ITaskbarList"
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
    Protected Overlay = CreateCircularHIcon(index)
    
    If containterMetaData(index)\overlayIconHandle
      DestroyIcon_(containterMetaData(index)\overlayIconHandle)
    EndIf 
    containterMetaData(index)\overlayIconHandle = Overlay
    
    
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
    
    Protected Overlay = CreateCircularHIcon(index)
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
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ; Call the procedure to get the icon handles
    iconBG =  CreateImage(#PB_Any, #ICON_SIZE, #ICON_SIZE)
    If iconBG
      StartDrawing(ImageOutput(iconBG))
      Box(0, 0, #ICON_SIZE, #ICON_SIZE, bgColor(index))
      StopDrawing()
      
      ;       BigIconHandle   =  CreateHIconFromImage(iconBG) ;Taskbar icon
      ;       
      ;       If BigIconHandle 
      ;         If containterMetaData(index)\bigIconHandle
      ;           DestroyIcon_(containterMetaData(index)\bigIconHandle)
      ;         EndIf 
      ;         containterMetaData(index)\bigIconHandle = BigIconHandle
      ;         SendMessage_(WindowID(winID), #WM_SETICON, #ICON_BIG, BigIconHandle)
      ;       EndIf 
      
      If infoImageID(index)
        SendMessage_(WindowID(winID), #WM_SETICON, #ICON_SMALL, infoImageID(index))
      EndIf
    EndIf 
    SetOverlayIcon(WindowID(winID),index)
    SendMessage_(WindowID(winID), #WM_SETICON, #ICON_BIG, ExtractIcon_(GetModuleHandle_(0), ProgramFilename(), 0))
    
  CompilerEndIf
EndProcedure





CompilerEndIf







; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 2
; Folding = --
; EnableXP
; DPIAware
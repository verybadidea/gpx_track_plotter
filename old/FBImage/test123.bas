' To Do : finish editor mode
' text preservation on resize
' internal message passing
' text writing on the root image
' image stacking as addition to stretch [check ]
' image center


#include once "fbgfx.bi"
#include once "FBImage.bi"
#include once "crt/mem.bi"
#include once "crt/stdlib.bi"
#include once "crt/stdio.bi"

#define ASCII

Type Character
   Value as Integer
   FColor as Long
   BColor as Long
   PrevChar as Any Ptr
   NextChar as Any Ptr
ENd Type

Type Block
   Title as String
   X as Integer
   Y as Integer
   Wd as Integer
   Hg as Integer
   Status as Byte ' CTL/Normal/Lost/Hidden
   ID as Integer
   Ad as any ptr
End Type

Type Message
   Target as Integer ' Message is to who'm?
   Source as Integer
   ID as Integer ' Message ID
   Content as String ' parameter for ID
   Response as String ' Result
End Type

type TView
   Public:
      Declare Sub Create(ByRef X as Integer, ByRef Y as Integer, ByRef W as Integer, ByRef H as Integer, ByRef Title as String="")
      Declare Sub Redraw()
      Declare Sub Move(ByRef X as Integer, ByRef Y as Integer)
      Declare Sub Resize (ByRef W as Integer, ByRef H as Integer)
      Declare Sub Debug(ByRef SX as Integer, ByRef SY as Integer,ByRef WD as Integer,ByRef HG as Integer)
      Declare Function Hide() as Boolean
      Declare Function Show() as Boolean
      Declare Property Focus(ByRef Value as Boolean)
      Declare Property Focus() as Boolean
      Declare Property SetMode(ByRef Modus as Byte)
      Declare Property SetMode() as Byte
      Declare Function SendMessage(ByRef M as Any Ptr) as Integer
      Declare Function ImageSource(ByRef ImgSrc as Any Ptr) as Byte
      Declare Sub GReceiveKey(ByRef W as Integer)
      Declare Sub Refresh()
      Declare Property WTitle(ByRef W as String)
      Declare Property WTitle() as string
      Declare Property Decoration(ByRef W as Byte)
      Declare Property Decoration() as Byte
      Declare Sub Echo(ByRef W as Boolean)
      Declare Function Register(ByRef Value as Message Ptr) as Integer
      Declare Function UpdateTitle(ByRef NewTitle as String) as Byte
      Declare Function ReadKey(ByRef Modi as Integer=0) as Integer
      Declare Property TextColor(ByRef NewVal as ulong)
      Declare Property TextColor() as ULong
      Declare Property BackGroundColor(ByRef NewVal as ulong)
      Declare Property BackGroundColor() as ulong
      Declare Function LoadImage(ByRef File as String) as Any Ptr
      Declare Sub ResetColors()
      Declare Property ScaleMode(ByRef Waarde as Integer)
      Declare Property ControlMode(ByRef W as Boolean)
      Declare Property ControlMode() as Boolean
      Declare Sub IFU()
      Declare Sub ShowImage()
      Declare Sub GraphicsTest()
      Declare Sub GridTest()
      Declare Sub GCls()
      Declare Sub GLocate(ByRef Y as Byte, ByRef X as Byte)
      Declare Sub GPrint(Byref Value as String)
      Declare Function SetCursor(ByRef V as String="") as String
      Declare Sub SetCursorBlink(ByRef V as Single)
      Declare Sub Canvas(ByRef T as String="")
      Declare sub DebugPrint(ByVal Tekst as String)
      Declare Property CanvasHandle (ByVal N as ANY ptr)
      Declare Constructor
      Declare Destructor
      
      
   Private:
      Declare Sub DrawFrame ()
      Declare Sub StoreCanvas()
      Declare Sub RestoreCanvas()
      'Declare Sub GDisplay(ByRef W as Integer)
      Declare Sub GDisplay(ByVal W as Integer)
      Declare Sub Scroll(ByRef Delta as integer)
      Declare Function ImageResize(ByRef ImgSrc as any ptr,ByRef XFactor as Single, ByRef YFactor as Single) as Any Ptr
      Declare Function FitImage(ByRef ImgSrc as any ptr) as Any Ptr
      Declare Sub SwapChar(ByRef Dest as Integer, ByRef Source as Integer)
      Declare Sub Blink(ByRef BP as integer=0)
      Declare Function LinPos(ByRef Va as Integer,ByRef XV as Integer,ByRef YV as Integer) as Integer
      Declare Sub ResizeGrid(ByRef NX as Integer, ByRef NY as Integer,ByVal OWijd as Integer, ByVal OHoog as Integer)
      Declare Function LinPos(ByRef ox as Integer,ByRef oy as Integer, ByRef NW as Integer, ByRef NH as Integer) as Integer
      Declare Sub InsertNode(ByRef W as String)
      Declare Sub UpdateContent()
      Declare Function Parse(ByRef M as Message Ptr) as Integer
      
      RootHandle as TView PTR
      DDebug as Boolean ' Debug Visible
      Xp as Integer ' The windows X location
      Yp as Integer ' The Windows Y location
      Xr as Integer ' X location inside window
      Yr as Integer ' Y location inside window
      Naam as String ' Name of the Window
      Wijd as Integer ' width of the window
      Hoog as Integer ' hight of the window
      ScrW as Integer ' Wide of the screen in pixels
      ScrH as Integer ' hight of the screen in pixels
      Deco as Byte ' window border style
      EchoKey as Boolean ' echo recieved keys in windows (yes/no)
      ScrGraph as Boolean ' is used as graphic canvas (yes/no)
      CanvasStorePtr as FB.image PTR ' stores background before window is drawn
      Graphics as FB.Image PTR ' receives the external graphics canvas
      ImageShown as FB.Image PTR ' working copy of image to display
      TextStorePtr as Any Ptr ' pointer list for characters in windows textmode
      CTStorePtr as Character Ptr
      Resizeable as Boolean ' Can window be resized (yes/no)
      RealTime as Boolean
      WindowMode as Byte ' Type of Window
      CTLMode as Boolean ' Current state  of window
      Visible as Boolean ' visible (yes/no)
      AFocus as Boolean ' Does window have focus (yes/no)
      DFGColor as Long ' default FGColor
      DBGColor as Long ' default BGColor
      TCol as ulong ' TextColor ' 24bits
      BCol as ulong ' BackGround Color ' 24bits
      Scale as Integer ' Should received Graphic canvas be scaled
      GridStr as Character PTR
      IUP as Boolean ' Internal Update
      FU as Boolean ' Just update frame, do not overwrite content
      Cursor as String*1 ' cursor Character
      CursorStr as Any Ptr
      CursorBlink as Double ' blink interval
      LastTimer as Double ' last time blink was measured
      CursorVisible as Boolean
      CursorImg as Any Ptr
      Root as Boolean
      
      Sys as string
      Instance as Integer
End Type

Sub TView.DebugPrint (ByVal Tekst as String)
If Root and DDebug then
   this.GPrint Tekst
Else
   RootHandle->Gprint Tekst
end if
End Sub

Property TView.CanvasHandle(ByVal N as ANY Ptr)
dim as integer ti'
   if not Root then
      RootHandle = N ' This is the address of the root TView object.
   else
      puts("This property can only be used by non-canvas views")
   end if
End Property

Constructor TView()
   dim as Character Ptr Tmp = New Character
   ScreenInfo ScrW, ScrH
   If ScreenPTR <> 0 then ScrGraph = True else ScrGraph=False
   ScrW = ScrW/8
   ScrH = ScrH/8
   DFGColor=&Hc0c0c0
   DBGColor = 0
   Resizeable=True
   CanvasStorePtr = 0
   TextStorePtr = 0
   CTLMode = False
   EchoKey = True
   Xr=1
   Yr=1
   FU = False
   Visible=True
   Cursor=chr(254)
   CursorVisible=False
   CursorBlink=0.9
   CursorImg = ImageCreate(9,9)
   Tmp->Value=0
   Tmp->NextChar=0
   Tmp->PrevChar=0
   Tmp->FColor=DFGColor
   Tmp->BColor=DBGColor
   TextStorePtr = tmp
   CTStorePtr = TextStorePtr
   'MaxI = 0
   'dim as Message Ptr Msg = New Message
   #ifdef __FB_LINUX__
      Sys="Linux"
   #endif
   #ifdef  __WIN32__
      Sys="Windows"
   #endif
End Constructor

Destructor TView()
   If CanvasStorePtr <> 0 then
      Put (Xp*8,Yp*8),CanvasStorePtr
      ImageDestroy(CanvasStorePtr)
      CanvasStorePtr=0
   else
      TextStorePtr=0
   end if
   If Graphics <> 0 then
      ImageDestroy(Graphics)
   end if
   if ImageShown <> 0 then
      ImageDestroy(ImageShown)
   End if
   If GridStr <> 0 then
      'DeAllocate(GridStr)
      Free(GridStr)
   End if
   
end Destructor

Function TView.SendMessage(ByRef N as Any Ptr) as Integer'
   'Return Parse(N)
   return 0
End Function

Sub TView.InsertNode(ByRef W as String)
Dim as Character PTR Tmp = New Character
if CTStorePtr->NextChar = 0 then ' last
   CTStorePtr->NextChar = Tmp
   Tmp->PrevChar = CTStorePtr
   Tmp->Value = asc(W)
   Tmp->FColor=TCol
   Tmp->BColor=BCol
   Tmp->NextChar=0
   CTStorePtr = Tmp
else ' this is an insert
   Tmp->NextChar=CTStorePtr->NextChar
   Tmp->PrevChar=CTStorePtr
   CTStorePtr->NextChar=Tmp
end if
End Sub



Sub TView.IFU()
If FU = False then FU = True Else FU=False
End Sub

Property TView.TextColor(ByRef NewVal as ulong)
   TCol = NewVal
   Color TCol
End Property

Property TView.TextColor() as ulong
   Return TCol
End Property

Property TView.BackGroundColor(ByRef NewVal as ulong)
   BCol = NewVal
   Color TCol,BCol
End Property

Property TView.BackGroundColor() as ulong
   return BCol
End Property

Sub TView.ResetColors()
   Color DFGColor,DBGColor
End Sub


Sub TView.Canvas(ByRef T as String="")
if T="" and ImageShown = 0 then exit sub
dim as Integer IW,IH,SW,SH
ScreenInfo SW,SH
if len(T) > 1 then
   Graphics = LoadRGBAFile(T)
   if Graphics = 0 then
      exit sub
   end if
end if
If Graphics > 0 then
   ImageInfo Graphics,IW,IH
   if (IW = 0) or (IH = 0) then exit sub
End if
If (Graphics > 0) then
   root=True
   ImageShown = FitImage(Graphics)
   Put (0,0),ImageShown,PSET
   Instance=0
else
   Print string (wijd*hoog,T);
end if
End Sub

Sub TView.Debug(ByRef SX as Integer, ByRef SY as Integer,ByRef WD as Integer,ByRef HG as Integer)
if root then
   GridStr = Calloc(Wd*Hg,SizeOf(Character))
   create (SX,SY,WD,HG,"info")
   DDebug=True
end if
end sub


'Function TView.Register(ByRef value as Message Ptr) as Integer
'dim as Message Ptr Hulp = Value
'print Value->Response
'print DDebug : sleep
'MaxI+=1
'if Root then
'   Value->Response=Str(MaxI)
'   If DDebug then GPrint "Registered :"
'   Return 0
'else
'   return -2
'end if
'End Function
   


Function TView.SetCursor(ByRef V as String="") as string
   if len(V) > 0 then
      Cursor=trim(left(V,1))
   else
      Return Cursor
   End if
End Function

Function TView.ReadKey(Byref Modi as Integer=0) as Integer
   Dim as String Toets = Inkey$
   Dim as Integer OK, Value
   If Len(Toets) = 2 then
      OK = ASC(left(Toets,1))
      Value=asc(Right(Toets,1))
   end if
   if asc(Toets) = 27 then
      IF Not CTLMode then ' escape sequence
         ControlMode=True
         return 0
      else
         Return 27
      end if
   end if
   if NOT CTLMode then
      if len(Toets) = 1 then
         GReceiveKey(asc(Toets))
         Return asc(Toets)
      end if
      if len(Toets) = 2 then
         Modi = OK
         Return Value
      end if
   else
      if asc(Toets) = 13 then ' get in
         ControlMode=False
         UpdateContent()
         Return 0
      end if
      if OK = 255 then
         If MultiKey(&H1D) then
            Select Case Value
               Case 77
                  Resize(Wijd+1,Hoog)
               Case 75
                  Resize(Wijd-1,Hoog)
               Case 72
                  Resize(Wijd,Hoog-1)
               Case 80
                  Resize(Wijd,Hoog+1)
            end select
         else         
            Select Case Value
               Case 77 ' right
                  Move(Xp+1,Yp)
               Case 75 ' left
                  Move(Xp-1,Yp)
               Case 72 ' up
                  Move(Xp,Yp-1)
               Case 80 ' down
                  Move(Xp,Yp+1)
            end Select
         end if
      end if
   end if
End Function

Sub TView.Blink(ByRef BP as integer=0)
if CTLMode then exit sub
ScreenLock
if BP = 0 then    
   If (timer - LastTimer) < CursorBlink then
      ScreenUnlock
      exit sub ' change cursor every 0.5 sec
   End if
else
   CursorVisible=True ' ensure that cursor is always removed
End if
Dim as Integer GX = ((Xp-1+Xr)*8)
Dim as Integer GY = ((Yp-1+Yr)*8)
LastTimer=Timer
If Not CursorVisible then
         If ImageShown > 0 then
            Get ImageShown,(GX,GY) - STEP (8,8),CursorImg ' save current piece of background
            Draw String (GX,GY),Cursor
         else
            locate Yp+Yr,Xp+Xr : print Cursor;
         end if
         CursorVisible=True
         ScreenUnlock
         exit sub
else
   If ImageShown > 0 then
      Put (GX,GY),CursorImg,PSET
   else
      Locate Yp+Yr,Xp+Xr : print " ";
   end if
   CursorVisible=False
end if
ScreenUnlock
End Sub
         
Function TView.LinPos(ByRef ox as Integer,ByRef oy as Integer, ByRef NW as Integer, ByRef NH as Integer) as Integer
   if ox > NW then return NW
   if oy > NH then return NH
   Return (NW * (oy-1))+ox
End Function          
      
Sub TView.Scroll(ByRef Delta as Integer)
' Negative value scrolls up
' Positive value scrolls down
Dim as Integer amount = abs(Delta)
dim as Integer CWijd,CHoog
Cwijd = Wijd -2
CHoog = Hoog -2

If Delta > 0 then
   ' Scroll down
   if GridStr > 0 then
      'dim as Character Ptr NGridStore =   CAllocate ((Wijd*Hoog)+10,SizeOf(Character)) ' new grid buffer
      dim as Character Ptr NGridStore =   Calloc ((Wijd*Hoog)+10,SizeOf(Character)) ' new grid buffer
      Memcpy ( @NGridStore[0],@GridStr[CWijd],   (Cwijd*(Choog-1))*SizeOf(Character))
      'DeAllocate GridStr
      Free(GridStr)
      GridStr=NGridStore
   else
      exit sub
   end if
else
   dim as Character Ptr NGridStore =   Calloc ((Wijd*Hoog)+10,SizeOf(Character)) ' new grid buffer
   Memcpy(@NGridStore[0],@GridStr[0],(Cwijd*(Choog-1))*SizeOf(Character))
   Free(GridStr)
   GridStr = NGridStore
end if
End Sub

Sub TView.SwapChar(ByRef Dest as Integer, ByRef Source as Integer)
   'Dim as Character Tmp
   'Tmp =  GridStr [ Dest ]
   'GridStr [ Dest ] = GridStr [ Source ]
   'GridStr [ Source ] = Tmp
   swap Dest,Source
End Sub

Sub TView.ShowImage()
   screenlock
   If ImageShown <> 0 then ' ImageShown was already used.
      ImageDestroy ImageShown
   End if
   ImageShown = FitImage(Graphics)
   Put ((Xp)*8,(Yp)*8),ImageShown,PSET
   screenunlock
End Sub


Property TView.ScaleMode(ByRef Waarde as Integer)
' 0 do not scale
' 1 fit to window
' 2 fill window (stretch)
' 3 stack
' 4 center
If waarde > 4 then Scale=0 else Scale=Waarde
End Property

Function TView.FitImage(ByRef ImgSrc as any ptr) as Any Ptr
'calculate new image size
'create new image
Dim as Integer IW, IH,WSX,WSY,IO,VO,XC,YC
Dim as Single SF,SFX,SFY
Dim as Any Ptr RetImg
ImageInfo ImgSrc,IW,IH
' Get orientation of image
IO=IIF(IW>IH,1,2) ' (1) Landscape (2) Portrait
if IW=IH then IO=3 ' Square
' get orientation of target window
' ensure canvas mode works
if root then
   Screeninfo WSX,WSY
   Wijd = (WSX/8)+2
   Hoog = (WSY/8)+2
End if
VO=IIF(Wijd>Hoog,1,2) ' (1) Landscape (2) Portrait
If Wijd = Hoog then VO=3
WSX=(Wijd-2)*8
WSY=(Hoog-2)*8

select case as const Scale
   Case 0 ' no scaling
      RetImg = ImageCreate(WSX+2,WSY+2)
      GET Graphics,(0,0)-(((Wijd-2)*8),((Hoog-2)*8)),RetImg
      Return RetImg
   case 1 ' fit image to window
      if (IW < ((Wijd-2)*8)) and IH < (((Hoog-2)*8)) then ' image fits, no
         RetImg = ImageResize(ImgSrc,SF,SF)
         Return RetImg
      End if
      'If VO=1 then ' Landscape
            'If IO=2 then SF= ((Hoog-2)*8)/IH
            'If IO=1 then SF= ((Wijd-2)*8)/IW
            'SF  = IIF(IO=2,WSY/IH,WSX/IW)
      'end if
      'If VO=2 then ' Portrait
         'if IO=2 then SF = ((Hoog-2)*8)/IH
         'if IO=1 then SF = ((Wijd-2)*8)/IW
         SF  = IIF(IO=2,WSY/IH,WSX/IW)
      'end if
      If (IO=3) then
            if VO=1 then
               'SF=((Hoog-2)*8)/IH
               SF=(WSY/IH)
            else
               'SF=((Wijd-2)*8)/IW ' this also applies for squared
               SF=(WSX/IW)
            end if
      End If
      RetImg = ImageResize(ImgSrc,SF,SF)
      return RetImg

   case 2 '' stretch
      SFX = WSX/IW
      SFY=WSY/IH
      RetImg = ImageResize(ImgSrc,SFX,SFY)
      Return RetImg
   case 3 ' stack
      RetImg = ImageCreate(WSX+2,WSY+2)
      Xc =  IIF (IW > Wijd,1, Wijd \ IW)
      Yc = IIF (IH > Hoog,1,Hoog \ IH)
      for ylus as Integer = 0 to Yc+1
         for xlus as integer = 0 to Xc+2
            put RetImg,(xlus * IW,Ylus*IH),ImgSrc,PSET
         next
      Next
      return RetImg
   case 4 ' centered
      RetImg = ImageCreate(WSX+2,WSY+2)
      ' If image fits windows -> calculate middle
      ' if image > window find middle image and take centered piece
      
      
      
end select
End Function


Function TView.ImageResize(ByRef ImgPtr as any ptr,ByRef XFactor as Single, ByRef YFactor as Single) as any Ptr
dim as integer Hg, Wd
Dim as Single X,Y,exf,eyf
exf=1/XFactor
eyf=1/YFactor
ImageInfo ImgPtr, Wd, Hg
dim tmpimg as any ptr = ImageCreate((Wd * XFactor),(Hg * YFactor),0,32)
for Y = 1 to hg step eyf
        for x =1 to wd Step exf
                put TmpImg,(x / exf,y / eyf),ImgPtr,(x,y)-(x,y),pset
        next x
next y
return TmpImg
End Function

Function TView.UpdateTitle(ByRef NewTitle as String) as Byte
If len(NewTitle) > (Wijd-5) then
   return -1
else
   Naam = NewTitle
   FU = True
   DrawFrame()
   FU = False
   Return 0
end if
End Function

Property TView.Focus(ByRef Value as Boolean)
If Value and (not AFocus) then ' window did not have focus
   AFocus=True
end if
If Not Value and AFocus then
   AFocus=False
end if
If visible then
   DrawFrame
   UpdateContent
end if
End Property

Property TView.Focus() as Boolean
   Return AFocus
End Property

Property TView.WTitle(ByRef W as String)
If Len(trim(W)) < (Wijd-5) then '
   Naam = trim(W)
else
   naam = left(naam,Wijd-5)
end if
End Property

Property TView.WTitle() as String
   Return Naam
End Property




Sub TView.GReceiveKey(ByRef W as Integer)
   if W > 12 and W < 255 then
      if EchoKey then GDisplay(W)
   end if
End Sub   

Sub TView.GCls()
   ' Clear Grid
   Free(GridStr)
   GridStr=Calloc ((Wijd * Hoog)+10,SizeOf(Character))
   DrawFrame()
   Xr=1
   Yr=1
End Sub

Sub TView.GLocate(ByRef Y as Byte,ByRef X as Byte)
   Xr=x
   Yr=y
End sub


'Sub TView.GDisplay(ByRef W as Integer)
Sub TView.GDisplay(ByVal W as Integer)
	Dim as Integer CWijd, CHoog
	CWijd = Wijd-2
	CHoog = Hoog-2
	If CursorVisible then Blink(2)

	print Yr, Cwijd, Xr, ((Yr-1)*Cwijd)+Xr
	sleep
	With GridStr [ ((Yr-1)*Cwijd)+Xr   ]
		.FColor = DFGColor
		.BColor = DBGColor
		.Value = W
		.NextChar=0
		.PrevChar=0
	End With
	
	if W = 13 then 'return
		Yr+=1
		Xr=1
		W=0
	else
		If ImageShown > 0 then
			Draw  String( ((Xp-1)+Xr)*8,((Yp-1)+Yr)*8),chr(W)
		else
			Locate Yp+Yr,Xp+Xr : print chr(W);
		End If
		Xr+=1
		if  (Xr+1) > CWijd then
			Yr+=1
			Xr=1
		end if
	end if

	if Yr > Choog then
		Scroll(1)
		UpdateContent()
		if ImageShown = 0 then
			Locate Yp+(CHoog),Xp+1 : Print String (CWijd,32);
		end if
		Yr=CHoog
	end if
End Sub


Sub TView.Refresh()
if not root then
   DrawFrame()
   UpdateContent()
else
   if ImageShown <> 0 then
      Put (0,0),ImageShown,PSET
   end if
end if
End Sub

Sub TView.UpdateContent()
Dim as Character TmpChar
Dim as Integer NX,NY,CHoog,CWijd
screenlock
NX=1
NY=1
Choog=Hoog-2
CWijd=Wijd-2
Select Case as Const WindowMode
case 1,3
   If ImageShown > 0 then
      ShowImage()
   end if
   if not CTLMode then
      IUP=True
      For lus as integer = 1 to ((Yr-1)*(wijd-2))+Xr
         TmpChar=GridStr [ lus ]
         With TmpChar
            if .Value > 31 then
               Color .FColor,.BColor
               if ImageShown > 0 then
                  Draw String ((Xp-1+NX)*8,(Yp-1+NY)*8),Chr(.Value)
               else
                  GLocate cbyte(NY),cbyte(NX)
                  GPrint (chr(.Value))
               end if
               NX+=1
               if NX=(CWijd) then
                  NX=1
                  NY+=1
               end if
            end if
            if .Value = 13 then
               NY+=1
               NX=1
            end if
         End With
      Next
      IUP=False
   end if
End Select
screenunlock
End Sub
      
      

Property TView.SetMode(ByRef Modus as Byte)
' Modus = 0 -> Returns current mode
' Modus = 1 -> Grid
' Modus = 2 -> Editor
' Modus = 3 -> Graphic
Select Case as Const Modus
   Case 1
      WindowMode=1
      'GridStr=CAllocate ((Wijd * Hoog)+10,SizeOf(Character))
      GridStr=Calloc ((Wijd * Hoog)+10,SizeOf(Character))
   Case 2
      WindowMode=2
   Case 3
      'GridStr=CAllocate ((Wijd * Hoog)+10,SizeOf(Character))
      GridStr=CAlloc ((Wijd * Hoog)+10,SizeOf(Character))
      WindowMode=3
end select
End Property

Property TView.SetMode() as Byte
   Return WindowMode
End Property

Function TView.LoadImage(ByRef File as String) as Any Ptr
   If len(File)=0 then return 0
   If Graphics <> 0 then
      ImageDestroy(Graphics)
   end if
   Graphics=LoadRGBAFile(File)
   Return Graphics
End Function

Function TView.ImageSource(ByRef ImgSrc as Any Ptr) as Byte
If ImgSrc = 0 then
   Return -2 ' No Graphics Image presented
else
   Graphics = ImgSrc
   return 1
End If
End Function

Property TView.ControlMode(ByRef W as Boolean)
If W and (NOT CTLMode) then
   CTLMode=True
   Decoration=2
end if
if (Not W) and CTLMode then
   CTLMode=False
   Decoration=1
end if
End Property

Property TView.ControlMode() as Boolean
   Return CTLMode
End Property

Property TView.Decoration(ByRef W as Byte)
' Mode  = 1 (active) ' Double
' Mode  = 2 (CTL-Mode)
' Mode  = 4 Frameless
' Mode  = 5 Lost Focus
' Mode  = 6 Canvas_Message
Select Case as Const W
   Case 1
      Deco = 1
      DrawFrame()
   Case 4
      Deco=4
      Refresh()
   Case 2
      Deco = 2
      if Visible then
         FU=True
         DrawFrame()
         FU=False
      end if
   Case 6
      Deco=6
End Select
End Property

Property TView.Decoration() as Byte
   Return Deco
End Property

Function TView.Show() as boolean
if Visible then
   Return True
else
   screenlock
   StoreCanvas()
   Visible=True
   DrawFrame()
   UpdateContent()
   screenunlock
   Return True
end if
End Function

Function TView.Hide() as Boolean
If not Visible then
   Return True
else
   RestoreCanvas()
   Visible=False
   Return True
end if
End Function


Sub TView.StoreCanvas()
   Dim as Integer SX,SY,Ex,Ey
   SX = (Xp-1)*8
   SY = (Yp-1)*8
   Ex = Wijd*8
   Ey = Hoog*8
   CanvasStorePtr = ImageCreate(Ex+2,Ey+2)
   if CanvasStorePtr <> 0 then
      Get (SX,SY) - (SX+Ex,SY+Ey),CanvasStorePtr
   else
      print "couldn't create backdrop",Wijd,Hoog
   end if
End Sub

Sub TView.RestoreCanvas()   
   If CanvasStorePtr <> 0 then
      Put ((Xp-1)*8,(Yp-1)*8),CanvasStorePtr,pset
   end if
End Sub


Sub TView.Create(ByRef X as Integer, ByRef Y as Integer, ByRef W as Integer, ByRef H as Integer, ByRef Title as String="")
      screenlock()
      Xp = X
      Yp = Y
      Wijd = W
      Hoog = H
      if root then
         Deco = 6
      else
         Deco = 1
      End if
      if not root then AFocus=True
      If len(Title) > 0 then Naam=Title
      if not root then StoreCanvas()
      DrawFrame()
      screenunlock()
End Sub
         
Sub TView.Redraw()
   DrawFrame()
   UpdateContent()
End Sub

Sub TView.Move(ByRef X as Integer, ByRef Y as Integer)
   RestoreCanvas()
   If X > 0 then
      Xp = IIF((X+Wijd) <= ScrW,X,ScrW-Wijd)
   end if
   If Y > 0 then
      Yp = IIF((Y+Hoog) <= ScrH,Y,ScrH-Hoog)
   end if
   Screenlock()
   StoreCanvas()
   DrawFrame()
   if WindowMode = 3 then
      '~ Put (Xp*8,Yp*8),ImageShown,PSET ' This is faster, no calculus required
   end if
   UpdateContent()
   ScreenUnlock()
End Sub

Sub TView.ResizeGrid(ByRef NX as Integer, ByRef NY as Integer,ByVal OWijd as Integer, ByVal OHoog as Integer)'
   Dim as Integer Ylus,XLus,XT,YT,IL
   'Dim as Character Ptr NGrid = Callocate (((Wijd+2)*(Hoog+2))*SizeOf(Character))
   Dim as Character Ptr NGrid = Calloc (((Wijd+2)*(Hoog+2)),SizeOf(Character))
   OWijd = Wijd-2
   OHoog = Hoog-2
   Dim as Integer CWijd, CHoog
   CWijd = Wijd-2
   CHoog = Hoog -2
   For YT = 1 to CHoog
      For XT = 1 to Cwijd
         IL+=1
         If GridStr [ IL ].Value > 0 then 'if there is a
            NGrid [ LinPos(XT,YT,OWijd,OHoog) ] = GridStr [ IL ]
         else
            exit for
         End If
      Next
   Next
End Sub

Sub TView.GPrint(ByRef Value as String)
Dim as Integer Lus
' dirty and only usable for ASCII '
#ifdef ASCII
'~ dim as any ptr start = strptr(Value)
'~ for lus = start to start+len(Value)-1
   '~ GDisplay(cint(peek(lus)))
'~ next
'~ #else
For lus = 0 to Len(Value)-1
	print chr(Value[lus])
	'sleep
   GDisplay(Value[lus])
next
#endif
End Sub


Sub TView.Resize(ByRef W as Integer, ByRef H as Integer)
   If (W=Wijd) and (H = Hoog) then exit sub
   RestoreCanvas()
   Dim as Integer OWijd = Wijd
   Dim as Integer OHoog = Hoog
   If Wijd>3 then ' minimum size of window is 3x3
      Wijd = IIF (Xp+W < ScrW,W,ScrW-Xp)
   end if
   If Hoog>3 then ' minimum size of a window is 3x3
      Hoog = IIF(Yp+H < ScrH,H,ScrH-Yp)
   end if
   Screenlock()
   StoreCanvas()
   DrawFrame()
   'ResizeGrid(Wijd,Hoog,Owijd,OHoog)
   UpdateContent()
   Screenunlock()
End Sub


Sub TView.DrawFrame()
'Requested size is frame, content is 2 smaller
Color DFGColor
if not Visible then exit sub
ScreenLock()
Select Case Deco
Case 1
   Color &HFFFF00,DBGColor
   ' normal - active/inactive
Case 2
   Color &H00FF00,DBGColor
    ' CTL Mode
Case 4
   'Color DBGColor,DBGColor 'frameless
   screenunlock
   exit sub
case 5 ' Lost Focus / debug   
   Color DFGColor,DBGColor
   ' normal gray / black
case 6 ' debug
   color DFGColor
End Select
Select case as const Deco
    Case 1,2,3,4,5
      dim as String Res=" "
      If AFocus then
         If Resizeable then Res = chr(254) else Res=chr(188)
         if len(Naam) > 0 and (Wijd > (len(Naam)+5))then
            Locate Yp,Xp : print (chr(201)+chr(181)+trim(Naam)+chr(198)+string(Wijd - (len(Naam)+4),205)+chr(187))
         else
            Locate Yp,Xp : print(chr(201)+string(Wijd-2,205)+chr(187))
         end if
         Locate Yp + Hoog-1,Xp : print( chr(200)+string(Wijd-2,205)+Res)
         For lus as integer = 1 to Hoog -2
            if FU then
               locate Yp+lus,Xp : print( chr(186))
               Locate Yp+lus,XP+(Wijd-1) : Print( chr(186))
            else
               locate Yp+lus,Xp : print( chr(186)+string(Wijd-2,32)+chr(186))
            end if
         next
      else
         If Resizeable then Res = chr(254) else Res=chr(217)
         if Len(Naam) > 0 and (Wijd > (len(Naam)+5)) then
            Locate Yp,Xp : print chr(218)+chr(180)+trim(Naam)+chr(195)+string(Wijd - (len(Naam)+4),196)+chr(191);
         else
            Locate Yp,Xp : print(chr(218)+string(Wijd-2,196)+chr(191))
         end if
         Locate Yp + Hoog-1,Xp : print( chr(192)+string(Wijd-2,196)+Res)
         For lus as integer = 1 to Hoog -2
            if FU then
               locate Yp+lus,Xp : print( Chr(179))
               Locate Yp+lus,Xp+(wijd-1) : print( Chr(179))
            else
               locate Yp+lus,Xp : print( chr(179)+string(Wijd-2,32)+chr(179))
            end if
         next
      end if 

   case 6
      locate Yp,Xp : print chr(218)+string (wijd-2,196) +chr(191);
      for lus as integer = 1 to Hoog-2
         locate Yp+Lus,XP : print chr(179)+string(wijd-2,32)+chr(179);
      next
      locate Yp+Hoog-1,Xp : print chr(192)+string(Wijd-2,196)+chr(217);
end select
      Color DFGColor      
Screenunlock()   
End Sub

Sub TView.GridTest()
Dim as Integer KeyMode
Create(2,2,82,27,"Win")
SetMode=1
Gprint "Hello World!"
dim Toets as String = Inkey$
   While Asc(Toets) <> 27
      Blink()
      if Toets="A" then Gcls()
      GReceiveKey(asc(Toets))
      UpdateTitle("X:"+str(Xr)+",Y:"+str(Yr)+" PTR:"+str((Yr-1)*(wijd-2)+Xr))
      sleep 20
      Toets=inkey$
   Wend
End Sub

   
Sub TView.GraphicsTest()
   Dim as Integer KeyMode
   Create(2,2,82,27,"Win")
   SetMode=3
   ScaleMode=3
   'if (LoadImage("Wind.jpg") = 0) then
   if (LoadImage("tire.jpg") = 0) then
      print "Couldn't load image"
      end
   end if
   ShowImage()
   move(4,4)
   print "ddd"
   TextColor=&Hffffff
   GLocate 1,1
   Gprint "Vera"
   ResetColors()
   RootHandle->GPrint "Hello there"
   sleep
   While ReadKey(Keymode) <> 27
      Blink()
      UpdateTitle(Time)
      sleep 20
   Wend
End Sub

'' Main program
Dim as String Toets
Dim as Integer KeyMod

ScreenRes 1024,768,32
Line (10,10)-(140,30), RGB(255,255,0), bf
Draw String (16, 16), "Hello there!", RGB(255,0,0)
Dim as TView PTR CVAS = new TView
CVAS->ScaleMode=2
'CVAS->canvas("tiles.jpg")
CVAS->canvas("tire.jpg")
CVAS->debug(80,60,40,25)
dim as TView PTR App = New TView
App->CanvasHandle=@CVAS
App->GraphicsTest()
'App->GridTest()
sleep
Delete App
Delete CVAS
end


;Double clicking the trayicon: DisplayBrightness slider emerges from systray. MWolff2022
;automaticallly hiding after 3 seconds of previously hovering.
#noEnv
#notrayicon
#persistent
#SingleInstance force
setWorkingDir %a_scriptDir%
detecthiddenwindows,on
setbatchlines,-1
sendMode,Input
gosub,Varz

Moonpic:= b64_2_hBitmap(moon4864)
ico_hBmp:= b64_2_hicon(sun2464)
Sunpic:= b64_2_hBitmap(sun4864)

sl_X:= a_screenwidth-352 ; top right ;
sl_Y:= 69

menu,Tray,Icon
menu,Tray,Icon,% "HICON:*" ico_hBmp

Time:= a_tickcount+5000
Timer("Main",-90)
return,

Main:
Butt_Go()
OnMessage(0x0200,"PointerMove")
OnMessage(0x02A3,"PointerLeave")
OnMessage(0x0215,"PointerLeave") ;WM_CAPTURECHANGED
OnMessage(0x404,"AHK_NOTIFYICON")
return,

HideMe: ;slide vertically-negative back toward top oriented taskbar
if(isvisible(_surrogate_gui))
	WinAnimate(_surrogate_gui,"hide slide vneg",155)
return,

ShowMe: ;slide vertically-positive emerging from top oriented taskbar
if(!isvisible(_surrogate_gui))
	WinAnimate(_surrogate_gui,"activate slide vpos",155)
return,

PointerMove() { ;start 30 sec timeout
	setTimer,hideme,-30000
}

PointerLeave() { ;start 3 sec timeout
	settimer,hideme,-3000
}

Butt_Go() {
	global
	(!Adopted? Adopted:= True)
	gui,slider:New,-DPIScale +AlwaysOnTop +toolwindow +hWnd_surrogate_gui -Caption
	gui,slider:+LastFound -Caption ;+E0x80000
	try,curr:= DisplayBrightness_get()
	gui,slider:Add,picture,x-2 y0 h48 w48 +hWndsunhandle gSun_label vSun_var,% "HBITMAP:*" Sunpic
	sliderX:= (ParentX + 8),sliderY:= (Parenty + 48), moonY:= (slidery + SliderH)
	gui,slider:Add, Slider,Range1-96 AltSubmit NoTicks +0x8 Vertical x8 y48 Invert H%SliderH% +hWndChild_slider gChild_Slider_Label vChild_slider_var,%curr% ; ROUND(curr*0.1) ;(WS_EX_LAYERED := 0x80000),+0x30000
	gui,slider:Add,picture,x1 y190 h48 w48 +hWndMoonhandle vMoonn gMoon_label,% "HBITMAP:*" Moonpic
	GuiControl, ,slide,Buddy1Sun_var
	GuiControl, ,slide,Buddy2moon
	1stclick:= False
	gui,slider:show,na hide x300 y80 w52 h300
	VarSetCapacity(rect0,16,0xff)
	DllCall("dwmapi\DwmExtendFrameIntoClientArea","uint",_surrogate_gui,"uint",&rect0)
	winset,style,-0x110,ahk_id %child_slider%
	winset,exstyle,+0xc8,ahk_id %child_slider%
	winset,exstyle,+0xc8,ahk_id %sunhandle%
	winset,exstyle,+0xc8,ahk_id %moonhandle%
	winset,exstyle,+0xc8,ahk_id %Parent_hwnd%
	gui,slider:+LastFound -Caption %istopmost% ;+E0x80000
	winset,alwaysontop,on,ahk_id %_surrogate_gui%
	Win_Move(Child_slider,-2,48,60,SliderH-10)
	Win_Move(_surrogate_gui, sl_x, sl_y,"","")
	winset,style,-0x80000000,ahk_id %_surrogate_gui%
	winset,style,+0x40000000,ahk_id %_surrogate_gui%
	gosub,ShowMe
	return,
}

Sun_label:
Moon_label:
switch,a_thislabel {
	case,"Sun_var" : New_val:= 100
	case,"moonn"   : New_val:= 0.1
} guiControl,,child_slider_var,% New_val
gui,slider:submit,nohide
return,

SliderEvent: ; slider changes come here
GuiControlGet,child_slider_var ; get new value for Slider
return,

Child_Slider_Label:
((child_slider_var < 10)? child_slider_var *= 10)
(!slideold?	slideold:= child_slider_var)
if((child_slider_var>(slideold+4))||(child_slider_var<(slideold-4))) {
	DisplayBrightness_set(child_slider_var)
} else {
	DisplayBrightness_get()
	return,
} try,((curr:= DisplayBrightness_get())? (curr && !(curr=child_slider_var)? timer("Child_Slider_Label",-1)))
if(!curr) {
	gosub,tt0ff
	goto,Child_Slider_Label
} if !(curr=child_slider_var) {
	DisplayBrightness_set(child_slider_var)
	settimer,Child_Slider_Label,-50
} else {
	slideold:= child_slider_var
	settimer,ToolOff,-1000
	settimer,ttdone,-1200
} return,
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------

!#lbutton:: ;force adoption of slider;not used
if winexist("ahk_class #32768")
	winclose, ;tt("menu control-adoption is not-yet functional")
Coord_get:
CoordMode,mouse,Window  ;	ToolTip|Pixel|Mouse|Caret|Menu / Screen|Window|Client
mousegetpos,ParentX,ParentY,Parent_hwnd,Parent_cWnd
if !Adopted {
	controlget,parent_control_handle,hWnd,,%Parent_cWnd%,ahk_id %Parent_hwnd%
if parent_control_handle {
	Adopted:= True
	settimer, Butt_Go, -200
} } else {
	adopt()
	gui,slider: destroy
	Adopted:= False	;else, msgbox,% "error"
} return,

adopt() {
	global
	DllCall("SetParent","uint",child_slider,"uint",_surrogate_gui)
	DllCall("SetParent","uint",sunhandle,"uint",_surrogate_gui)
	DllCall("SetParent","uint",moonhandle,"uint",_surrogate_gui)
}

ToolOff:
toolTip,
return,

ttdone:
return,

ChildWindowFromPoint(hWnd,x,y) {
 return,Format("{:#x}",DllCall("ChildWindowFromPoint","int",hWnd,"int",x,"int",y))
}

IsVisible(hWnd) {
	return,DllCall("IsWindowVisible","Ptr",hWnd)
}

AHK_NOTIFYICON(wParam, lParam) { ; 0x201: ; WM_LButtonDOWN   ; 0x202:; WM_LButtonUP
	listlines,off
	Switch,lParam {
		case,0x203: if(!IsVisible(_surrogate_gui)) {
				winget,id,id,ahk_class NotifyIconOverflowWindow
			if(IsVisible(id))
				winclose,ahk_id %id%
			setTimer,ShowMe,-10
			setTimer,hideme,-30000
			return,1
			}		; case,0x205:  ;	;return,(trayActiv?MENSpunction())	WM_RBUTTONUP ; menuTrayUndermouse() experimental fail
	} ;exit,
} ;TRAY WM_;^^^^^;

Open_ScriptDir:
toolTip %a_scriptFullPath%
z=explorer.exe /select,%a_scriptFullPath%
run,%comspec% /C %z%,, hide

tt0ff:
tt0n:= false
return,

varz:
global Parent_hWnd, exStyles, _surrogate_gui, child_slider_var, HPMON, HMON, curr, slideold, dbgtt, tt0n, STARTPOS, sun, Sun_var, sunhandle, moon, moonn, moonhandle, adopted, ParentX, ParentY, moonY, SliderH, sl_x, sl_y
, sun:= "sun_48_3.png", moon:= "Moon_48.png", moon2:= "MOONCHEESE2.png", dbgtt:= True ;| (ws_ex_trans:= 0x20) ; | (WS_EX_LAYERED := 0x80000)  ;| (WS_EX_COMPOSITED := 0x02000000) |
; global time
, SliderH:= 144, ParentX:= 3575, ParentY:= 865, istopmost:= "+alwaysontop",sun2464,sun4864,moon4864
, sun2464:="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"
sun4864:="iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAADAFBMVEVZP1xcQV9dQWBfQ2JhRGRiRWZkRmdlR2lmSGpoSWtoSmxpSm1qS21rS25rS25rTG9tTXBsTG9tTnBsTHBtTXBsTG9sTXBrS25rTG5pSm1rTW5nSWtoS2xlR2hmSWliRWViR2VfRGJgR2NaP1xcRF5XPllZQ1tQOFJZSXZcV6VlY8trb+pucvZtcfxucf5tcP9tcv9wdf9zev91fP96gf99g/9+i/9/jP+Cmv97j/95if90iv91jf9zjf9xjf9skP9mjf9hj/9ckP9ck/9Xlv9VmP9Smv9ToP9jo/9Xpf9cp/9Rqv9Lr/9Fu/9XwP9Vy/9N0P9G0P9T0/9O1f9i2f9M2v9F3P883f814P8m6v8c7v8j8/8a9v8d/P47/f4+/f1T/f1W/fxc//lk//hn//dy/vqC/fuM+f2Q+v6V8v6c7P+g5f+g3/+f2/+o1P+gzP+jyP+pyv+pyP+rwf+twP+wu/+yuf+3s/+ytP+zrP+xqv+wp/+spP+toP+hmP+jlf+cif+Ug/+Ld/+Eav+LdP+Nd/+Rff+XhP+Zhf+ajP+eh/+ghv+jif+kgv+ng/+qgf+sgP+rgf+vg/+xhf+yif+yj/+yjv+zjv+2jP+1h/+2i/+3jf+6kf+4kv+/j//BjP/Fj//GkP/Ek//HmP/Fn//HpP/Hp//Hqf/Iq//Iq//Gq//Kq//Nq//Pqf/TqP/Upv/Vo//Wpf/Wpf/Xp//Xp//Zpv/apf/cpP/cof/eov/eov/go//gpP/hpf/hpv/iqP/hpv7hqP7fpv3gp/7covzepf7aoPnep/zZn/fhqvzbofXlrfvVm+zmsvnTnObmuPXFj9bmvfPClNHlxe+jda/lyu2wirrmz+2bcqTo0e2mhq3p1u2GYI3q2u2dg6Ls2+98XYDt4u+OfpHu6O9IMkrv7e98eXzx8PE8OzwAAAD9/f19fX37+/s9PT35+fl7e3v39/ccHBz19fV4eHjz8/Na/fsj/f4S+v8p5f9Tx/9mx/9fwv9Gvf9Bvf9CuP9btv+93thQAAAA6nRSTlMEAwMDAwICAgICAgICAQEBAQEBAQEBAQEBAQEBAAEBAQEBAQEBAQEBF0t9s8jV2Nrd3uHe3tve3+bo7PHz+Pz9/f7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v7+/v79/fr49/Hy6OPh28y5rqOajJCPlJukpKapqqqnopyWj46Kh4R+d3JuamxsbW5sZ2FbUkpFQ0ZJT1JWW2VscHNxcGtjXlVOTEdCQD45ODIsJyQiISAfHBsYFxcWFRITEhEPDw0PCw4LCwoICAIBAgIDAgMDAwQEBAUFBgoWWYDP7ACLsJ38AAACJ0lEQVQozz1Sy04aYRSeB/EZiiGQUgw3awAFbQhEEWwhFBDUUpFEpC0EnLTQhhpoJFwnYKVJNWIRXFApARugTMiszGQWs/jfYgAbsDMiPYuzOF/Oyfku0NS4SBSQ1zUAUPAwgJhGkDh2Ue+Uzzv1IoaTxATAsSraPDtDTr4jhW+/0WoXHwM4jp0XkFO3x+1+4z7J/Dju4jgDEFi3fen27DodDseOy+3xltoYRtAAWS2U43vOrY0Nu33r9bbLG788qpDMBlrw7jk37TabxajX3Mp57/zHf+gNEmsinp3NdavNZjX2VjV3osdvM00MQGgxf7r7at1osVotJkq/vCSf8ecTuRYE6nmfS6N/YbGYzWbDWn+wIOYGErUbiOwgH7c1espkZoBef6CQcD6lWwC6voj5eLerPQM9f0mtaQfKWbb/sNiAfuUOfLy/y3rKYDIZnq+qhwoJ23+Qu4IAfYp390yr61FUT6dVjWRiTgihT4F6av+JfEm10tfp+iuqoXJOyIITdfrd7JdYQLCwOFCp1arBolIq4gdikSz9Lk0wzBHNK0fD4XCkkIoEj8LpBk1wCkdzcJArfiqbV8ikcyIBNwh/Re9FvEqWosHpGbFkViIU8lnBaDk5FpGRHQ7vT7P5fA4rEIZLze697IxRqWQmDoc+vA/Bh+mj5INRjLUVtJmMpiOfkUSkgVYm1jJhILBsrZ1NtetZjCDJ/ymhC7RuQOMnAK1JfP4BjqQqa7QkgREAAAAASUVORK5CYII"
moon4864:="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"
return,
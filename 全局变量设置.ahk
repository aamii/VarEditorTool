; 请修改everything所在路径
; 请修改ini路径及段名
; ========ev的用法采自 @nepter ==Everything通信的范例by2011年,具体可参考官方SDK=================
	EVDLL:=A_PtrSize=4 ? "Everything32.dll":"Everything64.dll"
	DllCall("LoadLibrary", "Str", "Z:\kini\file\search\Everything\" EVDLL, "Ptr")
	gini_GeneralSettings     := "z:\hoe\ini\GeneralSettings.ini"
	if winexist("全局变量编辑-UCC")
		return
	Gui VSS: Font, s10 微软雅黑 c62384C q2
	Gui VSS: Margin,0,0
	Gui VSS: Add, ListView, vVooVSSLV gGooVSSLV  x5  w700 h410 AltSubmit Grid , 别名|路径
	Gui VSS: Add, text,x2 y+5 w50 ,过滤：
	Gui VSS: Add, Edit,x+8 w530 vInput g过滤选择,
	Gui VSS: Add, Checkbox,x+5 v有效选择 g过滤选择 Checked section,有效
	Gui VSS: Add, Checkbox,x+5 v无效选择 g过滤选择 Checked,无效
	Gui VSS: Add, text,x2 y+13 w50 ,别名：
	Gui VSS: Add, Edit,x+8 vVooVSSEdit别名 w640
	Gui VSS: Add, text,x2 w50 ,路径：
	Gui VSS: Add, Edit,x+8 vVooVSSEdit程序 w640
	Gui VSS: Add, button,x2 w100 gGooVSSFileSelect ,浏览...
	Gui VSS: Add, button,x+20 w100 gGooVSSSearch ,全盘搜索
	Gui VSS: Add, button,x+20 w100 gGooVSSOK ,确认修改
	Gui VSS: Add, ListBox,x2 r10 vVooVSSListBox程序 gGooVSSListBox程序 w700
	Gui VSS: Default
	DrawMenu_VSS()
	gosub 过滤选择
	Gui VSS:Show,,全局变量编辑-UCC
	return

VSSGuiClose:
VSSGuiEscape:
	Gui VSS: destroy
	ExitApp
	return

GooVSSLV:
	if A_GuiEvent = DoubleClick
	{
		LV_GetText(别名, A_EventInfo, 1) ; 从首个字段中获取文本.
		LV_GetText(路径, A_EventInfo, 2)  ; 从第二个字段中获取文本.
		GuiControl VSS: text,VooVSSEdit别名,%别名%
		GuiControl VSS: text,VooVSSEdit程序,%路径%
		GuiControl VSS:, VooVSSListBox程序,|
	}
	return

GooVSSFileSelect:
	FileSelectFile, SelectedFile, 3, , Open a file, Text Documents (*.txt; *.doc)
	if SelectedFile =
		return
	else
		GuiControl VSS: text,VooVSSEdit程序,%SelectedFile%
	return

GooVSSSearch:
	Gui VSS: submit ,nohide
	thispath:=""
	String:=RegExReplace(VooVSSEdit程序, ".*\\(.*)$", "$1")
	if string=""
		return
	DllCall(EVDLL . "\Everything_SetSearch", "Str",String)
	DllCall(EVDLL . "\Everything_Query", "Int", True)
	Loop % DllCall(EVDLL . "\Everything_GetNumResults", "UInt")
	{
		LoopPath:=DllCall(EVDLL . "\Everything_GetResultPath", "UInt", A_Index - 1, "Str") "\" DllCall(EVDLL . "\Everything_GetResultFileName", "UInt", A_Index - 1, "Str")
		if regexmatch(looppath, "i)\\" String "$")
			ThisPath .= "|" LoopPath
	}
	GuiControl VSS:, VooVSSListBox程序,%ThisPath%
	return
GooVSSListBox程序:
	if A_GuiEvent = DoubleClick
	{
		Gui VSS: submit ,nohide
		选中的路径:=VooVSSListBox程序
		GuiControl VSS: text,VooVSSEdit程序,%选中的路径%
	}
	return

过滤选择:
	Gui vss: submit ,NoHide
	过滤条件:=有效选择 无效选择
	GuiControl, -ReDraw, Output
	GuiControlGet, Input
	LV_Delete()
	IniRead,var_GeneralVars,%gini_GeneralSettings%,UserEnvironmentVariables
	loop,parse,% var_GeneralVars,`n
	{
		if(input<>"" and not instr(A_LoopField,input))
			continue
		gvar_Key:=RegExReplace(A_LoopField,"=.*?$")  	 	;用户自定义变量的key
		gvar_Val:=RegExReplace(A_LoopField,"^.*?=") 		;用户自定义变量的value
		if(过滤条件=11)
		{
			LV_Add("",gvar_Key,gvar_Val)
		}
		else if(过滤条件=10)
		{
			if fileexist(gvar_Val)
				LV_Add("",gvar_Key,gvar_Val)
		}
		else  if(过滤条件=01)
		{
			if !fileexist(gvar_Val)
				LV_Add("",gvar_Key,gvar_Val)
		}
	}
	LV_ModifyCol(1,100)
	GuiControl, +ReDraw, Output
	return

GooVSSOK:
	Gui VSS: submit ,nohide
	if (VooVSSEdit程序 && VooVSSEdit程序)
		IniWrite, %VooVSSEdit程序%,%gini_GeneralSettings%,UserEnvironmentVariables,%VooVSSEdit别名%
	gosub 过滤选择
	return
DrawMenu_VSS()
{
	Menu,VSSMenu_Lv,Add,删除记录,VSSMenuHandle_LV删除条目
	return
}
VSSGuiContextMenu:
	if (A_GuiControl = "VooVSSLV")
		Menu, VSSMenu_Lv, Show
	return

VSSMenuHandle_LV删除条目:
	Gui VSS: Default
	RowNumber = 0
	Loop
	{
		RowNumber := LV_GetNext(RowNumber)
		if not RowNumber
			break
		LV_GetText(别名, RowNumber)
		MsgBox, 4116,,确认删除这条定义，删除后不可恢复！
		IfMsgBox Yes
		{
			LV_Delete(RowNumber)
			IniDelete ,%gini_GeneralSettings%,UserEnvironmentVariables,%别名%
		}
	}
	return

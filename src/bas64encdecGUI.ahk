/*
	Base64 Encoder/Decoder GUI (WIP)
	By d4n / Dan3436
	
	To do:
	-Progress bar (?)
	-Script simplify & cleanup -
	-Real time string encode / decode ✔
	-Unify Encode and Decode GUIs ✔
*/

SetBatchLines -1 ;Run the script at maximum speed
SetControlDelay -1 ;No delay after control change
Process, Priority,, H
#NoEnv
#SingleInstance Force
#NoTrayIcon
;#Warn

Gui -MinimizeBox
Gui Add, Text, x20 y10 w160 h30 Center, Select the options from the boxes and click the button
Gui Add, Button, vButtonText gEncodeDecodeGUI x18 y46 w164 h44 Default, Encode a string
Gui Add, GroupBox, x25 y100 w150 h45, Action
Gui Add, Radio, vEncode gEncode x36 y119 w54 h17 Checked, Encode
Gui Add, Radio, vDecode gDecode x104 y119 w58 h17, Decode
Gui Add, GroupBox, x25 y155 w150 h45, Type
Gui Add, Radio, vText gText x36 y174 w50 h17 Checked, String
Gui Add, Radio, vFile gFile x104 y174 w44 h17, File
Gui -E0x10
Gui Show, w200 h215, Base64 Encoder/Decoder
Return

Encode:
Decode:
File:
Text:
Gui Submit, NoHide
GuiControl,, ButtonText, % (Encode?"Encode":"Decode") " a " (File?"file":"string")
Return

EncodeDecodeGUI:
Gui Submit
Gui New, % Text?"-MaximizeBox":"-MinimizeBox", % "Base64 " (File?"File ":"Text ") . (Encode?"Encoder":"Decoder")
Gui Color, White
Gui Add, Text, % "x24 y6 w202 h26 Center " (!(File && Encode)?"0x200":""), % (File && Encode)?"Click the button to select the file. Encoded file will appear here":"Enter the " (File?"file":"Base64 string") " to " (Encode?"encode":"decode") " here"
Gui Add, Edit, vInput gTextChange x24 y37 w202 h178, % (File && Encode)?"Note: You can also drag and drop the file here.": ""
if !(Decode && File)
	Gui Add, CheckBox, % "vCopyToClipboard " (File?"x42":"x253") " y220 w166 h26", % "Copy the " (Encode?"encoded ":"decoded ") (File?"file":"string") " to the clipboard"
if !(Encode && File)
	Gui Add, CheckBox, vLoadString x42 y220 w166 h26, % "Load the string to " (Encode?"encode":"decode") " from a text file"
Gui Add, Text, % "x0 " (File?"y250 w251":"y286 w463") " h46 -Background"
Gui Add, Button, % "gEncodeDecode " (File?"x85 y262":"x191 y298") " w80 h23 Default", % Encode?(File?"Select a file":"Encode"):(File?"Save the file":"Decode")
if Text
{
	Gui Add, Edit, vOutput x237 y37 w202 h178 ReadOnly
	Gui Add, Text, x257 y13 w151 h17, % (Encode?"Encoded":"Decoded") " string will appear here"
	Gui Add, CheckBox, vLiveModeOn gLiveMode x150 y259 w162 h18, % "Live Mode (Real-time " (Encode?"encode":"decode") ")"
}
if (File && Encode)
	Gui +E0x10
Gui Show, % File?"w251 h296":"w463 h332"
Return

LiveMode: ;Only for strings
Gui Submit, NoHide
GuiControl Disable%LiveModeOn%, CopyToClipboard
GuiControl Disable%LiveModeOn%, LoadString
GuiControl Disable%LiveModeOn%, % Encode?"Encode":"Decode"
GuiControl,, Input
GuiControl,, Output
Return

TextChange:
Gui Submit, NoHide
if LiveModeOn
{
	if (Decode && !IsBase64(Input))
		GuiControl,, Output, Invalid Base64 string.
	else
		GuiControl,, Output, % Encode?Base64Encode(Input):Base64Decode(Input)
}
Return

GuiDropFiles:
if (File && Encode) ;Only for encoding files
{	
	IsDragAndDrop := 1
	Loop, Parse, A_GuiEvent, `n
	{
		FileToEncode := A_LoopField
		break
	}
	Goto EncodeDecode
}
Return

EncodeDecode:
Gui +OwnDialogs
Gui Submit, NoHide
if LoadString ;Load a string from a text file
{
	FileSelectFile TextWithString, 3,, Select the text file that contains the string, Text Files (*.txt)
	if ErrorLevel
		Return
	FileRead Input, % TextWithString
	;EncodeInput := FileOpen(TextWithString, "r").Read()
	if ErrorLevel
	{
		MsgBox 16, % Encode?"Base64 Encoder":"Base64 Decoder", there was a problem while reading the text.
		Return
	}
	ToolTip Loading the string...
	GuiControl,, Input, % Input
	ToolTip
}
if (File && Encode)
{
	if !IsDragAndDrop
	{
		FileSelectFile FileToEncode, 3,, Select the file to encode
		if ErrorLevel
			Return
	}
	IsDragAndDrop := 0
	OpenFile := FileOpen(FileToEncode, "r")
	Length := OpenFile.Length
	OpenFile.RawRead(Input, Length)
	;FileGetSize Length, % FileToEncode ;Get file size
	;FileRead Input, *c %FileToEncode%
}
if Decode
{
	if File
	{
		if (Input ~= "[^\w+/=]") 
		{
			MsgBox 16, Base64 Decoder, The string contains invalid characters.
			Return
		}
		FileSelectFile DecodedFile, S8,, Save As
		if ErrorLevel
			Return
		ToolTip Decoding the file... Please wait
		SaveFile := FileOpen(DecodedFile, "w") ;Overwrites any existing file
		SaveFile.RawWrite(Data, Base64Decode(Input, Data))
		SaveFile.Close()
		ToolTip
		FileGetSize Length, DecodedFile
		if (Length = 0)
		{
			FileDelete % DecodedFile
			MsgBox 16, Base64 Decoder, There was an error while decoding the file.
		}
		else
		{
			MsgBox 68, Base64 Decoder, File decoded and saved.`nOpen the file in Windows Explorer?
			IfMsgBox Yes
				Run % "explorer.exe /select`, " . DecodedFile
		}
		Return
	}
	if !IsBase64(Input)
	{
		GuiControl,, Output, Invalid Base64 string.
		Return
	}
}

;Encode/Decode text & Encode file
ToolTip % (Encode?"Encoding":"Decoding") " the " (File?"file":"string") "..."
Result := Encode?Base64Encode(File ? Base64 : Input, File ? Input : "", File ? Length : ""):Base64Decode(Input)
GuiControl,, % File?"Input":"Output", % Result
ToolTip
if CopyToClipboard
{
	if (Output <> "" || Output <> "Invalid Base64 string.")
	{
		Clipboard := Result
		ClipWait
		MsgBox 64, % Encode?"Base64 Encoder":"Base64 Decoder", % (Encode?"Encoded ":"Decoded ") (File?"file":"string") " copied to the clipboard."
		Return
	}
}
Return

GuiEscape:
GuiClose:
if A_Gui <> 1 ;If the script isn't in the Main GUI, reload when user closes or press Escape button, so it can show the Main GUI rather than exiting the script.
	Reload
ExitApp

;==================================================
;Base64 Encode and Decode functions

;Source:
;https://github.com/ahkscript/libcrypt.ahk/blob/master/build/libcrypt.ahk
;https://github.com/ahkscript/libcrypt.ahk/blob/master/src/Base64.ahk

;CRYPT_STRING_BASE64 = 0x00000001
;CRYPT_STRING_NOCRLF = 0x40000000

Base64Encode(Out, ByRef In := "", InLen := "")
{
	if !(In && InLen) ;Assume that is text
	{
		VarSetCapacity(In, StrPut(Out, "UTF-8"))
		InLen := StrPut(Out, &In, "UTF-8") - 1
	}
	DllCall("Crypt32\CryptBinaryToString", "Ptr", &In, "UInt", InLen, "UInt", 0x40000001, "Ptr", 0, "UInt*", OutLen)
	VarSetCapacity(Out, OutLen * (1 + A_IsUnicode))
	DllCall("Crypt32\CryptBinaryToString", "Ptr", &In, "UInt", InLen, "UInt", 0x40000001, "Str", Out, "UInt*", OutLen)
	Return Out
}

Base64Decode(In, ByRef Out := "")
{
	global Text
	DllCall("Crypt32\CryptStringToBinary", "Ptr", &In, "UInt", StrLen(In), "UInt", 0x1, "Ptr", 0, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(Out, OutLen)
	DllCall("Crypt32\CryptStringToBinary", "Ptr", &In, "UInt", StrLen(In), "UInt", 0x1, "Str", Out, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	Return Text ? StrGet(&Out, OutLen, "UTF-8") : OutLen
}

IsBase64(Base64String)
{
	;if the reencoded string isn't equal to input, return false.
	if (Base64Encode(Base64Decode(Base64String)) <> Base64String)
		Return False
	else
		Return True
}

;==================================================

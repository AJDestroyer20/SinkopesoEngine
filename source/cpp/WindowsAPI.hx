package cpp;

#if (windows && cpp)
@:cppFileCode('
#include <windows.h>
#include <iostream>

void showMessageBox(const char* title, const char* message, int icon) {
	MessageBoxA(NULL, message, title, icon | MB_OK);
}
')
#end

class WindowsAPI
{
	#if (windows && cpp)
	@:functionCode('
		showMessageBox(title, message, icon);
	')
	#end
	public static function showMessageBox(title:String, message:String, icon:Int = 0):Void
	{
		#if (windows && cpp)
		#else
		trace('MessageBox: $title - $message');
		#end
	}
}

@:enum abstract MessageBoxIcon(Int) from Int to Int
{
	var INFO = 0x00000040;
	var WARNING = 0x00000030;
	var ERROR = 0x00000010;
}

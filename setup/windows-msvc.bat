@echo off
cd ..
@echo on
echo Installing Microsoft Visual Studio Community (Dependency)
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
del vs_Community.exe

echo Installing scripting and engine libraries
haxelib install flixel
haxelib install flixel-addons
haxelib install grig.audio
haxelib install tink_core
haxelib install tjson
haxelib install hscript
haxelib install hscript-iris
haxelib install hxvlc
haxelib install linc_luajit
haxelib install discord_rpc
haxelib install away3d 5.0.9

echo Finished.
pause

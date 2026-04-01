@echo off
title Setup
color 02
echo Setup
echo Installing libraries
echo.
haxelib newrepo
echo.
haxelib install flixel 5.6.1
haxelib install flixel-addons 3.2.2
haxelib install flixel-tools 1.5.1
haxelib install flixel-ui
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install actuate
haxelib install polymod
haxelib install tjson 1.4.0
haxelib install hxvlc 2.0.1
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxcpp-debug-server 1.2.4
haxelib install grig.audio 0.0.5
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib dev hscript-iris .haxelib/hscript-iris/git
haxelib dev linc_luajit .haxelib/linc_luajit/git

echo.
echo Libraries installed correctly
echo.

choice /c YN /m "Do you want to compile?"

if errorlevel 2 goto end
if errorlevel 1 call compile.bat

:end
pause
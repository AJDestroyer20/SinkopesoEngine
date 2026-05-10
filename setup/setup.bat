@echo off
title Setup

echo ===============================================
echo Setup
echo ===============================================

cd ..
haxelib newrepo

:: Core libraries
haxelib install flixel
haxelib install flixel-addons
haxelib install grig.audio
haxelib install tink_core
haxelib install tjson
haxelib install hscript
haxelib install hscript-iris

:: Optional desktop libraries (install anyway)
haxelib install hxvlc
haxelib install linc_luajit
haxelib install discord_rpc
haxelib install away3d 5.0.9

echo ===============================================
echo All installations attempted.
pause
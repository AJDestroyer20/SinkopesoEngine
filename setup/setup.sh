#!/bin/bash

set -e

echo "==============================================="
echo "Setup"
echo "==============================================="

cd ..
haxelib newrepo || true

haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel 5.6.1
haxelib install flixel-addons 3.2.2
haxelib install flixel-tools 1.5.1
haxelib install tjson 1.4.0
haxelib install hxvlc 2.0.1
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxcpp-debug-server 1.2.4
haxelib install hscript
haxelib install hscript-iris
haxelib install grig.audio
haxelib install tink_core
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90

echo "==============================================="
echo "All installations attempted."

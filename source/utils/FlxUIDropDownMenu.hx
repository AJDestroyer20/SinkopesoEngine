package utils;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIButton;

class FlxUIDropDownMenu extends FlxUIGroup
{
	public var list:Array<String> = [];
	public var selectedLabel:String = "";
	public var selectedIndex:Int = 0;
	
	private var button:FlxUIButton;
	private var dropPanel:FlxUI9SliceSprite;
	private var itemButtons:Array<FlxUIButton> = [];
	
	private var isOpen:Bool = false;
	
	public var callback:String->Void;
	
	public function new(x:Float, y:Float, dataList:Array<String>, ?callback:String->Void)
	{
		super();
		
		this.x = x;
		this.y = y;
		this.list = dataList;
		this.callback = callback;
		
		if (list.length > 0)
			selectedLabel = list[0];
		
		button = new FlxUIButton(0, 0, selectedLabel, clickDropButton);
		add(button);
		
		dropPanel = new FlxUI9SliceSprite(0, button.height, null, new FlxRect(0, 0, 100, 100), [4, 4, 4, 4]);
		dropPanel.resize(100, list.length * 20);
		dropPanel.visible = false;
		add(dropPanel);
		
		for (i in 0...list.length)
		{
			var itemButton:FlxUIButton = new FlxUIButton(0, button.height + (i * 20), list[i], function()
			{
				selectItem(i);
			});
			itemButton.visible = false;
			add(itemButton);
			itemButtons.push(itemButton);
		}
	}
	
	private function clickDropButton():Void
	{
		isOpen = !isOpen;
		dropPanel.visible = isOpen;
		
		for (btn in itemButtons)
		{
			btn.visible = isOpen;
		}
	}
	
	private function selectItem(index:Int):Void
	{
		selectedIndex = index;
		selectedLabel = list[index];
		button.label.text = selectedLabel;
		
		isOpen = false;
		dropPanel.visible = false;
		
		for (btn in itemButtons)
		{
			btn.visible = false;
		}
		
		if (callback != null)
			callback(selectedLabel);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

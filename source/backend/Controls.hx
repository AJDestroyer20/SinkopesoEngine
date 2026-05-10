package backend;

import flixel.input.keyboard.FlxKey;

class Controls
{
	public static var instance:Controls;

	public var LEFT_P:Bool = false;
	public var DOWN_P:Bool = false;
	public var UP_P:Bool = false;
	public var RIGHT_P:Bool = false;

	public var LEFT_R:Bool = false;
	public var DOWN_R:Bool = false;
	public var UP_R:Bool = false;
	public var RIGHT_R:Bool = false;

	public var LEFT:Bool = false;
	public var DOWN:Bool = false;
	public var UP:Bool = false;
	public var RIGHT:Bool = false;

	public var ACCEPT:Bool = false;
	public var BACK:Bool = false;
	public var PAUSE:Bool = false;
	public var RESET:Bool = false;

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	
	public function new()
	{
		keyboardBinds = [
			'note_left' => [A, LEFT],
			'note_down' => [S, DOWN],
			'note_up' => [W, UP],
			'note_right' => [D, RIGHT],
			'ui_left' => [A, LEFT],
			'ui_down' => [S, DOWN],
			'ui_up' => [W, UP],
			'ui_right' => [D, RIGHT],
			'accept' => [SPACE, ENTER],
			'back' => [BACKSPACE, ESCAPE],
			'pause' => [ENTER, ESCAPE],
			'reset' => [R]
		];
	}

	public function update():Void
	{
		LEFT_P = checkKeys('note_left', JUST_PRESSED);
		DOWN_P = checkKeys('note_down', JUST_PRESSED);
		UP_P = checkKeys('note_up', JUST_PRESSED);
		RIGHT_P = checkKeys('note_right', JUST_PRESSED);

		LEFT_R = checkKeys('note_left', JUST_RELEASED);
		DOWN_R = checkKeys('note_down', JUST_RELEASED);
		UP_R = checkKeys('note_up', JUST_RELEASED);
		RIGHT_R = checkKeys('note_right', JUST_RELEASED);

		LEFT = checkKeys('note_left', PRESSED);
		DOWN = checkKeys('note_down', PRESSED);
		UP = checkKeys('note_up', PRESSED);
		RIGHT = checkKeys('note_right', PRESSED);

		ACCEPT = checkKeys('accept', JUST_PRESSED);
		BACK = checkKeys('back', JUST_PRESSED);
		PAUSE = checkKeys('pause', JUST_PRESSED);
		RESET = checkKeys('reset', JUST_PRESSED);
	}

	private function checkKeys(action:String, state:KeyState):Bool
	{
		var keys = keyboardBinds.get(action);
		if (keys == null) return false;

		for (key in keys)
		{
			switch (state)
			{
				case PRESSED:
					if (FlxG.keys.checkStatus(key, PRESSED)) return true;
				case JUST_PRESSED:
					if (FlxG.keys.checkStatus(key, JUST_PRESSED)) return true;
				case JUST_RELEASED:
					if (FlxG.keys.checkStatus(key, JUST_RELEASED)) return true;
			}
		}

		return false;
	}

	public function getKeyArray(action:String):Array<Bool>
	{
		return switch (action)
		{
			case 'note_left': [LEFT_P];
			case 'note_down': [DOWN_P];
			case 'note_up': [UP_P];
			case 'note_right': [RIGHT_P];
			default: [false];
		}
	}

	public static function init():Void
	{
		if (instance == null)
			instance = new Controls();
	}
}

enum KeyState
{
	PRESSED;
	JUST_PRESSED;
	JUST_RELEASED;
}

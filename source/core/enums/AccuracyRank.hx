package core.enums;

enum abstract AccuracyRank(String)
{
	var F = "F";
	var D = "D";
	var C = "C";
	var B = "B";
	var A = "A";
	var A_PLUS = "A+";

	public static function fromAccuracy(acc:Float):AccuracyRank
	{
		if (acc >= 98) return A_PLUS;
		if (acc >= 90) return A;
		if (acc >= 80) return B;
		if (acc >= 70) return C;
		if (acc >= 60) return D;
		return F;
	}
}

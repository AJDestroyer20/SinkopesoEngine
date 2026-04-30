package gameplay.chart.adapters;
import gameplay.chart.InternalChart;

class KadeChartAdapter
{
	public static function adapt(raw:Dynamic):InternalChart
	{
		return {
			song: raw.song,
			bpm: raw.bpm,
			speed: raw.speed,
			notes: raw.notes,
			events: raw.events
		};
	}
}

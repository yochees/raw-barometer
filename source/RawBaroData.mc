import Toybox.Activity;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Time;

// Raw (station) pressure: the value the sensor measures, not reduced to sea
// level and not corrected for altitude. All values are in hPa (= mbar).
(:glance)
module RawBaroData {

    // The 4 hour view: 48 px per hour over the 230 px graph box, so it
    // shows 4.8 hours, the same as the stock screen.
    const WINDOW_4H = 230 * 3600 / 48;

    // Colours of the stock Barometer screens (MIP 64-colour palette).
    const BLUE = 0x00AAFF;
    const FILL = 0x000055;
    const GRID = 0x555555;
    const GRID_FILLED = 0x005555;
    const LABEL = 0xAAAAAA;

    // Current raw pressure in hPa, or null if no source has a value.
    function current() as Float or Null {
        var info = Activity.getActivityInfo();
        if (info != null) {
            if (info.rawAmbientPressure != null) {
                return info.rawAmbientPressure / 100.0;
            }
        }
        var s = Sensor.getInfo();
        if (s has :pressure && s.pressure != null) {
            return s.pressure / 100.0;
        }
        if (info != null && info.ambientPressure != null) {
            return info.ambientPressure / 100.0;
        }
        var it = SensorHistory.getPressureHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
        var sample = it.next();
        if (sample != null && sample.data != null) {
            return sample.data / 100.0;
        }
        return null;
    }

    // Pressure history for the last `seconds`, averaged into `n` columns
    // (oldest first, the last column is now). Returns
    // [columns, minValue, minColumn, maxValue, maxColumn]; the extremes are
    // single samples, not column averages, so the labels show real readings.
    // Done in one pass so the full history is never held in memory.
    function history(seconds as Number, n as Number) as Array {
        var sums = new Array<Float>[n];
        var counts = new Array<Number>[n];
        for (var i = 0; i < n; i++) {
            sums[i] = 0.0;
            counts[i] = 0;
        }
        var lo = null;
        var loCol = 0;
        var hi = null;
        var hiCol = 0;
        var now = Time.now().value();
        var it = SensorHistory.getPressureHistory({:period => new Time.Duration(seconds), :order => SensorHistory.ORDER_OLDEST_FIRST});
        var sample = it.next();
        while (sample != null) {
            if (sample.data != null && sample.when != null) {
                var age = now - sample.when.value();
                var col = n - 1 - (age.toLong() * n / seconds).toNumber();
                if (col >= 0) {
                    if (col > n - 1) { col = n - 1; }
                    var p = sample.data / 100.0;
                    sums[col] += p;
                    counts[col] += 1;
                    if (lo == null || p < lo) { lo = p; loCol = col; }
                    if (hi == null || p >= hi) { hi = p; hiCol = col; }
                }
            }
            sample = it.next();
        }
        var cols = new Array<Float or Null>[n];
        for (var i = 0; i < n; i++) {
            cols[i] = counts[i] > 0 ? sums[i] / counts[i] : null;
        }
        // Samples are further apart than one column, so join known columns
        // with straight lines. Nothing is added before the first or after
        // the last sample.
        var prev = -1;
        for (var i = 0; i < n; i++) {
            if (cols[i] == null) {
                continue;
            }
            if (prev >= 0 && i - prev > 1) {
                var a = cols[prev] as Float;
                var b = cols[i] as Float;
                for (var j = prev + 1; j < i; j++) {
                    cols[j] = a + (b - a) * (j - prev) / (i - prev);
                }
            }
            prev = i;
        }
        return [cols, lo, loCol, hi, hiCol];
    }

    function format(p as Float or Null) as String {
        return p == null ? "--" : p.format("%.1f");
    }
}

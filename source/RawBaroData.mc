import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Time;

// Raw (station) pressure: the value the sensor measures, not reduced to sea
// level and not corrected for altitude. All values are in hPa (= mbar).
(:glance)
module RawBaroData {

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

    // Pressure history for the last `hours`, averaged into `n` buckets
    // (oldest first). A bucket with no samples is null. Done in one pass so
    // the glance never holds the full history in memory.
    function history(hours as Number, n as Number) as Array<Float or Null> {
        var sums = new Array<Float>[n];
        var counts = new Array<Number>[n];
        for (var i = 0; i < n; i++) {
            sums[i] = 0.0;
            counts[i] = 0;
        }
        var span = hours * 3600;
        var now = Time.now().value();
        var it = SensorHistory.getPressureHistory({:period => new Time.Duration(span), :order => SensorHistory.ORDER_OLDEST_FIRST});
        var sample = it.next();
        while (sample != null) {
            if (sample.data != null && sample.when != null) {
                var age = now - sample.when.value();
                var b = n - 1 - (age * n / span);
                if (b < 0) { b = 0; }
                if (b > n - 1) { b = n - 1; }
                sums[b] += sample.data;
                counts[b] += 1;
            }
            sample = it.next();
        }
        var out = new Array<Float or Null>[n];
        for (var i = 0; i < n; i++) {
            out[i] = counts[i] > 0 ? sums[i] / counts[i] / 100.0 : null;
        }
        return out;
    }

    // Bionic is the fenix 8 system font. Older devices fall back to
    // Roboto Condensed and then to the given bitmap font.
    const TEXT_FACE = ["BionicSemiBold", "BionicBold", "RobotoCondensedBold"];
    const NUMBER_FACE = ["BionicSemiBold", "BionicBold", "RobotoCondensedBold"];

    function font(face as Array<String>, size as Number, fallback as Graphics.FontType) as Graphics.FontType {
        if (Graphics has :getVectorFont) {
            var vf = Graphics.getVectorFont({:face => face, :size => size});
            if (vf != null) {
                return vf;
            }
        }
        return fallback;
    }

    function format(p as Float or Null) as String {
        return p == null ? "--" : p.format("%.1f");
    }

    // Draws `pts` as a line inside the box. Returns [min, max] or null.
    // The vertical scale spans at least `minRange` hPa so sensor noise does
    // not look like a weather front.
    function drawGraph(dc as Graphics.Dc, pts as Array<Float or Null>, x as Number, y as Number,
                       w as Number, h as Number, minRange as Float, color as Number) as [Float, Float] or Null {
        var lo = null;
        var hi = null;
        for (var i = 0; i < pts.size(); i++) {
            var p = pts[i];
            if (p != null) {
                if (lo == null || p < lo) { lo = p; }
                if (hi == null || p > hi) { hi = p; }
            }
        }
        if (lo == null || hi == null) {
            return null;
        }
        var top = hi;
        var bottom = lo;
        if (top - bottom < minRange) {
            var mid = (top + bottom) / 2.0;
            top = mid + minRange / 2.0;
            bottom = mid - minRange / 2.0;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var n = pts.size();
        var px = -1;
        var py = -1;
        for (var i = 0; i < n; i++) {
            var p = pts[i];
            if (p == null) {
                continue;
            }
            var cx = x + (n > 1 ? i * (w - 1) / (n - 1) : 0);
            var cy = y + h - 1 - ((p - bottom) / (top - bottom) * (h - 1)).toNumber();
            if (px >= 0) {
                dc.drawLine(px, py, cx, cy);
            } else {
                dc.drawPoint(cx, cy);
            }
            px = cx;
            py = cy;
        }
        dc.setPenWidth(1);
        return [lo, hi];
    }
}

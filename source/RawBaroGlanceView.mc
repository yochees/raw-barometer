import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Pixel copy of the stock Barometer glance on the fenix 8 MIP: title in the
// glance font, value in Bionic, and a blue trend line from x = 98 to the
// right edge. The line covers the same time as the full view graph.
(:glance)
class RawBaroGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 14, Graphics.FONT_GLANCE, "Raw Barometer", Graphics.TEXT_JUSTIFY_LEFT);

        var valueFont = Graphics.FONT_GLANCE_NUMBER;
        if (Graphics has :getVectorFont) {
            var vf = Graphics.getVectorFont({:face => ["BionicSemiBold", "RobotoCondensedBold"], :size => 40});
            if (vf != null) {
                valueFont = vf;
            }
        }
        dc.drawText(0, 40, valueFont, RawBaroData.format(RawBaroData.current()), Graphics.TEXT_JUSTIFY_LEFT);

        // Trend line, scaled to the lowest and highest reading so it always
        // fills y = 48..84 (with the 2 px pen that is 47..85, as on the stock
        // glance).
        var gx = 98;
        var n = w - gx;
        if (n < 10) {
            return;
        }
        var h = RawBaroData.history(RawBaroData.WINDOW_4H, n);
        var cols = h[0] as Array<Float or Null>;
        var lo = h[1];
        var hi = h[3];
        if (lo == null || hi == null) {
            return;
        }
        var range = hi - lo;
        if (range < 0.2) {
            lo -= (0.2 - range) / 2;
            range = 0.2;
        }
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(RawBaroData.BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var px = -1;
        var py = 0;
        for (var i = 0; i < n; i++) {
            var p = cols[i];
            if (p == null) {
                px = -1;
                continue;
            }
            var y = 48 + ((hi - p) / range * 36).toNumber();
            if (px >= 0) {
                dc.drawLine(px, py, gx + i, y);
            }
            px = gx + i;
            py = y;
        }
        dc.setPenWidth(1);
    }
}

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Same layout as the stock Barometer glance: title on top, current value
// with its unit below, and a small trend line on the right.
(:glance)
class RawBaroGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var titleFont = RawBaroData.font(RawBaroData.TEXT_FACE, 26, Graphics.FONT_GLANCE);
        var valueFont = RawBaroData.font(RawBaroData.NUMBER_FACE, 44, Graphics.FONT_GLANCE_NUMBER);
        var titleH = dc.getFontHeight(titleFont);
        var valueH = dc.getFontHeight(valueFont);
        var top = (h - titleH - valueH) / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, top, titleFont, "Raw Barometer", Graphics.TEXT_JUSTIFY_LEFT);

        var value = RawBaroData.format(RawBaroData.current());
        var vy = top + titleH;
        dc.drawText(0, vy, valueFont, value, Graphics.TEXT_JUSTIFY_LEFT);
        var vw = dc.getTextWidthInPixels(value, valueFont);
        var unitFont = RawBaroData.font(RawBaroData.TEXT_FACE, 22, Graphics.FONT_XTINY);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vw + 3, vy + valueH - dc.getFontHeight(unitFont) - 2, unitFont, "hPa", Graphics.TEXT_JUSTIFY_LEFT);

        // Trend graph for the last 4 hours fills all the space right of the
        // value, to the edge of the glance and down to its bottom. The round
        // bezel crops the corner when the glance is not in the centre slot.
        var gx = vw + 3 + dc.getTextWidthInPixels("hPa", unitFont) + 8;
        var gw = w - gx;
        var gy = vy + 4;
        var gh = h - 2 - gy;
        if (gw >= 30 && gh >= 10) {
            RawBaroData.drawGraph(dc, RawBaroData.history(4, gw / 3), gx, gy, gw, gh, 1.0, Graphics.COLOR_WHITE);
        }
    }
}

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;
import Toybox.WatchUi;

// Full screen view, styled after the stock Barometer widget: title, trend
// graph with its high and low, large current value, period label.
class RawBaroView extends WatchUi.View {

    const PERIODS = [4, 12, 24] as Array<Number>;

    var _period as Number = 0;
    var _timer as Timer.Timer or Null;

    function initialize() {
        View.initialize();
    }

    function nextPeriod() as Void {
        _period = (_period + 1) % PERIODS.size();
        WatchUi.requestUpdate();
    }

    function prevPeriod() as Void {
        _period = (_period + PERIODS.size() - 1) % PERIODS.size();
        WatchUi.requestUpdate();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 5000, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var small = RawBaroData.font(RawBaroData.TEXT_FACE, 22, Graphics.FONT_XTINY);
        var smallH = dc.getFontHeight(small);
        var titleFont = RawBaroData.font(RawBaroData.TEXT_FACE, 28, Graphics.FONT_TINY);
        var bigFont = RawBaroData.font(RawBaroData.NUMBER_FACE, 64, Graphics.FONT_NUMBER_MEDIUM);
        var bigH = dc.getFontHeight(bigFont);
        var hours = PERIODS[_period];

        // Stack from the edges in: title at the top, period label at the
        // bottom, value above it. The graph takes everything in between.
        var titleY = h * 7 / 100;
        var lastY = h - h * 6 / 100 - smallH;
        var vy = lastY - bigH + 6;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleY, titleFont, "Raw Barometer", Graphics.TEXT_JUSTIFY_CENTER);

        // Widest box that stays inside the round screen between the title
        // and the value: its width is set by the chord at the edge that is
        // furthest from the centre.
        var gy = titleY + dc.getFontHeight(titleFont) + 2;
        var gb = vy + 4;
        var gh = gb - gy;
        var r = (w < h ? w : h) / 2;
        var dy = (h / 2 - gy).abs();
        var dyb = (gb - h / 2).abs();
        if (dyb > dy) { dy = dyb; }
        var half = Math.sqrt(r * r - dy * dy).toNumber() - 4;
        var gx = cx - half;
        var gw = 2 * half;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var x = gx; x < gx + gw; x += 4) {
            dc.drawPoint(x, gy);
            dc.drawPoint(x, gb);
        }
        var range = RawBaroData.drawGraph(dc, RawBaroData.history(hours, gw / 2), gx, gy + 2, gw, gh - 3, 2.0, Graphics.COLOR_BLUE);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        if (range != null) {
            // High and low sit inside the box, on a black background so the
            // line under them does not hide the digits.
            dc.drawText(gx + gw, gy + 2, small, RawBaroData.format(range[1]), Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(gx + gw, gb - smallH - 1, small, RawBaroData.format(range[0]), Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(cx, gy + gh / 2 - smallH / 2, small, "No history", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Current value and unit.
        var value = RawBaroData.format(RawBaroData.current());
        var vw = dc.getTextWidthInPixels(value, bigFont);
        var uw = dc.getTextWidthInPixels(" hPa", small);
        var vx = cx - (vw + uw) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx, vy, bigFont, value, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx + vw, vy + bigH - smallH - 4, small, " hPa", Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(cx, lastY, small, "Last " + hours + " Hrs", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

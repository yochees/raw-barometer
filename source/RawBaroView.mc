import Toybox.Graphics;
import Toybox.Lang;
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

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 12 / 100, RawBaroData.font(RawBaroData.TEXT_FACE, 28, Graphics.FONT_TINY), "Raw Barometer", Graphics.TEXT_JUSTIFY_CENTER);

        // Graph box with dotted grid lines at top and bottom.
        var gx = w * 18 / 100;
        var gw = w - 2 * gx;
        var gy = h * 27 / 100;
        var gh = h * 30 / 100;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var x = gx; x < gx + gw; x += 4) {
            dc.drawPoint(x, gy);
            dc.drawPoint(x, gy + gh);
        }
        var hours = PERIODS[_period];
        var range = RawBaroData.drawGraph(dc, RawBaroData.history(hours, gw / 2), gx, gy + 2, gw, gh - 3, 2.0, Graphics.COLOR_BLUE);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (range != null) {
            dc.drawText(gx + gw, gy - smallH, small, RawBaroData.format(range[1]), Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(gx + gw, gy + gh, small, RawBaroData.format(range[0]), Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(cx, gy + gh / 2 - smallH / 2, small, "No history", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Current value and unit.
        var value = RawBaroData.format(RawBaroData.current());
        var bigFont = RawBaroData.font(RawBaroData.NUMBER_FACE, 64, Graphics.FONT_NUMBER_MEDIUM);
        var vy = h * 62 / 100;
        var vw = dc.getTextWidthInPixels(value, bigFont);
        var uw = dc.getTextWidthInPixels(" hPa", small);
        var vx = cx - (vw + uw) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx, vy, bigFont, value, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(vx + vw, vy + dc.getFontHeight(bigFont) - smallH - 4, small, " hPa", Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(cx, h * 84 / 100, small, "Last " + hours + " Hrs", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Pixel copy of the stock Barometer screen on the fenix 8 MIP (280x280):
// icon, value, START arc, graph with filled area, clock-aligned grid, min and
// max markers, axis labels and the period label. Coordinates are the ones
// measured on the watch's own screenshot.
class RawBaroView extends WatchUi.View {

    // Graph box: x 0..229, y 114..220.
    const BOX_W = 230;
    const BOX_TOP = 114;
    const BOX_BOTTOM = 220;
    const PERIODS = [4, 12, 24] as Array<Number>;

    var _period as Number = 0;
    var _timer as Timer.Timer or Null;
    var _icon as WatchUi.BitmapResource or Null;
    var _small as Graphics.FontType = Graphics.FONT_XTINY;
    var _buffer as Graphics.BufferedBitmap or Null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _icon = WatchUi.loadResource(Rez.Drawables.Icon24) as WatchUi.BitmapResource;
        _small = RawBaroData.bionic(26, Graphics.FONT_XTINY);
        // The screen is drawn off screen and copied in one step. Drawing
        // straight to the display let the watch show a half-drawn first
        // frame (the filled graph before its grid).
        var opts = {:width => dc.getWidth(), :height => dc.getHeight()};
        if (Graphics has :createBufferedBitmap) {
            _buffer = Graphics.createBufferedBitmap(opts).get() as Graphics.BufferedBitmap;
        } else {
            _buffer = new Graphics.BufferedBitmap(opts);
        }
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
        var buffer = _buffer;
        if (buffer != null) {
            drawScreen(buffer.getDc());
            dc.drawBitmap(0, 0, buffer);
        } else {
            drawScreen(dc);
        }
    }

    private function drawScreen(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        if (_icon != null) {
            dc.drawBitmap(128, 14, _icon);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(140, 41, Graphics.FONT_NUMBER_MEDIUM, RawBaroData.format(RawBaroData.current()), Graphics.TEXT_JUSTIFY_CENTER);

        // Arc next to the START button: START changes the period.
        dc.setPenWidth(4);
        dc.drawArc(140, 140, 135, Graphics.ARC_COUNTER_CLOCKWISE, 18, 42);
        dc.setPenWidth(1);

        var hours = PERIODS[_period];
        drawGraph(dc, hours);

        dc.setColor(RawBaroData.LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(138, 221, _small, "Last " + hours + " Hours", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawGraph(dc as Graphics.Dc, hours as Number) as Void {
        var pxPerHour = 192 / hours;
        var seconds = BOX_W * 3600 / pxPerHour;
        var h = RawBaroData.history(seconds, BOX_W);
        var cols = h[0] as Array<Float or Null>;
        var lo = h[1] as Float or Null;
        var hi = h[3] as Float or Null;

        // Scale: whole hPa at top and bottom, an even span of at least 2 hPa
        // so the middle line is a whole hPa too. Solid lines every span / 4,
        // dotted between them, labels on the top and middle lines.
        var top = 1;
        var span = 2;
        if (lo != null && hi != null) {
            var bottom = Math.floor(lo).toNumber();
            top = Math.ceil(hi).toNumber();
            while (top - bottom < 2 || (top - bottom) % 2 != 0) {
                if (lo - bottom < top - hi) {
                    bottom -= 1;
                } else {
                    top += 1;
                }
            }
            span = top - bottom;
        }
        var boxH = BOX_BOTTOM - BOX_TOP;

        // Column -> y of the line (-1 = no data).
        var ys = new Array<Number>[BOX_W];
        for (var x = 0; x < BOX_W; x++) {
            var p = cols[x];
            ys[x] = p == null ? -1 : BOX_TOP + ((top - p) * boxH / span).toNumber();
        }

        // Filled area under the line.
        dc.setColor(RawBaroData.FILL, Graphics.COLOR_TRANSPARENT);
        for (var x = 0; x < BOX_W; x++) {
            if (ys[x] >= 0) {
                dc.drawLine(x, ys[x], x, BOX_BOTTOM);
            }
        }

        // Vertical grid on the clock: solid every span/4 of the period
        // (each hour on the 4 hour view), dotted half way between.
        var step = hours * 3600 / 8;
        var now = Time.now().value();
        var vlines = new Array<Number>[0];
        var vsolid = new Array<Boolean>[0];
        var t = now - now % step;
        while (true) {
            var x = BOX_W - 1 - ((now - t) * pxPerHour / 3600);
            if (x < 0) {
                break;
            }
            vlines.add(x);
            vsolid.add((t / step) % 2 == 0);
            t -= step;
        }
        for (var i = 0; i < vlines.size(); i++) {
            var x = vlines[i];
            var fy = ys[x] >= 0 ? ys[x] : BOX_BOTTOM;
            if (vsolid[i]) {
                if (fy > BOX_TOP + 1) {
                    dc.setColor(RawBaroData.GRID, Graphics.COLOR_TRANSPARENT);
                    dc.drawLine(x, BOX_TOP + 1, x, fy);
                }
                dc.setColor(RawBaroData.GRID_FILLED, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x, fy, x, BOX_BOTTOM);
            } else {
                dc.setColor(RawBaroData.GRID, Graphics.COLOR_TRANSPARENT);
                var filled = false;
                for (var y = BOX_TOP + 1; y < BOX_BOTTOM; y += 2) {
                    if (!filled && y >= fy) {
                        filled = true;
                        dc.setColor(RawBaroData.GRID_FILLED, Graphics.COLOR_TRANSPARENT);
                    }
                    dc.drawPoint(x, y);
                }
            }
        }

        // Horizontal grid: 8 rows, solid on even ones. Top and bottom rows
        // stay grey; the dotted rows have a pixel on even x and where they
        // cross a vertical line.
        for (var r = 0; r <= 8; r++) {
            var y = BOX_TOP + r * boxH / 8;
            if (r == 0 || r == 8) {
                dc.setColor(RawBaroData.GRID, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(0, y, BOX_W, y);
                continue;
            }
            var solid = r % 2 == 0;
            var vi = 0;
            var vx = vlines.size() > 0 ? vlines[vlines.size() - 1] : -9;
            var color = -1;
            var runStart = 0;
            for (var x = 0; x <= BOX_W; x++) {
                var c = -1;
                var cross = false;
                if (x < BOX_W) {
                    cross = (x == vx);
                    if (cross) {
                        vi++;
                        vx = vi < vlines.size() ? vlines[vlines.size() - 1 - vi] : -9;
                    }
                    c = (ys[x] >= 0 && y >= ys[x]) ? RawBaroData.GRID_FILLED : RawBaroData.GRID;
                }
                if (solid) {
                    // One line per run of the same colour.
                    if (c != color) {
                        if (color != -1) {
                            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                            dc.drawLine(runStart, y, x, y);
                        }
                        color = c;
                        runStart = x;
                    }
                } else if (x < BOX_W && (x % 2 == 0 || cross)) {
                    if (c != color) {
                        color = c;
                        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
                    }
                    dc.drawPoint(x, y);
                }
            }
        }

        // Axis labels on the top and middle lines.
        dc.setColor(RawBaroData.LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(230, BOX_TOP - 13, _small, top.toString(), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(230, BOX_TOP + boxH / 2 - 13, _small, (top - span / 2).toString(), Graphics.TEXT_JUSTIFY_LEFT);

        if (lo == null || hi == null) {
            dc.setColor(RawBaroData.LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(BOX_W / 2, BOX_TOP + boxH / 2 - 13, _small, "No history", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // The line.
        dc.setColor(RawBaroData.BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var px = -1;
        for (var x = 0; x < BOX_W; x++) {
            if (ys[x] < 0) {
                px = -1;
                continue;
            }
            if (px >= 0) {
                dc.drawLine(px, ys[px], x, ys[x]);
            }
            px = x;
        }
        dc.setPenWidth(1);

        // Markers: a triangle 2 px from the point, the reading 6 px beyond
        // its base. Max sits under the line pointing up, min above it
        // pointing down.
        var maxX = h[4] as Number;
        var minX = h[2] as Number;
        if (ys[maxX] >= 0) {
            var base = ys[maxX] + 6;
            drawTriangle(dc, maxX, ys[maxX] + 2, 1);
            drawMarkerLabel(dc, maxX, base, RawBaroData.format(hi));
        }
        if (ys[minX] >= 0) {
            var base = ys[minX] - 6;
            drawTriangle(dc, minX, ys[minX] - 2, -1);
            drawMarkerLabel(dc, minX, base - 24, RawBaroData.format(lo));
        }
    }

    // 10 px wide, 5 rows, apex at (cx, apexY); dir 1 points up, -1 down.
    // Edge pixels are grey for the stock anti-aliased look, with a 1 px
    // black outline.
    private function drawTriangle(dc as Graphics.Dc, cx as Number, apexY as Number, dir as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var k = -1; k <= 5; k++) {
            var kk = k < 0 ? 0 : (k > 4 ? 4 : k);
            dc.drawLine(cx - 2 - kk, apexY + k * dir, cx + kk + 2, apexY + k * dir);
        }
        for (var k = 0; k <= 4; k++) {
            var y = apexY + k * dir;
            dc.setColor(RawBaroData.LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawPoint(cx - 1 - k, y);
            dc.drawPoint(cx + k, y);
            if (k > 0) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(cx - k, y, cx + k, y);
            }
        }
    }

    // White reading with a black outline, centred on x but kept inside the
    // graph on the right and 4 px inside the round screen on the left.
    private function drawMarkerLabel(dc as Graphics.Dc, x as Number, y as Number, text as String) as Void {
        var font = _small;
        var w = dc.getTextWidthInPixels(text, font);
        var left = x - w / 2;
        if (left + w > BOX_W) {
            left = BOX_W - w;
        }
        var r = 140;
        var dy = (y + 18 - 140).abs();
        var minLeft = r - Math.sqrt(r * r - dy * dy).toNumber() + 4 - 1;
        if (left < minLeft) {
            left = minLeft;
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var ox = -1; ox <= 1; ox++) {
            for (var oy = -1; oy <= 1; oy++) {
                if (ox != 0 || oy != 0) {
                    dc.drawText(left + ox, y + oy, font, text, Graphics.TEXT_JUSTIFY_LEFT);
                }
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
}

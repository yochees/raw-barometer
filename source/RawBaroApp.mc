import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class RawBaroApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new RawBaroView();
        return [view, new RawBaroDelegate(view)];
    }

    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new RawBaroGlanceView()];
    }

    // Light blue side bar, as on the stock Barometer glance.
    function getGlanceTheme() as Application.AppBase.GlanceTheme {
        return Application.AppBase.GLANCE_THEME_LIGHT_BLUE;
    }
}

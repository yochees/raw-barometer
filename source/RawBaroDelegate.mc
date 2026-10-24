import Toybox.Lang;
import Toybox.WatchUi;

// START and DOWN show a longer period, UP a shorter one. MENU (hold UP)
// opens the unit menu. BACK exits.
class RawBaroDelegate extends WatchUi.BehaviorDelegate {

    var _view as RawBaroView;

    function initialize(view as RawBaroView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.nextPeriod();
        return true;
    }

    function onNextPage() as Boolean {
        _view.nextPeriod();
        return true;
    }

    function onMenu() as Boolean {
        RawBaroMenu.open();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.prevPeriod();
        return true;
    }
}

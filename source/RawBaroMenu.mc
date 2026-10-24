import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Unit menu, opened with MENU (hold UP) in the full view. It edits the same
// "Unit" property as the phone app settings.
class RawBaroMenu {

    static function open() as Void {
        var menu = new WatchUi.Menu2({:title => Rez.Strings.SettUnit});
        var names = [Rez.Strings.UnitHpa, Rez.Strings.UnitMbar, Rez.Strings.UnitInhg, Rez.Strings.UnitMmhg];
        for (var i = 0; i < names.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(names[i], null, i, null));
        }
        menu.setFocus(RawBaroData.unit());
        WatchUi.pushView(menu, new RawBaroMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class RawBaroMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Application.Properties.setValue("Unit", item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }
}

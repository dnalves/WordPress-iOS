import ScreenObject
import XCTest

public class MeTabScreen: ScreenObject {
    let logOutButton: XCUIElement
    let logOutAlert: XCUIElement
    var appSettingsButton: XCUIElement { expectedElement }
    let myProfileButton: XCUIElement
    let accountSettingsButton: XCUIElement
    let notificationSettingsButton: XCUIElement
    let doneButton: XCUIElement

    init(app: XCUIApplication = XCUIApplication()) throws {
        logOutButton = app.cells["logOutFromWPcomButton"]
        logOutAlert = app.alerts.element(boundBy: 0)
        myProfileButton = app.cells["myProfile"]
        accountSettingsButton = app.cells["accountSettings"]
        notificationSettingsButton = app.cells["notificationSettings"]
        doneButton = app.navigationBars.buttons["doneBarButton"]

        try super.init(
            expectedElementGetter: { $0.cells["appSettings"] },
            app: app
        )
    }

    public func isLoggedInToWpcom() -> Bool {
        return logOutButton.exists
    }

    public func logout() -> WelcomeScreen {
        app.cells["logOutFromWPcomButton"].tap()

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonAxisX {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return WelcomeScreen()
    }

    public func logoutToPrologue() -> PrologueScreen {
        app.cells["logOutFromWPcomButton"].tap()

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonAxisX {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return PrologueScreen()
    }

    func goToLoginFlow() -> PrologueScreen {
        app.cells["Log In"].tap()

        return PrologueScreen()
    }

    public func dismiss() -> MySiteScreen {
        app.buttons["Done"].tap()

        return MySiteScreen()
    }
}

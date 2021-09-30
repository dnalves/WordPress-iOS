import UITestsFoundation
import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = try TabNavComponent()
            .goToMySiteScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    func testTabBarNavigation() throws {
        XCTAssert(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")

        _ = mySiteScreen
            .tabBar.goToReaderScreen()

        XCTAssert(ReaderScreen.isLoaded(), "Reader screen isn't loaded.")

        _ = try mySiteScreen
            .tabBar.gotoNotificationsScreen()
            .dismissNotificationAlertIfNeeded()

        XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
            XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
            XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
        }
    }
}

import XCTest

public class EditorPublishEpilogueScreen: BaseScreen {
    let doneButton: XCUIElement
    let viewButton: XCUIElement

    public init() {
        let app = XCUIApplication()
        let published = app.staticTexts["publishedPostStatusLabel"]
        doneButton = app.navigationBars.buttons["doneButton"]
        viewButton = app.buttons["viewPostButton"]

        super.init(element: published)
    }

    // returns void since return screen depends on what screen you started on
    public func done() {
        doneButton.tap()
    }

    public func verifyEpilogueDisplays(postTitle expectedPostTitle: String, siteAddress expectedSiteAddress: String) -> EditorPublishEpilogueScreen {
        let actualPostTitle = XCUIApplication().staticTexts["postTitle"].label
        let actualSiteAddress = XCUIApplication().staticTexts["siteUrl"].label

        XCTAssertEqual(expectedPostTitle, actualPostTitle, "Post title doesn't match expected title")
        XCTAssertEqual(expectedSiteAddress, actualSiteAddress, "Site address doesn't match expected address")

        return self
    }
}

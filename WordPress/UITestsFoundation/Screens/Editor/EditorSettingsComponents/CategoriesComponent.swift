import XCTest

public class CategoriesComponent: BaseScreen {
    let categoriesList: XCUIElement

    init() {
        let app = XCUIApplication()
        categoriesList = app.tables["CategoriesList"]

        super.init(element: categoriesList)
    }

    public func selectCategory(name: String) -> CategoriesComponent {
        let category = app.cells.staticTexts[name]
        category.tap()

        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        navBackButton.tap()

        return EditorPostSettings()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().tables["CategoriesList"].exists
    }
}

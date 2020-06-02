import Foundation

class ReaderDetailCoordinator {

    /// A post to be displayed
    var post: ReaderPost?

    /// Reader Post Service
    private let service: ReaderPostService

    /// Reader Topic Service
    private let topicService: ReaderTopicService

    /// Post Sharing Controller
    private let sharingController: PostSharingController

    /// Reader Link Router
    private let readerLinkRouter: UniversalLinkRouter

    /// Reader View
    private weak var view: ReaderDetailView?

    /// Reader View Controller
    private var viewController: UIViewController? {
        return view as? UIViewController
    }

    /// A post ID to fetch
    private(set) var postID: NSNumber?

    /// A site ID to be used to fetch a post
    private(set) var siteID: NSNumber?

    /// If the site is an external feed (not hosted at WPcom and not using Jetpack)
    private(set) var isFeed: Bool?

    /// Initialize the Reader Detail Coordinator
    ///
    /// - Parameter service: a Reader Post Service
    init(service: ReaderPostService = ReaderPostService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         topicService: ReaderTopicService = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext),
         sharingController: PostSharingController = PostSharingController(),
         readerLinkRouter: UniversalLinkRouter = UniversalLinkRouter(routes: UniversalLinkRouter.readerRoutes),
         view: ReaderDetailView) {
        self.service = service
        self.topicService = topicService
        self.sharingController = sharingController
        self.readerLinkRouter = readerLinkRouter
        self.view = view
    }

    /// Start the cordinator
    ///
    func start() {
        if let post = post {
            view?.render(post)
            view?.show(title: post.postTitle)
        } else if let siteID = siteID, let postID = postID, let isFeed = isFeed {
            fetch(postID: postID, siteID: siteID, isFeed: isFeed)
        }
    }

    /// Share the current post
    ///
    func share(fromView anchorView: UIView) {
        guard let post = post, let view = viewController else {
            return
        }

        sharingController.shareReaderPost(post, fromView: anchorView, inViewController: view)
    }

    /// Set a postID, siteID and isFeed
    ///
    /// - Parameter postID: A post ID to fetch
    /// - Parameter siteID: A site ID to fetch
    /// - Parameter isFeed: If the site is an external feed (not hosted at WPcom and not using Jetpack)
    func set(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        self.postID = postID
        self.siteID = siteID
        self.isFeed = isFeed
    }

    /// Show more about a specific site in Discovery
    ///
    func showMore() {
        guard let post = post, post.sourceAttribution != nil else {
            return
        }

        if let blogID = post.sourceAttribution.blogID {
            let controller = ReaderStreamViewController.controllerWithSiteID(blogID, isFeed: false)
            viewController?.navigationController?.pushViewController(controller, animated: true)
            return
        }

        var path: String?
        if post.sourceAttribution.attributionType == SourcePostAttributionTypePost {
            path = post.sourceAttribution.permalink
        } else {
            path = post.sourceAttribution.blogURL
        }

        if let path = path, let linkURL = URL(string: path) {
            presentWebViewControllerWithURL(linkURL)
        }
    }

    /// Loads an image (or GIF) from a URL and displays it in fullscreen
    ///
    /// - Parameter url: URL of the image or gif
    func presentImage(_ url: URL) {
        let imageViewController = WPImageViewController(url: url)
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.modalPresentationStyle = .fullScreen

        viewController?.present(imageViewController, animated: true)
    }

    /// Requests a ReaderPost from the service and updates the View.
    ///
    /// Use this method to fetch a ReaderPost.
    /// - Parameter postID: a post identification
    /// - Parameter siteID: a site identification
    /// - Parameter isFeed: a Boolean indicating if the site is an external feed (not hosted at WPcom and not using Jetpack)
    private func fetch(postID: NSNumber, siteID: NSNumber, isFeed: Bool) {
        service.fetchPost(postID.uintValue,
                          forSite: siteID.uintValue,
                          isFeed: isFeed,
                          success: { [weak self] post in
                            guard let post = post else {
                                return
                            }

                            self?.post = post
                            self?.view?.render(post)
                            self?.view?.show(title: post.postTitle)
        }, failure: { [weak self] _ in
            self?.view?.showError()
        })
    }

    /// Shows the current post site posts in a new screen
    ///
    private func previewSite() {
        guard let post = post else {
            return
        }

        let controller = ReaderStreamViewController.controllerWithSiteID(post.siteID, isFeed: post.isExternal)
        viewController?.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL as AnyObject?, forKey: "URL")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }

    /// Show a menu with options forthe current post's site
    ///
    private func showMenu(_ anchorView: UIView) {
        guard let post = post else {
            return
        }

        guard post.isFollowing else {
            ReaderPostMenu.showMenuForPost(post, fromView: anchorView, inViewController: viewController)
            return
        }

        if let topic = topicService.findSiteTopic(withSiteID: post.siteID) {
            ReaderPostMenu.showMenuForPost(post, topic: topic, fromView: anchorView, inViewController: viewController)
            return
        }
    }

    /// Show a list with posts contianing this tag
    ///
    private func showTag() {
        guard let post = post else {
            return
        }

        let controller = ReaderStreamViewController.controllerWithTagSlug(post.primaryTagSlug)
        viewController?.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.primaryTagSlug as AnyObject?, forKey: "tag")
        WPAppAnalytics.track(.readerTagPreviewed, withProperties: properties)
    }

    func handle(_ url: URL) {
        if url.pathExtension.contains("gif") || url.pathExtension.contains("jpg") || url.pathExtension.contains("jpeg") || url.pathExtension.contains("png") {
            presentImage(url)
        } else if readerLinkRouter.canHandle(url: url) {
            readerLinkRouter.handle(url: url, shouldTrack: false, source: viewController)
        } else if url.isWordPressDotComPost {
            presentReaderDetail(url)
        } else {
            presentWebViewController(url)
        }
    }

    /// Show the featured image fullscreen
    ///
    private func showFeaturedImage(_ sender: CachedAnimatedImageView) {
        guard let post = post else {
            return
        }

        var controller: WPImageViewController
        if post.featuredImageURL.isGif, let data = sender.animatedGifData {
            controller = WPImageViewController(gifData: data)
        } else if let featuredImage = sender.image {
            controller = WPImageViewController(image: featuredImage)
        } else {
            return
        }

        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        viewController?.present(controller, animated: true)
    }

    /// Given a URL presents it in a new Reader detail screen
    ///
    private func presentReaderDetail(_ url: URL) {
        let readerDetail = ReaderDetailWebviewViewController.controllerWithPostURL(url)
        viewController?.navigationController?.pushViewController(readerDetail, animated: true)
    }

    /// Given a URL presents it in a web view controller screen
    ///
    private func presentWebViewController(_ url: URL) {
        var url = url
        if url.host == nil {
            if let postURLString = post?.permaLink {
                let postURL = URL(string: postURLString)
                url = URL(string: url.absoluteString, relativeTo: postURL)!
            }
        }
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        viewController?.present(navController, animated: true)
    }

    /// Displays a specific URL in a separated View Controller
    ///
    /// - Parameter url: the URL to be loaded
    private func presentWebViewControllerWithURL(_ url: URL) {
        var url = url
        if url.host == nil {
            if let postURLString = post?.permaLink {
                let postURL = URL(string: postURLString)
                url = URL(string: url.absoluteString, relativeTo: postURL)!
            }
        }
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        viewController?.present(navController, animated: true)
    }
}

extension ReaderDetailCoordinator: ReaderDetailHeaderViewDelegate {
    func didTapBlogName() {
        previewSite()
    }

    func didTapMenuButton(_ sender: UIView) {
        showMenu(sender)
    }

    func didTapTagButton() {
        showTag()
    }

    func didTapHeaderAvatar() {
        previewSite()
    }

    func didTapFeaturedImage(_ sender: CachedAnimatedImageView) {
        showFeaturedImage(sender)
    }
}

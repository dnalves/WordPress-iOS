import Foundation


/// This service encapsulates all of the Actions that can be performed with a NotificationBlock
///
open class NotificationActionsService: LocalCoreDataService {

    /// Follows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func followSiteWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.uintValue else {
            completion?(false)
            return
        }

        siteService.followSite(withID: siteID, success: {
            DDLogSwift.logInfo("Successfully followed site \(siteID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to follow site: \(error)")
            block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Follow)
    }


    /// Unfollows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unfollowSiteWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.uintValue else {
            completion?(false)
            return
        }

        siteService.unfollowSite(withID: siteID, success: {
            DDLogSwift.logInfo("Successfully unfollowed site \(siteID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to unfollow site: \(error)")
            block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Follow)
    }


    /// Replies a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Reply's Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func replyCommentWithBlock(_ block: NotificationBlock, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.replyToComment(withID: commentID, siteID: siteID, content: content, success: {
            DDLogSwift.logInfo("Successfully replied to comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to reply comment: \(error)")
            completion?(false)
        })
    }


    /// Updates a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Comment's New Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func updateCommentWithBlock(_ block: NotificationBlock, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // Local Override: Temporary hack until the Notification is updated
        block.textOverride = content

        // Hit the backend
        commentService.updateComment(withID: commentID, siteID: siteID, content: content, success: {
            DDLogSwift.logInfo("Successfully updated to comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to update comment: \(error)")
            completion?(false)
        })
    }


    /// Likes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func likeCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved == false {
            approveCommentWithBlock(block)
        }

        // Proceed toggling the Like field
        commentService.likeComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully liked comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to like comment: \(error)")
            block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Like)
    }


    /// Unlikes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unlikeCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unlikeComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unliked comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to unlike comment: \(error)")
            block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Like)
    }


    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func approveCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.approveComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully approved comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Approve)
    }


    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unapproveCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unapproveComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unapproved comment \(siteID).\(commentID)")
            self.invalidateCacheForNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Approve)
    }


    /// Spams a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func spamCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.spamComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully spammed comment \(siteID).\(commentID)")
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to mark comment as spam: \(error)")
            completion?(false)
        })
    }


    /// Deletes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func deleteCommentWithBlock(_ block: NotificationBlock, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.deleteComment(withID: commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully deleted comment \(siteID).\(commentID)")
            completion?(true)

        }, failure: { error in
            DDLogSwift.logError("Error while trying to delete comment: \(error)")
            completion?(false)
        })
    }
}



// MARK: - Private Helpers
//
private extension NotificationActionsService {

    /// Invalidates the Local Cache for a given Notification. This will effectively cause the notification to
    /// be re-downloaded from the remote endpoint.
    ///
    /// Required due to a beautiful backend bug. Details here: https://github.com/wordpress-mobile/WordPress-iOS/pull/6871
    ///
    /// - Parameter block: child NotificationBlock object of the Notification-to-be-refreshed.
    ///
    func invalidateCacheForNotification(with block: NotificationBlock) {
        guard let notificationID = block.notificationID, let mediator = NotificationSyncMediator() else {
            return
        }

        DDLogSwift.logInfo("Invalidating cache for Notification with ID: \(notificationID)")
        mediator.invalidateCacheForNotification(with: notificationID)
    }
}



// MARK: - Computed Properties
//
private extension NotificationActionsService {

    var commentService: CommentService {
        return CommentService(managedObjectContext: managedObjectContext)
    }

    var siteService: ReaderSiteService {
        return ReaderSiteService(managedObjectContext: managedObjectContext)
    }
}

//
//  LivefeedListViewController.swift
//  Portl
//
//  Created by Jeff Creed on 5/24/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import RxSwift
import CoreData
import CoreLocation

class LivefeedListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, LivefeedTableViewCellDelegate, OverflowMenuProvidingCellDelegate, VideoPlayerProvidingCellDelegate, VoteButtonsProvidingCellDelegate {
	// MARK: VoteButtonsProvidingCellDelegate
	
	func voteForIndexPath(indexPath: IndexPath, isUp: Bool) {
		let notification = notificationResultsController!.fetchedObjects![indexPath.row]

		switch notification.notificationType {
		case .community:
			if let eventID = notification.eventID, let messageKey = notification.messageKey {
				let conversationKey = ConversationService.getCommunityConversationID(fromEventID: eventID)
				let voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationKey, messageKey: messageKey)
				let newVoteStatus = voteStatus == isUp ? nil : isUp

				profileService.voteOnConversationMessage(withConversationKey: conversationKey, andMessageKey: messageKey, vote: newVoteStatus)
			}
		case .reply:
			if let conversationKey = notification.replyThreadKey, let messageKey = notification.messageKey {
				let voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: conversationKey, messageKey: messageKey)
				let newVoteStatus = voteStatus == isUp ? nil : isUp

				profileService.voteOnConversationMessage(withConversationKey: conversationKey, andMessageKey: messageKey, vote: newVoteStatus)
			}
		case .experience:
			if let experienceID = notification.messageKey {
				let voteStatus = profileService.getVoteStatusForExperience(profileID: notification.userID, experienceKey: experienceID)
				let newVoteStatus = voteStatus == isUp ? nil : isUp

				profileService.voteOnExperience(withProfileID: notification.userID, andExperienceKey: experienceID, vote: newVoteStatus)
			}
		default:
			return
		}
	}
	
	func voteButtonsProvidingCellSelectedUpvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		if let indexPath = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell) {
			voteForIndexPath(indexPath: indexPath, isUp: true)
		}
	}
	
	func voteButtonsProvidingCellSelectedDownvote(_ voteButtonsProvidingCell: VoteButtonsProvidingCell) {
		if let indexPath = tableView.indexPath(for: voteButtonsProvidingCell as! UITableViewCell) {
			voteForIndexPath(indexPath: indexPath, isUp: false)
		}
	}
	
	// MARK: VideoPlayerProvidingCellDelegate
	
	func videoPlayerProvidingCellTapped(_ cell: VideoPlayerProvidingCell) {
		if let indexPath = tableView.indexPath(for: cell as! UITableViewCell),
			let notification = notificationResultsController?.object(at: IndexPath(row: indexPath.row, section: 0)),
			let messageKey = notification.messageKey,
			let _ = messageIDToMessage[messageKey] {
					playbackController.present(contentForMessageKey: messageKey, from: self)
		}
	}
	
	// MARK: OverflowMenuProvidingCellDelegate
	
	func overflowMenuProvidingCellRequestedMenu(_ overflowMenuProvingCell: OverflowMenuProvidingCell) {
		let idx = tableView.indexPath(for: overflowMenuProvingCell as! UITableViewCell)!.row
		let notification = notificationResultsController!.fetchedObjects![idx]
		let alert = UIAlertController(title: nil, message: "Manage Post/Comment", preferredStyle: .actionSheet)
		
		switch notification.notificationType {
		case .share:
			alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: {[unowned self] (_) in
				guard let event = self.idToLoadedEvents[notification.eventID!] else {
					self.presentErrorAlert(withMessage: "Try again once event is loaded.", completion: nil)
					return
				}
				
				let conversationKey = ConversationService.getShareConversationID(fromEventID: notification.eventID!, userID: notification.userID, andActionDateString: self.notificationDateFormatter.string(from: notification.date as Date))
				
				guard let conversationOverview = self.conversationIDToOverview[conversationKey] else {
					self.presentErrorAlert(withMessage: "Try again once share is fully loaded", completion: nil)
					return
				}
				
				let nav = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! ShareViewController
				controller.configureForEdit(event: event, message: conversationOverview.firstMessage, conversationKey: conversationKey)
				
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}))
			
			alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[unowned self] (_) in
				self.profileService.deleteShare(self.notificationDateFormatter.string(from: notification.date as Date), completion: {
					self.firebaseService.deleteLivefeedNotification(notification)
					self.deleteCount += 1
				})
			}))
			
			break
		case .community:
			let conversationKey = ConversationService.getCommunityConversationID(fromEventID: notification.eventID!)
			
			guard let messageKey = notification.messageKey else {
				self.presentErrorAlert(withMessage: "Older messages can't be edited", completion: nil)
				return
			}
			
			alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: {[unowned self] (_) in
				guard let message = try? self.livefeedService.getConversationMessageObservable(forConversationID: conversationKey, andMessageID: messageKey).value() else {
					self.presentErrorAlert(withMessage: "Try again once Community post is fully loaded", completion: nil)
					return
				}
				
				let nav = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! CreateMessageViewController
				controller.configureForEdit(message: message.message, imageURL: message.imageURL, videoURL: message.videoURL, conversationKey: conversationKey, messageKey: messageKey)
				
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}))
			
			alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[unowned self] (_) in
				self.conversationService.deleteMessage(conversationKey: conversationKey, messageKey: messageKey, completion: {
					self.firebaseService.deleteLivefeedNotificationForCommunitMessage(withEventID: notification.eventID!, andMessageKey: messageKey)
					self.deleteCount += 1
				})
			}))
			
			break
		case .experience:
			guard let messageKey = notification.messageKey else {
				self.presentErrorAlert(withMessage: "Older messages can't be edited", completion: nil)
				return
			}
			
			alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: {[unowned self] (_) in
				guard let message = try? self.livefeedService.getExperiencePostObservable(forProfileID: Auth.auth().currentUser!.uid, andMessageID: messageKey).value() else {
					self.presentErrorAlert(withMessage: "Try again once post is fully loaded", completion: nil)
					return
				}
				
				let nav = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! CreateMessageViewController
				controller.configureForExperienceEdit(message: message.message, imageURL: notification.imageURL, videoURL: notification.videoURL, experienceKey: messageKey)
				
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}))
			
			alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[unowned self] (_) in
				self.conversationService.deleteExperience(profileID: Auth.auth().currentUser!.uid, experienceKey: messageKey, completion: {
					self.firebaseService.deleteLivefeedNotificationForExperience(withExperienceKey: messageKey)
					self.deleteCount += 1
				})
			}))

			
			break
		case .reply:
			let conversationKey = notification.replyThreadKey!
						
			guard let messageKey = notification.messageKey else {
				self.presentErrorAlert(withMessage: "Older messages can't be edited", completion: nil)
				return
			}
			
			alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: {[unowned self] (_) in
				guard let message = try? self.livefeedService.getConversationMessageObservable(forConversationID: conversationKey, andMessageID: messageKey).value() else {
					self.presentErrorAlert(withMessage: "Try again once Reply post is fully loaded", completion: nil)
					return
				}
				
				let nav = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! CreateMessageViewController
				controller.configureForEdit(message: message.message, imageURL: message.imageURL, videoURL: nil, conversationKey: conversationKey, messageKey: messageKey)
				
				nav.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(nav, animated: true, completion: nil)
			}))
			
			alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[unowned self] (_) in
				self.conversationService.deleteMessage(conversationKey: conversationKey, messageKey: messageKey, completion: {
					self.firebaseService.deleteLivefeedNotificationForReply(withReplyThreadKey: conversationKey, andMessageKey: messageKey)
										
					self.deleteCount += 1
				})
			}))
			
			break
		case .going, .interested:
			// this should never be the case, need switch to be exhaustive
			break
		}
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	// MARK: LivefeedTableViewCellDelegate
	
	func livefeedTableViewCellSelectedProfile(_ livefeedTableViewCell: UITableViewCell) {
		guard !isForProfileView, let idx = tableView.indexPath(for: livefeedTableViewCell)?.row, let notification = notificationResultsController?.fetchedObjects?[idx] else {
			return
		}
		
		if notification.userID != authProfile?.uid || !isForProfileView {
			friendIDForProfileSegue = notification.userID
			performSegue(withIdentifier: friendProfileSegueIdentifier, sender: self)
		}
	}
	
	func livefeedTableViewCellSelectedEvent(_ livefeedTableViewCell: UITableViewCell) {
		let idx = tableView.indexPath(for: livefeedTableViewCell)!.row
		let notification = notificationResultsController!.fetchedObjects![idx]
		
		if let eventID = notification.eventID, let event = idToLoadedEvents[eventID] {
			eventForDetailSegue = event
			performSegue(withIdentifier: eventDetailsSegueIdentifier, sender: self)
		}
	}
	
	func livefeedTableViewCellSelectedInterested(_ livefeedTableViewCell: UITableViewCell) {
		guard let idx = tableView.indexPath(for: livefeedTableViewCell)?.row, let notification = notificationResultsController?.fetchedObjects?[idx], let profile = authProfile, let event = idToLoadedEvents[notification.eventID!] else {
			return
		}
		
		let goingStatus = profile.events?.going?[event.identifier]?.goingStatus() ?? .none
		let actionDateString = notificationDateFormatter.string(from: Date())
		let eventDateString = notificationDateFormatter.string(from: event.startDateTime as Date)
		let goingData = goingStatus == .interested ? nil : FirebaseProfile.Events.GoingData(actionDate: actionDateString, status: "i", eventDate: eventDateString)
		profileService.setGoingData(goingData, forEventID: event.identifier)
	}
	
	func livefeedTableViewCellSelectedGoing(_ livefeedTableViewCell: UITableViewCell) {
		guard let idx = tableView.indexPath(for: livefeedTableViewCell)?.row, let notification = notificationResultsController?.fetchedObjects?[idx], let profile = authProfile, let event = idToLoadedEvents[notification.eventID!] else {
			return
		}
		
		let goingStatus = profile.events?.going?[event.identifier]?.goingStatus() ?? .none
		let actionDateString = notificationDateFormatter.string(from: Date())
		let eventDateString = notificationDateFormatter.string(from: event.startDateTime as Date)
		let goingData = goingStatus == .going ? nil : FirebaseProfile.Events.GoingData(actionDate: actionDateString, status: "g", eventDate: eventDateString)
		profileService.setGoingData(goingData, forEventID: event.identifier)
		
	}
	
	func livefeedTableViewCellSelectedShare(_ livefeedTableViewCell: UITableViewCell) {
		guard let idx = tableView.indexPath(for: livefeedTableViewCell)?.row, let notification = notificationResultsController?.fetchedObjects?[idx] else {
			return
		}
		
		if let event = idToLoadedEvents[notification.eventID!] {
			let alert = UIAlertController(title: nil, message: "Share Event", preferredStyle: .actionSheet)
			alert.addAction(UIAlertAction(title: "Livefeed", style: .default, handler: {[unowned self] (_) in
				guard self.authProfile?.showJoined ?? true else {
					self.presentErrorAlert(withMessage: "You can't share to the Livefeed with a private account.", completion: nil)
					return
				}
				
				let nav = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! ShareViewController
				controller.event = event
				nav.modalPresentationStyle = .overFullScreen
				
				if let presentingViewController = self.navigationController?.presentingViewController {
					presentingViewController.dismiss(animated: true, completion: {
						presentingViewController.present(nav, animated: true, completion: nil)
					})
				} else {
					self.tabBarController?.present(nav, animated: true, completion: nil)
				}
			}))
			alert.addAction(UIAlertAction(title: "With a Friend", style: .default, handler: {[unowned self] (_) in
				let nav = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareFriendSelectScene") as! UINavigationController
				let controller = nav.viewControllers[0] as! ShareFriendSelectViewController
				controller.eventForShare = event
				nav.modalPresentationStyle = .overFullScreen
				
				if let presentingViewController = self.navigationController?.presentingViewController {
					presentingViewController.dismiss(animated: true, completion: {
						presentingViewController.present(nav, animated: true, completion: nil)
					})
				} else {
					self.tabBarController?.present(nav, animated: true, completion: nil)
				}
			}))
			if let urlString = event.url, let url = URL(string: urlString) {
				alert.addAction(UIAlertAction(title: "Other", style: .default, handler: {[unowned self] (_) in
					let controller = UIActivityViewController(activityItems: ["Check out this event I found using the PORTL Social Discovery mobile app. Find out more, and install PORTL for free at: https://portl.com\n\n", url], applicationActivities: nil)
					
					if let presentingViewController = self.navigationController?.presentingViewController {
						presentingViewController.dismiss(animated: true, completion: {
							presentingViewController.present(controller, animated: true, completion: nil)
						})
					} else {
						self.present(controller, animated: true, completion: nil)
					}
				}))
			}
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			present(alert, animated: true, completion: nil)
		}
	}
	
	func livefeedTableViewCellSelectedShowShareDetail(_ livefeedTableViewCell: UITableViewCell) {
		guard let idx = tableView.indexPath(for: livefeedTableViewCell)?.row, let notification = notificationResultsController?.fetchedObjects?[idx] else {
			return
		}
		showShareMessaging(forNotification: notification, andStartingSegmentIndex: 2)
	}
	
	func livefeedTableViewCell(selectedImage image: UIImage, livefeedTableViewCell: UITableViewCell) {
		guard let controller = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "ImageFullScreenViewController") as? ImageFullScreenViewController else {
			return
		}
		controller.image = image
		navigationController?.show(controller, sender: self)
	}
	
	private func showShareMessaging(forNotification notification: LivefeedNotification, andStartingSegmentIndex idx: Int) {
		let controller = UIStoryboard(name: "share", bundle: nil).instantiateViewController(withIdentifier: "ShareMessagingViewController") as! ShareMessagingViewController
		controller.livefeedNotification = notification
		controller.segmentIndex = idx
		navigationController?.pushViewController(controller, animated: true)
	}
	
	// MARK: NSFetchedResultsControllerDelegate
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == notificationResultsController {
			tableIsUpdating = true
			tableView.beginUpdates()
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		UIView.performWithoutAnimation {
			if controller == notificationResultsController {
				switch(type) {
				case .insert:
					if let notification = anObject as? LivefeedNotification, let videoURLString = notification.videoURL, let URL = URL(string: videoURLString), let messageKey = notification.messageKey {
						playbackController.videos[messageKey] = Video(hlsUrl: URL, duration: notification.videoDuration!.doubleValue)
					}
					tableView.insertRows(at: [IndexPath(row: newIndexPath!.row, section: livefeedSection)], with: .none)
					break
				case .update:
					tableView.cellForRow(at: IndexPath(row: indexPath!.row, section: livefeedSection))
					break
				case .move:
					tableView.deleteRows(at: [IndexPath(row: indexPath!.row, section: livefeedSection)], with: .none)
					tableView.insertRows(at: [IndexPath(row: newIndexPath!.row, section: livefeedSection)], with: .none)
					break
				case .delete:
					tableView.deleteRows(at: [IndexPath(row: indexPath!.row, section: livefeedSection)], with: .none)
					break
				@unknown default:
					print("ERROR: Handling unknown NSFetchedResultsChangeType...")
				}
			}
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == eventsResultsController {
			populateEventsDictionaryFromResultsController()
		} else {
			tableView.endUpdates()
			tableIsUpdating = false
		}
	}
	
	// MARK: UIScrollViewDelegate
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offsetY = scrollView.contentOffset.y
		let contentHeight = scrollView.contentSize.height
		
		let notificationCount = (notificationResultsController?.fetchedObjects?.count ?? 0) + deleteCount
		
		if offsetY > contentHeight - scrollView.frame.size.height && !requestInProgress &&  notificationCount == page * pageSize {
			page = (notificationCount / pageSize) + 1
			spinnerView.isHidden = false
			loadLivefeed()
		}
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let notification = notificationResultsController!.fetchedObjects![indexPath.row]
		switch notification.notificationType {
		case .share:
			return 420.0
		case .going, .interested:
			return 130.0
		case .community, .reply, .experience:
			return notification.imageURL != nil || notification.videoURL != nil ? 360.0 : 160.0
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		guard indexPath.section == livefeedSection else {
			return
		}
		
		let notification = notificationResultsController!.fetchedObjects![indexPath.row]
		switch notification.notificationType {
		case .community:
			guard let notification = notificationResultsController?.fetchedObjects?[indexPath.row], let messageKey = notification.messageKey else {
				return
			}
						
			messageKeyForSegue = messageKey
			eventIDForSegue = notification.eventID
			
			performSegue(withIdentifier: communitySegueIdentifier, sender: self)
			break
		case .reply, .experience:
			guard let notification = notificationResultsController?.fetchedObjects?[indexPath.row], let messageKey = notification.messageKey else {
				return
			}

			if notification.eventID == nil {
				eventIDForSegue = nil
				messageKeyForSegue = nil
				experienceIDForSegue = messageKey
				profileIDForSegue = notification.userID
				keyToHighlightForSegue = notification.messageKey

				if notification.notificationType == .reply {
					guard let profileAndMessageIDs = ConversationService.getProfileIDandExperienceKey(fromRepliesKey: notification.replyThreadKey!) else {
						return
					}
					profileIDForSegue = profileAndMessageIDs.0
					experienceIDForSegue = profileAndMessageIDs.1
				}
			} else {
				messageKeyForSegue = ConversationService.getOriginalMessageKey(fromRepliesKey: notification.replyThreadKey!)
				keyToHighlightForSegue = notification.messageKey
				eventIDForSegue = notification.eventID
			}

			performSegue(withIdentifier: communityPostDetailSegueIdentifier, sender: self)
			break

		default:
			break
		}
	}
		
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let count = notificationResultsController?.fetchedObjects?.count ?? 0
		emptyLabel?.isHidden = count > 0
		return count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return getLivefeedTableViewCell(forIndexPath: indexPath)
	}
		
	// MARK: Private
	
	private func getLivefeedTableViewCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
		let notification = notificationResultsController!.fetchedObjects![indexPath.row]
		let actionDateString = actionDateFormatter.string(from: notification.date as Date)
		var event: PortlEvent? = nil
		
		if let eventID = notification.eventID {
			event = idToLoadedEvents[eventID]
		
			if event == nil {
				if let eventObservable = idToEventsObservables[eventID] {
					eventObservable.observeOn(MainScheduler.instance)
						.subscribe(onNext: {[weak self] portlEvent in
							if portlEvent != nil {
								self?.eventLoaded(event: portlEvent)
							}
						}).disposed(by: disposeBag)
				} else {
					loadEvents {
						idToEventsObservables[eventID]!
							.observeOn(MainScheduler.instance)
							.subscribe(onNext: {[weak self] portlEvent in
								if portlEvent != nil {
									self?.eventLoaded(event: portlEvent)
								}
							}).disposed(by: disposeBag)
					}
				}
			}
		}
		
		var profile = notification.userID == authProfile?.uid ? authProfile : profileIDToProfile[notification.userID]
		
		if profile == nil && isForProfileView {
			profile = profileForProfileView
		}
		
		if profile == nil {
			livefeedService.getProfileObservable(forProfileID: notification.userID)
				.subscribe(onNext: {[weak self] profile in
					if profile != nil {
						self?.profileIDToProfile[notification.userID] = profile
						self?.profileLoaded(profile: profile)
					}
				}).disposed(by: disposeBag)
		}
		
		switch notification.notificationType {
		case .share:
			let cell = tableView.dequeue(LivefeedShareTableViewCell.self, for: indexPath)
			let conversationKey = ConversationService.getShareConversationID(fromEventID: notification.eventID!, userID: notification.userID, andActionDateString: notificationDateFormatter.string(from: notification.date as Date))
			
			if let profile = profile {
				cell.configure(forProfile: profile)
			}
			
			if let event = event {
				let myLocation = locationService.currentLocation ?? CLLocation(latitude: 0.0, longitude: 0.0)
				cell.configure(forPortlEvent: event, eventDateFormatter: eventDateFormatter, myLocation: myLocation)
			}
			
			if let conversationOverview = conversationIDToOverview[conversationKey] {
				cell.configure(forConversationOverview: conversationOverview)
			} else {
				livefeedService.getConversationObservable(forConversationID: conversationKey)
					.subscribe(onNext: {[weak self] overview in
						if overview != nil {
							self?.conversationIDToOverview[conversationKey] = overview
							self?.conversationOverviewLoaded(conversationKey: conversationKey)
						}
					}).disposed(by: disposeBag)
			}
			
			let goingObservable = livefeedService.getGoingDataObservable(forEventID: notification.eventID!)
			cell.configure(forGoingDataRx: goingObservable)
			
			cell.setActionDateString(actionDateString)
			cell.setShowHR(indexPath.row < notificationResultsController!.fetchedObjects!.count - 1)
			cell.delegate = self
			cell.overflowMenuDelegate = self
			return cell
		case .going, .interested:
			let cell = tableView.dequeue(LivefeedGoingTableViewCell.self, for: indexPath)
			let goingStatus = notification.notificationType == .going ? FirebaseProfile.EventGoingStatus.going : FirebaseProfile.EventGoingStatus.interested
			
			if let profile = profile {
				cell.configure(forProfile: profile, goingStatus: goingStatus)
			}
			
			if let event = event {
				cell.configure(forPortlEvent: event, eventDateFormatter: eventDateFormatter)
			}
			
			cell.setActionDateString(actionDateString)
			cell.setShowHR(indexPath.row < notificationResultsController!.fetchedObjects!.count - 1)
			cell.delegate = self
			return cell
		case .community, .reply, .experience:
			if notification.videoURL != nil {
				let cell = tableView.dequeue(LivefeedVideoTableViewCell.self, for: indexPath)

				if let event = event {
					cell.configure(forPortlEvent: event)
				}
				
				if let profile = profile {
					cell.configure(forProfile: profile, isExperience: notification.notificationType == .experience)
				}
				
				cell.setActionDateString(actionDateString)

				if let messageKey = notification.messageKey {
					cell.videoDelegate = self
					if let thumbURL = notification.imageURL {
						cell.thumbnailView.sd_setImage(with: URL(string: thumbURL)) { (_, error, _, _) in
							guard error == nil else {
								cell.thumbnailView.image = nil
								return
							}
						}
					}
						
					if let message = messageIDToMessage[messageKey] {
						cell.setMessage(message: message.message)
						cell.setVoteTotal(message.voteTotal)
					} else {
						cell.setMessage(message: notification.message)
						cell.setVoteTotal(notification.voteTotal?.int64Value)
						
						let completion = { (weakSelf: LivefeedListViewController?, message: FirebaseConversation.Message?, messageKey: String) in
							if message != nil {
								weakSelf?.messageIDToMessage[messageKey] = message
								// not sure why we need this here. there seems to be a problem with
								// reload rows even if it is placed within table updates
								if weakSelf?.tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
									cell.setMessage(message: message?.message)
									cell.setVoteTotal(message?.voteTotal)
								} else {
									weakSelf?.messageLoaded(messageKey: messageKey)
								}
							}
						}

						if notification.notificationType == .experience {
							livefeedService.getExperiencePostObservable(forProfileID: notification.userID, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						} else {
							let conversationKey = ConversationService.getCommunityConversationID(fromEventID: notification.eventID!)
							livefeedService.getConversationMessageObservable(forConversationID: conversationKey, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						}
					}
										
					let repliesKey: String
					if notification.notificationType == .experience {
						repliesKey = ConversationService.getRepliesConversationID(fromProfileID: notification.userID, andExperienceKey: notification.messageKey!)
					} else {
						repliesKey = ConversationService.getRepliesConversationID(fromMessageKey: messageKey)
					}

					if let conversationOverview = conversationIDToOverview[repliesKey] {
						cell.configure(forRepliesOverView: conversationOverview, isExperience: notification.notificationType == .experience)
					} else {
						livefeedService.getConversationOverviewObservable(forConversationID: repliesKey)
							.subscribe(onNext: {[weak self] overview in
								if overview != nil {
									self?.conversationIDToOverview[repliesKey] = overview
									self?.conversationOverviewLoaded(conversationKey: repliesKey)
								}
							}).disposed(by: disposeBag)
					}
				}
								
				cell.setShowHR(indexPath.row < notificationResultsController!.fetchedObjects!.count - 1)
				cell.delegate = self
				cell.overflowMenuDelegate = self

				let voteStatus = notification.notificationType == .experience ?
					profileService.getVoteStatusForExperience(profileID: notification.userID, experienceKey: notification.messageKey!)
					: profileService.getVoteStatusForConversationMessage(conversationKey: ConversationService.getCommunityConversationID(fromEventID: notification.eventID!), messageKey: notification.messageKey!)
				cell.configure(forVote: voteStatus)
				cell.voteDelegate = self
				
				return cell

			} else if notification.imageURL != nil {
				let cell = tableView.dequeue(LivefeedCommunityPhotoTableViewCell.self, for: indexPath)
				
				if let profile = profile {
					cell.configure(forProfile: profile, isExperience: notification.notificationType == .experience)
				}
				
				if let event = event {
					cell.configure(forPortlEvent: event)
				}
				
				cell.setActionDateString(actionDateString)
				
				if let messageKey = notification.messageKey {
					if let message = messageIDToMessage[messageKey] {
						cell.setMessage(message: message.message)
						cell.setVoteTotal(message.voteTotal)
					} else {
						cell.setMessage(message: notification.message)
						cell.setVoteTotal(notification.voteTotal?.int64Value)

						let completion = { (weakSelf: LivefeedListViewController?, message: FirebaseConversation.Message?, messageKey: String) in
							if message != nil {
								weakSelf?.messageIDToMessage[messageKey] = message
								
								// not sure why we need this here. there seems to be a problem with
								// reload rows even if it is placed within table updates
								if weakSelf?.tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
									cell.setMessage(message: message?.message)
									cell.setVoteTotal(message?.voteTotal)
								} else {
									weakSelf?.messageLoaded(messageKey: messageKey)
								}
							}
						}

						if notification.notificationType == .experience {
							livefeedService.getExperiencePostObservable(forProfileID: notification.userID, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						} else {
							let conversationKey = ConversationService.getCommunityConversationID(fromEventID: notification.eventID!)
							livefeedService.getConversationMessageObservable(forConversationID: conversationKey, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						}
					}
					
					cell.setImageURLString(imageURLString: notification.imageURL!)
					
					let repliesKey: String
					if notification.notificationType == .experience {
						repliesKey = ConversationService.getRepliesConversationID(fromProfileID: notification.userID, andExperienceKey: notification.messageKey!)
					} else {
						repliesKey = ConversationService.getRepliesConversationID(fromMessageKey: messageKey)
					}
					
					if let conversationOverview = conversationIDToOverview[repliesKey] {
						cell.configure(forRepliesOverView: conversationOverview, isExperience: notification.notificationType == .experience)
					} else {
						livefeedService.getConversationOverviewObservable(forConversationID: repliesKey)
							.subscribe(onNext: {[weak self] overview in
								if overview != nil {
									self?.conversationIDToOverview[repliesKey] = overview
									self?.conversationOverviewLoaded(conversationKey: repliesKey)
								}
							}).disposed(by: disposeBag)
					}
				}
								
				cell.setShowHR(indexPath.row < notificationResultsController!.fetchedObjects!.count - 1)
				cell.delegate = self
				cell.overflowMenuDelegate = self
				
				let voteStatus = notification.notificationType == .experience ?
					profileService.getVoteStatusForExperience(profileID: notification.userID, experienceKey: notification.messageKey!)
					: profileService.getVoteStatusForConversationMessage(conversationKey: ConversationService.getCommunityConversationID(fromEventID: notification.eventID!), messageKey: notification.messageKey!)
				cell.configure(forVote: voteStatus)
				cell.voteDelegate = self
				
				return cell
			} else {
				let cell = tableView.dequeue(LivefeedCommunityMessageTableViewCell.self, for: indexPath)
				cell.isReply = notification.notificationType == .reply
				cell.setActionDateString(actionDateString)
				
				let conversationKey: String
				
				if notification.notificationType == .reply {
					conversationKey = notification.replyThreadKey!
				} else if let eventID = notification.eventID {
					conversationKey = ConversationService.getCommunityConversationID(fromEventID: eventID)
				} else {
					conversationKey = ConversationService.getRepliesConversationID(fromProfileID: notification.userID, andExperienceKey: notification.messageKey!)
				}
				
				if let profile = profile {
					cell.configure(forProfile: profile, hasNoEvent: notification.eventID == nil, isReply: notification.notificationType == .reply)
				}
				
				if let event = event {
					cell.configure(forPortlEvent: event)
				}
				
				if let messageKey = notification.messageKey {
					if let message = messageIDToMessage[messageKey] {
						cell.setMessage(message: message.message)
						cell.setVoteTotal(message.voteTotal)
					} else {
						cell.setMessage(message: notification.message)
						cell.setVoteTotal(notification.voteTotal?.int64Value)

						let completion = { (weakSelf: LivefeedListViewController?, message: FirebaseConversation.Message?, messageKey: String) in
							if message != nil {
								weakSelf?.messageIDToMessage[messageKey] = message

								// not sure why we need this here. there seems to be a problem with
								// reload rows even if it is placed within table updates
								if weakSelf?.tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
									cell.setMessage(message: message?.message)
									cell.setVoteTotal(message?.voteTotal)
								} else {
									weakSelf?.messageLoaded(messageKey: messageKey)
								}
							}
						}
						
						if notification.notificationType == .experience {
							livefeedService.getExperiencePostObservable(forProfileID: notification.userID, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						} else {
							livefeedService.getConversationMessageObservable(forConversationID: conversationKey, andMessageID: messageKey)
								.subscribe(onNext: {[weak self] message in
									completion(self, message, messageKey)
								}).disposed(by: disposeBag)
						}
					}
					
					if notification.notificationType != .reply {
						let repliesKey = ConversationService.getRepliesConversationID(fromMessageKey: messageKey)
						
						if let conversationOverview = conversationIDToOverview[repliesKey] {
							cell.configure(forRepliesOverView: conversationOverview, isReply: false)
						} else {
							livefeedService.getConversationOverviewObservable(forConversationID: repliesKey)
								.subscribe(onNext: {[weak self] overview in
									if overview != nil {
										self?.conversationIDToOverview[repliesKey] = overview
										self?.conversationOverviewLoaded(conversationKey: repliesKey)
									}
								}).disposed(by: disposeBag)
						}
					} else {
						cell.configure(forRepliesOverView: nil, isReply: true)
					}
				}
				
				
				cell.delegate = self
				cell.overflowMenuDelegate = self
				cell.setShowHR(indexPath.row < notificationResultsController!.fetchedObjects!.count - 1)
				
				var voteStatus: Bool? = nil
				if notification.notificationType == .experience {
					voteStatus = profileService.getVoteStatusForExperience(profileID: notification.userID, experienceKey: notification.messageKey!)
				} else if notification.notificationType == .reply {
					voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: notification.replyThreadKey!, messageKey: notification.messageKey!)
				} else {
					voteStatus = profileService.getVoteStatusForConversationMessage(conversationKey: ConversationService.getCommunityConversationID(fromEventID: notification.eventID!), messageKey: notification.messageKey!)
				}
				
				cell.configure(forVote: voteStatus)
				cell.voteDelegate = self
				
				return cell
			}
		}
	}
	
	private func eventLoaded(event: PortlEvent?) {
		reloadVisibleRows { (notification) -> Bool in
			return notification.eventID == event?.identifier
		}
	}
	
	private func profileLoaded(profile: FirebaseProfile?) {
		reloadVisibleRows { (notification) -> Bool in
			return notification.userID == profile?.uid
		}
	}
	
	private func firebaseEventLoaded(eventID: String) {
		reloadVisibleRows { (notification) -> Bool in
			return notification.notificationType == .share && notification.eventID == eventID
		}
	}
	
	private func conversationOverviewLoaded(conversationKey: String) {
		// short circuiting should protect the force unwrap
		reloadVisibleRows { (notification) -> Bool in
			return (notification.notificationType == .share && conversationKey == ConversationService.getShareConversationID(fromEventID: notification.eventID!, userID: notification.userID, andActionDateString: self.notificationDateFormatter.string(from: notification.date as Date)))
				|| (notification.messageKey != nil && (notification.notificationType == .community || notification.notificationType == .experience) && conversationKey == ConversationService.getRepliesConversationID(fromMessageKey: notification.messageKey!))
		}
	}
	
	private func goingDataLoaded(eventID: String) {
		reloadVisibleRows { (notification) -> Bool in
			return notification.notificationType == .share && notification.eventID == eventID
		}
	}
	
	private func messageLoaded(messageKey: String) {
		reloadVisibleRows { (notification) -> Bool in
			return notification.messageKey == messageKey
		}
	}
	
	private func reloadVisibleRows(usingPredicate predicate:(LivefeedNotification) -> Bool) {
		var toReload = [IndexPath]()
		if let indexPaths = tableView.indexPathsForVisibleRows {
			for indexPath in indexPaths {
				if indexPath.section == livefeedSection, let notification = notificationResultsController?.object(at: IndexPath(row: indexPath.row, section: 0)) {
					if predicate(notification) {
						toReload.append(indexPath)
					}
				}
			}
			if !tableIsUpdating {
				UIView.performWithoutAnimation {
					tableView.reloadRows(at: toReload, with: .none)
				}
			}
		}
	}
	
	func loadLivefeed() {
		if initialLoad || profileService.liveFeedNotificationCount > 0 || (notificationResultsController?.fetchedObjects?.count ?? 0) < page * pageSize {
			initialLoad = false
			requestInProgress = true
			firebaseService.getLivefeed(forUserID: userIDForLivefeedRequest(), maxNotifications: pageSize * page, isForProfilePage: isForProfileView) { (objectID, error) in
				DispatchQueue.main.async {
					self.deleteCount = 0
					self.requestInProgress = false
					if let objectID = objectID {
						self.notificationResultsController = self.firebaseService.fetchedResultsController(forLivefeedWithObjectID: objectID, delegate: self)
					
						if !self.isForProfileView, self.authProfile?.unseenLivefeed != nil {
							if let newKeys = (self.notificationResultsController?.fetchedObjects?.map { $0.notificationKey })?.filter({ !self.keysViewed.contains($0) }) {
								self.profileService.markLivefeedNotificationsSeen(notificationKeys: newKeys)
								self.keysViewed = self.keysViewed.union(Set(newKeys))
							}
						}
					}
				
					if let videoNotifications = (self.notificationResultsController?.fetchedObjects?.filter { $0.videoURL != nil}) {
						for notification in videoNotifications {
							self.playbackController.videos[notification.messageKey!] = Video(hlsUrl: URL(string: notification.videoURL!)!, duration: notification.videoDuration!.doubleValue)
						}
					}
					
					self.loadEvents {
						self.refreshControl.endRefreshing()
						self.spinnerView.isHidden = true
						UIView.performWithoutAnimation {
							self.tableView.reloadSections(IndexSet(arrayLiteral: self.livefeedSection), with: .none)
						}
					}
				}
			}
		} else {
			self.refreshControl.endRefreshing()
		}
	}
	
	func userIDForLivefeedRequest() -> String {
		return userID
	}
	
	private func loadEvents(completion: () -> Void) {
		if let eventIDs = (self.notificationResultsController?.fetchedObjects?.compactMap { $0.eventID }) {
			self.loadEventsForIDs(eventIDs: eventIDs)
		}
		completion()
	}
	
	private func loadEventsForIDs(eventIDs: [String]) {
		eventIDs.forEach { eid in
			if self.idToEventsObservables[eid] == nil {
				self.idToEventsObservables[eid] = BehaviorSubject<PortlEvent?>(value: nil)
			}
		}
		
		self.portlService.getEvents(forIDs: eventIDs).subscribe(onNext: { _ in
			self.eventsResultsController = self.portlService.fetchedResultsController(forEventIDs: eventIDs, delegate: self)
			self.populateEventsDictionaryFromResultsController()
		}).disposed(by: disposeBag)
	}
	
	private func populateEventsDictionaryFromResultsController() {
		for event in eventsResultsController?.fetchedObjects ?? [] {
			idToLoadedEvents[event.identifier] = event
			idToEventsObservables[event.identifier]?.onNext(event)
		}
	}
	
	@IBAction func refresh() {
		initialLoad = true
		loadLivefeed()
	}
		
	@IBAction private func onPostButtonPress(_ sender: Any) {
		UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
			if let imageView = self.postButton.imageView {
				imageView.transform = self.messageYConstraint.constant == 0 ? CGAffineTransform(rotationAngle: .pi / 4) : CGAffineTransform.identity
			}
			self.messageButton.isHidden = false
			self.messageButton.layer.shadowOpacity = self.messageYConstraint.constant == 0 ? 0.8 : 0
			self.messageYConstraint.constant = self.messageYConstraint.constant == 0 ? -48 : 0
			self.cameraButton.isHidden = false
			self.cameraButton.layer.shadowOpacity = self.cameraYConstraint.constant == 0 ? 0.8 : 0
			self.cameraYConstraint.constant = self.cameraYConstraint.constant == 0 ? -96 : 0
			self.view.layoutIfNeeded()
		}, completion: { complete in
			self.messageButton.isHidden = self.messageYConstraint.constant == 0
			self.cameraButton.isHidden = self.cameraYConstraint.constant == 0
		})
	}
	
	@IBAction private func startPost(_ sender: Any) {
		onPostButtonPress(self)
		
		if sender as? UIButton == cameraButton {
			if let controller = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildPhotoMessageScene") as? UINavigationController { 
				let photoPickerViewController = controller.viewControllers[0] as! PhotoPickerViewController
				photoPickerViewController.isExperience = true
				controller.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(controller, animated: true, completion: nil)
			}
		} else if sender as? UIButton == messageButton {
			if let controller = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "BuildTextMessageScene") as? UINavigationController {
				let messageViewController = controller.viewControllers[0] as! CreateMessageViewController
				messageViewController.isExperience = true
				controller.modalPresentationStyle = .overFullScreen
				self.tabBarController?.present(controller, animated: true, completion: nil)
			}
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == friendProfileSegueIdentifier {
			let controller = segue.destination as! ProfileViewController
			controller.profileID = friendIDForProfileSegue!
			friendIDForProfileSegue = nil
			
			let backItem = UIBarButtonItem()
			backItem.tintColor = .white
			navigationItem.backBarButtonItem = backItem
		} else if segue.identifier == communityPostDetailSegueIdentifier {
			let controller = segue.destination as! CommunityRepliesViewController
			controller.originalMessageKey = messageKeyForSegue
			controller.eventID = eventIDForSegue
			controller.experienceID = experienceIDForSegue
			controller.profileID = profileIDForSegue
			controller.messageKeyToHighlight = keyToHighlightForSegue
		} else if segue.identifier == communitySegueIdentifier {
			let controller = segue.destination as! CommunityViewController
			controller.eventID = eventIDForSegue
			controller.messageKeyToHighlight = messageKeyForSegue
		} else if segue.identifier == eventDetailsSegueIdentifier {
			let controller = segue.destination as! EventDetailsViewController
			controller.event = eventForDetailSegue
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	// MARK: View Life Cycle
	
	func registerNibs() {
		tableView.registerNib(LivefeedShareTableViewCell.self)
		tableView.registerNib(LivefeedGoingTableViewCell.self)
		tableView.registerNib(LivefeedCommunityMessageTableViewCell.self)
		tableView.registerNib(LivefeedCommunityPhotoTableViewCell.self)
		tableView.registerNib(LivefeedVideoTableViewCell.self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Livefeed"
		navigationItem.hidesBackButton = true
		
		registerNibs()
		
		tableView.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		profileService.authenticatedProfile.subscribe(onNext: {[unowned self] profile in
			self.authProfile = profile
		}).disposed(by: disposeBag)
		
		cameraButton.layer.borderColor = PaletteColor.light1.cgColor
		cameraButton.layer.borderWidth = 1.0
		cameraButton.layer.cornerRadius = 8.0
		
		cameraButton.layer.shadowColor = PaletteColor.dark1.cgColor
		cameraButton.layer.shadowOpacity = 0
		cameraButton.layer.shadowRadius = 8.0
		cameraButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)
		
		messageButton.layer.borderColor = PaletteColor.light1.cgColor
		messageButton.layer.borderWidth = 1.0
		messageButton.layer.cornerRadius = 8.0
		
		messageButton.layer.shadowColor = PaletteColor.dark1.cgColor
		messageButton.layer.shadowOpacity = 0
		messageButton.layer.shadowRadius = 8.0
		messageButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)

		postButton.layer.cornerRadius = 8.0
		postButton.layer.shadowColor = PaletteColor.dark1.cgColor
		postButton.layer.shadowOpacity = 0.8
		postButton.layer.shadowRadius = 8.0
		postButton.layer.shadowOffset = CGSize(width:12.0, height:12.0)

		postButton.imageView?.clipsToBounds = false
		postButton.imageView?.contentMode = .center
		
		tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 72.0, right: 0.0)
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		
		if shouldShowLivefeed {
			loadLivefeed()
			tableView.refreshControl = refreshControl
		} else {
			tableView.refreshControl = nil
			self.spinnerView.isHidden = true
		}
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Injector.root!.inject(into: inject)
	}
	
	deinit {
		// todo: cleanup livefeed service
	}
	
	private func inject(portlService: PortlDataProviding, firebaseService: FirebaseDataProviding, dateFormatter: DateFormatterQualifier, notificationDateFormatter: FirebaseDateFormatter, eventDateFormatter: LongDateFormatterQualifier, livefeedService: LivefeedService, profileService: UserProfileService, locationService: LocationProviding, conversationService: ConversationService) {
		self.portlService = portlService
		self.firebaseService = firebaseService
		self.actionDateFormatter = dateFormatter.value
		self.notificationDateFormatter = notificationDateFormatter.value
		self.eventDateFormatter = eventDateFormatter.value
		self.profileService = profileService
		self.locationService = locationService
		self.conversationService = conversationService
		self.livefeedService = livefeedService
		playbackController = PlaybackController()
	}
	
	// MARK: Properties
	
	var profileService: UserProfileService!
	var livefeedSection: Int = 0
	var livefeedService: LivefeedService!
	var isForProfileView = false
	var profileForProfileView: FirebaseProfile?
	var shouldShowLivefeed = true
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var spinnerView: UIView!
	@IBOutlet weak var emptyLabel: UILabel?
	@IBOutlet weak var postButton: UIButton!
	@IBOutlet weak var cameraButton: UIButton!
	@IBOutlet weak var cameraYConstraint: NSLayoutConstraint!
	@IBOutlet weak var messageButton: UIButton!
	@IBOutlet weak var messageYConstraint: NSLayoutConstraint!
	
	// MARK: Properties (Private)
	
	private var initialLoad = true
	
	private var playbackController: PlaybackController!
	private var wantsFullScreen = false

	private var page = 1
	private var requestInProgress = false
	private var tableIsUpdating = false
	private let refreshControl = UIRefreshControl()
	private var deleteCount = 0
	private var keysViewed = Set<String>()
	
	private var actionDateFormatter: DateFormatter!
	private var notificationDateFormatter: DateFormatter!
	private var eventDateFormatter: DateFormatter!
	private var shortDateFormatter: DateFormatter!
	private var portlService: PortlDataProviding!
	private var locationService: LocationProviding!
	private var conversationService: ConversationService!
	private var firebaseService: FirebaseDataProviding!
	
	private var alertToShow: UIAlertController?
	private let disposeBag = DisposeBag()
	private var livefeedDisposable: Disposable?
	private var authProfile: FirebaseProfile?
	
	private var friendIDForProfileSegue: String?
	
	private var messageKeyForSegue: String?
	private var keyToHighlightForSegue: String?
	private var eventIDForSegue: String?
	private var experienceIDForSegue: String?
	private var profileIDForSegue: String?
	
	var eventForDetailSegue: PortlEvent?
	
	private var conversationIDToOverview = [String: FirebaseConversation.Overview]()
	private var messageIDToMessage = [String: FirebaseConversation.Message]()
	private var profileIDToProfile = [String: FirebaseProfile]()
	private var idToLoadedEvents = [String: PortlEvent]()
	private var idToEventsObservables = [String: BehaviorSubject<PortlEvent?>]()
	
	private var eventsResultsController: NSFetchedResultsController<PortlEvent>?
	private var notificationResultsController: NSFetchedResultsController<LivefeedNotification>?
	
	// MARK: Properties (Private Constant)
	
	private let friendProfileSegueIdentifier = "friendProfileSegue"
	private let communityPostDetailSegueIdentifier = "communityPostDetailSegue"
	private let communitySegueIdentifier = "communitySegue"
	private let eventDetailsSegueIdentifier = "eventDetailSegue"
	private let photoPostSegueIdentifier = "createPhotoPostSegue"
	private let messagePostSegueIdentifier = "createMessagePostSegue"
	
	private let userID = Auth.auth().currentUser!.uid
	private let pageSize = 50
}

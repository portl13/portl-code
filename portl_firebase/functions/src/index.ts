import * as functions from 'firebase-functions'
import * as schema from './model1_2'
import * as admin from 'firebase-admin'
import * as h from './helpers'
import { Friendship } from './model_1';

admin.initializeApp()

// Start writing Firebase Functions
// https://firebase.google.com/docs/functions/typescript

export const on_going_create = functions.database.ref('/v2/profile/{uid}/events/going/{event_id}').onCreate(async (after, context) => {
    const profile_status = after.val() as schema.ProfileGoingActionData
    const event_ref = h.get_event_ref(context.params.event_id)
    const event_going_uid_ref = event_ref.child('going').child(context.params.uid)
    const going_count_ref = event_ref.child('going_count')
    const interested_count_ref = event_ref.child('interested_count')

    const new_event_status = new schema.EventGoingStatus(profile_status.status, profile_status.action_date)

    await going_count_ref.transaction((current) => {
        const to_add = profile_status.status === 'g' ? 1 : 0
        return (current || 0) + to_add
    })

    await interested_count_ref.transaction((current) => {
        const to_add = profile_status.status === 'i' ? 1 : 0
        return (current || 0) + to_add
    })
    
    return event_going_uid_ref.set(h.to_json(new_event_status))
    .then((_) => {
        return h.update_live_feeds_for_going(context.params.uid, context.params.event_id, profile_status.status, profile_status.action_date)  
    })
    .then((_) => {
        return null
    })
})

export const on_going_delete = functions.database.ref('/v2/profile/{uid}/events/going/{event_id}').onDelete(async (before, context) => {
    const profile_status = before.val() as schema.ProfileGoingActionData
    const event_ref = h.get_event_ref(context.params.event_id)
    const event_going_uid_ref = event_ref.child('going').child(context.params.uid)
    const going_count_ref = event_ref.child('going_count')
    const interested_count_ref = event_ref.child('interested_count')

    await going_count_ref.transaction((current) => {
        const to_subtract = profile_status.status === 'g' ? 1 : 0
        return (current || 0) - to_subtract
    })

    await interested_count_ref.transaction((current) => {
        const to_subtract = profile_status.status === 'i' ? 1 : 0
        return (current || 0) - to_subtract
    })

    return event_going_uid_ref.remove()
    .then((_) => {
        return h.update_live_feeds_for_going(context.params.uid, context.params.event_id, undefined, undefined)
    })
    .then((_) => {
        return null
    })
})

export const on_going_update = functions.database.ref('/v2/profile/{uid}/events/going/{event_id}').onUpdate(async (change, context) => {
    const old_status = change.before!.val() as schema.ProfileGoingActionData

    const profile_status = change.after!.val() as schema.ProfileGoingActionData
    const event_ref = h.get_event_ref(context.params.event_id)
    const event_going_uid_ref = event_ref.child('going').child(context.params.uid)
    const going_count_ref = event_ref.child('going_count')
    const interested_count_ref = event_ref.child('interested_count')

    const new_event_status = new schema.EventGoingStatus(profile_status.status, profile_status.action_date)

    if (old_status.status !== profile_status.status) {
        await going_count_ref.transaction((current) => {
            const to_subtract = profile_status.status === 'i' ? 1 : 0
            const to_add = profile_status.status === 'g' ? 1 : 0
            return current - to_subtract + to_add
        })

        await interested_count_ref.transaction((current) => {
            const to_subtract = profile_status.status === 'g' ? 1 : 0
            const to_add = profile_status.status === 'i' ? 1 : 0
            return current - to_subtract + to_add
        })
    }

    return event_going_uid_ref.set(h.to_json(new_event_status))
    .then((_) => {
        return h.update_live_feeds_for_going(context.params.uid, context.params.event_id, profile_status.status, profile_status.action_date)  
    })
    .then((_) => {
        return null
    })
})

export const on_share_create = functions.database.ref('/v2/profile/{uid}/events/share/{action_date}').onCreate(async (after, context) => {
    const event_id = after.val()

    return h.update_live_feeds_for_share(context.params.uid, event_id, context.params.action_date)  
    .then((_) => {
        return null
    })
})

export const on_share_delete = functions.database.ref('/v2/profile/{uid}/events/share/{action_date}').onDelete(async (before, context) => {
    const event_id = before.val()

    // todo: find and remove conversation
    return h.update_live_feeds_for_share(context.params.uid, event_id, context.params.action_date, true)
    .then((_) => {
        return null
    })
})

export const on_following_artist_create = functions.database.ref('v2/profile/{uid}/following/artist/{artist_id}').onCreate(async (after, context) => {
    return h.get_artist_following_ref(context.params.artist_id, context.params.uid).set(h.to_json(true))
    .then((_) => {
        return null
    })
})

export const on_following_artist_delete = functions.database.ref('/v2/profile/{uid}/following/artist/{artist_id}').onDelete(async (before, context) => {
    return h.get_artist_following_ref(context.params.artist_id, context.params.uid).remove()
    .then((_) => {
        return null
    })
})

export const on_following_venue_create = functions.database.ref('v2/profile/{uid}/following/venue/{venue_id}').onCreate(async (after, context) => {
    return h.get_venue_following_ref(context.params.venue_id, context.params.uid).set(h.to_json(true))
    .then((_) => {
        return null
    })
})

export const on_following_venue_delete = functions.database.ref('/v2/profile/{uid}/following/venue/{venue_id}').onDelete(async (before, context) => {
    return h.get_venue_following_ref(context.params.venue_id, context.params.uid).remove()
    .then((_) => {
        return null
    })
})

export const on_conversation_message_create = functions.database.ref('/v2/conversation/{conversation_id}/messages/{message_id}').onCreate(async (after, context) => {
    const new_message_data = after.val() as schema.ConversationMessage_V2
    
    const messages_ref = h.get_conversation_messages_ref(context.params.conversation_id)
    const messages_data = await messages_ref.once("value")
    const message_count = messages_data.numChildren()
    
    const senders_ref = h.get_conversation_senders_ref(context.params.conversation_id)

    // update conversation senders
    return senders_ref.child(new_message_data.profile_id).set(new_message_data.sent)
    .then(async (_) => {
        // update conversation overview
        const senders_data = await senders_ref.once("value")
        const sender_count = senders_data.numChildren()
        const overview_ref = h.get_conversation_overview_ref(context.params.conversation_id)

        const overviewSnap = await overview_ref.once("value")
        var overview = overviewSnap.val() as schema.ConversationOverview_V2
        if (overview) {
            overview.message_count = message_count
            overview.sender_count = sender_count
            overview.last_sender = new_message_data.profile_id
            overview.last_activity = new_message_data.sent
            overview.last_message = new_message_data.message
            overview.last_image_url = new_message_data.image_url
            overview.last_message_key = context.params.message_id

            if (new_message_data.image_url && !new_message_data.video_url) {
                overview.image_count = overview.image_count + 1
            }
            if (new_message_data.message) {
                overview.comment_count = overview.comment_count + 1
            }
            if (new_message_data.video_url) {
                overview.video_count = overview.video_count + 1
            }
        } else {
            const image_count = (new_message_data.image_url && !new_message_data.video_url) ? 1 : 0
            const video_count = new_message_data.video_url ? 1 : 0
            let comment_count
            if (context.params.conversation_id.charAt(0) === 's') {
                // don't count first message in share conversation
                comment_count = 0
            } else {
                comment_count = new_message_data.message ? 1 : 0
            }
            overview = new schema.ConversationOverview_V2(new_message_data.sent, message_count, sender_count, new_message_data.profile_id, new_message_data.sent, comment_count, image_count, video_count, new_message_data.message, new_message_data.message, new_message_data.image_url, context.params.message_id)
        }

        return overview_ref.update(h.to_json(overview))
        .then(() => {
            console.log(`conversation ${context.params.conversation_id} overview updated`)
            return Promise.resolve()
        })
    })
    .then(async (_) => {
        // create sender's profile conversation data if needed
        return h.get_profile_conversation_ref(new_message_data.profile_id, context.params.conversation_id).once("value").then((snap) => {
            if (snap.exists()) {
                return Promise.resolve()
            } else {
                const profile_convo_data = new schema.ProfileConversationInfo(true, false, false)
                return h.get_profile_conversation_ref(new_message_data.profile_id, context.params.conversation_id).set(h.to_json(profile_convo_data))
            }
        })
    })
    .then(async (_) => {
        // update other senders' profile conversation data
        return h.update_profile_conversation_data_for_new_message(context.params.conversation_id, new_message_data.profile_id)
        .then(() => {
            console.log("updated profile conversation data for senders.")
            return Promise.resolve()
        })
    })
    .then(async () => {
        if (context.params.conversation_id.charAt(0) === 'c') {
            const event_id = (context.params.conversation_id as string).substring(2)
            // create livefeed notifications for community interactions
            return h.update_live_feeds_for_community(event_id, new_message_data, context.params.message_id)
        } else if (context.params.conversation_id.charAt(0) === 'r' && new_message_data.event_id) {
            return h.update_live_feeds_for_community_reply(new_message_data.event_id, new_message_data, context.params.message_id, context.params.conversation_id)
        } else if (context.params.conversation_id.charAt(0) === 'r') {
            // reply is on an experience. experience is a post with no event
            return h.update_live_feeds_for_experience_reply(new_message_data, context.params.message_id, context.params.conversation_id)
        } else {
            return Promise.resolve()
        }
    })
    .then(async () => {
        if (context.params.conversation_id.charAt(0) === 'd') {
            // special handling for direct conversation
            const splitKey = context.params.conversation_id.split("_")
            const promises: Promise<void>[] = []

            for (var element of splitKey) {
                if (element !== "d" && element !== new_message_data.profile_id) {
                    // update profile conversation data for recipient of direct conversation message, auto-unarchive

                    const recipient_id = element
                    const profile_convo_data = new schema.ProfileConversationInfo(true, true)
                    return h.get_profile_conversation_ref(recipient_id, context.params.conversation_id).set(h.to_json(profile_convo_data))
                        .then(async () => {
                            console.log(`updated profile conversation data for ${recipient_id}`)
                            // add unread message key to recipient's unread messages 

                            return h.get_profile_unread_messages_ref(recipient_id).child(context.params.message_id).set(new_message_data.sent)
                                .then(() => {
                                    console.log(`updated unread messages for ${recipient_id}`)
                                    return Promise.resolve()
                                })
                        })
                        .then(async () => {
                            // send push notifications for direct conversation message

                            const sender_profile = (await h.get_profile_ref(new_message_data.profile_id).once("value")).val() as schema.Profile_V2
                            var notification_type = "m"
                            var notification_title = `${sender_profile.username} sent you a message.`
                            var notification_body = new_message_data.message

                            if (new_message_data.image_url) {
                                notification_type = "i"
                                notification_title = `${sender_profile.username} sent you an image.`
                                notification_body = new_message_data.message || ""
                            } else if (new_message_data.event_id) {
                                notification_type = "e"
                                notification_title = `${sender_profile.username} shared an event with you.`
                                notification_body = new_message_data.event_title
                            }

                            const payload = {
                                notification: {
                                    title: notification_title,
                                    body: notification_body
                                },
                                data: {
                                    notification_type: notification_type,
                                    sender_username: sender_profile.username,
                                    conversation_id: context.params.conversation_id
                                }
                            }

                            return h.send_notification_payload(payload, recipient_id)
                        }).then(() => {
                            return null
                        })       
                }
            }
            return Promise.all(promises).then(() => {
                return null
            })
        } else {
            console.log("no notification sent for non-direct message")
            return null
        }
    })
    .catch((reason) => {
        console.log(reason)
        return null
    })
})

export const on_conversation_message_update = functions.database.ref('/v2/conversation/{conversation_id}/messages/{message_id}').onUpdate(async (change, context) => {
    const new_message_data = change.after!.val() as schema.ConversationMessage_V2
    const overview_ref = h.get_conversation_overview_ref(context.params.conversation_id)
    const overviewSnap = await overview_ref.once("value")
    var overview = overviewSnap.val() as schema.ConversationOverview_V2

    if (overview && overview.created === new_message_data.sent) {
        // update overview "first message" property if edited message is first in convo
        overview.first_message = new_message_data.message
        return overview_ref.update(h.to_json(overview))
        .then(() => {
            console.log(`conversation ${context.params.conversation_id} overview updated`)
            return Promise.resolve()
        })
        .then(() => {
            if (context.params.conversation_id.charAt(0) === 'c') {
                const event_id = (context.params.conversation_id as string).substring(2)
                // create livefeed notifications for community interactions
                return h.update_live_feeds_for_community_update(event_id, new_message_data, context.params.message_id)
            } else if (context.params.conversation_id.charAt(0) === 'r' && new_message_data.event_id) {
                // community reply
                return h.update_live_feeds_for_community_reply_update(new_message_data.event_id, new_message_data, context.params.message_id, context.params.conversation_id)
            } else if (context.params.conversation_id.charAt(0) === 'r') {
                // reply is on an experience. experience is a post with no event
                return h.update_live_feeds_for_experience_reply_update(new_message_data, context.params.message_id, context.params.conversation_id)
            } else {
                return Promise.resolve()
            }
        })
    } else {
        return null
    }
})

export const on_conversation_message_delete = functions.database.ref('/v2/conversation/{conversation_id}/messages/{message_id}').onDelete(async (before, context) => {
    const event_id = (context.params.conversation_id as string).substring(2)
    const old_message_data = before.val() as schema.ConversationMessage_V2

    const messages_ref = h.get_conversation_messages_ref(context.params.conversation_id)
    const other_user_messages_snap = await messages_ref.orderByChild("profile_id").equalTo(old_message_data.profile_id).once("value")
    const senders_ref = h.get_conversation_senders_ref(context.params.conversation_id)
    
    if (other_user_messages_snap.numChildren() === 0 && context.params.conversation_id.charAt(0) !== 'd') {
        if (context.params.conversation_id.charAt(0) !== 'd') {
            // not a direct message & user is no longer in conversation
            // remove user id from conversation senders 
            // remove from profile conversations
            await senders_ref.child(old_message_data.profile_id).remove()
            .then(async (_) => {
                console.log(`${old_message_data.profile_id} removed from senders of conversation ${context.params.conversation_id}`)
                return h.get_profile_conversation_ref(old_message_data.profile_id, context.params.conversation_id).remove()
                .then(async () => {
                    console.log(`conversation ${context.params.conversation_id} data removed from deleted sender ${old_message_data.profile_id}`)
                    return Promise.resolve()
                })
            })
        }
    }

    const overview_ref = h.get_conversation_overview_ref(context.params.conversation_id)
    const current_overview = await overview_ref.once("value").then((snap) => {return snap.val() as schema.ConversationOverview_V2})

    return messages_ref.orderByKey().limitToLast(1).once("value").then(async (snap) => {
        if (snap.exists()) {
            const message_key = Object.keys(snap.val())[0]
            // more messages still exist after deleting
            const newest_other_message = snap.child(message_key).val() as schema.ConversationMessage_V2
                    
            const sender_count = (await senders_ref.once("value")).numChildren()
            const number_images = Math.max(old_message_data.image_url && !old_message_data.video_url ? current_overview.image_count - 1 : current_overview.image_count, 0)
            const number_comments = Math.max(old_message_data.message ? current_overview.message_count - 1 : current_overview.message_count, 0)
            const number_videos = Math.max(old_message_data.video_url ? current_overview.video_count - 1 : current_overview.video_count, 0)
            // latest message was deleted, update overview accordingly
            const new_overview = new schema.ConversationOverview_V2(current_overview.created, Math.max(current_overview.message_count - 1, 0), sender_count, newest_other_message.profile_id, newest_other_message.sent, number_comments, number_images, number_videos, current_overview.first_message, newest_other_message.message, newest_other_message.image_url, newest_other_message.video_url, message_key)
            
            return overview_ref.update(h.to_json(new_overview))
            .then(async () => {
                console.log(`conversation ${context.params.conversation_id} overview updated`)
                return Promise.resolve()
            })         
        } else {
            var empty_overview = current_overview
            
            empty_overview.comment_count = 0
            empty_overview.image_count = 0
            empty_overview.video_count = 0
            empty_overview.message_count = 0
            empty_overview.first_message = undefined
            empty_overview.last_image_url = undefined
            empty_overview.last_video_url = undefined
            empty_overview.last_message = undefined
            empty_overview.sender_count = 0
            empty_overview.last_message_key = undefined

            // don't remove senders of direct messages*
            return overview_ref.update(h.to_json(empty_overview))
            .then(async () => {
                console.log(`only message deleted from direct conversation ${context.params.conversation_id} - creating empty overview`)
                return Promise.resolve()
            })         
        }
    })
    .then(async () => {
        if (context.params.conversation_id.charAt(0) === 'c') {
            // delete livefeed notifications for deleted community post
            return h.update_live_feeds_for_community(event_id, old_message_data, context.params.message_id, true)
        } else if (context.params.conversation_id.charAt(0) === 'r' && old_message_data.event_id) {
            // delete livefeed notifications for deleted community reply
            return h.update_live_feeds_for_community_reply(old_message_data.event_id, old_message_data, context.params.message_id, context.params.conversation_id, true)
        } else if (context.params.conversation_id.charAt(0) === 'r') {
            // reply is on an experience. experience is a post with no event
            return h.update_live_feeds_for_experience_reply(old_message_data, context.params.message_id, context.params.conversation_id, true)
        } else {
            return Promise.resolve()
        }
    })  
    .then(()=>{
        // save copy of deleted message
        return h.get_conversation_deleted_ref(context.params.conversation_id).child(context.params.message_id).set(h.to_json(old_message_data))
    })
    .then(async () => {
        if (context.params.conversation_id.charAt(0) === 'd') {
            // special handling for direct conversations
            // remove message key from direct conversation receiver's unread messages (if exists)

            const splitKey = context.params.conversation_id.split("_")
            const promises: Promise<any>[] = []

            for (var element of splitKey) {
                if (element !== "d" && element !== old_message_data.profile_id) {
                    const receiver_id = element
                    const unread_message_data = await h.get_profile_unread_messages_ref(receiver_id).child(context.params.message_id).once("value")
                    if (unread_message_data.exists()) {
                        promises.push(h.get_profile_unread_messages_ref(receiver_id).child(context.params.message_id).remove())
                    }
                }
            }
            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log("Receiver unread messages updated.")
                    return null
                })
            } else {
                return null
            }
        } else {
            return null
        }
    })
    .then(async () => {
        /* if message has a reply thread:
           delete each message in reply thread 
           (should cover deleting livefeed notifications too) 
        */
       
        return h.get_conversation_ref(`r_${context.params.message_id}`).child("messages").once("value").then((messages_snap) => {
            const promises: Promise<any>[] = []

            messages_snap.forEach((message) => {
                console.log(message.ref)
                promises.push(message.ref.remove())
            })
            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log("Message replies deleted.")
                    return null
                })
            } else {
                return null
            }
        })
        .then(() => {
            return null
        })
    })
    .catch((reason) => {
        console.error(reason)
    })
})

export const on_experience_create = functions.database.ref('/v2/experience/{profile_id}/{message_id}').onCreate(async (after, context) => {
    const new_experience_data = after.val() as schema.ConversationMessage_V2
    
    return h.update_live_feeds_for_experience(new_experience_data, context.params.message_id)
})

export const on_experience_update = functions.database.ref('/v2/experience/{profile_id}/{message_id}').onUpdate(async (change, context) => {
    const new_message_data = change.after!.val() as schema.ConversationMessage_V2

    return h.update_live_feeds_for_experience_update(new_message_data, context.params.message_key)
})

export const on_experience_delete = functions.database.ref('/v2/experience/{profile_id}/{message_id}').onDelete(async (before, context) => {
    const old_experience_data = before.val() as schema.ConversationMessage_V2

    return h.update_live_feeds_for_experience(old_experience_data, context.params.message_id, true)
    .then(async () => {
        /* if experience has a reply thread:
           delete each message in reply thread 
           (should cover deleting livefeed notifications too) 
        */
       
        return h.get_conversation_ref(`r_${context.params.profile_id}_${context.params.message_id}`).child("messages").once("value").then((messages_snap) => {
            const promises: Promise<any>[] = []

            messages_snap.forEach((message) => {
                console.log(message.ref)
                promises.push(message.ref.remove())
            })
            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log("Message replies deleted.")
                    return null
                })
            } else {
                return null
            }
        })
        .then(() => {
            return null
        })
    })
    .then(async () => {
        // TODO: **** REMOVE THIS AFTER SANITIZING OLD DATA BY DELETING ALL EXPERIENCES

        /* if experience has a reply thread:
           delete each message in reply thread 
           (should cover deleting livefeed notifications too) 
        */
       
        return h.get_conversation_ref(`r_${context.params.message_id}`).child("messages").once("value").then((messages_snap) => {
            const promises: Promise<any>[] = []

            messages_snap.forEach((message) => {
                console.log(message.ref)
                promises.push(message.ref.remove())
            })
            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log("Message replies deleted.")
                    return null
                })
            } else {
                return null
            }
        })
        .then(() => {
            return null
        })
    })
})

export const on_direct_conversation_archive = functions.database.ref('/v2/profile/{profile_id}/conversation/{conversation_id}/is_archived').onWrite(async (change, context) => {
    const before = change.before.val() || false
    const after = change.after.val() || false

    if (!before && after) {
        // user has archived a direct conversation, make sure no keys from this conversation are in user's unread messages
        return h.get_conversation_messages_ref(context.params.conversation_id).once("value").then(async (messages_snap) => {
            let updateObject = Object()

            Object.keys(messages_snap.exportVal()).forEach((key) => {
                updateObject[key] = null
            })
            
            return h.get_profile_unread_messages_ref(context.params.profile_id).update(h.to_json(updateObject)).then(() => {
                return null
            })
        })
    } else {
        return null
    }
})

export const on_friendship_requested = functions.database.ref('/v2/friend/{friendship_id}').onCreate(async (after, context) => {
    const friendship = after.val() as Friendship
    const user1 = friendship.user1
    const user2 = friendship.user2

    const sender_profile = (await h.get_profile_ref(user1).once("value")).val() as schema.Profile_V2
    const payload = {
        notification: {
          title: `You have a new connection request!`,
          body: `${sender_profile.username} sent you an invitation to connect.`
        },
        data: {
            notification_type: "f",
            user_id: user1
        }
    }

    return h.send_notification_payload(payload, user2)
    .then(() => {
        return null
    })  
})

export const on_friendship_accepted = functions.database.ref('/v2/friend/{friendship_id}').onUpdate(async (change) => {
    const friendship = change.after!.val() as Friendship
    const accepted_date = friendship.accepted
    const user1 = friendship.user1
    const user2 = friendship.user2

    if (friendship.accepted) {
        return h.get_profile_friends_ref(user1).child(user2).set(accepted_date)
        .then(async () => {
            return h.get_profile_friends_ref(user2).child(user1).set(accepted_date)
        })
        .then(() => {
            return null
        })
    } else {
        return null
    }
})

export const on_friendship_ended = functions.database.ref('/v2/friend/{friendship_id}').onDelete(async (before) => {
    const friendship = before.val() as Friendship
    const user1 = friendship.user1
    const user2 = friendship.user2

    return h.get_profile_friends_ref(user1).child(user2).remove()
        .then(() => {
            return h.get_profile_friends_ref(user2).child(user1).remove()
        })
        .then(() => {
            return h.update_livefeed_for_friendship_delete(user1, user2)
        })
        .then(() => {
            return h.update_livefeed_for_friendship_delete(user2, user1)
        })
        .then(() => {
            return null
        })
})


export const on_conversation_vote = functions.database.ref('/v2/profile_private/{profile_id}/votes/conversation/{conversation_key}/{message_key}').onWrite(async (change, context) => {
    const before = change.before.val()
    const after = change.after.val()
    const message_ref = h.get_conversation_message_ref(context.params.conversation_key, context.params.message_key)

    return message_ref.transaction((message) => {
        if (message === null) return message

        let message_update = message
        var upvoteDelta = 0
        var downvoteDelta = 0
    
        if (before === null) {
            // user has created a vote
            upvoteDelta = after ? 1 : 0
            downvoteDelta = 1 - upvoteDelta
        } else if (after === null) {
            // user has deleted a vote
            upvoteDelta = before ? -1 : 0
            downvoteDelta = -1 - upvoteDelta
        } else {
            // user has changed a vote
            if (before && !after) {
                upvoteDelta = -1
                downvoteDelta = 1
            } else {
                upvoteDelta = 1
                downvoteDelta = -1
            }
        }
    
        message_update.upvotes = (message.upvotes || 0) + upvoteDelta
        message_update.downvotes = (message.downvotes || 0) + downvoteDelta
        message_update.vote_total = (message.downvotes === 0 && message.upvotes === 0) ? null : message_update.upvotes - message_update.downvotes 
        return message_update
    }, (error, committed, snapshot) => {
        if (error) {
            console.log("error in transaction");
        } else if (!committed) {
            console.log("transaction not committed");
        } else {
            console.log("Transaction Committed");
        }    
    })
})

export const on_experience_vote = functions.database.ref('/v2/profile_private/{profile_id}/votes/experience/{experience_profile_id}/{experience_key}').onWrite(async (change, context) => {
    const before = change.before.val()
    const after = change.after.val()
    const message_ref = h.get_experience_ref(context.params.experience_profile_id, context.params.experience_key)

    return message_ref.transaction((message) => {
        if (message === null) return message 

        let message_update = message
        var upvoteDelta = 0
        var downvoteDelta = 0
    
        if (before === null) {
            // user has created a vote
            upvoteDelta = after ? 1 : 0
            downvoteDelta = 1 - upvoteDelta
        } else if (after === null) {
            // user has deleted a vote
            upvoteDelta = before ? -1 : 0
            downvoteDelta = -1 - upvoteDelta
        } else {
            // user has changed a vote
            if (before && !after) {
                upvoteDelta = -1
                downvoteDelta = 1
            } else {
                upvoteDelta = 1
                downvoteDelta = -1
            }
        }
    
        message_update.upvotes = (message.upvotes || 0) + upvoteDelta
        message_update.downvotes = (message.downvotes || 0) + downvoteDelta
        message_update.vote_total = (message.downvotes === 0 && message.upvotes === 0) ? null : message_update.upvotes - message_update.downvotes 
        return message_update
    }, (error, committed, snapshot) => {
        if (error) {
            console.log("error in transaction");
        } else if (!committed) {
            console.log("transaction not committed");
        } else {
            console.log("Transaction Committed");
        }    
    })
})

// auto-moderation and user management

const Vision = require('@google-cloud/vision')
const vision = new Vision()
const spawn = require('child-process-promise').spawn
const path = require('path')
const os = require('os')
const fs = require('fs')

export const blur_offensive_images = functions.storage.object().onFinalize(async object => {
    const splitPath = object.name!.split("/")
    if(splitPath[0] === "conversation") {
        if(splitPath[1].charAt(0) === "d") {
            return
        }
    }

    if(object.contentType === "video/mp4") {
        return
    }

    const image = {
        source: {imageUri: `gs://${object.bucket}/${object.name}`},
      };

      // Check the image content using the Cloud Vision API.
      const batchAnnotateImagesResponse = await vision.safeSearchDetection(image);
      const safeSearchResult = batchAnnotateImagesResponse[0].safeSearchAnnotation;
      const Likelihood = Vision.types.Likelihood;
      if (Likelihood[safeSearchResult.adult] >= Likelihood.LIKELY ||
          Likelihood[safeSearchResult.violence] >= Likelihood.LIKELY) {
        console.log('The image', object.name, 'has been detected as inappropriate.');
        return blurImage(object.name!);
      }
      console.log('The image', object.name, 'has been detected as OK.');
  })

// Blurs the given image located in the given bucket using ImageMagick.
async function blurImage(filePath: string) {
    const tempLocalFile = path.join(os.tmpdir(), path.basename(filePath));
    const bucket = admin.storage().bucket();
  
    // Download file from bucket.
    await bucket.file(filePath).download({destination: tempLocalFile});
    console.log('Image has been downloaded to', tempLocalFile);
    // Blur the image using ImageMagick.
    await spawn('convert', [tempLocalFile, '-channel', 'RGBA', '-blur', '0x24', tempLocalFile]);
    console.log('Image has been blurred');
    // Uploading the Blurred image back into the bucket.
    await bucket.upload(tempLocalFile, {destination: filePath});
    console.log('Blurred image has been uploaded to', filePath);
    // Deleting the local file to free up disk space.
    fs.unlinkSync(tempLocalFile);
    console.log('Deleted local file.');
  }

  // cleanup user-generated content after account deletion
  export const on_delete_user = functions.auth.user().onDelete(async (user) => {
    return h.get_profile_conversations_ref(user.uid).once("value").then(async (profile_conversations_snap) => {

        if (profile_conversations_snap.exists()) {
            // delete all messages (should handle livefeed notifications as well)
            const promises: Promise<any>[] = []

            const conversation_keys = Object.keys(profile_conversations_snap.val())
            // tslint:disable-next-line:prefer-for-of
            for (let index = 0; index < conversation_keys.length; index++) {
                let conversation_key = conversation_keys[index]
                let messages_snap = await h.get_conversation_messages_ref(conversation_key).orderByChild("profile_id").equalTo(user.uid).once("value")
                
                messages_snap.forEach((message_snap) => {
                    promises.push(message_snap.ref.remove())
                })
                
                // if direct conversation, need to delete conversation info from other user's profile
                if (conversation_key.charAt(0) === "d") {
                    const splitKey = conversation_key.split("_")
        
                    for (var element of splitKey) {
                        if (element !== "d" && element !== user.uid) {
                            const other_user_id = element
                            promises.push(h.get_profile_conversations_ref(other_user_id).child(conversation_key).remove())
                        }
                    }
                }
            }

            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log(`All messages for ${user.uid} deleted.`)
                    return null
                })
            } else {
                return null
            }
        } else {
            return null
        }
    })
    .then(async () => {
        // delete profile share, going, and interested (should handle updating the events and livefeeds)
        // deleting one at a time to ensure hook is called for each one (might not be necessary)
        const promises: Promise<any>[] = []

        await h.get_profile_shares_ref(user.uid).once("value").then((shares_snap) => {
            if (shares_snap.exists()) {
                shares_snap.forEach((share_snap) => {
                    promises.push(share_snap.ref.remove())
                })
            }
        })

        await h.get_profile_goings_ref(user.uid).once("value").then((goings_snap) => {
            if (goings_snap.exists()) {
                goings_snap.forEach((going_snap) => {
                    promises.push(going_snap.ref.remove())
                })
            }
        })

        await h.get_profile_interesteds_ref(user.uid).once("value").then((interesteds_snap) => {
            if (interesteds_snap.exists()) {
                interesteds_snap.forEach((interested_snap) => {
                    promises.push(interested_snap.ref.remove())
                })
            }
        })

        if (promises.length > 0) {
            return Promise.all(promises).then(() => {
                console.log(`All profile event data for ${user.uid} deleted.`)
                return null
            })
        } else {
            return null
        }   
    })
    .then(async () => {
        // delete friendships (should handle deleting livefeed objects)
        const promises: Promise<any>[] = []

        await h.get_friendships_ref().orderByChild("user1").equalTo(user.uid).once("value").then((friendships_snap) => {
            if (friendships_snap.exists()) {
                friendships_snap.forEach((friendship) => {
                    promises.push(friendship.ref.remove())
                })
            }
        })
       
        await h.get_friendships_ref().orderByChild("user2").equalTo(user.uid).once("value").then((friendships_snap) => {
            if (friendships_snap.exists()) {
                friendships_snap.forEach((friendship) => {
                    promises.push(friendship.ref.remove())
                })
            }
        })

        if (promises.length > 0) {
            return Promise.all(promises).then(() => {
                console.log(`All friend data for ${user.uid} deleted.`)
                return null
            })
        } else {
            return null
        }           
    })
    .then(async () => {
        // delete experiences
        const promises: Promise<any>[] = []
        await h.get_experiences_ref(user.uid).once("value").then((experiences_snap) => {
            if (experiences_snap.exists()) {
                experiences_snap.forEach((experience) => {
                    promises.push(experiences_snap.ref.remove())
                })
            }
        })

        if (promises.length > 0) {
            return Promise.all(promises).then(() => {
                console.log(`All experience data for ${user.uid} deleted.`)
                return null
            })
        } else {
            return null
        }           
    })
    .then(async () => {
        // delete profile

        return h.get_profile_ref(user.uid).remove().then(() => {
            console.log(`Profile for ${user.uid} deleted.`)
            return null
        })
    })
  })

  export const cleanup_deleted_users = functions.pubsub.schedule('0 0 * * *').timeZone('America/Los_Angeles').onRun((context) => {
    // this will run every day at midnight pacific time
    return h.get_delete_ref().once("value").then((ids_snap) => {
        if (ids_snap.exists()) {
            const promises: Promise<any>[] = []

            ids_snap.forEach((id_snap) => {
                const dateForDeletion = new Date(id_snap.val())
                const now = new Date()
                if (now > dateForDeletion) {
                    promises.push(admin.auth().deleteUser(id_snap.key!))
                    promises.push(id_snap.ref.remove())
                }
            })

            if (promises.length > 0) {
                return Promise.all(promises).then(() => {
                    console.log(`Scheduled user deletions completed.`)
                    return null
                })
            } else {
                return null
            }               
        } else {
            return null
        }
    })
  })

  export const search_user_profiles = functions.https.onCall(async (data, context) => {
    const text = data.text;

    // Checking attribute.
    if (!(typeof text === 'string') || text.length === 0) {
        // Throwing an HttpsError so that the client gets the error details.
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with ' +
        'one arguments "text" containing the message text to add.')
    }
    // Checking that the user is authenticated.
    if (!context.auth) {
        // Throwing an HttpsError so that the client gets the error details.
        throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while authenticated.')
    }

    // Authentication / user information is automatically added to the request.
    const uid = context.auth!.uid

    return h.search_user_profiles(text, uid).then((results) => {
        return {profiles: results}
    })
  });  

  
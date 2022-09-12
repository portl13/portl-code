import * as admin from 'firebase-admin';
import * as schema from './model1_2';
import * as Fuse from 'fuse.js';

export function to_json(some_thing: any) {
    return JSON.parse(JSON.stringify(some_thing))
}

export function get_profiles_ref() {
    return admin.database().ref('/v2/profile')
}

export function get_profile_ref(user_id: string) {
    return admin.database().ref(`/v2/profile/${user_id}`)
}

export function get_event_ref(event_id: string) {
    return admin.database().ref(`/v2/event/${event_id}`)
}

export function get_conversation_ref(conversation_id: string) {
    return admin.database().ref(`/v2/conversation/${conversation_id}`)
}

export function get_conversation_overview_ref(conversation_id: string) {
    return get_conversation_ref(conversation_id).child('overview')
}

export function get_conversation_senders_ref(conversation_id: string) {
    return get_conversation_ref(conversation_id).child('senders')
}

export function get_conversation_messages_ref(conversation_id: string) {
    return get_conversation_ref(conversation_id).child('messages')
}

export function get_conversation_message_ref(conversation_key: string, message_key: string) {
    return get_conversation_messages_ref(conversation_key).child(message_key)
}

export function get_conversation_deleted_ref(conversation_id: string) {
    return get_conversation_ref(conversation_id).child('deleted')
}

export function get_profile_conversations_ref(user_id: string) {
    return get_profile_ref(user_id).child('conversation')
}

export function get_profile_conversation_ref(user_id: string, conversation_id: string) {
    return get_profile_conversations_ref(user_id).child(`${conversation_id}`)
}

export function get_profile_unread_messages_ref(user_id: string) {
    return get_profile_ref(user_id).child(`unread_messages`)
}

export function get_profile_friends_ref(user_id: string) {
    return get_profile_ref(user_id).child('friends')
}

export function get_profile_goings_ref(user_id: string) {
    return get_profile_ref(user_id).child("events/going")
}

export function get_profile_interesteds_ref(user_id: string) {
    return get_profile_ref(user_id).child("events/interested")
}

export function get_profile_shares_ref(user_id: string) {
    return get_profile_ref(user_id).child("events/share")
}

export function get_fcm_tokens_ref(user_id: string) {
    return admin.database().ref(`/v2/device/${user_id}`)
}

export function get_friendships_ref() {
    return admin.database().ref('/v2/friend')
}

export function get_experiences_ref(user_id: string) {
    return admin.database().ref(`/v2/experience/${user_id}`)
}

export function get_experience_ref(user_id: string, message_id: string) {
    return get_experiences_ref(user_id).child(message_id)
}

export function get_delete_ref() {
    return admin.database().ref('/v2/delete')
}

export function get_following_ref() {
    return admin.database().ref('/v2/following')
}

export function get_artist_following_ref(artist_id: string, user_id: string) {
    return get_following_ref().child('artist').child(artist_id).child(user_id)
}

export function get_venue_following_ref(venue_id: string, user_id: string) {
    return get_following_ref().child('venue').child(venue_id).child(user_id)
}

export async function update_live_feeds_for_going(uid: string, event_id: string, going_status?: string, action_date?: string) {
    const profile = (await get_profile_ref(uid).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return (l.type === 'g' || l.type === 'i') && l.event_id === event_id
        }
        const livefeed_entry = (going_status && action_date) ? new schema.LivefeedObject(action_date, uid, going_status, event_id) : undefined
        return update_live_feeds(uid, predicate, livefeed_entry)
    } else {
        return
    }
}

export async function update_live_feeds_for_share(uid: string, event_id: string, action_date: string, is_delete: boolean = false) {
    const profile = (await get_profile_ref(uid).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 's' && l.event_id === event_id && l.date === action_date
        }
        const livefeed_entry = is_delete ? undefined : new schema.LivefeedObject(action_date, uid, 's', event_id)
        return update_live_feeds(uid, predicate, livefeed_entry, false)
    } else {
        return
    }
}

export async function update_live_feeds_for_community(event_id: string, message_data: schema.ConversationMessage_V2, message_key: string, is_delete: boolean = false) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'c' && l.event_id === event_id && l.date === message_data.sent
        }
        const livefeed_entry = is_delete ? undefined : new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'c', event_id, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key)
        return update_live_feeds(message_data.profile_id, predicate, livefeed_entry, false).then(() => {
            console.log("livefeeds updated for community action")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_community_update(event_id: string, message_data: schema.ConversationMessage_V2, message_key: string) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'c' && l.event_id === event_id && l.date === message_data.sent
        }
        const livefeed_entry = new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'c', event_id, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, undefined, message_data.upvotes, message_data.downvotes, message_data.vote_total)

        return update_livefeeds_for_message_update(profile.uid, predicate, livefeed_entry).then(() => {
            console.log("livefeeds updated for community message update")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_experience(message_data: schema.ConversationMessage_V2, message_key: string, is_delete: boolean = false) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'e' && l.message_key === message_key
        }
        const livefeed_entry = is_delete ? undefined : new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'e', undefined, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key)
        return update_live_feeds(message_data.profile_id, predicate, livefeed_entry, false).then(() => {
            console.log("livefeeds updated for experience action")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_experience_update(message_data: schema.ConversationMessage_V2, message_key: string) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'e' && l.message_key === message_key
        }
        const livefeed_entry = new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'e', undefined, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, undefined, message_data.upvotes, message_data.downvotes, message_data.vote_total)

        return update_livefeeds_for_message_update(profile.uid, predicate, livefeed_entry).then(() => {
            console.log("livefeeds updated for experience update")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_community_reply(event_id: string, message_data: schema.ConversationMessage_V2, message_key: string, reply_thread_key: string, is_delete: boolean = false) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'r' && l.event_id === event_id && l.date === message_data.sent
        }
        const livefeed_entry = is_delete ? undefined : new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'r', event_id, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, reply_thread_key)
        return update_live_feeds(message_data.profile_id, predicate, livefeed_entry, false).then(() => {
            console.log("livefeeds updated for community reply action")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_community_reply_update(event_id: string, message_data: schema.ConversationMessage_V2, message_key: string, reply_thread_key: string) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'r' && l.event_id === event_id && l.date === message_data.sent
        }
        const livefeed_entry = new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'r', event_id, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, reply_thread_key, message_data.upvotes, message_data.downvotes, message_data.vote_total)

        return update_livefeeds_for_message_update(profile.uid, predicate, livefeed_entry).then(() => {
            console.log("livefeeds updated for community reply update")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_experience_reply(message_data: schema.ConversationMessage_V2, message_key: string, reply_thread_key: string, is_delete: boolean = false) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'r' && l.message_key === message_key
        }
        const livefeed_entry = is_delete ? undefined : new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'r', undefined, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, reply_thread_key)
        return update_live_feeds(message_data.profile_id, predicate, livefeed_entry, false).then(() => {
            console.log("livefeeds updated for community reply action")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

export async function update_live_feeds_for_experience_reply_update(message_data: schema.ConversationMessage_V2, message_key: string, reply_thread_key: string) {
    const profile = (await get_profile_ref(message_data.profile_id).once("value")).val() as schema.Profile_V2
    if (profile && profile.show_joined !== false) {
        const predicate = (l: schema.LivefeedObject) => {
            return l.type === 'r' && l.message_key === message_key
        }
        const livefeed_entry = new schema.LivefeedObject(message_data.sent, message_data.profile_id, 'r', undefined, message_data.message, message_data.image_url, message_data.video_url, message_data.video_duration, message_key, reply_thread_key, message_data.upvotes, message_data.downvotes, message_data.vote_total)

        return update_livefeeds_for_message_update(profile.uid, predicate, livefeed_entry).then(() => {
            console.log("livefeeds updated for experience reply update")
            return Promise.resolve()
        })
    } else {
        return Promise.resolve()
    }
}

function get_livefeed_ref(user_id: string) {
    return admin.database().ref(`/v2/livefeed/${user_id}`)
}

function get_unseen_livefeed_ref(user_id: string) {
    return get_profile_ref(user_id).child('unseen_livefeed')
}

async function update_live_feeds(profile_id: string, predicate: (l: schema.LivefeedObject) => boolean, livefeed_entry?: schema.LivefeedObject, unique_in_feed: boolean = true) {
    
    async function delete_old_entry(user_id: string) {
        const livefeed_ref = get_livefeed_ref(user_id)

        return livefeed_ref.orderByChild("profile_id").equalTo(profile_id).once("value").then((snapshot) => {
            const entriesPromises: Promise<void>[] = []

            snapshot.forEach((entry_snap) => {
                if (entry_snap.exists()) {
                    const entry = entry_snap.val() as schema.LivefeedObject
                    if (predicate(entry)) {
                        entriesPromises.push(
                            get_livefeed_ref(user_id).child(entry_snap.key!).remove().then((_) => {
                                return get_unseen_livefeed_ref(user_id).child(entry_snap.key!).remove()
                            })
                        )
                    }
                }
            })
            return Promise.all(entriesPromises)
        })
    }

    async function push_new_entry(user_id: string, to_push: schema.LivefeedObject) {        
        return get_livefeed_ref(user_id).push().then((push_ref) => {
            return push_ref.set(to_json(to_push)).then(() => {
                return get_unseen_livefeed_ref(user_id).child(push_ref.key!).set(to_push.date)
            })
        })
    }

    return get_profile_friends_ref(profile_id).once("value").then((snapshot) => {
        const friend_promises: Promise<void>[] = []

        snapshot.forEach((friend) => {
            if (unique_in_feed || !livefeed_entry) {
                friend_promises.push( 
                    delete_old_entry(friend.key!).then((_) => {
                        if (livefeed_entry) {
                            return push_new_entry(friend.key!, livefeed_entry)
                        }
                        return Promise.resolve()
                    })
                )
            } else if (livefeed_entry) {
                friend_promises.push(
                    push_new_entry(friend.key!, livefeed_entry)
                )
            }
        })

        if (unique_in_feed || !livefeed_entry) {
            friend_promises.push( 
                delete_old_entry(profile_id).then((_) => {
                    if (livefeed_entry) {
                        return push_new_entry(profile_id, livefeed_entry)
                    } else {
                        return Promise.resolve()
                    }
                })
            )
        } else if (livefeed_entry) {
            friend_promises.push(
                push_new_entry(profile_id, livefeed_entry)
            )
        }

        return Promise.all(friend_promises)
    })
}

async function update_livefeeds_for_message_update(profile_id: string, predicate: (l: schema.LivefeedObject) => boolean, livefeed_entry: schema.LivefeedObject) {

    async function update_old_entry(user_id: string, update: schema.LivefeedObject) {
        const livefeed_ref = get_livefeed_ref(user_id)

        return livefeed_ref.orderByChild("profile_id").equalTo(profile_id).once("value").then((snapshot) => {
            const entriesPromises: Promise<void>[] = []

            snapshot.forEach((entry_snap) => {
                if (entry_snap.exists()) {
                    const entry = entry_snap.val() as schema.LivefeedObject
                    if (predicate(entry)) {
                        entriesPromises.push(
                            get_livefeed_ref(user_id).child(entry_snap.key!).set(to_json(update))
                        )
                    }
                }
            })
            return Promise.all(entriesPromises)
        })
    }

    return get_profile_friends_ref(profile_id).once("value").then((snapshot) => {
        const friend_promises: Promise<void>[] = []

        snapshot.forEach((friend) => {
                friend_promises.push(
                    update_old_entry(friend.key!, livefeed_entry)
                    .then(() => {
                       return Promise.resolve()
                    })
                )
        })

        friend_promises.push( 
            update_old_entry(profile_id, livefeed_entry)
            .then(() => {
                return Promise.resolve()
             })
          )

        return Promise.all(friend_promises)
    })

}

export async function update_livefeed_for_friendship_delete(friend_id_1: string, friend_id_2: string) {
    return get_livefeed_ref(friend_id_1).orderByChild("profile_id").equalTo(friend_id_2).once("value").then(async (livefeed_objects_snap) => {
        const promises: Promise<void>[] = []

        livefeed_objects_snap.forEach((object_snap) => {
            promises.push(get_unseen_livefeed_ref(friend_id_1).child(object_snap.key!).remove())
            promises.push(get_livefeed_ref(friend_id_1).child(object_snap.key!).remove())
        })

        return Promise.all(promises)
    })
}

export async function update_profile_conversation_data_for_new_message(conversation_id: string, posted_by: string) {
    return get_conversation_senders_ref(conversation_id).once("value").then(async (senders_snap) => {
        const sender_promises: Promise<void>[] = []

        senders_snap.forEach((sender) => {
            if (sender.key! !== posted_by) {
                sender_promises.push(
                    get_profile_conversation_ref(sender.key!, conversation_id).child('has_new').set(to_json(true))
                )
            }
        })

        return Promise.all(sender_promises)
    })
}

export async function send_notification_payload(payload: Object, user_id: string) {
    const tokens_snap = await get_fcm_tokens_ref(user_id).once("value")
    if (!tokens_snap.hasChildren()) {
        console.log('There are no notification tokens to send to.')
        return Promise.resolve()
    }

    const tokens = Object.keys(tokens_snap.val())

    return admin.messaging().sendToDevice(tokens, payload).then(async (response) => {
        console.log(`Notification for userId ${user_id} sent to tokens: ${tokens}`)

        const tokens_to_remove: Promise<void>[] = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup old invalid tokens.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokens_to_remove.push(tokens_snap.ref.child(tokens[index]).remove())
                }
            }
        })

        if (tokens_to_remove.length > 0) {
            return Promise.all(tokens_to_remove).then(() => {
                console.log("Invalid tokens removed")
                return Promise.resolve()
            })
        } else {
            return Promise.resolve()
        }
    })
}

export async function search_user_profiles(query_string: string, user_id: string) {
    return get_profiles_ref().orderByChild("username").once("value").then((profiles_snap) => {
        const profiles = profiles_snap.val() as schema.Profiles_V2

        let values = Object.values(profiles).filter(function(profile) {
            return profile.uid !== user_id
        })

        var options = {
            threshold: 0.6,
            keys: [{
              name: 'first_last',
              weight: 0.5
            }, {
              name: 'username',
              weight: 0.5
            }]
          }
    
          var fuse = new Fuse(values, options)
          
          return fuse.search(query_string)
    })
}

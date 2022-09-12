import * as model_1 from "./model_1";

export class ProfileEventsActions_V2 {
    [event_id: string]: ProfileEventActionData
}

export class ProfileEventsGoing_V2 {
    [event_id: string]: ProfileGoingActionData
}

export class ProfileEventsShare_V2 {
    // action_date -> event_id
    [action_date: string]: string
}

export class ProfileEventActionData {
    action_date: string
    event_date?: string

    constructor(action_date: string, event_date?: string) {
        this.action_date = action_date
        this.event_date = event_date
    }
}

export class ProfileGoingActionData extends ProfileEventActionData {
    status: string

    constructor(action_date: string, status: string, event_date?: string) {
        super(action_date, event_date)
        this.status = status
    }
}

export class EventIdsToDate {
    [event_id: string]: string
}

export class ProfileEvents_V2 {
    going?: ProfileEventsGoing_V2
    favorite?: ProfileEventsActions_V2
    share?: ProfileEventsShare_V2

    constructor(going?: ProfileEventsGoing_V2, favorite?: ProfileEventsActions_V2, share?: ProfileEventsShare_V2) {
        this.going = going
        this.favorite = favorite
        this.share = share
    }
}

export class LivefeedObject {
    date: string
    profile_id: string
    // type: s(hare), g(oing), i(nterested), c(ommunity), r(eply), e(xperience)
    type: string
    event_id?: string
    message?: string
    image_url?: string
    message_key?: string
    reply_thread_key?: string
    video_url?: string
    video_duration?: number
    upvotes?: number
    downvotes?: number
    vote_total?: number

    constructor(date: string, profile_id: string, type: string, event_id?: string, message?: string, image_url?: string, video_url?: string, video_duration?:number, message_key?: string, reply_thread_key?: string, upvotes?: number, downvotes?: number, vote_total?: number) {
        this.date = date
        this.profile_id = profile_id
        this.type = type
        this.event_id = event_id
        this.message = message
        this.image_url = image_url
        this.video_url = video_url
        this.video_duration = video_duration
        this.message_key = message_key
        this.reply_thread_key = reply_thread_key
        this.upvotes = upvotes
        this.downvotes = downvotes
        this.vote_total = vote_total
    }
}

export class ProfileLivefeed {
    [auto_id: string]:  LivefeedObject
}

export class UnseenLivefeed {
    [livefeed_id: string]: string
}

export class ProfileConversationInfo {
    notification: boolean
    has_new: boolean
    last_seen?: string
    is_archived?: boolean

    constructor(notification: boolean, has_new: boolean, is_archived?: boolean) {
        this.notification = notification
        this.has_new = has_new
    }
}

export class ProfileConversations {
    [conversation_id: string]: ProfileConversationInfo
}

export class Profile_V2 {
    avatar?: string
    bio?: string
    birth_date?: string
    conversation?: ProfileConversations
    created: string
    email: string
    events?: ProfileEvents_V2
    friends?: ProfileIdsToDate
    first_last: string
    first_name?: string
    from_guest?: string
    gender?: string
    interests?: Array<model_1.ProfileInterest>
    last_name?: string
    location: string
    show_joined?: boolean
    uid: string
    unseen_livefeed?: UnseenLivefeed
    username: string
    username_d: string
    website?: string
    zipcode?: string

    constructor(birth_date: string, created: string, email: string, first_last: string, location: string, uid: string, username: string, username_d: string, bio?: string, events?: ProfileEvents_V2, first_name?: string, friends?: ProfileIdsToDate, from_guest?: string, gender?: string, interests?: Array<model_1.ProfileInterest>, last_name?: string, show_joined?: string, unseen_livefeed?: UnseenLivefeed, website?: string, zipcode?: string, conversation?: ProfileConversations, avatar?: string) {
        this.avatar = avatar
        this.bio = bio
        this.birth_date = birth_date
        this.created = created
        this.conversation = conversation
        this.email = email
        this.events = events
        this.friends = friends
        this.first_last = first_last
        this.first_name = first_name
        this.from_guest = from_guest
        this.gender = gender
        this.interests = interests
        this.last_name = last_name
        this.location = location
        this.show_joined = show_joined === "true"
        this.uid = uid
        this.unseen_livefeed = unseen_livefeed
        this.username = username
        this.username_d = username_d
        this.website = website
        this.zipcode = zipcode
    }
}

export class Profiles_V2 {
    [uid: string]: Profile_V2
}

export class Votes {
    [message_id: string]: boolean
}

export class ConversationVotes {
    [conversation_id: string]: Votes
}

export class ExperienceVotes {
    [profile_id: string]: Votes
}

export class ProfileVotes {
    conversation?: ConversationVotes
    experience?: ExperienceVotes
}

class ProfilePrivate {
    votes?: ProfileVotes
}

export class ProfilesPrivate {
    [uid: string]: ProfilePrivate
}

export class EventGoingStatus {
    // status: g(oing), i(interested)
    status: string
    date: string

    constructor(status: string, date: string) {
        this.status = status
        this.date = date
    }
}

export class EventGoing {
    [profile_id: string]: EventGoingStatus
}

export class ProfileIdsToDate {
    [profile_id: string]: string
}

export class ConversationMessage_V2 {
    profile_id: string
    sent: string
    message?: string
    is_html?: boolean
    image_url?: string
    image_height?: number
    image_width?: number
    video_url?: string
    video_duration?: number
    event_id?: string
    event_title?: string
    upvotes?: number
    downvotes?: number
    vote_total?: number

    constructor(profile_id: string, sent: string) {
        this.profile_id = profile_id
        this.sent = sent
    }
}

export class ConversationMessages_V2 {
    [auto_id: string]: ConversationMessage_V2
}

export class ConversationSenders_V2 {
    // profile_id -> date
    [profile_id: string]: string 
}

export class ConversationOverview_V2 {
    message_count: number
    sender_count: number
    comment_count: number
    image_count: number
    video_count: number
    first_message?: string
    last_message?: string
    last_image_url?: string
    last_video_url?: string
    last_sender: string
    last_activity: string
    last_message_key?: string
    created: string

    constructor(created: string, message_count: number, sender_count: number, last_sender: string, last_activity: string, comment_count: number, image_count: number, video_count: number, first_message?: string, last_message?: string, last_image_url?: string, last_video_url?: string, last_message_key?: string) {
        this.message_count = message_count
        this.sender_count = sender_count
        this.last_sender = last_sender
        this.last_activity = last_activity
        this.last_message = last_message
        this.last_image_url = last_image_url
        this.last_video_url = last_video_url
        this.comment_count = comment_count
        this.image_count = image_count
        this.video_count = video_count
        this.first_message = first_message
        this.created = created
        this.last_message_key = last_message_key
    }
}

export class Conversation_V2 {
    senders: ConversationSenders_V2
    overview: ConversationOverview_V2
    messages: ConversationMessages_V2

    constructor(senders: ConversationSenders_V2, overview: ConversationOverview_V2, messages: ConversationMessages_V2) {
        this.senders = senders
        this.overview = overview
        this.messages = messages
    }
}

export class Conversations_V2 {
    /*
    conversation keys
    =======
    type- c(ommunity), d(irect), s(hare), r(eply)

    community - c_eid
    direct - d_pid_pid (pids alphabetical)
    share - s_eid_pid_adate (adate = action date)
    replies - r_mid (mid = message id)
    */
    [conversation_key: string]: Conversation_V2
}

export class Event_V2 {
    going?: EventGoing
    going_count?: number
    interested_count?: number
}

export class Events_V2 {
    [event_id: string]: Event_V2
}

export class Livefeed_V2 {
    [profile_id: string] : ProfileLivefeed
}

export class DataModelV2 {
    device: model_1.Devices
    friend: model_1.Friends
    event: Events_V2
    profile: Profiles_V2
    conversation: Conversations_V2
    livefeed: Livefeed_V2

    constructor(event: Events_V2, profile: Profiles_V2, conversation: Conversations_V2, device: model_1.Devices, friend: model_1.Friends, livefeed: Livefeed_V2) {
        this.event = event
        this.profile = profile
        this.conversation = conversation
        this.device = device
        this.friend = friend
        this.livefeed = livefeed
    }
}

export class DataModelV1_2 implements model_1.DataModelV1 {
    device: model_1.Devices
    event: model_1.Events
    friend: model_1.Friends
    message: model_1.Conversations
    notification: model_1.UserNotifications
    profile: model_1.Profiles
    room: model_1.RoomProfiles
    shared_event: model_1.ShareProfiles
    schema: model_1.Schema
    v2: DataModelV2

    constructor(device: model_1.Devices, event: model_1.Events, friend: model_1.Friends, message: model_1.Conversations, notification: model_1.UserNotifications, profile: model_1.Profiles, room: model_1.RoomProfiles, shared_event: model_1.ShareProfiles) {
        this.device = device
        this.event = event
        this.friend = friend
        this.message = message
        this.notification = notification
        this.profile = profile
        this.room = room
        this.shared_event = shared_event
        
        var conversationsV2 = new Conversations_V2()
        for (var conversation_key in message) {
            const new_messages = new ConversationMessages_V2()
            const new_senders = new ConversationSenders_V2()

            if (conversation_key.startsWith("em_")) {
                const new_key = `c_${conversation_key.substring(3)}`
                const convo = message[conversation_key] as model_1.ConversationOverview
                const new_message_count = convo.messages ? Object.keys(convo.messages).length : 0
                const new_sender_count = convo.senders ? Object.keys(convo.senders).length : 0

                for (var c_message_key in convo.messages) {
                    const old_message = convo.messages![c_message_key] as model_1.ConversationMessage
                    const new_message = new ConversationMessage_V2(old_message.sender, old_message.sent)
                    new_message.message = old_message.msg
                    new_message.is_html = false
                    new_messages[c_message_key] = new_message
                }

                const new_overview = new ConversationOverview_V2("", new_message_count, new_sender_count, convo.lastinfo!.last_sender, convo.lastinfo!.last_sent, new_message_count, 0, 0, undefined, convo.lastinfo!.last_message)

                for (var c_sender_key in convo.senders) {
                    new_senders[c_sender_key] = "12-31-1999 23:59:59 PST"
                }

                const new_convo = new Conversation_V2(new_senders, new_overview, new_messages)

                conversationsV2[new_key] = new_convo
            } else {
                const member_ids = conversation_key.substring(3).split("___")
                const member_id = member_ids[0]
                const other_member_id = member_ids[1]
                const sorted_ids = [member_id, other_member_id].sort()
                const new_key = `d_${sorted_ids[0]}_${sorted_ids[1]}`

                new_senders[member_id] = "12-31-1999 23:59:59 PST"
                new_senders[other_member_id] = "12-31-1999 23:59:59 PST"

                const convo = message[conversation_key] as model_1.PrivateConversation
                const new_message_count = Object.keys(convo).length

                var new_latest_sender, new_latest_message, new_last_action;

                var senders: string[] = []

                var created = null

                for (var d_message_key in convo) {
                    if (!created) {
                        created = convo[d_message_key].sent
                    }

                    const old_message = convo[d_message_key] as model_1.PrivateMessage
                    const new_message = new ConversationMessage_V2(old_message.sender, old_message.sent)
                    new_message.message = old_message.msg
                    new_message.is_html = false
                    new_messages[d_message_key] = new_message
                    if (!new_last_action || new_last_action < old_message.sent) {
                        new_last_action = old_message.sent
                        new_latest_sender = old_message.sender
                        new_latest_message = old_message.msg
                    }
                    if (senders.indexOf(old_message.sender) < 0) {
                        senders.push(old_message.sender)
                    }
                }

                const new_overview = new ConversationOverview_V2(created!, new_message_count, senders.length, new_latest_sender || "", new_last_action || "", new_message_count, 0, 0, undefined, new_latest_message)

                const new_convo = new Conversation_V2(new_senders, new_overview, new_messages)

                conversationsV2[new_key] = new_convo
            }
        }

        var eventsV2 = new Events_V2()

        for (var event_id in event) {
            var eventV2 = new Event_V2()

            let members = event[event_id].members
            let going = new EventGoing()
            var going_count = 0
            for (var m_profile_id in members) {
                going[m_profile_id] = new EventGoingStatus("g", members[m_profile_id]!)
                going_count++
            }
            
            eventV2.going = going
            eventV2.going_count = going_count
            
            eventsV2[event_id] = eventV2
        }

        var livefeed_V2 = new Livefeed_V2()

        var profilesV2 = new Profiles_V2()
        for(var p_profile_id in profile) {
            let old = profile[p_profile_id]

            let old_going = old.events
            var new_going = new ProfileEventsGoing_V2()
            for (var g_event_id in old_going) {
                new_going[g_event_id] = new ProfileGoingActionData(old_going[g_event_id]!, "g")
            }

            var new_share = new ProfileEventsShare_V2()
            for (var p_profile_key_pair in shared_event) {
                let share = (shared_event[p_profile_key_pair])
                for (var s_event_id in share) {
                    if (share[s_event_id].sender === p_profile_id) {
                        new_share[share[s_event_id].shared] = s_event_id
                    }
                }
            }

            var new_favorite = new ProfileEventsActions_V2()
            for (var f_event_id in profile[p_profile_id].favorites) {
                let favorite_data = profile[p_profile_id].favorites![f_event_id]
                let new_favorite_data = new ProfileEventActionData(favorite_data)
                new_favorite[f_event_id] = new_favorite_data
            }

            let new_profile_events = new ProfileEvents_V2(new_going, new_favorite, new_share)

            var friends = new ProfileIdsToDate()
            for (var f_auto_id in friend) {
                let friendship = friend[f_auto_id]
                if (friendship.accepted && (friendship.user1 === p_profile_id || friendship.user2 === p_profile_id)) {
                    friends[friendship.user1 === p_profile_id ? friendship.user2 : friendship.user1] = friendship.accepted
                }
            }

            var livefeed = new ProfileLivefeed()
            var unseen_livefeed = new UnseenLivefeed()

            var old_notifications = notification[p_profile_id]
            for (var n_auto_id in old_notifications) {
                let old_notification = old_notifications[n_auto_id]
                let object_type = old_notification.type === 106 ? "g" : "s"
                let livefeed_object = new LivefeedObject(old_notification.created, old_notification.sender, object_type, old_notification.extra.event.key)
                livefeed[n_auto_id] = livefeed_object
                unseen_livefeed[n_auto_id] = old_notification.created
            }

            var conversations = new ProfileConversations()
            for (var p_conversation_key in conversationsV2) {
                if (p_conversation_key.startsWith("em_")) {
                    const p_senders = (conversationsV2[p_conversation_key] as Conversation_V2).senders
                    if(p_senders && Object.keys(p_senders).indexOf(p_profile_id) > 0) {
                        const e_info = new ProfileConversationInfo(true, false)
                        conversations[p_conversation_key] = e_info
                    } 
                } else if (p_conversation_key.includes(p_profile_id)) {
                    const d_info = new ProfileConversationInfo(true, false)
                    conversations[p_conversation_key] = d_info
                }
            }

            livefeed_V2[p_profile_id] = livefeed

            var profileV2 = new Profile_V2(old.birth_date, old.created, old.email, old.first_last, old.location, old.uid, old.username, old.username_d, old.bio, new_profile_events, old.first_name, friends, old.from_guest, old.gender, old.interests, old.last_name, old.showJoined, unseen_livefeed, old.website, old.zipcode, conversations, old.avatar)

            profilesV2[p_profile_id] = profileV2
        }

        this.schema = new model_1.Schema("2018-04-01 00:00:00 PST", 2)
        this.v2 = new DataModelV2(eventsV2, profilesV2, conversationsV2, device, friend, livefeed_V2)
    } 
}

// devices info

export interface DeviceInfo {
    device: string
    lat: number
    lng: number
    model: string
    token: string
    type: string
}

export interface UserDevice {
    [autoKey: string]: DeviceInfo
}

export interface Devices {
    [profile_id: string]: UserDevice
}

export interface ProfileIdsWithDate {
    [profile_id: string] : string
}

// events

export interface EventInfo {
    members: ProfileIdsWithDate
}

export interface Events {
    [event_id: string]: EventInfo
} 

// friends

export interface Friendship {
    accepted?: string
    invited: string
    status: string
    user1: string
    user2: string
}

export interface Friends {
    [auto_key: string]: Friendship
}

// messages

export interface ConversationLatest {
    last_message: string
    last_sender: string
    last_sender_avatar: string
    last_sender_name: string
    last_sent: string
}

export interface ConversationMessage {
    msg: string
    sender: string
    sent: string
}

export interface ConversationMessages {
    [auto_key: string]: ConversationMessage
}

export interface SenderInfo {
    avatar: string
    name: string
}

export interface ConversationSenders {
    [profile_id: string]: SenderInfo
}

export interface SettingInfo {
    last_sent: string
    notification: boolean
    saved: boolean
}

export interface ConversationSettings {
    [profile_id: string]: SettingInfo
}

export interface ConversationOverview {
    lastinfo?: ConversationLatest
    messages?: ConversationMessages
    senders?: ConversationSenders
}

export interface PrivateMessage {
    msg: string
    sender: string
    sent: string
    [read_by: string]: string
}

export interface PrivateConversation {
    [auto_key: string]: PrivateMessage
}

export interface Conversations {
    [key: string]: PrivateConversation | ConversationOverview
}

// notification

export interface NotificationExtraEvent {
    image?: string
    key: string
    title: string
}

export interface NotificationExtraFrom {
    avatar: string
    name: string
    uid: string
}

export interface NotificationExtra {
    event: NotificationExtraEvent
    from: NotificationExtraFrom
}

export interface PortlNotification {
    created: string
    extra: NotificationExtra
    message: string
    read: boolean
    receiver: string
    sender: string
    type: number
}

export interface NotificationList {
    [auto_id: string]: PortlNotification
}

export interface UserNotifications {
    [receiver_profile_id: string]: NotificationList
}

// profiles

export interface ProfileInterest {
    [key: string]: boolean
}

export interface EventIdsWithDates {
    [event_id: string]: string
}

export interface Profile {
    avatar?: string
    bio?: string
    birth_date: string
    created: string
    email: string
    events?: EventIdsWithDates
    favorites?: EventIdsWithDates
    first_last: string
    first_name: string
    from_guest: string
    gender: string
    interests?: Array<ProfileInterest>
    last_name: string
    location: string
    shared: EventIdsWithDates
    showJoined?: string
    uid: string
    username: string
    username_d: string
    website?: string
    zipcode: string
}

export interface Profiles {
    [profile_id: string]: Profile
}

// message 'rooms'

export interface Room {
    last_message: string
    last_notification: string
    last_read?: string
    last_sender: string
    last_sender_avatar: string
    last_sender_name?: string
    last_sent: string
    opened?: boolean
    picture: string
    title: string
    unread: number
}

export interface UserRoom {
    [combo_id: string]: Room
}

export interface RoomProfiles {
    [profile_id: string]: UserRoom
}

// shares

export interface Share {
    event_key: string
    sender: string
    shared: string
    start: string
    title: string
    to: string
    venue: string
}

export interface EventShares {
    [event_id: string]: Share
}

export interface ShareProfiles {
    [profile_key_pair: string]: EventShares
}

export class Schema {
    deprecation_date: string
    version: Number

    constructor(deprecation_date: string, version: Number) {
        this.deprecation_date = deprecation_date
        this.version = version
    }
}

export interface DataModelV1 {
    device: Devices
    event: Events
    friend: Friends
    message: Conversations
    notification: UserNotifications
    profile: Profiles
    room: RoomProfiles
    shared_event: ShareProfiles
    schema: Schema
}

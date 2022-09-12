import { Event } from '../events/event.type';
import { artists } from './artists-data';
import { venues } from './venues-data';

export const events: Event[] = [
  {
    title: 'Event 1',
    artist: artists[0],
    venue: venues[0],
    timezone: 'America/Los_Angeles',
    startDateTime: 1519815794000,
    endDateTime: 1519819394000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+1',
    description: 'Some description...',
    category: 'Music',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-fds5-sfg5'
  },
  {
    title: 'Event 2',
    artist: artists[1],
    venue: venues[1],
    timezone: 'America/Los_Angeles',
    startDateTime: 1524938594000,
    endDateTime: 1524942194000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+2',
    description: 'Some description...',
    category: 'Music',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-fds5-vns8'
  },
  {
    title: 'Event 3',
    artist: artists[2],
    venue: venues[2],
    timezone: 'America/Los_Angeles',
    startDateTime: 1535479394000,
    endDateTime: 1535482994000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+3',
    description: 'Some description...',
    category: 'Business',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-fds5-7f8s'
  },
  {
    title: 'Event 4',
    artist: artists[3],
    venue: venues[3],
    timezone: 'America/Los_Angeles',
    startDateTime: 1534356194000,
    endDateTime: 1534442594000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+4',
    description: 'Some description...',
    category: 'Fashion',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-s75b-sfg5'
  },
  {
    title: 'Event 5',
    artist: null,
    venue: venues[4],
    timezone: 'America/Los_Angeles',
    startDateTime: 1528203794000,
    endDateTime: 1528808594000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+5',
    description: 'Some description...',
    category: 'Travel',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-fds5-glp1'
  },
  {
    title: 'Event 6',
    artist: artists[2],
    venue: venues[3],
    timezone: 'America/Los_Angeles',
    startDateTime: 1528894994000,
    endDateTime: 1528898594000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+6',
    description: 'Some description...',
    category: 'Music',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-gfs4-vsv5'
  },
  {
    title: 'Event 7',
    artist: null,
    venue: venues[0],
    timezone: 'America/Los_Angeles',
    startDateTime: 1560430994000,
    endDateTime: 1560517394000,
    imageUrl: 'http://via.placeholder.com/200x200?text=Event+7',
    description: 'Some description...',
    category: 'Science',
    url: null,
    ticketPurchaseUrl: null,
    id: '5f45-fs84-4dff'
  }
];

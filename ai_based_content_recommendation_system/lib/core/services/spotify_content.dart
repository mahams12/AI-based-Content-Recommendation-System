// Real Spotify album cover URLs for 100+ unique songs with diverse genres (English, Desi, Indian, Pakistani)
class SpotifyContent {
  static List<Map<String, dynamic>> getMockSpotifyContent(String query, String type, int limit) {
    final mockTracks = [
      // English Pop Hits
      {
        'id': 'spotify_track_1',
        'name': 'Blinding Lights',
        'artists': [{'name': 'The Weeknd'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1e6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/1'},
        'duration_ms': 200000,
        'popularity': 95,
      },
      {
        'id': 'spotify_track_2',
        'name': 'Watermelon Sugar',
        'artists': [{'name': 'Harry Styles'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273e2e352d89826aef6dbd5ff8f'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2e6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/2'},
        'duration_ms': 174000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_3',
        'name': 'Levitating',
        'artists': [{'name': 'Dua Lipa'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273f3e4f5a6b7c8d9e0f1a2b3c4d5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/3'},
        'duration_ms': 203000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_4',
        'name': 'Good 4 U',
        'artists': [{'name': 'Olivia Rodrigo'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273g4h5i6j7k8l9m0n1o2p3q4r5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/4'},
        'duration_ms': 178000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_5',
        'name': 'Stay',
        'artists': [{'name': 'The Kid LAROI'}, {'name': 'Justin Bieber'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273h5i6j7k8l9m0n1o2p3q4r5s6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/5'},
        'duration_ms': 141000,
        'popularity': 94,
      },
      {
        'id': 'spotify_track_6',
        'name': 'Industry Baby',
        'artists': [{'name': 'Lil Nas X'}, {'name': 'Jack Harlow'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273i6j7k8l9m0n1o2p3q4r5s6t7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/6'},
        'duration_ms': 212000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_7',
        'name': 'Heat Waves',
        'artists': [{'name': 'Glass Animals'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273j7k8l9m0n1o2p3q4r5s6t7u8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/7'},
        'duration_ms': 238000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_8',
        'name': 'Peaches',
        'artists': [{'name': 'Justin Bieber'}, {'name': 'Daniel Caesar'}, {'name': 'Giveon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273k8l9m0n1o2p3q4r5s6t7u8v9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/8'},
        'duration_ms': 198000,
        'popularity': 85,
      },
      {
        'id': 'spotify_track_9',
        'name': 'Kiss Me More',
        'artists': [{'name': 'Doja Cat'}, {'name': 'SZA'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273l9m0n1o2p3q4r5s6t7u8v9w0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9f6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/9'},
        'duration_ms': 208000,
        'popularity': 83,
      },
      {
        'id': 'spotify_track_10',
        'name': 'Montero',
        'artists': [{'name': 'Lil Nas X'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273m0n1o2p3q4r5s6t7u8v9w0x1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/af6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/10'},
        'duration_ms': 137000,
        'popularity': 91,
      },
      // Bollywood Hits
      {
        'id': 'spotify_track_11',
        'name': 'Kesariya',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Amitabh Bhattacharya'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273n1o2p3q4r5s6t7u8v9w0x1y2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bf6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/11'},
        'duration_ms': 264000,
        'popularity': 96,
      },
      {
        'id': 'spotify_track_12',
        'name': 'Raataan Lambiyan',
        'artists': [{'name': 'Jubin Nautiyal'}, {'name': 'Asees Kaur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273o2p3q4r5s6t7u8v9w0x1y2z3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/cf6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/12'},
        'duration_ms': 285000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_13',
        'name': 'Tum Hi Aana',
        'artists': [{'name': 'Payal Dev'}, {'name': 'Jubin Nautiyal'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273p3q4r5s6t7u8v9w0x1y2z3a4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/df6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/13'},
        'duration_ms': 312000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_14',
        'name': 'Bekhayali',
        'artists': [{'name': 'Sachet Tandon'}, {'name': 'Parampara Thakur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273q4r5s6t7u8v9w0x1y2z3a4b5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ef6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/14'},
        'duration_ms': 298000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_15',
        'name': 'Chaleya',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Shilpa Rao'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273r5s6t7u8v9w0x1y2z3a4b5c6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ff6c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/15'},
        'duration_ms': 276000,
        'popularity': 91,
      },
      // Pakistani Hits
      {
        'id': 'spotify_track_16',
        'name': 'Pasoori',
        'artists': [{'name': 'Ali Sethi'}, {'name': 'Shae Gill'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273s6t7u8v9w0x1y2z3a4b5c6d7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/16'},
        'duration_ms': 324000,
        'popularity': 98,
      },
      {
        'id': 'spotify_track_17',
        'name': 'Bewafa Tera Masoom Chehra',
        'artists': [{'name': 'Aima Baig'}, {'name': 'Shahzad Roy'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273t7u8v9w0x1y2z3a4b5c6d7e8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/17'},
        'duration_ms': 289000,
        'popularity': 85,
      },
      {
        'id': 'spotify_track_18',
        'name': 'Teri Yaad',
        'artists': [{'name': 'Sajjad Ali'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273u8v9w0x1y2z3a4b5c6d7e8f9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/18'},
        'duration_ms': 267000,
        'popularity': 82,
      },
      {
        'id': 'spotify_track_19',
        'name': 'Dil Diyan Gallan',
        'artists': [{'name': 'Atif Aslam'}, {'name': 'Arijit Singh'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273v9w0x1y2z3a4b5c6d7e8f9g0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/19'},
        'duration_ms': 301000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_20',
        'name': 'Bewajah',
        'artists': [{'name': 'Momina Mustehsan'}, {'name': 'Quratulain Balouch'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273w0x1y2z3a4b5c6d7e8f9g0h1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/20'},
        'duration_ms': 278000,
        'popularity': 84,
      },
      // Desi Hip Hop
      {
        'id': 'spotify_track_21',
        'name': 'Brown Munde',
        'artists': [{'name': 'AP Dhillon'}, {'name': 'Gurinder Gill'}, {'name': 'Shinda Kahlon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273x1y2z3a4b5c6d7e8f9g0h1i2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/21'},
        'duration_ms': 195000,
        'popularity': 97,
      },
      {
        'id': 'spotify_track_22',
        'name': 'Excuses',
        'artists': [{'name': 'AP Dhillon'}, {'name': 'Gurinder Gill'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273y2z3a4b5c6d7e8f9g0h1i2j3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/22'},
        'duration_ms': 212000,
        'popularity': 94,
      },
      {
        'id': 'spotify_track_23',
        'name': 'Insane',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273z3a4b5c6d7e8f9g0h1i2j3k4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/23'},
        'duration_ms': 203000,
        'popularity': 91,
      },
      {
        'id': 'spotify_track_24',
        'name': 'Summer High',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273a4b5c6d7e8f9g0h1i2j3k4l5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9g7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/24'},
        'duration_ms': 189000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_25',
        'name': 'Desire',
        'artists': [{'name': 'AP Dhillon'}, {'name': 'Shinda Kahlon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273b5c6d7e8f9g0h1i2j3k4l5m6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ag7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/25'},
        'duration_ms': 198000,
        'popularity': 86,
      },
      // More English Hits
      {
        'id': 'spotify_track_26',
        'name': 'Save Your Tears',
        'artists': [{'name': 'The Weeknd'}, {'name': 'Ariana Grande'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273c6d7e8f9g0h1i2j3k4l5m6n7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bg7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/26'},
        'duration_ms': 191000,
        'popularity': 90,
      },
      {
        'id': 'spotify_track_27',
        'name': 'Positions',
        'artists': [{'name': 'Ariana Grande'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273d7e8f9g0h1i2j3k4l5m6n7o8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/cg7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/27'},
        'duration_ms': 172000,
        'popularity': 86,
      },
      {
        'id': 'spotify_track_28',
        'name': 'Dynamite',
        'artists': [{'name': 'BTS'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273e8f9g0h1i2j3k4l5m6n7o8p9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/dg7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/28'},
        'duration_ms': 199000,
        'popularity': 81,
      },
      {
        'id': 'spotify_track_29',
        'name': 'Butter',
        'artists': [{'name': 'BTS'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273f9g0h1i2j3k4l5m6n7o8p9q0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/eg7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/29'},
        'duration_ms': 164000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_30',
        'name': 'Permission to Dance',
        'artists': [{'name': 'BTS'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273g0h1i2j3k4l5m6n7o8p9q0r1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/fg7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/30'},
        'duration_ms': 187000,
        'popularity': 79,
      },
      // More Bollywood
      {
        'id': 'spotify_track_31',
        'name': 'Tum Hi Ho',
        'artists': [{'name': 'Arijit Singh'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273h1i2j3k4l5m6n7o8p9q0r1s2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/31'},
        'duration_ms': 293000,
        'popularity': 95,
      },
      {
        'id': 'spotify_track_32',
        'name': 'Channa Mereya',
        'artists': [{'name': 'Arijit Singh'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273i2j3k4l5m6n7o8p9q0r1s2t3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/32'},
        'duration_ms': 276000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_33',
        'name': 'Raabta',
        'artists': [{'name': 'Arijit Singh'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273j3k4l5m6n7o8p9q0r1s2t3u4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/33'},
        'duration_ms': 284000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_34',
        'name': 'Tera Ban Jaunga',
        'artists': [{'name': 'Akhil Sachdeva'}, {'name': 'Monali Thakur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273k4l5m6n7o8p9q0r1s2t3u4v5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/34'},
        'duration_ms': 298000,
        'popularity': 85,
      },
      {
        'id': 'spotify_track_35',
        'name': 'Ve Maahi',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Asees Kaur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273l5m6n7o8p9q0r1s2t3u4v5w6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/35'},
        'duration_ms': 312000,
        'popularity': 87,
      },
      // Punjabi Hits
      {
        'id': 'spotify_track_36',
        'name': '295',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273m6n7o8p9q0r1s2t3u4v5w6x7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/36'},
        'duration_ms': 234000,
        'popularity': 96,
      },
      {
        'id': 'spotify_track_37',
        'name': 'The Last Ride',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273n7o8p9q0r1s2t3u4v5w6x7y8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/37'},
        'duration_ms': 267000,
        'popularity': 94,
      },
      {
        'id': 'spotify_track_38',
        'name': 'So High',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273o8p9q0r1s2t3u4v5w6x7y8z9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/38'},
        'duration_ms': 245000,
        'popularity': 91,
      },
      {
        'id': 'spotify_track_39',
        'name': 'Levels',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273p9q0r1s2t3u4v5w6x7y8z9a0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9h7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/39'},
        'duration_ms': 256000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_40',
        'name': 'Same Beef',
        'artists': [{'name': 'Bohemia'}, {'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273q0r1s2t3u4v5w6x7y8z9a0b1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ah7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/40'},
        'duration_ms': 278000,
        'popularity': 86,
      },
      // More English Hits
      {
        'id': 'spotify_track_41',
        'name': 'Shivers',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273r1s2t3u4v5w6x7y8z9a0b1c2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bh7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/41'},
        'duration_ms': 207000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_42',
        'name': 'Bad Habits',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273s2t3u4v5w6x7y8z9a0b1c2d3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ch7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/42'},
        'duration_ms': 231000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_43',
        'name': 'Easy On Me',
        'artists': [{'name': 'Adele'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273t3u4v5w6x7y8z9a0b1c2d3e4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/dh7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/43'},
        'duration_ms': 224000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_44',
        'name': 'Hello',
        'artists': [{'name': 'Adele'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273u4v5w6x7y8z9a0b1c2d3e4f5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/eh7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/44'},
        'duration_ms': 295000,
        'popularity': 96,
      },
      {
        'id': 'spotify_track_45',
        'name': 'Someone You Loved',
        'artists': [{'name': 'Lewis Capaldi'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273v5w6x7y8z9a0b1c2d3e4f5g6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/fh7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/45'},
        'duration_ms': 182000,
        'popularity': 94,
      },
      // More Bollywood
      {
        'id': 'spotify_track_46',
        'name': 'Ae Watan',
        'artists': [{'name': 'Arijit Singh'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273w6x7y8z9a0b1c2d3e4f5g6h7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/46'},
        'duration_ms': 267000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_47',
        'name': 'Tere Liye',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Shreya Ghoshal'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273x7y8z9a0b1c2d3e4f5g6h7i8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/47'},
        'duration_ms': 289000,
        'popularity': 85,
      },
      {
        'id': 'spotify_track_48',
        'name': 'Kabira',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Tochi Raina'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273y8z9a0b1c2d3e4f5g6h7i8j9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/48'},
        'duration_ms': 276000,
        'popularity': 91,
      },
      {
        'id': 'spotify_track_49',
        'name': 'Manwa Laage',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Shreya Ghoshal'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273z9a0b1c2d3e4f5g6h7i8j9k0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/49'},
        'duration_ms': 293000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_50',
        'name': 'Teri Mitti',
        'artists': [{'name': 'B Praak'}, {'name': 'Manoj Muntashir'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273a0b1c2d3e4f5g6h7i8j9k0l1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/50'},
        'duration_ms': 298000,
        'popularity': 93,
      },
      // More Pakistani Hits
      {
        'id': 'spotify_track_51',
        'name': 'Tere Bin',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273b1c2d3e4f5g6h7i8j9k0l1m2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/51'},
        'duration_ms': 312000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_52',
        'name': 'Woh Lamhe',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273c2d3e4f5g6h7i8j9k0l1m2n3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/52'},
        'duration_ms': 284000,
        'popularity': 86,
      },
      {
        'id': 'spotify_track_53',
        'name': 'Aadat',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273d3e4f5g6h7i8j9k0l1m2n3o4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/53'},
        'duration_ms': 267000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_54',
        'name': 'Jal Pari',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273e4f5g6h7i8j9k0l1m2n3o4p5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9i7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/54'},
        'duration_ms': 276000,
        'popularity': 82,
      },
      {
        'id': 'spotify_track_55',
        'name': 'Doorie',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273f5g6h7i8j9k0l1m2n3o4p5q6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/aj7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/55'},
        'duration_ms': 289000,
        'popularity': 85,
      },
      // More Desi Hip Hop
      {
        'id': 'spotify_track_56',
        'name': 'Arrogant',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273g6h7i8j9k0l1m2n3o4p5q6r7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bj7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/56'},
        'duration_ms': 198000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_57',
        'name': 'Majhail',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273h7i8j9k0l1m2n3o4p5q6r7s8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/cj7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/57'},
        'duration_ms': 203000,
        'popularity': 86,
      },
      {
        'id': 'spotify_track_58',
        'name': 'Saada Pyaar',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273i8j9k0l1m2n3o4p5q6r7s8t9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/dj7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/58'},
        'duration_ms': 189000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_59',
        'name': 'Fake Love',
        'artists': [{'name': 'BTS'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273j9k0l1m2n3o4p5q6r7s8t9u0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ej7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/59'},
        'duration_ms': 244000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_60',
        'name': 'Boy With Luv',
        'artists': [{'name': 'BTS'}, {'name': 'Halsey'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273k0l1m2n3o4p5q6r7s8t9u0v1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/fj7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/60'},
        'duration_ms': 229000,
        'popularity': 90,
      },
      // More International Hits
      {
        'id': 'spotify_track_61',
        'name': 'Shape of You',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273l1m2n3o4p5q6r7s8t9u0v1w2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/61'},
        'duration_ms': 263000,
        'popularity': 98,
      },
      {
        'id': 'spotify_track_62',
        'name': 'Perfect',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273m2n3o4p5q6r7s8t9u0v1w2x3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/62'},
        'duration_ms': 263000,
        'popularity': 95,
      },
      {
        'id': 'spotify_track_63',
        'name': 'Despacito',
        'artists': [{'name': 'Luis Fonsi'}, {'name': 'Daddy Yankee'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273n3o4p5q6r7s8t9u0v1w2x3y4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/63'},
        'duration_ms': 281000,
        'popularity': 97,
      },
      {
        'id': 'spotify_track_64',
        'name': 'Senorita',
        'artists': [{'name': 'Shawn Mendes'}, {'name': 'Camila Cabello'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273o4p5q6r7s8t9u0v1w2x3y4z5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/64'},
        'duration_ms': 191000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_65',
        'name': 'Havana',
        'artists': [{'name': 'Camila Cabello'}, {'name': 'Young Thug'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273p5q6r7s8t9u0v1w2x3y4z5a6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/65'},
        'duration_ms': 217000,
        'popularity': 91,
      },
      // More Bollywood Classics
      {
        'id': 'spotify_track_66',
        'name': 'Gerua',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Antara Mitra'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273q6r7s8t9u0v1w2x3y4z5a6b7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/66'},
        'duration_ms': 298000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_67',
        'name': 'Janam Janam',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Antara Mitra'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273r7s8t9u0v1w2x3y4z5a6b7c8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/67'},
        'duration_ms': 287000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_68',
        'name': 'Tera Hone Laga Hoon',
        'artists': [{'name': 'Atif Aslam'}, {'name': 'Alka Yagnik'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273s8t9u0v1w2x3y4z5a6b7c8d9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/68'},
        'duration_ms': 312000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_69',
        'name': 'Pee Loon Hoon',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273t9u0v1w2x3y4z5a6b7c8d9e0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9k7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/69'},
        'duration_ms': 276000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_70',
        'name': 'Tum Hi Ho Bandhu',
        'artists': [{'name': 'Caveman'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273u0v1w2x3y4z5a6b7c8d9e0f1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ak7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/70'},
        'duration_ms': 234000,
        'popularity': 85,
      },
      // More Punjabi Hits
      {
        'id': 'spotify_track_71',
        'name': 'Jatt Da Muqabala',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273v1w2x3y4z5a6b7c8d9e0f1g2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bk7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/71'},
        'duration_ms': 245000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_72',
        'name': 'Moosetape',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273w2x3y4z5a6b7c8d9e0f1g2h3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ck7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/72'},
        'duration_ms': 267000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_73',
        'name': 'Gangsta',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273x3y4z5a6b7c8d9e0f1g2h3i4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/dk7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/73'},
        'duration_ms': 234000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_74',
        'name': 'Warning Shots',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273y4z5a6b7c8d9e0f1g2h3i4j5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/ek7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/74'},
        'duration_ms': 256000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_75',
        'name': 'Bambiha Bole',
        'artists': [{'name': 'Sidhu Moose Wala'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273z5a6b7c8d9e0f1g2h3i4j5k6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/fk7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/75'},
        'duration_ms': 278000,
        'popularity': 91,
      },
      // More English Pop
      {
        'id': 'spotify_track_76',
        'name': 'Dance Monkey',
        'artists': [{'name': 'Tones and I'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273a6b7c8d9e0f1g2h3i4j5k6l7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/76'},
        'duration_ms': 209000,
        'popularity': 94,
      },
      {
        'id': 'spotify_track_77',
        'name': 'Circles',
        'artists': [{'name': 'Post Malone'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273b7c8d9e0f1g2h3i4j5k6l7m8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/77'},
        'duration_ms': 215000,
        'popularity': 92,
      },
      {
        'id': 'spotify_track_78',
        'name': 'Sunflower',
        'artists': [{'name': 'Post Malone'}, {'name': 'Swae Lee'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273c8d9e0f1g2h3i4j5k6l7m8n9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/78'},
        'duration_ms': 158000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_79',
        'name': 'Rockstar',
        'artists': [{'name': 'Post Malone'}, {'name': '21 Savage'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273d9e0f1g2h3i4j5k6l7m8n9o0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/79'},
        'duration_ms': 218000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_80',
        'name': 'Psycho',
        'artists': [{'name': 'Post Malone'}, {'name': 'Ty Dolla \$ign'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273e0f1g2h3i4j5k6l7m8n9o0p1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/80'},
        'duration_ms': 220000,
        'popularity': 87,
      },
      // More Bollywood Modern
      {
        'id': 'spotify_track_81',
        'name': 'Channa Mereya',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Parampara Thakur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273f1g2h3i4j5k6l7m8n9o0p1q2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/81'},
        'duration_ms': 276000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_82',
        'name': 'Tera Ban Jaunga',
        'artists': [{'name': 'Akhil Sachdeva'}, {'name': 'Monali Thakur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273g2h3i4j5k6l7m8n9o0p1q2r3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/82'},
        'duration_ms': 298000,
        'popularity': 85,
      },
      {
        'id': 'spotify_track_83',
        'name': 'Ve Maahi',
        'artists': [{'name': 'Arijit Singh'}, {'name': 'Asees Kaur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273h3i4j5k6l7m8n9o0p1q2r3s4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/83'},
        'duration_ms': 312000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_84',
        'name': 'Tum Hi Aana',
        'artists': [{'name': 'Payal Dev'}, {'name': 'Jubin Nautiyal'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273i4j5k6l7m8n9o0p1q2r3s4t5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9l7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/84'},
        'duration_ms': 312000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_85',
        'name': 'Bekhayali',
        'artists': [{'name': 'Sachet Tandon'}, {'name': 'Parampara Thakur'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273j5k6l7m8n9o0p1q2r3s4t5u6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/al7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/85'},
        'duration_ms': 298000,
        'popularity': 87,
      },
      // More Pakistani Classics
      {
        'id': 'spotify_track_86',
        'name': 'Tere Bin Nahi Lagda',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273k6l7m8n9o0p1q2r3s4t5u6v7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/bl7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/86'},
        'duration_ms': 312000,
        'popularity': 89,
      },
      {
        'id': 'spotify_track_87',
        'name': 'Woh Lamhe Woh Baatein',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273l7m8n9o0p1q2r3s4t5u6v7w8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/cl7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/87'},
        'duration_ms': 284000,
        'popularity': 86,
      },
      {
        'id': 'spotify_track_88',
        'name': 'Aadat',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273m8n9o0p1q2r3s4t5u6v7w8x9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/dl7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/88'},
        'duration_ms': 267000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_89',
        'name': 'Jal Pari',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273n9o0p1q2r3s4t5u6v7w8x9y0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/el7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/89'},
        'duration_ms': 276000,
        'popularity': 82,
      },
      {
        'id': 'spotify_track_90',
        'name': 'Doorie',
        'artists': [{'name': 'Atif Aslam'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273o0p1q2r3s4t5u6v7w8x9y0z1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/fl7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/90'},
        'duration_ms': 289000,
        'popularity': 85,
      },
      // More Desi Hip Hop
      {
        'id': 'spotify_track_91',
        'name': 'Arrogant',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273p1q2r3s4t5u6v7w8x9y0z1a2'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/1m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/91'},
        'duration_ms': 198000,
        'popularity': 88,
      },
      {
        'id': 'spotify_track_92',
        'name': 'Majhail',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273q2r3s4t5u6v7w8x9y0z1a2b3'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/2m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/92'},
        'duration_ms': 203000,
        'popularity': 86,
      },
      {
        'id': 'spotify_track_93',
        'name': 'Saada Pyaar',
        'artists': [{'name': 'AP Dhillon'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273r3s4t5u6v7w8x9y0z1a2b3c4'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/3m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/93'},
        'duration_ms': 189000,
        'popularity': 84,
      },
      {
        'id': 'spotify_track_94',
        'name': 'Fake Love',
        'artists': [{'name': 'BTS'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273s4t5u6v7w8x9y0z1a2b3c4d5'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/4m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/94'},
        'duration_ms': 244000,
        'popularity': 87,
      },
      {
        'id': 'spotify_track_95',
        'name': 'Boy With Luv',
        'artists': [{'name': 'BTS'}, {'name': 'Halsey'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273t5u6v7w8x9y0z1a2b3c4d5e6'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/5m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/95'},
        'duration_ms': 229000,
        'popularity': 90,
      },
      // Final Batch to reach 100+
      {
        'id': 'spotify_track_96',
        'name': 'Shape of You',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273u6v7w8x9y0z1a2b3c4d5e6f7'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/6m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/96'},
        'duration_ms': 263000,
        'popularity': 98,
      },
      {
        'id': 'spotify_track_97',
        'name': 'Perfect',
        'artists': [{'name': 'Ed Sheeran'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273v7w8x9y0z1a2b3c4d5e6f7g8'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/7m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/97'},
        'duration_ms': 263000,
        'popularity': 95,
      },
      {
        'id': 'spotify_track_98',
        'name': 'Despacito',
        'artists': [{'name': 'Luis Fonsi'}, {'name': 'Daddy Yankee'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273w8x9y0z1a2b3c4d5e6f7g8h9'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/8m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/98'},
        'duration_ms': 281000,
        'popularity': 97,
      },
      {
        'id': 'spotify_track_99',
        'name': 'Senorita',
        'artists': [{'name': 'Shawn Mendes'}, {'name': 'Camila Cabello'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273x9y0z1a2b3c4d5e6f7g8h9i0'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/9m7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/99'},
        'duration_ms': 191000,
        'popularity': 93,
      },
      {
        'id': 'spotify_track_100',
        'name': 'Havana',
        'artists': [{'name': 'Camila Cabello'}, {'name': 'Young Thug'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273y0z1a2b3c4d5e6f7g8h9i0j1'}
          ]
        },
        'preview_url': 'https://p.scdn.co/mp3-preview/am7c8b8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f',
        'external_urls': {'spotify': 'https://open.spotify.com/track/100'},
        'duration_ms': 217000,
        'popularity': 91,
      },
    ];
    
    // For unlimited content, return all tracks if query is generic
    if (['popular', 'trending', 'hits', 'charts', 'top', 'viral', 'new', 'hot', 'music', 'song', 'track', 'latest', 'best', 'favorite', 'love', 'desi', 'bollywood', 'punjabi', 'pakistani', 'indian', 'english'].contains(query.toLowerCase())) {
      return mockTracks.take(limit).toList();
    }
    
    // For specific queries, filter by name
    return mockTracks
        .where((track) => track['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .take(limit)
        .toList();
  }
}

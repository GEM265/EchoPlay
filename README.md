Original App Design Project
# EchoPlay 
## Table of Contents
1. Overview
2. Product Spec
3. Wireframes
4. Schema
## Overview
### Description
EchoPlay is a social music discovery app inspired by Spotify's personalized playlists and TikToks viral trends. It allows users to discover new songs through short, user-generated clips, which they can swipe through and save to their playlists. The app includes collaborative playlists, music challenges, and trending song charts. 

### App Evaluation
[Evaluation of your app across the following attributes]

* Category: Social, Music, Entertaine
* Mobile: Fully mobile-focused application
* Story: Connects music lovers through short-form music discovery, empowering users and indie artists to share and explore new sounds
* Market: Gen Z and Millenial music enthusiasts, indie artists
* Habit: Daily use app for music discovery and sharing
* Scope: Moderate scope with core music discovery and social sharing features
### Product Spec
#### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* User can create an account 
* User can swipe through music clips 
* User can save songs to personal playlists 
* User can view artist information for each clip

Optional Nice-to-have Stories

* User can create collaborative playlists 
* User can participate in music challenges 
* User can view trending song charts 
* User can share clips to other social platforms 
#### 2. Screen Archetypes
- [x] Login Screen
    * User can log in or sign up
- [x] Clip Discovery Screen 
    * User can swip through music clips 
- [x] Playlist Manager Screen 
    * User can create, edit, and view playlists
- [x] Profile Screen
    * User can view and edit profile information
- [x] Trending Charts Screen 
    * User can view popular and trending songs
- [ ] Artist Profile Screen
    * User can view artist information and discography
#### 3. Navigation
**Tab Navigation** (Tab to Screen)

- [x] Home Feed
- [x] Trending 
- [x] Profile
- [x] Discover (Clip Swiping)
- [x] Profile 
**Flow Navigation** (Screen to Screen)

- [x] Login Screen 
    * Leads to Discover Screen
- [x] Clip Discovery Screen 
    * Can navigate to Playlist Creation
    * Can navigate to Artist Profile 
- [x] Playlist Screen 
    * can navigate to individual playlist details 
- [ ] Artist Profile Screen 
    * Can navigate back to Discover Screen
### Wireframes
[Add picture of your hand sketched wireframes in this section]

## [BONUS] Digital Wireframes & Mockups
## [BONUS] Interactive Prototype
## Schema
Models
[Model Name, e.g., User]

**User** 
Property | Type	| Description
-------- |------| ------------
username | String | unique id for the user post (default field)
email | String | User's email for authentication
password | String | user's password for login authentication
profilePicture | File | User's profile picture 
savedPlaylists | Array | List of user's created playlists 

**Clip**

Property | Type | Description
-------- | ---- | -----------
songTitle | String | Title of the song 
artist | Pointer to Artist | Artist who created the song 
clipURL | File | Short music clip 
likes | Number | Number of likes on the clip 
Favorites | Number | Number of favorites on the clip 
share | Number | Number of shares the clip on the clip

**Playlist**
Property | Type | Description
-------- | ---- | -----------
name | String | Playlist name 
creator | Pointer to User | User who created the playlist 
isCollaborative | Boolean | Whether playlist can be edited by others 

## Networking
* [GET]/users - to retrieve user data
* [GET]/clips - Retreive music clips 
* [POST]/playlists - Create new playlist 
* [PUT]/playlists/:id - Update Playlist
* [GET]/trending - Fetch trending songs 
* [GET]/artists/:id - Retreive artist information


https://github.com/user-attachments/assets/01ad2948-b8d3-4505-a00e-2922acb4cb4a




Here is a video of the Demo
https://youtu.be/detORtGdPWw 

Gabrielle McCrae Z23551433

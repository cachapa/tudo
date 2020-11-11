![tudo](tudo.svg)

an experiment in simple connected to-do lists.

To-do lists are supposed to be easy, yet everyone seems to be making them complicated.<br/>
You just want to write down a simple shopping list but then find yourself dealing with user accounts, permissions, roles, ads, autocompleters, AI helpers, location-based services, user tracking, etc. etc. etc.

This is different. It's simply useful. 

## Try it out

<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="80">

(iOS app coming later)

The server part of this project is maintained separately: [tudo_server](https://github.com/cachapa/tudo_server).

## Features

* **Anonymous**<br/>
No user accounts, registrations or tracking of any sort. The web client creates a couple of cookies used to store local data but those aren't tracked by the server.

* **Shareable**<br/>
Lists can be shared between your devices or trusted contacts simply using the list id.

* **Real-time**<br/>
Changes to lists appear immediately in every connected device where the app is open and online.

* **Private**<br/>
Each to-do list has a 128 character-long random unique identifier that should make it effectively impossible to guess.

* **Offline-first**<br/>
Any changes made to the list are stored locally on the device and synchronized whenever network is available.

* **Multiplatform**<br/>
Installable apps for Android and iOS, and a web interface for everything else.

* **Forgetful**<br/>
Lists exist on the server for relatively short timespans, just enough to perform synchronization between active devices.

* **Open-source**<br/>
Look at how it's built. Modify it. Host it yourself. Maybe help me improve it?

## How it works

To do lists are stored on the device as [CRDT](https://github.com/cachapa/crdt) maps which enable conflictless synchronization with an essentially unlimited number of devices possible. Every device maintains a local copy of the entire database.

A live websocket connection to the server is kept open whenever the app is active and network is available. Local changes are immediately pushed to the network, and remote changes are pulled in real-time. This promotes rapid consistency of the database between all active devices in the network, and allows users to see those changes happen in the user interface.

On the server side the data is only stored temporarily - currently in volatile memory but this may be changed to temporary disk storage in the future. Because all clients keep a complete local copy of the database locally, the data is completely restored whenever any client restores the socket connection.<br/>
The side-effect of this behaviour is that lists that are regularly updated effectively exist permanently on the server, those which are updated infrequently may not benefit from proper multi-device synchronization, and those which are deleted from all devices can be truly said to be lost in the ether.

The clients use the Flutter framework, which makes it possible to build Android, iOS and Web applications from a single shared codebase.

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/cachapa/tudo_client/issues).

# DEPRECATED

> Im no longer jailbroken, and I will no longer maintain this. If some one wants to take it over, hit me up. 

## Why was this made

Previously when a new jailbreak was released, the community manages a large google spreadsheet. The old process is super time consuming and tedious to cross reference against your device.

## What does it do

![Screenshot](docs/screenshot1.jpg?raw=true "Screenshot1a")
![Screenshot](docs/screenshot2.jpg?raw=true "Screenshot2a")
![Screenshot](docs/screenshot3.jpg?raw=true "Screenshot3a")

In the spirit of open source and to give back, I spent some time writing this tweak for Cydia that adds a section with compatibility results into the package details page.

Users can also go to the frontend website @ https://jlippold.github.io/tweakCompatible/ to view user submissions.

## Submissions

In order to submit whether a tweak works with an iOS version, you need to submit a review via Cydia. If you click the `Working` button at the bottom of the package details page, you will be redirected to github issues with a pre-populated issue created. A github account is required to submit reviews.

Every hour, I pull any open issues, update `docs/tweaks.json`, and close the ticket. This is done by cron.

## Scripting

This repo also contains a nodejs script, `tools\index.js`, that pulls open issues from github and updates the tweaks.json file. Just run `npm install`, then `npm start`. If changes were found, commits will be made, then just `git push` to remote.

To use the script, the env variable `GITHUB_API_TOKEN` must be set.

Also, `npm run rebuild` will wipe out all packages and recreate them from the closed issues in the repo.

## Calculations

I wanted to make this automated, community driven, with minimal human dependencies. Here is how the statuses are calculated:

 - `Working`: if 75% of the users say it's working. 
 - `Likely working`: if 40% of the users say it's working. 
 - `Not working`: if < 40% say it's working

## Installing

This tweak can be installed with Cydia via my [personal repo](http://repo.jed.bz) or the [big boss](http://apt.thebigboss.org/onepackage.php?bundleid=bz.jed.tweakcompatible) repo, or via the releases page on github. To package a final release, run `make package FINALPACKAGE=1`

## To-Do
 - Add request feature
 - Add more moderation tools
    - block package
    - block user
    - ~~block cydia repo~~
 
## License

Licensed under [Apache License, version 2.0](https://www.apache.org/licenses/LICENSE-2.0.html).

## Credits

 - [HASHBANG](https://github.com/hbang) for open sourcing the now defunct tweak Pheromone.
 - https://bootswatch.com/ Yeti theme
 - https://getbootstrap.com/ css framework
 - https://vuejs.org/
 - https://github.com/Sticktron/repo for the repo template

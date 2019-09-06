# Conda API

A small service to make it easier for [Libraries.io](https://libraries.io) to read data about Conda Packages in different channels.

## Essentials

- Provide a REST interface for list of all names of packages (as json)
- Provide a REST interface for list of versions for each package (as json)
- Update info from Specs repo frequently

## Extras

- Watch https://github.com/Conda/Specs/commits/master.atom for updates
- RSS feed of new/updated packages for https://github.com/librariesio/dispatcher to track
- Tell Libraries about removed versions/packages

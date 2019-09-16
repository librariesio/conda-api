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

## Development

### Requirements
* ruby 2.6.3
  * Installing via [RVM](http://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) is recommended
* redis
  * Ubuntu Linux: `sudo apt-get install redis-server`
  * OS X `brew install redis` `brew services start redis`

### Local Development

Run `bundle install` to download all dependencies.

You can run a local server within a container with docker-compose `docker-compose up` or locally with `bundle exec puma`.

The server should now be running port 9292. This can be verified by going to `http://localhost:9292` and verifying it sends back an 'Hello world' response.

### Tests

Run the unit tests using `rspec` locally or within a built docker container `docker build -t librariesio/conda-api . && docker run -it -e PORT=9292 -p 9292:9292 librariesio/conda-api rspec`.



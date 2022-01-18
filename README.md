# Inky Info Display

This repo uses a template SVG to populate an information display for an Inky Impression

## Installation

This repo assumes you've the Pimoroni [Python library](https://github.com/pimoroni/inky) installed, with the example image setter in `$HOME/Pimoroni/inky/examples/7color/image.py`.

After that, a few bits of ruby are needed:

```
sudo apt install ruby ruby-bundler ruby-dev ruby-nokogiri fonts-lato
bundle install --path vendor/bundle
```

## Usage

This software is configured through environment variables.  There is a `.env.example` with the various settings in it.  You'll want some API keys for services from
* [Met Office](https://www.metoffice.gov.uk/services/data/datapoint/api)
* [Weather Underground](https://www.wunderground.com/member/api-keys)

and put these into the `.env`

### Configuring the weahter forecast

For the weather forecast you'll want a Met Office location ID.  This is not the easiest to get hold of.

e.g. for Braintree (**NB** you'll need `jq` and `curl` installed here)
```
$ curl http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/sitelist?key=API_KEY > sitelist.json
$ jq '.Locations.Location | map(select(.name | startswith("Braintree")))'  < sitelist.json
```
gives
```json
[
  {
    "elevation": "70.0",
    "id": "350563",
    "latitude": "51.8797",
    "longitude": "0.5526",
    "name": "Braintree",
    "region": "ee",
    "unitaryAuthArea": "Essex"
  }
]`
```
so pick out the `id` of `350563` and put that in `DATAPOINT_LOCATION_ID`

### Configuring the tide forecast

This uses the [Admiralty Easy Tide](https://easytide.admiralty.co.uk/).  Simply look up the port you want to use, and then pinch the ID from the URL.  E.g. for Maldon, Essex, it is `0123B`.  Put that into `EASYTIDE_PORT_ID`.

### Configuring the sun rise/set etc

For this you need to know your latitude / longitude.  There are any number of geocoding websites to use here.  The results need to be decimals (rather than degrees), e.g. for Colchester, Essex put `LATITUDE` as 0.898 and `LONGITUDE` as 51.881.

### Testing it all out

You should now be able to run `./bin/update-inky.sh`

## weather-icons

This are taken from [Erik Flowers's weather-icons](https://github.com/erikflowers/weather-icons).

I've converted them to have a 100px base size, up from 30px using `rsvg-convert`, so that when embedded in the output SVG no scaling is needed.



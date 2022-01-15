# Inky Info Display

This repo uses a template SVG to populate an information display for an Inky Impression

## Installation

A few bits of ruby are needed

```
sudo apt install ruby ruby-bundler ruby-dev
```

and then

```
bundle install --path vendor/bundle
```

## Usage

```
bundle exec bin/generate-info-display inky-impression.svg > info-display.svg
rsvg-convert -b white -o info-display.png info-display.svg
```

## weather-icons

This are taken from [Erik FLowers's weather-icons](https://github.com/erikflowers/weather-icons).

I've converted them to have a 100px base size, up from 30px using `rsvg-convert`, so that when embedded in the output SVG no scaling is needed.



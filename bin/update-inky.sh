#!/bin/sh

BASENAME='info-display'

cd $(dirname $0)/..

bundle exec bin/generate-info-display alt-inky-impression.svg > $BASENAME.svg
rsvg-convert -b white -o $BASENAME.png $BASENAME.svg

~/Pimoroni/inky/examples/7color/image.py $BASENAME.png

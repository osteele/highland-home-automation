#!/bin/bash -eu

ls *.coffee *.yml | entr -r coffee main.coffee

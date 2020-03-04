#!/usr/bin/env bash

function background() {
  runcrond="crond -b" && bash -c "${runcrond}"
}

function start() {
  background
}

"$@"

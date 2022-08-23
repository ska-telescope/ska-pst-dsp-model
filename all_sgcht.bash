#!/bin/bash

cd products/

function plot () {

  echo $1 $args
  passband $args $1
  read

}

args="-s -D/xs"

for comb in "comb" "comb_coarse"; do

  plot frequency_${comb}.dada
  plot frequency_${comb}_low.dada
  plot frequency_${comb}_low_inverted.dada
  plot frequency_${comb}_low_two_stage.dada
  plot frequency_${comb}_low_two_stage_inverted.dada

  args="$args -j 0"

done

exit 0

-rw-r--r--  1 em8341  1270578465  1073807360 23 Aug 08:21 square_wave.dada
-rw-r--r--  1 em8341  1270578465  1431683072 23 Aug 08:22 square_wave_low.dada
-rw-r--r--  1 em8341  1270578465  1073545216 23 Aug 08:23 square_wave_low_inverted.dada
-rw-r--r--  1 em8341  1270578465  1897988096 23 Aug 08:24 square_wave_low_two_stage.dada
-rw-r--r--  1 em8341  1270578465  1384185856 23 Aug 08:26 square_wave_low_two_stage_inverted.dada


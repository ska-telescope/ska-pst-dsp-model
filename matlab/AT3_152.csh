#!/bin/csh

cd ../products

foreach test ( "low" "low_psi" "low_alt" "low_psi_alt" "mid" )

  echo test
  dspsr square_wave_${test}.dada -IF 1:1024:128 -dr -O square_wave_${test}
  psrplot -pD -c log=1 square_wave_${test}.ar -D square_wave_${test}.eps/cps

end


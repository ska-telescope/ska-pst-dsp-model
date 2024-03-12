#!/usr/bin/bash

# no rounding
file=products/square_wave_sps_lowpsi_two_stage_critical.dada
out=sw-low-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# rounding input without re-scaling
file=products/square_wave_sps_lowpsi_two_stage_critical_rndIn.dada
out=sw-low-rndIn-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# scaling for optimal 8-bit rounded input
file='products/square_wave_sps_lowpsi_two_stage_critical_rndIn_rmsIn=23.9002.dada'
out=sw-low-8bitIn-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# rounding output without re-scaling
file=products/square_wave_sps_lowpsi_two_stage_critical_rndOut.dada
out=sw-low-rndOut-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# scaling for optimal 8-bit rounded output
file='products/square_wave_sps_lowpsi_two_stage_critical_rndOut_rmsOut=23.9002.dada'
out=sw-low-8bitOut-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# scaling for optimal 12-bit rounded output
file='products/square_wave_sps_lowpsi_two_stage_critical_rndOut_rmsOut=462.6.dada'
out=sw-low-12bitOut-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png

# scaling for optimal 16-bit rounded output
file='products/square_wave_sps_lowpsi_two_stage_critical_rndOut_rmsOut=1769.25.dada'
out=sw-low-16bitOut-2s-critical-IF-hanning

dspsr $file -a PSRFITS -IF 256:1024:128 -O $out -f-taper=hanning
psrplot -pD -x -c log=-1 -jF ${out}.ar -D ${out}.png/png


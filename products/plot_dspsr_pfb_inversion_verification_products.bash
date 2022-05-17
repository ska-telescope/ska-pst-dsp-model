#!/usr/bin/env bash
function sqrt_int {
  local x=$1
  local res=$(python -c "import math; import sys; print(int(math.sqrt(float(sys.argv[1]))))" ${x})
  return ${res}
}

function plot_archives {
  local archive_files=$1
  local options=$2
  local name=$3

  local archive_files_list=(${archive_files})
  local len=${#archive_files_list[@]}
  sqrt_int ${len}
  local rows=$(($? + 1))
  local cols=$((${len} / ${rows}))
  if (( ${len} % ${rows} != 0 )); then
    cols=$((${cols} + 1))
  fi
  local width=$((${rows} * 600))
  local height=$((${cols} * 600))
  psrplot ${archive_files} ${options} -N ${cols}x${rows} -D /PNG -g ${width}x${height}
  mv pgplot.png ${name}
}

plot_archives "test_multi*.ar" "-p freq+" "multi.png"
plot_archives "test_vanilla.ar test_single*.ar" "-p stokes" "single.png"

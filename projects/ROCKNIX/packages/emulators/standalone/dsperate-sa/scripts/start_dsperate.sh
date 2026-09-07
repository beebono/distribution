#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile

set_kill set "-9 dsperate"

CONF_DIR="/storage/.config/dsperate"
DSPERATE_INI="${CONF_DIR}/dsperate.ini"

if [ ! -d "${CONF_DIR}" ]; then
	mkdir -p "${CONF_DIR}"
fi

# The emulator's own settings file. Command-line flags below override it, so
# anything EmulationStation does not drive stays editable here.
if [ ! -f "${DSPERATE_INI}" ]; then
	cp -f "/usr/config/dsperate/dsperate.ini" "${DSPERATE_INI}"
fi

if [ ! -d "/storage/roms/savestates/nds" ]; then
	mkdir -p "/storage/roms/savestates/nds"
fi

if [ ! -d "/storage/.cache/dsperate" ]; then
	mkdir -p "/storage/.cache/dsperate"
fi

#Emulation Station Features
GAME=$(echo "${1}" | sed "s#^/.*/##")
PLATFORM=$(echo "${2}" | sed "s#^/.*/##")
SLAYOUT=$(get_setting screen_layout "${PLATFORM}" "${GAME}")
SCREEN=$(get_setting main_screen "${PLATFORM}" "${GAME}")
SMOOTH=$(get_setting smooth_scaling "${PLATFORM}" "${GAME}")
CHUNKY=$(get_setting chunky_pixels "${PLATFORM}" "${GAME}")
LCDGRID=$(get_setting lcd_grid "${PLATFORM}" "${GAME}")
VSYNC=$(get_setting vsync "${PLATFORM}" "${GAME}")
FRAMESKIP=$(get_setting frameskip "${PLATFORM}" "${GAME}")
SPEEDHACK=$(get_setting speed_hack "${PLATFORM}" "${GAME}")
AA=$(get_setting anti_aliasing "${PLATFORM}" "${GAME}")

OPTS=("--fullscreen")

#Screen Layout
case "${SLAYOUT}" in
	vertical|horizontal|single|pip|dominant_v|dominant_h)
		OPTS+=("--layout" "${SLAYOUT}")
	;;
esac

#Which screen is shown alone, large, or dominant
case "${SCREEN}" in
	top|bottom)
		OPTS+=("--screen" "${SCREEN}")
	;;
esac

#Smooth scaling. It takes precedence over the grid and chunky cells, so the
#emulator is told about one or the other, never both.
if [ "${SMOOTH}" = "1" ]; then
	OPTS+=("--linear")
else
	#Chunky pixels: each 2x2 block of DS pixels drawn as one flat cell,
	#averaged ("mean", the default mode).
	[ "${CHUNKY}" = "1" ] && OPTS+=("--chunky" "mean")

	#LCD pixel grid, 0 (off) .. 1 (black seams)
	case "${LCDGRID}" in
		0|"")
		;;
		*)
			OPTS+=("--lcd-grid" "${LCDGRID}")
		;;
	esac
fi

#Vsync
[ "${VSYNC}" = "0" ] && OPTS+=("--no-vsync")

#Frameskip
case "${FRAMESKIP}" in
	[0-9]*)
		OPTS+=("--frameskip" "${FRAMESKIP}")
	;;
esac

#Speed hacks, least accurate last. Each is a step further from the hardware,
#so a game that misbehaves is fixed by stepping back down.
case "${SPEEDHACK}" in
	fast_load)
		OPTS+=("--fast-load")
	;;
	cpu_oc)
		OPTS+=("--fast-load" "--cpu-oc")
	;;
	timing_oc)
		OPTS+=("--fast-load" "--cpu-oc" "--timing-oc")
	;;
esac

#One window per panel on a dual-screen handheld, a DS screen in each
[ "${DEVICE_HAS_DUAL_SCREEN}" = "true" ] && OPTS+=("--dual-window")

#3D anti-aliasing
[ "${AA}" = "1" ] && OPTS+=("--aa")

# DSperate reads .nds and .zip itself; a .7z is unpacked first.
ROM="${1}"
if [[ "${ROM}" == *.7z ]]; then
	TEMP="/tmp/dsperate"
	rm -rf "${TEMP}"
	mkdir -p "${TEMP}"
	7z x -y -o"${TEMP}" "${ROM}"
	ROM=$(find "${TEMP}" -maxdepth 1 -type f -name "*.nds" | head -n 1)
fi

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
unset EMUPERF
[ "${CORES}" = "little" ] && EMUPERF="${SLOW_CORES}"
[ "${CORES}" = "big" ] && EMUPERF="${FAST_CORES}"

#Run DSperate. It takes over the controller itself, so there is no gptokeyb
#layer here.
${EMUPERF} /usr/bin/dsperate --config "${DSPERATE_INI}" "${OPTS[@]}" "${ROM}"

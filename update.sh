#!/bin/sh

cd "`dirname \"$0\"`"
patches=`pwd`

#Configuration
android=~/android/system
device=mango
devices="anzu coconut haida hallon iyokan mango satsuma smultron urushi"
debug=N

linaro_name=arm-eabi-4.7-linaro
linaro_file=android-toolchain-eabi-4.7-daily-linux-x86.tar.bz2
linaro_url=https://android-build.linaro.org/jenkins/view/Toolchain/job/linaro-android_toolchain-4.7-bzr/lastSuccessfulBuild/artifact/build/out/${linaro_file}

toolchain_32bit=Y

#--- bootimage ---

kernel_mods=Y
kernel_60=N
kernel_linaro=Y
kernel_cpugovernors=Y
kernel_ioschedulers=Y
kernel_voltage=Y
kernel_autogroup=Y
kernel_wifi_range=Y
kernel_wifi_psoff=N
kernel_rcutiny=Y
kernel_displaylink=Y
kernel_videodriver=Y
kernel_binder60=Y
kernel_whisper=N
kernel_misc=Y
kernel_optimize=N

kernel_compress=Y
filler_small=N
filler_large=N

bootlogo=Y
bootlogoh=logo_H_extended.png
bootlogom=logo_M_extended.png

#--- ROM ---

cellbroadcast=Y
openpdroid=Y
oompriorities=N
nano=Y
terminfo=Y
emptydrawer=Y
massstorage=Y
enable720p=Y
als=Y
wifiautoconnect=Y
eba=Y
ssh=Y
layout=Y
mediacontrols=Y
pinlayout=Y
mvolume=Y
bluetooth_bugfix=Y
trebuchet_patch=Y
trebuchet_fix=Y
new_superuser=Y

#Say hello
echo ""
echo "CM/FXP extended ROM/kernel"
echo "Copyright (c) 2012-2013 Marcel Bokhorst (M66B)"
echo "http://blog.bokhorst.biz/about/"
echo ""
echo "GNU GENERAL PUBLIC LICENSE Version 3"
echo ""
echo "Patches: ${patches}"
echo "Android: ${android}"
echo "Devices: ${devices}"
echo ""
read -p "Press [ENTER] to continue" dummy
echo ""

#Define functions
do_replace() {
	sed -i "s/$1/$2/g" $3
	grep -q "$2" $3
	if [ $? -ne 0 ]; then
		echo "!!! Error replacing '$1' by '$2' in $3"
		exit
	fi
	if [ "${debug}" = "Y" ]; then
		echo "Replaced '$1' by '$2' in $3"
	fi
}

do_patch() {
	patch -p1 --forward -r- --no-backup-if-mismatch <${patches}/$1
	if [ $? -ne 0 ]; then
		echo "!!! Error applying patch $1"
		exit
	fi
}

do_append() {
	if [ -f $2 ]; then
		echo "$1" >>$2
		if [ "${debug}" = "Y" ]; then
			echo "Appended '$1' to $2"
		fi
	else
		echo "!!! Error appending '$1' to $2"
		exit
	fi
}

do_deldir() {
	if [ -d "$1" ]; then
		rm -R $1
	fi
}

#Cleanup
echo "*** Cleanup ***"
if [ -d "${android}/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates" ]; then
	rm -R ${android}/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates
fi
if [ -d "${android}/out/target/common/obj/JAVA_LIBRARIES/framework2_intermediates" ]; then
	rm -R ${android}/out/target/common/obj/JAVA_LIBRARIES/framework2_intermediates
fi
if [ -d "${android}/out/target/common/obj/APPS/TelephonyProvider_intermediates" ]; then
	rm -R ${android}/out/target/common/obj/APPS/TelephonyProvider_intermediates
fi
for device in ${devices}
do
	#ROM
	if [ -d "${android}/out/target/product/${device}/system" ]; then
		rm -f ${android}/out/target/product/${device}/system/build.prop
		rm -f ${android}/out/target/product/${device}/system/lib/modules/*
	fi

	#kernel
	do_deldir ${android}/out/target/product/${device}/obj/KERNEL_OBJ/
	if [ -d "${android}/out/target/product/${device}" ]; then
		cd ${android}/out/target/product/${device}/
		rm -f ./kernel ./*.img ./*.cpio ./*.fs
		rm -f ./root/filler*
	fi

	#recovery
	#do_deldir ${android}/bootable/recovery
	#do_deldir ${android}/.repo/projects/bootable/recovery.git
	do_deldir ${android}/out/target/product/${device}/obj/EXECUTABLES/recovery_intermediates
	do_deldir ${android}/out/target/product/${device}/obj/RECOVERY_EXECUTABLES
	do_deldir ${android}/out/target/product/${device}/obj/STATIC_LIBRARIES/libcrecovery_intermediates
	do_deldir ${android}/out/target/product/${device}/recovery/root
done

#Local manifest
echo "*** Local manifest ***"
mkdir -p ${android}/.repo/local_manifests
cp ${patches}/cmxtended.xml ${android}/.repo/local_manifests/cmxtended.xml
if [ "${trebuchet_patch}" != "Y" ]; then
	sed -i "/Trebuchet/d" ${android}/.repo/local_manifests/cmxtended.xml
fi
if [ "${new_superuser}" != "Y" ]; then
	sed -i "/system_su/d" ${android}/.repo/local_manifests/cmxtended.xml
fi
if [ "${toolchain_32bit}" != "Y" ]; then
	sed -i "/androideabi/d" ${android}/.repo/local_manifests/cmxtended.xml
fi

echo "*** Repo sync ***"
cd ${android}
repo forall -c "git reset --hard && git clean -df"
if [ $? -ne 0 ]; then
	exit
fi
repo sync
if [ $? -ne 0 ]; then
	exit
fi

#Linaro toolchain
if [ "${linaro}" = "Y" ] || [ "${kernel_linaro}" = "Y" ]; then
	echo "*** Linaro toolchain: ${linaro_name} ***"

	linaro_dir=${android}/prebuilt/linux-x86/toolchain/${linaro_name}/
	if [ ! -d "${linaro_dir}" ]; then
		linaro_dl=~/Downloads/${linaro_file}
		if [ ! -f "${linaro_dl}" ]; then
			wget -O ${linaro_dl} ${linaro_url}
			if [ $? -ne 0 ]; then
				exit
			fi
		fi
		echo "--- Extracting"
		cd /tmp
		if [ -d "./android-toolchain-eabi/" ]; then
			rm -R ./android-toolchain-eabi/
		fi
		tar -jxf ${linaro_dl}
		mkdir ${linaro_dir}
		echo "--- Installing"
		cp -R ./android-toolchain-eabi/* ${linaro_dir}
	fi
fi

#Prebuilts
if [ "${openpdroid}" = "Y" ]; then
	do_append "curl -L -o ${android}/vendor/cm/proprietary/pdroidalternative.apk -O -L https://github.com/wsot/pdroid_manager_build/blob/master/PDroid_Manager_latest.apk?raw=true" ${android}/vendor/cm/get-prebuilts
fi
${android}/vendor/cm/get-prebuilts
if [ $? -ne 0 ]; then
	exit
fi

#--- kernel ---

#msm7x30 kernel
if [ "${kernel_mods}" = "Y" ]; then
	echo "*** Kernel ***"

	if [ "${kernel_60}" = "Y" ]; then
		echo "--- 2.6.32.9-60"
		cd ${android}/kernel/semc/msm7x30/
		do_patch kernel_2.6.32.9-60.patch
		do_patch kernel_lowmem60.patch
		do_patch kernel_compaction.patch
	fi

	if [ "${kernel_linaro}" = "Y" ]; then
		echo "--- Linaro"
		cd ${android}/device/semc/msm7x30-common
		do_patch linaro.patch
		for device in ${devices}
		do
			do_replace "arm-eabi-4.4.3" "${linaro_name}" ${android}/device/semc/${device}/BoardConfig.mk
		done
		cd ${android}/kernel/semc/msm7x30/
		do_patch kernel_linaro_head.patch
		do_patch kernel_linaro_boot.patch
	fi

	cd ${android}/kernel/semc/msm7x30/

	if [ "${kernel_cpugovernors}" = "Y" ]; then
		echo "--- CPU governors"
		do_patch kernel_cpugovernor.patch
		do_patch kernel_underclock.patch
		do_patch kernel_cpuminmax.patch
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig

			do_append "CONFIG_CPU_FREQ_GOV_SMARTASS=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_SCARY=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_MINMAX=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_LAGFREE=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_INTERACTIVEX=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_SAVAGEDZEN=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_SMARTASS2=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_SMOOTHASS=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_BRAZILIANWAX=y" ${kconfig}

			do_append "CONFIG_CPU_FREQ_GOV_LAZY=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_BADASS=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_INTELLIDEMAND=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_LULZACTIVE=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_SUPERBAD=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_VIRTUOUS=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_DARKSIDE=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_LIONHEART=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_ONDEMANDX=y" ${kconfig}
			do_append "CONFIG_CPU_FREQ_GOV_INTELLIDEMAND2=y" ${kconfig}

			do_append "CONFIG_CPU_FREQ_GOV_SMARTASSH3=y" ${kconfig}
		done
	fi

	if [ "${kernel_ioschedulers}" = "Y" ]; then
		echo "--- I/O schedulers"
		do_patch kernel_iosched.patch
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_replace "# CONFIG_IOSCHED_AS is not set" "CONFIG_IOSCHED_AS=y" ${kconfig}
			do_replace "# CONFIG_IOSCHED_CFQ is not set" "CONFIG_IOSCHED_CFQ=y" ${kconfig}
			do_append "CONFIG_IOSCHED_VR=y" ${kconfig}
			do_append "CONFIG_IOSCHED_SIO=y" ${kconfig}
		done
	fi

	if [ "${kernel_voltage}" = "Y" ]; then
		echo "--- Undervolt"
		do_patch kernel_board_config.patch
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_append "CONFIG_CPU_FREQ_VDD_LEVELS=y" ${kconfig}
			if [ "${device}" = "iyokan" ]; then
				do_replace "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2800" "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2700" ${kconfig}
			elif [ "${device}" = "mango" ]; then
				do_replace "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2700" "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2600" ${kconfig}
			elif [ "${device}" = "smultron" ]; then
				do_replace "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2900" "CONFIG_MOGAMI_VIBRATOR_ON_VOLTAGE=2800" ${kconfig}
			fi
		done
	fi

	if [ "${kernel_autogroup}" = "Y" ]; then
		echo "--- autogroup"
		if [ "${kernel_60}" = "Y" ]; then
			do_patch kernel_autogroup60.patch
		else
			do_patch kernel_autogroup.patch
		fi
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_append "CONFIG_SCHED_AUTOGROUP=y" ${kconfig}
		done
	fi

	if [ "${kernel_wifi_range}" = "Y" ]; then
		echo "--- Wi-Fi range"
		do_patch kernel_wifi_range.patch
	fi

	if [ "${kernel_wifi_psoff}" = "Y" ]; then
		echo "-- Wi-Fi power save off"
		do_patch kernel_wifi_psoff.patch
	fi

	if [ "${kernel_rcutiny}" = "Y" ]; then
		echo "--- RCU tiny"
		do_patch kernel_rcutiny.patch
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_append "CONFIG_TINY_RCU=y" ${kconfig}
			do_replace "CONFIG_TREE_RCU=y" "# CONFIG_TREE_RCU is not set" ${kconfig}
		done
	fi

	if [ "${kernel_displaylink}" = "Y" ]; then
		echo "--- DisplayLink"
		do_patch kernel_fbudl.patch
		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_replace "# CONFIG_FB_UDL is not set" "CONFIG_FB_UDL=m" ${kconfig}
			#do_replace "CONFIG_USB_OTG_WHITELIST=y" "CONFIG_USB_OTG_WHITELIST=n" ${kconfig}
		done
	fi

	if [ "${kernel_videodriver}" = "Y" ]; then
		echo "-- Video driver"
		do_patch kernel_videodriver.patch
	fi

	if [ "${kernel_binder60}" = "Y" ] && [ "${kernel_60}" != "Y" ]; then
		echo "-- Android binder .60"
		do_patch kernel_binder60.patch
	fi

	if [ "${kernel_whisper}" = "Y" ]; then
		echo "-- Whisper yaffs"
		do_replace "# CONFIG_CRYPTO_GF128MUL is not set" "CONFIG_CRYPTO_GF128MUL=y" ${kconfig}
		do_replace "# CONFIG_CRYPTO_XTS is not set" "CONFIG_CRYPTO_XTS=y" ${kconfig}
		do_patch kernel_whisper.patch
	fi

	echo "-- iyokan touch precision"
	do_patch kernel_iyokan_touch.patch

	if [ "${kernel_misc}" = "Y" ]; then
		echo "-- Misc"
		if [ "${kernel_60}" != "Y" ]; then
			do_patch kernel_slowdeath.patch
		fi

		do_patch kernel_oom_nokill.patch

		if [ "${kernel_60}" != "Y" ]; then
			do_patch kernel_sysfs.patch
		fi

		do_patch kernel_readahead.patch

		for device in ${devices}
		do
			kconfig=${android}/kernel/semc/msm7x30/arch/arm/configs/cyanogen_${device}_defconfig
			do_replace "# CONFIG_IKCONFIG_PROC is not set" "CONFIG_IKCONFIG_PROC=y" ${kconfig}
			do_replace "CONFIG_SLAB=y" "# CONFIG_SLAB is not set" ${kconfig}
			do_replace "# CONFIG_SLUB is not set" "CONFIG_SLUB=y" ${kconfig}
		done
	fi

	if [ "${kernel_optimize}" = "Y" ] && [ "${kernel_linaro}" != "Y" ]; then
		echo "--- Optimized build"
		for device in ${devices}
		do
			do_replace "CONFIG_CC_OPTIMIZE_FOR_SIZE" "CONFIG_CC_OPTIMIZE_ALOT" ${kconfig}
		done
	fi
fi

#Kernel compression
if [ "${kernel_compress}" != "Y" ]; then
	echo "*** No kernel compression ***"
	do_append "BOARD_USES_UNCOMPRESSED_BOOT := true" ${android}/device/semc/msm7x30-common/BoardConfigCommon.mk
fi

#Fillers
if [ "${filler_small}" = "Y" ]; then
	echo "*** Small filler: 34,692 bytes ***"
	do_append "PRODUCT_COPY_FILES += device/semc/msm7x30-common/prebuilt/fillers:root/fillers" ${android}/device/semc/msm7x30-common/msm7x30.mk
fi
if [ "${filler_large}" = "Y" ]; then
	echo "*** Large filler: 524,288 bytes ***"
	do_append "PRODUCT_COPY_FILES += device/semc/msm7x30-common/prebuilt/filler:root/filler" ${android}/device/semc/msm7x30-common/msm7x30.mk
fi

#Boot logo
if [ "${bootlogo}" = "Y" ]; then
	echo "*** Boot logo ***"
	gcc -O2 -Wall -Wno-unused-parameter -Wno-unused-result -o /tmp/to565 ${android}/build/tools/rgb2565/to565.c
	convert -depth 8 ${patches}/bootlogo/${bootlogoh} rgb:/tmp/logo_H_new.raw
	/tmp/to565 -rle </tmp/logo_H_new.raw >${android}/device/semc/msm7x30-common/prebuilt/logo_H.rle
	convert -depth 8 ${patches}/bootlogo/${bootlogom} rgb:/tmp/logo_M_new.raw
	/tmp/to565 -rle </tmp/logo_M_new.raw >${android}/device/semc/msm7x30-common/prebuilt/logo_M.rle
fi

#--- ROM ---

#Cell broadcast
if [ "${cellbroadcast}" = "Y" ]; then
	echo "*** Cell broadcast ***"
	do_append "PRODUCT_PACKAGES += CellBroadcastReceiver" ${android}/build/target/product/core.mk
	cd ${android}/device/semc/mogami-common
	do_patch cb_settings.patch
fi

#OpenPDroid
if [ "${openpdroid}" = "Y" ]; then
	echo "*** OpenPDroid ***"

	cd /tmp
	if [ ! -d "/tmp/OpenPDroidPatches" ]; then
		git clone git://github.com/OpenPDroid/OpenPDroidPatches.git
	fi
	cd OpenPDroidPatches
	git checkout 4.1.2-cm
	git pull

	cd ${android}/build; patch -p1 --forward -r- </tmp/OpenPDroidPatches/openpdroid_4.1.2-cm_build.patch
	cd ${android}/libcore; patch -p1 --forward -r- </tmp/OpenPDroidPatches/openpdroid_4.1.2-cm_libcore.patch
	cd ${android}/packages/apps/Mms; patch -p1 --forward -r- </tmp/OpenPDroidPatches/openpdroid_4.1.2-cm_packages_apps_Mms.patch
	cd ${android}/frameworks/base; patch -p1 --forward -r- </tmp/OpenPDroidPatches/openpdroid_4.1.2-cm_frameworks_base.patch

	mkdir -p ${android}/privacy
	cp /tmp/OpenPDroidPatches/PDroid.jpeg ${android}/privacy
	do_append "PRODUCT_COPY_FILES += privacy/PDroid.jpeg:system/media/PDroid.jpeg" ${android}/vendor/cm/config/common.mk
	do_append "PRODUCT_COPY_FILES += vendor/cm/proprietary/pdroidalternative.apk:system/app/pdroidalternative.apk" ${android}/vendor/cm/config/common.mk
fi

#OOM priorities
if [ "${oompriorities}" = "Y" ]; then
	echo "*** OOM priorities ***"
	cd ${android}/frameworks/base
	do_patch supercharger.patch
fi

#nano
if [ "${nano}" = "Y" ]; then
	echo "*** Nano enter key ***"
	cd ${android}/external/nano
	do_patch nano.patch
fi

#terminfo
if [ "${terminfo}" = "Y" ]; then
	echo "*** Terminfo ***"
	terminfo_dl=~/Downloads/termtypes.master.gz
	if [ ! -f "${terminfo_dl}" ]; then
		wget -O ${terminfo_dl} http://catb.org/terminfo/termtypes.master.gz
		if [ $? -ne 0 ]; then
			exit
		fi
	fi

	echo "--- Extracting"
	gunzip <${terminfo_dl} >/tmp/termtypes.master
	echo "--- Converting"
	tic -o ${android}/vendor/cm/prebuilt/common/etc/terminfo/ /tmp/termtypes.master
	if [ $? -ne 0 ]; then
		exit
	fi
	echo "--- Installing"
	do_append "PRODUCT_COPY_FILES += \\" ${android}/vendor/cm/config/common.mk
	cd ${android}/vendor/cm/prebuilt/common
	find etc/terminfo -type f -exec echo "    vendor/cm/prebuilt/common/{}:system/{} \\" >>${android}/vendor/cm/config/common.mk \;

	cd ${android}/vendor/cm/prebuilt/common/etc
	do_patch mkshrc.patch
fi

#Empty drawer
if [ "${emptydrawer}" = "Y" ]; then
	echo "*** Empty drawer ***"
	cd ${android}/bionic
	do_patch drawer.patch
fi

#Mass storage
if [ "${massstorage}" = "Y" ]; then
	echo "*** Mass storage ***"
	cd ${android}/device/semc/msm7x30-common
	do_patch mass_storage.patch
fi

#720p
if [ "${enable720p}" = "Y" ]; then
	echo "*** Enable 720p ***"
	cd ${android}/device/semc/msm7x30-common
	do_patch enable_720p.patch
	echo "--- Thanks Hikari no Tenshi for improving"
fi

#ALS
if [ "${als}" = "Y" ]; then
	echo "*** Automatic brightness ***"
	do_append "BOARD_SYSFS_LIGHT_SENSOR := /sys/class/leds/lcd-backlight/als/enable" ${android}/device/semc/msm7x30-common/BoardConfigCommon.mk
	do_append "PRODUCT_PROPERTY_OVERRIDES += ro.hardware.respect_als=true" ${android}/device/semc/msm7x30-common/msm7x30.mk
	cd ${android}/device/semc/mango
	do_patch ALS_mango.patch
	cd ${android}/device/semc/iyokan
	do_patch ALS_iyokan.patch
	cd ${android}/device/semc/smultron
	do_patch ALS_smultron.patch
fi

#Wi-Fi auto connect option
if [ "${wifiautoconnect}" = "Y" ]; then
	echo "*** Wi-Fi auto connect option ***"
	cd ${android}/frameworks/base
	do_patch wifi_auto_connect1.patch
	cd ${android}/packages/apps/Settings
	do_patch wifi_auto_connect2.patch
fi

#Electron beam animation
if [ "${eba}" = "Y" ]; then
	echo "*** Electron beam animation ***"
	cd ${android}/frameworks/base
	do_patch eba.patch
	do_patch eba_frameworks.patch
	cd ${android}/packages/apps/Settings
	do_patch eba_settings.patch
fi

#ssh
if [ "${ssh}" = "Y" ]; then
	echo "*** sftp-server ***"
	cd ${android}/external/openssh
	do_patch sftp-server.patch
fi

#Layout fixes
if [ "${layout}" = "Y" ]; then
	echo "*** Enabled expanded desktop ***"
	cd ${android}/device/semc/msm7x30-common
	do_patch layout_desktop.patch

	echo "*** In call layout ***"
	for device in ${devices}
	do
		if [ "${device}" = "mango" ] ||  [ "${device}" = "smultron" ]; then
			echo "--- ${device}"
			cd ${android}/device/semc/${device}
			do_patch incall_mdpi.patch
		fi
	done
	echo "--- Thanks Hikari no Tenshi"

	echo "*** Clear all button layout ***"
	cd ${android}/frameworks/base
	do_patch clear_all_button.patch
	echo "--- Thanks Hikari no Tenshi"
fi

#Lockscreen media controls layout
if [ "${mediacontrols}" = "Y" ]; then
	echo "*** Lockscreen media controls layout ***"
	cd ${android}/frameworks/base
	do_patch lockscreen_media_controls.patch
fi

#Lockscreen pin layout
if [ "${pinlayout}" = "Y" ]; then
	echo "*** Lockscreen pin layout ***"
	cd ${android}/frameworks/base
	do_patch lockscreen_password_block.patch
fi

#Music volume
if [ "${mvolume}" = "Y" ]; then
	echo "*** Finer music volume ***"
	cd ${android}/frameworks/base
	do_patch music_volume.patch
fi

#Bluetooth bugfix
if [ "${bluetooth_bugfix}" = "Y" ]; then
	echo "*** Bluetooth bugfix ***"
	cd ${android}/frameworks/base
	do_patch frameworks_bluetooth.patch
fi

#Trebuchet Patch
if [ "${trebuchet_patch}" = "Y" ]; then
	if [ -f ${android}/vendor/cm/overlay/common/packages/apps/Trebuchet/res/values/config.xml ];
	then
   	 rm ${android}/vendor/cm/overlay/common/packages/apps/Trebuchet/res/values/config.xml
	fi
	echo "*** Trebuchet Patch ***"
	echo "config.xml removed"
	cd ${android}/packages/apps/Trebuchet
	do_patch trebuchet_port.patch
fi

#Trebuchet fix build
if [ "${trebuchet_fix}" = "Y" ]; then
	echo "*** Trebuchet fix build ***"
	cd ${android}/packages/apps/Trebuchet
	do_patch trebuchet_fix_build.patch
fi

#Say whats next
echo "*** Done ***"
echo ""
echo "cd ${android}"
echo ". build/envsetup.sh"
echo ""
echo "brunch <device name>"
echo ""
echo "or"
echo ""
echo "lunch cm_<device name>-userdebug"
echo "make bootimage"
echo ""

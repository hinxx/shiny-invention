# Creating Imaging IOC from scratch

Author: Hinko Kocevar <hinkocevar@gmail.com>

Updated: 2017-11-01

## Install RPMs

	sudo yum install gtk-doc glibmm24-devel


## Build aravis

Will install into __/usr/local__.

	cd $HOME
	curl -L -o ARAVIS_0_4_1.tar.gz https://github.com/AravisProject/aravis/archive/ARAVIS_0_4_1.tar.gz
	tar xf ARAVIS_0_4_1.tar.gz
	cd aravis-ARAVIS_0_4_1
	./autogen.sh
	make -j
	sudo make install

## Get the SHI code

	git clone https://github.com/hinxx/shiny-invention.git
	cd shi/packages

## Build base

	bash tools/shi_single.sh packages/base/R3.15.4.rcp release

## Build IOC & dependent packages

	export IMGIOC_RCP=master+3
	bash tools/shi_batch.sh packages/imgioc/$IMGIOC_RCP.rcp

## Configure IOC

Open the __$HOME/shi/root/R3.15.4/iocs/imgioc-$IMGIOC_RCP/iocBoot/iocImg/st.cmd__ and:

Configure the camera ID to:

	aravisCameraConfig("$(PORT)", "Allied Vision Technologies-50-0503374606")

	or

	aravisCameraConfig("$(PORT)", "Allied Vision Technologies-50-0503374607")

Configure the spectrometer ID:

	# CCS175
	epicsEnvSet("RSCSTR", "USB::0x1313::0x8087::M00408690::RAW")

	or

	# CCS100
	epicsEnvSet("RSCSTR", "USB::0x1313::0x8081::M00407489::RAW")


If no other USB TMC devices are present no configuration is needed for PM100USB.

## Start the IOC

	cd $HOME/shi/root/R3.15.4/iocs/imgioc-$IMGIOC_RCP/iocBoot/iocImg
	LD_LIBRARY_PATH=/usr/local/lib ../../bin/linux-x86_64/imgApp st.cmd

	or

	start_ioc.sh

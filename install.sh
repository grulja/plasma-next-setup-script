#!/bin/bash

# Install build dependencies
# NOTE: Qt 5.3 is required for PLASMA_NEXT
echo "Installing build dependencies ..."
sudo yum -q -y install oxygen-fonts* polkit-devel qt5* qimageblitz-devel libbsd-devel libICE-devel lm_sensors-devel mesa-libGL-devel mesa-libEGL-devel pciutils-devel libraw1394-devel gpsd-devel pam-devel mesa-libGLES-devel boost-devel libXau-devel libXdmcp-devel libXdamage-devel libXfixes-devel\
libXcursor-devel libXcomposite-devel libusb-devel fontconfig-devel libxkbfile-devel xcb-util-keysyms-devel xcb-util-image-devel xcb-util-renderutil-devel xcb-util-wm-devel xcb-util-devel libxkbcommon-devel phonon-qt5-devel NetworkManager-devel NetworkManager-glib-devel openconnect-devel ModemManager-devel\
libupnp-devel libXrandr-devel libxslt-devel gettext-devel fdupes giflib-devel libjpeg-devel libpng-devel libGL-devel openssl-devel libSM-devel libXext-devel libXScrnSaver-devel docbook-dtds docbook-style-xsl libxml2-devel avahi-devel systemd-devel aspell-devel hspell-devel hunspell-devel gettext zlib-devel\
bzip2-devel lzma-devel libX11-devel libxcb-devel jasper-devel OpenEXR-devel perl pcre-devel glib2-devel xcb-util-keysyms-devel libXrender-devel libusb-devel libepoxy-devel

FRAMEWORKS_EXTRAS='extra-cmake-modules kf5umbrella polkit-qt-1'
FRAMEWORKS_TIER1='attica karchive kcodecs kconfig kcoreaddons kdbusaddons kglobalaccel kguiaddons kidletime kimageformats kitemmodels kitemviews kjs kplotting kwidgetsaddons kwindowsystem solid sonnet threadweaver'
FRAMEWORKS_TIER2='kauth kcompletion kcrash kdnssd kdoctools ki18n kjobwidgets'
FRAMEWORKS_TIER3='kconfigwidgets kiconthemes kservice knotifications ktextwidgets kxmlgui kbookmarks kcmutils kwallet kio kdeclarative kparts kdewebkit kinit kded kjsembed kunitconversion kdesignerplugin kpty kdesu knotifyconfig kross knewstuff kemoticons kmediaplayer kactivities plasma-framework krunner'
FRAMEWORKS_TIER4='frameworkintegration kapidox kdelibs4support khtml'
FRAMEWORKS_UNSTABLE='libnm-qt libmm-qt libkscreen:frameworks libksysguard kfilemetadata:frameworks baloo:frameworks baloo-widgets:frameworks'
PLASMA_NEXT='khelpcenter khotkeys kio-extras kmenuedit kwrited milou:frameworks powerdevil kwin oxygen plasma-nm plasma-workspace plasma-desktop kde-baseapps:frameworks breeze systemsettings kwalletmanager:frameworks ksysguard kscreen:frameworks'

PACKAGE_COLLECTIONS='FRAMEWORKS_EXTRAS FRAMEWORKS_TIER1 FRAMEWORKS_TIER2 FRAMEWORKS_TIER3 FRAMEWORKS_TIER4 FRAMEWORKS_UNSTABLE PLASMA_NEXT'


CURRENT_DIR=`pwd`

for collection in $PACKAGE_COLLECTIONS; do
    for x in ${!collection}; do
        NAME=$(echo "$x" | cut -f1 -d:)
        BRANCH=$(echo "$x" | cut -f2 -d: -s)
        if [ -d "$NAME" ]; then
            cd $NAME
            git pull
        else
            git clone git://anongit.kde.org/$NAME.git
            cd $NAME
        fi
        if [ -n "$BRANCH" ]; then
            git checkout "$BRANCH"
        else
            if [ "$(git branch | sed -n '/\* /s///p')" != "master" ]; then
                git checkout master
            fi
        fi
        mkdir -p build && cd build
        if [ $collection == "PLASMA_NEXT" ]; then
            cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR:STRING=/etc -DBIN_INSTALL_DIR:STRING=bin -DDATA_INSTALL_DIR:STRING=share/kde5 -DLIBEXEC_INSTALL_DIR:STRING=libexec/kde5 -DCMAKE_BUILD_TYPE=Debug
        else
            cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR:STRING=/etc -DCMAKE_BUILD_TYPE=Debug
        fi
        make -j5
        sudo make install
        cd $CURRENT_DIR
    done
done

## Taken from fedora kde5-plasma-workspace spec file

if [ ! -f /usr/share/xsessions/kde5-plasma.desktop ]; then
    sudo mkdir -p /usr/share/xsessions
    sudo cp kde5-plasma.desktop /usr/share/xsessions/kde5-plasma.desktop
fi

if [ ! -f /etc/profile.d/kde5.sh ]; then
    sudo mkdir -p /etc/profile.d
    sudo cp kde5.sh /etc/profile.d/kde5.sh
fi

# Makes kcheckpass work
if [ ! -f /etc/pam.d/kde ]; then
    sudo install -m455 -p -D kde /etc/pam.d/kde
fi

# Fix startkde being stupid and broken
sudo sed -i 's/lib\(\|64\)\/kde5\/libexec/libexec/' /usr/bin/startkde

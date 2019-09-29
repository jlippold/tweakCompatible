include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tweakCompatible
BUNDLE_NAME = bz.jed.tweakcompatible
bz.jed.tweakcompatible_INSTALL_PATH = /Library/Application Support
TARGET = iphone:10.2:10.2

include $(THEOS)/makefiles/bundle.mk

tweakCompatible_FILES = Tweak.xm
tweakCompatible_FRAMEWORKS = UIKit
tweakCompatible_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall Cydia; sleep 0.5; open com.saurik.Cydia"

SUBPROJECTS += tweakcompatible_prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

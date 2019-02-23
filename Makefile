include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tweakCompatible
BUNDLE_NAME = bz.jed.tweakcompatible
bz.jed.tweakcompatible_INSTALL_PATH = /Library/Application Support

include $(THEOS)/makefiles/bundle.mk

tweakCompatible_FILES = Tweak.xm
tweakCompatible_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall Cydia; sleep 0.5; activator send com.saurik.Cydia"

SUBPROJECTS += tweakcompatible_prefs
include $(THEOS_MAKE_PATH)/aggregate.mk



include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tweakCompatible
tweakCompatible_FILES = Tweak.xm
tweakCompatible_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall Cydia; sleep 0.5; sblaunch com.saurik.Cydia"
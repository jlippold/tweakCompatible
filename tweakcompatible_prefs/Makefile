include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = tweakCompatible_prefs
tweakCompatible_prefs_FILES = JTCRootListController.m
tweakCompatible_prefs_INSTALL_PATH = /Library/PreferenceBundles
tweakCompatible_prefs_FRAMEWORKS = UIKit
tweakCompatible_prefs_PRIVATE_FRAMEWORKS = Preferences
tweakCompatible_prefs_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/tweakCompatible_prefs.plist$(ECHO_END)

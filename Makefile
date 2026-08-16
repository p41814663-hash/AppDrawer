export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0
export THEOS_DEVICE_IP = localhost
export THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppDrawer

AppDrawer_FILES = Tweak.xm
AppDrawer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
AppDrawer_FRAMEWORKS = UIKit CoreGraphics QuartzCore
AppDrawer_PRIVATE_FRAMEWORKS = SpringBoardFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
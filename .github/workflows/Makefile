TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := LocationTest
LocationTest_FILES := Tweak.x
LocationTest_FRAMEWORKS := UIKit MapKit CoreLocation

include $(THEOS)/makefiles/tweak.mk
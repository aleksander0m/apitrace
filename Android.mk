#
# This Android.make allows apitrace to be included in an Android AOSP build
# e.g. in a manifest like this:
#
#  <manifest>
#      <remote name="aleksander0m" fetch="https://github.com/aleksander0m/" />
#      <project path="external/apitrace" name="apitrace.git" remote="aleksander0m" revision="aosp" groups="default" />
#  </manifest>
#
# This build file is based on the original one prepared for FirefoxOS and
# removed in commit 173fda8d, and therefore it has the same issues as that
# one:
#
#  * The $(linked_module) targets for both apitrace and egltrace are overriden,
#    which generates some warnings during build as soon as the build system
#    detects the issue.
#
#  * The $(LOCAL_INSTALLED_MODULE) target for egltrace has the same issue.
#
#  * This file overrides the installation steps so that the custom built
#    library and program are installed where we want them. But this file
#    doesn't provide rules to clean the intermediate files :/
#

LOCAL_PATH := $(call my-dir)

# Android NDK absolute path, required by android.toolchain.cmake
ANDROID_NDK := $(abspath prebuilts/ndk/current)

ifeq ($(shell which cmake),)
$(shell echo "CMake not found, will not compile apitrace" >&2)
else # cmake
ifeq ($(wildcard $(ANDROID_NDK)),)
$(shell echo "CMake present but NDK not found at $(ANDROID_NDK), will not compile apitrace" >&2)
else # NDK

APITRACE_SRCDIR := $(LOCAL_PATH)/
APITRACE_BUILDDIR := $(LOCAL_PATH)/build/

#------------------------------------------------------------------------------
# common rules

apitrace_common_target:
	$(hide) if [ ! -e $(APITRACE_BUILDDIR)/Makefile ] ; then                \
			cmake                                                   \
				-H$(APITRACE_SRCDIR)                            \
				-B$(APITRACE_BUILDDIR)                          \
				-DCMAKE_TOOLCHAIN_FILE=android.toolchain.cmake  \
				-DANDROID_NDK=${ANDROID_NDK}                    \
				-DANDROID_API_LEVEL=21                          \
				-DANDROID_STL=gnustl_static ;                   \
		fi
	$(hide) make -C $(APITRACE_BUILDDIR)

#------------------------------------------------------------------------------
# egltrace shared library

include $(CLEAR_VARS)

LOCAL_MODULE := egltrace
LOCAL_MODULE_TAGS := debug eng

include $(BUILD_SHARED_LIBRARY)

# copy egltrace lib to where the build system expects it
$(linked_module): apitrace_common_target
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $(APITRACE_BUILDDIR)/wrappers/egltrace$(TARGET_SHLIB_SUFFIX) $@

# copy egltrace lib to where the apitrace expects to find it
$(LOCAL_INSTALLED_MODULE): $(LOCAL_BUILT_MODULE) | $(ACP)
	@echo "Install (overridden): $@"
	@mkdir -p $(dir $@)/apitrace/wrappers
	$(hide) $(ACP) -fp $< $(dir $@)/apitrace/wrappers/egltrace$(TARGET_SHLIB_SUFFIX)

#------------------------------------------------------------------------------
# apitrace program

include $(CLEAR_VARS)

LOCAL_MODULE := apitrace
LOCAL_MODULE_TAGS := debug eng

include $(BUILD_EXECUTABLE)

# copy apitrace executable to where the build system expects it
$(linked_module): apitrace_common_target
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $(APITRACE_BUILDDIR)/apitrace$(TARGET_EXECUTABLE_SUFFIX) $@

endif # NDK
endif # cmake


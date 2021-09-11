include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = MPlayer

MPlayer_SUBPROJECTS = Controllers Classes

MPlayer_MAIN_MODEL_FILE = MainMenu.gorm

MPlayer_OBJC_FILES = main.m\
LocalizedInterface.m\

MPlayer_RESOURCE_FILES = ./Resources/MainMenu.gorm \
./Resources/Graphics/*


ADDITIONAL_INCLUDE_DIRS += -IClasses/ -IControllers/


ADDITIONAL_OBJCFLAGS +=  -Wall -Wno-import

include $(GNUSTEP_MAKEFILES)/subproject.make
include $(GNUSTEP_MAKEFILES)/application.make


#MplayerInterface.m\
#PlaylistTableView.m\
#ScrubbingBar.m\

# MPlayer_HEADER_FILES = LocalizedInterface.h\
# AppController.h\
# PlayListCtrllr.h\
# PlayerCtrllr.h\
# PreferencesController.h\
# SettingsController.h\
# MplayerInterface.h\
# PlaylistTableView.h\
# ScrubbingBar.h\

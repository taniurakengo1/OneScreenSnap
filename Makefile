APP_NAME = OneScreenSnap
BUNDLE_NAME = $(APP_NAME).app
INSTALL_DIR = /Applications
INSTALL_PATH = $(INSTALL_DIR)/$(BUNDLE_NAME)
EXECUTABLE_PATH = $(INSTALL_PATH)/Contents/MacOS/$(APP_NAME)
PLIST_NAME = com.onescreensnap.app.plist
PLIST_PATH = $(HOME)/Library/LaunchAgents/$(PLIST_NAME)

define LAUNCHAGENT_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.onescreensnap.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(EXECUTABLE_PATH)</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
endef

export LAUNCHAGENT_PLIST

.PHONY: build bundle install uninstall start stop clean test

build:
	swift build -c release

bundle: build
	@rm -rf $(BUNDLE_NAME)
	@mkdir -p $(BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(BUNDLE_NAME)/Contents/Resources
	@cp .build/release/$(APP_NAME) $(BUNDLE_NAME)/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist $(BUNDLE_NAME)/Contents/Info.plist
	@codesign --force --sign - $(BUNDLE_NAME)
	@echo "Created $(BUNDLE_NAME)"

test:
	swift test

install: bundle
	sudo rm -rf $(INSTALL_PATH)
	sudo cp -R $(BUNDLE_NAME) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_PATH)"
	@mkdir -p $(HOME)/Library/LaunchAgents
	@echo "$$LAUNCHAGENT_PLIST" > $(PLIST_PATH)
	@echo "LaunchAgent installed to $(PLIST_PATH)"

start:
	launchctl load $(PLIST_PATH) 2>/dev/null || true
	launchctl start com.onescreensnap.app
	@echo "$(APP_NAME) started"

stop:
	launchctl stop com.onescreensnap.app 2>/dev/null || true
	launchctl unload $(PLIST_PATH) 2>/dev/null || true
	@echo "$(APP_NAME) stopped"

uninstall: stop
	sudo rm -rf $(INSTALL_PATH)
	sudo rm -f /usr/local/bin/$(APP_NAME)
	rm -f $(PLIST_PATH)
	@echo "$(APP_NAME) uninstalled"

clean:
	swift package clean
	rm -rf .build $(BUNDLE_NAME)

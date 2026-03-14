APP_NAME = OneScreenSnap
INSTALL_PATH = /usr/local/bin/$(APP_NAME)
PLIST_NAME = com.onescreensnap.app.plist
PLIST_PATH = $(HOME)/Library/LaunchAgents/$(PLIST_NAME)

.PHONY: build install uninstall start stop clean test

build:
	swift build -c release

test:
	swift test

install: build
	sudo cp .build/release/$(APP_NAME) $(INSTALL_PATH)
	@echo "Installed to $(INSTALL_PATH)"
	@mkdir -p $(HOME)/Library/LaunchAgents
	@cat > $(PLIST_PATH) <<- 'EOF'
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.onescreensnap.app</string>
		<key>ProgramArguments</key>
		<array>
			<string>$(INSTALL_PATH)</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
		<key>KeepAlive</key>
		<false/>
	</dict>
	</plist>
	EOF
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
	sudo rm -f $(INSTALL_PATH)
	rm -f $(PLIST_PATH)
	@echo "$(APP_NAME) uninstalled"

clean:
	swift package clean
	rm -rf .build

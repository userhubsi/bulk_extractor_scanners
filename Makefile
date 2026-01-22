# --- Configuration ---
BE_REPO       = https://github.com/simsong/bulk_extractor.git
BE_DIR        = bulk_extractor

# --- Patch Definitions ---
NEW_CPPS      = scan_bitcoin.cpp scan_monero.cpp scan_domains.cpp scan_ethereum.cpp scan_hwallets.cpp scan_mnemonics.cpp scan_torurls.cpp
NEW_FLEXS     = scan_bitcoin.flex extern/Keccak-more-compact.h extern/Keccak-more-compact.c scan_monero.flex scan_ethereum.flex scan_hwallets.flex scan_mnemonics.flex scan_domains.flex scan_torurls.flex extern/base32.h extern/base32.c
NEW_SCANNERS  = SCANNER(bitcoin)\nSCANNER(monero)\nSCANNER(domains)\nSCANNER(ethereum)\nSCANNER(hwallets)\nSCANNER(mnemonics)\nSCANNER(torurls)

.PHONY: all clone copy_local patch build install clean_src

# Default target: Do everything
all: clone copy_local patch build install

# 1. Clone Bulk Extractor Base
clone:
	@echo "--- Cloning Bulk Extractor Base ---"
	# Only clone if it doesn't exist yet
	if [ ! -d "$(BE_DIR)" ]; then \
		git clone --recursive $(BE_REPO) $(BE_DIR); \
	fi

# 2. Copy THIS directory's files into the BE source tree
copy_local:
	@echo "--- Copying Local Plugins to BE Source ---"
	# Copy 'extern' folder
	cp -R extern $(BE_DIR)/src/
	# Copy scanner flex files
	cp scan_*.flex $(BE_DIR)/src/
	# Copy auxiliary files
	cp domains_list.csv $(BE_DIR)/src/
	# Copy headers/c files to extern
	cp extern/*.h $(BE_DIR)/src/extern/
	cp extern/*.c $(BE_DIR)/src/extern/

# 3. Patch Makefile.am and scanners.h
patch:
	@echo "--- Patching BE Build Configuration ---"
	# Reset files to git state to avoid double-patching if run multiple times
	cd $(BE_DIR)/src && git checkout Makefile.am bulk_extractor_scanners.h

	# Patch Makefile.am
	sed -i 's|scan_gps.cpp|scan_gps.cpp $(NEW_CPPS)|g' $(BE_DIR)/src/Makefile.am
	sed -i 's|scan_gps.flex|scan_gps.flex $(NEW_FLEXS)|g' $(BE_DIR)/src/Makefile.am

	# Patch bulk_extractor_scanners.h
	sed -i 's|SCANNER(gps)|SCANNER(gps)\n$(NEW_SCANNERS)|g' $(BE_DIR)/src/bulk_extractor_scanners.h

# 4. Compile
build:
	@echo "--- Compiling ---"
	cd $(BE_DIR) && ./bootstrap.sh
	cd $(BE_DIR) && ./configure
	cd $(BE_DIR) && make -j$$(nproc)

# 5. Install locally
install:
	@echo "--- Installing ---"
	cd $(BE_DIR) && make

# Helper to wipe source if you want a clean slate
clean_src:
	rm -rf $(BE_DIR)
.PHONY: build clean install test help

# Default target
all: build

# Build the binary using SBCL
build:
	@echo "Building lda binary..."
	ros run -- --non-interactive \
		--eval "(require :asdf)" \
		--eval "(push (uiop:getcwd) asdf:*central-registry*)" \
		--eval "(asdf:load-system :lispy-data-analysis)" \
		--eval "(asdf:make :lispy-data-analysis)"
	@echo "Build complete: bin/lda"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	find . -name "*.fasl" -delete
	@echo "Clean complete"

# Install to ~/.local/bin
install: build
	@echo "Installing lda to ~/.local/bin..."
	mkdir -p ~/.local/bin
	cp bin/lda ~/.local/bin/lda
	chmod +x ~/.local/bin/lda
	@echo "Installation complete"

# Run tests (placeholder for future implementation)
test:
	@echo "No tests defined yet"

# Display help
help:
	@echo "Available targets:"
	@echo "  build    - Build the lda binary (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  install  - Install lda to ~/.local/bin"
	@echo "  test     - Run tests (not yet implemented)"
	@echo "  help     - Display this help message"

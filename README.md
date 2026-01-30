# Lispy Data Analysis (lda)

A deployable Common Lisp binary with remote REPL connectivity for data analysis on remote machines. Provides DuckDB integration with zeek-duckdb extension support and Vega-Lite visualization capabilities.

## Features

- **Remote REPL Access**: Start a swank server for remote Emacs/SLIME connectivity
- **DuckDB Integration**: Full DuckDB database support with zeek-duckdb extension
- **Vega-Lite Visualizations**: Create interactive charts and visualizations
- **State Persistence**: Save and restore Lisp image state (SBCL only)
- **Multiple Authentication Modes**: Password-based or localhost-only binding
- **Command-Line Interface**: Easy-to-use CLI for common operations

## Installation

### Prerequisites

- SBCL (Steel Bank Common Lisp)
- Quicklisp
- zeek-duckdb extension (optional, but recommended)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/lispy-data-analysis.git
cd lispy-data-analysis

# Build the binary
make build

# Install to ~/.local/bin (optional)
make install
```

### Pre-built Binaries

Download pre-built binaries from the [releases page](https://github.com/yourusername/lispy-data-analysis/releases).

## Usage

### Server Mode

Start a swank server for remote REPL access:

```bash
# Localhost-only (secure for SSH tunneling)
./bin/lda server --port 4005 --daemon

# With password authentication
./bin/lda server --port 4005 --password secret123 --daemon

# Listen on all interfaces (use with caution)
./bin/lda server --port 4005 --host 0.0.0.0 --password secret123 --daemon

# Custom zeek-duckdb extension path
./bin/lda server --zeek-extension /path/to/zeek.duckdb_extension --daemon
```

### REPL Mode

Start a local REPL with initialized environment:

```bash
./bin/lda repl
```

Available functions in the REPL:
- `(lda:start-swank-server)` - Start swank server for remote access
- `(lda:chart results "x" "y")` - Create and display a chart
- `(db:q "SELECT ...")` - Run SQL query
- `(db:run "CREATE TABLE ...")` - Execute SQL statement

### Save State

Save the current Lisp image, overwriting the binary (SBCL only):

```bash
./bin/lda save --compression 9
```

This is useful for saving loaded data or state for quick resume.

## Remote Access via SSH Tunnel

The recommended way to access a remote lda server securely:

1. Start lda on the remote machine:
   ```bash
   ssh user@remote
   ./bin/lda server --daemon
   ```

2. Create an SSH tunnel from your local machine:
   ```bash
   ssh -L 4005:127.0.0.1:4005 user@remote
   ```

3. Connect from Emacs/SLIME:
   ```
   M-x slime-connect
   Host: localhost
   Port: 4005
   ```

## Visualization Examples

```lisp
;; Simple bar chart
(chart (db:q "SELECT app, COUNT(*) as freq FROM apps GROUP BY app")
       "app" "freq"
       :title "App Frequency"
       :x-sort "-y")

;; Scatter plot with custom styling
(chart results "x" "y"
       :mark "point"
       :mark-properties '(:size 100 :filled t :opacity 0.7))

;; Line chart with smooth interpolation
(chart results "date" "value"
       :mark "line"
       :mark-properties '(:stroke-width 3 :interpolate "monotone"))

;; Area chart with transparency
(chart results "date" "value"
       :mark "area"
       :mark-properties '(:opacity 0.5 :line t))
```

## Development

### Project Structure

```
lispy-data-analysis/
├── lispy-data-analysis.asd       # ASDF system definition
├── package.lisp                  # Package exports
├── Makefile                      # Build targets
├── README.md                     # Documentation
├── .gitignore                    # Git ignore patterns
├── .github/
│   └── workflows/
│       └── build.yml             # CI/CD configuration
├── src/
│   ├── database.lisp             # DB initialization, save-state
│   ├── visualization.lisp        # Vega-Lite visualizations
│   ├── swank-server.lisp         # Swank server management
│   └── cli.lisp                  # CLI entry point
├── bin/
│   └── lda                       # Built binary
└── data/                         # Data files (gitignored)
```

### Building

```bash
make build    # Build the binary
make clean    # Remove build artifacts
make install  # Install to ~/.local/bin
make test     # Run tests (not yet implemented)
```

### Dependencies

- **duckdb** - DuckDB database bindings
- **alexandria** - Common Lisp utilities
- **com.inuoe.jzon** - JSON encoding/decoding
- **swank** - SLIME backend for remote REPL
- **bordeaux-threads** - Cross-platform threading
- **clingon** - CLI option parsing

## License

MIT License. See LICENSE file for details.

## Author

Yacin Nadji <yacin@gatech.edu>

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

# Jellygem

A powerful command-line tool to organize your TV series collection with proper file/folder renaming and metadata generation for Jellyfin, Kodi, Plex, and Emby media centers.

## Features

- **Interactive TV Show Selection** - Easily search and select the correct TV show from TMDB
- **TMDB Integration** - Fetches detailed information from The Movie Database API
- **Smart Renaming** - Renames folders and files to a consistent format
- **Metadata Generation** - Creates NFO files compatible with popular media centers
- **Artwork Download** - Downloads posters, fanart, and episode thumbnails
- **Episode Organization** - Detects season and episode numbers and organizes accordingly
- **User-Friendly Interface** - Progress bars, colored output, and interactive prompts
- **Flexible Options** - Customizable through command-line options and config file

## Installation

```bash
gem install jellygem
```

Or build from source:

```bash
git clone https://github.com/yourusername/jellygem.git
cd jellygem
bundle install
rake install
```

## Usage

Basic usage:

```bash
jellygem /path/to/your/tv/show
```

Options:

```
Usage: jellygem [options] [path/to/series]

Options:
  -h, --help           Show this help message
  -v, --version        Show version information
  --dry-run            Simulate operations without making changes
  --verbose            Show detailed output
  --skip-images        Skip downloading images
  --force              Override existing files
  --no-prompt          Use defaults without prompting
```

### Example

```bash
jellygem "Supernatural_2005_2160p_s01-s12_COMPLETE_BLUERAY_HEVC_AAC"
```

The tool will:
1. Search TMDB for matching series
2. Present the best matches to you for confirmation
3. Rename the folder to "Supernatural (2005)"
4. Organize seasons and episodes
5. Download artwork
6. Generate metadata files

## How It Works

Jellygem analyzes your TV show folders and helps you organize them into a format that media centers can correctly identify:

1. **Folder Analysis**: Jellygem first analyzes the folder name to make an initial guess about the show
2. **Search and Confirm**: You search for and confirm the correct show on TMDB
3. **Series Organization**: The tool renames the main folder to the proper format with year
4. **Season Detection**: Each season folder is organized with a consistent naming pattern
5. **Episode Processing**: Episodes are renamed to include proper season, episode number, and name
6. **Metadata Generation**: NFO files are created with detailed show information
7. **Artwork Download**: Posters, fanart, and episode thumbnails are downloaded

## Configuration

You can customize the behavior by creating a `~/.jellygem.yml` file:

```yaml
# The Movie Database API key (optional, default provided)
tmdb_api_key: 'your-tmdb-api-key'

# Default options
dry_run: false
verbose: false 
skip_images: false
max_api_retries: 3
force: false
no_prompt: false
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/jellygem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
# ScreenKit Documentation

**Terminal to screencast, simplified**

ScreenKit is a Ruby-based tool for creating professional screencasts from
terminal recordings. It automates the process of combining intro/outro scenes,
terminal recordings (via [demotapes](https://github.com/fnando/demotape)),
voiceovers, background music, callouts (lower thirds), and watermarks into
polished video content.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Commands](#cli-commands)
- [Project Configuration](#project-configuration)
- [Episode Configuration](#episode-configuration)
- [Scenes](#scenes)
- [Callouts](#callouts)
- [Text-to-Speech (TTS)](#text-to-speech-tts)
- [Animations](#animations)
- [File Structure](#file-structure)
- [Advanced Features](#advanced-features)

---

## Installation

```bash
gem install screenkit
```

Or add to your Gemfile:

```ruby
gem "screenkit"
```

---

## Quick Start

### 1. Create a New Project

```bash
screenkit new my-screencast
cd my-screencast
```

This generates:

- `screenkit.yml` - Project configuration
- `episodes/` - Directory for episodes
- `resources/` - Images, sounds, fonts, etc.
- `output/` - Generated videos

### 2. Create a New Episode

```bash
screenkit episode new --title "My First Episode"
```

This creates an episode directory with:

- `config.yml` - Episode configuration
- `content/` - Terminal recording files (`.tape` files)
- `scripts/` - Voiceover scripts (`.txt` files)
- `voiceovers/` - Generated voiceover audio
- `resources/` - Episode-specific resources

### 3. Export the Episode

```bash
screenkit episode export --dir episodes/001-my-first-episode
```

The final video is saved to the `output/` directory.

---

## CLI Commands

### Root Commands

#### `screenkit new PATH`

Create a new ScreenKit project at the specified path.

```bash
screenkit new my-project
```

#### `screenkit callout`

Generate a standalone callout PNG for testing.

**Options:**

- `--type` (required) - Callout type (e.g., `info`, `warning`)
- `--title` (required) - Callout title text
- `--body` (required) - Callout body text
- `--output` - Output path for PNG (optional)

```bash
screenkit callout --type info --title "Note" --body "This is important" --output callout.png
```

### Episode Commands

#### `screenkit episode new`

Create a new episode.

**Options:**

- `--title` (required) - Episode title
- `--config` - Path to project config file (default: `screenkit.yml`)

```bash
screenkit episode new --title "Getting Started with Ruby"
```

#### `screenkit episode export`

Export an episode to video.

**Options:**

- `--dir` (required) - Episode directory path
- `--voice-api-key` - API key for TTS service (e.g., ElevenLabs)
- `--overwrite` - Overwrite existing exported files (default: `false`)
- `--match-segment` - Only export segments matching this string
- `--output-dir` - Custom output directory path
- `--banner` - Display ScreenKit banner (default: `true`)
- `--require` - Additional Ruby files to require (can be used multiple times)
- `--config` - Path to project config file (default: `screenkit.yml`)

```bash
screenkit episode export --dir episodes/001-getting-started
screenkit episode export --dir episodes/001-getting-started --overwrite
screenkit episode export --dir episodes/001-getting-started --match-segment "002"

# Load custom TTS engines or callout styles
screenkit episode export --dir episodes/001-getting-started --require ./lib/custom_tts.rb
screenkit episode export --dir episodes/001-getting-started --require ./lib/custom_tts.rb --require ./lib/custom_callout.rb
```

---

## Project Configuration

The `screenkit.yml` file defines project-wide settings.

### Schema

```yaml
schema: 1 # Required: Schema version (currently 1)
```

### Directory Structure

```yaml
# Episode directory naming pattern
# Supports placeholders: %{episode_number}, %{episode_slug}, %{date}
# Use %<episode_number>03d for padded numbers (e.g., 001)
episode_dir: episodes/%<episode_number>03d-%{episode_slug}

# Output directory for generated videos
# Supports placeholder: %{episode_dirname}
output_dir: output/%{episode_dirname}

# Resource directories (searched in order)
resources_dir:
  - .
  - "%{episode_dir}"
  - resources
  - "%{episode_dir}/resources"
  - ~/Library/Fonts
  - /usr/share/fonts
```

### Background Music

```yaml
# String: Path to specific backtrack file
backtrack: resources/music/background.mp3

# String: Directory - random file selected
backtrack: backtracks/

# Boolean: Disable backtrack
backtrack: false
```

### Watermark

```yaml
# Simple string path
watermark: watermark.png

# Detailed configuration
watermark:
  path: "watermark.png"
  anchor: [right, bottom]  # Positioning
  margin: 100              # Margin from edge (pixels)
  opacity: 0.8             # 0.0 to 1.0

# Disable watermark
watermark: false
```

### Callout Definitions

Define reusable callout styles:

```yaml
callouts:
  default:
    background_color: "#ffff00"
    shadow: "#2242d3" # Color string or false

    # Title styling
    title_style:
      color: "#000000"
      size: 40
      font_path: opensans/OpenSans-ExtraBold.ttf

    # Body styling
    body_style:
      color: "#000000"
      size: 32
      font_path: opensans/OpenSans-Semibold.ttf

    # Positioning
    anchor: [left, bottom] # [horizontal, vertical]
    margin: 100 # Margin from anchor edge
    padding: 50 # Internal padding

    # Animation
    animation: fade # "fade" or "slide"

    # Transitions
    in_transition:
      duration: 0.4
      sound: pop.mp3

    out_transition:
      duration: 0.3
      sound:
        path: pop.mp3
        volume: 0.7 # 0.0 to 1.0

  warning:
    background_color: "#ff6600"
    # ... additional callout types
```

---

## Episode Configuration

The `episodes/*/config.yml` file defines episode-specific settings.

### Basic Settings

```yaml
# Required: Episode title (displayed in intro)
title: "Creating Screencasts with ScreenKit"
```

### Episode-Specific Overrides

Episodes can override project settings:

```yaml
# Override backtrack
backtrack: resources/custom-music.mp3
backtrack: false  # Disable for this episode

# Override TTS settings
tts:
  engine: elevenlabs
  voice_id: custom_voice_id

# Override watermark
watermark: false
```

### Callout Instances

Define when and where callouts appear:

```yaml
callouts:
  - type: info # References callout defined in project config
    title: "ScreenKit"
    body: "Visit https://github.com/fnando/screenkit"
    starts_at: 3 # Start time (seconds or HH:MM:SS)
    duration: 5 # Duration in seconds
    width: 600 # Optional: Override width (pixels or percentage)

  - type: warning
    title: "Important"
    body: "Remember to save your work"
    starts_at: "00:01:30" # HH:MM:SS format
    duration: 4
    width: "50%" # Percentage of screen width
```

#### Time Formats

- **Seconds**: `starts_at: 90` (90 seconds)
- **HH:MM:SS**: `starts_at: "00:01:30"` (1 minute 30 seconds)
- **Duration**: Always in seconds or time units (`5s`, `2m`, `1h`)

---

## Scenes

ScreenKit supports three scene types: **intro**, **outro**, and **segment**.

### Intro Scene

Opening scene with logo and title.

```yaml
scenes:
  intro:
    duration: 5.5      # Scene duration (seconds)
    fade_in: 0         # Fade-in duration
    fade_out: 0.5      # Fade-out duration

    # Background (color or image path)
    background: "#100f50"
    background: resources/intro-bg.png

    # Title text
    title:
      x: 100           # X position (pixels or "center")
      y: 300           # Y position (pixels or "center")
      font_path: opensans/OpenSans-ExtraBold.ttf
      size: 144        # Font size
      color: "#ffffff"

    # Logo
    logo:
      path: logo.png
      x: 100           # X position (pixels or "center")
      y: 200           # Y position (pixels or "center")
      width: 300       # Width in pixels (height auto-calculated)

    # Sound effect
    sound: chime.mp3
    sound: false       # Disable sound
```

### Outro Scene

Closing scene with logo.

```yaml
scenes:
  outro:
    duration: 5.5
    fade_in: 0.5
    fade_out: 0.5
    background: "#100f50"

    logo:
      path: logo.png
      x: center # Center horizontally
      y: center # Center vertically
      width: 300

    sound: chime.mp3
```

### Segment Scene

Main content configuration.

```yaml
scenes:
  segment:
    # Crossfade duration between video segments
    crossfade_duration: 0.5
```

---

## Callouts

Callouts (also known as lower thirds) are informational overlays that appear
during the video.

### Callout Styles

ScreenKit provides two built-in callout styles:

#### Default Style

The default style displays a title and body in a box with optional shadow.

```yaml
callouts:
  info:
    style: default                    # Optional: defaults to "default"
    background_color: "#ffff00"       # Background color (hex)

    # Shadow
    shadow: "#2242d3"                 # Simple shadow (color)
    shadow:                           # Detailed shadow
      color: "#2242d3"
      offset: 10                      # Shadow offset in pixels
    shadow: false                     # No shadow

    # Text Styles
    title_style:
      color: "#000000"
      size: 40
      font_path: opensans/OpenSans-ExtraBold.ttf

    body_style:
      color: "#000000"
      size: 32
      font_path: opensans/OpenSans-Semibold.ttf

    # Layout
    padding: 50                       # Internal padding (pixels)
    margin: 100                       # Margin from edge (pixels)
    anchor: [left, bottom]            # Position anchor point

    # Animation
    animation: fade                   # "fade" or "slide"

    # Transitions
    in_transition:
      duration: 0.4                   # Transition duration (seconds)
      sound: pop.mp3                  # Sound effect

    out_transition:
      duration: 0.3
      sound:
        path: pop.mp3
        volume: 0.7                   # Volume (0.0 to 1.0)
```

**Usage in episode:**

```yaml
callouts:
  - type: info
    title: "ScreenKit"
    body: "Visit https://github.com/fnando/screenkit"
    starts_at: 3
    duration: 5
```

#### Inline Block Style

The inline block style displays text with a background highlight on each line,
similar to syntax highlighting or code comments. Perfect for displaying code
snippets, commands, or short inline text.

```yaml
callouts:
  code:
    style: inline_block
    background_color: "#000000" # Background color (hex)

    # Text Style (single style for all text)
    text_style:
      color: "#ffffff"
      size: 40
      font_path: opensans/OpenSans-ExtraBold.ttf

    # Layout
    padding: 20 # Padding around text (pixels)
    margin: 100 # Margin from edge (pixels)
    anchor: [left, center] # Position anchor point
    width: 600 # Maximum width (pixels)

    # Animation
    animation: fade # "fade" or "slide"

    # Transitions
    in_transition:
      duration: 0.4
      sound: false

    out_transition:
      duration: 0.3
      sound: false
```

**Usage in episode:**

```yaml
callouts:
  # Single line text (auto-wrapped)
  - type: code
    text: "npm install screenkit --save-dev"
    starts_at: 5
    duration: 4

  # Multi-line text (explicit line breaks)
  - type: code
    text: |
      git add .
      git commit -m "Update"
      git push
    starts_at: 15
    duration: 6
```

**Key differences from default style:**

- Uses `text` instead of `title` and `body`
- Only one `text_style` (no separate title/body styles)
- No `shadow` option
- Each line gets its own background rectangle
- Text can include manual line breaks (`\n`)
- Auto-wraps based on `width` if no line breaks present

### Anchor Positions

Anchor determines where the callout is positioned:

**Horizontal**: `left`, `center`, `right`  
**Vertical**: `top`, `center`, `bottom`

```yaml
anchor: [left, top]      # Top-left corner
anchor: [center, center] # Center of screen
anchor: [right, bottom]  # Bottom-right corner
```

### Position Values

- **Pixels**: `x: 100`, `y: 200`
- **Center**: `x: center`, `y: center`

### Size Values

- **Pixels**: `width: 600`
- **Percentage**: `width: "50%"` (percentage of screen width)

---

## Text-to-Speech (TTS)

ScreenKit supports multiple TTS engines for voiceovers.

### macOS `say` Engine

Uses the built-in macOS `say` command.

```yaml
tts:
  engine: say
  voice: Alex # Optional: Voice name
  rate: 150 # Words per minute (optional)
```

### ElevenLabs Engine

Professional AI voice synthesis.

```yaml
tts:
  engine: elevenlabs
  voice_id: "56AoDkrOh6qfVPDXZ7Pt" # Required: ElevenLabs voice ID
  language_code: en # 2-letter language code

  # Optional: Voice settings
  voice_settings:
    speed: 0.9 # Speech speed (default: 1.0)
    stability: 0.5 # Voice stability (0.0 - 1.0)
    similarity: 0.75 # Voice similarity (0.0 - 1.0)
    style: 0.0 # Speaking style (0.0+)

  # Optional: Output format
  output_format: mp3_44100_128

  # Optional: Model ID
  model_id: eleven_monolingual_v1
```

#### ElevenLabs Output Formats

- MP3: `mp3_22050_32`, `mp3_44100_128`, `mp3_44100_192`
- PCM: `pcm_16000`, `pcm_24000`, `pcm_44100`
- Opus: `opus_48000_32`, `opus_48000_64`
- Others: `ulaw_8000`, `alaw_8000`

### Disable TTS

```yaml
tts: false
```

### Custom TTS Engines

You can create custom TTS engines by placing them in the `ScreenKit::TTS`
module. Custom engines must implement the `generate` method:

```ruby
module ScreenKit
  module TTS
    class CustomEngine
      include Shell
      extend SchemaValidator

      # Optional: Define schema path for validation
      def self.schema_path
        ScreenKit.root_dir.join("screenkit/schemas/tts/custom_engine.json")
      end

      def initialize(**options)
        @options = options
        # Validate options against schema if defined
        self.class.validate!(@options) if respond_to?(:validate!)
      end

      def generate(text:, output_path:, log_path: nil)
        # Generate audio file from text
        # Write output to output_path
        # Optionally log to log_path

        # Example implementation:
        # File.write(output_path, generated_audio_data)
      end
    end
  end
end
```

**Configuration:**

```yaml
tts:
  engine: custom_engine # Camelized to CustomEngine
  # Add your custom options here
  api_key: your_api_key
  custom_option: value
```

The engine name is camelized (e.g., `custom_engine` → `CustomEngine`,
`google_cloud` → `GoogleCloud`) and loaded as
`ScreenKit::TTS::#{CamelizedName}`.

---

## Animations

ScreenKit supports two animation types for callouts:

### Fade Animation

Callouts fade in and out with opacity changes.

```yaml
animation: fade
in_transition:
  duration: 0.4
out_transition:
  duration: 0.3
```

**Behavior:**

- Fades in from transparent to opaque
- Remains visible
- Fades out to transparent

### Slide Animation

Callouts slide in from the left and slide out to the left with blur effects.

```yaml
animation: slide
in_transition:
  duration: 0.4
out_transition:
  duration: 0.3
```

**Behavior:**

- Slides in from left (off-screen to position) with blur
- Sharp focus when static
- Slides out to left with blur

---

## File Structure

### Episode Directory Structure

```
episodes/001-episode-name/
├── config.yml              # Episode configuration
├── content/                # Terminal recordings
│   ├── 001.tape           # VHS tape files
│   ├── 002.tape
│   └── ...
├── scripts/                # Voiceover scripts
│   ├── 001.txt            # Text for TTS
│   ├── 002.txt
│   └── ...
├── voiceovers/             # Generated audio
│   ├── 001.aiff
│   ├── 002.aiff
│   └── ...
└── resources/              # Episode-specific resources
    ├── images/
    ├── sounds/
    └── fonts/
```

### VHS Tape Files

ScreenKit uses [VHS](https://github.com/charmbracelet/vhs) tape files for
terminal recordings:

```tape
# content/001.tape
Type "echo 'Hello, World!'"
Sleep 100ms
Enter
Sleep 2s
```

### Script Files

Plain text files for voiceover generation:

```txt
# scripts/001.txt
Welcome to this tutorial on ScreenKit.
Today we'll learn how to create amazing screencasts.
```

### Naming Convention

Files are matched by number:

- `content/001.tape` → `scripts/001.txt` → `voiceovers/001.aiff`
- Segments are processed in numerical order
- Missing scripts create silent segments

---

## Advanced Features

### Resource Lookup

Resources are searched in order from `resources_dir`:

1. Current directory
2. Episode directory
3. Project resources
4. Episode resources
5. System font directories

Reference resources by partial path:

```yaml
font_path: opensans/OpenSans-Bold.ttf # Found in resources/fonts/
```

### Placeholders

#### Project Configuration

- `%{episode_number}` - Episode number (1, 2, 3...)
- `%<episode_number>03d` - Padded episode number (001, 002, 003...)
- `%{episode_slug}` - URL-friendly episode title
- `%{date}` - Current date (`YYYY-MM-DD`)
- `%{episode_dirname}` - Episode directory name

```yaml
episode_dir: episodes/%<episode_number>03d-%{episode_slug}
output_dir: output/%{episode_dirname}
```

### Color Formats

Colors support hex format with optional alpha channel:

```yaml
# 6-character hex (RGB)
color: "#ffffff"      # White

# 8-character hex (RGBA) - includes alpha channel for transparency
color: "#ffffff80"    # White with 50% transparency
```

Alpha channel values range from `00` (fully transparent) to `ff` (fully opaque).

### Sound Configuration

Three ways to specify sounds:

```yaml
# String path
sound: pop.mp3

# Detailed configuration
sound:
  path: pop.mp3
  volume: 0.7  # 0.0 to 1.0

# Disable
sound: false
```

### Shadow Configuration

```yaml
# Simple color
shadow: "#2242d3"

# Detailed configuration
shadow:
  color: "#2242d3"
  offset: 10  # Pixels

# Disable
shadow: false
```

### Background Configuration

```yaml
# Solid color
background: "#100f50"

# Image path
background: resources/background.png
```

### Spacing Configuration

Spacing values accept:

```yaml
margin: 100 # Single value (all sides)
padding: 50 # Single value (all sides)
```

### Text Wrapping

Long titles are automatically wrapped based on approximate text width. Manual
line breaks in the episode title are preserved.

---

## Schema Validation

ScreenKit validates configurations against JSON schemas:

- **Project**: `lib/screenkit/schemas/project.json`
- **Episode**: `lib/screenkit/schemas/episode.json`
- **Callouts**: `lib/screenkit/schemas/callouts/*.json`
- **TTS**: `lib/screenkit/schemas/tts/*.json`

Use the `yaml-language-server` comment for IDE support:

```yaml
# yaml-language-server: $schema=../../schemas/project.json
```

---

## Export Process

When exporting an episode, ScreenKit:

1. **Validates** project and episode configurations
2. **Generates voiceovers** from script files (if TTS enabled)
3. **Renders terminal recordings** from tape files using VHS
4. **Combines segments** with crossfade transitions
5. **Adds intro/outro** scenes
6. **Overlays callouts** with animations
7. **Applies watermark** (if configured)
8. **Mixes background music** (if configured)
9. **Outputs final video** to the output directory

### Segment Filtering

Export only specific segments:

```bash
screenkit episode export --dir episodes/001-test --match-segment "002"
```

This processes only segments matching "002" (e.g., `002.tape`, `003.tape` won't
be processed).

---

## Tips & Best Practices

### Performance

- Use `--match-segment` during development to export only changed segments
- Place frequently-accessed resources in the first `resources_dir` entry
- Use high-resolution logos (2x target size) for best quality

### Audio

- Keep voiceover scripts concise and natural
- Test TTS voices before bulk generation
- Background music volume is automatically adjusted to not overpower voiceovers

### Visuals

- Use consistent branding across callouts
- Test callout timing with `screenkit callout` command
- PNG images with transparency work best for logos and watermarks

### Organization

- Use numbered segments (001, 002, etc.) for proper ordering
- Keep episode-specific resources in episode directories
- Use descriptive callout type names (`info`, `warning`, `tip`, etc.)

---

## Troubleshooting

### Common Issues

**"Gem not found" error:**

```bash
bundle install
bundle exec screenkit ...
```

**"Schema validation failed":**

- Check YAML syntax
- Verify required fields are present
- Use schema hints with `yaml-language-server`

**Missing resources:**

- Check `resources_dir` configuration
- Verify file paths are relative to resource directories
- Use absolute paths for system resources

**TTS not working:**

- For ElevenLabs: Set `--voice-api-key` or `ELEVENLABS_API_KEY` env variable
- For macOS `say`: Verify voice name with `say -v ?`

---

## Contributing

For development and contribution guidelines, see:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

---

## License

MIT License - See [LICENSE.md](LICENSE.md)

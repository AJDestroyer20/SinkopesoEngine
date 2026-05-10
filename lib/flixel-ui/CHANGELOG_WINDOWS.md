# Changelog - Windows Theme

## [Windows Edition] - 2026-05-06

### 🎨 Visual Changes
- Redesigned all UI elements with Windows 95/98/2000 aesthetic
- Implemented classic 3D border effects using 4-color shading system
- Changed color palette from vibrant to Windows gray (#C0C0C0)
- Added navy blue title bars (#000080)
- Created yellow tooltip backgrounds (#FFFFE1)

### 🖼️ New Assets
- `button.png` - 3D raised button with Windows border
- `button_thin.png` - Thinner variant of the button
- `chrome.png` - Window frame with blue title bar
- `chrome_inset.png` - Inset/sunken border for inputs
- `tab.png` - Tab with rounded top corners
- `check_mark.png` - Black checkmark icon
- `radio_dot.png` - Black circular dot for radio buttons
- `dropdown_mark.png` - Downward pointing triangle
- `button_arrow_up.png` - Up arrow
- `button_arrow_down.png` - Down arrow
- `button_arrow_left.png` - Left arrow
- `button_arrow_right.png` - Right arrow
- `plus_mark.png` - Plus sign icon
- `hilight.png` - Navy blue highlight overlay
- `tooltip_arrow.png` - Tooltip pointer with 3D effect
- `swatch.png` - Color swatch with inset border

### 📝 Configuration Files
- Added `windows_theme.xml` - Complete Windows theme configuration
- Updated `defaults.xml` - Changed text colors from white to black
- Removed text outlines for cleaner look

### 🔧 Technical Details
**3D Border Algorithm:**
- Top/Left borders: White (#FFFFFF) + Light gray (#DFDFDF)
- Bottom/Right borders: Dark gray (#404040) + Medium gray (#808080)
- Creates realistic depth perception

**Color Palette:**
- Button Face: #C0C0C0 (RGB: 192, 192, 192)
- Highlight: #FFFFFF (RGB: 255, 255, 255)
- Light: #DFDFDF (RGB: 223, 223, 223)
- Shadow: #808080 (RGB: 128, 128, 128)
- Dark Shadow: #404040 (RGB: 64, 64, 64)
- Title Blue: #000080 (RGB: 0, 0, 128)
- Window Text: #000000 (RGB: 0, 0, 0)
- Desktop Teal: #008080 (RGB: 0, 128, 128)

### 📚 Documentation
- Created `README_WINDOWS.md` with theme overview
- Added usage examples and visual comparisons

### ⚡ Performance
- All assets remain lightweight PNG format
- No performance impact vs original theme
- 100% backward compatible with Flixel-UI

### 🎯 Design Goals
1. Authentic Windows 95/98/2000 look and feel
2. Pixel-perfect recreation of classic UI elements
3. Nostalgic yet functional design
4. Maintain full compatibility with Flixel-UI API

---
*Coded with 🪟 and nostalgia*

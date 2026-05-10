# Flixel-UI Windows Theme

Fork de Flixel-UI con estilo visual de Windows 95/98/2000

## Características

### 🎨 Paleta de Colores Clásica
- **Button Face**: `#C0C0C0` - Gris característico de botones
- **3D Highlight**: `#FFFFFF` y `#DFDFDF` - Bordes iluminados
- **3D Shadow**: `#808080` y `#404040` - Sombras para efecto 3D
- **Title Bar**: `#000080` - Azul marino clásico
- **Window Text**: `#000000` - Texto negro
- **Tooltip**: `#FFFFE1` - Amarillo claro

### 🖼️ Elementos Gráficos
Todos los assets han sido recreados con el estilo visual de Windows:

- **Botones**: Bordes 3D elevados con efecto de profundidad
- **Chrome**: Ventanas con barra de título azul
- **Chrome Inset**: Áreas hundidas para inputs
- **Checkboxes**: Cajas blancas con borde negro y checkmark
- **Radio Buttons**: Círculos con punto central
- **Tabs**: Pestañas con bordes superiores redondeados
- **Arrows**: Flechas para navegación y dropdowns
- **Tooltips**: Fondo amarillo con borde negro

### 📐 Efectos 3D
Los botones y ventanas usan el sistema de iluminación clásico de Windows:
- Borde superior e izquierdo: Colores claros (blanco/gris claro)
- Borde inferior y derecho: Colores oscuros (gris oscuro/negro)
- Esto crea la ilusión de una fuente de luz desde arriba-izquierda

### 🎯 Archivos Principales
- `assets/xml/windows_theme.xml` - Configuración completa del tema
- `assets/xml/defaults.xml` - Definiciones de texto actualizadas
- `assets/images/*.png` - Assets gráficos estilo Windows

### 🚀 Uso
Importa el tema Windows en tu proyecto Flixel:
```haxe
FlxUIState.static_constructor();
FlxUIAssets.loadTheme("assets/xml/windows_theme.xml");
```

## Comparación Visual

### Antes (Original Flixel-UI)
- Colores brillantes y saturados
- Bordes simples
- Estilo moderno/flat

### Después (Windows Theme)
- Gris neutro (#C0C0C0)
- Bordes 3D con sombras
- Estilo retro de los 90s
- Barra de título azul marino
- Tooltips amarillos

## Cambios Técnicos

1. **Paleta de colores**: De colores vibrantes a gris Windows
2. **Tipografía**: Texto negro sin outline (más legible)
3. **Bordes**: Sistema de 4 colores para efecto 3D
4. **Íconos**: Rediseñados con estilo pixel-art simple
5. **Ventanas**: Barra de título azul con gradiente sutil

## Compatibilidad
Mantiene 100% de compatibilidad con Flixel-UI original. Solo cambia la apariencia visual, no la funcionalidad.

---
*Nostalgia de Windows 95 incluida* 🪟

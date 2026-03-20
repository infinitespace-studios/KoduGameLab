using Microsoft.Xna.Framework;

namespace TileProcessor
{
    public class UIMeshData
    {
        public BoundingBox bBox;
    }
}

namespace Boku.Common
{
    public class WinKeyboard
    {
        public KeyboardInput.KeyboardCharEvent CharacterEntered;
    }

    public class BitmapFont
    {
        public int LineHeight { get; set; }
        public int MeasureString(string text) { return 0; }
        public void DrawString(int x, int y, Color color, string text) { }
    }

    public class BokuSettings
    {
        private static BokuSettings instance = new BokuSettings();
        public static BokuSettings Settings { get { return instance; } }
        public static void Save() { }
        public bool FullScreen { get; set; }
        public bool PostEffects { get; set; } = true;
        public bool Audio { get; set; } = true;
        public bool AntiAlias { get; set; }
        public bool PreferReach { get; set; }
        public bool Vsync { get; set; } = true;
        public bool Animation { get; set; } = true;
        public bool UseSystemFontRendering { get; set; }
        public string Language { get; set; } = "en";
        public int ResolutionX { get; set; } = 1280;
        public int ResolutionY { get; set; } = 720;
        public int TerrainRenderMethod { get; set; }
        public string UserFolder { get; set; } = string.Empty;
    }

    public class Touch
    {
        public int fingerId;
        public Vector2 position;
        public Vector2 deltaPosition;
        public float deltaTime;
        public TouchPhase phase;
    }

    public enum TouchPhase
    {
        Began,
        Moved,
        Stationary,
        Ended
    }
}

namespace Boku.XnaCompat
{
    public enum VertexElementMethod
    {
        Default = 0,
    }
}

namespace Boku.Input
{
    public interface IMicrobitTile
    {
    }
}

namespace Microsoft.Xna.Framework.Graphics
{
    public static class XnaEffectExtensions
    {
        public static void Begin(this Effect effect) { }
        public static void End(this Effect effect) { }
        public static void Begin(this EffectPass pass) { pass.Apply(); }
        public static void End(this EffectPass pass) { }
    }
}

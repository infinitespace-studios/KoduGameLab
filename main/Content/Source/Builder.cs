/// <summary>
/// Entry point for the Content Builder project.
/// Builds content according to the Content Collection Strategy defined in the Builder class.
/// </summary>

using Microsoft.Xna.Framework.Content.Pipeline;
using Microsoft.Xna.Framework.Content.Pipeline.Processors;
using MonoGame.Framework.Content.Pipeline.Builder;
using BokuContentProcessors;

var contentCollectionArgs = new ContentBuilderParams()
{
    Mode = ContentBuilderMode.Builder,
    WorkingDirectory = $"{AppContext.BaseDirectory}../../../",
    SourceDirectory = "Assets",
    Platform = TargetPlatform.DesktopGL
};
var builder = new Builder();

if (args is not null && args.Length > 0)
{
    builder.Run(args);
}
else
{
    builder.Run(contentCollectionArgs);
}

return builder.FailedToBuild > 0 ? -1 : 0;

public class Builder : ContentBuilder
{
    public override IContentCollection GetContentCollection()
    {
        var contentCollection = new ContentCollection();

        // Include all standard assets
        contentCollection.Include<WildcardRule>("*");

        // FBX models use Assimp-based FbxImporter
        contentCollection.Include<WildcardRule>("**/*.fbx", new FbxImporter(), new ModelProcessor());

        // Exclude legacy content project files
        contentCollection.Exclude<WildcardRule>("*.mgcb");
        contentCollection.Exclude<WildcardRule>("*.contentproj");

        // Exclude XML data files (loaded at runtime via XmlSerializer, not content pipeline)
        contentCollection.Exclude<WildcardRule>("Xml/**/*.xml");
        contentCollection.Exclude<WildcardRule>("Xml/**/*.Xml");

        // Exclude raw text/data files
        contentCollection.Exclude<WildcardRule>("Text/**/*");

        // Process censor CSV files with custom pipeline
        contentCollection.Include<WildcardRule>("Text/Censor/*.csv",
            new CensorContentImporter(), new CensorContentProcessor());

        // Exclude WAV audio files for now (audio system needs XACT replacement)
        contentCollection.Exclude<WildcardRule>("**/*.wav");

        // Exclude Unicode data files
        contentCollection.Exclude<WildcardRule>("**/*.txt");

        return contentCollection;
    }
}

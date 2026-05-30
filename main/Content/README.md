# Content Builder

Run `dotnet run --project main/Content/Builder.csproj` after a clean of `main/Content/bin` and `main/Content/obj` when rebuilding content. The builder also removes its generated content output/cache before each MSBuild build so stale XNBs from older pipelines cannot be reused.

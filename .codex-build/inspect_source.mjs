import fs from "node:fs/promises";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const sourcePath = "/Users/pro/Downloads/The_Little_Bird_Story_Hindi_English (7).pptx";
const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));

const content = await presentation.inspect({
  select: "$.slides[*]",
  include: [
    "id",
    "index",
    "layout",
    "title",
    "elements.id",
    "elements.name",
    "elements.kind",
    "elements.text",
    "elements.alt",
    "elements.position",
    "elements.style",
    "elements.paragraphs",
  ],
});

const summary = {
  slideSize: presentation.slideSize,
  slideCount: presentation.slides.items.length,
  masters: presentation.masters.items.map((master) => ({
    id: master.id,
    name: master.name,
    placeholderSummary: master.placeholders?.summary?.(),
  })),
  layouts: presentation.layouts.items.map((layout) => ({
    id: layout.id,
    name: layout.name,
    placeholderSummary: layout.placeholders?.summary?.(),
  })),
};

await fs.writeFile(
  "/Users/pro/Downloads/SiteSevaPro-main/.codex-build/analysis/source-summary.json",
  JSON.stringify(summary, null, 2),
);
await fs.writeFile(
  "/Users/pro/Downloads/SiteSevaPro-main/.codex-build/analysis/source-content.ndjson",
  content.ndjson,
);

console.log(JSON.stringify(summary, null, 2));
console.log(`Wrote ${content.recordCount} slide records.`);

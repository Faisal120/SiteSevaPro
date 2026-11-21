import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/pro/Downloads/SiteSevaPro-main";
const buildDir = path.join(workspaceDir, ".codex-build");
const assetsDir = path.join(buildDir, "assets");
const renderDir = path.join(buildDir, "render-v3");
const stagingDir = path.join(buildDir, "finalizer-v3");
const finalPath = path.join(
  workspaceDir,
  "output/pptx/The_Little_Bird_Lion_Format.pptx",
);
const sourceContentPath = path.join(buildDir, "analysis/source-content.ndjson");
const skillDir = "/Users/pro/.codex/plugins/cache/openai-primary-runtime/presentations/26.1118.11504/skills/presentations";
const runtimePython = "/Users/pro/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";

const W = 10692000 / 9525;
const H = 7560000 / 9525;

const C = {
  white: "#FFFFFF",
  ink: "#16211D",
  green: "#1D6A3D",
  pink: "#E23A72",
  lime: "#E5F23C",
  amber: "#E4A51B",
  cream: "#FFE9B2",
  tanLine: "#C9974D",
  muted: "#58635E",
};

const LATIN_FONT = "Arial";
const HINDI_FONT = "Arial Unicode MS";

const sourceSlides = (await fs.readFile(sourceContentPath, "utf8"))
  .trim()
  .split(/\r?\n/)
  .map((line) => JSON.parse(line));

const imageBySlide = [
  "image1.jpg",
  "image3.jpg",
  "image4.jpg",
  "image6.jpg",
  "image8.jpg",
  "image10.jpg",
  "image11.jpg",
  "image13.jpg",
  "image15.jpg",
  "image17.jpg",
  "image19.jpg",
  "image21.jpg",
  "image23.jpg",
  "image25.jpg",
  "image27.jpg",
  "image29.jpg",
  "image31.jpg",
  "image32.jpg",
  "image34.jpg",
  "image35.jpg",
  "image35.jpg",
  "image35.jpg",
  "image38.jpg",
  "image40.jpg",
  "image42.jpg",
  "image43.jpg",
  "image45.jpg",
  "image46.jpg",
];

const imageBytesByName = Object.fromEntries(
  await Promise.all(
    [...new Set(imageBySlide)].map(async (imageName) => [
      imageName,
      new Uint8Array(await fs.readFile(path.join(assetsDir, imageName))),
    ]),
  ),
);

function addText(slide, {
  name,
  text,
  left,
  top,
  width,
  height,
  fontSize,
  fontFamily = LATIN_FONT,
  color = C.ink,
  bold = false,
  alignment = "left",
  verticalAlignment = "top",
  autoFit = "shrinkText",
  lineSpacing = 1,
  fill = "none",
  lineFill = "none",
  lineWidth = 0,
  borderRadius,
  insets = 0,
}) {
  const shape = slide.shapes.add({
    geometry: borderRadius ? "roundRect" : "textbox",
    name,
    position: { left, top, width, height },
    fill,
    line: { style: "solid", fill: lineFill, width: lineWidth },
    ...(borderRadius ? { borderRadius } : {}),
  });
  shape.text = text;
  shape.text.style = {
    fontSize,
    typeface: fontFamily,
    color,
    bold,
    alignment,
    verticalAlignment,
    autoFit,
    lineSpacing,
    wrap: "square",
    insets,
  };
  return shape;
}

function addHeader(slide, rawTitle) {
  let title = rawTitle.replace(/\s*•\s*/g, " - ").toUpperCase();
  if (/^MA'AM$/i.test(rawTitle.trim())) title = "MA'AM - NARRATION";
  const tagWidth = Math.max(150, Math.min(440, 58 + title.length * 7.2));
  addText(slide, {
    name: "Role label",
    text: title,
    left: (W - tagWidth) / 2,
    top: 42,
    width: tagWidth,
    height: 20,
    fontSize: "8pt",
    color: C.green,
    bold: true,
    alignment: "center",
    verticalAlignment: "middle",
    fill: C.lime,
    insets: 2,
  });
  slide.shapes.add({
    geometry: "rect",
    name: "Amber divider",
    position: { left: 0, top: 85, width: W, height: 2.5 },
    fill: C.amber,
    line: { style: "solid", fill: "none", width: 0 },
  });
}

function addStoryImage(slide, slideNumber) {
  const imageName = imageBySlide[slideNumber - 1];
  slide.images.add({
    blob: imageBytesByName[imageName],
    contentType: "image/jpeg",
    alt: `Original Little Bird story illustration for slide ${slideNumber}`,
    fit: "cover",
    position: { left: 500, top: 137, width: 602, height: 430 },
  });
}

function bodySizes(english, hindi) {
  const maxLen = Math.max(english.length, hindi.length);
  if (maxLen > 190) return { en: "17pt", hi: "15pt", y: 164, h: 545 };
  if (maxLen > 125) return { en: "20pt", hi: "17pt", y: 188, h: 500 };
  if (maxLen > 75) return { en: "23pt", hi: "19pt", y: 220, h: 435 };
  return { en: "27pt", hi: "22pt", y: 246, h: 390 };
}

function addDialogue(slide, English, Hindi) {
  const sizes = bodySizes(English, Hindi);
  const gap = 18;
  const englishShare = English.length / Math.max(1, English.length + Hindi.length);
  const englishHeight = Math.max(145, Math.min(300, sizes.h * englishShare));
  const hindiHeight = sizes.h - englishHeight - gap;
  addText(slide, {
    name: "English dialogue",
    text: English,
    left: 22,
    top: sizes.y,
    width: 438,
    height: englishHeight,
    fontSize: sizes.en,
    color: C.ink,
    bold: true,
    lineSpacing: 1.02,
    verticalAlignment: "middle",
  });
  addText(slide, {
    name: "Hindi dialogue",
    text: Hindi,
    left: 22,
    top: sizes.y + englishHeight + gap,
    width: 438,
    height: hindiHeight,
    fontSize: sizes.hi,
    fontFamily: HINDI_FONT,
    color: C.pink,
    lineSpacing: 1.02,
    verticalAlignment: "top",
  });
}

const presentation = Presentation.create({
  slideSize: { width: W, height: H },
});

// Slide 1: cover in the reference deck's title/value composition.
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  const titleBox = slide.shapes.add({
    geometry: "roundRect",
    name: "Cover title box",
    position: { left: 156, top: 66, width: 810, height: 70 },
    fill: C.cream,
    line: { style: "solid", fill: C.tanLine, width: 1.5 },
    borderRadius: "rounded-xl",
  });
  titleBox.text = "THE LITTLE BIRD WHO TOOK RESPONSIBILITY";
  titleBox.text.style = {
    fontSize: "24pt",
    typeface: LATIN_FONT,
    bold: true,
    color: C.ink,
    alignment: "center",
    verticalAlignment: "middle",
    autoFit: "shrinkText",
    insets: 8,
  };
  slide.shapes.add({
    geometry: "rect",
    name: "Amber divider",
    position: { left: 0, top: 164, width: W, height: 2.5 },
    fill: C.amber,
    line: { style: "solid", fill: "none", width: 0 },
  });
  addText(slide, {
    name: "Cover Hindi title",
    text: "छोटी चिड़िया, जिसने अपनी ज़िम्मेदारी ली",
    left: 46,
    top: 306,
    width: 410,
    height: 94,
    fontSize: "24pt",
    fontFamily: HINDI_FONT,
    color: C.pink,
    bold: true,
    verticalAlignment: "middle",
    lineSpacing: 1.05,
  });
  addText(slide, {
    name: "Story type",
    text: "PLAYGROUP STORY ACT",
    left: 46,
    top: 246,
    width: 405,
    height: 40,
    fontSize: "14pt",
    color: C.muted,
    bold: true,
    verticalAlignment: "middle",
  });
  addText(slide, {
    name: "Cover value",
    text: "VALUE: RESPONSIBILITY | मूल्य: ज़िम्मेदारी",
    left: 46,
    top: 424,
    width: 425,
    height: 85,
    fontSize: "18pt",
    fontFamily: HINDI_FONT,
    color: C.green,
    bold: true,
    verticalAlignment: "middle",
    lineSpacing: 1.05,
  });
  slide.images.add({
    blob: imageBytesByName[imageBySlide[27]],
    contentType: "image/jpeg",
    alt: "The Little Bird and friends together in the garden",
    fit: "cover",
    position: { left: 500, top: 225, width: 602, height: 380 },
  });
}

// Slide 2: character list, still in the white A4 reference style.
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  addHeader(slide, "Our Characters - हमारे पात्र");
  const characterColumns = sourceSlides[1].elements.filter((element) =>
    String(element.name).startsWith("Characters column"),
  );
  const columnLefts = [42, 385, 728];
  characterColumns.forEach((column, columnIndex) => {
    const lines = column.text.split(/\r?\n/);
    const paragraphs = lines.map((line, lineIndex) => [
      {
        run: line,
        style: {
          fontSize: lineIndex % 2 === 0 ? "14pt" : "12.5pt",
          typeface: lineIndex % 2 === 0 ? LATIN_FONT : HINDI_FONT,
          color: lineIndex % 2 === 0 ? C.ink : C.pink,
          bold: lineIndex % 2 === 0,
        },
      },
    ]);
    const box = slide.shapes.add({
      geometry: "textbox",
      name: `Character column ${columnIndex + 1}`,
      position: { left: columnLefts[columnIndex], top: 126, width: 315, height: 435 },
      fill: "none",
      line: { style: "solid", fill: "none", width: 0 },
    });
    box.text.set(paragraphs);
    box.text.style = {
      fontSize: "14pt",
      typeface: LATIN_FONT,
      color: C.ink,
      autoFit: "shrinkText",
      lineSpacing: 0.95,
      insets: 0,
    };
    lines.forEach((line, lineIndex) => {
      if (lineIndex % 2 === 1) box.text.get(line).color = C.pink;
    });
  });
  slide.images.add({
    blob: imageBytesByName[imageBySlide[1]],
    contentType: "image/jpeg",
    alt: "Story characters caring for their garden",
    fit: "cover",
    position: { left: 0, top: 590, width: W, height: H - 590 },
  });
}

// Slides 3-27: role label, dialogue at left, original story image at right.
for (let slideIndex = 2; slideIndex <= 26; slideIndex += 1) {
  const source = sourceSlides[slideIndex];
  const slideNumber = slideIndex + 1;
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  addHeader(slide, source.title || "STORY");
  addStoryImage(slide, slideNumber);
  const dialogue = source.elements.find((element) => element.name === "Dialogue");
  const paragraphs = dialogue?.paragraphs ?? [];
  const English = paragraphs[0]?.text ?? dialogue?.text?.split(/\r?\n/)[0] ?? "";
  const Hindi = paragraphs[1]?.text ?? dialogue?.text?.split(/\r?\n/)[1] ?? "";
  addDialogue(slide, English, Hindi);
}

// Slide 28: full-width image and centered thank-you strip.
{
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  slide.images.add({
    blob: imageBytesByName[imageBySlide[27]],
    contentType: "image/jpeg",
    alt: "The Little Bird and friends together in the garden",
    fit: "cover",
    position: { left: 0, top: 0, width: W, height: 578 },
  });
  slide.shapes.add({
    geometry: "rect",
    name: "Amber divider",
    position: { left: 0, top: 578, width: W, height: 2.5 },
    fill: C.amber,
    line: { style: "solid", fill: "none", width: 0 },
  });
  addText(slide, {
    name: "Thank you",
    text: "THANK YOU!  •  धन्यवाद!",
    left: 100,
    top: 606,
    width: W - 200,
    height: 50,
    fontSize: "24pt",
    fontFamily: HINDI_FONT,
    color: C.green,
    bold: true,
    alignment: "center",
    verticalAlignment: "middle",
  });
  addText(slide, {
    name: "Closing English values",
    text: "RESPONSIBILITY | TEAMWORK | CARING FOR OUR GARDEN",
    left: 100,
    top: 668,
    width: W - 200,
    height: 31,
    fontSize: "12pt",
    color: C.ink,
    bold: true,
    alignment: "center",
    verticalAlignment: "middle",
  });
  addText(slide, {
    name: "Closing Hindi values",
    text: "ज़िम्मेदारी | मिलकर काम करना | बगीचे की देखभाल",
    left: 100,
    top: 707,
    width: W - 200,
    height: 34,
    fontSize: "13pt",
    fontFamily: HINDI_FONT,
    color: C.pink,
    alignment: "center",
    verticalAlignment: "middle",
  });
}

await fs.mkdir(renderDir, { recursive: true });
for (const [index, slide] of presentation.slides.items.entries()) {
  const preview = await presentation.export({ slide, format: "png", scale: 1 });
  const output = path.join(renderDir, `slide-${String(index + 1).padStart(2, "0")}.png`);
  await fs.writeFile(output, new Uint8Array(await preview.arrayBuffer()));
}
const montage = await presentation.export({ format: "webp", montage: true, scale: 0.5 });
await fs.writeFile(
  path.join(buildDir, "analysis/little-bird-v3-montage.webp"),
  new Uint8Array(await montage.arrayBuffer()),
);

await fs.mkdir(stagingDir, { recursive: true });
await fs.mkdir(path.dirname(finalPath), { recursive: true });
const candidatePath = path.join(stagingDir, "candidate-v3.pptx");
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

const { finalizePresentation } = await import(
  pathToFileURL(path.join(skillDir, "container_tools/artifact_tool_utils.mjs")).href
);

const result = await finalizePresentation({
  workspaceDir,
  candidatePath,
  finalPath,
  pythonExecutable: runtimePython,
  integrityValidatorPath: path.join(
    skillDir,
    "container_tools/inspect_presentation_package_integrity.py",
  ),
  layoutValidatorPath: path.join(
    skillDir,
    "container_tools/inspect_presentation_layout_geometry.py",
  ),
  layoutArgs: [
    "--expected-slide-size-emu",
    "10692000,7560000",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  explicitTotalSlideCount: 28,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  fontPolicy: {
    basis: "design",
    families: [LATIN_FONT, HINDI_FONT],
    scriptFonts: { cs: HINDI_FONT },
  },
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, "The_Little_Bird_Lion_Format.validation.json"),
});

console.log(JSON.stringify({ finalPath, slideCount: presentation.slides.items.length, result }, null, 2));

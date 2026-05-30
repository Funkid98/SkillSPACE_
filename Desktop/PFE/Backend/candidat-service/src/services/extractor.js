const pdfParse = require("pdf-parse");
const mammoth = require("mammoth");

//Extract text from a PDF buffer.

async function extractFromPdf(buffer) {
  // Handle both function and object versions of the library
  const parser = typeof pdfParse === "function" ? pdfParse : pdfParse.default;
  if (typeof parser !== "function") {
    throw new Error("pdf-parse is not a function. Version mismatch?");
  }
  const data = await parser(buffer);
  return data.text;
}

// Extract text from a DOCX buffer.

async function extractFromDocx(buffer) {
  const result = await mammoth.extractRawText({ buffer });
  return result.value;
}

// Detect file type by extension and extract text.

async function extractText(buffer, originalName) {
  const ext = originalName.split(".").pop().toLowerCase();
  if (ext === "pdf") return extractFromPdf(buffer);
  if (ext === "docx") return extractFromDocx(buffer);
  throw new Error(`Unsupported file type: .${ext}`);
}

module.exports = { extractText };

const fs = require("fs");
const path = require("path");

// Define directories to process
const directoriesToProcess = ["Components", "Navigation", "Views", "Utilities"];

// Base directory for the Swift files
const baseDir = "NavTemplate";

// Output file
const outputFile = "code.txt";

// Function to get all .swift files from a directory recursively
function getSwiftFiles(dir) {
  let results = [];
  const files = fs.readdirSync(dir);

  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      // Recursively get files from subdirectories
      results = results.concat(getSwiftFiles(fullPath));
    } else if (path.extname(file) === ".swift") {
      // Add .swift files to results
      results.push(fullPath);
    }
  }

  return results;
}

// Process directories and collect all .swift files
let allSwiftFiles = [];
directoriesToProcess.forEach((directory) => {
  const dirPath = path.join(baseDir, directory);
  try {
    if (fs.existsSync(dirPath)) {
      const files = getSwiftFiles(dirPath);
      allSwiftFiles = allSwiftFiles.concat(files);
    }
  } catch (err) {
    console.error(`Error processing directory ${dirPath}: ${err.message}`);
  }
});

// Generate output
let output = "";
allSwiftFiles.forEach((fullPath) => {
  try {
    const content = fs.readFileSync(fullPath, "utf8");
    // Get relative path from NavTemplate directory
    const relativePath = path.relative(baseDir, fullPath);
    output += `\`\`\`swift:${relativePath}\n`;
    output += content;
    output += "\n```\n\n";
  } catch (err) {
    console.error(`Error processing ${fullPath}: ${err.message}`);
  }
});

// Write the output
try {
  fs.writeFileSync(outputFile, output);
  console.log(`Successfully wrote code dump to ${outputFile}`);
  console.log(
    `Processed files:\n${allSwiftFiles
      .map((f) => path.relative(baseDir, f))
      .join("\n")}`
  );
} catch (err) {
  console.error(`Error writing output file: ${err.message}`);
}

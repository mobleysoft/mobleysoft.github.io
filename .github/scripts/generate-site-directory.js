const fs = require("fs");
const path = require("path");

const rootDir = "."; // Root directory of the repo
const outputFile = "site-directory.json"; // Root-level JSON file

function scanDirectory(dir) {
    let structure = {};
    const items = fs.readdirSync(dir, { withFileTypes: true });

    items.forEach((item) => {
        if (item.name.startsWith(".")) return; // Ignore hidden files
        const fullPath = path.join(dir, item.name);

        if (item.isDirectory()) {
            structure[item.name] = scanDirectory(fullPath);
        } else {
            structure[item.name] = "file";
        }
    });

    return structure;
}

const siteStructure = scanDirectory(rootDir);
fs.writeFileSync(outputFile, JSON.stringify(siteStructure, null, 2));
console.log("Site directory updated!");

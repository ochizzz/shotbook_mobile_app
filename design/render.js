const { chromium } = require('playwright');
const fs = require('fs');
const svg = fs.readFileSync('logo.svg', 'utf8');
(async () => {
  const b = await chromium.launch();
  const out = {};
  const sizes = JSON.parse(process.argv[2]);
  const p = await b.newPage();
  for (const [path, s] of Object.entries(sizes)) {
    await p.setViewportSize({ width: s, height: s });
    await p.setContent(`<style>html,body{margin:0}svg{display:block;width:${s}px;height:${s}px}</style>${svg}`);
    await p.screenshot({ path, omitBackground: false });
  }
  await b.close();
})();

const {deploySmarts}=require("./common.js");

async function main() {
  return deploySmarts();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

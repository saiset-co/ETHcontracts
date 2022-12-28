const {deploySmarts}=require("./common.js");
//const {deploySmarts}=require("./test_amm.js");


async function main() {
  return deploySmarts();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

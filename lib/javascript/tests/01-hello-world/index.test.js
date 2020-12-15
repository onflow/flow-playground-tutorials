import path from "path";
import { init } from "flow-js-testing/dist/utils/init";
import { deployContractByName } from "flow-js-testing/dist/utils/deploy-code";

const basePath = path.resolve(
  __dirname,
  "../../../../tutorials/01-hello-world"
);
init(basePath);

describe("test 01-hello-world tutorial", () => {
  test("deploy HelloWorld contract", async () => {
    let deployTx;

    try {
      deployTx = await deployContractByName({
        name: "HelloWorld",
      });
    } catch (e) {
      console.log(e);
    }

    expect(deployTx.errorMessage).toBe("");
  });
});

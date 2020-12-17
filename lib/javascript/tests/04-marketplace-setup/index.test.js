import { fail } from "assert";
import path from "path";
import {
  init,
  sendTransaction,
  deployContractByName,
  getAccountAddress,
  getTransactionCode,
  getContractAddress,
  getScriptCode,
  executeScript,
} from "../../flow-js-testing/src/utils";

const basePath = path.resolve(
  __dirname,
  "../../../../tutorials/04-marketplace-setup"
);

beforeAll(() => {
  init(basePath);
});

describe("Testing 'Marketplace Setup' Tutorial", () => {
  test("Deploys tutorial contracts successfully", async () => {
    const acct1 = await getAccountAddress("Account 1 (FT)");
    const acct2 = await getAccountAddress("Account 2 (NFT)");
    const acct3 = await getAccountAddress("Account 3");

    let c1, c2, c3;
    try {
      c1 = await deployContractByName({
        to: acct1,
        name: "FungibleToken",
      });
      c2 = await deployContractByName({
        to: acct2,
        name: "NonFungibleToken",
      });
      c3 = await deployContractByName({
        to: acct3,
        name: "Marketplace",
        addressMap: {
          FungibleToken: acct1,
          NonFungibleToken: acct2,
        },
      });
    } catch (e) {
      fail();
      console.log(e);
    }

    expect(c1.errorMessage).toBe("");
    expect(c2.errorMessage).toBe("");
    expect(c3.errorMessage).toBe("");
  });

  test("tx1: Create sale collection", () => {});
});

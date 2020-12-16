import { fail } from "assert";
import path from "path";
import {
  init,
  sendTransaction,
  deployContractByName,
  getAccountAddress,
  getTransactionCode,
  getContractAddress,
} from "../../flow-js-testing/src/utils";

const basePath = path.resolve(
  __dirname,
  "../../../../tutorials/02-fungible-tokens"
);

init(basePath);

describe("Testing 'Fungible Tokens' Tutorial", () => {
  describe("Deployment", () => {
    test("Deploys tutorial contracts successfully", async () => {
      let deployContract1;
      try {
        deployContract1 = await deployContractByName({
          name: "FungibleToken",
        });
      } catch (e) {
        console.log(e);
      }

      expect(deployContract1.errorMessage).toBe("");
    });
  });
  describe("Transactions (Signers required)", () => {
    test("tx1: Create Receiver capability", async () => {
      const FungibleTokenAddress = await getContractAddress("FungibleToken");

      let txCode = await getTransactionCode({
        name: "tx_01_create_capability",
        addressMap: { FungibleToken: FungibleTokenAddress },
      });

      txCode = txCode.replace(
        "getAccount(0x01)",
        `getAccount(${FungibleTokenAddress})`
      );

      try {
        const result = await sendTransaction({
          code: txCode,
          signers: [FungibleTokenAddress],
        });

        expect(result.errorMessage).toBe("");
        expect(result.status).toBe(4);
      } catch (e) {
        console.log(e);
        fail();
      }
    });
  });
  test("tx2: Configure accounts", async () => {
    const FungibleTokenAddress = await getContractAddress("FungibleToken");

    let txCode = await getTransactionCode({
      name: "tx_02_configure_account",
      addressMap: { FungibleToken: FungibleTokenAddress },
    });

    txCode = txCode.replace(
      "getAccount(0x01)",
      `getAccount(${FungibleTokenAddress})`
    );

    try {
      const result = await sendTransaction({
        code: txCode,
        signers: [FungibleTokenAddress],
      });

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });
});

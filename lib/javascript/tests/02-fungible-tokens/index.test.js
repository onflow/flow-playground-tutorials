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
  "../../../../cadence/02-fungible-tokens"
);

beforeAll(() => {
  init(basePath);
});

describe("Testing 'Fungible Tokens' Tutorial", () => {
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

  test("tx2: Configure accounts", async () => {
    const FungibleTokenAddress = await getContractAddress("FungibleToken");
    const BobAddress = await getAccountAddress("Bob");

    let txCode = await getTransactionCode({
      name: "tx_02_configure_account",
      addressMap: { FungibleToken: FungibleTokenAddress },
    });

    txCode = txCode.replace("getAccount(0x02)", `getAccount(${BobAddress})`);

    try {
      const result = await sendTransaction({
        code: txCode,
        signers: [BobAddress],
      });

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });
  test("tx3: Mint and deposit tokens", async () => {
    const FungibleTokenAddress = await getContractAddress("FungibleToken");
    const BobAddress = await getAccountAddress("Bob");

    let txCode = await getTransactionCode({
      name: "tx_03_mint_and_deposit_tokens",
      addressMap: { FungibleToken: FungibleTokenAddress },
    });

    txCode = txCode.replace("getAccount(0x02)", `getAccount(${BobAddress})`);

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
  test("script1: Read account balance", async () => {
    const FungibleTokenAddress = await getContractAddress("FungibleToken");
    const BobAddress = await getAccountAddress("Bob");

    let scriptCode = await getScriptCode({
      name: "script_01_read_balance",
      addressMap: { FungibleToken: FungibleTokenAddress },
    });

    scriptCode = scriptCode
      .replace("getAccount(0x01)", `getAccount(${FungibleTokenAddress})`)
      .replace("getAccount(0x02)", `getAccount(${BobAddress})`);

    try {
      const result = await executeScript({
        code: scriptCode,
      });

      expect(result).toBe(null);
    } catch (e) {
      console.log(e);
      fail();
    }
  });
});

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
  "../../../../tutorials/03-non-fungible-tokens"
);

beforeAll(() => {
  init(basePath);
});

describe("Testing 'Non-Fungible Tokens' Tutorial", () => {
  test("Deploys tutorial contracts successfully", async () => {
    let deployContract1, deployContract2;
    try {
      deployContract1 = await deployContractByName({
        name: "NonFungibleToken",
      });
      deployContract2 = await deployContractByName({
        name: "NonFungibleTokenBase",
      });
    } catch (e) {
      console.log(e);
    }

    expect(deployContract1.errorMessage).toBe("");
    expect(deployContract2.errorMessage).toBe("");
  });

  test("tx1: Check NFT", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );

    let txCode = await getTransactionCode({
      name: "tx_01_check_nft",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

    try {
      const result = await sendTransaction({
        code: txCode,
        signers: [NonFungibleTokenAddress],
      });

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  test("tx2: Configure user account", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );
    const BobAddress = await getAccountAddress("Bob");

    let txCode = await getTransactionCode({
      name: "tx_02_configure_user_account",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

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

  test("tx3: Mint NFT", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );

    let txCode = await getTransactionCode({
      name: "tx_03_mint_nft",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

    try {
      const result = await sendTransaction({
        code: txCode,
        signers: [NonFungibleTokenAddress],
      });

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  test("tx4: Transfer NFT", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );
    const BobAddress = await getAccountAddress("Bob");

    let txCode = await getTransactionCode({
      name: "tx_04_transfer_nft",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

    txCode = txCode.replace("getAccount(0x01)", `getAccount(${BobAddress})`);

    try {
      const result = await sendTransaction({
        code: txCode,
        signers: [NonFungibleTokenAddress],
      });

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });
  test("script1: Get NFT IDs", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );
    const BobAddress = await getAccountAddress("Bob");

    let scriptCode = await getScriptCode({
      name: "script_01_get_nft_ids",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

    scriptCode = scriptCode.replace(
      "getAccount(0x02)",
      `getAccount(${NonFungibleTokenAddress})`
    );

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
  test("script2: Get NFT IDs", async () => {
    const NonFungibleTokenAddress = await getContractAddress(
      "NonFungibleToken"
    );
    const BobAddress = await getAccountAddress("Bob");

    let scriptCode = await getScriptCode({
      name: "script_01_get_nft_ids",
      addressMap: { NonFungibleToken: NonFungibleTokenAddress },
    });

    scriptCode = scriptCode
      .replace("getAccount(0x02)", `getAccount(${NonFungibleTokenAddress})`)
      .replace("getAccount(0x01)", `getAccount(${BobAddress})`);

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

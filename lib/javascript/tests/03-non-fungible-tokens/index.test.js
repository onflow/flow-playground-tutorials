import { fail } from "assert";
import path from "path";
import { init } from "../../flow-js-testing/src/utils";

import {
  txFile as tx,
  contractFile as contract,
  createFlowAccount as account,
  addContract as deployContract,
  sendTx,
  addTokenVault,
} from "../../flow-js-testing/src/utils/api2";

const basePath = path.resolve(
  __dirname,
  "../../../../cadence/03-non-fungible-tokens"
);

let Alice,
  Bob,
  NFTContract,
  NFTContractBase,
  AliceNFTContract,
  BobNFTContractBase,
  tx1,
  tx2,
  tx3,
  tx4;

beforeAll(async () => {
  init(basePath);

  // Accounts
  // -----------------------
  Alice = await account("Alice");
  Bob = await account("Bob");

  // Load Cadence from Files
  // -----------------------
  /* Contracts */
  NFTContract = await contract("NonFungibleToken");
  NFTContractBase = await contract("NonFungibleTokenBase");

  /* Transactions */
  tx1 = await tx("tx_01_check_nft");
  tx2 = await tx("tx_02_configure_user_account");
  tx3 = await tx("tx_03_mint_nft");
  tx4 = await tx("tx_04_transfer_nft");

  /* Deploy Contracts */
  AliceNFTContract = await deployContract(Alice, NFTContract);
  BobNFTContractBase = await deployContract(Bob, NFTContractBase);

  return await DeployedFTContract;
});

describe("Testing 'Non-Fungible Tokens' Tutorial", () => {
  it("tx1: Check NFT", async () => {
    tx1.importing({
      NonFungibleToken: AliceNFTContract.address,
    });

    tx1.signers(Alice.address);

    try {
      const result = await sendTx(tx1);

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  it("tx2: Configure user account", async () => {
    tx2.importing({
      NonFungibleToken: AliceNFTContract.address,
    });

    tx2.signers(Bob.address);

    try {
      const result = await sendTx(tx2);

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  it("tx3: Mint NFT", async () => {
    tx2.importing({
      NonFungibleToken: AliceNFTContract.address,
    });

    tx2.signers(Alice.address);

    try {
      const result = await sendTx(tx3);

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  it("tx4: Transfer NFT", async () => {
    tx4.importing({
      NonFungibleToken: AliceNFTContract.address,
    });

    tx4.replace({
      "getAccount(0x01)": `getAccount(${Bob.address})`,
    });

    try {
      const result = await sendTx(tx4);

      expect(result.errorMessage).toBe("");
      expect(result.status).toBe(4);
    } catch (e) {
      console.log(e);
      fail();
    }
  });

  it("xxx", async () => {
    await addTokenVault(Alice, DeployedFTContract, "FTVault");
    const balance = await Alice.balance();
    expect(balance).toBe("0.00000000");
  });

  // it("script1: Get NFT IDs", async () => {
  //   const NonFungibleTokenAddress = await getContractAddress(
  //     "NonFungibleToken"
  //   );

  //   let scriptCode = await getScriptCode({
  //     name: "script_01_get_nft_ids",
  //     addressMap: { NonFungibleToken: NonFungibleTokenAddress },
  //   });

  //   scriptCode = scriptCode.replace(
  //     "getAccount(0x02)",
  //     `getAccount(${NonFungibleTokenAddress})`
  //   );

  //   try {
  //     const result = await executeScript({
  //       code: scriptCode,
  //     });

  //     expect(result).toBe(null);
  //   } catch (e) {
  //     console.log(e);
  //     fail();
  //   }
  // });
  // it("script2: Get NFT IDs", async () => {
  //   const NonFungibleTokenAddress = await getContractAddress(
  //     "NonFungibleToken"
  //   );
  //   const BobAddress = await getAccountAddress("Bob");

  //   let scriptCode = await getScriptCode({
  //     name: "script_01_get_nft_ids",
  //     addressMap: { NonFungibleToken: NonFungibleTokenAddress },
  //   });

  //   scriptCode = scriptCode
  //     .replace("getAccount(0x02)", `getAccount(${NonFungibleTokenAddress})`)
  //     .replace("getAccount(0x01)", `getAccount(${BobAddress})`);

  //   try {
  //     const result = await executeScript({
  //       code: scriptCode,
  //     });

  //     expect(result).toBe(null);
  //   } catch (e) {
  //     console.log(e);
  //     fail();
  //   }
  // });
});

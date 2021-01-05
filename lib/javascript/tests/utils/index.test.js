import path from "path";
import { init } from "../../flow-js-testing/src/utils";

import {
  // txFile as tx,
  contractFile as contract,
  createFlowAccount as account,
  addContract as deployContract,
  // sendTx,
  addEmptyFTVault,
  addEmptyNFTCollection,
} from "../../flow-js-testing/src/utils/api2";

let Alice,
  Bob,
  FTContract,
  NFTContract,
  DeployedFTContract,
  DeployedNFTContract;

const FTBase = path.resolve(
  __dirname,
  "../../../../tutorials/02-fungible-tokens"
);

const NFTBase = path.resolve(
  __dirname,
  "../../../../tutorials/03-non-fungible-tokens"
);

describe("Testing Utils", () => {
  describe("FT Utils", () => {
    it("Adds a token vault and storage path to own account", async () => {
      init(FTBase);
      Alice = await account("Alice");
      Bob = await account("Bob");

      FTContract = await contract("FungibleToken");
      DeployedFTContract = await deployContract(Alice, FTContract);

      await addEmptyFTVault(Alice, DeployedFTContract, "FTVault");
      const balance = await Alice.balance();
      expect(balance).toBe("0.00000000");
    });
    it("Adds a token vault and storage path to another account", async () => {
      await addEmptyFTVault(Bob, DeployedFTContract, "FTVault");

      const balance = await Bob.balance();
      expect(balance).toBe("0.00000000");
    });
  });

  describe("NFT Utils", () => {
    it("Adds a NFT collection and storage path to own account", async () => {
      init(NFTBase);
      NFTContract = await contract("NonFungibleToken");
      DeployedNFTContract = await deployContract(Alice, NFTContract);

      await addEmptyNFTCollection(
        Alice,
        DeployedNFTContract,
        "MyNFTCollection"
      );
    });
    it("Adds a token vault and storage path to another account", async () => {
      await addEmptyNFTCollection(Bob, DeployedNFTContract, "MyNFTCollection");
    });
  });
});

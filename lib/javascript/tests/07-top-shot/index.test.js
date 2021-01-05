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

let TopShotAdminAccount,
  TopShotContract,
  NFTAccount,
  NFTContract,
  TopShotAdminReceiverContract,
  TopShotShardedCollectionContract,
  MarketTopShotContract;

const TopShotBase = path.resolve(
  __dirname,
  "../../../../tutorials/07-top-shot"
);
const NFTBase = path.resolve(
  __dirname,
  "../../../../tutorials/03-non-fungible-tokens"
);

describe("Testing TopShot", () => {
  describe("TopShot Contracts", () => {
    it("Deploys all the TopShot Contracts", async () => {
      init(NFTBase);

      NFTAccount = await account("NFTAccount");
      NFTContract = await contract("NonFungibleToken");

      await deployContract(NFTAccount, NFTContract);

      init(TopShotBase);

      TopShotAdminAccount = await account("TopShotAdminAccount");
      TopShotContract = await contract("TopShot");

      TopShotContract.replaceImports({
        NonFungibleToken: NFTAccount.address,
      });

      try {
        const DeployedTopShotContract = await deployContract(
          TopShotAdminAccount,
          TopShotContract
        );

        expect(DeployedTopShotContract.address).toBeDefined();
      } catch (e) {
        fail(e);
      }
    });
  });
});

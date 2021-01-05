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

const basePath = path.resolve(__dirname, "../../../../cadence/01-hello-world");

beforeAll(() => {
  init(basePath);
});

const HelloWorld = describe("Testing 'Hello World' Tutorial", () => {
  describe("Deployment", () => {
    test("Deploys tutorial contracts successfully", async () => {
      let deployContract1, deployContract2;
      try {
        deployContract1 = await deployContractByName({
          name: "HelloWorld",
        });
        deployContract2 = await deployContractByName({
          name: "HelloResource",
        });
      } catch (e) {
        console.log(e);
      }

      expect(deployContract1.errorMessage).toBe("");
      expect(deployContract2.errorMessage).toBe("");
    });
  });

  describe("Transactions (No signers)", () => {
    test("tx1: Logs 'Hello World'", async () => {
      const HelloWorld = await getContractAddress("HelloWorld");

      const txCode = await getTransactionCode({
        name: "tx_01_call_hello_method",
        addressMap: { HelloWorld },
      });

      try {
        const result = await sendTransaction({
          code: txCode,
        });

        expect(result.errorMessage).toBe("");
        expect(result.status).toBe(4);
      } catch (e) {
        console.log(e);
        fail();
      }
    });
  });

  describe("Transactions (Signers required)", () => {
    describe("Correct signers are supplied", () => {
      test("tx2: Logs 'Hello World' (Using Resource)", async () => {
        const HelloResource = await getContractAddress("HelloResource");

        const txCode = await getTransactionCode({
          name: "tx_02_getHelloResource",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
            signers: [HelloResource],
          });

          expect(result.errorMessage).toBe("");
          expect(result.status).toBe(4);
        } catch (e) {
          console.log(e);
          fail();
        }
      });
      test("tx3: Creates a public capability", async () => {
        const HelloResource = await getContractAddress("HelloResource");

        const txCode = await getTransactionCode({
          name: "tx_03_create_capability",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
            signers: [HelloResource],
          });

          expect(result.errorMessage).toBe("");
          expect(result.status).toBe(4);
        } catch (e) {
          console.log(e);
          fail();
        }
      });
    });
    describe("Incorrect signers are supplied", () => {
      test("tx2: Logs 'Hello World' fails with no signer", async () => {
        const HelloResource = await getContractAddress("HelloResource");

        const txCode = await getTransactionCode({
          name: "tx_02_getHelloResource",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
          });

          fail();
        } catch (e) {
          expect(e).toBeDefined();
        }
      });
      test("tx2: Logs 'Hello World' fails with incorrect signer", async () => {
        const HelloResource = await getContractAddress("HelloResource");
        const HelloWorld = await getContractAddress("HelloWorld");

        const txCode = await getTransactionCode({
          name: "tx_02_getHelloResource",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
            signers: [HelloWorld],
          });

          fail();
        } catch (e) {
          expect(e).toBeDefined();
        }
      });
      test("tx3: Create capability fails with no signer", async () => {
        const HelloResource = await getContractAddress("HelloResource");

        const txCode = await getTransactionCode({
          name: "tx_03_create_capability",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
          });

          fail();
        } catch (e) {
          expect(e).toBeDefined();
        }
      });
      test("tx3: Create capability fails with incorrect signer", async () => {
        const HelloResource = await getContractAddress("HelloResource");
        const HelloWorld = await getContractAddress("HelloWorld");

        const txCode = await getTransactionCode({
          name: "tx_03_create_capability",
          addressMap: { HelloResource },
        });

        try {
          const result = await sendTransaction({
            code: txCode,
            signers: [HelloWorld],
          });

          fail();
        } catch (e) {
          expect(e).toBeDefined();
        }
      });
    });
  });
});

export default HelloWorld;

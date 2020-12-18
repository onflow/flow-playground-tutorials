import { getContractAddress } from "./contract";
import { getAccountAddress } from "./create-account";
import { getTransactionCode, sendTransaction } from "./index";

export class txFromFile {
  constructor(fileName) {
    this.fileName = fileName;
    this.signingAccounts = undefined;
    this.importsMap = undefined;
    this.code = undefined;
  }

  signers(...addressList) {
    this.signingAccounts = Promise.all(
      addressList.map(async (addr) => await addr)
    );
    return this;
  }

  replaceImports(importsMap) {
    this.importsMap = this._resolveImportAddress(importsMap);
    return this;
  }

  async send() {
    const addressMap = await this.importsMap;
    const signers = await this.signingAccounts;
    const code = await getTransactionCode({
      name: this.fileName,
      addressMap,
    });

    const result = await sendTransaction({
      code,
      signers,
    });

    return result;
  }

  async _resolveImportAddress(importAddressMap) {
    const resolved = {};
    for (const contractName in importAddressMap) {
      resolved[contractName] = await importAddressMap[contractName];
    }
    return resolved;
  }
}

const getAddress = () => {
  const addressMap = new Map();
  return (name) => async () => {
    if (!addressMap.has(name)) {
      let addr;
      addr = await getContractAddress(name);
      if (!addr) addr = await getAccountAddress(name);
      addressMap.set(name, addr);
      return addr;
    }
    return addressMap.get(name);
  };
};

export const address = getAddress();

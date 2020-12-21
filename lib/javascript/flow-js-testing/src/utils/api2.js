import { getContractAddress } from "./contract";
import { getAccountAddress } from "./create-account";
import {
  getTransactionCode,
  sendTransaction,
  deployContractByName,
} from "./index";

class TxFromFile {
  constructor(fileName) {
    this.fileName = fileName;
    this.importsMap = {};
    this.signingAccounts = undefined;
    this.code = undefined;
  }

  signers(...addressList) {
    this.signingAccounts = addressList;
    return this;
  }

  importing(addrMap) {
    this.importsMap = addrMap;
    return this;
  }
}
class FlowAcct {
  constructor(alias) {
    this.alias = alias;
    this.address = "";
  }

  async build() {
    this.address = await getAccountAddress(this.alias);
    return this;
  }
}

class ContractFromFile {
  constructor(fileName) {
    this.fileName = fileName;
    this.addrMap = {};
    this.replaceMap = {};
  }
  replaceImports(addrMap) {
    this.addrMap = addrMap;
  }
  replace(replaceMap) {
    this.replaceMap = replaceMap;
  }
}

export const txFile = (fileName) => {
  return new TxFromFile(fileName);
};

export const contractFile = (fileName) => {
  return new ContractFromFile(fileName);
};

export const createFlowAccount = async (acctAlias) => {
  const acct = new FlowAcct(acctAlias);
  await acct.build();
  return acct;
};

export const addContract = async (acct, contract) => {
  return await deployContractByName({
    to: acct.address,
    name: contract.fileName,
    addressMap: contract.addrMap,
    replaceMap: contract.replaceMap,
  });
};

export const sendTx = async (tx) => {
  let code = await getTransactionCode({
    name: tx.fileName,
    addressMap: tx.importsMap,
  });

  if (tx.replaceMap) {
    for (const string in replaceMap) {
      code = code.replace(string, replaceMap[string]);
    }
  }

  const result = await sendTransaction({
    code: code,
    signers: tx.signingAccounts,
  });

  return result;
};

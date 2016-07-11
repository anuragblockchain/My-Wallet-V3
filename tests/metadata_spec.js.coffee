proxyquire = require('proxyquireify')(require)

OriginalWalletCrypto = require('../src/wallet-crypto');

MyWallet =
  wallet:
    syncWallet: () ->
    hdwallet:
      getMasterHDNode: () ->
        deriveHardened: (purpose) ->
          deriveHardened: (payloadType) ->
            deriveHardened: (i) ->
              path = "m/#{ purpose }'/#{ payloadType }'/#{ i }'"
              {
                getAddress: () -> path + "-address"
                getPublicKeyBuffer: () ->
                  slice: (start, offset) ->
                    "#{ path }-pubkey-buffer-slice-#{ start }-#{ offset }"
                keyPair:
                  toString: () -> "#{ path }-keyPair"
                  d:
                    toBuffer: () ->
                      "#{ path }-private-key-buffer"
              }

BitcoinJS = {

}

WalletCrypto = {
  sha256: (x) ->
    if x == "info.blockchain.metadata"
      OriginalWalletCrypto.sha256(x) # Too tedious to mock
    else
      "#{ x }|sha256"
}

stubs = {
  './wallet': MyWallet,
  './wallet-crypto': WalletCrypto,
  'bitcoinjs-lib': BitcoinJS
}

Metadata = proxyquire('../src/metadata', stubs)

describe "Metadata", ->

  c = undefined
  unencryptedData = JSON.stringify({hello: "world"})
  encryptedData = "random|#{ unencryptedData }|encrypted-with-random+aes-256-key|base64"
  serverPayload = JSON.stringify({
    version:1,
    payload: encryptedData,
    signature:"#{ encryptedData }|m/510742'/2'/0'-signature",
    created_at:1468316898000,
    updated_at:1468316941000,
    payload_type_id:2
  })

  beforeEach ->
    JasminePromiseMatchers.install()

  afterEach ->
    JasminePromiseMatchers.uninstall()

  describe "class", ->
    describe "new Metadata()", ->

      it "should instantiate", ->
        c = new Metadata(2)
        expect(c.constructor.name).toEqual("Metadata")

      it "should set the address", ->
        expect(c._address).toEqual("m/510742'/2'/0'-address")

      it "should set the signature KeyPair", ->
        expect(c._signatureKeyPair.toString()).toEqual("m/510742'/2'/0'-keyPair")

      it "should set the encryption key", ->
        expect(c._encryptionKey.toString()).toEqual("m/510742'/2'/1'-private-key-buffer|sha256")


  describe "API", ->
    beforeEach ->
      c = new Metadata(2)
      spyOn(c, "request").and.callFake((method, endpoint, data) ->
        console.log(method, endpoint, data)
        if method == "GET" && endpoint == ""
          new Promise((resolve) -> resolve(serverPayload))
        else # 404 is resolved as null
          new Promise((resolve) -> resolve(null))
      )

    describe "API", ->
      describe "GET", ->
        it "should resolve with an encrypted payload",  ->
          promise = c.GET("m/510742'/2'/0'-keyPair")
          expect(promise).toBeResolvedWith(serverPayload)

        it "should resolve 404 with null",  ->
          promise = c.GET("m/510742'/3'/0'-keyPair")
          expect(promise).toBeResolvedWith(null)

      describe "POST", ->
        it "...", ->
          pending()

      describe "PUT", ->
        it "...", ->
          pending()

describe "instance", ->
  beforeEach ->
    c = new Metadata(2)

    spyOn(c, "GET").and.callFake((endpoint, data) ->
      handle = (resolve, reject) ->
        if endpoint == "m/510742'/2'/0'-address" # 200
          resolve("payload")
        else if endpoint == "m/510742'/3'/0'-address" # 404
          resolve(null)
        else
          reject("Unknown endpoint")
      {
        then: (resolve) ->
          handle(resolve, (() ->))
          {
            catch: (reject) ->
              handle((() ->), reject)
          }
      }
    )

    spyOn(c, "POST").and.callFake((endpoint, data) ->
      handle = (resolve, reject) ->
        if endpoint == "m/510742'/2'/0'-address"
          resolve({})
        else
          reject("Unknown endpoint")
      {
        then: (resolve) ->
          handle(resolve, (() ->))
          {
            catch: (reject) ->
              handle((() ->), reject)
          }
      }
    )

    spyOn(c, "PUT").and.callFake((endpoint, data) ->
      handle = (resolve, reject) ->
        if endpoint == "m/510742'/2'/0'-address"
          resolve({})
        else
          reject("Unknown endpoint")
      {
        then: (resolve) ->
          handle(resolve, (() ->))
          {
            catch: (reject) ->
              handle((() ->), reject)
          }
      }
    )

    describe "setMagicHash", ->
      it "should calculate and store based on contents", ->
        pending()

    describe "create", ->
      it "should store on the server", ->
        pending()

      describe "if successful", ->
        it "should remember the new value and magic hash", ->
          pending()

      describe "if failed", ->
        it "should not have a value or magic hash", ->

    describe "fetch", ->
      it "should fetch from the server", ->
        pending()

      describe "if successful", ->
        it "should remember the value and magic hash", ->
          pending()

      describe "if resolved with null", ->
        it "should return null", ->
          pending()

        it "should not have a value or magic hash", ->
          pending()

      describe "if failed", ->
        it "should not have a value or magic hash", ->
          pending()

    describe "update", ->
      it "should refuse if value is unchanged", ->
        pending()

      it "should update on the server", ->
        pending()

      describe "if successful", ->
        it "should remember the new value and magic hash", ->
          pending()

      describe "if failed", ->
        it "should keep the previous value and magic hash", ->
          pending()

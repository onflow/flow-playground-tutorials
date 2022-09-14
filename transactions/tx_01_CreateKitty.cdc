import KittyVerse from 0xf8d6e0586b0a20c7

// Abyssinian, Bengal, Burmese, Maine Coon, Persian, Siamese
transaction {
    prepare(acct: AuthAccount) {
        let kitty <- KittyVerse.createKitty(name: "Abyssinian")
        let hat <- KittyVerse.createHat(name: "Cowboy Hat", material: "Cotton")
        let stick <- KittyVerse.createMagicStick(name: "Golden Stick", length: 5)

        kitty.addAccessory(newAccessory: <-hat)
        kitty.addAccessory(newAccessory: <-stick)

        acct.save(<-kitty, to: KittyVerse.KittyStoragePath)

        log("Kitty with accessories saved")
    }
}
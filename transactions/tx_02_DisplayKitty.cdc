import KittyVerse from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let kitty <- acct.load<@KittyVerse.Kitty>(from: KittyVerse.KittyStoragePath)
            ?? panic("Kitty doesn't exist!")

        log("This is my cat:")
        log(kitty.toString())

        acct.save(<-kitty, to: KittyVerse.KittyStoragePath)
    }
}
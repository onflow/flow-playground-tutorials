pub contract KittyVerse {

    pub let KittyStoragePath: StoragePath

    init() {
        self.KittyStoragePath = /storage/kitty
    }

    pub resource interface Accessory {
        pub name: String

        pub fun toString(): String
    }

    pub resource KittyHat: Accessory {
        pub let name: String
        pub let material: String

        init(name: String, material: String) {
            self.name = name
            self.material = material
        }

         pub fun toString(): String {
             return self.name.concat(" made of ").concat(self.material)
         }
    }

    pub fun createHat(name: String, material: String): @KittyHat {
        return <-create KittyHat(name: name, material: material)
    }

    pub resource KittyMagicStick: Accessory {
        pub let name: String
        pub let length: Int

        init(name: String, length: Int) {
            self.name = name
            self.length = length
        }

        pub fun toString(): String {
             return self.name.concat(" with a length of ").concat(self.length.toString())
        }
    }

    pub fun createMagicStick(name: String, length: Int): @KittyMagicStick {
        return <-create KittyMagicStick(name: name, length: length)
    }

    pub resource Kitty {
        pub let name: String
        pub let accessories: @[AnyResource{Accessory}]

        init(name: String) {
            self.name = name
            self.accessories <- []
        }

        pub fun addAccessory(newAccessory: @AnyResource{Accessory}) {
           self.accessories.append(<- newAccessory)
        }

        pub fun toString(): String {
            var description: String = "I'm ".concat(self.name)
            //iteration is a bit special because of https://github.com/onflow/cadence/issues/704
            var i = 0
            while i < self.accessories.length {
              if(i == 0) {
                  description = description.concat(" with a ")
              } else if(i < self.accessories.length) {
                  description = description.concat(" and a ")
              }
              let accessoryRef = &self.accessories[i] as &AnyResource{Accessory}
              description = description.concat(accessoryRef.toString())
              i = i + 1
            }
            return description
        }

        destroy() {
            destroy self.accessories
        }
    }

    pub fun createKitty(name: String): @Kitty {
        return <-create Kitty(name: name)
    }
}
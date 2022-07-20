// HelloWorldResource.cdc
//
// This is a variation of the HelloWorld contract that introduces the concept of
// resources, a new form of linear type that is unique to Cadence. Resources can be
// used to create a secure model of digital ownership.
//
// Learn more about resources in this tutorial: https://docs.onflow.org/docs/hello-world

pub contract HelloWorld {

    // Declare a resource that only includes one function.
    pub resource HelloAsset {

        // A transaction can call this function to get the "Hello, World!"
        // message from the resource.
        pub fun hello(): String {
            return "Hello, World!"
        }
    }

    // We're going to use the built-in create function to create a new instance
    // of the HelloAsset resource
    pub fun createHelloAsset(): @HelloAsset {
        return <-create HelloAsset()
    }

    init() {
        log("Hello Asset")
    }
}
 

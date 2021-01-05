package tutorials

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../cadence -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../cadence/...

import (
	"github.com/onflow/flow-playground-tutorials/lib/go/tutorials/internal/assets"
)

const (
	playground_01_HelloWorld         = "01-hello-world/contracts/HelloWorld.cdc"
	playground_01_HelloWorldResource = "01-hello-world/contracts/HelloWorldResource.cdc"
)

func HelloWorld() []byte {
	code := assets.MustAssetString(playground_01_HelloWorld)
	return []byte(code)
}

func HelloWorldResource() []byte {
	code := assets.MustAssetString(playground_01_HelloWorldResource)
	return []byte(code)
}

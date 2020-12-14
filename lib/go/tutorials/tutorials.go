package tutorials

//go:generate go run github.com/kevinburke/go-bindata/go-bindata -prefix ../../../tutorials/... -o internal/assets/assets.go -pkg assets -nometadata -nomemcopy ../../../tutorials/...

import (
	"github.com/onflow/flow-playground-tutorials/lib/go/tutorials/internal/assets"
)


const (
	playground_01_HelloWorld = "../../../tutorials/01-hello-world/contracts/HelloWorld.cdc"
)

func HelloWorld() []byte {
	code := assets.MustAssetString(playground_01_HelloWorld)

	return []byte(code)
}
package tutorials_test

import (
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/onflow/flow-playground-tutorials/lib/go/tutorials"
)

func TestHelloWorldContract(t *testing.T) {
	contract := tutorials.HelloWorld()
	assert.NotNil(t, contract)
}

package tutorials_test

import (
	"github.com/onflow/flow-playground-tutorials/lib/go/tutorials"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestHelloWorldContract(t *testing.T) {
	contract := tutorials.HelloWorld()
	assert.NotNil(t, contract)
}

func TestHelloWorldResourceContract(t *testing.T) {
	contract := tutorials.HelloWorldResource()
	assert.NotNil(t, contract)
}

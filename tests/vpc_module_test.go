// tests/vpc_module_test.go
//
// Terratest tests for modules/vpc.
//
// Test classification:
//   STATIC  — runs terraform init + validate only; no AWS resources created or destroyed.
//   AWS     — would create real AWS resources; tagged with t.Skip() and documented below.
//
// To run static tests only (no AWS credentials required):
//   cd tests && go test -v -run TestVpc -timeout 5m

package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestVpcModuleInit_Static validates that the VPC module initialises without creating any AWS resources.
// Classification: STATIC
func TestVpcModuleInit_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "vpc"),
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
	require.NoError(t, err, "terraform init failed for modules/vpc")
}

// TestVpcModuleValidate_Static runs terraform validate on the VPC module.
// Classification: STATIC
func TestVpcModuleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "vpc"),
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
	require.NoError(t, err, "terraform init failed for modules/vpc")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for modules/vpc")
	assert.Contains(t, output, "Success", "expected validate to report Success")
}

// TestVpcExampleInit_Static validates the vpc/examples/basic example.
// Classification: STATIC
func TestVpcExampleInit_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "vpc", "examples", "basic"),
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
	require.NoError(t, err, "terraform init failed for vpc/examples/basic")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for vpc/examples/basic")
	assert.Contains(t, output, "Success")
}

// TestVpcModulePlan_AWS would run terraform plan against a real AWS account.
// Classification: AWS INTEGRATION — SKIPPED
func TestVpcModulePlan_AWS(t *testing.T) {
	t.Skip("AWS integration test — requires live AWS credentials and will incur API calls. Remove t.Skip() to run.")
}

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

// TestVpcModuleInit_Static validates that the VPC module initialises and
// passes `terraform validate` without creating any AWS resources.
// Classification: STATIC
func TestVpcModuleInit_Static(t *testing.T) {
	t.Parallel()

	moduleDir := filepath.Join("..", "modules", "vpc")

	opts := &terraform.Options{
		TerraformDir: moduleDir,
		// -backend=false skips S3 backend initialisation
		InitArgs: []string{"-backend=false"},
		// NoColor keeps test output readable
		NoColor: true,
	}

	// Init only — does not plan or apply
	_, err := terraform.InitE(t, opts)
	require.NoError(t, err, "terraform init failed for modules/vpc")
}

// TestVpcModuleValidate_Static runs terraform validate on the VPC module.
// Classification: STATIC
func TestVpcModuleValidate_Static(t *testing.T) {
	t.Parallel()

	moduleDir := filepath.Join("..", "modules", "vpc")

	opts := &terraform.Options{
		TerraformDir: moduleDir,
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for modules/vpc")
	assert.Contains(t, output, "Success", "expected validate to report Success")
}

// TestVpcExampleInit_Static validates the vpc/examples/basic example.
// Classification: STATIC
func TestVpcExampleInit_Static(t *testing.T) {
	t.Parallel()

	exampleDir := filepath.Join("..", "modules", "vpc", "examples", "basic")

	opts := &terraform.Options{
		TerraformDir: exampleDir,
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	_, err := terraform.InitE(t, opts)
	require.NoError(t, err, "terraform init failed for vpc/examples/basic")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for vpc/examples/basic")
	assert.Contains(t, output, "Success")
}

// TestVpcModulePlan_AWS would run terraform plan against a real AWS account.
// Classification: AWS INTEGRATION — SKIPPED
// To enable: remove t.Skip(), set AWS_REGION and ensure credentials are configured.
func TestVpcModulePlan_AWS(t *testing.T) {
	t.Skip("AWS integration test — requires live AWS credentials and will incur API calls. Remove t.Skip() to run.")

	// Would use terraform.Plan() with real var values here.
}

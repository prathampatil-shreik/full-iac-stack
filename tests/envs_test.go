// tests/envs_test.go
//
// Terratest static init+validate tests for envs/dev and envs/prod.
//
// These environments use an S3 backend. The -backend=false flag is passed
// during init so no AWS credentials are required for static validation.
//
// Test classification:
//   STATIC  — terraform init -backend=false + validate; no AWS resources.
//   AWS     — skipped; documented with t.Skip().
//
// Run: cd tests && go test -v -run TestEnv -timeout 5m

package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestDevEnvValidate_Static validates envs/dev without connecting to AWS.
// Classification: STATIC
func TestDevEnvValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "envs", "dev"),
		// -backend=false prevents Terraform from trying to connect to the S3 backend
		InitArgs: []string{"-backend=false"},
		NoColor:  true,
	}

	_, err := terraform.InitE(t, opts)
	require.NoError(t, err, "terraform init -backend=false failed for envs/dev")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for envs/dev")
	assert.Contains(t, output, "Success")
}

// TestProdEnvValidate_Static validates envs/prod without connecting to AWS.
// Classification: STATIC
func TestProdEnvValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "envs", "prod"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	_, err := terraform.InitE(t, opts)
	require.NoError(t, err, "terraform init -backend=false failed for envs/prod")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for envs/prod")
	assert.Contains(t, output, "Success")
}

// TestBootstrapValidate_Static validates bootstrap/state-bucket.
// Classification: STATIC
func TestBootstrapValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "bootstrap", "state-bucket"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	_, err := terraform.InitE(t, opts)
	require.NoError(t, err, "terraform init -backend=false failed for bootstrap/state-bucket")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for bootstrap/state-bucket")
	assert.Contains(t, output, "Success")
}

// TestDevEnvPlan_AWS would run terraform plan against the real dev environment.
// Classification: AWS INTEGRATION — SKIPPED
// Requires: AWS credentials, S3 backend accessible, TF_VAR_db_password set,
//           terraform.tfvars present (not committed — see terraform.tfvars.example).
func TestDevEnvPlan_AWS(t *testing.T) {
	t.Skip("AWS integration test — requires live credentials, S3 backend, and TF_VAR_db_password. Remove t.Skip() to run.")
}

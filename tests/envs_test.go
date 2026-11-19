// tests/envs_test.go
//
// Terratest static init+validate tests for envs/dev and envs/prod.
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
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
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
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
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
		NoColor:      true,
	}

	_, err := terraform.RunTerraformCommandE(t, opts, "init", "-backend=false", "-input=false", "-no-color")
	require.NoError(t, err, "terraform init -backend=false failed for bootstrap/state-bucket")

	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for bootstrap/state-bucket")
	assert.Contains(t, output, "Success")
}

// TestDevEnvPlan_AWS would run terraform plan against the real dev environment.
// Classification: AWS INTEGRATION — SKIPPED
func TestDevEnvPlan_AWS(t *testing.T) {
	t.Skip("AWS integration test — requires live credentials, S3 backend, and TF_VAR_db_password. Remove t.Skip() to run.")
}

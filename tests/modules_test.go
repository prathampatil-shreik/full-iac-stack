// tests/modules_test.go
//
// Terratest static init+validate tests for compute, database, and storage modules.
//
// Test classification:
//   STATIC  — terraform init + validate only; no AWS resources created.
//   AWS     — skipped; documented with t.Skip().
//
// Run: cd tests && go test -v -run TestCompute|TestDatabase|TestStorage -timeout 5m

package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ── Compute module ────────────────────────────────────────────────────────────

// TestComputeModuleValidate_Static validates the compute module.
// Classification: STATIC
func TestComputeModuleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "compute"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for modules/compute")
	assert.Contains(t, output, "Success")
}

// TestComputeExampleValidate_Static validates the compute example.
// Classification: STATIC
func TestComputeExampleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "compute", "examples", "basic"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for compute/examples/basic")
	assert.Contains(t, output, "Success")
}

// ── Database module ───────────────────────────────────────────────────────────

// TestDatabaseModuleValidate_Static validates the database module.
// Classification: STATIC
func TestDatabaseModuleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "database"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for modules/database")
	assert.Contains(t, output, "Success")
}

// TestDatabaseExampleValidate_Static validates the database example.
// Classification: STATIC
func TestDatabaseExampleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "database", "examples", "basic"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for database/examples/basic")
	assert.Contains(t, output, "Success")
}

// ── Storage module ────────────────────────────────────────────────────────────

// TestStorageModuleValidate_Static validates the storage module.
// Classification: STATIC
func TestStorageModuleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "storage"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for modules/storage")
	assert.Contains(t, output, "Success")
}

// TestStorageExampleValidate_Static validates the storage example.
// Classification: STATIC
func TestStorageExampleValidate_Static(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: filepath.Join("..", "modules", "storage", "examples", "basic"),
		InitArgs:     []string{"-backend=false"},
		NoColor:      true,
	}

	terraform.Init(t, opts)
	output, err := terraform.ValidateE(t, opts)
	require.NoError(t, err, "terraform validate failed for storage/examples/basic")
	assert.Contains(t, output, "Success")
}

// ── AWS integration tests (skipped) ──────────────────────────────────────────

// TestDatabaseModuleApply_AWS would deploy a real RDS instance.
// Classification: AWS INTEGRATION — SKIPPED
// Estimated cost: ~$0.02/hr for db.t3.micro. Always run terraform destroy after.
func TestDatabaseModuleApply_AWS(t *testing.T) {
	t.Skip("AWS integration test — creates real RDS instance. Remove t.Skip() only in a controlled environment with destroy deferred.")
}

// TestComputeModuleApply_AWS would deploy a real ECS cluster + ALB.
// Classification: AWS INTEGRATION — SKIPPED
// Estimated cost: ~$0.008/hr for ALB + Fargate tasks.
func TestComputeModuleApply_AWS(t *testing.T) {
	t.Skip("AWS integration test — creates real ECS/ALB resources. Remove t.Skip() only in a controlled environment with destroy deferred.")
}

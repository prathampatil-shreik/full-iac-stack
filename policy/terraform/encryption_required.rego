# policy/terraform/encryption_required.rego
#
# Rule 1: aws_db_instance must have storage_encrypted = true.
# Rule 2: aws_s3_bucket_server_side_encryption_configuration must exist and
#         use AES256 or aws:kms.
#
# These map directly to modules/database/main.tf and modules/storage/main.tf.

package terraform.encryption

import rego.v1

# --- RDS encryption -----------------------------------------------------------

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	config := resource.change.after

	not config.storage_encrypted == true

	msg := sprintf(
		"[encryption_required] %s: RDS instance must have storage_encrypted = true",
		[resource.address],
	)
}

# --- S3 encryption ------------------------------------------------------------

# Collect all S3 bucket names that have an SSE configuration resource
s3_buckets_with_sse contains bucket_id if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	rule := resource.change.after.rule[_]
	algo := rule.apply_server_side_encryption_by_default[_].sse_algorithm
	algo in {"AES256", "aws:kms"}
	bucket_id := resource.change.after.bucket
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket"
	bucket_id := resource.change.after_unknown.id

	# If the bucket ID is unknown at plan time, check by address correlation
	not _bucket_has_sse(resource.address)

	msg := sprintf(
		"[encryption_required] %s: S3 bucket must have server-side encryption configured with AES256 or aws:kms",
		[resource.address],
	)
}

# Helper: check whether an SSE config resource references this bucket address prefix
_bucket_has_sse(bucket_address) if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	rule := resource.change.after.rule[_]
	algo := rule.apply_server_side_encryption_by_default[_].sse_algorithm
	algo in {"AES256", "aws:kms"}
	# SSE resource address shares the same module path as the bucket
	startswith(resource.address, _module_prefix(bucket_address))
}

_module_prefix(address) := prefix if {
	parts := split(address, ".")
	prefix := concat(".", array.slice(parts, 0, count(parts) - 1))
}
